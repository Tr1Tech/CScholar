# Activity 10 - FastAPI Health and Endpoint Testing

**System:** CScholar (CEIT thesis repository)
**Backend run command:** `cd backend && venv\Scripts\python.exe run.py` (Uvicorn on http://127.0.0.1:5000)
**Swagger UI:** http://127.0.0.1:5000/docs
**Health check:** http://127.0.0.1:5000/health -> `{"status": "ok"}` (HTTP 200)

## Evidence Screenshots
- S01: evidence/screenshots/S01_health.png (health check)
- S02: evidence/screenshots/S02_docs.png (Swagger UI)

## Feature-to-Endpoint Inventory and Results
| ID | Method | Path | Status |
|----|--------|------|--------|
| H1 | GET | /health | 200 |
| H2 | GET | /api/health | 200 |
| H3 | GET | /api/db-test | 200 |
| A1 | POST | /api/auth/login | 200 |
| A2 | GET | /api/auth/me | 200 |
| A3 | GET | /api/users | 200 |
| A4 | POST | /api/auth/register | 201 |
| A5 | POST | /api/users | 201 |
| M1 | GET | /api/programs | 200 |
| M2 | GET | /api/academic-years | 200 |
| M3 | GET | /api/categories | 200 |
| M4 | GET | /api/keywords | 200 |
| M5 | GET | /api/authors | 200 |
| M6 | GET | /api/advisers | 200 |
| M7 | GET | /api/research-types | 200 |
| M8 | POST | /api/authors | 201 |
| M9 | PUT | /api/authors/9 | 200 |
| M10 | DELETE | /api/authors/9 | 200 |
| M11 | POST | /api/advisers | 201 |
| M12 | PUT | /api/advisers/10 | 200 |
| M13 | DELETE | /api/advisers/10 | 200 |
| M14 | POST | /api/categories | 201 |
| M15 | PUT | /api/categories/10 | 200 |
| M16 | DELETE | /api/categories/10 | 200 |
| M17 | POST | /api/programs | 201 |
| M18 | PUT | /api/programs/9 | 200 |
| M19 | DELETE | /api/programs/9 | 200 |
| M20 | POST | /api/academic-years | 201 |
| M21 | PUT | /api/academic-years/9 | 200 |
| M22 | DELETE | /api/academic-years/9 | 200 |
| T1 | GET | /api/theses | 200 |
| T2 | GET | /api/theses/21 | 200 |
| T3 | GET | /api/theses/21/recommend | 200 |
| T4 | GET | /api/theses/21/pdf | 404 |
| T5 | POST | /api/theses | 201 |
| T6 | PUT | /api/theses/28 | 200 |
| TPDF | GET | /api/theses/28/pdf | 200 |
| E1 | POST | /api/embeddings/generate/28 | 200 |
| T7 | DELETE | /api/theses/28 | 200 |
| E2 | GET | /api/embeddings/bulk-status | 200 |
| E3 | POST | /api/embeddings/generate-bulk | 202 |
| E4 | POST | /api/embeddings/search | 200 |
| D1 | GET | /api/dashboard/stats | 200 |
| D2 | GET | /api/dashboard/recent-activity | 200 |
| D3 | GET | /api/stats/summary | 200 |
| F1 | GET | /api/faculty/dashboard | 200 |
| F2 | GET | /api/faculty/activity | 200 |
| F3 | GET | /api/faculty/theses | 200 |
| F4 | GET | /api/faculty/advisees | 200 |
| F5 | GET | /api/faculty/analytics | 200 |
| U1 | POST | /api/upload/pdf | 200 |
| O1 | POST | /api/ocr/pdf | 200 |

## Error Resolution Log
| Endpoint | Before | Cause / Correction | After |
|----------|--------|--------------------|-------|
| POST /api/auth/register | 409 duplicate username/email (earlier run) | Test data already existed; used unique username per run | 201 |
| POST /api/users | 409 duplicate username (earlier run) | Same as above | 201 |
| GET /api/theses/{id}/pdf (thesis 21) | 404 No PDF attached | Expected: thesis 21 has no PDF; endpoint validated with a PDF-attached thesis | 200 (TPDF) |
| PUT /api/theses/{id} | 409 invalid status transition (earlier run) | Removed status change from update payload; title-only update | 200 |
| POST /api/upload/pdf | 500 (stale server / werkzeug missing) | Removed werkzeug dependency; replaced secure_filename with local helper; restarted server | 200 |

## Notes
- All endpoints returned HTTP 200/201/202 except the documented 404 for a thesis without an attached PDF (expected negative test).
- Test data created during the run was cleaned up (created theses/authors/advisers/etc. deleted).
