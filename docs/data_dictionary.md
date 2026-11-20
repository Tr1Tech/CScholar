# Data Dictionary

| Field | Value |
|---|---|
| Document | CScholar — Data Dictionary |
| Version | 1.0 (Final) |
| Date | 2026-10-09 |
| Source of truth | `db/schema.sql` (schema: `ceit_repo`) |
| Totals | **16 tables, 84 attributes** |

Legend — Key: PK = primary key, FK = foreign key, UK = unique key. Null = column accepts NULL.

## 1. users (8 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 1 | id | SERIAL | PK | No | — | Surrogate user identifier |
| 2 | username | VARCHAR(50) | UK | No | UNIQUE | Login name |
| 3 | email | VARCHAR(120) | UK | No | UNIQUE | Account email address |
| 4 | password_hash | VARCHAR(255) | — | No | — | Bcrypt hash (never plaintext) |
| 5 | role | VARCHAR(20) | — | No | CHECK IN ('student','faculty','admin') | Authorization role |
| 6 | is_active | BOOLEAN | — | No | DEFAULT TRUE | Soft-delete / activation flag |
| 7 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |
| 8 | updated_at | TIMESTAMP | — | No | DEFAULT NOW() | Last modification time |

## 2. programs (5 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 9 | id | SERIAL | PK | No | — | Program identifier |
| 10 | name | VARCHAR(150) | — | No | — | Program name (e.g. BS Information Technology) |
| 11 | code | VARCHAR(20) | UK | No | UNIQUE | Program code (e.g. BSIT, BSCS) |
| 12 | description | TEXT | — | Yes | — | Program description |
| 13 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## 3. academic_years (6 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 14 | id | SERIAL | PK | No | — | Academic year identifier |
| 15 | name | VARCHAR(20) | UK | No | UNIQUE | Label, e.g. '2025-2026' |
| 16 | start_year | INTEGER | — | No | — | First calendar year |
| 17 | end_year | INTEGER | — | No | — | Second calendar year |
| 18 | is_active | BOOLEAN | — | No | DEFAULT FALSE | Currently active year flag |
| 19 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## 4. theses (11 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 20 | id | SERIAL | PK | No | — | Thesis identifier |
| 21 | title | VARCHAR(300) | — | No | — | Thesis/capstone title |
| 22 | abstract | TEXT | — | No | — | Abstract text |
| 23 | research_type | VARCHAR(20) | — | No | CHECK IN ('Thesis','Capstone') | Research category |
| 24 | program_id | INTEGER | FK | No | REFERENCES programs(id) ON DELETE RESTRICT | Owning CEIT program |
| 25 | academic_year_id | INTEGER | FK | No | REFERENCES academic_years(id) ON DELETE RESTRICT | Academic year |
| 26 | status | VARCHAR(20) | — | No | DEFAULT 'draft'; CHECK IN ('draft','approved','published','archived') | Publication lifecycle state |
| 27 | creator_id | INTEGER | FK | Yes | REFERENCES users(id) ON DELETE SET NULL | Submitting user |
| 28 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |
| 29 | updated_at | TIMESTAMP | — | No | DEFAULT NOW() | Last modification time |
| 30 | pdf_url | VARCHAR(500) | — | Yes | — | Location of the PDF document |

> **Addendum 2026-11-19:** `theses.accession_no VARCHAR(50) UNIQUE` (nullable) was added for library accession numbers (`docs/real_data_plan.md` §8, applied before the pilot import). It is attribute 85; the running total below becomes **85 attributes** until the document is renumbered.
>
> **Addendum 2026-11-19:** `import_jobs` was added as operational metadata for the admin Bulk Import screen (preview rows, progress, report). It is not part of the thesis corpus and is intentionally excluded from the 85-attribute total.

## 5. authors (6 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 31 | id | SERIAL | PK | No | — | Author identifier |
| 32 | first_name | VARCHAR(80) | — | No | — | Given name |
| 33 | middle_name | VARCHAR(80) | — | Yes | — | Middle name/initial |
| 34 | last_name | VARCHAR(80) | — | No | — | Surname |
| 35 | email | VARCHAR(120) | — | Yes | — | Contact email (not unique) |
| 36 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## 6. thesis_authors (3 attributes) — junction (N:N theses↔authors)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 37 | thesis_id | INTEGER | PK, FK | No | REFERENCES theses(id) ON DELETE CASCADE | Part of composite PK |
| 38 | author_id | INTEGER | PK, FK | No | REFERENCES authors(id) ON DELETE CASCADE | Part of composite PK |
| 39 | order_index | INTEGER | — | No | DEFAULT 1 | Author position on the paper |

## 7. advisers (6 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 40 | id | SERIAL | PK | No | — | Adviser identifier |
| 41 | first_name | VARCHAR(80) | — | No | — | Given name |
| 42 | middle_name | VARCHAR(80) | — | Yes | — | Middle name/initial |
| 43 | last_name | VARCHAR(80) | — | No | — | Surname |
| 44 | email | VARCHAR(120) | — | Yes | — | Contact email (not unique) |
| 45 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## 8. thesis_advisers (2 attributes) — junction (N:N theses↔advisers)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 46 | thesis_id | INTEGER | PK, FK | No | REFERENCES theses(id) ON DELETE CASCADE | Part of composite PK |
| 47 | adviser_id | INTEGER | PK, FK | No | REFERENCES advisers(id) ON DELETE CASCADE | Part of composite PK |

## 9. categories (4 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 48 | id | SERIAL | PK | No | — | Category identifier |
| 49 | name | VARCHAR(100) | UK | No | UNIQUE | Category name (e.g. Machine Learning) |
| 50 | description | TEXT | — | Yes | — | Category description |
| 51 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## 10. thesis_categories (2 attributes) — junction (N:N theses↔categories)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 52 | thesis_id | INTEGER | PK, FK | No | REFERENCES theses(id) ON DELETE CASCADE | Part of composite PK |
| 53 | category_id | INTEGER | PK, FK | No | REFERENCES categories(id) ON DELETE CASCADE | Part of composite PK |

## 11. keywords (3 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 54 | id | SERIAL | PK | No | — | Keyword identifier |
| 55 | term | VARCHAR(100) | UK | No | UNIQUE | Keyword term |
| 56 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## 12. thesis_keywords (2 attributes) — junction (N:N theses↔keywords)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 57 | thesis_id | INTEGER | PK, FK | No | REFERENCES theses(id) ON DELETE CASCADE | Part of composite PK |
| 58 | keyword_id | INTEGER | PK, FK | No | REFERENCES keywords(id) ON DELETE CASCADE | Part of composite PK |

## 13. thesis_files (8 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 59 | id | SERIAL | PK | No | — | File-record identifier |
| 60 | thesis_id | INTEGER | FK | No | REFERENCES theses(id) ON DELETE CASCADE | Owning thesis |
| 61 | filename | VARCHAR(255) | — | No | — | Original file name |
| 62 | file_path | VARCHAR(512) | — | No | — | Storage path (disk / object storage) |
| 63 | file_size | BIGINT | — | Yes | — | Size in bytes |
| 64 | mime_type | VARCHAR(100) | — | Yes | — | MIME type (e.g. application/pdf) |
| 65 | uploaded_by | INTEGER | FK | Yes | REFERENCES users(id) ON DELETE SET NULL | Uploader |
| 66 | uploaded_at | TIMESTAMP | — | No | DEFAULT NOW() | Upload time |

## 14. thesis_embeddings (6 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 67 | id | SERIAL | PK | No | — | Embedding-row identifier |
| 68 | thesis_id | INTEGER | FK | No | REFERENCES theses(id) ON DELETE CASCADE | Owning thesis |
| 69 | chunk_text | TEXT | — | No | — | Text chunk the vector was built from |
| 70 | embedding | vector(384) | — | Yes | pgvector; dim = all-MiniLM-L6-v2 | Sentence-transformer vector |
| 71 | model_name | VARCHAR(100) | — | No | — | Model that produced the vector |
| 72 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## 15. search_logs (6 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 73 | id | SERIAL | PK | No | — | Log entry identifier |
| 74 | user_id | INTEGER | FK | Yes | REFERENCES users(id) ON DELETE SET NULL | User who searched (nullable) |
| 75 | query | TEXT | — | Yes | — | Search string |
| 76 | filters | JSONB | — | Yes | e.g. {"program_id":2,"year":2025} | Applied filters |
| 77 | result_count | INTEGER | — | Yes | — | Number of results returned |
| 78 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Search time |

## 16. recommendation_logs (6 attributes)

| # | Column | Type | Key | Null | Default / Constraint | Description |
|---|---|---|---|---|---|---|
| 79 | id | SERIAL | PK | No | — | Log entry identifier |
| 80 | user_id | INTEGER | FK | Yes | REFERENCES users(id) ON DELETE SET NULL | User shown the recommendation |
| 81 | source_thesis_id | INTEGER | FK | No | REFERENCES theses(id) ON DELETE CASCADE | Thesis the user viewed |
| 82 | recommended_thesis_id | INTEGER | FK | No | REFERENCES theses(id) ON DELETE CASCADE | Thesis recommended |
| 83 | similarity_score | REAL | — | Yes | — | Similarity value of the match |
| 84 | created_at | TIMESTAMP | — | No | DEFAULT NOW() | Row creation time |

## Attribute count by table

| Table | Attributes | | Table | Attributes |
|---|---|---|---|---|
| users | 8 | | thesis_advisers | 2 |
| programs | 5 | | categories | 4 |
| academic_years | 6 | | thesis_categories | 2 |
| theses | 11 | | keywords | 3 |
| authors | 6 | | thesis_keywords | 2 |
| thesis_authors | 3 | | thesis_files | 8 |
| advisers | 6 | | thesis_embeddings | 6 |
| search_logs | 6 | | recommendation_logs | 6 |
| **Total** | **84** | | | |
