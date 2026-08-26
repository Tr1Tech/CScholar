# CScholar

**Semantic Search and AI-Powered Recommendation System for the Caraga State University (CSU) Thesis and Capstone Repository — CEIT edition**

A thesis/capstone repository for the **College of Engineering and Information Technology (CEIT)** at CSU.
Authorized students, faculty, and admins can browse, filter, search, and discover CEIT research
using AI-powered **semantic search** and **content-based recommendations**.

> Scope note: this system covers **CEIT only**, for a limited academic year (e.g. 2025–2026).
> It does not cover other CSU colleges unless explicitly requested later.

## Technology Stack (agreed baseline)

| Layer | Technology |
|---|---|
| Frontend | Flutter (web + mobile) |
| Backend | Flask + Python (REST API, JSON) |
| Database | PostgreSQL |
| Vector search | pgvector |
| AI/ML | Sentence Transformers (`all-MiniLM-L6-v2`, 384-dim) |
| PDF processing | PyMuPDF |
| Web server | Nginx / Apache |
| Hosting | Cloud / VPS |
| Version control | Git + GitHub |

## Project Structure

```
capstopn/
├── backend/      # Flask API (Python)
├── frontend/     # Flutter app (web + mobile) — built in Phase 9/10
├── db/           # SQL schema + mock seed data (Phase 2+)
├── docs/         # Capstone papers, ERD, diagrams
└── README.md
```

## Development Phases

1. Project architecture & repository setup ✅ (this commit)
2. PostgreSQL database + pgvector
3. Flask backend setup
4. Authentication & authorization
5. CEIT program & academic-year management
6. Thesis/capstone CRUD
7. Author / adviser / category / keyword management
8. PDF upload & PyMuPDF extraction
9. Flutter web interface
10. Flutter mobile interface
11. Normal search & filters
12. Embedding generation (Sentence Transformers)
13. pgvector semantic search
14. Content-based recommendations
15. Admin dashboard & logs
16. Testing, security, deployment

## Running the Backend (Phase 1)

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
cp .env.example .env        # then edit if needed
python run.py
```

Then open: http://localhost:5000/api/health

Expected response:
```json
{"status":"ok","service":"CScholar API","project":"capstopn (CEIT thesis repository)","phase":1}
```
