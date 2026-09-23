"""Thesis routes — list, detail, create, update, delete."""

from flask import Blueprint, request, jsonify
from .. import models as db
from ..auth import login_required, admin_required

thesis_bp = Blueprint("thesis", __name__)


def _pagination_args():
    """Return validated pagination parameters or an error response."""
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    if page is None or page < 1:
        return None, jsonify({"error": "page must be a positive integer"}), 400
    if per_page is None or not 1 <= per_page <= 100:
        return None, jsonify({"error": "per_page must be between 1 and 100"}), 400
    return (page, per_page), None, None


@thesis_bp.route("/api/theses", methods=["GET"])
def list_theses():
    """List theses with optional filters."""
    q = request.args.get("q")
    program_id = request.args.get("program_id", type=int)
    year_id = request.args.get("year_id", type=int)
    category_id = request.args.get("category_id", type=int)
    keyword = request.args.get("keyword")
    sort_by = request.args.get("sort_by")
    research_type = request.args.get("research_type")
    status = request.args.get("status")
    if not status:
        status = ['published', 'approved']
    
    pagination, error, status_code = _pagination_args()
    if error:
        return error, status_code
    page, per_page = pagination

    result = db.list_theses(
        q=q,
        program_id=program_id,
        year_id=year_id,
        category_id=category_id,
        keyword=keyword,
        sort_by=sort_by,
        research_type=research_type,
        status=status,
        page=page,
        per_page=per_page,
    )
    return jsonify(result), 200


@thesis_bp.route("/api/theses/<int:id>", methods=["GET"])
def get_thesis(id):
    """Get a single thesis by ID."""
    thesis = db.get_thesis_by_id(id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404
    return jsonify(thesis), 200


@thesis_bp.route("/api/theses/<int:id>/recommend", methods=["GET"])
def recommend_theses(id):
    """Get recommended theses similar to the given thesis."""
    from ..services.embeddings import embedding_service
    
    thesis = db.get_thesis_by_id(id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404

    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available"}), 503

    limit = request.args.get("limit", 5, type=int)
    if limit is None or not 1 <= limit <= 20:
        return jsonify({"error": "limit must be between 1 and 20"}), 400
    theses = db.recommend_for_thesis(id, limit=limit)

    return jsonify({
        "thesis_id": id,
        "theses": theses,
        "count": len(theses),
    }), 200


@thesis_bp.route("/api/dashboard/stats", methods=["GET"])
@admin_required
def dashboard_stats():
    """Get admin dashboard statistics."""
    stats = db.get_dashboard_stats()
    return jsonify(stats), 200


@thesis_bp.route("/api/dashboard/recent-activity", methods=["GET"])
@login_required
def dashboard_recent_activity():
    """Get recent activity for dashboards."""
    limit = request.args.get("limit", 10, type=int)
    activity = db.recent_activity(limit=limit)
    return jsonify({"activity": activity}), 200


@thesis_bp.route("/api/faculty/dashboard", methods=["GET"])
@login_required
def faculty_dashboard():
    """Get faculty-specific dashboard data."""
    if request.current_user["role"] != "faculty":
        return jsonify({"error": "Faculty access required"}), 403
    stats = db.get_faculty_stats(request.current_user["email"])
    return jsonify(stats), 200


@thesis_bp.route("/api/faculty/activity", methods=["GET"])
@login_required
def faculty_activity():
    """Get activity for the current faculty's advisees."""
    limit = request.args.get("limit", 10, type=int)
    if request.current_user["role"] != "faculty":
        return jsonify({"error": "Faculty access required"}), 403
    if limit is None or not 1 <= limit <= 100:
        return jsonify({"error": "limit must be between 1 and 100"}), 400
    activity = db.get_faculty_activity(request.current_user["email"], limit=limit)
    return jsonify({"activity": activity}), 200


@thesis_bp.route("/api/theses", methods=["POST"])
@admin_required
def create_thesis():
    """Create a new thesis (admin only)."""
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    required = ["title", "abstract", "research_type", "program_id", "academic_year_id"]
    for field in required:
        if not data.get(field):
            return jsonify({"error": f"{field} is required"}), 400

    thesis_id = db.create_thesis(
        title=data["title"],
        abstract=data["abstract"],
        research_type=data["research_type"],
        program_id=data["program_id"],
        academic_year_id=data["academic_year_id"],
        creator_id=request.current_user["id"],
        status=data.get("status", "draft"),
        author_ids=data.get("author_ids"),
        adviser_id=data.get("adviser_id"),
        category_ids=data.get("category_ids"),
        keyword_terms=data.get("keyword_terms"),
    )

    # Auto-generate embedding if service is available (best-effort)
    try:
        from ..services.embeddings import embedding_service
        if embedding_service.available:
            text = f"{data['title']}. {data['abstract']}"
            vector = embedding_service.embed(text)
            if vector is not None:
                db.upsert_thesis_embedding(
                    thesis_id=thesis_id,
                    chunk_text=text[:1000],
                    embedding_vector=vector,
                    model_name=embedding_service.model_name,
                )
    except Exception:
        pass  # Never block thesis creation on embedding failure

    thesis = db.get_thesis_by_id(thesis_id)
    return jsonify(thesis), 201


@thesis_bp.route("/api/theses/<int:id>", methods=["PUT"])
@admin_required
def update_thesis(id):
    """Update a thesis (admin only)."""
    existing = db.get_thesis_by_id(id)
    if not existing:
        return jsonify({"error": "Thesis not found"}), 404

    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    db.update_thesis(id, **data)
    thesis = db.get_thesis_by_id(id)
    return jsonify(thesis), 200


@thesis_bp.route("/api/theses/<int:id>", methods=["DELETE"])
@admin_required
def delete_thesis(id):
    """Delete a thesis (admin only)."""
    existing = db.get_thesis_by_id(id)
    if not existing:
        return jsonify({"error": "Thesis not found"}), 404

    db.delete_thesis(id)
    return jsonify({"message": "Thesis deleted"}), 200
