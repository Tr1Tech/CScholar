"""Health-check endpoint."""

from fastapi import APIRouter

router = APIRouter(tags=["System"])


@router.get("/health")
def health_root():
    return {"status": "ok"}


@router.get("/api/health")
def health():
    return {
        "status": "ok",
        "service": "CScholar API",
        "project": "cscholar (CEIT thesis repository)",
        "phase": 1,
    }
