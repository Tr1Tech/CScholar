# Entity-Relationship Diagram (ERD)

| Field | Value |
|---|---|
| Document | CScholar — Final ERD (CEIT Scope) |
| Version | 1.0 (Final) |
| Date | 2026-10-09 |
| Status | Approved for Lab Activity 4 submission |
| Source of truth | `db/schema.sql` (16 tables, 18 foreign keys) |
| Tool / notation | Crow's Foot, Mermaid `erDiagram` |

## ERD

```mermaid
erDiagram
    users {
        int          id            PK
        varchar_50   username      UK
        varchar_120  email         UK
        varchar_255  password_hash
        varchar_20   role
        boolean      is_active
        timestamp    created_at
        timestamp    updated_at
    }

    programs {
        int          id          PK
        varchar_150  name
        varchar_20   code        UK
        text         description
        timestamp    created_at
    }

    academic_years {
        int         id         PK
        varchar_20  name       UK
        int         start_year
        int         end_year
        boolean     is_active
        timestamp   created_at
    }

    theses {
        int          id               PK
        varchar_300  title
        text         abstract
        varchar_20   research_type
        int          program_id       FK
        int          academic_year_id FK
        varchar_20   status
        int          creator_id       FK
        timestamp    created_at
        timestamp    updated_at
        varchar_500  pdf_url
        varchar_50   accession_no     UK
    }

    authors {
        int          id          PK
        varchar_80   first_name
        varchar_80   middle_name
        varchar_80   last_name
        varchar_120  email
        timestamp    created_at
    }

    thesis_authors {
        int thesis_id  PK,FK
        int author_id  PK,FK
        int order_index
    }

    advisers {
        int          id          PK
        varchar_80   first_name
        varchar_80   middle_name
        varchar_80   last_name
        varchar_120  email
        timestamp    created_at
    }

    thesis_advisers {
        int thesis_id  PK,FK
        int adviser_id PK,FK
    }

    categories {
        int          id          PK
        varchar_100  name        UK
        text         description
        timestamp    created_at
    }

    thesis_categories {
        int thesis_id   PK,FK
        int category_id PK,FK
    }

    keywords {
        int          id         PK
        varchar_100  term       UK
        timestamp    created_at
    }

    thesis_keywords {
        int thesis_id  PK,FK
        int keyword_id PK,FK
    }

    thesis_files {
        int          id           PK
        int          thesis_id    FK
        varchar_255  filename
        varchar_512  file_path
        bigint       file_size
        varchar_100  mime_type
        int          uploaded_by  FK
        timestamp    uploaded_at
    }

    thesis_embeddings {
        int          id          PK
        int          thesis_id   FK
        text         chunk_text
        vector_384   embedding
        varchar_100  model_name
        timestamp    created_at
    }

    search_logs {
        int       id           PK
        int       user_id      FK
        text      query
        jsonb     filters
        int       result_count
        timestamp created_at
    }

    recommendation_logs {
        int     id                    PK
        int     user_id               FK
        int     source_thesis_id      FK
        int     recommended_thesis_id FK
        real    similarity_score
        timestamp created_at
    }

    users            ||--o{ theses               : "creates"
    programs         ||--o{ theses               : "contains"
    academic_years   ||--o{ theses               : "covers"
    theses           ||--o{ thesis_authors       : "has"
    authors          ||--o{ thesis_authors       : "written by"
    theses           ||--o{ thesis_advisers      : "has"
    advisers         ||--o{ thesis_advisers      : "advised by"
    theses           ||--o{ thesis_categories    : "has"
    categories       ||--o{ thesis_categories    : "tagged"
    theses           ||--o{ thesis_keywords      : "has"
    keywords         ||--o{ thesis_keywords      : "described by"
    theses           ||--o{ thesis_files         : "has"
    users            ||--o{ thesis_files         : "uploads"
    theses           ||--o{ thesis_embeddings    : "has"
    users            ||--o{ search_logs          : "performs"
    users            ||--o{ recommendation_logs  : "receives"
    theses           ||--o{ recommendation_logs  : "source of"
    theses           ||--o{ recommendation_logs  : "recommended in"
```

## Relationship summary (Crow's Foot)

| # | Parent | Cardinality | Child | Via FK | Notes |
|---|---|---|---|---|---|
| 1 | users | 1 : N | theses | creator_id | ON DELETE SET NULL |
| 2 | programs | 1 : N | theses | program_id | ON DELETE RESTRICT |
| 3 | academic_years | 1 : N | theses | academic_year_id | ON DELETE RESTRICT |
| 4 | theses | 1 : N | thesis_authors | thesis_id | ON DELETE CASCADE |
| 5 | authors | 1 : N | thesis_authors | author_id | ON DELETE CASCADE |
| 6 | theses | 1 : N | thesis_advisers | thesis_id | ON DELETE CASCADE |
| 7 | advisers | 1 : N | thesis_advisers | adviser_id | ON DELETE CASCADE |
| 8 | theses | 1 : N | thesis_categories | thesis_id | ON DELETE CASCADE |
| 9 | categories | 1 : N | thesis_categories | category_id | ON DELETE CASCADE |
| 10 | theses | 1 : N | thesis_keywords | thesis_id | ON DELETE CASCADE |
| 11 | keywords | 1 : N | thesis_keywords | keyword_id | ON DELETE CASCADE |
| 12 | theses | 1 : N | thesis_files | thesis_id | ON DELETE CASCADE |
| 13 | users | 1 : N | thesis_files | uploaded_by | ON DELETE SET NULL |
| 14 | theses | 1 : N | thesis_embeddings | thesis_id | ON DELETE CASCADE |
| 15 | users | 1 : N | search_logs | user_id | ON DELETE SET NULL, nullable |
| 16 | users | 1 : N | recommendation_logs | user_id | ON DELETE SET NULL, nullable |
| 17 | theses | 1 : N | recommendation_logs | source_thesis_id | ON DELETE CASCADE |
| 18 | theses | 1 : N | recommendation_logs | recommended_thesis_id | ON DELETE CASCADE |

**Resolved many-to-many relationships (4):**

| Parent A | Junction table | Parent B | Junction payload |
|---|---|---|---|
| theses | thesis_authors | authors | order_index |
| theses | thesis_advisers | advisers | — |
| theses | thesis_categories | categories | — |
| theses | thesis_keywords | keywords | — |

## Statistics

- Entities: **16** (12 regular + 4 junction)
- Foreign keys: **18**
- Unique constraints: 7 (users.username, users.email, programs.code, academic_years.name, categories.name, keywords.term, theses.accession_no)
- CHECK constraints: 3 (users.role, theses.research_type, theses.status)
- Indexes: 6 (4 B-tree + 1 HNSW vector index + FK index on thesis_embeddings)

## Change log

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-10-09 | Final ERD released for Lab Activity 4; verified against `db/schema.sql` |
| 1.1 | 2026-11-19 | Added `theses.accession_no` (nullable UNIQUE) for library accession numbers |
