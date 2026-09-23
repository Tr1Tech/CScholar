-- =============================================================
-- CScholar — CEIT Thesis & Capstone Repository
-- Phase 2: Database schema (PostgreSQL + pgvector)
-- =============================================================
-- Scope: CEIT only (no colleges table). Limited academic year.
-- Embedding dimension = 384 (matches Sentence Transformers
--   all-MiniLM-L6-v2). If the model ever changes, this MUST change.
--
-- HOW TO RUN (once PostgreSQL + pgvector are installed):
--   psql -U postgres -d cscholar -f schema.sql
--   psql -U postgres -d cscholar -f seed.sql
-- =============================================================

-- 0. Create and point all objects at the ceit_repo schema.
CREATE SCHEMA IF NOT EXISTS ceit_repo;
SET search_path TO ceit_repo;

-- Enable the pgvector extension (must be installed in Postgres first)
CREATE EXTENSION IF NOT EXISTS vector;

-- 1. users -----------------------------------------------------
CREATE TABLE users (
    id           SERIAL PRIMARY KEY,
    username     VARCHAR(50) NOT NULL UNIQUE,
    email        VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role         VARCHAR(20) NOT NULL CHECK (role IN ('student', 'faculty', 'admin')),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 2. programs (CEIT departments) -------------------------------
-- Colleges table intentionally removed: CEIT is the fixed scope.
CREATE TABLE programs (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    code        VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3. academic_years -------------------------------------------
CREATE TABLE academic_years (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(20) NOT NULL UNIQUE,   -- e.g. '2025-2026'
    start_year INTEGER NOT NULL,
    end_year   INTEGER NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 4. theses (main entity) -------------------------------------
CREATE TABLE theses (
    id               SERIAL PRIMARY KEY,
    title            VARCHAR(300) NOT NULL,
    abstract         TEXT NOT NULL,
    research_type    VARCHAR(20) NOT NULL CHECK (research_type IN ('Thesis', 'Capstone')),
    program_id       INTEGER NOT NULL REFERENCES programs(id) ON DELETE RESTRICT,
    academic_year_id INTEGER NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    status           VARCHAR(20) NOT NULL DEFAULT 'draft'
                        CHECK (status IN ('draft', 'approved', 'published', 'archived')),
    creator_id       INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    pdf_url          VARCHAR(500)
);

-- 5. authors --------------------------------------------------
CREATE TABLE authors (
    id          SERIAL PRIMARY KEY,
    first_name  VARCHAR(80) NOT NULL,
    middle_name VARCHAR(80),
    last_name   VARCHAR(80) NOT NULL,
    email       VARCHAR(120),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 6. thesis_authors (N:N) -------------------------------------
CREATE TABLE thesis_authors (
    thesis_id  INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    author_id  INTEGER NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (thesis_id, author_id)
);

-- 7. advisers -------------------------------------------------
CREATE TABLE advisers (
    id          SERIAL PRIMARY KEY,
    first_name  VARCHAR(80) NOT NULL,
    middle_name VARCHAR(80),
    last_name   VARCHAR(80) NOT NULL,
    email       VARCHAR(120),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 8. thesis_advisers (N:N) ------------------------------------
CREATE TABLE thesis_advisers (
    thesis_id  INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    adviser_id INTEGER NOT NULL REFERENCES advisers(id) ON DELETE CASCADE,
    PRIMARY KEY (thesis_id, adviser_id)
);

-- 9. categories -----------------------------------------------
CREATE TABLE categories (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 10. thesis_categories (N:N) ---------------------------------
CREATE TABLE thesis_categories (
    thesis_id   INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (thesis_id, category_id)
);

-- 11. keywords ------------------------------------------------
CREATE TABLE keywords (
    id          SERIAL PRIMARY KEY,
    term        VARCHAR(100) NOT NULL UNIQUE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 12. thesis_keywords (N:N) -----------------------------------
CREATE TABLE thesis_keywords (
    thesis_id  INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    keyword_id INTEGER NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
    PRIMARY KEY (thesis_id, keyword_id)
);

-- 13. thesis_files --------------------------------------------
-- Stores METADATA only. Large PDF binaries stay on disk/object storage.
CREATE TABLE thesis_files (
    id          SERIAL PRIMARY KEY,
    thesis_id   INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    filename    VARCHAR(255) NOT NULL,
    file_path   VARCHAR(512) NOT NULL,
    file_size   BIGINT,
    mime_type   VARCHAR(100),
    uploaded_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    uploaded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 14. thesis_embeddings (pgvector) ----------------------------
-- One row per text chunk of a thesis. DIMENSION = 384.
CREATE TABLE thesis_embeddings (
    id          SERIAL PRIMARY KEY,
    thesis_id   INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    chunk_text  TEXT NOT NULL,
    embedding   vector(384),
    model_name  VARCHAR(100) NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 15. search_logs ---------------------------------------------
CREATE TABLE search_logs (
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER REFERENCES users(id) ON DELETE SET NULL,
    query        TEXT,
    filters      JSONB,            -- e.g. {"program_id":2,"year":2025}
    result_count INTEGER,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 16. recommendation_logs -------------------------------------
CREATE TABLE recommendation_logs (
    id                    SERIAL PRIMARY KEY,
    user_id               INTEGER REFERENCES users(id) ON DELETE SET NULL,
    source_thesis_id      INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    recommended_thesis_id INTEGER NOT NULL REFERENCES theses(id) ON DELETE CASCADE,
    similarity_score      REAL,
    created_at            TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ===================== INDEXES =====================
CREATE INDEX idx_theses_program       ON theses(program_id);
CREATE INDEX idx_theses_academic_year ON theses(academic_year_id);
CREATE INDEX idx_theses_status        ON theses(status);
CREATE INDEX idx_theses_creator       ON theses(creator_id);
CREATE INDEX idx_embeddings_thesis    ON thesis_embeddings(thesis_id);
-- Vector similarity index (HNSW). Exact scan also works for small data;
-- HNSW keeps it fast when more academic years are added later.
CREATE INDEX idx_embeddings_vec
    ON thesis_embeddings USING hnsw (embedding vector_cosine_ops);
