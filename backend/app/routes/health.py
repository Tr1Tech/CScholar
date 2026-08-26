"""Health-check endpoint.

Used to verify the API is running. More blueprints (auth, theses,
search, etc.) will be added in later phases.
"""

from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__)


@health_bp.route("/api/health", methods=["GET"])
def health():
    return (
        jsonify(
            {
                "status": "ok",
                "service": "CScholar API",
                "project": "capstopn (CEIT thesis repository)",
                "phase": 1,
            }
        ),
        200,
    )
