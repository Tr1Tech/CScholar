"""OCR routes — extract text from scanned/image-based PDFs using Tesseract."""

import os
import subprocess
import tempfile
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
import pymupdf
from ..auth import admin_required

ocr_bp = Blueprint("ocr", __name__)

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


def get_tesseract_path():
    """Find Tesseract executable."""
    paths = [
        r"C:\Program Files\Tesseract-OCR\tesseract.exe",
        r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
    ]
    for p in paths:
        if os.path.exists(p):
            return p
    return "tesseract"


@ocr_bp.route("/api/ocr/pdf", methods=["POST"])
@admin_required
def ocr_pdf():
    """Upload scanned PDF, extract text with Tesseract OCR."""
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    if not allowed_file(file.filename):
        return jsonify({"error": "Only PDF files are allowed"}), 400

    if request.content_length and request.content_length > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 413

    file_bytes = file.read(MAX_FILE_SIZE + 1)
    if len(file_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 413
    if not file_bytes.startswith(b"%PDF-"):
        return jsonify({"error": "Invalid PDF file"}), 400

    doc = None
    try:
        doc = pymupdf.open(stream=file_bytes, filetype="pdf")
        page_count = len(doc)
        if page_count > 50:
            return jsonify({"error": "PDF has too many pages (max 50 for OCR)"}), 400
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
                        capture_output=True, text=True, timeout=60,
                    )
                    if result.returncode != 0:
                        return jsonify({"error": f"OCR failed: {result.stderr[:500]}"}), 500
                    text += result.stdout + "\n"
                except (subprocess.TimeoutExpired, FileNotFoundError, OSError) as e:
                    return jsonify({"error": f"OCR failed: {str(e)}"}), 500

    except Exception as e:
        return jsonify({"error": f"Failed to process PDF: {str(e)}"}), 400
    finally:
        if doc is not None:
            try:
                doc.close()
            except Exception:
                pass

    return jsonify({
        "message": "OCR completed",
        "page_count": page_count,
        "extracted_text": text[:10000],
        "text_length": len(text),
    }), 200
