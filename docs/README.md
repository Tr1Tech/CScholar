# Docs

Capstone documentation lives here:

- Problem statement, objectives, scope
- Entity-Relationship Diagram (ERD)
- Architecture / data-flow diagrams
- Methodology (SDLC) and SDG alignment
- Defense materials

## Current documents

| File | Contents | Version |
|---|---|---|
| [ERD.md](ERD.md) | Final ERD (16 entities, 18 FKs, Mermaid + Crow's Foot tables) | 1.0 — 2026-10-09 |
| [normalization.md](normalization.md) | 1NF/2NF/3NF verification + BCNF evaluation for all 16 relations | 1.0 — 2026-10-09 |
| [data_dictionary.md](data_dictionary.md) | All 84 attributes across 16 tables (type, key, constraint, description) | 1.0 — 2026-10-09 |
| [requirements_traceability.md](requirements_traceability.md) | 20 functional requirements mapped to tables and columns | 1.0 — 2026-10-09 |
| [DESIGN_IMPROVEMENT_PROMPT.md](DESIGN_IMPROVEMENT_PROMPT.md) | Frontend design-improvement working notes | — |

Database schema and seed data live in `../db/` (`schema.sql`, `seed.sql`).
