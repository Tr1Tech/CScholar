"""Meta routes — programs, academic years, categories, keywords, authors, advisers."""

from flask import Blueprint, jsonify
from ..models import Program, AcademicYear, Category, Keyword, Author, Adviser

meta_bp = Blueprint("meta", __name__)

@meta_bp.route("/api/programs", methods=["GET"])
def list_programs():
    programs = Program.query.order_by(Program.name).all()
    return jsonify([{"id": p.id, "name": p.name, "code": p.code, "description": p.description} for p in programs]), 200

@meta_bp.route("/api/academic-years", methods=["GET"])
def list_academic_years():
    years = AcademicYear.query.order_by(AcademicYear.start_year.desc()).all()
    return jsonify([{"id": y.id, "name": y.name, "label": y.name, "start_year": y.start_year, "end_year": y.end_year, "is_active": y.is_active} for y in years]), 200

@meta_bp.route("/api/categories", methods=["GET"])
def list_categories():
    categories = Category.query.order_by(Category.name).all()
    return jsonify([{"id": c.id, "name": c.name, "description": c.description, "created_at": c.created_at.isoformat() if c.created_at else None} for c in categories]), 200

@meta_bp.route("/api/keywords", methods=["GET"])
def list_keywords():
    keywords = Keyword.query.order_by(Keyword.term).all()
    return jsonify([{"id": k.id, "term": k.term} for k in keywords]), 200

@meta_bp.route("/api/authors", methods=["GET"])
def list_authors():
    authors = Author.query.order_by(Author.last_name).all()
    return jsonify([{"id": a.id, "first_name": a.first_name, "last_name": a.last_name, "email": a.email} for a in authors]), 200

@meta_bp.route("/api/advisers", methods=["GET"])
def list_advisers():
    advisers = Adviser.query.order_by(Adviser.last_name).all()
    return jsonify([{"id": a.id, "first_name": a.first_name, "last_name": a.last_name, "email": a.email} for a in advisers]), 200
