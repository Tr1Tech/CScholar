"""DB connectivity smoke test (Phase 3)."""

from fastapi import APIRouter
from ..extensions import db_test as run_db_test

router = APIRouter(tags=["System"])


@router.get("/api/db-test")
def db_test_endpoint():
    return run_db_test()