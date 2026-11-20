"""Background embedding index maintenance.

The embedding model takes tens of seconds to import/load on a cold process.
Loading it inside a write request made the first thesis submission after every
backend restart appear to hang. These helpers hand that work to a daemon
thread so create/update responses are never blocked by model startup.

Scanned PDFs carry no text layer, so PyMuPDF returns nothing for them. When the
extracted text is too short to be real, the page images are OCR'd with Tesseract
and the text is cached beside the PDF. That is what lets a photographed
manuscript be indexed on its full content instead of title + abstract only.
"""

import os
import shutil
import subprocess
import tempfile
import threading

from .uploads import upload_path

# Below this many characters the PDF is treated as a scan, not a digital file.
MIN_TEXT_CHARS = 200
# A scanned 100-200 page manuscript is normal; 300 stops a runaway upload.
MAX_OCR_PAGES = 300
OCR_DPI = 200
OCR_TIMEOUT_PER_PAGE = 180

TESSERACT_CANDIDATES = [
    r"C:\Program Files\Tesseract-OCR\tesseract.exe",
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
    "tesseract",
]

# One OCR job at a time: a 120-page book is a couple of minutes of CPU, and
# several uploads arriving together must not fight over it.
_ocr_lock = threading.Lock()


def find_tesseract():
    """Return the tesseract executable path, or None when it is not installed."""
    for candidate in TESSERACT_CANDIDATES:
        if os.path.sep in candidate:
            if os.path.isfile(candidate):
                return candidate
        else:
            found = shutil.which(candidate)
            if found:
                return found
    return None


def _ocr_cache_path(path):
    return f"{path}.ocr.txt"


def _read_ocr_cache(path):
    cache = _ocr_cache_path(path)
    try:
        with open(cache, encoding="utf-8") as f:
            text = f.read()
        return text if text.strip() else ""
    except OSError:
        return ""


def ocr_pdf_file(path, max_pages=MAX_OCR_PAGES):
    """OCR a PDF's pages, caching the text beside the file.

    Returns "" when Tesseract is missing or the PDF cannot be read. Re-indexing
    never re-runs OCR: the cache is keyed by the stored filename, which is
    unique per upload.
    """
    tesseract = find_tesseract()
    if not tesseract:
        return ""

    cached = _read_ocr_cache(path)
    if cached:
        return cached

    with _ocr_lock:
        cached = _read_ocr_cache(path)
        if cached:
            return cached

        import pymupdf

        parts = []
        with pymupdf.open(path) as doc, tempfile.TemporaryDirectory() as tmpdir:
            for index, page in enumerate(doc):
                if index >= max_pages:
                    break
                image_path = os.path.join(tmpdir, f"page_{index:04d}.png")
                page.get_pixmap(dpi=OCR_DPI).save(image_path)
                result = subprocess.run(
                    [tesseract, image_path, "stdout", "-l", "eng", "--psm", "3"],
                    capture_output=True,
                    timeout=OCR_TIMEOUT_PER_PAGE,
                )
                if result.returncode != 0:
                    detail = (result.stderr or b"").decode("utf-8", errors="replace")
                    raise RuntimeError(f"OCR failed on page {index + 1}: {detail[:300]}")
                parts.append((result.stdout or b"").decode("utf-8", errors="replace"))

        text = "\n".join(parts)
        try:
            with open(_ocr_cache_path(path), "w", encoding="utf-8") as f:
                f.write(text)
        except OSError:
            pass
        return text


def pdf_text_from_url(pdf_url, allow_ocr=True):
    """Return a stored PDF's text, OCR'ing it when it has no useful text layer.

    The path rules live in [upload_path], shared with the download and
    validation routes: only a bare filename under UPLOAD_DIR is accepted.
    """
    path = None
    try:
        path = upload_path(pdf_url)
        if not path or not os.path.isfile(path):
            return ""
        import pymupdf

        with pymupdf.open(path) as doc:
            text = "".join(page.get_text() for page in doc)
        if len(text.strip()) >= MIN_TEXT_CHARS or not allow_ocr:
            return text
        return ocr_pdf_file(path) or text
    except Exception:
        # A missing, corrupt, or unreadable PDF must not stop title+abstract
        # indexing; the caller falls back to those.
        return ""


def embed_thesis_async(thesis_id, title, abstract, pdf_text=None, pdf_url=None):
    """Recompute and store a thesis' chunks/vectors off the request thread.

    When ``pdf_text`` is not supplied but ``pdf_url`` is, the manuscript is
    read from disk in the worker thread (OCR included for scans). That is what
    makes a thesis created with an attached PDF indexed on title + abstract +
    full PDF content.
    """

    def _work():
        try:
            from .. import models as db
            from .chunking import build_thesis_chunks
            from .embeddings import embedding_service

            if not embedding_service.available:
                return
            text = pdf_text
            if not text and pdf_url:
                text = pdf_text_from_url(pdf_url)
            chunks = build_thesis_chunks(title or "", abstract or "", text)
            if not chunks:
                return
            vectors = embedding_service.embed_batch(chunks)
            if not vectors or len(vectors) != len(chunks):
                return
            db.replace_thesis_embeddings(
                thesis_id,
                list(zip(chunks, vectors)),
                embedding_service.model_name,
            )
        except Exception:
            # Indexing is best-effort; a failure must never surface as a 500 on
            # the submission that triggered it.
            pass

    threading.Thread(
        target=_work, daemon=True, name=f"embed-thesis-{thesis_id}"
    ).start()
