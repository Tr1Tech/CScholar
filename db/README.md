# Phase 2 — Database Setup (PostgreSQL + pgvector)

This folder contains the CScholar database schema, mock seed data, and the
Lab 5 logic (views, functions, procedure, triggers).

## Files
- `schema.sql` — tables + pgvector extension + indexes (CEIT-only scope, no colleges table), including the operational `import_jobs` table used by the admin Bulk Import screen
- `bootstrap.sql` — real reference data (CEIT programs, academic years). Idempotent. Required before any thesis can be created.
- `import_template.csv` — column contract for the real-data import batches.
- `seed.sql` — FICTIONAL sample data (CEIT programs, AY 2025-2026, 3 sample theses). Not real CSU records. Development/demo only.
- `setup.md` — how to install & run PostgreSQL + pgvector, then apply this schema.
- `logic/cscholar_lab5_logic.sql` — views, PL/pgSQL, triggers (run last).

## Quick run (after Postgres + pgvector are ready)

From the **repo root**:

```bash
createdb cscholar
psql -U postgres -d cscholar -f db/schema.sql
psql -U postgres -d cscholar -f db/bootstrap.sql
psql -U postgres -d cscholar -f db/logic/cscholar_lab5_logic.sql
```

Then create the first administrator from `backend/` (the API cannot do this on an
empty database — registration always creates students):

```bash
cd backend
venv\Scripts\python scripts\bootstrap_admin.py
```

For a demo database only, `psql -U postgres -d cscholar -f db/seed.sql` adds
fictional theses on top. Never load `seed.sql` into a database that holds real
records.

Every object is created in the `ceit_repo` schema. A new `psql` session does not
inherit the script's `search_path`, so query with the prefix:

```bash
psql -U postgres -d cscholar -c "SELECT COUNT(*) FROM ceit_repo.theses;"
```

## Embedding dimension
`thesis_embeddings.embedding` is `vector(384)` to match Sentence Transformers
`all-MiniLM-L6-v2`. If you change the embedding model later, you MUST
recreate this column with the new dimension and re-embed all theses.
