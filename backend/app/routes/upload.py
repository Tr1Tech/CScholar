"""PDF upload routes — extract text + parse metadata with PyMuPDF."""

import os
import re
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


def parse_pdf_metadata(text):
    """Heuristic parser to extract thesis metadata from PDF text."""
    metadata = {
        "title": "",
        "authors": "",
        "program": "",
        "abstract": "",
        "adviser": "",
        "year": "",
        "keywords": "",
    }

    lines = text.split("\n")
    lines = [l.strip() for l in lines if l.strip()]

    # ── Title: first prominent heading (often all caps or bold) ─────────
    for line in lines[:30]:
        cleaned = line.strip()
        if len(cleaned) > 10 and cleaned.isupper():
            metadata["title"] = cleaned.title()
            break
    if not metadata["title"]:
        for line in lines[:10]:
            if len(line.strip()) > 15:
                metadata["title"] = line.strip()
                break

    # ── Authors: below title, often comma-separated names ──────────────
    # Look for lines with commas or "and" that look like names
    for i, line in enumerate(lines[:30]):
        if re.search(r"[A-Z][a-z]+ [A-Z][a-z]+(,| and)", line):
            metadata["authors"] = line.strip()
            break
    if not metadata["authors"]:
        for i, line in enumerate(lines[:15]):
            if i > 0 and "," in line and len(line) < 100:
                parts = [p.strip() for p in line.split(",")]
                if all(len(p.split()) <= 4 for p in parts):
                    metadata["authors"] = line.strip()
                    break

    # ── Program: search for CEIT program codes ─────────────────────────
    program_patterns = [
        r"BS\s*(Information Technology|IT)",
        r"BS\s*(Computer Science|CS)",
        r"BS\s*(Information Systems|IS)",
        r"BSIT", r"BSCS", r"BSIS",
        r"Bachelor of Science in (Information Technology|Computer Science|Information Systems)",
    ]
    for pattern in program_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            raw = match.group(0)
            # Normalize to full name
            if "IT" in raw.upper() and "INFORMATION" not in raw.upper():
                metadata["program"] = "BS Information Technology"
            elif "CS" in raw.upper() and "COMPUTER" not in raw.upper():
                metadata["program"] = "BS Computer Science"
            elif "IS" in raw.upper() and "INFORMATION" not in raw.upper():
                metadata["program"] = "BS Information Systems"
            else:
                metadata["program"] = raw.strip()
            break

    # ── Abstract: text between ABSTRACT and next heading ───────────────
    abstract_start = None
    abstract_end = None
    heading_pattern = re.compile(
        r"^(KEYWORDS|INTRODUCTION|CHAPTER|TABLE OF CONTENTS|METHODOLOGY|REVIEW OF RELATED|CONCLUSIONS)",
        re.IGNORECASE,
    )
    for i, line in enumerate(lines):
        if abstract_start is None and re.match(r"^ABSTRACT", line, re.IGNORECASE):
            abstract_start = i + 1
        elif abstract_start is not None and abstract_end is None:
            if heading_pattern.match(line) or (line.isupper() and len(line) > 5):
                abstract_end = i
                break
    if abstract_start is not None:
        end = abstract_end if abstract_end else abstract_start + 50
        metadata["abstract"] = "\n".join(lines[abstract_start:end]).strip()

    # ── Adviser: line containing "Adviser" or "Advisor" ────────────────
    for line in lines:
        match = re.search(
            r"(?:Adviser|Advisor|Panel|Chairperson)\s*[:\-]?\s*(.+)",
            line,
            re.IGNORECASE,
        )
        if match:
            metadata["adviser"] = match.group(1).strip()
            break

    # ── Year: 4-digit year near the title ──────────────────────────────
    year_match = re.search(r"(20[2-9][0-9])\s*[-–]\s*(20[2-9][0-9])", text)
    if year_match:
        metadata["year"] = f"{year_match.group(1)} - {year_match.group(2)}"
    else:
        year_match = re.search(r"(20[2-9][0-9])", text)
        if year_match:
            metadata["year"] = year_match.group(1)

    # ── Keywords: lines after KEYWORDS heading ─────────────────────────
    kw_start = None
    for i, line in enumerate(lines):
        if re.match(r"^KEYWORDS?\s*[:\-]?", line, re.IGNORECASE):
            kw_start = i + 1
            break
    if kw_start is not None:
        kw_lines = []
        for line in lines[kw_start:kw_start + 5]:
            if line.isupper() and len(line) > 5:
                break
            kw_lines.append(line.strip())
        metadata["keywords"] = " ".join(kw_lines).strip()

    return metadata


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

    file_bytes = file.read()
    if len(file_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File too large (max 50MB)"}), 400

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

    return jsonify({
        "message": "PDF uploaded and parsed successfully",
        "filename": filename,
        "saved_as": unique_name,
        "file_size": len(file_bytes),
        "page_count": page_count,
        "extracted_text": text[:5000],
        "text_length": len(text),
    }), 200


@upload_bp.route("/api/upload/parse", methods=["POST"])
@admin_required
def parse_pdf():
    """Upload PDF and return parsed metadata to auto-fill the thesis form."""
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

    try:
        doc = pymupdf.open(stream=file_bytes, filetype="pdf")
        text = ""
        for page in doc:
            text += page.get_text()
        doc.close()
    except Exception as e:
        return jsonify({"error": f"Failed to parse PDF: {str(e)}"}), 400

    if not text.strip():
        return jsonify({"error": "No text could be extracted from the PDF"}), 400

    metadata = parse_pdf_metadata(text)

    return jsonify({
        "message": "Metadata extracted",
        "metadata": metadata,
        "extracted_text_preview": text[:3000],
    }), 200
