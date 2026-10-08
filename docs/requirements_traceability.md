# Requirements & Traceability Matrix

| Field | Value |
|---|---|
| Document | CScholar — Requirements and Requirements-to-Tables Traceability Matrix |
| Version | 1.0 (Final) |
| Date | 2026-10-09 |
| Source of truth | `README.md` development phases + `db/schema.sql` |
| Totals | **20 functional requirements → 16/16 tables traced (100% coverage)** |

## 1. Functional requirements

| ID | Requirement | Phase |
|---|---|---|
| FR-01 | The system shall allow students, faculty, and admins to log in with a username and password. | 4 |
| FR-02 | The system shall restrict features by user role (student, faculty, admin). | 4 |
| FR-03 | Admins shall be able to activate or deactivate user accounts. | 4 |
| FR-04 | The system shall manage CEIT programs (BSIT, BSCS, BSIS). | 5 |
| FR-05 | The system shall manage academic years and mark one as active. | 5 |
| FR-06 | Users shall be able to create and edit thesis/capstone entries with title and abstract. | 6 |
| FR-07 | Each entry shall be classified as either a Thesis or a Capstone. | 6 |
| FR-08 | Each entry shall follow the status lifecycle draft → approved → published → archived. | 6 |
| FR-09 | Each entry shall store the location of its PDF document. | 6 |
| FR-10 | The system shall record file metadata (name, path, size, MIME type) for uploaded files. | 8 |
| FR-11 | Multiple authors shall be linkable to one thesis, in a meaningful order. | 7 |
| FR-12 | Multiple advisers shall be linkable to one thesis. | 7 |
| FR-13 | Theses shall be classifiable under multiple categories. | 7 |
| FR-14 | Theses shall be taggable with multiple keywords. | 7 |
| FR-15 | The system shall generate and store text embeddings for thesis chunks. | 12 |
| FR-16 | The system shall perform semantic (vector) search over thesis content. | 13 |
| FR-17 | The system shall recommend similar theses and log match scores. | 14 |
| FR-18 | The system shall support normal search with filters and log search activity. | 11 |
| FR-19 | The system shall record the creating user and creation/update timestamps. | all |
| FR-20 | The data model shall cover the CEIT college only (no multi-college structure). | scope |

## 2. Traceability matrix (requirement → tables → columns)

| Req | Table(s) | Key columns implementing it | Verification in schema |
|---|---|---|---|
| FR-01 | users | username, password_hash | UNIQUE username; bcrypt hash column (see `db/seed.sql` sample hashes) |
| FR-02 | users | role | `CHECK (role IN ('student','faculty','admin'))` |
| FR-03 | users | is_active | `DEFAULT TRUE`; soft-deactivate without row removal |
| FR-04 | programs | name, code | `code UNIQUE`; seeded with BSIT/BSCS/BSIS |
| FR-05 | academic_years | name, start_year, end_year, is_active | `name UNIQUE`; `is_active DEFAULT FALSE` |
| FR-06 | theses | title, abstract | `title VARCHAR(300) NOT NULL`, `abstract TEXT NOT NULL` |
| FR-07 | theses | research_type | `CHECK (research_type IN ('Thesis','Capstone'))` |
| FR-08 | theses | status | `CHECK (status IN ('draft','approved','published','archived')) DEFAULT 'draft'` |
| FR-09 | theses | pdf_url | `pdf_url VARCHAR(500)`; binary kept out of the DB |
| FR-10 | thesis_files | filename, file_path, file_size, mime_type, uploaded_by, uploaded_at | metadata table; `uploaded_by → users` |
| FR-11 | authors, thesis_authors | author names; thesis_id, author_id, order_index | junction PK `(thesis_id, author_id)` + `order_index` payload |
| FR-12 | advisers, thesis_advisers | adviser names; thesis_id, adviser_id | junction PK `(thesis_id, adviser_id)` |
| FR-13 | categories, thesis_categories | name; thesis_id, category_id | junction PK `(thesis_id, category_id)` |
| FR-14 | keywords, thesis_keywords | term; thesis_id, keyword_id | junction PK `(thesis_id, keyword_id)`; `term UNIQUE` |
| FR-15 | thesis_embeddings | chunk_text, embedding, model_name | `embedding vector(384)` = all-MiniLM-L6-v2 |
| FR-16 | thesis_embeddings | embedding | `CREATE INDEX ... USING hnsw (embedding vector_cosine_ops)` |
| FR-17 | recommendation_logs | source_thesis_id, recommended_thesis_id, similarity_score | two FKs to `theses` + REAL similarity_score |
| FR-18 | search_logs | query, filters, result_count, user_id | JSONB filters; nullable user_id (anonymous ok) |
| FR-19 | theses, users + audit columns | creator_id; created_at, updated_at | `creator_id → users` + timestamp columns on 11 tables |
| FR-20 | programs | (no colleges table) | colleges table intentionally omitted — see `db/schema.sql` line 5 comment |

## 3. Coverage summary

| Metric | Value |
|---|---|
| Functional requirements defined | 20 |
| Requirements traced to ≥ 1 table | 20 (100%) |
| Database tables traced | 16 of 16 |
| Requirements with a column-level constraint implementing them | 12 |
| Untraced tables | 0 |

## 4. Requirement ↔ normalized ERD linkage

Every requirement above maps to entities in the final ERD (see `ERD.md`, v1.0). The four many-to-many requirements (FR-11 to FR-14) correspond exactly to the four junction tables verified at 3NF/BCNF (see `normalization.md`); attribute-level meanings are defined in `data_dictionary.md` (84 attributes).
