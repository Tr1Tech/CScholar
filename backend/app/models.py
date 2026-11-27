"""Simple data access helpers — raw psycopg2 queries, no ORM.

Functions return plain dicts or None.
"""

from .extensions import get_conn, put_conn
import json
import re


class ThesisStatusConflict(Exception):
    """Raised when a guarded status UPDATE matched no row.

    Means another reviewer changed the thesis first (for example, two
    admins approving the same draft at the same time). The caller should
    treat this as a business conflict, not a successful update.
    """

    def __init__(self, thesis_id, required_statuses, current_status=None):
        self.thesis_id = thesis_id
        self.required_statuses = list(required_statuses)
        self.current_status = current_status
        super().__init__(
            f"Thesis {thesis_id} cannot move to the requested status "
            f"(required current status: {self.required_statuses}, "
            f"actual: {current_status})"
        )


# Valid lifecycle transitions (FR-08), keyed by target status. Mirrors
# ceit_repo.fn_can_transition_status in db/logic/cscholar_lab5_logic.sql.
# The source status is part of the UPDATE guard, so an approval can only
# ever succeed once — from 'draft'. Archiving is reversible: an archived
# thesis can be restored to 'draft' (edit and re-approve) or sent straight
# back to 'published' (unarchive into the repository).
THESIS_STATUS_SOURCES = {
    "draft": ("approved", "archived"),
    "approved": ("draft",),
    "published": ("approved", "archived"),
    "archived": ("draft", "published"),
}


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


def update_user(user_id, username=None, email=None, role=None):
    """Update username/email/role (any subset). Returns the updated user."""
    fields = {}
    if username is not None:
        fields["username"] = username.strip()
    if email is not None:
        fields["email"] = email.strip().lower()
    if role is not None:
        fields["role"] = role
    if not fields:
        return get_user_by_id(user_id)
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            set_clause = ", ".join(f"{k} = %s" for k in fields)
            params = list(fields.values()) + [user_id]
            cur.execute(f"UPDATE users SET {set_clause} WHERE id = %s", params)
        conn.commit()
        return get_user_by_id(user_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def set_user_active(user_id, is_active):
    """Activate or deactivate a user."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE users SET is_active = %s WHERE id = %s", (bool(is_active), user_id))
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def set_user_password(user_id, password_hash):
    """Replace a user's password hash. Returns True when a row was updated."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE users SET password_hash = %s WHERE id = %s",
                (password_hash, user_id),
            )
            updated = cur.rowcount > 0
        conn.commit()
        return updated
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

def serialize_thesis(row):
    """Convert a DB row to a thesis dict."""
    ever_published = bool(row[26]) if len(row) > 26 else False
    accession_no = row[27] if len(row) > 27 else None
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
        # Optional approval/review columns — only the detail query selects
        # them, so short (list) rows simply leave them unset.
        "approved_by": row[22] if len(row) > 22 else None,
        "approved_at": row[23].isoformat() if len(row) > 23 and row[23] else None,
        "review_notes": row[24] if len(row) > 24 else None,
        "approved_by_name": row[25] if len(row) > 25 else None,
        # Retention is history, not status. The commands use it to decide
        # whether a record may be deleted or only archived; list rows shorten
        # to defaults when the query did not select these columns.
        "ever_published": ever_published,
        "accession_no": accession_no,
        "retained": ever_published or accession_no is not None,
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


def _load_thesis_reviews(cur, thesis_id):
    """Review trail for one thesis, newest first.

    `theses.review_notes` only holds the latest return note; this table keeps
    every decision so a re-approval cannot erase the reason for a past return.
    """
    cur.execute(
        "SELECT r.id, r.decision, r.notes, r.reviewer_id, u.username, r.created_at "
        "FROM thesis_reviews r "
        "LEFT JOIN users u ON r.reviewer_id = u.id "
        "WHERE r.thesis_id = %s "
        "ORDER BY r.created_at DESC, r.id DESC",
        (thesis_id,),
    )
    return [
        {
            "id": r[0],
            "decision": r[1],
            "notes": r[2],
            "reviewer_id": r[3],
            "reviewer_name": r[4],
            "created_at": r[5].isoformat() if r[5] else None,
        }
        for r in cur.fetchall()
    ]


def _load_thesis_relations_batch(cur, thesis_ids):
    """Batch-load relations for many theses in 4 queries (fixes N+1)."""
    grouped = {tid: {"authors": [], "advisers": [], "categories": [], "keywords": []} for tid in thesis_ids}
    if not thesis_ids:
        return grouped
    ids = list(thesis_ids)

    cur.execute(
        "SELECT ta.thesis_id, a.id, a.first_name, a.middle_name, a.last_name, a.email, a.created_at "
        "FROM thesis_authors ta JOIN authors a ON ta.author_id = a.id "
        "WHERE ta.thesis_id = ANY(%s) ORDER BY ta.thesis_id, ta.order_index",
        (ids,),
    )
    for r in cur.fetchall():
        grouped[r[0]]["authors"].append({
            "id": r[1], "first_name": r[2], "middle_name": r[3],
            "last_name": r[4], "email": r[5],
            "created_at": r[6].isoformat() if r[6] else None,
        })

    cur.execute(
        "SELECT ta.thesis_id, a.id, a.first_name, a.middle_name, a.last_name, a.email, a.created_at "
        "FROM thesis_advisers ta JOIN advisers a ON ta.adviser_id = a.id "
        "WHERE ta.thesis_id = ANY(%s)",
        (ids,),
    )
    for r in cur.fetchall():
        grouped[r[0]]["advisers"].append({
            "id": r[1], "first_name": r[2], "middle_name": r[3],
            "last_name": r[4], "email": r[5],
            "created_at": r[6].isoformat() if r[6] else None,
        })

    cur.execute(
        "SELECT tc.thesis_id, c.id, c.name, c.description, c.created_at "
        "FROM thesis_categories tc JOIN categories c ON tc.category_id = c.id "
        "WHERE tc.thesis_id = ANY(%s)",
        (ids,),
    )
    for r in cur.fetchall():
        grouped[r[0]]["categories"].append({
            "id": r[1], "name": r[2], "description": r[3],
            "created_at": r[4].isoformat() if r[4] else None,
        })

    cur.execute(
        "SELECT tk.thesis_id, k.id, k.term, k.created_at "
        "FROM thesis_keywords tk JOIN keywords k ON tk.keyword_id = k.id "
        "WHERE tk.thesis_id = ANY(%s)",
        (ids,),
    )
    for r in cur.fetchall():
        grouped[r[0]]["keywords"].append({
            "id": r[1], "term": r[2],
            "created_at": r[3].isoformat() if r[3] else None,
        })

    return grouped


def normalize_keyword(term):
    """Canonical keyword form: collapsed whitespace, lowercase.

    ``keywords.term`` is UNIQUE and case-sensitive, so without this "IoT",
    "iot", and " IoT " become three separate vocabulary rows. Filtering still
    works (it uses ILIKE), but the list fragments and users see duplicates.
    """
    return re.sub(r"\s+", " ", str(term or "")).strip().lower()


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
        seen = set()
        for raw in keyword_terms:
            term = normalize_keyword(raw)
            if not term or term in seen:
                continue
            seen.add(term)
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
                "       t.status, t.creator_id, t.created_at, t.updated_at, t.pdf_url, "
                "       t.approved_by, t.approved_at, t.review_notes, u.username, "
                "       EXISTS (SELECT 1 FROM thesis_reviews r "
                "               WHERE r.thesis_id = t.id AND r.decision = 'published') AS ever_published, "
                "       t.accession_no "
                "FROM theses t "
                "LEFT JOIN programs p ON t.program_id = p.id "
                "LEFT JOIN academic_years ay ON t.academic_year_id = ay.id "
                "LEFT JOIN users u ON t.approved_by = u.id "
                "WHERE t.id = %s",
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            data = serialize_thesis(row)
            data.update(_load_thesis_relations(cur, thesis_id))
            data["reviews"] = _load_thesis_reviews(cur, thesis_id)
            return data
    finally:
        put_conn(conn)


def user_can_view_unpublished(thesis, user):
    """Whether [user] may open a study that is not publicly published.

    The repository is public for `published` only. Everything else is an
    internal archival record: staff can open it, and the submitting account can
    keep working on it. The people named as authors are bibliographic metadata,
    not accounts, so authorship alone grants no access.
    """
    if not user or not thesis:
        return False
    if user.get("role") in ("admin", "faculty"):
        return True
    return (
        thesis.get("creator_id") is not None
        and thesis["creator_id"] == user.get("id")
    )


def list_theses(q=None, program_id=None, year_id=None, research_type=None, status=None, category_id=None, keyword=None, sort_by=None, page=1, per_page=20, adviser_email=None, creator_id=None):
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
                    "OR EXISTS (SELECT 1 FROM thesis_authors ta2 JOIN authors a2 ON ta2.author_id = a2.id WHERE ta2.thesis_id = t.id AND (a2.first_name ILIKE %s OR a2.last_name ILIKE %s)) "
                    "OR EXISTS (SELECT 1 FROM thesis_advisers tadv2 JOIN advisers adv2 ON tadv2.adviser_id = adv2.id WHERE tadv2.thesis_id = t.id AND (adv2.first_name ILIKE %s OR adv2.last_name ILIKE %s))"
                    ")"
                )
                pattern = f"%{q}%"
                params.extend([pattern, pattern, pattern, pattern, pattern, pattern, pattern])
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
            if adviser_email and creator_id is not None:
                # Faculty "My Theses": advised by me OR submitted by me.
                conditions.append(
                    "(EXISTS (SELECT 1 FROM thesis_advisers ta JOIN advisers a ON ta.adviser_id = a.id "
                    "WHERE ta.thesis_id = t.id AND LOWER(a.email) = LOWER(%s)) "
                    "OR t.creator_id = %s)"
                )
                params.extend([adviser_email, creator_id])
            elif adviser_email:
                conditions.append(
                    "EXISTS (SELECT 1 FROM thesis_advisers ta JOIN advisers a ON ta.adviser_id = a.id "
                    "WHERE ta.thesis_id = t.id AND LOWER(a.email) = LOWER(%s))"
                )
                params.append(adviser_email)
            elif creator_id is not None:
                conditions.append("t.creator_id = %s")
                params.append(creator_id)
            if status:
                if isinstance(status, list):
                    conditions.append("t.status = ANY(%s)")
                    params.append(status)
                else:
                    conditions.append("t.status = %s")
                    params.append(status)

            # Keyword listing has no relevance/view/similarity ranking —
            # only honest sorts are supported. Semantic ordering lives in
            # semantic_search() (ORDER BY embedding distance).
            order_by_sql = "t.created_at DESC"
            if sort_by:
                sb = str(sort_by).strip().lower()
                if sb in ("latest", "newest", "relevance"):
                    order_by_sql = "t.created_at DESC"
                elif sb in ("oldest",):
                    order_by_sql = "t.created_at ASC"
                elif sb in ("title", "title (a-z)", "title_asc"):
                    order_by_sql = "t.title ASC"
                elif sb in ("title (z-a)", "title_desc"):
                    order_by_sql = "t.title DESC"
                # NOTE: "highest similarity" / "most viewed" are NOT supported
                # here on purpose — they fall through to created_at DESC so old
                # clients don't break, but the UI no longer offers them for
                # keyword search (see repository_screen sort dropdown).

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
                f"       t.status, t.creator_id, t.created_at, t.updated_at, t.pdf_url, "
                f"       t.approved_by, t.approved_at, t.review_notes, u.username, "
                f"       EXISTS (SELECT 1 FROM thesis_reviews r "
                f"               WHERE r.thesis_id = t.id AND r.decision = 'published') AS ever_published, "
                f"       t.accession_no "
                f"FROM theses t "
                f"LEFT JOIN programs p ON t.program_id = p.id "
                f"LEFT JOIN academic_years ay ON t.academic_year_id = ay.id "
                f"LEFT JOIN users u ON t.approved_by = u.id "
                f"{where} "
                f"ORDER BY {order_by_sql} "
                f"LIMIT %s OFFSET %s",
                params + [per_page, offset],
            )
            rows = cur.fetchall()
            theses = [serialize_thesis(row) for row in rows]

            thesis_ids = [t["id"] for t in theses]
            if thesis_ids:
                rel_map = _load_thesis_relations_batch(cur, thesis_ids)
                for t in theses:
                    t.update(rel_map.get(t["id"], {"authors": [], "advisers": [], "categories": [], "keywords": []}))

            return {
                "theses": theses,
                "total": total,
                "page": page,
                "per_page": per_page,
                "pages": (total + per_page - 1) // per_page,
            }
    finally:
        put_conn(conn)


def find_possible_duplicates(title, abstract=None, limit=5):
    """Soft duplicate guard for thesis submission (no UNIQUE constraint).

    Matches on normalized title: case-insensitive, trimmed, inner
    whitespace collapsed — so "  IoT  System " == "iot system".
    Title-only match = "exact_title" (common in real life, still allowed).
    Title + abstract both matching = "exact_title_and_abstract"
    (almost certainly a copy-paste / resubmission).

    Returns a list of dicts (id, title, status, program_id,
    academic_year_id, match_type). Never raises — returns [] on DB error
    so submission is never blocked by the guard itself.
    """
    norm_title = re.sub(r"\s+", " ", (title or "")).strip().lower()
    if not norm_title:
        return []
    norm_abstract = re.sub(r"\s+", " ", (abstract or "")).strip().lower()
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, title, abstract, status, program_id, "
                "       academic_year_id, creator_id, created_at "
                "FROM theses "
                "WHERE LOWER(btrim(title)) = LOWER(btrim(%s)) "
                "ORDER BY created_at DESC LIMIT %s",
                (title.strip(), limit),
            )
            dupes = []
            for r in cur.fetchall():
                row_abstract = re.sub(r"\s+", " ", (r[2] or "")).strip().lower()
                full = bool(norm_abstract and row_abstract == norm_abstract)
                dupes.append({
                    "id": r[0],
                    "title": r[1],
                    "status": r[3],
                    "program_id": r[4],
                    "academic_year_id": r[5],
                    "match_type": "exact_title_and_abstract" if full else "exact_title",
                })
            return dupes
    except Exception:
        return []
    finally:
        put_conn(conn)


def create_thesis(title, abstract, research_type, program_id, academic_year_id, creator_id, status="draft",
                  author_ids=None, adviser_id=None, category_ids=None, keyword_terms=None, pdf_url=None,
                  approved_by=None):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # A record created straight into approved/published records who
            # released it, so the approval trail is never blank.
            recorded_approval = (
                approved_by is not None and status in ("approved", "published")
            )
            if recorded_approval:
                cur.execute(
                    "INSERT INTO theses (title, abstract, research_type, program_id, academic_year_id, status, creator_id, pdf_url, approved_by, approved_at) "
                    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW()) RETURNING id",
                    (title, abstract, research_type, program_id, academic_year_id, status, creator_id, pdf_url, approved_by),
                )
            else:
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
            if recorded_approval:
                # The creation itself is the first review decision; record it
                # so the trail starts at the same place as the stamp.
                cur.execute(
                    "INSERT INTO thesis_reviews (thesis_id, reviewer_id, decision) "
                    "VALUES (%s, %s, %s)",
                    (thesis_id, approved_by, status),
                )
        conn.commit()
        return thesis_id
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def update_thesis(thesis_id, **kwargs):
    allowed = {"title", "abstract", "research_type", "program_id", "academic_year_id", "status", "pdf_url", "approved_by", "review_notes"}
    fields = {k: v for k, v in kwargs.items() if k in allowed and v is not None}
    target_status = fields.get("status")
    # The acting account, for the review trail. Not a column on `theses`, so it
    # stays outside `allowed`.
    actor_id = kwargs.get("actor_id")

    author_ids = kwargs.get("author_ids") if isinstance(kwargs.get("author_ids"), list) else None
    adviser_id = kwargs.get("adviser_id")
    category_ids = kwargs.get("category_ids") if isinstance(kwargs.get("category_ids"), list) else None
    keyword_terms = kwargs.get("keyword_terms") if isinstance(kwargs.get("keyword_terms"), list) else None

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            if fields:
                set_parts = [f"{k} = %s" for k in fields]
                params = list(fields.values())
                if target_status == "approved":
                    # Stamp the release decision server-side; the API passes
                    # the acting admin as approved_by. Review notes are kept —
                    # they are history, not a flag on the current status.
                    set_parts.append("approved_at = NOW()")
                elif target_status == "draft":
                    # Returning to draft revokes the approval record. The
                    # reviewer's notes stay on the row (and in thesis_reviews)
                    # so the reason for the return survives re-approval.
                    set_parts.append("approved_by = NULL")
                    set_parts.append("approved_at = NULL")
                set_clause = ", ".join(set_parts)
                params.append(thesis_id)
                where_clause = "id = %s"

                if target_status is not None:
                    required_statuses = THESIS_STATUS_SOURCES.get(target_status)
                    if required_statuses is None:
                        raise ValueError(f"Invalid status: {target_status}")
                    # Guarded UPDATE: the source status is part of the WHERE.
                    # A second admin approving the same draft waits on the row
                    # lock, then matches 0 rows after the first COMMIT.
                    where_clause += " AND status = ANY(%s)"
                    params.append(list(required_statuses))

                cur.execute(
                    f"UPDATE theses SET {set_clause} WHERE {where_clause}",
                    params,
                )

                if target_status is not None and cur.rowcount == 0:
                    cur.execute("SELECT status FROM theses WHERE id = %s", (thesis_id,))
                    row = cur.fetchone()
                    raise ThesisStatusConflict(
                        thesis_id,
                        required_statuses,
                        row[0] if row else None,
                    )

                if target_status is not None and actor_id is not None:
                    # Append the decision to the audit trail. Notes are only
                    # meaningful on a return, but recording every decision keeps
                    # the approval history complete.
                    cur.execute(
                        "INSERT INTO thesis_reviews (thesis_id, reviewer_id, decision, notes) "
                        "VALUES (%s, %s, %s, %s)",
                        (thesis_id, actor_id, target_status, fields.get("review_notes")),
                    )

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
    """Delete a thesis row and everything that cascades with it.

    The stored PDF is deliberately not removed here. The cascade also drops
    ``thesis_files``, so the route captures the file URL first and removes the
    blob after this commit, once no other thesis references it.
    """
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


def thesis_retention(thesis_id):
    """Retention facts for a thesis: whether it must be kept, and why.

    Current status is not evidence — a record can be archived and even
    restored to draft — so this reads history and the holdings register:
    ever published (``thesis_reviews``) or assigned an ``accession_no``.
    Hard delete refuses retained records; only an explicit, audited purge may
    remove one.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT t.accession_no, "
                "       EXISTS ("
                "           SELECT 1 FROM thesis_reviews r "
                "           WHERE r.thesis_id = t.id AND r.decision = 'published'"
                "       ) "
                "FROM theses t WHERE t.id = %s",
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                return {
                    "accession_no": None,
                    "ever_published": False,
                    "retained": False,
                }
            accession_no, ever_published = row
            return {
                "accession_no": accession_no,
                "ever_published": bool(ever_published),
                "retained": bool(accession_no) or bool(ever_published),
            }
    finally:
        put_conn(conn)


# ── Meta lookups ───────────────────────────────────────────────────────────

def list_programs():
    """Programs with the number of studies that reference them.

    ``thesis_count`` is the same figure the delete route checks, so the admin
    screen can mark a row as in use before offering the destructive action.
    The LEFT JOIN keeps unused programs (count 0) in the list.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT p.id, p.name, p.code, p.description, p.created_at, "
                "       COUNT(t.id) AS thesis_count "
                "FROM programs p "
                "LEFT JOIN theses t ON t.program_id = p.id "
                "GROUP BY p.id "
                "ORDER BY p.name"
            )
            return [
                {
                    "id": r[0],
                    "name": r[1],
                    "code": r[2],
                    "description": r[3],
                    "created_at": r[4].isoformat() if r[4] else None,
                    "thesis_count": r[5] or 0,
                }
                for r in cur.fetchall()
            ]
    finally:
        put_conn(conn)


def list_academic_years():
    """Academic years with the number of studies filed under each one."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT ay.id, ay.name, ay.start_year, ay.end_year, ay.is_active, "
                "       ay.created_at, COUNT(t.id) AS thesis_count "
                "FROM academic_years ay "
                "LEFT JOIN theses t ON t.academic_year_id = ay.id "
                "GROUP BY ay.id "
                "ORDER BY ay.start_year DESC"
            )
            return [
                {
                    "id": r[0],
                    "name": r[1],
                    "label": r[1],
                    "start_year": r[2],
                    "end_year": r[3],
                    "is_active": r[4],
                    "created_at": r[5].isoformat() if r[5] else None,
                    "thesis_count": r[6] or 0,
                }
                for r in cur.fetchall()
            ]
    finally:
        put_conn(conn)


def list_categories():
    """Categories with the number of studies tagged with each one.

    A study can carry a category at most once (composite primary key on
    ``thesis_categories``), so the count is also the number of studies.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT c.id, c.name, c.description, c.created_at, "
                "       COUNT(tc.thesis_id) AS thesis_count "
                "FROM categories c "
                "LEFT JOIN thesis_categories tc ON tc.category_id = c.id "
                "GROUP BY c.id "
                "ORDER BY c.name"
            )
            return [
                {
                    "id": r[0],
                    "name": r[1],
                    "description": r[2],
                    "created_at": r[3].isoformat() if r[3] else None,
                    "thesis_count": r[4] or 0,
                }
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


def list_authors(include_email=True):
    """List authors. Email is omitted unless the caller is an admin.

    The route is public because the repository and both thesis forms need the
    name list. Student addresses are personal data and used to be served to
    anonymous visitors; ``include_email`` keeps them for the admin screens
    that actually edit them.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, first_name, middle_name, last_name, email, created_at "
                "FROM authors ORDER BY last_name, first_name"
            )
            rows = []
            for r in cur.fetchall():
                row = {
                    "id": r[0],
                    "first_name": r[1],
                    "middle_name": r[2],
                    "last_name": r[3],
                    "created_at": r[5].isoformat() if r[5] else None,
                }
                if include_email:
                    row["email"] = r[4]
                rows.append(row)
            return rows
    finally:
        put_conn(conn)


def list_advisers(include_email=True):
    """List advisers. Email is omitted unless the caller is an admin.

    Adviser email is not just contact data here: it is the key that links a
    faculty login to advised theses, so it stays out of the anonymous payload.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, first_name, middle_name, last_name, email, created_at "
                "FROM advisers ORDER BY last_name, first_name"
            )
            rows = []
            for r in cur.fetchall():
                row = {
                    "id": r[0],
                    "first_name": r[1],
                    "middle_name": r[2],
                    "last_name": r[3],
                    "created_at": r[5].isoformat() if r[5] else None,
                }
                if include_email:
                    row["email"] = r[4]
                rows.append(row)
            return rows
    finally:
        put_conn(conn)


# ── Authors CRUD ───────────────────────────────────────────────────────────

def get_author_by_id(author_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, first_name, middle_name, last_name, email, created_at "
                "FROM authors WHERE id = %s",
                (author_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "first_name": row[1],
                "middle_name": row[2],
                "last_name": row[3],
                "email": row[4],
                "created_at": row[5].isoformat() if row[5] else None,
            }
    finally:
        put_conn(conn)


def create_author(first_name, last_name, email, middle_name=None):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO authors (first_name, middle_name, last_name, email) "
                "VALUES (%s, %s, %s, %s) RETURNING id",
                (first_name, middle_name, last_name, email),
            )
            author_id = cur.fetchone()[0]
        conn.commit()
        return get_author_by_id(author_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def find_author_match(first_name, middle_name, last_name, email=None):
    """Return an author describing the same person, or None.

    The admin/faculty forms can now create a student without leaving the page,
    so a double submit or two staff entering the same student must not split
    that student's history across duplicate rows. Email is the strongest
    signal; otherwise compare normalized names.
    """
    author_id = None
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            if email:
                cur.execute(
                    "SELECT id FROM authors "
                    "WHERE LOWER(COALESCE(email, '')) = LOWER(%s) "
                    "ORDER BY id LIMIT 1",
                    (email,),
                )
                row = cur.fetchone()
                if row:
                    author_id = row[0]
            if author_id is None:
                cur.execute(
                    "SELECT id FROM authors "
                    "WHERE LOWER(first_name) = LOWER(%s) "
                    "AND LOWER(last_name) = LOWER(%s) "
                    "AND LOWER(COALESCE(middle_name, '')) = LOWER(COALESCE(%s, '')) "
                    "ORDER BY id LIMIT 1",
                    (first_name, last_name, middle_name or ""),
                )
                row = cur.fetchone()
                if row:
                    author_id = row[0]
    finally:
        put_conn(conn)
    return get_author_by_id(author_id) if author_id else None


def update_author(author_id, **kwargs):
    allowed = {"first_name", "middle_name", "last_name", "email"}
    fields = {k: v for k, v in kwargs.items() if k in allowed and v is not None}
    if not fields:
        return get_author_by_id(author_id)

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            set_clause = ", ".join(f"{k} = %s" for k in fields)
            params = list(fields.values()) + [author_id]
            cur.execute(f"UPDATE authors SET {set_clause} WHERE id = %s", params)
        conn.commit()
        return get_author_by_id(author_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def delete_author(author_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM authors WHERE id = %s", (author_id,))
            deleted = cur.rowcount
        conn.commit()
        return deleted > 0
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


# ── Advisers CRUD ──────────────────────────────────────────────────────────

def get_adviser_by_id(adviser_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, first_name, middle_name, last_name, email, created_at "
                "FROM advisers WHERE id = %s",
                (adviser_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "first_name": row[1],
                "middle_name": row[2],
                "last_name": row[3],
                "email": row[4],
                "created_at": row[5].isoformat() if row[5] else None,
            }
    finally:
        put_conn(conn)


def ensure_adviser_for_email(email, display_name=None):
    """Return the advisers.id matching this email, creating the row (faculty
    auto-provision) when none exists. Admins can correct names afterwards."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id FROM advisers WHERE LOWER(email) = LOWER(%s) ORDER BY id LIMIT 1",
                (email,),
            )
            row = cur.fetchone()
            if row:
                return row[0]
            parts = re.split(r"[\s._-]+", (display_name or email.split("@")[0]).strip())
            parts = [p for p in parts if p]
            first = parts[0] if parts else (display_name or "Faculty")
            last = " ".join(parts[1:]) if len(parts) > 1 else ""
            cur.execute(
                "INSERT INTO advisers (first_name, middle_name, last_name, email) "
                "VALUES (%s, %s, %s, %s) RETURNING id",
                (first, None, last, email),
            )
            adviser_id = cur.fetchone()[0]
        conn.commit()
        return adviser_id
    except Exception:
        try:
            conn.rollback()
        except Exception:
            pass
        # Likely a duplicate-email race: re-read instead of failing the submit.
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id FROM advisers WHERE LOWER(email) = LOWER(%s) ORDER BY id LIMIT 1",
                (email,),
            )
            row = cur.fetchone()
            if row:
                return row[0]
        raise
    finally:
        put_conn(conn)


def create_adviser(first_name, last_name, email, middle_name=None):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO advisers (first_name, middle_name, last_name, email) "
                "VALUES (%s, %s, %s, %s) RETURNING id",
                (first_name, middle_name, last_name, email),
            )
            adviser_id = cur.fetchone()[0]
        conn.commit()
        return get_adviser_by_id(adviser_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def update_adviser(adviser_id, **kwargs):
    allowed = {"first_name", "middle_name", "last_name", "email"}
    # Keep explicit nulls: clearing an adviser's email is how an admin unlinks
    # a faculty account again.
    fields = {k: v for k, v in kwargs.items() if k in allowed}
    if not fields:
        return get_adviser_by_id(adviser_id)

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            set_clause = ", ".join(f"{k} = %s" for k in fields)
            params = list(fields.values()) + [adviser_id]
            cur.execute(f"UPDATE advisers SET {set_clause} WHERE id = %s", params)
        conn.commit()
        return get_adviser_by_id(adviser_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def delete_adviser(adviser_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM advisers WHERE id = %s", (adviser_id,))
            deleted = cur.rowcount
        conn.commit()
        return deleted > 0
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


# ── Categories CRUD ────────────────────────────────────────────────────────

def get_category_by_id(category_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, description, created_at FROM categories WHERE id = %s",
                (category_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "name": row[1],
                "description": row[2],
                "created_at": row[3].isoformat() if row[3] else None,
            }
    finally:
        put_conn(conn)


def normalize_label(value):
    """Collapse whitespace and trim, preserving capitalization.

    Category names are shown in the UI, so forcing lowercase would read badly.
    Uniqueness is enforced case-insensitively instead (see create_category).
    """
    return re.sub(r"\s+", " ", str(value or "")).strip()


def _category_dict(row):
    return {
        "id": row[0],
        "name": row[1],
        "description": row[2],
        "created_at": row[3].isoformat() if row[3] else None,
    }


def create_category(name, description=None):
    """Create a category, reusing one whose name differs only by case.

    ``categories.name`` is UNIQUE and case-sensitive, so without this lookup
    "Machine Learning" and "machine learning" become two entries in every
    dropdown. The first spelling wins and is kept for display.
    """
    name = normalize_label(name)
    if not name:
        raise ValueError("Category name is required")

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, description, created_at FROM categories "
                "WHERE lower(name) = lower(%s)",
                (name,),
            )
            row = cur.fetchone()
            if row is None:
                cur.execute(
                    "INSERT INTO categories (name, description) VALUES (%s, %s) "
                    "RETURNING id, name, description, created_at",
                    (name, description),
                )
                row = cur.fetchone()
                conn.commit()
        return _category_dict(row)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def update_category(category_id, **kwargs):
    allowed = {"name", "description"}
    fields = {k: v for k, v in kwargs.items() if k in allowed and v is not None}
    if not fields:
        return get_category_by_id(category_id)
    if "name" in fields:
        fields["name"] = normalize_label(fields["name"])
        if not fields["name"]:
            raise ValueError("Category name cannot be empty")

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            if "name" in fields:
                cur.execute(
                    "SELECT id FROM categories WHERE lower(name) = lower(%s) AND id <> %s",
                    (fields["name"], category_id),
                )
                if cur.fetchone():
                    raise ValueError("A category with that name already exists")
            set_clause = ", ".join(f"{k} = %s" for k in fields)
            params = list(fields.values()) + [category_id]
            cur.execute(f"UPDATE categories SET {set_clause} WHERE id = %s", params)
        conn.commit()
        return get_category_by_id(category_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def delete_category(category_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM categories WHERE id = %s", (category_id,))
            deleted = cur.rowcount
        conn.commit()
        return deleted > 0
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


# ── Keywords CRUD ──────────────────────────────────────────────────────────




# ── Delete-safety usage counts ─────────────────────────────────────────────
# Programs and academic years are protected by ON DELETE RESTRICT. Counting
# first lets the API explain the block instead of returning an opaque server
# error. Authors, advisers, and categories use CASCADE on their join tables,
# so the database would not complain: it would silently drop the link. The
# count is what turns that silent unlink into an explained 409.

def count_theses_for_program(program_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM theses WHERE program_id = %s",
                (program_id,),
            )
            return cur.fetchone()[0] or 0
    finally:
        put_conn(conn)


def count_theses_for_academic_year(year_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM theses WHERE academic_year_id = %s",
                (year_id,),
            )
            return cur.fetchone()[0] or 0
    finally:
        put_conn(conn)


def count_theses_for_category(category_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM thesis_categories WHERE category_id = %s",
                (category_id,),
            )
            return cur.fetchone()[0] or 0
    finally:
        put_conn(conn)


def count_theses_for_author(author_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM thesis_authors WHERE author_id = %s",
                (author_id,),
            )
            return cur.fetchone()[0] or 0
    finally:
        put_conn(conn)


def count_theses_for_adviser(adviser_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM thesis_advisers WHERE adviser_id = %s",
                (adviser_id,),
            )
            return cur.fetchone()[0] or 0
    finally:
        put_conn(conn)


# ── Programs CRUD ─────────────────────────────────────────────────────────

def get_program_by_id(program_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, code, description, created_at FROM programs WHERE id = %s",
                (program_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "name": row[1],
                "code": row[2],
                "description": row[3],
                "created_at": row[4].isoformat() if row[4] else None,
            }
    finally:
        put_conn(conn)


def create_program(name, code=None, description=None):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO programs (name, code, description) VALUES (%s, %s, %s) RETURNING id",
                (name, code, description),
            )
            program_id = cur.fetchone()[0]
        conn.commit()
        return get_program_by_id(program_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def update_program(program_id, **kwargs):
    allowed = {"name", "code", "description"}
    fields = {k: v for k, v in kwargs.items() if k in allowed and v is not None}
    if not fields:
        return get_program_by_id(program_id)

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            set_clause = ", ".join(f"{k} = %s" for k in fields)
            params = list(fields.values()) + [program_id]
            cur.execute(f"UPDATE programs SET {set_clause} WHERE id = %s", params)
        conn.commit()
        return get_program_by_id(program_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def delete_program(program_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM programs WHERE id = %s", (program_id,))
            deleted = cur.rowcount
        conn.commit()
        return deleted > 0
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


# ── Academic Years CRUD ───────────────────────────────────────────────────

def get_academic_year_by_id(year_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, start_year, end_year, is_active, created_at "
                "FROM academic_years WHERE id = %s",
                (year_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "name": row[1],
                "start_year": row[2],
                "end_year": row[3],
                "is_active": row[4],
                "created_at": row[5].isoformat() if row[5] else None,
            }
    finally:
        put_conn(conn)


def create_academic_year(name, start_year=None, end_year=None, is_active=True):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO academic_years (name, start_year, end_year, is_active) "
                "VALUES (%s, %s, %s, %s) RETURNING id",
                (name, start_year, end_year, is_active),
            )
            year_id = cur.fetchone()[0]
        conn.commit()
        return get_academic_year_by_id(year_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def update_academic_year(year_id, **kwargs):
    allowed = {"name", "start_year", "end_year", "is_active"}
    fields = {k: v for k, v in kwargs.items() if k in allowed and v is not None}
    if not fields:
        return get_academic_year_by_id(year_id)

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            set_clause = ", ".join(f"{k} = %s" for k in fields)
            params = list(fields.values()) + [year_id]
            cur.execute(f"UPDATE academic_years SET {set_clause} WHERE id = %s", params)
        conn.commit()
        return get_academic_year_by_id(year_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def delete_academic_year(year_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM academic_years WHERE id = %s", (year_id,))
            deleted = cur.rowcount
        conn.commit()
        return deleted > 0
    except Exception:
        conn.rollback()
        raise
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
    """Insert or update embedding for a thesis (legacy single-chunk path).

    Kept for backwards compatibility. New code should use
    replace_thesis_embeddings() so a thesis can hold many chunks.
    """
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


def replace_thesis_embeddings(thesis_id, chunks, model_name):
    """Replace ALL embedding chunks for a thesis (full-PDF chunking).

    chunks: list of (chunk_text, embedding_vector) tuples.
    Delete-then-insert keeps re-uploads/re-embeds idempotent — without
    this, every re-run would duplicate all chunk rows and inflate ranks.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM thesis_embeddings WHERE thesis_id = %s", (thesis_id,))
            for chunk_text, vector in chunks:
                cur.execute(
                    "INSERT INTO thesis_embeddings (thesis_id, chunk_text, embedding, model_name) "
                    "VALUES (%s, %s, %s::vector, %s)",
                    (thesis_id, chunk_text, vector, model_name),
                )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def count_thesis_embedding_chunks(thesis_id):
    """Return the number of stored embedding chunks for a thesis."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM thesis_embeddings WHERE thesis_id = %s",
                (thesis_id,),
            )
            return cur.fetchone()[0]
    finally:
        put_conn(conn)


def create_thesis_file(thesis_id, filename, file_path, file_size=None, mime_type=None, uploaded_by=None):
    """Persist upload metadata (thesis_files stores metadata only)."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO thesis_files (thesis_id, filename, file_path, file_size, mime_type, uploaded_by) "
                "VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
                (thesis_id, filename, file_path, file_size, mime_type, uploaded_by),
            )
            file_id = cur.fetchone()[0]
        conn.commit()
        return file_id
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def replace_thesis_file(thesis_id, filename, file_path, file_size=None, mime_type=None, uploaded_by=None):
    """Make ``thesis_files`` hold exactly one row: the current file.

    Re-uploads used to append, so v_thesis_admin_overview.file_count could
    report 3 files for a thesis with a single active PDF. Delete+insert in one
    transaction also cleans up duplicates left by earlier appends.

    This only moves the metadata. The old blob is removed by the caller after
    the commit, and only when ``pdf_is_still_referenced`` says no other thesis
    still points at it — one stored URL can be attached to several records.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM thesis_files WHERE thesis_id = %s", (thesis_id,)
            )
            cur.execute(
                "INSERT INTO thesis_files (thesis_id, filename, file_path, file_size, mime_type, uploaded_by) "
                "VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
                (thesis_id, filename, file_path, file_size, mime_type, uploaded_by),
            )
            file_id = cur.fetchone()[0]
        conn.commit()
        return file_id
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def get_thesis_file(thesis_id):
    """Return the current thesis_files row for a thesis, or None."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, filename, file_path, file_size, mime_type, "
                "       uploaded_by, uploaded_at "
                "FROM thesis_files WHERE thesis_id = %s "
                "ORDER BY id DESC LIMIT 1",
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            return {
                "id": row[0],
                "filename": row[1],
                "file_path": row[2],
                "file_size": row[3],
                "mime_type": row[4],
                "uploaded_by": row[5],
                "uploaded_at": row[6].isoformat() if row[6] else None,
            }
    finally:
        put_conn(conn)


def delete_thesis_files(thesis_id):
    """Remove file metadata for a thesis.

    The blob is not touched here; callers that clear or replace the active
    file remove it after the commit, once nothing references it.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM thesis_files WHERE thesis_id = %s", (thesis_id,)
            )
            deleted = cur.rowcount
        conn.commit()
        return deleted
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def pdf_is_still_referenced(pdf_url):
    """True when a remaining row still points at [pdf_url].

    One stored upload can be attached to more than one thesis (an admin can
    reuse an existing ``/api/uploads/...`` URL), so a blob is only safe to
    remove once nothing else references it. Checked after the delete commits,
    so the row being removed no longer counts itself.
    """
    if not pdf_url:
        return False
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT (SELECT COUNT(*) FROM theses WHERE pdf_url = %s) "
                "     + (SELECT COUNT(*) FROM thesis_files WHERE file_path = %s)",
                (pdf_url, pdf_url),
            )
            return (cur.fetchone()[0] or 0) > 0
    finally:
        put_conn(conn)


def get_dashboard_stats():
    """Get admin dashboard statistics, including real activity counts."""
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
            cur.execute(
                "SELECT count(*) FROM theses "
                "WHERE created_at >= NOW() - INTERVAL '7 days'"
            )
            studies_this_week = cur.fetchone()[0]
            cur.execute(
                "SELECT count(DISTINCT program_id) FROM theses"
            )
            programs_with_studies = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM search_logs")
            searches = cur.fetchone()[0]
            cur.execute(
                "SELECT count(*) FROM search_logs "
                "WHERE created_at >= NOW() - INTERVAL '7 days'"
            )
            searches_7d = cur.fetchone()[0]
            cur.execute(
                "SELECT count(*) FROM search_logs "
                "WHERE created_at >= NOW() - INTERVAL '14 days' "
                "AND created_at < NOW() - INTERVAL '7 days'"
            )
            searches_prev_7d = cur.fetchone()[0]
            if searches_prev_7d:
                search_growth = round(
                    (searches_7d - searches_prev_7d) * 100 / searches_prev_7d
                )
            else:
                search_growth = 100 if searches_7d else 0
            cur.execute(
                "SELECT count(*) FROM search_logs "
                "WHERE filters->>'mode' = 'semantic'"
            )
            semantic_searches = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM recommendation_logs")
            recommendations_served = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM thesis_embeddings")
            embedding_chunks = cur.fetchone()[0]
            cur.execute("SELECT count(DISTINCT thesis_id) FROM thesis_embeddings")
            embedded_theses = cur.fetchone()[0]
            cur.execute(
                "SELECT count(*) FROM theses WHERE status = 'published'"
            )
            published_theses = cur.fetchone()[0]
            cur.execute(
                "SELECT count(*) FROM thesis_reviews "
                "WHERE created_at >= NOW() - INTERVAL '7 days'"
            )
            reviews_7d = cur.fetchone()[0]
            cur.execute(
                "SELECT count(*) FROM import_jobs "
                "WHERE created_at >= NOW() - INTERVAL '7 days'"
            )
            imports_7d = cur.fetchone()[0]
            cur.execute(
                "SELECT LOWER(BTRIM(query)) AS query, "
                "       COALESCE(filters->>'mode', 'keyword') AS mode, "
                "       COUNT(*) AS count "
                "FROM search_logs "
                "WHERE query IS NOT NULL AND BTRIM(query) <> '' "
                "  AND created_at >= NOW() - INTERVAL '30 days' "
                "GROUP BY 1, 2 "
                "ORDER BY count DESC, query ASC "
                "LIMIT 5"
            )
            top_queries = [
                {"query": row[0], "mode": row[1], "count": row[2]}
                for row in cur.fetchall()
            ]
            return {
                "studies": total_theses,
                "programs": total_programs,
                "users": total_users,
                "authors": total_authors,
                "active_users": active_users,
                "studies_this_week": studies_this_week,
                "active_programs": programs_with_studies,
                "searches": searches,
                "searches_7d": searches_7d,
                "search_growth": search_growth,
                "semantic_searches": semantic_searches,
                "recommendations_served": recommendations_served,
                "embedding_chunks": embedding_chunks,
                "embedded_theses": embedded_theses,
                "published_theses": published_theses,
                "reviews_7d": reviews_7d,
                "imports_7d": imports_7d,
                "top_queries": top_queries,
            }
    finally:
        put_conn(conn)


def get_public_stats():
    """Public repository summary — published/approved counts only, no auth."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM theses WHERE status = 'published'")
            total_theses = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM programs")
            total_programs = cur.fetchone()[0]
            return {"studies": total_theses, "programs": total_programs}
    finally:
        put_conn(conn)


def recent_activity(limit=10, offset=0, include_admin=False):
    """Get one page of recent activity for the admin dashboard.

    The public-safe feed is submissions only. Admins also see review
    decisions and import batches, because those rows name a reviewer and
    describe internal work. ``include_admin`` is set by the route after it
    checks the caller's role.

    Returns ``(items, total)`` so the caller can render pagination. Authors are
    aggregated per thesis: the old author join duplicated a multi-author thesis
    once per author, which made a page look like repeated rows and would have
    made LIMIT/OFFSET walk the wrong rows.
    """
    submissions = (
        "SELECT t.id AS ref_id, t.title, t.created_at, p.name AS program, "
        "       'New thesis added' AS activity_type, "
        "       'Author: ' || COALESCE(a.authors, 'Unknown') AS subtitle, "
        "       'submission' AS kind "
        "FROM theses t "
        "LEFT JOIN programs p ON t.program_id = p.id "
        "LEFT JOIN ("
        "    SELECT ta.thesis_id, "
        "           string_agg(au.first_name || ' ' || au.last_name, ', ') AS authors "
        "    FROM thesis_authors ta "
        "    JOIN authors au ON ta.author_id = au.id "
        "    GROUP BY ta.thesis_id"
        ") a ON t.id = a.thesis_id"
    )
    if include_admin:
        reviews = (
            " SELECT tr.id AS ref_id, t.title, tr.created_at, p.name AS program, "
            "        CASE tr.decision "
            "            WHEN 'draft' THEN 'Review: returned to draft' "
            "            WHEN 'approved' THEN 'Review: approved' "
            "            WHEN 'published' THEN 'Review: published' "
            "            WHEN 'archived' THEN 'Review: archived' "
            "            ELSE 'Review: ' || tr.decision END AS activity_type, "
            "        'By ' || COALESCE(u.username, 'System') AS subtitle, "
            "        'review' AS kind "
            " FROM thesis_reviews tr "
            " JOIN theses t ON t.id = tr.thesis_id "
            " LEFT JOIN programs p ON p.id = t.program_id "
            " LEFT JOIN users u ON u.id = tr.reviewer_id"
        )
        imports = (
            " SELECT ij.id AS ref_id, "
            "        'Import: ' || COALESCE(ij.csv_filename, 'batch') AS title, "
            "        ij.created_at, NULL::text AS program, "
            "        CASE ij.status "
            "            WHEN 'completed' THEN 'Import completed' "
            "            WHEN 'failed' THEN 'Import failed' "
            "            WHEN 'running' THEN 'Import running' "
            "            WHEN 'queued' THEN 'Import queued' "
            "            ELSE 'Import previewed' END AS activity_type, "
            "        'Created ' || ij.created_count || ', updated ' || "
            "        ij.updated_count || ', skipped ' || ij.skipped_count AS subtitle, "
            "        'import' AS kind "
            " FROM import_jobs ij"
        )
        feed = f"{submissions} UNION ALL {reviews} UNION ALL {imports}"
    else:
        feed = submissions

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(f"SELECT COUNT(*) FROM ({feed}) AS feed")
            total = cur.fetchone()[0] or 0
            cur.execute(
                f"SELECT ref_id, title, created_at, program, activity_type, "
                f"       subtitle, kind "
                f"FROM ({feed}) AS feed "
                f"ORDER BY created_at DESC, ref_id DESC LIMIT %s OFFSET %s",
                (limit, offset),
            )
            rows = cur.fetchall()
            items = [
                {
                    "id": r[0],
                    "title": r[1],
                    "created_at": r[2].isoformat() if r[2] else None,
                    "program": r[3],
                    "activity_type": r[4],
                    "subtitle": r[5],
                    "kind": r[6],
                }
                for r in rows
            ]
            return items, total
    finally:
        put_conn(conn)


def list_security_audit_logs(
    page=1,
    limit=25,
    action=None,
    actor_id=None,
    date_from=None,
    date_to=None,
):
    """One filtered page of the security audit trail, newest first."""
    clauses = []
    params = []
    if action:
        clauses.append("action = %s")
        params.append(action)
    if actor_id is not None:
        clauses.append("actor_id = %s")
        params.append(actor_id)
    if date_from is not None:
        clauses.append("created_at >= %s")
        params.append(date_from)
    if date_to is not None:
        clauses.append("created_at <= %s")
        params.append(date_to)
    where = f" WHERE {' AND '.join(clauses)}" if clauses else ""

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                f"SELECT COUNT(*) FROM security_audit_log{where}",
                params,
            )
            total = cur.fetchone()[0] or 0
            cur.execute(
                "SELECT id, actor_id, actor_username, actor_role, action, "
                "       entity_type, entity_id, summary, details, ip_address, "
                "       user_agent, created_at "
                f"FROM security_audit_log{where} "
                "ORDER BY created_at DESC, id DESC LIMIT %s OFFSET %s",
                params + [limit, (page - 1) * limit],
            )
            rows = cur.fetchall()
            items = [
                {
                    "id": r[0],
                    "actor_id": r[1],
                    "actor_username": r[2],
                    "actor_role": r[3],
                    "action": r[4],
                    "entity_type": r[5],
                    "entity_id": r[6],
                    "summary": r[7],
                    "details": r[8],
                    "ip_address": r[9],
                    "user_agent": r[10],
                    "created_at": r[11].isoformat() if r[11] else None,
                }
                for r in rows
            ]
            return items, total
    finally:
        put_conn(conn)


def semantic_search(query_vector, limit=10):
    """Find theses by embedding cosine similarity.

    One row per thesis: with full-PDF chunking a thesis owns many chunk
    rows, so the inner query picks each thesis's NEAREST chunk
    (DISTINCT ON + ORDER BY distance) and the outer query ranks theses by
    that best-chunk similarity. Without this a 40-page thesis would occupy
    many slots in its own result list.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            try:
                cur.execute("SET LOCAL hnsw.ef_search = 100")
            except Exception:
                pass
            cur.execute(
                "SELECT * FROM ("
                "SELECT DISTINCT ON (t.id) t.id, t.title, t.abstract, t.research_type, "
                "       t.program_id, t.status, "
                "       1 - (e.embedding <=> %s::vector) AS similarity "
                "FROM thesis_embeddings e "
                "JOIN theses t ON e.thesis_id = t.id "
                "WHERE t.status = 'published' "
                "ORDER BY t.id, e.embedding <=> %s::vector"
                ") s ORDER BY similarity DESC "
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

            cur.execute(
                "SELECT COUNT(DISTINCT t.program_id) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s)",
                (email,),
            )
            programs = cur.fetchone()[0] or 0

            return {
                "theses": total_theses,
                "advisees": total_advisees,
                "published": published,
                "active_projects": active_projects,
                "programs": programs,
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


def get_faculty_theses(email, user_id=None, page=1, per_page=50):
    """Theses advised by (or submitted by) this faculty member, all statuses."""
    return list_theses(adviser_email=email, creator_id=user_id, status=None, page=page, per_page=per_page)


def get_faculty_advisees(email):
    """Authors linked to theses advised by this faculty member."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT a.id, a.first_name, a.middle_name, a.last_name, a.email, "
                "       COUNT(DISTINCT ta.thesis_id) AS thesis_count, "
                "       MAX(t.updated_at) AS last_activity "
                "FROM thesis_advisers tadv "
                "JOIN advisers adv ON tadv.adviser_id = adv.id "
                "JOIN thesis_authors ta ON ta.thesis_id = tadv.thesis_id "
                "JOIN authors a ON ta.author_id = a.id "
                "JOIN theses t ON t.id = tadv.thesis_id "
                "WHERE LOWER(adv.email) = LOWER(%s) "
                "GROUP BY a.id, a.first_name, a.middle_name, a.last_name, a.email "
                "ORDER BY last_activity DESC NULLS LAST, a.last_name ASC",
                (email,),
            )
            return [
                {
                    "id": r[0],
                    "first_name": r[1],
                    "middle_name": r[2],
                    "last_name": r[3],
                    "email": r[4],
                    "thesis_count": r[5],
                    "last_activity": r[6].isoformat() if r[6] else None,
                }
                for r in cur.fetchall()
            ]
    finally:
        put_conn(conn)


def get_faculty_analytics(email):
    """Status + program breakdown of theses advised by this faculty member."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT t.status, COUNT(*) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s) "
                "GROUP BY t.status",
                (email,),
            )
            by_status = {r[0]: r[1] for r in cur.fetchall()}
            cur.execute(
                "SELECT p.name, COUNT(*) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "JOIN programs p ON t.program_id = p.id "
                "WHERE LOWER(a.email) = LOWER(%s) "
                "GROUP BY p.name ORDER BY COUNT(*) DESC",
                (email,),
            )
            by_program = [{"program": r[0], "count": r[1]} for r in cur.fetchall()]
            cur.execute(
                "SELECT ay.name, COUNT(*) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "JOIN academic_years ay ON t.academic_year_id = ay.id "
                "WHERE LOWER(a.email) = LOWER(%s) "
                "GROUP BY ay.name ORDER BY ay.name DESC",
                (email,),
            )
            by_year = [{"year": r[0], "count": r[1]} for r in cur.fetchall()]
            cur.execute(
                "SELECT t.research_type, COUNT(*) FROM theses t "
                "JOIN thesis_advisers ta ON t.id = ta.thesis_id "
                "JOIN advisers a ON ta.adviser_id = a.id "
                "WHERE LOWER(a.email) = LOWER(%s) "
                "GROUP BY t.research_type ORDER BY COUNT(*) DESC",
                (email,),
            )
            by_type = [{"type": r[0], "count": r[1]} for r in cur.fetchall()]
            total = sum(by_status.values())
            return {
                "total": total,
                "by_status": by_status,
                "by_program": by_program,
                "by_year": by_year,
                "by_type": by_type,
            }
    finally:
        put_conn(conn)


# ── Import jobs (admin bulk import) ────────────────────────────────────────

_IMPORT_JOB_FIELDS = {
    "status",
    "csv_filename",
    "total_rows",
    "processed_rows",
    "created_count",
    "updated_count",
    "skipped_count",
    "error_count",
    "indexed_count",
    "message",
    "rows",
    "started_at",
    "finished_at",
}


def _import_job_dict(row):
    return {
        "id": row[0],
        "status": row[1],
        "created_by": row[2],
        "csv_filename": row[3],
        "total_rows": row[4],
        "processed_rows": row[5],
        "created_count": row[6],
        "updated_count": row[7],
        "skipped_count": row[8],
        "error_count": row[9],
        "indexed_count": row[10],
        "message": row[11],
        "rows": row[12] or [],
        "created_at": row[13].isoformat() if row[13] else None,
        "started_at": row[14].isoformat() if row[14] else None,
        "finished_at": row[15].isoformat() if row[15] else None,
    }


def create_import_job(created_by=None, csv_filename=None):
    """Create a previewed import job and return its id."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO import_jobs (status, created_by, csv_filename) "
                "VALUES ('previewed', %s, %s) RETURNING id",
                (created_by, csv_filename),
            )
            job_id = cur.fetchone()[0]
        conn.commit()
        return job_id
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def get_import_job(job_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, status, created_by, csv_filename, total_rows, "
                "       processed_rows, created_count, updated_count, skipped_count, "
                "       error_count, indexed_count, message, rows, created_at, "
                "       started_at, finished_at "
                "FROM import_jobs WHERE id = %s",
                (job_id,),
            )
            row = cur.fetchone()
            return _import_job_dict(row) if row else None
    finally:
        put_conn(conn)


def update_import_job(job_id, **fields):
    """Update any subset of the job's progress/report columns."""
    import json

    fields = {k: v for k, v in fields.items() if k in _IMPORT_JOB_FIELDS}
    if not fields:
        return get_import_job(job_id)

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            set_parts = []
            params = []
            for key, value in fields.items():
                if key == "rows":
                    set_parts.append("rows = %s::jsonb")
                    params.append(json.dumps(value or []))
                else:
                    set_parts.append(f"{key} = %s")
                    params.append(value)
            params.append(job_id)
            cur.execute(
                f"UPDATE import_jobs SET {', '.join(set_parts)} WHERE id = %s",
                params,
            )
        conn.commit()
        return get_import_job(job_id)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def delete_import_job(job_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM import_jobs WHERE id = %s", (job_id,))
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def list_import_job_ids():
    """Every job id, used to find staging folders that lost their row."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM import_jobs")
            return {row[0] for row in cur.fetchall()}
    finally:
        put_conn(conn)


def active_import_job_count(exclude_id=None):
    """Jobs queued/running right now. One batch at a time avoids fighting
    over the embedding model and OCR lock."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            if exclude_id is None:
                cur.execute(
                    "SELECT COUNT(*) FROM import_jobs "
                    "WHERE status IN ('queued', 'running')"
                )
            else:
                cur.execute(
                    "SELECT COUNT(*) FROM import_jobs "
                    "WHERE status IN ('queued', 'running') AND id <> %s",
                    (exclude_id,),
                )
            return cur.fetchone()[0]
    finally:
        put_conn(conn)


def mark_stale_import_jobs():
    """Called at startup: a job left running by a previous process is dead."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE import_jobs SET status = 'failed', "
                "       message = 'Server restarted while the import was running', "
                "       finished_at = NOW() "
                "WHERE status IN ('queued', 'running')"
            )
            count = cur.rowcount
        conn.commit()
        return count
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def recommend_for_thesis(thesis_id, limit=5):
    """Find similar theses to a given thesis using its embedding chunks.

    The source thesis may own many chunks; we use its FIRST chunk's
    embedding (the title+abstract lead chunk written first by
    replace_thesis_embeddings) as the query, then dedupe candidates to
    one row per thesis via the nearest-chunk subquery (same pattern as
    semantic_search).
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Get the embedding of the source thesis (lead chunk = lowest id)
            cur.execute(
                "SELECT embedding FROM thesis_embeddings WHERE thesis_id = %s ORDER BY id LIMIT 1",
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                return []
            source_embedding = row[0]

            try:
                cur.execute("SET LOCAL hnsw.ef_search = 100")
            except Exception:
                pass

            # Find similar theses (excluding the source itself)
            cur.execute(
                "SELECT * FROM ("
                "SELECT DISTINCT ON (t.id) t.id, t.title, t.abstract, t.research_type, "
                "       t.program_id, t.status, "
                "       1 - (e.embedding <=> %s::vector) AS similarity "
                "FROM thesis_embeddings e "
                "JOIN theses t ON e.thesis_id = t.id "
                "WHERE t.status = 'published' AND t.id != %s "
                "ORDER BY t.id, e.embedding <=> %s::vector"
                ") s ORDER BY similarity DESC "
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


# ── Profile-based ranking (no extra tables) ────────────────────────────────
# The student's history lives on their device; this module only turns the
# thesis ids they send into a centroid and ranks against it. Impressions are
# written to the existing `recommendation_logs` table.


def _vector_list(value):
    """pgvector returns '[0.1,0.2,...]'; normalise it to a list of floats.

    Kept dependency-free so MMR never depends on a pgvector adapter being
    registered. Returns None when the value cannot be parsed.
    """
    if value is None:
        return None
    if isinstance(value, (list, tuple)):
        return [float(x) for x in value]
    try:
        text = str(value).strip().strip("[]")
        return [float(part) for part in text.split(",")] if text else None
    except (TypeError, ValueError):
        return None


def recommend_for_profile(thesis_ids, weights, exclude_ids=None, limit=4):
    """Rank published theses by similarity to a weighted centroid.

    `thesis_ids` and `weights` are parallel lists; repeating an id simply
    increases its weight. Each thesis contributes its lead chunk (lowest id),
    the same convention as recommend_for_thesis, so one long PDF cannot
    dominate the profile.

    The centroid is averaged in Python: pgvector has no `vector * scalar`
    operator on every install, and a handful of 384-d vectors is trivial to
    combine here.

    Returns dicts ordered by descending `similarity`.
    """
    if not thesis_ids or len(thesis_ids) != len(weights):
        return []
    excluded = list(dict.fromkeys(exclude_ids or thesis_ids))
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT DISTINCT ON (thesis_id) thesis_id, embedding "
                "FROM thesis_embeddings WHERE thesis_id = ANY(%s) "
                "ORDER BY thesis_id, id",
                (thesis_ids,),
            )
            vectors = {}
            for thesis_id, embedding in cur.fetchall():
                vec = _vector_list(embedding)
                if vec:
                    vectors[thesis_id] = vec

            dimension = len(next(iter(vectors.values()))) if vectors else 0
            if not dimension:
                return []

            acc = [0.0] * dimension
            total_weight = 0.0
            for thesis_id, weight in zip(thesis_ids, weights):
                vec = vectors.get(thesis_id)
                if not vec or len(vec) != dimension:
                    continue
                for index, value in enumerate(vec):
                    acc[index] += value * weight
                total_weight += weight
            if not total_weight:
                return []
            centroid = [value / total_weight for value in acc]

            try:
                cur.execute("SET LOCAL hnsw.ef_search = 100")
            except Exception:
                pass
            cur.execute(
                "SELECT * FROM ("
                "  SELECT DISTINCT ON (t.id) t.id, t.title, t.abstract, t.research_type, "
                "         t.program_id, t.status, "
                "         1 - (e.embedding <=> %s::vector) AS similarity "
                "  FROM thesis_embeddings e "
                "  JOIN theses t ON e.thesis_id = t.id "
                "  WHERE t.status = 'published' AND NOT (t.id = ANY(%s)) "
                "  ORDER BY t.id, e.embedding <=> %s::vector"
                ") s ORDER BY similarity DESC "
                "LIMIT %s",
                (centroid, excluded, centroid, limit),
            )
            rows = cur.fetchall()
            if not rows or rows[0][6] is None:
                return []
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


def log_recommendations(user_id, source_thesis_id, items):
    """Write one `recommendation_logs` row per thesis shown.

    This is the only write the recommender performs, and it uses the table
    exactly as the manuscript describes it (FR-17).
    """
    if not items:
        return 0
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.executemany(
                "INSERT INTO recommendation_logs "
                "(user_id, source_thesis_id, recommended_thesis_id, similarity_score) "
                "VALUES (%s, %s, %s, %s)",
                [
                    (user_id, source_thesis_id, item["thesis"]["id"], item["score"])
                    for item in items
                ],
            )
        conn.commit()
        return len(items)
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)


def log_search(user_id, query, result_count, filters=None):
    """Persist one search call in the existing `search_logs` table.

    `filters` is stored as JSONB; the column already exists and stays NULL
    when no filter was applied. Callers treat logging as diagnostics, so this
    never decides whether a search succeeds.
    """
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO search_logs (user_id, query, filters, result_count) "
                "VALUES (%s, %s, %s::jsonb, %s)",
                (
                    user_id,
                    query,
                    json.dumps(filters) if filters else None,
                    result_count,
                ),
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        put_conn(conn)
