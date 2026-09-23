"""PDF upload routes — extract text with PyMuPDF, associate with thesis."""

import os
import uuid
from flask import Blueprint, request, jsonify, current_app, send_from_directory
from werkzeug.utils import secure_filename
import pymupdf
from ..auth import admin_required, login_required
from .. import models as db

upload_bp = Blueprint("upload", __name__)

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


@upload_bp.route("/api/upload/pdf", methods=["POST"])
@admin_required
def upload_pdf():
    """Upload PDF, extract text with PyMuPDF, return preview.
    
    Accepts optional thesis_id via form data to associate the uploaded
    PDF with a thesis record (stores relative path in pdf_url column).
    """
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    if not allowed_file(file.filename):
        return jsonify({"error": "Only PDF files are allowed"}), 400

    file_bytes = file.read()
    if len(file_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 400

    # Parse thesis_id if provided
    thesis_id = request.form.get("thesis_id", type=int)
    if thesis_id is not None:
        existing = db.get_thesis_by_id(thesis_id)
        if not existing:
            return jsonify({"error": "Thesis not found"}), 404

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
