"""OCR routes — extract text from scanned/image-based PDFs using Tesseract."""

import os
import uuid
import subprocess
import tempfile
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
import pymupdf
from ..auth import login_required, admin_required

ocr_bp = Blueprint("ocr", __name__)

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB

def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

def get_tesseract_path():
    """Find Tesseract executable."""
    # Common Windows paths
    paths = [
        r"C:\Program Files\Tesseract-OCR\tesseract.exe",
        r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
    ]
    for p in paths:
        if os.path.exists(p):
            return p
    # Try system PATH
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
    
    # Read file bytes
    file_bytes = file.read()
    if len(file_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 400
    
    # Get Tesseract path
    tesseract_path = get_tesseract_path()
    
    try:
        # Open PDF with PyMuPDF
        doc = pymupdf.open(stream=file_bytes, filetype="pdf")
        page_count = len(doc)
        
        # Extract text with OCR
        full_text = ""
        pages_processed = 0
        
        with tempfile.TemporaryDirectory() as tmpdir:
            for i, page in enumerate(doc):
                # Render page to image
                pix = page.get_pixmap(dpi=300)  # High DPI for better OCR
                img_path = os.path.join(tmpdir, f"page_{i}.png")
                pix.save(img_path)
                
                # Run Tesseract OCR
                result = subprocess.run(
                    [tesseract_path, img_path, "stdout", "-l", "eng"],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.returncode == 0:
                    full_text += result.stdout + "\n"
                    pages_processed += 1
                else:
                    full_text += f"[OCR failed for page {i+1}]\n"
                
                # Clean up image
                os.remove(img_path)
        
        doc.close()
        
    except subprocess.TimeoutExpired:
        return jsonify({"error": "OCR processing timed out"}), 400
    except Exception as e:
        return jsonify({"error": f"Failed to process PDF: {str(e)}"}), 400
    
    if not full_text.strip():
        return jsonify({"error": "No text could be extracted from the PDF"}), 400
    
    # Return extracted text
    return jsonify({
        "message": "OCR completed successfully",
        "filename": secure_filename(file.filename),
        "file_size": len(file_bytes),
        "page_count": page_count,
        "pages_processed": pages_processed,
        "extracted_text": full_text[:10000],  # First 10000 chars
        "text_length": len(full_text),
    }), 200
