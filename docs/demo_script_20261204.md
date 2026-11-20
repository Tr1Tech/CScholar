# Demo script — December 4, 2026

| Field | Value |
|---|---|
| Build | P0 demo build (freeze Dec 1) |
| Duration | 12 minutes, 3 minutes Q&A |
| Corpus | 19 published CEIT theses/capstones |
| Evaluated retrieval | keyword hit@3 6/10, MRR 0.60; semantic hit@3 9/10, MRR 0.85 |

This script is a run sheet, not a transcript. Say the lines in your own words,
but keep the claims exactly as written — they are the ones the data supports.

## 1. Accounts

| Role | Username | Password |
|---|---|---|
| Student | `demostudent` | team-held; do not type on screen |
| Admin | `admin1` | team-held; do not type on screen |
| Faculty (demo) | `demo_faculty` | team-held; do not type on screen |

`demo_faculty` is a temporary account linked to **Joseph Vistal** so the
faculty pages have data. It is not a real person and must be removed after the
defense. Do not open **Users** while presenting; the account is not the point.

## 2. Pre-flight (T-15 minutes)

From `backend/`, with the database running:

```powershell
venv\Scripts\python.exe run.py
```

Then, in a second terminal:

```powershell
venv\Scripts\python.exe scripts\demo_preflight.py
```

Every line must read `PASS`. If the API is up but a check fails, **restart the
backend**. On Nov 20 the uvicorn reloader silently kept serving an old build
(adviser search returned 0, anonymous advisers leaked an email); a full restart
fixed both. Do not trust auto-reload on demo day.

Also confirm before presenting:

- [ ] Browser at 100% zoom, notifications off, only the demo tabs open.
- [ ] Signed out of every account; start from the login screen.
- [ ] Fresh backup exists: `backups\cscholar_<stamp>.dump` and
      `backups\uploads_<stamp>.zip`.
- [ ] PDF viewer opens a local file (test one before the panel arrives).
- [ ] Laptop on power, screen sleep disabled.

## 3. Run of show

### 0:00 — Opening (30 s)

> "CScholar is the CEIT thesis and capstone repository for CSU Cabadbaran. It
> replaces the shared-drive folder with a searchable, role-aware system. Two
> things make it more than a database: semantic search over the manuscript
> text, and publishing controls that keep drafts out of the public view."

### 0:30 — Student: literal search (1.5 min)

Sign in as `demostudent`, open **Research** (sidebar), keep **Keyword** selected.

1. Type `library`.
2. Result: **59 — LIBRARY MONITORING AND BORROWING INFORMATION SYSTEM** first.
3. Point at the card: title, authors, adviser, program, year, type.

> "Keyword mode is literal: it looks for the phrase in the title, abstract,
> keywords, author names, and adviser names. That is fast and predictable, and
> it is what most repositories do."

### 2:00 — Student: semantic contrast (2 min)

1. Toggle **Semantic**.
2. Type `detecting cars on the road`.
3. Result: **54 — VEHICLE DETECTION USING YOLO V5** at ~57%, then 48, then 42.
4. Clear, type `vacation leave`.
5. Result: **51 — WEB-BASED EMPLOYEES LEAVE INFORMATION SYSTEM** first.

> "Neither phrase appears in those titles. Keyword mode returns nothing for
> 'vacation leave' — the study says 'employees leave'. Semantic mode embeds the
> query and every manuscript chunk with a sentence model, then ranks by cosine
> distance in PostgreSQL using pgvector. It retrieves by meaning, not spelling."

If asked about the model: `all-MiniLM-L6-v2`, 384 dimensions, chunked
manuscripts, 462 vectors for 19 records.

### 4:00 — Student: adviser-aware search (1 min)

1. Toggle back to **Keyword**.
2. Clear, type `Vistal`.
3. Result: 4 studies (48, 50, 54, 56).

> "Search also matches the adviser, not just the student authors. A faculty
> member checking what a colleague supervised gets the four studies they
> advised."

### 5:00 — Study detail (2 min)

1. Open **54 — VEHICLE DETECTION**.
2. Walk the abstract, authors, adviser, program, year.
3. Press **Read PDF**; the stored manuscript opens. Close it.
4. Scroll to **Related research**.

> "Related research is content similarity: the nearest published studies to
> this one. It is not personalized and it does not use viewing history."

Do not call this an AI recommendation. The desktop build still says
"Recommended Studies"; the capstone unifies that copy.

### 7:00 — Admin: publishing controls (2.5 min)

Sign out, sign in as `admin1`.

1. **Dashboard** — totals for the 19 published records and 3 programs.
2. **Theses / Capstone** — point out status filters and that only published
   records reach the public repository. Do not change a record's status.
3. **Bulk Import** — show **Download CSV template**, the two inputs (metadata
   CSV, PDF manuscripts), and explain the pipeline: validate the batch, preview
   per-row errors, import as drafts, then publish through Thesis Management.
   Do not run an import live.
4. Mention the audit log: submissions, approvals, and status changes are
   recorded with the acting user.

> "Nothing goes public without review. Import creates drafts; an admin
> publishes after checking metadata and the PDF."

Avoid the **Users** page in the demo (temporary demo account).

### 9:30 — Faculty: advising view (2 min)

Sign out, sign in as `demo_faculty`.

1. **Dashboard** — 4 studies, 12 advisees, 4 published.
2. **My Theses** — the same four studies.
3. **My Students** — the roster. Search `Glen`; tap a student; the dialog lists
   that student's studies. Close it.
4. **Analytics** — counts by year and program.

> "Faculty see the students they advise and the studies they supervise. The
> roster is identity first — name, program, study count — because a student can
> have more than one study."

### 11:30 — Close (30 s)

> "Today the repository holds 19 complete CEIT records. On the same ten queries,
> keyword retrieval puts the right study in the top three six times; semantic
> retrieval does it nine times, with a mean reciprocal rank of 0.85 versus 0.60.
> The next phase is growing the corpus to 100–150 records, adding people
> profiles, and bringing semantic search to the faculty and admin shells."

## 4. Ten queries and fallbacks

Use these exact queries. Expected results come from
`docs/evaluation/relevance_20261120.md`; re-run
`backend/scripts/eval_relevance.py` if the corpus changes.

### Keyword scenes

| # | Query | Expected top result | If it fails, say |
|---|---|---|---|
| 1 | `library` | 59 LIBRARY MONITORING AND BORROWING | "Keyword is literal; let me show the semantic mode, which is the point." |
| 2 | `scholar tracking` | 57 SCHOLAR TRACKING INFORMATION SYSTEM | "The phrase matches this title exactly; that is the expected behaviour." |
| 3 | `driver's license` | 48 DRIVER'S ID CARD EXTRACTOR | "The title says 'driver's ID card', so this is a near phrase, not an exact one." |
| 4 | `hometel reservation` | 41 HOMETEL RESERVATION SYSTEM | "It is a unique term in this corpus, so one result is correct." |
| 5 | `incoming and outgoing communication` | 46 DOCUMENT MANAGEMENT SYSTEM | "This is verbatim from the title." |

### Semantic scenes

| # | Query | Expected top-3 | If it fails, say |
|---|---|---|---|
| 6 | `detecting cars on the road` | 54 (57%), 48 (43%), 42 (28%) | "Use 'driver's license' next; it is the same neighbourhood with a stronger vector." |
| 7 | `monitoring electricity of a transformer` | 49 (56%), 42 (37%), 50 (25%) | "The transformer study is IoT monitoring; the model also pulls monitoring systems, which is reasonable but not perfect." |
| 8 | `vacation leave` | 51 (24%), 50 (21%), 41 (20%) | "Keyword returns zero here; semantic's top hit is the leave system at 24%. Low scores are expected in a 19-record corpus." |
| 9 | `library` | 59 (48%), 42 (30%), 55 (29%) | "Same record as keyword, but the ranking behind it is by meaning." |
| 10 | `hometel reservation` | 41 (66%), 50 (39%), 52 (24%) | "A distinctive phrase gives a high-confidence vector; that is the easy end of the scale." |

**Known miss, do not hide it:** `finding a place to stay near campus` should
retrieve 58 (boarding house mapping) but ranks 41, 47, 57. Say:

> "This is the one paraphrase we miss. At 19 records the embedding space is
> sparse, and 'place to stay' is closer to a hometel than to a boarding-house
> mapping system. It is why the evaluation reports 9/10, not 10/10."

## 5. Claims to avoid

| Do not say | Say instead |
|---|---|
| "AI recommends studies for you" | "Related research shows content-similar studies" |
| "Personalized recommendations" | "Nearest-neighbour retrieval; there is no user profile" |
| "It understands everything" | "It ranks by semantic similarity; one paraphrase miss is documented" |
| "99% accurate" | "hit@3 9/10 on ten labeled queries, 19 records" |
| "ChatGPT for theses" | "Sentence embeddings plus pgvector, not a generative model" |
| "All CEIT studies" | "19 complete records with PDFs and metadata, growing" |

## 6. Failure drills

- **Semantic returns 0 results.** The embedding service may not be loaded.
  Switch to Keyword, keep presenting, and check
  `count_thesis_embedding_chunks` after the session. Do not debug live.
- **PDF does not open.** Show the metadata and say the file is served from the
  same record; retry once. If it still fails, move on — the repository view is
  the claim, not the viewer.
- **A page is slow.** Narrate the stack: Flutter web client, FastAPI, PostgreSQL
  with pgvector; the first semantic query warms the model.
- **Projector/network dies.** The app can run locally; the database and API are
  on the demo laptop. Restore from the backup if needed (section 7).
- **A panelist asks for a query you did not rehearse.** Take it, run it, and
  interpret the result honestly. If it misses, say why the corpus is small.

## 7. Freeze, backup, and restore

Freeze code on **Dec 1**. After that, only demo-blocking fixes.

Current restore point (Nov 20, 2026 17:33):

- `backups\cscholar_20261120_1733.dump` (custom-format database dump)
- `backups\uploads_20261120_1734.zip` (32 PDFs, ~128 MB)

Restore drill, already exercised once:

```powershell
$env:PGPASSWORD='<password>'
$bin='C:\Program Files\PostgreSQL\18\bin'
& "$bin\createdb.exe" -h localhost -U postgres cscholar_restore_check
& "$bin\pg_restore.exe" -h localhost -U postgres -d cscholar_restore_check `
    --no-owner --no-privileges backups\cscholar_20261120_1733.dump
```

Verified counts in the restored copy: 19 theses (all published), 58 authors,
10 advisers, 23 users, 462 embedding chunks, 1 adviser email. Drop the scratch
database afterwards.

To recover the demo machine: restore into `cscholar`, unzip the PDFs into
`backend\app\uploads\`, start the backend, and run `demo_preflight.py`.

## 8. Post-defense cleanup

Do this on Dec 5, before any real faculty emails are added:

```sql
UPDATE ceit_repo.advisers SET email = NULL
WHERE LOWER(last_name) = 'vistal';
DELETE FROM ceit_repo.users WHERE username = 'demo_faculty';
```

Then confirm:

- zero adviser emails unless a real faculty address was intentionally added;
- `demo_faculty` no longer exists;
- the public repository still shows 19 published records;
- `demo_preflight.py` fails only the demo-faculty check (expected after
  cleanup), and every other check stays green.
