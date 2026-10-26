"""FastAPI application factory."""

import os
from dotenv import load_dotenv

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException

from .config import Config

load_dotenv()

app = FastAPI(title="CScholar API")

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
from .routes import health, db_test, auth, thesis, meta, upload, ocr, embedding, swagger

app.include_router(health.router)
app.include_router(db_test.router)
app.include_router(auth.router)
app.include_router(thesis.router)
app.include_router(meta.router)
app.include_router(upload.router)
app.include_router(ocr.router)
app.include_router(embedding.router)
app.include_router(swagger.router)


# Custom /docs and /swagger.json are registered by the swagger router.