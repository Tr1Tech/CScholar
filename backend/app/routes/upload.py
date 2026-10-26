"""PDF upload routes -- extract text with PyMuPDF, associate with thesis."""

import os
import threading
import uuid
from fastapi import APIRouter, Request, Depends, HTTPException, UploadFile, File, Form
from fastapi import status as http_status
from ..auth import login_required
from .. import models as db
from ..config import UPLOAD_DIR

router = APIRouter()

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 50 * 1024 * 1024


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


def _reembed_thesis_async(thesis_id, pdf_text):
    def _work():
        try:
            from ..services.chunking import build_thesis_chunks
            from ..services.embeddings import embedding_service
            if not embedding_service.available:
                return
            thesis = db.get_thesis_by_id(thesis_id)
            if not thesis:
                return
            chunks = build_thesis_chunks(
                thesis.get("title", ""), thesis.get("abstract", ""), pdf_text)
            if not chunks:
                return
            vectors = embedding_service.embed_batch(chunks)
            if not vectors or len(vectors) != len(chunks):
                return
            db.replace_thesis_embeddings(
                thesis_id, list(zip(chunks, vectors)),
                embedding_service.model_name)
        except Exception:
            pass
    threading.Thread(target=_work, daemon=True).start()


@router.post("/api/upload/pdf", dependencies=[Depends(login_required)])
async def upload_pdf(
    request: Request,
    file: UploadFile = File(...),
    thesis_id: int = Form(None),
):
    role = request.state.current_user["role"]
    if role not in ("admin", "faculty"):
        raise HTTPException(status_code=403, detail="Admin or faculty access required")
    if not file or not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    if not allowed_file(file.filename):
        raise HTTPException(status_code=400, detail="Only PDF files are allowed")

    cl = request.headers.get("content-length")
    if cl:
        try:
            if int(cl) > MAX_FILE_SIZE:
                raise HTTPException(status_code=413, detail="File too large (max 50MB)")
        except ValueError:
            pass

    file_bytes = await file.read(MAX_FILE_SIZE + 1)
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="File too large (max 50MB)")
    if not file_bytes.startswith(b"%PDF-"):
        raise HTTPException(status_code=400, detail="Invalid PDF file")

    if thesis_id is not None:
        existing = db.get_thesis_by_id(thesis_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Thesis not found")
        if role == "faculty":
            if existing.get("creator_id") != request.state.current_user["id"]:
                raise HTTPException(status_code=403, detail="You can only attach PDFs to theses you submitted")
            if existing.get("status") != "draft":
                raise HTTPException(status_code=403, detail="PDFs can only be attached to drafts")

    try:
        import pymupdf
        doc = pymupdf.open(stream=file_bytes, filetype="pdf")
        text = ""
        for page in doc:
            text += page.get_text()
        page_count = len(doc)
        doc.close()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to parse PDF: {str(e)}")

    if not text.strip():
        raise HTTPException(status_code=400, detail="No text could be extracted from the PDF")

    import uuid as _uuid
    from werkzeug.utils import secure_filename
    filename = secure_filename(file.filename)
    unique_name = f"{_uuid.uuid4().hex}_{filename}"

    os.makedirs(UPLOAD_DIR, exist_ok=True)
    file_path = os.path.join(UPLOAD_DIR, unique_name)
    with open(file_path, "wb") as f:
        f.write(file_bytes)

    pdf_url = f"/api/uploads/{unique_name}"

    if thesis_id is not None:
        try:
            db.update_thesis(thesis_id, pdf_url=pdf_url)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to update thesis record: {str(e)}")
        try:
            db.create_thesis_file(
                thesis_id=thesis_id,
                filename=filename,
                file_path=pdf_url,
                file_size=len(file_bytes),
                mime_type="application/pdf",
                uploaded_by=request.state.current_user["id"],
            )
        except Exception:
            pass
        try:
            _reembed_thesis_async(thesis_id, text)
        except Exception:
            pass

    return {
        "message": "PDF uploaded and parsed successfully",
        "filename": filename,
        "saved_as": unique_name,
        "file_size": len(file_bytes),
        "page_count": page_count,
        "extracted_text": text[:5000],
        "text_length": len(text),
        "pdf_url": pdf_url,
    }