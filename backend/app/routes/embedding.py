"""Embedding routes — generate and store thesis embeddings (full-PDF chunking)."""

import os
import threading

from flask import Blueprint, request, jsonify, current_app
from .. import models as db
from ..auth import login_required, admin_required
from ..services.embeddings import embedding_service
from ..services.chunking import build_thesis_chunks

embedding_bp = Blueprint("embedding", __name__)

# ── Bulk backfill progress (in-memory; resets on restart) ────────────────────
_bulk_lock = threading.Lock()
_bulk_state = {
    "running": False,
    "total": 0,
    "processed": 0,
    "embedded": 0,
    "skipped": 0,
    "failed": 0,
    "error": None,
}


def _extract_pdf_text_for_thesis(thesis, upload_dir):
    """Best-effort PDF body text for a thesis whose pdf_url is a local upload.

    Returns "" when there is no local PDF or extraction fails — callers fall
    back to title+abstract chunks. Never raises.
    """
    try:
        pdf_url = (thesis.get("pdf_url") or "")
        prefix = "/api/uploads/"
        if not pdf_url.startswith(prefix):
            return ""
        filename = pdf_url[len(prefix):]
        if (not filename or ".." in filename or "/" in filename
                or "\\" in filename or filename.startswith((".",))):
            return ""
        path = os.path.join(upload_dir, filename)
        if not os.path.exists(path):
            return ""
        import pymupdf
        text_parts = []
        with pymupdf.open(path) as doc:
            for page in doc:
                try:
                    text_parts.append(page.get_text())
                except Exception:
                    continue
        return "".join(text_parts)
    except Exception:
        return ""


def _embed_thesis_chunks(thesis_id, title, abstract, pdf_text=None):
    """Chunk + batch-encode + replace all embedding rows for one thesis.

    Returns the chunk count on success, None when the model is unavailable
    or encoding fails. Raises on DB errors.
    """
    chunks = build_thesis_chunks(title, abstract, pdf_text)
    if not chunks:
        return None
    vectors = embedding_service.embed_batch(chunks)
    if not vectors or len(vectors) != len(chunks):
        return None
    db.replace_thesis_embeddings(
        thesis_id,
        list(zip(chunks, vectors)),
        embedding_service.model_name,
    )
    return len(chunks)


def _iter_all_theses(statuses, page_size=100):
    """Yield every thesis row for the given statuses (paginated)."""
    page = 1
    while True:
        result = db.list_theses(status=statuses, page=page, per_page=page_size)
        rows = result.get("theses", [])
        if not rows:
            return
        for row in rows:
            yield row
        if page >= result.get("pages", page):
            return
        page += 1


def _bulk_worker(upload_dir, refresh):
    """Background backfill: chunk + embed every thesis missing embeddings."""
    with _bulk_lock:
        _bulk_state.update(running=True, processed=0, embedded=0,
                           skipped=0, failed=0, error=None)
    try:
        theses = list(_iter_all_theses(["published", "approved"]))
        with _bulk_lock:
            _bulk_state["total"] = len(theses)
        for t in theses:
            tid = t["id"]
            try:
                if not refresh and db.count_thesis_embedding_chunks(tid) > 0:
                    with _bulk_lock:
                        _bulk_state["skipped"] += 1
                else:
                    full = db.get_thesis_by_id(tid)
                    pdf_text = _extract_pdf_text_for_thesis(full or t, upload_dir)
                    n = _embed_thesis_chunks(
                        tid, t.get("title", ""), t.get("abstract", ""), pdf_text)
                    with _bulk_lock:
                        if n:
                            _bulk_state["embedded"] += 1
                        else:
                            _bulk_state["failed"] += 1
            except Exception:
                with _bulk_lock:
                    _bulk_state["failed"] += 1
            finally:
                with _bulk_lock:
                    _bulk_state["processed"] += 1
    except Exception as e:
        with _bulk_lock:
            _bulk_state["error"] = str(e)[:500]
    finally:
        with _bulk_lock:
            _bulk_state["running"] = False


@embedding_bp.route("/api/embeddings/generate/<int:thesis_id>", methods=["POST"])
@admin_required
def generate_embedding(thesis_id):
    """Generate (chunked) embeddings for a thesis, including its PDF body."""
    thesis = db.get_thesis_by_id(thesis_id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404

    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available. Install sentence-transformers."}), 503

    upload_dir = os.path.join(current_app.root_path, "uploads")
    pdf_text = _extract_pdf_text_for_thesis(thesis, upload_dir)
    try:
        n = _embed_thesis_chunks(
            thesis_id, thesis.get("title", ""), thesis.get("abstract", ""), pdf_text)
    except Exception as e:
        return jsonify({"error": f"Failed to store embeddings: {str(e)[:300]}"}), 500
    if not n:
        return jsonify({"error": "Failed to generate embedding"}), 500

    return jsonify({
        "message": "Embeddings generated",
        "thesis_id": thesis_id,
        "model": embedding_service.model_name,
        "chunks": n,
        "used_pdf": bool(pdf_text and pdf_text.strip()),
    }), 200


@embedding_bp.route("/api/embeddings/generate-bulk", methods=["POST"])
@admin_required
def generate_bulk_embeddings():
    """Start a background backfill for all theses missing chunk embeddings.

    Query params: ?refresh=true re-embeds everything (e.g. after a model
    change). Returns 202 with the worker state; poll bulk-status.
    """
    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available"}), 503

    with _bulk_lock:
        if _bulk_state["running"]:
            return jsonify({"message": "Backfill already running",
                            "status": dict(_bulk_state)}), 202
        _bulk_state.update(running=True, total=0, processed=0, embedded=0,
                           skipped=0, failed=0, error=None)

    refresh = request.args.get("refresh", "false").lower() == "true"
    upload_dir = os.path.join(current_app.root_path, "uploads")
    worker = threading.Thread(target=_bulk_worker, args=(upload_dir, refresh), daemon=True)
    worker.start()
    return jsonify({"message": "Backfill started", "refresh": refresh}), 202


@embedding_bp.route("/api/embeddings/bulk-status", methods=["GET"])
@admin_required
def bulk_status():
    """Poll the background backfill progress."""
    with _bulk_lock:
        return jsonify(dict(_bulk_state)), 200


@embedding_bp.route("/api/embeddings/search", methods=["POST"])
@login_required
def search():
    """Semantic search using embeddings."""
    data = request.get_json()
    if not data or "query" not in data:
        return jsonify({"error": "Query is required"}), 400

    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available"}), 503

    query = data["query"]
    if not isinstance(query, str) or not query.strip():
        return jsonify({"error": "Query must be a non-empty string"}), 400
    try:
        limit = int(data.get("limit", 10))
    except (TypeError, ValueError):
        return jsonify({"error": "limit must be between 1 and 20"}), 400
    if not 1 <= limit <= 20:
        return jsonify({"error": "limit must be between 1 and 20"}), 400

    query_vector = embedding_service.embed(query)
    if query_vector is None:
        return jsonify({"error": "Failed to generate query embedding"}), 500

    theses = db.semantic_search(query_vector, limit=limit)

    return jsonify({
        "query": query,
        "results": theses,
        "count": len(theses),
    }), 200
