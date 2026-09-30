"""Flask application factory — raw psycopg2, no ORM."""

import os
from dotenv import load_dotenv
from flask import Flask, jsonify
from .extensions import cors

load_dotenv()


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # ── Config ──────────────────────────────────────────────────────────────
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-change-me")
    if app.config["SECRET_KEY"] == "dev-change-me":
        print("WARNING: using default dev SECRET_KEY — set SECRET_KEY in production!")
    app.config["FLASK_DEBUG"] = os.getenv("FLASK_DEBUG", "0") == "1"
    # Guard against unbounded uploads (upload/ocr routes also check size).
    app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024  # 50 MB

    # ── CORS ────────────────────────────────────────────────────────────────
    # Comma-separated allowlist, e.g. CORS_ORIGINS=https://cscholar.example,http://localhost:8080
    _cors_origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
    if _cors_origins:
        cors.init_app(app, origins=_cors_origins)
    else:
        cors.init_app(app, origins="*")

    # ── Blueprints ───────────────────────────────────────────────────────────
    from .routes import db_test_bp, health_bp, auth_bp, thesis_bp, meta_bp, upload_bp, ocr_bp, embedding_bp, swagger_bp

    app.register_blueprint(db_test_bp)
    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(thesis_bp)
    app.register_blueprint(meta_bp)
    app.register_blueprint(upload_bp)
    app.register_blueprint(ocr_bp)
    app.register_blueprint(embedding_bp)
    app.register_blueprint(swagger_bp)

    # ── Swagger UI ─────────────────────────────────────────────────────────
    @app.route("/docs")
    def swagger_ui():
        return """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>CScholar API Docs</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.10.3/swagger-ui.css">
  <style>
    body { margin: 0; }
    .topbar { background: #033F15; color: white; padding: 12px 24px; font-family: sans-serif; display: flex; align-items: center; gap: 12px; }
    .topbar h1 { margin: 0; font-size: 18px; font-weight: 700; }
    .topbar span { font-size: 13px; opacity: 0.8; }
    .swagger-ui .info { background: #F8FAF9; padding: 20px; margin: 0; border-bottom: 1px solid #E2E8F0; }
    .swagger-ui .info .title { color: #033F15; }
    .swagger-ui .btn.authorize { background: #033F15; border-color: #033F15; }
    .swagger-ui .btn.authorize:hover { background: #022B0E; }
    .swagger-ui .opblock.opblock-get { border-color: #DCFCE7; background: #F0FDF4; }
    .swagger-ui .opblock.opblock-post { border-color: #DBEAFE; background: #EFF6FF; }
    .swagger-ui .opblock.opblock-put { border-color: #FEF3C7; background: #FFFBEB; }
    .swagger-ui .opblock.opblock-delete { border-color: #FEE2E2; background: #FEF2F2; }
  </style>
</head>
<body>
  <div class="topbar">
    <h1>CScholar API</h1>
    <span>Semantic Search and AI-Powered Recommendation System for CSU CEIT</span>
  </div>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5.10.3/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: '/swagger.json',
      dom_id: '#swagger-ui',
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      tagsSorter: "alpha",
      operationsSorter: (a, b) => {
        const pathA = a.get("path");
        const pathB = b.get("path");
        if (pathA !== pathB) return pathA.localeCompare(pathB);
        const order = { get: 0, post: 1, put: 2, delete: 3, patch: 4, options: 5, head: 6, trace: 7 };
        return (order[a.get("method")] ?? 99) - (order[b.get("method")] ?? 99);
      },
      deepLinking: true,
      docExpansion: "list",
      tryItOutEnabled: true,
    });
  </script>
</body>
</html>
        """

    # ── Error handlers ──────────────────────────────────────────────────────
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Not found"}), 404

    @app.errorhandler(500)
    def internal_error(e):
        return jsonify({"error": "Internal server error"}), 500

    return app
