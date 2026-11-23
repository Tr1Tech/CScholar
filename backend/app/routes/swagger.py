"""Swagger UI router for API documentation.

The spec is generated from the FastAPI routes and Pydantic request models.
There is deliberately no hand-maintained copy: the same document powers both
``/docs`` (via ``/openapi.json``) and ``/swagger.json``, so the documentation
cannot drift from the fields the frontend actually sends.
"""

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, JSONResponse

from ..api_lock import load_contract

router = APIRouter()


@router.get("/docs", response_class=HTMLResponse, include_in_schema=False)
def swagger_ui():
    # The endpoint list is frozen. Say so in the UI so nobody treats the page as
    # an open invitation to add routes; the count comes from the contract file.
    contract = load_contract() or {}
    count = contract.get("operation_count")
    badge = f"{count} endpoints &middot; locked" if count else "API surface"
    html = """<!DOCTYPE html>
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
    .topbar .lock { margin-left: auto; opacity: 1; font-weight: 600; background: rgba(255,255,255,0.14); border: 1px solid rgba(255,255,255,0.25); padding: 3px 10px; border-radius: 999px; }
  </style>
</head>
<body>
  <div class="topbar"><h1>CScholar API</h1><span>Semantic Search and AI-Powered Recommendation System for CSU CEIT</span><span class="lock">{{LOCK_BADGE}}</span></div>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5.10.3/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: '/openapi.json?_=' + Date.now(),
      dom_id: '#swagger-ui',
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      deepLinking: true,
      docExpansion: "list",
      tryItOutEnabled: true,
    });
  </script>
</body>
</html>""".replace("{{LOCK_BADGE}}", badge)
    return HTMLResponse(content=html)


@router.get("/swagger.json", include_in_schema=False)
def swagger_json(request: Request):
    """Return the generated OpenAPI document (same content as /openapi.json)."""
    return JSONResponse(request.app.openapi())
