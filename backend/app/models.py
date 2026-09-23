"""Simple data access helpers — raw psycopg2 queries, no ORM.

Functions return plain dicts or None.
"""

from .extensions import get_conn, put_conn


# ── Users ───────────────────────────────────────────────────────────────────

def get_user_by_id(user_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, email, password_hash, role, is_active, created_at, updated_at "
                "FROM users WHERE id = %s",
                (user_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "username": row[1],
                "email": row[2],
                "password_hash": row[3],
                "role": row[4],
                "is_active": row[5],
                "created_at": row[6],
                "updated_at": row[7],
            }
    finally:
        put_conn(conn)


def get_user_by_username(username):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, email, password_hash, role, is_active, created_at, updated_at "
                "FROM users WHERE username = %s",
                (username,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "username": row[1],
                "email": row[2],
                "password_hash": row[3],
                "role": row[4],
                "is_active": row[5],
                "created_at": row[6],
                "updated_at": row[7],
            }
    finally:
        put_conn(conn)


def get_user_by_email(email):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, email, password_hash, role, is_active, created_at, updated_at "
                "FROM users WHERE email = %s",
                (email.lower(),),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "username": row[1],
                "email": row[2],
                "password_hash": row[3],
                "role": row[4],
                "is_active": row[5],
                "created_at": row[6],
                "updated_at": row[7],
            }
    finally:
        put_conn(conn)


def find_user(login_id):
    """Find user by username or email."""
    user = get_user_by_username(login_id)
    if not user:
        user = get_user_by_email(login_id)
    return user


def create_user(username, email, password_hash, role="student"):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO users (username, email, password_hash, role, is_active) "
                "VALUES (%s, %s, %s, %s, TRUE) RETURNING id",
                (username, email.lower(), password_hash, role),
            )
            user_id = cur.fetchone()[0]
        conn.commit()
        return get_user_by_id(user_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def update_user_role(user_id, new_role):
    """Update a user's role."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE users SET role = %s WHERE id = %s", (new_role, user_id))
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def user_exists(username, email):
    """Check if username or email already exists."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT username, email FROM users WHERE username = %s OR email = %s",
                (username, email.lower()),
            )
            return cur.fetchall()
    finally:
        put_conn(conn)


def get_all_users():
    """Return all users with id, username, email, role, is_active, created_at."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, email, role, is_active, created_at "
                "FROM users ORDER BY created_at DESC"
            )
            return [
                {
                    "id": row[0],
                    "username": row[1],
                    "email": row[2],
                    "role": row[3],
                    "is_active": row[4],
                    "created_at": row[5].isoformat() if row[5] else None,
                }
                for row in cur.fetchall()
            ]
    finally:
        put_conn(conn)


# ── Theses ─────────────────────────────────────────────────────────────────

def serialize_thesis(row, detailed=False):
    """Convert a DB row to a thesis dict."""
    data = {
        "id": row[0],
        "title": row[1],
        "abstract": row[2],
        "research_type": row[3],
        "program_id": row[4],
        "program": {
            "id": row[5],
            "name": row[6],
            "code": row[7],
            "description": row[8],
            "created_at": row[9].isoformat() if row[9] else None,
        } if row[5] else None,
        "academic_year_id": row[10],
        "academic_year": {
            "id": row[11],
            "name": row[12],
            "start_year": row[13],
            "end_year": row[14],
            "is_active": row[15],
            "created_at": row[16].isoformat() if row[16] else None,
        } if row[11] else None,
        "status": row[17],
        "creator_id": row[18],
        "created_at": row[19].isoformat() if row[19] else None,
        "updated_at": row[20].isoformat() if row[20] else None,
        "pdf_url": row[21] if len(row) > 21 else None,
    }
    return data


def _load_thesis_relations(cur, thesis_id):
    """Load authors, advisers, categories, and keywords for one thesis."""
    thesis_id = int(thesis_id)
    cur.execute(
        "SELECT a.id, a.first_name, a.middle_name, a.last_name, a.email, a.created_at "
        "FROM thesis_authors ta JOIN authors a ON ta.author_id = a.id "
        "WHERE ta.thesis_id = %s ORDER BY ta.order_index",
        (thesis_id,),
    )
    authors = [
        {
            "id": r[0],
            "first_name": r[1],
            "middle_name": r[2],
            "last_name": r[3],
            "email": r[4],
            "created_at": r[5].isoformat() if r[5] else None,
        }
        for r in cur.fetchall()
    ]

    cur.execute(
        "SELECT a.id, a.first_name, a.middle_name, a.last_name, a.email, a.created_at "
        "FROM thesis_advisers ta JOIN advisers a ON ta.adviser_id = a.id "
        "WHERE ta.thesis_id = %s",
        (thesis_id,),
    )
    advisers = [
        {
            "id": r[0],
            "first_name": r[1],
            "middle_name": r[2],
            "last_name": r[3],
            "email": r[4],
            "created_at": r[5].isoformat() if r[5] else None,
        }
        for r in cur.fetchall()
    ]

    cur.execute(
        "SELECT c.id, c.name, c.description, c.created_at "
        "FROM thesis_categories tc JOIN categories c ON tc.category_id = c.id "
        "WHERE tc.thesis_id = %s",
        (thesis_id,),
    )
    categories = [
        {
            "id": r[0],
            "name": r[1],
            "description": r[2],
            "created_at": r[3].isoformat() if r[3] else None,
        }
        for r in cur.fetchall()
    ]

    cur.execute(
        "SELECT k.id, k.term, k.created_at "
        "FROM thesis_keywords tk JOIN keywords k ON tk.keyword_id = k.id "
        "WHERE tk.thesis_id = %s",
        (thesis_id,),
    )
    keywords = [
        {
            "id": r[0],
            "term": r[1],
            "created_at": r[2].isoformat() if r[2] else None,
        }
        for r in cur.fetchall()
    ]

    return {"authors": authors, "advisers": advisers, "categories": categories, "keywords": keywords}


def _persist_thesis_relations(cur, thesis_id, author_ids=None, adviser_id=None, category_ids=None, keyword_terms=None):
    """Replace author/adviser/category/keyword links for a thesis."""
    if author_ids is not None:
        cur.execute("DELETE FROM thesis_authors WHERE thesis_id = %s", (thesis_id,))
        for idx, aid in enumerate(author_ids, start=1):
            cur.execute(
                "INSERT INTO thesis_authors (thesis_id, author_id, order_index) VALUES (%s, %s, %s) "
                "ON CONFLICT (thesis_id, author_id) DO UPDATE SET order_index = EXCLUDED.order_index",
                (thesis_id, int(aid), idx),
            )

    if adviser_id is not None:
        cur.execute("DELETE FROM thesis_advisers WHERE thesis_id = %s", (thesis_id,))
        cur.execute(
            "INSERT INTO thesis_advisers (thesis_id, adviser_id) VALUES (%s, %s) "
            "ON CONFLICT (thesis_id, adviser_id) DO NOTHING",
            (thesis_id, int(adviser_id)),
        )

    if category_ids is not None:
        cur.execute("DELETE FROM thesis_categories WHERE thesis_id = %s", (thesis_id,))
        for cid in category_ids:
            cur.execute(
                "INSERT INTO thesis_categories (thesis_id, category_id) VALUES (%s, %s) "
                "ON CONFLICT (thesis_id, category_id) DO NOTHING",
                (thesis_id, int(cid)),
            )

    if keyword_terms is not None:
        cur.execute("DELETE FROM thesis_keywords WHERE thesis_id = %s", (thesis_id,))
        for term in keyword_terms:
            term = str(term).strip()
            if not term:
                continue
            cur.execute("INSERT INTO keywords (term) VALUES (%s) ON CONFLICT (term) DO NOTHING", (term,))
            cur.execute("SELECT id FROM keywords WHERE term = %s", (term,))
            kid = cur.fetchone()[0]
            cur.execute(
                "INSERT INTO thesis_keywords (thesis_id, keyword_id) VALUES (%s, %s) "
                "ON CONFLICT (thesis_id, keyword_id) DO NOTHING",
                (thesis_id, kid),
            )


def get_thesis_by_id(thesis_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT t.id, t.title, t.abstract, t.research_type, t.program_id, "
                "       p.id, p.name, p.code, p.description, p.created_at, "
                "       t.academic_year_id, ay.id, ay.name, ay.start_year, ay.end_year, ay.is_active, ay.created_at, "
                "       t.status, t.creator_id, t.created_at, t.updated_at, t.pdf_url "
                "FROM theses t "
                "LEFT JOIN programs p ON t.program_id = p.id "
                "LEFT JOIN academic_years ay ON t.academic_year_id = ay.id "
                "WHERE t.id = %s",
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            data = serialize_thesis(row, detailed=True)
            data.update(_load_thesis_relations(cur, thesis_id))
            return data
    finally:
        put_conn(conn)


def list_theses(q=None, program_id=None, year_id=None, research_type=None, status=None, category_id=None, keyword=None, sort_by=None, page=1, per_page=20):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            conditions = []
            params = []
            if q:
                conditions.append(
                    "("
                    "t.title ILIKE %s OR t.abstract ILIKE %s "
                    "OR EXISTS (SELECT 1 FROM thesis_keywords tk2 JOIN keywords k2 ON tk2.keyword_id = k2.id WHERE tk2.thesis_id = t.id AND k2.term ILIKE %s) "
                    "OR EXISTS (SELECT 1 FROM thesis_authors ta2 JOIN authors a2 ON ta2.author_id = a2.id WHERE ta2.thesis_id = t.id AND (a2.first_name ILIKE %s OR a2.last_name ILIKE %s))"
                    ")"
                )
                pattern = f"%{q}%"
                params.extend([pattern, pattern, pattern, pattern, pattern])
            if program_id:
                conditions.append("t.program_id = %s")
                params.append(program_id)
            if year_id:
                conditions.append("t.academic_year_id = %s")
                params.append(year_id)
            if research_type:
                conditions.append("t.research_type = %s")
                params.append(research_type)
            if category_id:
                conditions.append("EXISTS (SELECT 1 FROM thesis_categories tc WHERE tc.thesis_id = t.id AND tc.category_id = %s)")
                params.append(category_id)
            if keyword:
                conditions.append("EXISTS (SELECT 1 FROM thesis_keywords tk JOIN keywords k ON tk.keyword_id = k.id WHERE tk.thesis_id = t.id AND k.term ILIKE %s)")
                params.append(f"%{keyword}%")
            if status:
                if isinstance(status, list):
                    conditions.append("t.status = ANY(%s)")
                    params.append(status)
                else:
                    conditions.append("t.status = %s")
                    params.append(status)

            order_by_sql = "t.created_at DESC"
            if sort_by:
                sb = str(sort_by).strip().lower()
                if sb in ("latest", "newest"):
                    order_by_sql = "t.created_at DESC"
                elif sb in ("oldest",):
                    order_by_sql = "t.created_at ASC"
                elif sb in ("title", "title (a-z)", "title_asc"):
                    order_by_sql = "t.title ASC"
                elif sb in ("title (z-a)", "title_desc"):
                    order_by_sql = "t.title DESC"
                elif sb in ("relevance", "highest similarity", "most viewed"):
                    order_by_sql = "t.created_at DESC"

            where = "WHERE " + " AND ".join(conditions) if conditions else ""
            offset = (page - 1) * per_page

            cur.execute(
                f"SELECT COUNT(*) FROM theses t {where}",
                params,
            )
            total = cur.fetchone()[0]

            cur.execute(
                f"SELECT t.id, t.title, t.abstract, t.research_type, t.program_id, "
                f"       p.id, p.name, p.code, p.description, p.created_at, "
                f"       t.academic_year_id, ay.id, ay.name, ay.start_year, ay.end_year, ay.is_active, ay.created_at, "
                f"       t.status, t.creator_id, t.created_at, t.updated_at, t.pdf_url "
                f"FROM theses t "
                f"LEFT JOIN programs p ON t.program_id = p.id "
                f"LEFT JOIN academic_years ay ON t.academic_year_id = ay.id "
                f"{where} "
                f"ORDER BY {order_by_sql} "
                f"LIMIT %s OFFSET %s",
                params + [per_page, offset],
            )
            rows = cur.fetchall()
            theses = [serialize_thesis(row) for row in rows]

            thesis_ids = [t["id"] for t in theses]
            if thesis_ids:
                for t in theses:
                    t.update(_load_thesis_relations(cur, t["id"]))

            return {
                "theses": theses,
                "total": total,
                "page": page,
                "per_page": per_page,
                "pages": (total + per_page - 1) // per_page,
            }
    finally:
        put_conn(conn)


def create_thesis(title, abstract, research_type, program_id, academic_year_id, creator_id, status="draft",
                  author_ids=None, adviser_id=None, category_ids=None, keyword_terms=None, pdf_url=None):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO theses (title, abstract, research_type, program_id, academic_year_id, status, creator_id, pdf_url) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id",
                (title, abstract, research_type, program_id, academic_year_id, status, creator_id, pdf_url),
            )
            thesis_id = cur.fetchone()[0]
            _persist_thesis_relations(
                cur, thesis_id,
                author_ids=author_ids,
                adviser_id=adviser_id,
                category_ids=category_ids,
                keyword_terms=keyword_terms,
            )
        conn.commit()
        return thesis_id
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def update_thesis(thesis_id, **kwargs):
    allowed = {"title", "abstract", "research_type", "program_id", "academic_year_id", "status", "pdf_url"}
    fields = {k: v for k, v in kwargs.items() if k in allowed and v is not None}

    author_ids = kwargs.get("author_ids") if isinstance(kwargs.get("author_ids"), list) else None
    adviser_id = kwargs.get("adviser_id")
    category_ids = kwargs.get("category_ids") if isinstance(kwargs.get("category_ids"), list) else None
    keyword_terms = kwargs.get("keyword_terms") if isinstance(kwargs.get("keyword_terms"), list) else None

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            if fields:
                set_clause = ", ".join(f"{k} = %s" for k in fields)
                params = list(fields.values()) + [thesis_id]
                cur.execute(f"UPDATE theses SET {set_clause} WHERE id = %s", params)

            _persist_thesis_relations(
                cur, thesis_id,
                author_ids=author_ids,
                adviser_id=adviser_id,
                category_ids=category_ids,
                keyword_terms=keyword_terms,
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def delete_thesis(thesis_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM theses WHERE id = %s", (thesis_id,))
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


# ── Meta lookups ───────────────────────────────────────────────────────────

def list_programs():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, code, description, created_at FROM programs ORDER BY name")
            return [
                {"id": r[0], "name": r[1], "code": r[2], "description": r[3], "created_at": r[4].isoformat() if r[4] else None}
                for r in cur.fetchall()
            ]
    finally:
        put_conn(conn)


def list_academic_years():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, start_year, end_year, is_active, created_at FROM academic_years ORDER BY start_year DESC")
            return [
                {"id": r[0], "name": r[1], "label": r[1], "start_year": r[2], "end_year": r[3], "is_active": r[4], "created_at": r[5].isoformat() if r[5] else None}
                for r in cur.fetchall()
            ]
    finally:
        put_conn(conn)


def list_categories():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, description, created_at FROM categories ORDER BY name")
            return [
                {"id": r[0], "name": r[1], "description": r[2], "created_at": r[3].isoformat() if r[3] else None}
                for r in cur.fetchall()
            ]
    finally:
        put_conn(conn)


def list_keywords():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, term FROM keywords ORDER BY term")
            return [{"id": r[0], "term": r[1]} for r in cur.fetchall()]
    finally:
        put_conn(conn)


def list_authors():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, first_name, last_name, email FROM authors ORDER BY last_name")
            return [{"id": r[0], "first_name": r[1], "last_name": r[2], "email": r[3]} for r in cur.fetchall()]
    finally:
        put_conn(conn)


def list_advisers():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, first_name, last_name, email FROM advisers ORDER BY last_name")
            return [{"id": r[0], "first_name": r[1], "last_name": r[2], "email": r[3]} for r in cur.fetchall()]
    finally:
        put_conn(conn)


# ── Thesis Embeddings ──────────────────────────────────────────────────────

def get_thesis_embedding(thesis_id):
    """Get existing embedding for a thesis, or None."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id FROM thesis_embeddings WHERE thesis_id = %s",
                (thesis_id,),
            )
            row = cur.fetchone()
            return row is not None
    finally:
        put_conn(conn)


def upsert_thesis_embedding(thesis_id, chunk_text, embedding_vector, model_name):
    """Insert or update embedding for a thesis."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id FROM thesis_embeddings WHERE thesis_id = %s",
                (thesis_id,),
            )
            existing = cur.fetchone()
            if existing:
                cur.execute(
                    "UPDATE thesis_embeddings SET embedding = %s::vector, chunk_text = %s, model_name = %s WHERE thesis_id = %s",
                    (embedding_vector, chunk_text, model_name, thesis_id),
                )
            else:
                cur.execute(
                    "INSERT INTO thesis_embeddings (thesis_id, chunk_text, embedding, model_name) "
                    "VALUES (%s, %s, %s::vector, %s)",
                    (thesis_id, chunk_text, embedding_vector, model_name),
                )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def get_dashboard_stats():
    """Get admin dashboard statistics."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM theses")
            total_theses = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM programs")
            total_programs = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM users")
            total_users = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM authors")
            total_authors = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM users WHERE is_active = true")
            active_users = cur.fetchone()[0]
            return {
                "studies": total_theses,
                "programs": total_programs,
                "users": total_users,
                "authors": total_authors,
                "active_users": active_users,
                "studies_this_week": 0,
                "active_programs": total_programs,
                "searches": "0",
                "search_growth": 0,
            }
    finally:
        put_conn(conn)


def recent_activity(limit=10):
    """Get recent activity for the admin dashboard."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Get recent theses
            cur.execute(
                "SELECT t.id, t.title, t.created_at, "
                "       p.name as program_name, "
                "       'New thesis added' as activity_type, "
                "       'Author: ' || COALESCE(a.first_name || ' ' || a.last_name, 'Unknown') as subtitle "
                "FROM theses t "
                "LEFT JOIN programs p ON t.program_id = p.id "
                "LEFT JOIN thesis_authors ta ON t.id = ta.thesis_id "
                "LEFT JOIN authors a ON ta.author_id = a.id "
                "ORDER BY t.created_at DESC LIMIT %s",
                (limit,),
            )
            rows = cur.fetchall()
            return [
                {
                    "id": r[0],
                    "title": r[1],
                    "created_at": r[2].isoformat() if r[2] else None,
                    "program": r[3],
                    "activity_type": r[4],
                    "subtitle": r[5],
                }
                for r in rows
            ]
    finally:
        put_conn(conn)


def semantic_search(query_vector, limit=10):
    """Find theses by embedding cosine similarity."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT t.id, t.title, t.abstract, t.research_type, t.program_id, t.status, "
                "       1 - (e.embedding <=> %s::vector) AS similarity "
                "FROM thesis_embeddings e "
                "JOIN theses t ON e.thesis_id = t.id "
                "WHERE t.status IN ('published', 'approved') "
                "ORDER BY e.embedding <=> %s::vector "
                "LIMIT %s",
                (query_vector, query_vector, limit),
            )
            rows = cur.fetchall()
            return [
                {
                    "id": r[0],
                    "title": r[1],
                    "abstract": r[2],
                    "research_type": r[3],
                    "program_id": r[4],
                    "status": r[5],
                    "similarity": float(r[6]),
                }
                for r in rows
            ]
    finally:
        put_conn(conn)


def get_faculty_stats(email):
    """Get faculty-specific dashboard statistics."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Count theses where this user is an adviser
            cur.execute(
                "SELECT COUNT(*) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s)",
                (email,),
            )
            total_theses = cur.fetchone()[0]

            # Count distinct advisees (authors of advised theses)
            cur.execute(
                "SELECT COUNT(DISTINCT ta2.author_id) FROM thesis_advisers tadv "
                "JOIN thesis_authors ta2 ON tadv.thesis_id = ta2.thesis_id "
                "JOIN advisers a ON tadv.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s)",
                (email,),
            )
            total_advisees = cur.fetchone()[0] or 0

            # Count published theses
            cur.execute(
                "SELECT COUNT(*) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s) AND t.status = 'published'",
                (email,),
            )
            published = cur.fetchone()[0]

            # Active projects (theses with status != 'published')
            cur.execute(
                "SELECT COUNT(*) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s) AND t.status != 'published'",
                (email,),
            )
            active_projects = cur.fetchone()[0]

            return {
                "theses": total_theses,
                "advisees": total_advisees,
                "published": published,
                "active_projects": active_projects,
                "programs": 3,
                "pending_reviews": active_projects,
                "completed_reviews": published,
            }
    finally:
        put_conn(conn)


def get_faculty_activity(email, limit=10):
    """Get activity for a faculty's advisees."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT t.id, t.title, t.created_at, t.status, "
                "       p.name as program_name, "
                "       'Thesis update: ' || t.title as activity_type, "
                "       'Status: ' || t.status || ' • Program: ' || p.name as subtitle "
                "FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN programs p ON t.program_id = p.id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s) "
                "ORDER BY t.updated_at DESC LIMIT %s",
                (email, limit),
            )
            rows = cur.fetchall()
            return [
                {
                    "id": r[0],
                    "title": r[1],
                    "created_at": r[2].isoformat() if r[2] else None,
                    "status": r[3],
                    "program": r[4],
                    "activity_type": r[5],
                    "subtitle": r[6],
                }
                for r in rows
            ]
    finally:
        put_conn(conn)


def recommend_for_thesis(thesis_id, limit=5):
    """Find similar theses to a given thesis using its embedding."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Get the embedding of the source thesis
            cur.execute(
                "SELECT embedding FROM thesis_embeddings WHERE thesis_id = %s",
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                return []
            source_embedding = row[0]

            # Find similar theses (excluding the source itself)
            cur.execute(
                "SELECT t.id, t.title, t.abstract, t.research_type, t.program_id, t.status, "
                "       1 - (e.embedding <=> %s::vector) AS similarity "
                "FROM thesis_embeddings e "
                "JOIN theses t ON e.thesis_id = t.id "
                "WHERE t.status IN ('published', 'approved') AND t.id != %s "
                "ORDER BY e.embedding <=> %s::vector "
                "LIMIT %s",
                (source_embedding, thesis_id, source_embedding, limit),
            )
            rows = cur.fetchall()
            return [
                {
                    "id": r[0],
                    "title": r[1],
                    "abstract": r[2],
                    "research_type": r[3],
                    "program_id": r[4],
                    "status": r[5],
                    "similarity": float(r[6]),
                }
                for r in rows
            ]
    finally:
        put_conn(conn)
