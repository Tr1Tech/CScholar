"""DB connectivity smoke test (Phase 3)."""

from flask import Blueprint, jsonify
from ..extensions import db_test

db_test_bp = Blueprint("db_test", __name__)


@db_test_bp.get("/api/db-test")
def db_test_endpoint():
    """Quick live-DB health check for CScholar (raw psycopg)."""
    return jsonify(db_test()), 200
