"""Embedding routes — generate and store thesis embeddings."""

from flask import Blueprint, request, jsonify
from ..models import Thesis, ThesisEmbedding
from ..extensions import db
from ..auth import login_required, admin_required
from ..services.embeddings import embedding_service

embedding_bp = Blueprint("embedding", __name__)

@embedding_bp.route("/api/embeddings/generate/<int:thesis_id>", methods=["POST"])
@admin_required
def generate_embedding(thesis_id):
    """Generate embedding for a thesis."""
    thesis = Thesis.query.get(thesis_id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404
    
    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available. Install sentence-transformers."}), 503
    
    # Combine title and abstract for embedding
    text = f"{thesis.title}. {thesis.abstract}"
    
    # Generate embedding
    vector = embedding_service.embed(text)
    if vector is None:
        return jsonify({"error": "Failed to generate embedding"}), 500
    
    # Store in database
    existing = ThesisEmbedding.query.filter_by(thesis_id=thesis_id).first()
    if existing:
        existing.embedding = vector
        existing.model_name = embedding_service.model_name
    else:
        emb = ThesisEmbedding(
            thesis_id=thesis_id,
            chunk_text=text[:1000],
            embedding=vector,
            model_name=embedding_service.model_name,
        )
        db.session.add(emb)
    
    db.session.commit()
    
    return jsonify({
        "message": "Embedding generated",
        "thesis_id": thesis_id,
        "model": embedding_service.model_name,
        "dimensions": len(vector),
    }), 200

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
    
    # Generate query embedding
    query_vector = embedding_service.embed(query)
    if query_vector is None:
        return jsonify({"error": "Failed to generate query embedding"}), 500
    
    # Search using pgvector cosine similarity
    from pgvector.psycopg2 import register_vector
    from ..extensions import db
    
    # Use raw SQL for vector similarity search
    sql = """
        SELECT t.id, t.title, t.abstract, t.research_type, t.program_id, t.status,
               1 - (e.embedding <=> :query_vector) as similarity
        FROM thesis_embeddings e
        JOIN theses t ON e.thesis_id = t.id
        WHERE t.status = 'published'
        ORDER BY e.embedding <=> :query_vector
        LIMIT :limit
    """
    
    result = db.session.execute(
        db.text(sql),
        {"query_vector": str(query_vector), "limit": limit}
    )
    
    theses = []
    for row in result:
        theses.append({
            "id": row[0],
            "title": row[1],
            "abstract": row[2],
            "research_type": row[3],
            "program_id": row[4],
            "status": row[5],
            "similarity": float(row[6]),
        })
    
    return jsonify({
        "query": query,
        "results": theses,
        "count": len(theses),
    }), 200
