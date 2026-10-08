-- =============================================================
-- CScholar — IT 108 Lab Activity 5
-- PostgreSQL Views, PL/pgSQL, Functions, Procedures, Triggers
-- Schema: ceit_repo (16 tables, see db/schema.sql)
-- File: db/logic/cscholar_lab5_logic.sql
--
-- RUN ORDER (dependency-safe, idempotent):
--   1. psql -U postgres -d cscholar -f db/schema.sql   (once)
--   2. psql -U postgres -d cscholar -f db/seed.sql     (once, dev only)
--   3. psql -U postgres -d cscholar -f db/logic/cscholar_lab5_logic.sql
--
-- This script is re-runnable (CREATE OR REPLACE / IF NOT EXISTS /
-- DROP TRIGGER IF EXISTS). Run only on a DEVELOPMENT copy.
-- =============================================================
SET search_path TO ceit_repo;

-- =============================================================
-- 0. AUDIT TABLE (new, required by Trigger 2)
-- NOTE: thesis_id is intentionally WITHOUT a foreign key so that
-- DELETE audits survive the deletion of the parent thesis row.
-- If it had ON DELETE CASCADE, deleting a thesis would delete its
-- own audit trail. title snapshot preserves evidence.
-- =============================================================
CREATE TABLE IF NOT EXISTS ceit_repo.thesis_audit_log (
    id           SERIAL PRIMARY KEY,
    thesis_id    INTEGER NOT NULL,
    thesis_title VARCHAR(300),
    action       VARCHAR(20) NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    old_status   VARCHAR(20),
    new_status   VARCHAR(20),
    changed_at   TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_thesis ON ceit_repo.thesis_audit_log(thesis_id);

-- =============================================================
-- 1. VIEWS
-- =============================================================

-- V1: v_published_thesis_listing
-- Consumer: Flutter browse/search list + GET /api/theses (FR-18, FR-06/07/08)
-- Purpose: one reusable join students/faculty hit constantly.
-- Security: exposes NO password_hash, NO emails, NO embeddings.
CREATE OR REPLACE VIEW ceit_repo.v_published_thesis_listing AS
SELECT
    t.id            AS thesis_id,
    t.title,
    t.abstract,
    t.research_type,
    t.status,
    p.code          AS program_code,
    p.name          AS program_name,
    ay.name         AS academic_year,
    u.username      AS creator_username,
    COALESCE((
        SELECT string_agg(a.first_name || ' ' || a.last_name, ', ' ORDER BY ta.order_index)
        FROM ceit_repo.thesis_authors ta
        JOIN ceit_repo.authors a ON a.id = ta.author_id
        WHERE ta.thesis_id = t.id
    ), '') AS authors,
    COALESCE((
        SELECT string_agg(c.name, ', ' ORDER BY c.name)
        FROM ceit_repo.thesis_categories tc
        JOIN ceit_repo.categories c ON c.id = tc.category_id
        WHERE tc.thesis_id = t.id
    ), '') AS categories,
    t.created_at,
    t.updated_at
FROM ceit_repo.theses t
JOIN ceit_repo.programs p       ON p.id  = t.program_id
JOIN ceit_repo.academic_years ay ON ay.id = t.academic_year_id
LEFT JOIN ceit_repo.users u     ON u.id  = t.creator_id
WHERE t.status IN ('approved', 'published');

-- V2: v_thesis_admin_overview
-- Consumer: Admin dashboard "repository health" (FR-09, FR-10, FR-15)
-- Purpose: per-thesis completeness: authors? PDF? embeddings?
-- Security: no credentials, no vectors, counts only.
CREATE OR REPLACE VIEW ceit_repo.v_thesis_admin_overview AS
SELECT
    t.id              AS thesis_id,
    t.title,
    t.status,
    t.research_type,
    p.code            AS program_code,
    ay.name           AS academic_year,
    COUNT(DISTINCT ta.author_id)::int AS author_count,
    COUNT(DISTINCT tf.id)::int        AS file_count,
    COUNT(DISTINCT te.id)::int        AS embedding_chunks,
    (t.pdf_url IS NOT NULL)           AS has_pdf,
    t.created_at,
    t.updated_at
FROM ceit_repo.theses t
JOIN ceit_repo.programs p        ON p.id  = t.program_id
JOIN ceit_repo.academic_years ay ON ay.id = t.academic_year_id
LEFT JOIN ceit_repo.thesis_authors ta    ON ta.thesis_id = t.id
LEFT JOIN ceit_repo.thesis_files tf      ON tf.thesis_id = t.id
LEFT JOIN ceit_repo.thesis_embeddings te ON te.thesis_id = t.id
GROUP BY t.id, t.title, t.status, t.research_type,
         p.code, ay.name, t.pdf_url, t.created_at, t.updated_at;

-- MV candidate: mv_thesis_counts_by_program_year
-- Decision: IMPLEMENTED (justified).
-- Why materialize: admin report GROUP BY over theses+programs+years,
--   hit on every dashboard load; staleness of up to 24h is acceptable
--   for counts (not for search). Small data now, but avoids repeated
--   aggregation as years/chunks grow.
-- Refresh: nightly cron OR after publish workflow calls:
--   REFRESH MATERIALIZED VIEW CONCURRENTLY ceit_repo.mv_thesis_counts_by_program_year;
-- Staleness guard: API shows `refreshed_at` (pg_matviews) beside counts.
DROP MATERIALIZED VIEW IF EXISTS ceit_repo.mv_thesis_counts_by_program_year;
CREATE MATERIALIZED VIEW ceit_repo.mv_thesis_counts_by_program_year AS
SELECT
    p.code   AS program_code,
    ay.name  AS academic_year,
    t.research_type,
    COUNT(*)::int AS thesis_count,
    COUNT(*) FILTER (WHERE t.status = 'published')::int AS published_count
FROM ceit_repo.theses t
JOIN ceit_repo.programs p        ON p.id  = t.program_id
JOIN ceit_repo.academic_years ay ON ay.id = t.academic_year_id
GROUP BY p.code, ay.name, t.research_type
WITH DATA;

-- Unique index required for CONCURRENTLY refresh (no blocking reads).
CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_counts
    ON ceit_repo.mv_thesis_counts_by_program_year
    (program_code, academic_year, research_type);

-- =============================================================
-- 2. FUNCTIONS
-- =============================================================

-- F1: fn_can_transition_status (scalar validation)
-- Rule: thesis lifecycle draft -> approved -> published -> archived (FR-08)
-- Why DB-side: must hold regardless of client (Flutter web/mobile,
--   psql, Supabase editor). Single source of truth reused by trigger
--   AND procedure AND backend pre-check (defensive duplicate).
-- Volatility: IMMUTABLE, read-only (no writes).
CREATE OR REPLACE FUNCTION ceit_repo.fn_can_transition_status(
    p_current TEXT,
    p_next    TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_allowed TEXT[] := ARRAY['draft','approved','published','archived'];
BEGIN
    IF p_current IS NULL OR p_next IS NULL THEN
        RAISE EXCEPTION 'Status transition requires non-null values (got % -> %)',
            p_current, p_next;
    END IF;
    IF NOT (p_current = ANY (v_allowed)) THEN
        RAISE EXCEPTION 'Unknown current status: %', p_current;
    END IF;
    IF NOT (p_next = ANY (v_allowed)) THEN
        RAISE EXCEPTION 'Unknown target status: %', p_next;
    END IF;
    IF p_current = p_next THEN
        RETURN FALSE;  -- no-op is not a transition
    END IF;
    -- Allowed edges:
    IF p_current = 'draft'    AND p_next IN ('approved','archived') THEN RETURN TRUE; END IF;
    IF p_current = 'approved' AND p_next IN ('published','draft')   THEN RETURN TRUE; END IF;
    IF p_current = 'published' AND p_next = 'archived'              THEN RETURN TRUE; END IF;
    -- archived is terminal (must re-publish via approved flow in API, not direct)
    RETURN FALSE;
END;
$$;

-- F2: fn_get_thesis_full_info (set-returning retrieval)
-- Consumer: thesis detail page + GET /api/theses/:id (FR-06, FR-11..FR-14)
-- Why DB-side: one stable contract assembling 7 tables + string_aggs;
--   reused by web, mobile, and admin without duplicating JOIN logic.
-- Volatility: STABLE, read-only. Raises meaningful exception if missing.
CREATE OR REPLACE FUNCTION ceit_repo.fn_get_thesis_full_info(p_thesis_id BIGINT)
RETURNS TABLE (
    thesis_id     INTEGER,
    title         VARCHAR,
    abstract      TEXT,
    research_type VARCHAR,
    status        VARCHAR,
    program_code  VARCHAR,
    program_name  VARCHAR,
    academic_year VARCHAR,
    authors       TEXT,
    advisers      TEXT,
    categories    TEXT,
    keywords      TEXT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_found INTEGER;
BEGIN
    IF p_thesis_id IS NULL OR p_thesis_id <= 0 THEN
        RAISE EXCEPTION 'Invalid thesis id: % (must be a positive integer)', p_thesis_id;
    END IF;

    SELECT t.id INTO v_found
    FROM ceit_repo.theses t
    WHERE t.id = p_thesis_id;

    IF v_found IS NULL THEN
        RAISE EXCEPTION 'Thesis % was not found', p_thesis_id;
    END IF;

    RETURN QUERY
    SELECT
        t.id, t.title, t.abstract, t.research_type, t.status,
        p.code, p.name, ay.name,
        COALESCE((
            SELECT string_agg(a.first_name || ' ' || a.last_name, ', ' ORDER BY ta.order_index)
            FROM ceit_repo.thesis_authors ta
            JOIN ceit_repo.authors a ON a.id = ta.author_id
            WHERE ta.thesis_id = t.id), '')::TEXT,
        COALESCE((
            SELECT string_agg(ad.first_name || ' ' || ad.last_name, ', ' ORDER BY ad.last_name)
            FROM ceit_repo.thesis_advisers tad
            JOIN ceit_repo.advisers ad ON ad.id = tad.adviser_id
            WHERE tad.thesis_id = t.id), '')::TEXT,
        COALESCE((
            SELECT string_agg(c.name, ', ' ORDER BY c.name)
            FROM ceit_repo.thesis_categories tc
            JOIN ceit_repo.categories c ON c.id = tc.category_id
            WHERE tc.thesis_id = t.id), '')::TEXT,
        COALESCE((
            SELECT string_agg(k.term, ', ' ORDER BY k.term)
            FROM ceit_repo.thesis_keywords tk
            JOIN ceit_repo.keywords k ON k.id = tk.keyword_id
            WHERE tk.thesis_id = t.id), '')::TEXT
    FROM ceit_repo.theses t
    JOIN ceit_repo.programs p        ON p.id  = t.program_id
    JOIN ceit_repo.academic_years ay ON ay.id = t.academic_year_id
    WHERE t.id = p_thesis_id;
END;
$$;

-- =============================================================
-- 3. STORED PROCEDURE
-- P01: sp_submit_thesis_with_links (multi-step atomic submit)
-- Operation: INSERT theses (draft) + thesis_authors + thesis_categories
--   in ONE database transaction. Caller = POST /api/theses.
-- Why PROCEDURE (not function): explicit command with side effects,
--   CALL semantics, OUT id; must not be embedded in SELECT expressions.
-- =============================================================
CREATE OR REPLACE PROCEDURE ceit_repo.sp_submit_thesis_with_links(
    IN  p_title            VARCHAR,
    IN  p_abstract         TEXT,
    IN  p_research_type    VARCHAR,
    IN  p_program_id       INTEGER,
    IN  p_academic_year_id INTEGER,
    IN  p_creator_id       INTEGER,
    IN  p_author_ids       INTEGER[],
    IN  p_category_ids     INTEGER[],
    OUT p_new_thesis_id    INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_aid INTEGER;
    v_cid INTEGER;
BEGIN
    -- ---- Precondition checks (invalid input) ----
    IF p_title IS NULL OR btrim(p_title) = '' THEN
        RAISE EXCEPTION 'Title must not be empty';
    END IF;
    IF p_abstract IS NULL OR btrim(p_abstract) = '' THEN
        RAISE EXCEPTION 'Abstract must not be empty';
    END IF;
    IF p_research_type NOT IN ('Thesis','Capstone') THEN
        RAISE EXCEPTION 'Invalid research_type: % (must be Thesis or Capstone)', p_research_type;
    END IF;
    IF p_author_ids IS NULL OR cardinality(p_author_ids) = 0 THEN
        RAISE EXCEPTION 'At least one author is required';
    END IF;
    -- ---- Existence checks (record-not-found, FK guard with clean messages) ----
    IF NOT EXISTS (SELECT 1 FROM ceit_repo.programs WHERE id = p_program_id) THEN
        RAISE EXCEPTION 'Program % was not found', p_program_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ceit_repo.academic_years WHERE id = p_academic_year_id) THEN
        RAISE EXCEPTION 'Academic year % was not found', p_academic_year_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ceit_repo.users WHERE id = p_creator_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Creator % was not found or is deactivated', p_creator_id;
    END IF;
    -- ---- Multi-step writes (atomic: any failure rolls back all) ----
    INSERT INTO ceit_repo.theses
        (title, abstract, research_type, program_id, academic_year_id, status, creator_id)
    VALUES
        (btrim(p_title), p_abstract, p_research_type, p_program_id,
         p_academic_year_id, 'draft', p_creator_id)
    RETURNING id INTO p_new_thesis_id;

    FOREACH v_aid IN ARRAY p_author_ids LOOP
        IF NOT EXISTS (SELECT 1 FROM ceit_repo.authors WHERE id = v_aid) THEN
            RAISE EXCEPTION 'Author % was not found', v_aid;
        END IF;
        INSERT INTO ceit_repo.thesis_authors(thesis_id, author_id, order_index)
        VALUES (p_new_thesis_id, v_aid,
                COALESCE(array_position(p_author_ids, v_aid), 1));
    END LOOP;

    IF p_category_ids IS NOT NULL THEN
        FOREACH v_cid IN ARRAY p_category_ids LOOP
            IF NOT EXISTS (SELECT 1 FROM ceit_repo.categories WHERE id = v_cid) THEN
                RAISE EXCEPTION 'Category % was not found', v_cid;
            END IF;
            INSERT INTO ceit_repo.thesis_categories(thesis_id, category_id)
            VALUES (p_new_thesis_id, v_cid);
        END LOOP;
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Duplicate link: thesis link already exists (%)', SQLERRM;
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Related record missing while submitting thesis (%)', SQLERRM;
    WHEN OTHERS THEN
        -- Re-raise with context, never swallow; SQLSTATE preserved for API mapping.
        RAISE EXCEPTION 'sp_submit_thesis_with_links failed: %', SQLERRM;
END;
$$;

-- =============================================================
-- 4. TRIGGERS
-- =============================================================

-- TG-A: tg_validate_thesis_status_transition (BEFORE UPDATE)
-- Rule: lifecycle enforcement + auto-maintain updated_at.
-- Why BEFORE: must reject bad NEW.status before the row is written,
--   and mutate NEW.updated_at. A CHECK constraint cannot see OLD.
-- Why not API-only: direct psql/Supabase writes would bypass the API.
CREATE OR REPLACE FUNCTION ceit_repo.tg_validate_thesis_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        IF NOT ceit_repo.fn_can_transition_status(OLD.status, NEW.status) THEN
            RAISE EXCEPTION
                'Invalid thesis status transition from % to %. Allowed: draft->approved/archived; approved->published/draft; published->archived',
                OLD.status, NEW.status
                USING ERRCODE = 'P0001';
        END IF;
    END IF;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_theses_validate_status ON ceit_repo.theses;
CREATE TRIGGER trg_theses_validate_status
BEFORE UPDATE ON ceit_repo.theses
FOR EACH ROW
EXECUTE FUNCTION ceit_repo.tg_validate_thesis_status_transition();

-- TG-B: tg_audit_thesis_change (AFTER INSERT/UPDATE/DELETE)
-- Rule: every change to theses leaves an audit row (FR-19 support).
-- Why AFTER: audit only fires if the write actually succeeded.
-- Why not API-only: bulk fixes, admin SQL, and future clients would
--   otherwise leave no trail. FOR EACH ROW because audit is per-thesis.
CREATE OR REPLACE FUNCTION ceit_repo.tg_audit_thesis_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO ceit_repo.thesis_audit_log(thesis_id, thesis_title, action, old_status, new_status)
        VALUES (NEW.id, NEW.title, 'INSERT', NULL, NEW.status);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO ceit_repo.thesis_audit_log(thesis_id, thesis_title, action, old_status, new_status)
        VALUES (NEW.id, NEW.title, 'UPDATE', OLD.status, NEW.status);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO ceit_repo.thesis_audit_log(thesis_id, thesis_title, action, old_status, new_status)
        VALUES (OLD.id, OLD.title, 'DELETE', OLD.status, NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_theses_audit ON ceit_repo.theses;
CREATE TRIGGER trg_theses_audit
AFTER INSERT OR UPDATE OR DELETE ON ceit_repo.theses
FOR EACH ROW
EXECUTE FUNCTION ceit_repo.tg_audit_thesis_change();

-- Also keep users.updated_at fresh (lightweight, same pattern, documented
-- here but NOT counted toward the required 2 thesis triggers).
CREATE OR REPLACE FUNCTION ceit_repo.tg_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_users_updated_at ON ceit_repo.users;
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON ceit_repo.users
FOR EACH ROW
EXECUTE FUNCTION ceit_repo.tg_set_updated_at();
