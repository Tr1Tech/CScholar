# Database

SQL schema, migrations, and mock/sample seed data live here.

- **Phase 2:** create PostgreSQL schema (16 tables) + enable the `pgvector` extension.
- Use **mock/sample data only** during development. Do not invent real CEIT thesis records.

Tables (CEIT-only scope — no `colleges` table):

users, programs, academic_years, theses, authors, thesis_authors,
advisers, thesis_advisers, categories, thesis_categories, keywords,
thesis_keywords, thesis_files, thesis_embeddings, search_logs, recommendation_logs
