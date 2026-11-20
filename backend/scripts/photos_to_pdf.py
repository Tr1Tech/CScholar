"""Turn page photos into one PDF per book.

Point it at a folder of book subfolders (or a single folder of photos):

    scans/
      BSIT_2023_0142/  page_001.jpg page_002.jpg ...
      BSEE_2022_0087/  page_001.jpg ...

    venv\\Scripts\\python scripts\\photos_to_pdf.py ..\\scans
    venv\\Scripts\\python scripts\\photos_to_pdf.py ..\\scans --searchable

Without ``--searchable`` the PDF is images only. The app cannot read text from
that, so the thesis is embedded on title + abstract only.

With ``--searchable`` every page is OCR'd and the page image is returned with an
invisible text layer, so the existing upload endpoint extracts the whole
manuscript and embeds it. This is what makes photographed pages actually
searchable — at roughly 1 second per page.

Pages are downscaled to ``--max-width`` and JPEG-compressed so a 100-page book
lands around 10-20 MB instead of 150-300 MB (the upload endpoint caps at 50 MB).
"""

import argparse
import datetime
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import pymupdf

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tif", ".tiff"}

TESSERACT_CANDIDATES = [
    r"C:\Program Files\Tesseract-OCR\tesseract.exe",
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
    "tesseract",
]


def find_tesseract():
    for candidate in TESSERACT_CANDIDATES:
        if os.path.sep in candidate:
            if os.path.isfile(candidate):
                return candidate
        else:
            try:
                subprocess.run([candidate, "--version"], capture_output=True, timeout=10)
                return candidate
            except (OSError, subprocess.TimeoutExpired):
                continue
    return None


def natural_key(path):
    """page_2 before page_10."""
    return [int(part) if part.isdigit() else part.lower()
            for part in re.split(r"(\d+)", path.name)]


TIMESTAMP_NAME = re.compile(r"^IMG_(\d{8})_(\d{6})(?:_\d+)?$")


def sort_key(path):
    """Chronological order, mixing camera and timestamp-style filenames.

    Phones produce either ``IMG_20261117_132941.jpg`` or a bare epoch
    milliseconds name such as ``1794893530594.jpg``. Sorting those two formats
    as strings puts 13:32 before 13:29, which silently reorders the pages.
    Both are parsed to an epoch and merged into one timeline.
    """
    stem = path.stem
    match = TIMESTAMP_NAME.match(stem)
    if match:
        try:
            stamp = datetime.datetime.strptime(
                match.group(1) + match.group(2), "%Y%m%d%H%M%S"
            )
            return (0, stamp.timestamp(), stem.lower())
        except ValueError:
            pass
    if stem.isdigit() and len(stem) >= 12:
        return (0, int(stem) / 1000.0, stem)
    return (1, 0.0, natural_key(path))


def page_jpeg(image_path, max_width, quality):
    """Return (jpeg_bytes, width, height) downscaled and greyscaled."""
    with pymupdf.open(image_path) as doc:
        page = doc[0]
        zoom = max_width / page.rect.width if page.rect.width > max_width else 1.0
        pix = page.get_pixmap(matrix=pymupdf.Matrix(zoom, zoom),
                              colorspace=pymupdf.csGRAY, alpha=False)
        return pix.tobytes("jpeg", jpg_quality=quality), pix.width, pix.height


def build_book(image_paths, pdf_path, tesseract, max_width, quality, searchable, tmpdir):
    out = pymupdf.open()
    for index, image in enumerate(image_paths, start=1):
        jpeg, width, height = page_jpeg(image, max_width, quality)

        if searchable:
            page_source = os.path.join(tmpdir, f"page_{index:04d}.jpg")
            with open(page_source, "wb") as f:
                f.write(jpeg)
            single = os.path.join(tmpdir, f"page_{index:04d}")
            result = subprocess.run(
                [tesseract, page_source, single, "-l", "eng", "--psm", "3", "pdf"],
                capture_output=True, timeout=300,
            )
            if result.returncode != 0:
                detail = (result.stderr or b"").decode("utf-8", errors="replace")
                raise RuntimeError(f"tesseract failed on {image.name}: {detail[:300]}")
            with pymupdf.open(single + ".pdf") as page_pdf:
                # Tesseract sets the page size from the JPEG's assumed DPI, which
                # yields inconsistent, oversized pages. Place the OCR'd page on
                # a normal page instead; this scales the image and its invisible
                # text layer together.
                page_width = 595.0
                page_height = page_width * height / width
                page = out.new_page(width=page_width, height=page_height)
                page.show_pdf_page(page.rect, page_pdf, 0)
        else:
            page_width = 595.0
            page_height = page_width * height / width
            page = out.new_page(width=page_width, height=page_height)
            page.insert_image(page.rect, stream=jpeg)

    out.save(pdf_path, garbage=3, deflate=True)
    out.close()


def main():
    parser = argparse.ArgumentParser(description="Convert page photos to one PDF per book.")
    parser.add_argument("folder", help="Folder of book subfolders, or a folder of photos")
    parser.add_argument("--searchable", action="store_true",
                        help="OCR each page and embed an invisible text layer")
    parser.add_argument("--max-width", type=int, default=2000,
                        help="Downscale pages to this width in pixels (default 2000)")
    parser.add_argument("--quality", type=int, default=75, help="JPEG quality (default 75)")
    parser.add_argument("--out", default=None, help="Output folder (default: alongside input)")
    args = parser.parse_args()

    root = Path(args.folder).expanduser().resolve()
    if not root.is_dir():
        sys.exit(f"Not a folder: {root}")

    tesseract = None
    if args.searchable:
        tesseract = find_tesseract()
        if tesseract is None:
            sys.exit("Tesseract not found. Install it, or drop --searchable.")

    out_dir = Path(args.out).expanduser().resolve() if args.out else root
    out_dir.mkdir(parents=True, exist_ok=True)

    # Any folder that directly contains images is one book, at any depth.
    # Handles both scans/BOOK/ and scans/GROUP/BOOK/.
    books = []
    used_names = set()
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
        images = sorted(
            (Path(dirpath) / name for name in filenames
             if Path(name).suffix.lower() in IMAGE_EXTENSIONS),
            key=sort_key,
        )
        if images:
            name = Path(dirpath).name
            if name in used_names:
                name = f"{name}_{len(used_names)}"
            used_names.add(name)
            books.append((name, images))

    if not books:
        sys.exit(f"No images found in {root}")

    print(f"Tesseract: {tesseract or 'not used (images only)'}")
    print(f"Books: {len(books)}")

    failed = 0
    for name, images in books:
        pdf_path = out_dir / f"{name}.pdf"
        print(f"\n{name}: {len(images)} pages")
        try:
            with tempfile.TemporaryDirectory() as tmpdir:
                build_book(images, pdf_path, tesseract, args.max_width,
                           args.quality, args.searchable, tmpdir)
            size_mb = pdf_path.stat().st_size / (1024 * 1024)
            note = ""
            if size_mb > 50:
                note = "  OVER 50 MB - the upload endpoint will reject this; lower --quality"
            print(f"  -> {pdf_path.name}  {size_mb:.1f} MB{note}")
        except Exception as exc:
            print(f"  FAILED: {exc}")
            failed += 1

    print(f"\ndone: {len(books) - failed} built, {failed} failed")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
