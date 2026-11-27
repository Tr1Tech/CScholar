"""Append-only security audit trail.

Writes one row to ``ceit_repo.security_audit_log`` for events that the domain
tables cannot record: sign-ins, account changes, taxonomy edits, imports, and
other admin mutations.

The writer is deliberately best-effort. An audit failure must never block a
sign-in or a content action, so the error is logged to the server log and the
caller continues. The table is append-only by convention: there is no update
or delete path.
"""

import logging

from psycopg.types.json import Jsonb

from .extensions import get_conn, put_conn

logger = logging.getLogger(__name__)


def _text(value, limit):
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    return text[:limit]


def _client_info(request):
    if request is None:
        return None, None
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        ip = forwarded.split(",", 1)[0].strip()
    else:
        ip = request.client.host if request.client else None
    agent = request.headers.get("user-agent")
    return _text(ip, 45), _text(agent, 255)


def log_security_event(
    action,
    *,
    actor=None,
    request=None,
    actor_username=None,
    actor_role=None,
    entity_type=None,
    entity_id=None,
    summary=None,
    details=None,
):
    """Persist one security event. Never raises into the request path."""
    try:
        actor_id = actor.get("id") if actor else None
        username = _text(actor_username or (actor.get("username") if actor else None), 120)
        role = _text(actor_role or (actor.get("role") if actor else None), 20)
        ip_address, user_agent = _client_info(request)
        payload = Jsonb(details) if isinstance(details, (dict, list)) else None

        conn = get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO security_audit_log "
                    "(actor_id, actor_username, actor_role, action, entity_type, "
                    " entity_id, summary, details, ip_address, user_agent) "
                    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                    (
                        actor_id,
                        username,
                        role,
                        _text(action, 50) or "unknown",
                        _text(entity_type, 30),
                        entity_id,
                        _text(summary, 500),
                        payload,
                        ip_address,
                        user_agent,
                    ),
                )
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            put_conn(conn)
    except Exception:
        logger.exception("Could not write security audit event: %s", action)
