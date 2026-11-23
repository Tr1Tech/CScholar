# Agent Notes

Instructions for AI coding agents working in this repository. Read this before
making changes.

## 🚫 Database schema is locked — never add tables

The PostgreSQL schema in [`db/schema.sql`](db/schema.sql) is the **complete and
frozen** definition of the CScholar database (18 physical tables = 16 domain
+ 2 operational, including `import_jobs` and `thesis_reviews`). The backend uses
raw `psycopg2` queries with no ORM, so there is
no model layer that should be creating tables either.

Hard rules:

- **Do not add, rename, drop, or alter** tables, columns, indexes, constraints,
  or enum values.
- **Do not write migrations** or emit DDL such as `CREATE TABLE`,
  `ALTER TABLE`, `DROP TABLE`, `CREATE SCHEMA`, or `Base.metadata.create_all()`.
- **Do not create** "temporary", "helper", "cache", "analytics", or "lookup"
  tables to make a feature work.
- **Do not assume new state needs a table.** Use the existing tables and
  columns; if the state is personal or UI-only, keep it on the client (for
  example `SharedPreferences`); otherwise return a clear error.
- **If a task genuinely cannot be done without a schema change, stop and ask
  the project owner for explicit approval.** Never make the change yourself.

This applies to every file and workflow, including "just for testing" scripts
and one-off SQL. All objects live in the `ceit_repo` schema, and queries must
use the `ceit_repo.` prefix.

Full rule: see the “Schema is locked — do not add tables” section in
[`db/README.md`](db/README.md).

## Project layout

```
backend/    FastAPI + raw psycopg2 (Python 3.11) — no ORM
frontend/   Flutter app for web and mobile (one codebase)
db/         schema.sql, bootstrap.sql, seed.sql, logic/ — locked schema
docs/       ERD, normalization, data dictionary, traceability, plans
```

## Other repository rules

- **Never run `flutter create`** in this project; it regenerates shared files.
- `db/seed.sql` contains **fictional** demo data. Never load it into a database
  that holds real records.
- Run the relevant checks before finishing:
  - Frontend: `cd frontend && flutter analyze && flutter test`
  - Backend: `cd backend && python -m compileall app`
  - With the API and database running: `python scripts\demo_preflight.py`
- Do not delete or overwrite unrelated local changes.
