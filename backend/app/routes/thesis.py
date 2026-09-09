"""Thesis routes — list, detail, create, update, delete."""

from flask import Blueprint, request, jsonify
from ..models import Thesis
from ..extensions import db
from ..auth import admin_required

thesis_bp = Blueprint("thesis", __name__)

@thesis_bp.route("/api/theses", methods=["GET"])
def list_theses():
    """List theses with optional filters."""
    query = Thesis.query

    # Filters
    q = request.args.get("q")
    if q:
        query = query.filter(Thesis.title.ilike(f"%{q}%") | Thesis.abstract.ilike(f"%{q}%"))
    
    program_id = request.args.get("program_id", type=int)
    if program_id:
        query = query.filter(Thesis.program_id == program_id)
    
    year_id = request.args.get("year_id", type=int)
    if year_id:
        query = query.filter(Thesis.academic_year_id == year_id)
    
    research_type = request.args.get("research_type")
    if research_type:
        query = query.filter(Thesis.research_type == research_type)
    
    status = request.args.get("status")
    if status:
        query = query.filter(Thesis.status == status)

    # Pagination
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    pagination = query.order_by(Thesis.created_at.desc()).paginate(page=page, per_page=per_page)

    return jsonify({
        "theses": [_serialize_thesis(t) for t in pagination.items],
        "total": pagination.total,
        "page": page,
        "per_page": per_page,
        "pages": pagination.pages,
    }), 200

@thesis_bp.route("/api/theses/<int:id>", methods=["GET"])
def get_thesis(id):
    """Get a single thesis by ID."""
    thesis = Thesis.query.get(id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404
    return jsonify(_serialize_thesis(thesis, detailed=True)), 200

@thesis_bp.route("/api/theses", methods=["POST"])
@admin_required
def create_thesis():
    """Create a new thesis (admin only)."""
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    # Validation
    required = ["title", "abstract", "research_type", "program_id", "academic_year_id"]
    for field in required:
        if not data.get(field):
            return jsonify({"error": f"{field} is required"}), 400

    thesis = Thesis(
        title=data["title"],
        abstract=data["abstract"],
        research_type=data["research_type"],
        program_id=data["program_id"],
        academic_year_id=data["academic_year_id"],
        status=data.get("status", "draft"),
        creator_id=request.current_user.id,
    )
    db.session.add(thesis)
    db.session.commit()

    return jsonify(_serialize_thesis(thesis)), 201

@thesis_bp.route("/api/theses/<int:id>", methods=["PUT"])
@admin_required
def update_thesis(id):
    """Update a thesis (admin only)."""
    thesis = Thesis.query.get(id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404

    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    # Update fields
    if "title" in data:
        thesis.title = data["title"]
    if "abstract" in data:
        thesis.abstract = data["abstract"]
    if "research_type" in data:
        thesis.research_type = data["research_type"]
    if "program_id" in data:
        thesis.program_id = data["program_id"]
    if "academic_year_id" in data:
        thesis.academic_year_id = data["academic_year_id"]
    if "status" in data:
        thesis.status = data["status"]

    db.session.commit()
    return jsonify(_serialize_thesis(thesis)), 200

@thesis_bp.route("/api/theses/<int:id>", methods=["DELETE"])
@admin_required
def delete_thesis(id):
    """Delete a thesis (admin only)."""
    thesis = Thesis.query.get(id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404

    db.session.delete(thesis)
    db.session.commit()
    return jsonify({"message": "Thesis deleted"}), 200

def _serialize_thesis(thesis, detailed=False):
    """Serialize a thesis to JSON."""
    data = {
        "id": thesis.id,
        "title": thesis.title,
        "abstract": thesis.abstract,
        "research_type": thesis.research_type,
        "program_id": thesis.program_id,
        "program": {
            "id": thesis.program.id,
            "name": thesis.program.name,
            "code": thesis.program.code,
            "description": thesis.program.description,
            "created_at": thesis.program.created_at.isoformat() if thesis.program.created_at else None,
        } if thesis.program else None,
        "academic_year_id": thesis.academic_year_id,
        "academic_year": {
            "id": thesis.academic_year.id,
            "name": thesis.academic_year.name,
            "start_year": thesis.academic_year.start_year,
            "end_year": thesis.academic_year.end_year,
            "is_active": thesis.academic_year.is_active,
            "created_at": thesis.academic_year.created_at.isoformat() if thesis.academic_year.created_at else None,
        } if thesis.academic_year else None,
        "status": thesis.status,
        "creator_id": thesis.creator_id,
        "created_at": thesis.created_at.isoformat() if thesis.created_at else None,
        "updated_at": thesis.updated_at.isoformat() if thesis.updated_at else None,
    }
    return data
