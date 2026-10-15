"""PDF upload routes — extract text with PyMuPDF, associate with thesis."""

import os
import threading
import uuid
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
import pymupdf
from ..auth import login_required
from .. import models as db

upload_bp = Blueprint("upload", __name__)

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


def _reembed_thesis_async(thesis_id, pdf_text):
    """Chunk + re-embed a thesis in a background thread (best-effort)."""
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
            pass  # Never break uploads on embedding failures.
    threading.Thread(target=_work, daemon=True).start()


@upload_bp.route("/api/upload/pdf", methods=["POST"])
@login_required
def upload_pdf():
    """Upload PDF, extract text with PyMuPDF, return preview.

    Admins and faculty. Accepts optional thesis_id via form data to
    associate the uploaded PDF with a thesis record (stores relative path
    in pdf_url column). Faculty may only attach to their own drafts.
    """
    role = request.current_user["role"]
    if role not in ("admin", "faculty"):
        return jsonify({"error": "Admin or faculty access required"}), 403
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    if not allowed_file(file.filename):
        return jsonify({"error": "Only PDF files are allowed"}), 400

    # Reject obviously oversized bodies before buffering into RAM.
    if request.content_length and request.content_length > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 413

    file_bytes = file.read(MAX_FILE_SIZE + 1)
    if len(file_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 413
    if not file_bytes.startswith(b"%PDF-"):
        return jsonify({"error": "Invalid PDF file"}), 400

    # Parse thesis_id if provided
    thesis_id = request.form.get("thesis_id", type=int)
    if thesis_id is not None:
        existing = db.get_thesis_by_id(thesis_id)
        if not existing:
            return jsonify({"error": "Thesis not found"}), 404
        if role == "faculty":
            if existing.get("creator_id") != request.current_user["id"]:
                return jsonify({"error": "You can only attach PDFs to theses you submitted"}), 403
            if existing.get("status") != "draft":
                return jsonify({"error": "PDFs can only be attached to drafts"}), 403

    try:
        doc = pymupdf.open(stream=file_bytes, filetype="pdf")
        text = ""
        for page in doc:
            text += page.get_text()
        page_count = len(doc)
        doc.close()
    except Exception as e:
        return jsonify({"error": f"Failed to parse PDF: {str(e)}"}), 400

    if not text.strip():
        return jsonify({"error": "No text could be extracted from the PDF"}), 400

    filename = secure_filename(file.filename)
    unique_name = f"{uuid.uuid4().hex}_{filename}"

    upload_dir = os.path.join(current_app.root_path, "uploads")
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, unique_name)

    with open(file_path, "wb") as f:
        f.write(file_bytes)

    # Build relative URL for storage
    pdf_url = f"/api/uploads/{unique_name}"

    # Associate with thesis record if thesis_id was provided
    if thesis_id is not None:
        try:
            db.update_thesis(thesis_id, pdf_url=pdf_url)
        except Exception as e:
            return jsonify({"error": f"Failed to update thesis record: {str(e)}"}), 500
        try:
            db.create_thesis_file(
                thesis_id=thesis_id,
                filename=filename,
                file_path=pdf_url,
                file_size=len(file_bytes),
                mime_type="application/pdf",
                uploaded_by=request.current_user["id"],
            )
        except Exception:
            pass  # Metadata row is nice-to-have; never fail the upload.
        # Re-embed in the background so recommendations/search see the full
        # PDF body. Fire-and-forget: extraction already succeeded above.
        try:
            _reembed_thesis_async(thesis_id, text)
        except Exception:
            pass

    return jsonify({
        "message": "PDF uploaded and parsed successfully",
        "filename": filename,
        "saved_as": unique_name,
        "file_size": len(file_bytes),
        "page_count": page_count,
        "extracted_text": text[:5000],
        "text_length": len(text),
        "pdf_url": pdf_url,
    }), 200
