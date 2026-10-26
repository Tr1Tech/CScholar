"""Health-check endpoint."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/api/health")
def health():
    return {
        "status": "ok",
        "service": "CScholar API",
        "project": "cscholar (CEIT thesis repository)",
        "phase": 1,
    }