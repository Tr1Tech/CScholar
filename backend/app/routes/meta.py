"""Meta routes — programs, academic years, categories, keywords, authors, advisers."""

from flask import Blueprint, jsonify
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
