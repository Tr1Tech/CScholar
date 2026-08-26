# Phase 2 — Database Setup (PostgreSQL + pgvector)

This folder contains the CScholar database schema and mock seed data.

## Files
- `schema.sql` — 16 tables + pgvector extension + indexes (CEIT-only scope, no colleges table)
- `seed.sql` — FICTIONAL sample data (CEIT programs, AY 2025-2026, 3 sample theses). Not real CSU records.
- `setup.md` — how to install & run PostgreSQL + pgvector, then apply this schema.

## Quick run (after Postgres + pgvector are ready)
```bash
createdb cscholar
psql -U postgres -d cscholar -f schema.sql
psql -U postgres -d cscholar -f seed.sql
```

## Embedding dimension
`thesis_embeddings.embedding` is `vector(384)` to match Sentence Transformers
`all-MiniLM-L6-v2`. If you change the embedding model later, you MUST
recreate this column with the new dimension and re-embed all theses.
