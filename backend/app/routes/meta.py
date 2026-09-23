"""Meta routes — programs, academic years, categories, keywords, authors, advisers."""

from flask import Blueprint, jsonify, request
from ..auth import admin_required
from .. import models as db

meta_bp = Blueprint("meta", __name__)


@meta_bp.route("/api/programs", methods=["GET"])
def list_programs():
    return jsonify(db.list_programs()), 200


@meta_bp.route("/api/academic-years", methods=["GET"])
def list_academic_years():
    return jsonify(db.list_academic_years()), 200


@meta_bp.route("/api/categories", methods=["GET"])
def list_categories():
    return jsonify(db.list_categories()), 200


@meta_bp.route("/api/keywords", methods=["GET"])
def list_keywords():
    return jsonify(db.list_keywords()), 200


@meta_bp.route("/api/authors", methods=["GET"])
def list_authors():
    return jsonify(db.list_authors()), 200


@meta_bp.route("/api/advisers", methods=["GET"])
def list_advisers():
    return jsonify(db.list_advisers()), 200


@meta_bp.route("/api/research-types", methods=["GET"])
def list_research_types():
    return jsonify(["Thesis", "Capstone"]), 200


# ── Authors CRUD ───────────────────────────────────────────────────────────

@meta_bp.route("/api/authors", methods=["POST"])
@admin_required
def create_author():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    first_name = data.get("first_name")
    last_name = data.get("last_name")
    if not first_name or not last_name:
        return jsonify({"error": "first_name and last_name are required"}), 400
    author = db.create_author(
        first_name=first_name,
        last_name=last_name,
        email=data.get("email"),
        middle_name=data.get("middle_name"),
    )
    return jsonify(author), 201


@meta_bp.route("/api/authors/<int:author_id>", methods=["PUT"])
@admin_required
def update_author(author_id):
    existing = db.get_author_by_id(author_id)
    if not existing:
        return jsonify({"error": "Author not found"}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    allowed = {"first_name", "last_name", "email", "middle_name"}
    updates = {k: v for k, v in data.items() if k in allowed}
    author = db.update_author(author_id, **updates)
    return jsonify(author), 200


@meta_bp.route("/api/authors/<int:author_id>", methods=["DELETE"])
@admin_required
def delete_author(author_id):
    existing = db.get_author_by_id(author_id)
    if not existing:
        return jsonify({"error": "Author not found"}), 404
    db.delete_author(author_id)
    return jsonify({"message": "Author deleted", "id": author_id}), 200


# ── Advisers CRUD ──────────────────────────────────────────────────────────

@meta_bp.route("/api/advisers", methods=["POST"])
@admin_required
def create_adviser():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    first_name = data.get("first_name")
    last_name = data.get("last_name")
    if not first_name or not last_name:
        return jsonify({"error": "first_name and last_name are required"}), 400
    adviser = db.create_adviser(
        first_name=first_name,
        last_name=last_name,
        email=data.get("email"),
        middle_name=data.get("middle_name"),
    )
    return jsonify(adviser), 201


@meta_bp.route("/api/advisers/<int:adviser_id>", methods=["PUT"])
@admin_required
def update_adviser(adviser_id):
    existing = db.get_adviser_by_id(adviser_id)
    if not existing:
        return jsonify({"error": "Adviser not found"}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    allowed = {"first_name", "last_name", "email", "middle_name"}
    updates = {k: v for k, v in data.items() if k in allowed}
    adviser = db.update_adviser(adviser_id, **updates)
    return jsonify(adviser), 200


@meta_bp.route("/api/advisers/<int:adviser_id>", methods=["DELETE"])
@admin_required
def delete_adviser(adviser_id):
    existing = db.get_adviser_by_id(adviser_id)
    if not existing:
        return jsonify({"error": "Adviser not found"}), 404
    db.delete_adviser(adviser_id)
    return jsonify({"message": "Adviser deleted", "id": adviser_id}), 200


# ── Categories CRUD ────────────────────────────────────────────────────────

@meta_bp.route("/api/categories", methods=["POST"])
@admin_required
def create_category():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    name = data.get("name")
    if not name:
        return jsonify({"error": "name is required"}), 400
    category = db.create_category(
        name=name,
        description=data.get("description"),
    )
    return jsonify(category), 201


@meta_bp.route("/api/categories/<int:category_id>", methods=["PUT"])
@admin_required
def update_category(category_id):
    existing = db.get_category_by_id(category_id)
    if not existing:
        return jsonify({"error": "Category not found"}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    allowed = {"name", "description"}
    updates = {k: v for k, v in data.items() if k in allowed}
    category = db.update_category(category_id, **updates)
    return jsonify(category), 200


@meta_bp.route("/api/categories/<int:category_id>", methods=["DELETE"])
@admin_required
def delete_category(category_id):
    existing = db.get_category_by_id(category_id)
    if not existing:
        return jsonify({"error": "Category not found"}), 404
    db.delete_category(category_id)
    return jsonify({"message": "Category deleted", "id": category_id}), 200


# ── Keywords CRUD ──────────────────────────────────────────────────────────

@meta_bp.route("/api/keywords", methods=["POST"])
@admin_required
def create_keyword():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    term = data.get("term")
    if not term:
        return jsonify({"error": "term is required"}), 400
    keyword = db.create_keyword(term=term)
    return jsonify(keyword), 201


@meta_bp.route("/api/keywords/<int:keyword_id>", methods=["PUT"])
@admin_required
def update_keyword(keyword_id):
    existing = db.get_keyword_by_id(keyword_id)
    if not existing:
        return jsonify({"error": "Keyword not found"}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    allowed = {"term"}
    updates = {k: v for k, v in data.items() if k in allowed}
    keyword = db.update_keyword(keyword_id, **updates)
    return jsonify(keyword), 200


@meta_bp.route("/api/keywords/<int:keyword_id>", methods=["DELETE"])
@admin_required
def delete_keyword(keyword_id):
    existing = db.get_keyword_by_id(keyword_id)
    if not existing:
        return jsonify({"error": "Keyword not found"}), 404
    db.delete_keyword(keyword_id)
    return jsonify({"message": "Keyword deleted", "id": keyword_id}), 200


# ── Programs CRUD ─────────────────────────────────────────────────────────

@meta_bp.route("/api/programs", methods=["POST"])
@admin_required
def create_program():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    name = data.get("name")
    if not name:
        return jsonify({"error": "name is required"}), 400
    program = db.create_program(
        name=name,
        code=data.get("code"),
        description=data.get("description"),
    )
    return jsonify(program), 201


@meta_bp.route("/api/programs/<int:program_id>", methods=["PUT"])
@admin_required
def update_program(program_id):
    existing = db.get_program_by_id(program_id)
    if not existing:
        return jsonify({"error": "Program not found"}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    allowed = {"name", "code", "description"}
    updates = {k: v for k, v in data.items() if k in allowed}
    program = db.update_program(program_id, **updates)
    return jsonify(program), 200


@meta_bp.route("/api/programs/<int:program_id>", methods=["DELETE"])
@admin_required
def delete_program(program_id):
    existing = db.get_program_by_id(program_id)
    if not existing:
        return jsonify({"error": "Program not found"}), 404
    db.delete_program(program_id)
    return jsonify({"message": "Program deleted", "id": program_id}), 200


# ── Academic Years CRUD ───────────────────────────────────────────────────

@meta_bp.route("/api/academic-years", methods=["POST"])
@admin_required
def create_academic_year():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    name = data.get("name")
    if not name:
        return jsonify({"error": "name is required"}), 400
    is_active = data.get("is_active", True)
    if isinstance(is_active, str):
        is_active = is_active.lower() in ("true", "1", "yes")
    academic_year = db.create_academic_year(
        name=name,
        start_year=data.get("start_year"),
        end_year=data.get("end_year"),
        is_active=is_active,
    )
    return jsonify(academic_year), 201


@meta_bp.route("/api/academic-years/<int:year_id>", methods=["PUT"])
@admin_required
def update_academic_year(year_id):
    existing = db.get_academic_year_by_id(year_id)
    if not existing:
        return jsonify({"error": "Academic year not found"}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    allowed = {"name", "start_year", "end_year", "is_active"}
    updates = {k: v for k, v in data.items() if k in allowed}
    if "is_active" in updates and isinstance(updates["is_active"], str):
        updates["is_active"] = updates["is_active"].lower() in ("true", "1", "yes")
    academic_year = db.update_academic_year(year_id, **updates)
    return jsonify(academic_year), 200


@meta_bp.route("/api/academic-years/<int:year_id>", methods=["DELETE"])
@admin_required
def delete_academic_year(year_id):
    existing = db.get_academic_year_by_id(year_id)
    if not existing:
        return jsonify({"error": "Academic year not found"}), 404
    db.delete_academic_year(year_id)
    return jsonify({"message": "Academic year deleted", "id": year_id}), 200
