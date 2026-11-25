"""FastAPI application factory."""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException

from .env import load_env

load_env()

tags_metadata = [
    {"name": "System", "description": "Health check and database status"},
    {"name": "Auth", "description": "User authentication and registration"},
    {"name": "Users", "description": "User management (admin only)"},
    {"name": "Theses", "description": "Thesis CRUD operations"},
    {"name": "Metadata", "description": "Programs, years, categories, keywords, authors, advisers"},
    {"name": "Search", "description": "Semantic search and recommendations"},
    {"name": "Upload", "description": "PDF upload and OCR"},
    {"name": "Embeddings", "description": "AI embedding generation"},
    {"name": "Dashboard", "description": "Admin and faculty dashboard data"},
    {"name": "Admin", "description": "Endpoints restricted to administrators (admin only)"},
]

@asynccontextmanager
async def _lifespan(_app):
    """Warm the embedding model in the background at startup."""
    # The documented endpoint list is frozen in backend/api_contract.json. A
    # drifted route set must fail loudly here instead of quietly publishing a
    # different Swagger UI. See scripts/check_api_contract.py.
    from .api_lock import assert_surface_locked

    assert_surface_locked(_app)
    try:
        from . import models as _db

        # A batch import is a daemon thread. If the process was restarted
        # mid-import, that job can never finish; mark it failed instead of
        # leaving the UI polling a "running" row forever.
        _db.mark_stale_import_jobs()
    except Exception:
        pass
    try:
        from .services.embeddings import embedding_service

        embedding_service.warm_up()
    except Exception:
        pass
    yield


app = FastAPI(
    title="CScholar API",
    version="1.0.0",
    openapi_tags=tags_metadata,
    docs_url=None,
    redoc_url=None,
    lifespan=_lifespan,
)


def _order_example_keys(node):
    """Sort every schema example by its declared property order.

    Pydantic emits ``json_schema_extra`` examples with keys alphabetically
    sorted, which made Swagger show ``password`` before ``email``/``username``.
    Swagger UI should read exactly like the Flutter form, so reorder example
    objects to match the model's field order instead.
    """
    if isinstance(node, list):
        for item in node:
            _order_example_keys(item)
        return
    if not isinstance(node, dict):
        return
    example = node.get("example")
    properties = node.get("properties")
    if isinstance(example, dict) and isinstance(properties, dict):
        ordered = {key: example[key] for key in properties if key in example}
        ordered.update({key: value for key, value in example.items() if key not in ordered})
        node["example"] = ordered
    for value in node.values():
        _order_example_keys(value)


def _fix_binary_formats(node):
    """Convert JSON-Schema-2020-12 style ``contentMediaType`` markers into
    OpenAPI 3.0 ``format: binary``.

    Newer Pydantic v2 releases emit ``{"type": "string",
    "contentMediaType": "application/octet-stream"}`` for ``UploadFile``
    fields, but Swagger UI only renders the file-picker control for the
    OpenAPI 3.0 style ``{"type": "string", "format": "binary"}``. Without
    this translation the docs show a plain text box for file uploads.
    """
    if isinstance(node, dict):
        if node.get("type") == "string" and "contentMediaType" in node:
            node["format"] = "binary"
            del node["contentMediaType"]
        for value in node.values():
            _fix_binary_formats(value)
    elif isinstance(node, list):
        for item in node:
            _fix_binary_formats(item)


_METHOD_ORDER = {"get": 0, "post": 1, "put": 2, "patch": 3, "delete": 4}


def _path_group(path):
    """Return the resource bucket used to keep related routes together."""
    parts = [part for part in path.split("/") if part]
    if parts and parts[0] == "api":
        parts = parts[1:]
    return parts[0] if parts else path


def _order_paths(schema):
    """Group related routes and list CRUD methods as GET, POST, PUT, DELETE.

    Swagger UI renders operations in the order they appear in the OpenAPI
    document, so reordering ``paths`` (and the methods inside each path) is
    what makes the UI read like ``GET programs``, ``POST programs``,
    ``PUT programs``, ``DELETE programs``.
    """
    paths = schema.get("paths")
    if not isinstance(paths, dict):
        return

    group_order = {}
    path_order = {}
    for index, path in enumerate(paths):
        group_order.setdefault(_path_group(path), len(group_order))
        path_order[path] = index

    ordered_paths = {}
    for path in sorted(
        paths,
        key=lambda p: (
            group_order[_path_group(p)],
            len([part for part in p.split("/") if part]),
            path_order[p],
        ),
    ):
        methods = paths[path]
        if not isinstance(methods, dict):
            ordered_paths[path] = methods
            continue
        known = {
            method: op
            for method, op in methods.items()
            if method.lower() in _METHOD_ORDER
        }
        unknown = {
            method: op
            for method, op in methods.items()
            if method.lower() not in _METHOD_ORDER
        }
        ordered_paths[path] = dict(
            sorted(
                known.items(),
                key=lambda item: (_METHOD_ORDER[item[0].lower()], item[0]),
            )
        )
        ordered_paths[path].update(unknown)

    schema["paths"] = ordered_paths


def _flatten_routes(router):
    '''Recursively collect APIRoute objects, including included routers.'''
    out = []
    for r in getattr(router, "routes", []) or []:
        if type(r).__name__ == "_IncludedRouter":
            out.extend(_flatten_routes(r.original_router))
        elif hasattr(r, "endpoint") and hasattr(r, "methods"):
            out.append(r)
        elif hasattr(r, "routes"):
            out.extend(_flatten_routes(r))
    return out


def _admin_route_keys():
    '''Return set of (METHOD, path) pairs whose handler requires admin access.'''
    try:
        from .auth import admin_required
    except Exception:
        admin_required = None
    keys = set()
    for r in _flatten_routes(app.router):
        deps = []
        for d in getattr(r, "dependencies", []) or []:
            dep = getattr(d, "dependency", None)
            if dep is not None:
                deps.append(dep)
        is_admin = False
        for dep in deps:
            if dep is admin_required or getattr(dep, "__name__", None) == "admin_required":
                is_admin = True
                break
        if is_admin:
            for method in getattr(r, "methods", []) or []:
                keys.add((str(method).upper(), getattr(r, "path", None)))
    return keys


def _role_suffix(roles):
    """Human-readable summary suffix for the roles allowed on an endpoint."""
    if not roles:
        return None
    if len(roles) == 1:
        return f"({roles[0]} only)"
    return "(" + " & ".join(roles) + " only)"


def _role_description(roles):
    """Short description explaining which account types may call an endpoint."""
    if roles == ["admin"]:
        return "This endpoint requires an administrator account (admin only)."
    if roles == ["faculty"]:
        return "This endpoint requires a faculty account (faculty only)."
    return f"This endpoint is restricted to {' & '.join(roles)} accounts."


def _custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        tags=tags_metadata,
    )
    _order_example_keys(schema)
    _fix_binary_formats(schema)

    # Append a role indicator to summaries, e.g. "Update Author (admin only)" or
    # "Create Thesis (admin or faculty only)". Strictly admin endpoints are
    # detected from the admin_required dependency; mixed-role endpoints declare
    # their roles explicitly with openapi_extra={"x-required-roles": [...]}.
    admin_keys = _admin_route_keys()
    for path, methods in (schema.get("paths") or {}).items():
        if not isinstance(methods, dict):
            continue
        for method, op in list(methods.items()):
            if not isinstance(op, dict):
                continue
            explicit_roles = op.get("x-required-roles")
            if explicit_roles:
                roles = [str(r).strip().lower() for r in explicit_roles if str(r).strip()]
            elif (str(method).upper(), path) in admin_keys:
                roles = ["admin"]
            else:
                continue
            if not roles:
                continue
            if roles == ["admin"]:
                op["x-admin-only"] = True
            op["x-required-roles"] = roles
            suffix = _role_suffix(roles)
            original_summary = op.get("summary")
            if isinstance(original_summary, str) and original_summary.strip():
                if suffix.lower() not in original_summary.lower():
                    op["summary"] = original_summary.rstrip() + " " + suffix
            else:
                op["summary"] = suffix[1:-1]
            desc = op.get("description")
            if not isinstance(desc, str) or suffix.lower() not in desc.lower():
                prefix = _role_description(roles)
                op["description"] = (prefix + (("\n\n" + desc) if isinstance(desc, str) and desc else "")).strip()

    _order_paths(schema)

    app.openapi_schema = schema
    return schema


app.openapi = _custom_openapi

# -- Config ----------------------------------------------------------------
SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me")
if SECRET_KEY == "dev-change-me":
    print("WARNING: using default dev SECRET_KEY - set SECRET_KEY in production!")
DEBUG = os.getenv("DEBUG", "0") == "1"

# -- CORS ------------------------------------------------------------------
_cors_origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins if _cors_origins else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -- Exception handlers ----------------------------------------------------
@app.exception_handler(HTTPException)
async def http_exc_handler(request: Request, exc: HTTPException):
    detail = exc.detail
    if isinstance(detail, str):
        return JSONResponse({"error": detail}, status_code=exc.status_code)
    if isinstance(detail, dict):
        return JSONResponse(detail, status_code=exc.status_code)
    return JSONResponse({"error": str(detail)}, status_code=exc.status_code)


@app.exception_handler(404)
async def not_found(request: Request, exc):
    return JSONResponse({"error": "Not found"}, status_code=404)


@app.exception_handler(500)
async def internal_error(request: Request, exc):
    return JSONResponse({"error": "Internal server error"}, status_code=500)


# -- Routers ---------------------------------------------------------------
from .routes import (
    health,
    db_test,
    auth,
    thesis,
    meta,
    upload,
    ocr,
    embedding,
    swagger,
    import_batch,
)

app.include_router(health.router)
app.include_router(db_test.router)
app.include_router(auth.router)
app.include_router(thesis.router)
app.include_router(meta.router)
app.include_router(upload.router)
app.include_router(ocr.router)
app.include_router(embedding.router)
app.include_router(import_batch.router)
app.include_router(swagger.router)


# Custom /docs and /swagger.json are registered by the swagger router.