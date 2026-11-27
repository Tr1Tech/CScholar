"""Admin security audit log read route.

One read endpoint. The table is written by ``app.audit.log_security_event``;
there is no create, update, or delete route.
"""

from datetime import datetime, time

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from .. import models as db
from ..auth import admin_required

router = APIRouter(tags=["Audit"])


def _parse_moment(raw, *, end_of_day=False):
    if raw is None or not str(raw).strip():
        return None
    text = str(raw).strip()
    try:
        if len(text) == 10:
            day = datetime.strptime(text, "%Y-%m-%d").date()
            return datetime.combine(day, time.max if end_of_day else time.min)
        return datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="date_from and date_to must be ISO dates (YYYY-MM-DD).",
        )


@router.get(
    "/api/admin/audit-logs",
    dependencies=[Depends(admin_required)],
    openapi_extra={"x-required-roles": ["admin"]},
)
def list_audit_logs(
    request: Request,
    page: int = Query(1),
    limit: int = Query(25),
    action: str = Query(None),
    actor_id: int = Query(None),
    date_from: str = Query(None),
    date_to: str = Query(None),
):
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be 1 or greater")
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")

    items, total = db.list_security_audit_logs(
        page=page,
        limit=limit,
        action=(action or "").strip() or None,
        actor_id=actor_id,
        date_from=_parse_moment(date_from),
        date_to=_parse_moment(date_to, end_of_day=True),
    )
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
    }
