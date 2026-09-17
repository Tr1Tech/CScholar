"""Connection pooling with raw psycopg (v3)."""

import os
import psycopg_pool

_pool = None


def get_pool():
    """Get or create the connection pool."""
    global _pool
    if _pool is None:
        conninfo = (
            f"host={os.getenv('DB_HOST', 'localhost')} "
            f"port={os.getenv('DB_PORT', '5432')} "
            f"dbname={os.getenv('DB_NAME', 'cscholar')} "
            f"user={os.getenv('DB_USER', 'postgres')} "
            f"password={os.getenv('DB_PASSWORD', 'radj062406')} "
            f"options='-c search_path=ceit_repo'"
        )
        _pool = psycopg_pool.ConnectionPool(conninfo, min_size=1, max_size=20)
    return _pool


def get_conn():
    """Get a connection from the pool."""
    return get_pool().getconn()


def put_conn(conn):
    """Return a connection to the pool."""
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
        put_conn(conn)
    except Exception as e:
        result["error"] = str(e)
    return result


from flask_cors import CORS

cors = CORS()
db = None  # re-exported for route modules that do `from .. import db`
