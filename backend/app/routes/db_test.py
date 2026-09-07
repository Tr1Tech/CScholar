"""DB connectivity smoke test (Phase 3).

Returns a small payload proving Flask can reach the live database,
list the schemas/tables we expect, and count a few rows from seed data.
"""

from __future__ import annotations

import datetime
import os

from flask import Blueprint, jsonify

from ..extensions import db
from ..models import Program, Thesis, User

db_test_bp = Blueprint("db_test", __name__)


@db_test_bp.get("/api/db-test")
def db_test():
    """Quick live-DB health check for CScholar."""
    result: dict = {
        "phase": 3,
        "project": "CScholar (CEIT thesis repository)",
        "database_url": _masked_database_url(),
        "checked_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }

    try:
        # 1) raw connection + schema awareness
        with db.engine.connect() as conn:
            search_path = conn.exec_driver_sql("SHOW search_path").scalar()
            schemas = [
                row[0]
                for row in conn.exec_driver_sql(
                    "SELECT nspname FROM pg_namespace WHERE nspname NOT IN ('pg_catalog','information_schema')"
                ).fetchall()
            ]
        result["search_path"] = search_path
        result["schemas"] = schemas
        result["connection"] = "ok"

        # 2) ORM counts (from ceit_repo tables)
        result["counts"] = {
            "users": User.query.count(),
            "programs": Program.query.count(),
            "theses": Thesis.query.count(),
        }

        # 3) sample theses (lightweight — only 3 seed rows)
        sample = (
            db.session.query(Thesis.id, Thesis.title, Thesis.research_type)
            .order_by(Thesis.id.asc())
            .limit(5)
            .all()
        )
        result["sample_theses"] = [
            {"id": row.id, "title": row.title, "research_type": row.research_type}
            for row in sample
        ]

        result["status"] = "ok"

    except Exception as exc:  # pragma: no cover - safety net
        result["status"] = "error"
        result["error"] = f"{type(exc).__name__}: {exc}"

    return jsonify(result)


def _masked_database_url() -> str:
    """Show DB host/name without leaking the password."""
    url = os.getenv("DATABASE_URL", "")
    # Rough mask: keep user + host + db, hide password
    try:
        # postgresql://USER:PASSWORD@HOST:PORT/DB
        prefix, rest = url.split("://", 1)
        creds_host, dbname = rest.split("/", 1)
        user_pass, host_port = creds_host.rsplit("@", 1)
        user = user_pass.split(":")[0]
        return f"{prefix}://{user}:***@{host_port}/{dbname}"
    except Exception:
        return url or "(not set)"
