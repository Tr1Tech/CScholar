"""PDF upload routes — extract text with PyMuPDF."""

import os
import uuid
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
import pymupdf
from ..auth import admin_required

upload_bp = Blueprint("upload", __name__)

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB

def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

@upload_bp.route("/api/upload/pdf", methods=["POST"])
@admin_required
def upload_pdf():
    """Upload PDF, extract text with PyMuPDF, return preview."""
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400
    
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400
    
    if not allowed_file(file.filename):
        return jsonify({"error": "Only PDF files are allowed"}), 400
    
    # Read file bytes
    file_bytes = file.read()
    if len(file_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 400
    
    # Extract text with PyMuPDF
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
    
    # Generate unique filename
    filename = secure_filename(file.filename)
    unique_name = f"{uuid.uuid4().hex}_{filename}"
    
    # Save file to uploads directory
    upload_dir = os.path.join(current_app.root_path, "uploads")
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, unique_name)
    
    with open(file_path, "wb") as f:
        f.write(file_bytes)
    
    # Return extracted text preview
    return jsonify({
        "message": "PDF uploaded and parsed successfully",
        "filename": filename,
        "saved_as": unique_name,
        "file_size": len(file_bytes),
        "page_count": page_count,
        "extracted_text": text[:5000],  # First 5000 chars
        "text_length": len(text),
    }), 200
