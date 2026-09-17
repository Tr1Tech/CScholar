"""Embedding routes — generate and store thesis embeddings."""

from flask import Blueprint, request, jsonify
from .. import models as db
from ..auth import login_required, admin_required
from ..services.embeddings import embedding_service

embedding_bp = Blueprint("embedding", __name__)


@embedding_bp.route("/api/embeddings/generate/<int:thesis_id>", methods=["POST"])
@admin_required
def generate_embedding(thesis_id):
    """Generate embedding for a thesis."""
    thesis = db.get_thesis_by_id(thesis_id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404

    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available. Install sentence-transformers."}), 503

    text = f"{thesis['title']}. {thesis['abstract']}"

    vector = embedding_service.embed(text)
    if vector is None:
        return jsonify({"error": "Failed to generate embedding"}), 500

    db.upsert_thesis_embedding(
        thesis_id=thesis_id,
        chunk_text=text[:1000],
        embedding_vector=vector,
        model_name=embedding_service.model_name,
    )

    return jsonify({
        "message": "Embedding generated",
        "thesis_id": thesis_id,
        "model": embedding_service.model_name,
        "dimensions": len(vector),
    }), 200


@embedding_bp.route("/api/embeddings/generate-bulk", methods=["POST"])
@admin_required
def generate_bulk_embeddings():
    """Generate embeddings for all published theses missing them."""
    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available"}), 503
    
    theses = db.list_theses(status="published")
    generated = 0
    for t in theses["theses"]:
        tid = t["id"]
        existing = db.get_thesis_embedding(tid)
        if not existing:
            text = f"{t['title']}. {t['abstract']}"
            vector = embedding_service.embed(text)
            if vector is not None:
                db.upsert_thesis_embedding(
                    thesis_id=tid,
                    chunk_text=text[:1000],
                    embedding_vector=vector,
                    model_name=embedding_service.model_name,
                )
                generated += 1
    
    return jsonify({"generated": generated, "total": len(theses["theses"])}), 200


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
    limit = data.get("limit", 10)

    query_vector = embedding_service.embed(query)
    if query_vector is None:
        return jsonify({"error": "Failed to generate query embedding"}), 500

    theses = db.semantic_search(query_vector, limit=limit)

    return jsonify({
        "query": query,
        "results": theses,
        "count": len(theses),
    }), 200
