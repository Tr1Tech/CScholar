"""Application factory for the CScholar (capstopn) backend.

This module wires together the Flask app, extensions (CORS, SQLAlchemy),
and the route blueprints. Keeping the app inside a factory function makes it
easy to test and to configure differently per environment later.
"""

from flask import Flask

from .config import Config
from .extensions import cors, db
from .routes import db_test_bp, health_bp


def create_app(config_class=Config):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions with the app
    cors.init_app(app)
    db.init_app(app)

    # Register route blueprints
    app.register_blueprint(health_bp)
    app.register_blueprint(db_test_bp)

    return app
