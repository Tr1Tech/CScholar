# Phase 2 — Database Setup (PostgreSQL + pgvector)

This folder contains the CScholar database schema, mock seed data, and the
Lab 5 logic (views, functions, procedure, triggers).

## Files
- `schema.sql` — tables + pgvector extension + indexes (CEIT-only scope, no colleges table)
- `seed.sql` — FICTIONAL sample data (CEIT programs, AY 2025-2026, 3 sample theses). Not real CSU records.
- `setup.md` — how to install & run PostgreSQL + pgvector, then apply this schema.
- `logic/cscholar_lab5_logic.sql` — views, PL/pgSQL, triggers (run last).

## Quick run (after Postgres + pgvector are ready)

From the **repo root**:

```bash
createdb cscholar
psql -U postgres -d cscholar -f db/schema.sql
psql -U postgres -d cscholar -f db/seed.sql
psql -U postgres -d cscholar -f db/logic/cscholar_lab5_logic.sql
```

Every object is created in the `ceit_repo` schema. A new `psql` session does not
inherit the script's `search_path`, so query with the prefix:

```bash
psql -U postgres -d cscholar -c "SELECT COUNT(*) FROM ceit_repo.theses;"
```

## Embedding dimension
`thesis_embeddings.embedding` is `vector(384)` to match Sentence Transformers
`all-MiniLM-L6-v2`. If you change the embedding model later, you MUST
recreate this column with the new dimension and re-embed all theses.
