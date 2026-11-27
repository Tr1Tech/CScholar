# Docs

> ## API surface is locked — do not add endpoints
>
> The API documented in the Swagger UI (`/docs`) is **final**. Its 62 documented
> operations are frozen in [`backend/api_contract.json`](../backend/api_contract.json);
> the server will not start if a route is added, removed, re-tagged, or has its
> allowed roles changed. Do not add endpoints as a shortcut for a feature — use
> the existing operations, or ask the project owner first.
>
> Verify the lock offline (no server needed):
>
> ```bash
> cd backend
> venv\Scripts\python scripts\check_api_contract.py
> ```
>
> See `backend/app/api_lock.py` for the guard.

> ## Database schema is locked — do not add tables
>
> The PostgreSQL schema defined in [`db/schema.sql`](../db/schema.sql) is
> **frozen**. AI agents and contributors must not create tables, add columns,
> write migrations, or run any other DDL against it. Use the existing tables
> and columns, keep new state on the client (for example
> `SharedPreferences`), or stop and ask the project owner for explicit
> approval before changing the schema.
>
> See the “Schema is locked — do not add tables” section in
> [`db/README.md`](../db/README.md) for the full rule.

Capstone documentation lives here:

- Problem statement, objectives, scope
- Entity-Relationship Diagram (ERD)
- Architecture / data-flow diagrams
- Methodology (SDLC) and SDG alignment
- Defense materials

## Current documents

| File | Contents | Version |
|---|---|---|
| [ERD.md](ERD.md) | Final ERD (16 domain entities + 3 operational tables, 22 FKs, Mermaid + Crow's Foot tables) | 1.3 — 2026-11-27 |
| [normalization.md](normalization.md) | 1NF/2NF/3NF verification + BCNF evaluation for all 16 domain relations (plus 3 operational tables) | 1.2 — 2026-11-27 |
| [data_dictionary.md](data_dictionary.md) | All 84 domain attributes (+ `accession_no` = 85) across 16 domain tables, plus 3 operational tables (type, key, constraint, description) | 1.2 — 2026-11-27 |
| [requirements_traceability.md](requirements_traceability.md) | 20 functional requirements mapped to tables and columns | 1.1 — 2026-11-21 |
| [DEPLOY_RENDER_NEON.md](DEPLOY_RENDER_NEON.md) | Free public deployment (Render Free + Neon Postgres/Object Storage + GitHub Pages): setup, data copy, phone use, limits | 1.0 — 2026-11-25 |
| [DESIGN_IMPROVEMENT_PROMPT.md](DESIGN_IMPROVEMENT_PROMPT.md) | Frontend design-improvement working notes | — |

## Defense materials

| File | Contents |
|---|---|
| [demo_script_20261204.md](demo_script_20261204.md) | 12-minute run sheet, preflight, fallbacks, restore drill |
| [api_testing_guide.md](api_testing_guide.md) | Every locked Swagger endpoint with the exact inputs to type, demo order, expected errors |
| [qa_cheatsheet_20261204.md](qa_cheatsheet_20261204.md) | Spoken Q&A answers, exact numbers, failure fallbacks, don't-say list |
| [evaluation/relevance_20261120.md](evaluation/relevance_20261120.md) | Keyword vs semantic relevance check (10 labeled queries) |
| [evaluation/survey_questionnaire_20261125.md](evaluation/survey_questionnaire_20261125.md) | System context brief + post-build evaluation questionnaire for students, faculty, admin, and IT experts (ISO 25010 constructs, scoring, and administration plan) |

Database schema and seed data live in `../db/` (`schema.sql`, `seed.sql`).
