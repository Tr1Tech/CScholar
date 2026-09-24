"""Connection pooling with raw psycopg (v3)."""

import os
import threading
from dotenv import load_dotenv
import psycopg_pool

load_dotenv()

_pool = None
_pool_lock = threading.Lock()


def _configure_conn(conn):
    """Run once per new pooled connection — replaces options='-c search_path=...'."""
    with conn.cursor() as cur:
        cur.execute("SET search_path TO ceit_repo")
    # psycopg3 pools run with autocommit=False: without this commit the
    # connection sits INTRANS and the pool discards it ("left in status
    # INTRANS by configure function"). Commit only the SET, keep the
    # connection's normal transactional behavior for app queries.
    conn.commit()


def get_pool():
    """Get or create the connection pool (thread-safe singleton)."""
    global _pool
    # Double-checked locking: Flask's threaded dev server fires parallel
    # first requests; without the lock two threads each create a pool
    # (pool-1 + pool-2) and connections get returned to the wrong one:
    # "can't return connection to pool 'pool-2', it comes from pool 'pool-1'".
    if _pool is None:
        with _pool_lock:
            if _pool is None:
                # NOTE: no options='-c search_path=...' here — some libpq/psycopg
                # builds reject it with: invalid connection option "search_path".
                # search_path is set per-connection in _configure_conn() + get_conn().
                # Prefer DATABASE_URL when set (your .env uses it); else split DB_* vars.
                conninfo = os.getenv("DATABASE_URL") or (
                    f"host={os.getenv('DB_HOST', 'localhost')} "
                    f"port={os.getenv('DB_PORT', '5432')} "
                    f"dbname={os.getenv('DB_NAME', 'cscholar')} "
                    f"user={os.getenv('DB_USER', 'postgres')} "
                    f"password={os.getenv('DB_PASSWORD', '')}"
                )
                _pool = psycopg_pool.ConnectionPool(
                    conninfo, min_size=1, max_size=20,
                    configure=_configure_conn, timeout=10,
                )
    return _pool


def get_conn():
    """Get a connection from the pool (search_path pinned to ceit_repo)."""
    conn = get_pool().getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("SET search_path TO ceit_repo")
        conn.commit()
    except Exception:
        # If the connection is dead, return it and let the caller see the error.
        try:
            conn.rollback()
        except Exception:
            pass
    return conn


def put_conn(conn):
    """Return a connection to the pool."""
    # Read-only paths (list_theses, etc.) leave an idle transaction open
    # under autocommit=False. Roll it back first so the pool gets a clean
    # IDLE connection instead of logging "rolling back returned connection".
    # Safe: every write path commits explicitly before put_conn().
    try:
        conn.rollback()
    except Exception:
        pass
    get_pool().putconn(conn)


def _masked_database_url():
    """Mask the password for logging/debugging."""
    return f"postgresql://{os.getenv('DB_USER', 'postgres')}:****@{os.getenv('DB_HOST', 'localhost')}:{os.getenv('DB_PORT', '5432')}/{os.getenv('DB_NAME', 'cscholar')}"


def db_test():
    """Quick live-DB health check for CScholar."""
    import datetime
    result = {
        "project": "CScholar (CEIT thesis repository, raw psycopg)",
        "database_url": _masked_database_url(),
        "checked_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    try:
        conn = get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute("SHOW search_path")
                search_path = cur.fetchone()[0]
                result["search_path"] = search_path
                result["connection"] = "ok"
                cur.execute(
                    "SELECT nspname FROM pg_namespace "
                    "WHERE nspname NOT IN ('pg_catalog','information_schema')"
                )
                result["schemas"] = [row[0] for row in cur.fetchall()]
                cur.execute("SELECT count(*) FROM users")
                result["counts"] = {"users": cur.fetchone()[0]}
                cur.execute("SELECT count(*) FROM programs")
                result["counts"]["programs"] = cur.fetchone()[0]
                cur.execute("SELECT count(*) FROM theses")
                result["counts"]["theses"] = cur.fetchone()[0]
        finally:
            put_conn(conn)
    except Exception as e:
        result["error"] = str(e)
    return result


from flask_cors import CORS

cors = CORS()
db = None  # re-exported for route modules that do `from .. import db`
