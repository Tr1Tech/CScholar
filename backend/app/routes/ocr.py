"""OCR routes -- extract text from scanned/image-based PDFs using Tesseract."""

import os
import subprocess
import tempfile
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
import pymupdf
from ..auth import admin_required

router = APIRouter(tags=["Upload"])

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 50 * 1024 * 1024


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


def get_tesseract_path():
    paths = [
        r"C:\Program Files\Tesseract-OCR\tesseract.exe",
        r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
    ]
    for p in paths:
        if os.path.exists(p):
            return p
    return "tesseract"


@router.post("/api/ocr/pdf", dependencies=[Depends(admin_required)])
async def ocr_pdf(file: UploadFile = File(...)):
    if not file or not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    if not allowed_file(file.filename):
        raise HTTPException(status_code=400, detail="Only PDF files are allowed")

    file_bytes = await file.read(MAX_FILE_SIZE + 1)
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="File too large (max 50MB)")
    if not file_bytes.startswith(b"%PDF-"):
        raise HTTPException(status_code=400, detail="Invalid PDF file")

    doc = None
    try:
        doc = pymupdf.open(stream=file_bytes, filetype="pdf")
        page_count = len(doc)
        if page_count > 50:
            raise HTTPException(status_code=400, detail="PDF has too many pages (max 50 for OCR)")
        text = ""
        tesseract_path = get_tesseract_path()

        with tempfile.TemporaryDirectory() as tmpdir:
            for i, page in enumerate(doc):
                pix = page.get_pixmap(dpi=200)
                img_path = os.path.join(tmpdir, f"page_{i}.png")
                pix.save(img_path)
                try:
                    result = subprocess.run(
                        [tesseract_path, img_path, "stdout", "-l", "eng"],
                        capture_output=True, timeout=60,
                    )
                    if result.returncode != 0:
                        err = (result.stderr or b"").decode("utf-8", errors="replace")
                        raise HTTPException(status_code=500, detail=f"OCR failed: {err[:500]}")
                    text += (result.stdout or b"").decode("utf-8", errors="replace") + "\n"
                except (subprocess.TimeoutExpired, FileNotFoundError, OSError) as e:
                    raise HTTPException(status_code=500, detail=f"OCR failed: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to process PDF: {str(e)}")
    finally:
        if doc is not None:
            try:
                doc.close()
            except Exception:
                pass

    return {
        "message": "OCR completed",
        "page_count": page_count,
        "extracted_text": text[:10000],
        "text_length": len(text),
    }