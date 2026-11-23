# Normalization Verification (1NF → 2NF → 3NF → BCNF)

| Field | Value |
|---|---|
| Document | CScholar — Normalization Verification Report |
| Version | 1.1 |
| Date | 2026-11-21 |
| Source of truth | `db/schema.sql` (16 domain relations + 2 operational tables) |

## Method

For each relation R:

1. **1NF** — every attribute is atomic; no repeating groups or multi-valued attributes.
2. **2NF** — no partial dependency of a non-prime attribute on part of a composite candidate key.
3. **3NF** — for every non-trivial FD X → Y, either X is a superkey, or every attribute in Y is prime.
4. **BCNF** — for every non-trivial FD X → Y, X is a superkey.

## Result summary

**All 16 domain relations pass 1NF, 2NF and 3NF. All 16 also satisfy BCNF** — the only determinants of non-trivial functional dependencies are candidate keys / superkeys, so the BCNF condition is met in every relation. Because BCNF ⊂ 3NF ⊂ 2NF ⊂ 1NF, this verifies the whole domain model at every level. The two operational tables (`thesis_reviews`, `import_jobs`) are verified separately below and also pass 1NF–BCNF; they are excluded from the 16-relation count because they are workflow records, not domain entities.

| # | Relation | Candidate key(s) | Detected non-trivial FDs | 1NF | 2NF | 3NF | BCNF |
|---|---|---|---|---|---|---|---|
| 1 | users | id, username, email | id→all; username→all; email→all | ✅ | ✅ | ✅ | ✅ |
| 2 | programs | id, code | id→all; code→all | ✅ | ✅ | ✅ | ✅ |
| 3 | academic_years | id, name | id→all; name→all | ✅ | ✅ | ✅ | ✅ |
| 4 | theses | id | id→all | ✅ | ✅ | ✅ | ✅ |
| 5 | authors | id | id→all | ✅ | ✅ | ✅ | ✅ |
| 6 | thesis_authors | (thesis_id, author_id) | (thesis_id, author_id)→order_index | ✅ | ✅ | ✅ | ✅ |
| 7 | advisers | id | id→all | ✅ | ✅ | ✅ | ✅ |
| 8 | thesis_advisers | (thesis_id, adviser_id) | (thesis_id, adviser_id) | ✅ | ✅ | ✅ | ✅ |
| 9 | categories | id, name | id→all; name→all | ✅ | ✅ | ✅ | ✅ |
| 10 | thesis_categories | (thesis_id, category_id) | (thesis_id, category_id) | ✅ | ✅ | ✅ | ✅ |
| 11 | keywords | id, term | id→all; term→all | ✅ | ✅ | ✅ | ✅ |
| 12 | thesis_keywords | (thesis_id, keyword_id) | (thesis_id, keyword_id) | ✅ | ✅ | ✅ | ✅ |
| 13 | thesis_files | id | id→all | ✅ | ✅ | ✅ | ✅ |
| 14 | thesis_embeddings | id | id→all | ✅ | ✅ | ✅ | ✅ |
| 15 | search_logs | id | id→all | ✅ | ✅ | ✅ | ✅ |
| 16 | recommendation_logs | id | id→all | ✅ | ✅ | ✅ | ✅ |

### Operational tables (verified separately)

These tables support workflows rather than the domain model, so they are not
counted among the 16 core relations. Both still satisfy 1NF–BCNF.

| # | Relation | Candidate key(s) | Detected non-trivial FDs | 1NF | 2NF | 3NF | BCNF |
|---|---|---|---|---|---|---|---|
| O1 | thesis_reviews | id | id→all | ✅ | ✅ | ✅ | ✅ |
| O2 | import_jobs | id | id→all | ✅ | ✅ | ✅ | ✅ |

## Per-relation notes

### users
Atomic attributes (1NF). Single-column surrogate PK `id`; no composite key → 2NF holds trivially. `username` and `email` are UNIQUE alternate candidate keys so their determinants {username, email, id} are superkeys → 3NF and BCNF hold. `role`, `is_active`, timestamps depend directly on the key.

### programs
`code` is a UNIQUE natural key alongside `id`; both determinants are superkeys → BCNF. `description` depends on `id`/`code` only (no transitive dependency on another non-key attribute).

### academic_years
`name` (e.g. "2025-2026") is a UNIQUE alternate key; `start_year`/`end_year` are functionally determined by `name` (and `id`). All determinants are superkeys → BCNF. No partial or transitive dependencies.

### theses
Single-column PK `id`; composite-key relations cannot have partial dependencies. `program_id`, `academic_year_id`, `creator_id` are foreign keys (many-to-one), not multi-valued attributes → 1NF preserved. All remaining attributes depend directly on `id` → 3NF. Only determinant is `id`, a superkey → BCNF.

### authors
`id` is the only candidate key. `email` is nullable and **not** UNIQUE (the same person may appear with a shared/blank email), so it is not a determinant and creates no dependency that could violate 3NF/BCNF. All attributes depend on `id`.

### thesis_authors (junction)
Composite PK `(thesis_id, author_id)` resolving the theses↔authors N:N. The only non-key attribute, `order_index`, is determined by the **full** key (the order of an author is meaningful only within one thesis) → no partial dependency (2NF), no transitive dependency (3NF). Only determinant is the full candidate key → BCNF.

### advisers
Identical structure to `authors`: single PK `id`, no non-key determinants → BCNF.

### thesis_advisers (junction)
Pure associative table: PK `(thesis_id, adviser_id)`, no non-key attributes → trivially 2NF, 3NF and BCNF.

### categories
`name` is a UNIQUE natural key; both `id` and `name` determine the relation → determinants are superkeys → BCNF → 3NF.

### thesis_categories (junction)
Pure associative table with PK `(thesis_id, category_id)` → BCNF.

### keywords
`term` is a UNIQUE natural key; all determinants are superkeys → BCNF → 3NF.

### thesis_keywords (junction)
Pure associative table with PK `(thesis_id, keyword_id)` → BCNF.

### thesis_files
`id` PK; `thesis_id`/`uploaded_by` are FKs. Metadata-only design (binary stays on disk/object storage), so no multi-valued attributes → 1NF. All attributes depend directly on `id` → 3NF, and `id` is the only determinant → BCNF.

### thesis_embeddings
`id` PK; one row per text chunk. `embedding` (single 384-dim vector value), `chunk_text`, `model_name` are atomic → 1NF. All depend on `id` directly → 3NF; `id` is the only determinant → BCNF.

### search_logs
`id` PK; `user_id` nullable (searches can be anonymous/logged without a user). `filters` is a JSONB document — treated as a single atomic value, not decomposed → 1NF preserved. All attributes depend on `id` → 3NF; only determinant is `id` → BCNF.

### recommendation_logs
`id` PK; `source_thesis_id` and `recommended_thesis_id` are two separate FKs to `theses` (correctly modeled as two relationships, not one multi-valued attribute). All attributes depend on `id` → 3NF; only determinant is `id` → BCNF.

### thesis_reviews (operational)
`id` PK; `thesis_id` and `reviewer_id` are FKs (many-to-one), not multi-valued attributes. `decision`, `notes` and `created_at` depend directly on `id`; `id` is the only determinant → BCNF.

### import_jobs (operational)
`id` PK; `created_by` is an FK. `rows` is a JSONB report treated as one atomic value, so 1NF holds. The status, progress counters and timestamps depend directly on `id`; `id` is the only determinant → BCNF.

## Conclusion

- **Core domain relations verified at 3NF: 16 of 16** (theses and its 15 companions, including all 4 junction tables).
- **Relations evaluated for BCNF: 16 of 16 domain — all pass**, because no relation contains a non-trivial functional dependency whose determinant is not a superkey.
- **Operational tables: 2 of 2** (`thesis_reviews`, `import_jobs`) also pass 1NF–BCNF; they are not counted in the 16 domain relations.
