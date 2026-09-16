"""Flask application factory — raw psycopg2, no ORM."""

import os
from flask import Flask, jsonify
from .extensions import cors, db_test


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # ── Config ──────────────────────────────────────────────────────────────
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-change-me")
    app.config["FLASK_DEBUG"] = os.getenv("FLASK_DEBUG", "1") == "1"

    # ── CORS ────────────────────────────────────────────────────────────────
    cors.init_app(app, origins="*")

    # ── Blueprints ───────────────────────────────────────────────────────────
    from .routes import db_test_bp, health_bp, auth_bp, thesis_bp, meta_bp, upload_bp, ocr_bp, embedding_bp

    app.register_blueprint(db_test_bp)
    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(thesis_bp)
    app.register_blueprint(meta_bp)
    app.register_blueprint(upload_bp)
    app.register_blueprint(ocr_bp)
    app.register_blueprint(embedding_bp)

    # ── Error handlers ──────────────────────────────────────────────────────
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Not found"}), 404

    @app.errorhandler(500)
    def internal_error(e):
        return jsonify({"error": "Internal server error"}), 500

    return app
