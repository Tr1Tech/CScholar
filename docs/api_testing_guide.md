# API testing guide (Swagger UI)

Everything below is generated from the **locked** contract
(`backend/api_contract.json`, 61 operations). No endpoint was added for this
guide.

- **Swagger UI:** <http://localhost:5000/docs>
- **Raw spec:** <http://localhost:5000/swagger.json>
- **API check (offline):** `backend\venv\Scripts\python backend\scripts\check_api_contract.py`

## 1. Before you test

Start the server from `backend/`:

```powershell
venv\Scripts\python run.py
```

Then open <http://localhost:5000/docs>.

### Accounts (seed/demo data)

| Role | Email | Password |
|---|---|---|
| Admin | `admin@csu.edu.ph` | `admin123` |
| Faculty | `faculty2@csu.edu.ph` | `secret123` |
| Student | `demo@csu.edu.ph` | `demo1234` |

### Authorize in Swagger

1. Call **POST /api/auth/login** with the email/password of the role you need.
2. Copy `token` from the response.
3. Click **Authorize** at the top of the page.
4. Paste only the token (Swagger adds `Bearer ` itself), then **Authorize**.

Re-authorize to switch roles. Public endpoints work with no token.

## 2. Copy these IDs (verified 2026-11-23)

The API takes **database ids**, not names. Fetch the lists first, then copy the
ids. Current values:

| What you need | How to get it | Current ids |
|---|---|---|
| Program | `GET /api/programs` | `1` BSIT, `2` BSEE, `14` BSCpE |
| Academic year | `GET /api/academic-years` | `1` = 2025-2026 (active), `12`–`15` older |
| Category | `GET /api/categories` | `13`–`18` |
| Author | `GET /api/authors` | `12`–`17` (and more) |
| Adviser | `GET /api/advisers` | `14`–`19` |
| Thesis | `GET /api/theses` | `41`–`59` (all published today) |
| User | `GET /api/users` (admin token) | `5` admin, `17`/`30`/`51` faculty, `29` student |
| Import job | `POST /api/import/preview` response | none right now (past job `7`) |

> If a number no longer exists, copy a fresh one from the list response.

## 3. Endpoint-by-endpoint

Legend: **Who** = role needed (`public` = no token). Success codes are what the
instructor should see when the inputs are valid.

### System

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| GET | `/health` | public | none | `200 {"status":"ok"}` |
| GET | `/api/health` | public | none | `200` status/service/project/phase |
| GET | `/api/db-test` | public | none | `200` project, masked `database_url`, `checked_at` |
| GET | `/api/stats/summary` | public | none | `200 {"studies":19,"programs":3}` |

### Auth and users

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| POST | `/api/auth/register` | public | body: `username`, `email`, `password` | `201` token + user, role is always `student` |
| POST | `/api/auth/login` | public | body: `email`, `password` | `200` token + user |
| GET | `/api/auth/me` | any login | header only | `200` id, username, email, role, `is_active`, timestamps |
| PUT | `/api/auth/password` | any login | body: `current_password`, `new_password` | `200 {"message":"Password updated","token":"..."}` — old tokens are now rejected |
| GET | `/api/users` | admin | none | `200 {"users":[...],"total":23}` |
| POST | `/api/users` | admin | body: `username`, `email`, `password`, `role` | `201 {"message":"User created","user":{...}}` |
| PUT | `/api/users/{user_id}` | admin | path id + body: `username` and/or `email` and/or `role` | `200 {"message":"User updated",...}` |
| PUT | `/api/users/{user_id}/active` | admin | path id + body: `is_active` | `200 {"message":"User status updated",...}` |

Copy-paste bodies:

```json
// POST /api/auth/register   (UI: Register — Full name, Email, Password)
{"username": "instructor_test", "email": "instructor.test@csu.edu.ph", "password": "test1234"}
```

```json
// POST /api/auth/login      (UI: Sign in — Email, Password)
{"email": "admin@csu.edu.ph", "password": "admin123"}
```

```json
// PUT /api/auth/password    (UI: Settings/Profile → Change password)
{"current_password": "admin123", "new_password": "newsecret123"}
```

```json
// POST /api/users           (UI: User Management → Add user)
{"username": "faculty_demo", "email": "faculty.demo@csu.edu.ph", "password": "secret123", "role": "faculty"}
```

```json
// PUT /api/users/{user_id}  (UI: Edit user → Role)
{"role": "faculty"}
```

```json
// PUT /api/users/{user_id}/active  (UI: Active toggle)
{"is_active": false}
```

Rules to show:

- register/login errors: missing fields → `400`, wrong password → `401`, duplicate username/email → `409`, deactivated account → `403`.
- change password (any role, own account only): missing field or a new password under 6 characters → `400`, wrong `current_password` → `401`, new password equal to the current one → `400`.
- Every JWT carries a keyed fingerprint of the password hash. A password change rotates that fingerprint, so all tokens issued before it return `401 Session expired; please sign in again`. The response's `token` is the replacement for the device that made the change. Deploying this claim signs out every session that predates it, once.
- Admin cannot remove their own admin role, or deactivate their own account (`400`).
- `role` must be `student`, `faculty`, or `admin` (`400` otherwise).
- The UI's register form also asks for a **student ID** and **program**; those are not part of the API body and are not stored by `/api/auth/register`.

### Theses

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| GET | `/api/theses` | public | query: `q`, `program_id`, `year_id`, `category_id`, `keyword`, `research_type`, `sort_by`, `status`, `show_all`, `page`, `per_page` | `200 {theses,total,page,per_page,pages}` |
| GET | `/api/theses/{id}` | public | path id | `200` thesis object, `404` if not visible |
| GET | `/api/theses/{id}/recommend` | public | path id + query `limit` (1–20, default 5) | `200 {thesis_id,theses,count}` |
| POST | `/api/theses` | admin, faculty | full body below | `201` thesis object |
| PUT | `/api/theses/{id}` | admin; faculty only own drafts | partial body | `200` thesis object |
| POST | `/api/theses/bulk-status` | admin | body: `ids`, `status` (`approved` or `published`) | `200 {requested,status,updated,skipped}` |
| DELETE | `/api/theses/{id}` | admin; faculty only own drafts | path id | `200 {"message":"Thesis deleted"}` |
| GET | `/api/theses/{thesis_id}/pdf` | any login | path id (+ header token) | `200` PDF file, `404` when none |

Useful query examples (all map to the repository filters):

| UI filter | Swagger query |
|---|---|
| Search box | `q=Vistal` |
| Program | `program_id=1` |
| Academic year | `year_id=1` |
| Category | `category_id=14` |
| Keyword tag | `keyword=semantic search` |
| Research type | `research_type=Thesis` (or `Capstone`) |
| Sort: Latest / Oldest / Title (A-Z) / Title (Z-A) | `sort_by=Latest` / `Oldest` / `Title (A-Z)` / `Title (Z-A)` |
| Page | `page=1`, `per_page=20` (1–100) |
| Admin "All statuses" | `show_all=true` **with an admin token** |
| Status filter (admin) | `status=draft` / `approved` / `published` / `archived` |

```json
// POST /api/theses  (UI: Add Thesis — Title, Abstract, Academic Program,
// Academic Year, Research Type, Adviser, Authors, Primary Category,
// Keywords/Tags; new records start as drafts)
{
  "title": "Instructor Demo: Web-Based Library Kiosk",
  "abstract": "This capstone developed a self-service library kiosk for students and recorded borrowing activity in a web dashboard.",
  "program_id": 1,
  "academic_year_id": 1,
  "research_type": "Capstone",
  "author_ids": [12, 13],
  "adviser_id": 18,
  "category_ids": [14],
  "keyword_terms": ["library kiosk", "web development"],
  "status": "draft"
}
```

```json
// PUT /api/theses/{id}  — the lifecycle the admin screen uses
{"status": "approved"}
```

```json
// PUT /api/theses/{id}  — approve, then publish
{"status": "published"}
```

```json
// PUT /api/theses/{id}  — edit a field (admin)
{"title": "Instructor Demo: Web-Based Library Kiosk (revised)"}
```

```json
// POST /api/theses/bulk-status  (UI: Approve selected / Publish selected)
{"ids": [60, 61], "status": "approved"}
```

```json
// PUT /api/theses/{id}  — returning a study to draft carries reviewer notes
{"status": "draft", "review_notes": "Please add the evaluation results."}
```

Lifecycle rules (the DB enforces these):

| From | Allowed target |
|---|---|
| `draft` | `approved`, `archived` |
| `approved` | `published`, `draft` |
| `published` | `archived` |
| `archived` | `published`, `draft` |

- `POST /api/theses` missing title/abstract/research_type/program_id/academic_year_id → `400`; unknown program/year → `400`; unknown adviser → `404`.
- A near-duplicate title/abstract returns `409` with `possible_duplicates`; resubmit with `"confirm_duplicate": true` (the UI shows a duplicate warning dialog).
- A faculty submission is forced to `draft`, and a faculty can edit/delete only their own draft.
- An invalid status transition returns `409` with `current_status` and `required_statuses`.
- `GET /api/theses` without `status` shows **published only**. `show_all=true` needs an admin token (`403` otherwise).
- PDF id example: `GET /api/theses/59/pdf` opens the 5-page PDF.

### Search and recommendations

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| GET | `/api/theses/{id}/recommend` | public | path id, `limit` 1–20 | `200` related theses with similarity |
| POST | `/api/recommendations` | any login | body: `saved_ids`, `viewed_ids`, `limit` 1–10 | `200 {personalized,basis,items,count}` |
| POST | `/api/embeddings/search` | any login | body: `query`, `limit` 1–20 | `200 {query,results,count}` |

```json
// POST /api/recommendations  (UI: student dashboard "Recommended for you")
{"saved_ids": [59], "viewed_ids": [50, 48], "limit": 4}
```

```json
// POST /api/embeddings/search  (UI: repository search with AI ranking)
{"query": "student dropout prediction", "limit": 5}
```

Expected errors: empty query → `400`; `limit` outside range → `400`; embedding
model unavailable → `503`. The first ML call after a cold start can take ~60 s
while the model loads; later calls are fast.

### Dashboards and faculty

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| GET | `/api/dashboard/stats` | admin | none | `200` studies/programs/users/authors counts |
| GET | `/api/dashboard/recent-activity` | any login | `limit` 1–100 (10), `page` ≥1 | `200 {activity,total,page,limit}` |
| GET | `/api/faculty/dashboard` | faculty | none | `200` theses/advisees/published/reviews |
| GET | `/api/faculty/activity` | faculty | `limit` 1–100 | `200 {"activity":[...]}` |
| GET | `/api/faculty/theses` | faculty | `page` ≥1, `per_page` 1–100 | `200` theses envelope |
| GET | `/api/faculty/advisees` | faculty | none | `200 {advisees,total}` |
| GET | `/api/faculty/analytics` | faculty | none | `200` totals by status/program/year |

Wrong role returns `403` ("Faculty access required" or "Admin access required").

### Metadata (UI: Programs / Categories / Authors / Advisers screens)

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| GET | `/api/programs` | public | none | `200` array |
| GET | `/api/academic-years` | public | none | `200` array |
| GET | `/api/categories` | public | none | `200` array |
| GET | `/api/keywords` | public | none | `200` array |
| GET | `/api/authors` | public | none | `200` array (email only with admin token) |
| GET | `/api/advisers` | public | none | `200` array (email only with admin token) |
| GET | `/api/research-types` | public | none | `200 ["Thesis","Capstone"]` |
| POST | `/api/authors` | admin, faculty | `first_name`, `last_name`, `email`, `middle_name` | `201` new; `200 {"reused":true}` if the person exists |
| PUT | `/api/authors/{author_id}` | admin | any of the four fields | `200` updated author |
| DELETE | `/api/authors/{author_id}` | admin | path id | `200 {"message":"Author deleted","id":...}` |
| POST | `/api/advisers` | admin | `first_name`, `last_name`, `email`, `middle_name` | `201` adviser |
| PUT | `/api/advisers/{adviser_id}` | admin | any of the four fields | `200` adviser |
| DELETE | `/api/advisers/{adviser_id}` | admin | path id | `200` |
| POST | `/api/categories` | admin | `name`, `description` | `201` category |
| PUT | `/api/categories/{category_id}` | admin | `name`, `description` | `200` |
| DELETE | `/api/categories/{category_id}` | admin | path id | `200` |
| POST | `/api/programs` | admin | `name`, `code`, `description` | `201` program |
| PUT | `/api/programs/{program_id}` | admin | `name`, `code`, `description` | `200` |
| DELETE | `/api/programs/{program_id}` | admin | path id | `200` |
| POST | `/api/academic-years` | admin | `name`, `start_year`, `end_year`, `is_active` | `201` year |
| PUT | `/api/academic-years/{year_id}` | admin | same four fields | `200` |
| DELETE | `/api/academic-years/{year_id}` | admin | path id | `200` |

```json
// POST /api/authors  (UI: Add author — First, Middle, Last, Email)
{"first_name": "Juan", "middle_name": "P.", "last_name": "Dela Cruz", "email": "juan.delacruz@student.csu.edu.ph"}
```

```json
// POST /api/advisers
{"first_name": "Ana", "middle_name": "B.", "last_name": "Reyes", "email": "ana.reyes@ceit.csu.edu.ph"}
```

```json
// POST /api/categories
{"name": "Instructor Demo Category", "description": "Created during the API demo"}
```

```json
// POST /api/programs
{"name": "BS Data Science", "code": "BSDS", "description": "Bachelor of Science in Data Science"}
```

```json
// POST /api/academic-years
{"name": "2026-2027", "start_year": 2026, "end_year": 2027, "is_active": true}
```

Deleting/renaming records that are still referenced can fail with a database
error; create a fresh "demo" record and delete that one instead of touching the
seeded rows.

### Upload and OCR

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| POST | `/api/upload/pdf` | admin, faculty | multipart: `file` (PDF ≤ 50 MB), optional form field `thesis_id` | `200` message, `page_count`, `ocr_pending`, `extracted_text`, `pdf_url` |
| POST | `/api/ocr/pdf` | admin | multipart: `file` (PDF ≤ 50 pages) | `200` message, `page_count`, `extracted_text`, `text_length` |

How to test in Swagger:

1. Click **Try it out**.
2. `file` → **Choose File** → pick any PDF under 50 MB (the repo has `backend/test.pdf`).
3. `thesis_id` is optional; leave it blank for a standalone upload, or use an
   existing **draft** id to attach the PDF to that record (faculty may only
   attach to their own draft).
4. **Execute**.

Plain text PDFs return `ocr_pending: false`; scans return `true` and are OCR'd
in the background during indexing. Non-PDF or a file without a `%PDF-` header →
`400`; over 50 MB → `413`.

### Embeddings (admin)

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| POST | `/api/embeddings/generate/{thesis_id}` | admin | path id | `200` message, `thesis_id`, `model`, `chunks`, `used_pdf` |
| POST | `/api/embeddings/generate-bulk` | admin | query `refresh=true/false` | `202 {"message":"Backfill started","refresh":false}` |
| GET | `/api/embeddings/bulk-status` | admin | none | `200` running/total/processed/embedded/skipped/failed/error |

- `generate` on a real thesis rewrites its chunks and can take a few seconds; on a
  missing id it returns `404`.
- `generate-bulk` is heavy: it re-indexes every published/approved study in a
  background thread. For the demo, only start it if you have time to wait; the
  status endpoint shows progress. Calling it twice returns "Backfill already running".

### Bulk import (admin)

| Method | Path | Who | Inputs | Success |
|---|---|---|---|---|
| GET | `/api/import/template` | admin | none | `200` CSV download (`cscholar_import_template.csv`) |
| POST | `/api/import/preview` | admin | multipart: `csv_file`, then `pdf_files` (repeat for each PDF) | `200` job with per-row actions/errors |
| POST | `/api/import/{job_id}/run` | admin | path id, empty body | `200` job with `status: queued` |
| GET | `/api/import/{job_id}` | admin | path id | `200` job/progress |
| DELETE | `/api/import/{job_id}` | admin | path id | `200 {"message":"Import preview discarded"}` |
| GET | `/api/import/{job_id}/report` | admin | path id | `200` CSV report |

Walkthrough that matches the **Bulk Import** screen:

1. `GET /api/import/template`, save the CSV, delete the two `EXAMPLE` rows, keep
   the header row, fill one row, and name the PDF exactly as `pdf_filename`
   (e.g. `CEIT_BSIT_2023_0142.pdf`).
2. `POST /api/import/preview` → `csv_file` = the CSV, `pdf_files` = every PDF.
   Expected `action` values in `rows`: `would_create`, `would_update`,
   `would_skip`, `error`.
3. If there are no errors, `POST /api/import/{id}/run`.
4. Poll `GET /api/import/{id}` until `status` is `completed` or `failed`.
5. `GET /api/import/{id}/report` downloads the report.
6. `DELETE /api/import/{id}` discards the staged files.

Imported studies are **drafts**; approve and publish them afterwards with the
thesis endpoints. Running a second import while one is active returns `409`.
Deleting a running import returns `409`.

## 4. Suggested 10-minute demo order

1. `GET /health`, `GET /api/stats/summary`, `GET /api/db-test`.
2. `POST /api/auth/login` (admin) → **Authorize**.
3. `GET /api/programs`, `/api/academic-years`, `/api/categories`, `/api/authors`,
   `/api/advisers` (copy ids).
4. `POST /api/authors` → `POST /api/theses` (draft) → `PUT` status `approved`
   → `PUT` status `published` → `GET /api/theses?q=Instructor`.
5. `POST /api/theses/bulk-status` with another draft.
6. `GET /api/theses/{id}/recommend` and `POST /api/embeddings/search`.
7. `POST /api/upload/pdf` (attach a PDF), then `GET /api/theses/{id}/pdf`.
8. `POST /api/embeddings/generate/{id}` and `GET /api/embeddings/bulk-status`.
9. `GET /api/dashboard/stats`, `GET /api/dashboard/recent-activity`.
10. `GET /api/users` → `POST /api/users` (faculty) → login as that faculty →
    `GET /api/faculty/dashboard` / `/activity` / `/theses` / `/advisees` / `/analytics`.
11. `POST /api/recommendations` with the student token.
12. Bulk import: template → preview → run → status → report → discard.
13. Clean up the records you created (`DELETE` endpoints) if the instructor
    wants the seed data untouched.

## 5. Expected errors are also "working"

The instructor may try invalid input on purpose. These are correct responses:

| Input | Result |
|---|---|
| No `Authorization` on a protected route | `401 {"error":"Missing Bearer token"}` |
| Student token on an admin route | `403 {"error":"Admin access required"}` |
| Admin token on a faculty-only route | `403 {"error":"Faculty access required"}` |
| Unknown id in the path | `404 {"error":"Not found"}` |
| Empty body on a create/update | `400` with a specific message |
| Missing multipart file | `422` with FastAPI field details |
| Bad login | `401 {"error":"Invalid credentials"}` |
| Duplicate thesis title/abstract | `409` + `possible_duplicates` |

## 6. One caution when testing `GET /api/theses` as a guest

Without `status`, the list is published-only. If you pass a non-published
`status` (for example `status=draft`) **without** an admin token, the route
currently honours it and returns matching summaries (review notes are removed).
There are no non-published records right now, but do not create a draft and then
test that combination as a guest. Use `status=published` publicly, or
`show_all=true` with the admin token for the full admin view.
