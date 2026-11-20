"""OCR every PDF in a folder and write a .txt beside each one.

This is the front-matter workflow, not the batch importer: point it at the folder
of scanned title pages / abstracts and it leaves one text file per PDF that you
can copy from into the admin form. PDFs that already carry a text layer are read
directly; only image-only scans go through Tesseract.

Usage (from ``backend/``):

    venv\\Scripts\\python scripts\\ocr_folder.py ..\\..\\scans
    venv\\Scripts\\python scripts\\ocr_folder.py ..\\..\\scans --dpi 300 --pages 8

Existing .txt files that are newer than their PDF are skipped, so re-running
after adding a few scans only processes the new ones.
"""

import argparse
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

TESSERACT_CANDIDATES = [
    r"C:\Program Files\Tesseract-OCR\tesseract.exe",
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
    "tesseract",
]

# A text layer this long means the PDF is digital, not a scan.
TEXT_LAYER_MIN_CHARS = 200


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


def pdf_text_layer(path):
    import pymupdf

    try:
        with pymupdf.open(path) as doc:
            return "".join(page.get_text() for page in doc)
    except Exception:
        return ""


def ocr_pdf(path, tesseract, dpi, max_pages):
    import pymupdf

    started = time.perf_counter()
    with pymupdf.open(path) as doc:
        pages = list(doc)[:max_pages] if max_pages else list(doc)
        with tempfile.TemporaryDirectory() as tmp:
            parts = []
            for index, page in enumerate(pages):
                image_path = os.path.join(tmp, f"page_{index}.png")
                page.get_pixmap(dpi=dpi).save(image_path)
                result = subprocess.run(
                    [tesseract, image_path, "stdout", "-l", "eng", "--psm", "3"],
                    capture_output=True,
                    timeout=180,
                )
                if result.returncode != 0:
                    detail = (result.stderr or b"").decode("utf-8", errors="replace")
                    raise RuntimeError(f"tesseract failed on page {index + 1}: {detail[:300]}")
                parts.append((result.stdout or b"").decode("utf-8", errors="replace"))
        return "\n".join(parts), len(pages), time.perf_counter() - started


def main():
    parser = argparse.ArgumentParser(description="OCR a folder of scanned thesis front matter.")
    parser.add_argument("folder", help="Folder containing the PDF scans")
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument(
        "--pages",
        type=int,
        default=8,
        help="Maximum pages per PDF (front matter is 4-6). 0 means all pages.",
    )
    parser.add_argument("--force", action="store_true", help="Re-OCR even if a .txt exists")
    args = parser.parse_args()

    folder = Path(args.folder).expanduser().resolve()
    if not folder.is_dir():
        sys.exit(f"Not a folder: {folder}")

    pdfs = sorted(p for p in folder.iterdir() if p.suffix.lower() == ".pdf")
    if not pdfs:
        sys.exit(f"No PDFs in {folder}")

    tesseract = find_tesseract()
    if tesseract is None:
        sys.exit(
            "Tesseract not found. Install it from "
            "https://github.com/UB-Mannheim/tesseract/wiki (English data), "
            "or make sure tesseract.exe is on PATH."
        )

    print(f"Tesseract: {tesseract}")
    print(f"PDFs: {len(pdfs)} in {folder}")

    done = skipped = failed = 0
    for pdf in pdfs:
        text_path = pdf.with_suffix(".txt")
        if not args.force and text_path.exists() and text_path.stat().st_mtime >= pdf.stat().st_mtime:
            print(f"skip    {pdf.name} (has {text_path.name})")
            skipped += 1
            continue

        try:
            layer = pdf_text_layer(pdf)
            if len(layer.strip()) >= TEXT_LAYER_MIN_CHARS:
                text, pages, seconds = layer, "digital", 0.0
            else:
                text, pages, seconds = ocr_pdf(pdf, tesseract, args.dpi, args.pages)
            text_path.write_text(text.strip() + "\n", encoding="utf-8")
            print(f"ok      {pdf.name}  {pages} pages, {len(text)} chars, {seconds:.1f}s")
            done += 1
        except Exception as exc:
            print(f"FAILED  {pdf.name}: {exc}")
            failed += 1

    print(f"\ndone: {done} processed, {skipped} skipped, {failed} failed")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
