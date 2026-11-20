# Real Dataset Plan — CSU Library Theses

| Field | Value |
|---|---|
| Status | Draft for approval |
| Date | 2026-11-17 |
| Scope | CEIT theses/capstones, most recent 3-5 academic years, all programs |
| Source | Physical theses at the CSU library (no soft copies exist) |
| Permission | Approved by library and CEIT |
| Owner | TBD |

## 1. Situation

The library holds paper copies only. There is no spreadsheet, no PDF folder, and
no catalog export to import. Every record has to be created from the physical
document, and every searchable document has to be digitized.

That makes this a **data-production project** with a software component, not a
scraping job. The bottleneck is human throughput (scanning and encoding), so the
plan is built around minimizing pages captured and minimizing rework.

## 2. Dataset contract (what "done" means)

A thesis is in the dataset when all of these are true:

| Requirement | Rule |
|---|---|
| Metadata complete | title, abstract, research_type, program, academic_year all present |
| Authors | at least one, with `order_index` matching the title page |
| Adviser | present when the approval sheet names one |
| Document | a scan stored under `UPLOAD_DIR`, linked as `pdf_url` |
| Text | OCR text exists and contains the abstract verbatim (fuzzy match) |
| Embeddings | at least 1 chunk row in `thesis_embeddings` |
| Status | `published` only after QA sign-off |
| Traceable | accession number recorded (see §8) |

Target volume for the first wave: **every CEIT thesis from the last 3-5 academic
years**. Exact count comes from the inventory in Phase 0 — do not commit to a
number before the shelf count.

## 3. The central decision: front matter only, or full text?

**Decision: front matter for the corpus, full manuscripts for a 3-5 book showcase subset.**

Capture 4-6 pages per thesis:

1. Title page (title, authors, program, date)
2. Approval / signature sheet (adviser, panel)
3. Abstract page
4. Keywords page, if separate

Why:

- The matcher indexes title + abstract + PDF text. The abstract is the signal
  that makes semantic search work; chapters 1-5 add cost, not findability.
- 5 pages at ~20 seconds/page is ~2 minutes of scanning per thesis. A 150-page
  thesis is ~50 minutes. That is the difference between finishing the batch and
  abandoning it.
- Copyright: abstracts are routinely published; full manuscripts are not. A
  front-matter-only public corpus sidesteps the consent problem entirely.

**Full text is a showcase, not a requirement.** The research gap is semantic search
over the collection, which title + abstract already delivers. Scan 3-5 books
completely to demonstrate full-manuscript search, then stop. Without a book
scanner, each book costs 10-16 minutes of page turning by phone; the whole archive
would cost days and would not strengthen the argument.

Those showcase manuscripts are the only ones needing access control, since they
contain the full work. See Appendix A.

## 4. Pipeline

```
physical shelf
   -> pull + inventory (accession no, shelf count)
   -> scan front matter at library station
   -> OCR (Tesseract, local batch)
   -> encode metadata row (CSV)
   -> import batch (script: DB rows + PDF copy + embeddings)
   -> QA sample
   -> publish
```

Nothing here needs the thesis to leave the library.

## 5. Phases

### Phase 0 — Inventory and paperwork (week 1)

| Task | Output |
|---|---|
| Get the shelf list for the 3-5 target years, all CEIT programs | Count per program per year; confirms real scope |
| Confirm which programs count as CEIT (**confirmed: BSIT, BSEE, BSCpE**) | Program code list matching `programs.code` |
| Written data-use note from the library (even a signed memo) | File in `docs/` |
| Agree a scan window and supervised access | Schedule |
| Decide §3 (front matter vs full text) | Recorded decision |

**Gate:** shelf count known, or the schedule is fiction.

### Phase 1 — Scanning station (week 1-2)

Minimum viable station, set up inside the library:

- Phone with a scanning app (Microsoft Lens or Adobe Scan), or the library's
  flatbed scanner if one exists
- Phone clamp / copy stand, so pages are flat and square
- Desk lamp or window light, no flash
- A laptop for renaming and uploading at the end of each session

Rules:

- One PDF per thesis. Do not batch multiple theses into one file.
- **Put a sheet of black card behind the page before every shot.** Thesis paper
  is thin enough to show the reverse side through the leaf, and that ghost text
  is the single worst OCR failure found in testing (§7.1). This one step removes it.
- 300 DPI equivalent, greyscale, straighten + crop in the app.
- File naming: `CEIT_<PROGRAM>_<STARTYEAR>_<ACCESSION>.pdf`
  e.g. `CEIT_BSIT_2023_0142.pdf`
- Upload each session's files to the shared folder the same day. Never let scans
  live only on a phone.
- Log every thesis in the tracker as it is scanned (see §6).

**Gate:** 5 test theses scanned end-to-end and readable by OCR.

### Phase 2 — Import tooling (week 2-3)

Build `backend/scripts/import_theses.py`. Not an API endpoint — batch work should
not run inside a web request.

Requirements:

- Input: `batch.csv` + a folder of PDFs
- `--dry-run` validates everything and writes a report without touching the DB
- Idempotent: re-running the same batch must not create duplicates
- Resolves or creates `programs`, `academic_years`, `authors`, `advisers`,
  `keywords`, `categories`
- Parses names as `Last, First M.` and rejects malformed rows
- Copies PDFs into `UPLOAD_DIR` using the existing filename-safety rules
- OCRs with Tesseract when the PDF has no text layer; caches results in
  `<name>.ocr.txt` so re-runs never re-OCR
- Builds chunks and embeddings using the existing `chunking` / `embeddings`
  services, in batches, with progress output and resume support
- Inserts as `status='draft'`; publication is a separate flagged step
- Writes `import_report.csv`: row, action, thesis_id, warnings, errors

Do not reuse `/api/ocr/pdf` for this: it is admin-only, capped at 50 pages, and
serializes one request at a time.

**Gate:** dry-run on 5 scanned theses produces correct rows.

### Phase 3 — Pilot (week 3-4)

20-30 theses from one program.

Measure and record:

- Minutes per thesis, scan to published
- OCR word accuracy on a 2-page sample per thesis
- Metadata fields that are missing or ambiguous on real title pages
- Search relevance: 10 realistic queries, does the right thesis appear in top 3?

Fix the importer, the CSV format, and the field rules based on what breaks. The
pilot exists to find the ugly cases (no abstract, illegible adviser name, two
programs on one cover) before they are multiplied by 300.

**Gate:** 20+ theses published, relevance check passes, per-thesis time known.

### Phase 4 — Production batches (week 4-8)

Run in batches of ~50. One batch = one CSV + one folder + one import run + one QA
pass. Never mix unfinished batches.

Publish only after QA. Keep `draft` as the default so a bad import is invisible to
students.

### Phase 5 — QA and publish (continuous, plus final)

- 100% of rows: required fields present, PDF opens, OCR text non-empty
- 10% sample: abstract matches the physical page, author order matches title page
- Duplicate check on normalized title + year + first author
- Final relevance run across all programs
- Backup the database and the PDF folder, then restore into a scratch DB to prove
  the backup works

### Phase 6 — Steady state (after week 8)

New theses arrive every term. Define a handoff with the library: who scans, who
encodes, who imports, on what schedule. The importer makes this a recurring
30-minute task per batch instead of a project.

## 6. Metadata CSV format

One row per thesis. UTF-8, comma-separated, quoted.

| Column | Required | Example | Notes |
|---|---|---|---|
| `accession_no` | yes | `0142` | From the library record |
| `title` | yes | `Web-Based Records System for Barangay Ampayon` | Title case, as printed |
| `abstract` | yes | `This study developed...` | Full abstract, cleaned of line breaks |
| `research_type` | yes | `Thesis` | `Thesis` or `Capstone` |
| `program_code` | yes | `BSIT` | Must match `programs.code` |
| `academic_year` | yes | `2023-2024` | Must be an existing row or the importer creates it |
| `authors` | yes | `Dela Cruz, Juan P.; Santos, Maria L.` | `Last, First M.`, semicolon-separated, printed order |
| `adviser` | no | `Reyes, Ana B.` | From the approval sheet |
| `keywords` | no | `records system; barangay; web` | Semicolon-separated |
| `categories` | no | `Web Development` | Semicolon-separated |
| `pdf_filename` | yes | `CEIT_BSIT_2023_0142.pdf` | Must exist in the batch folder |
| `pages_scanned` | no | `5` | For effort tracking |
| `scanned_by` | no | `initials` | Accountability |
| `notes` | no | `abstract page torn` | Anything a reviewer should know |

Field rules to settle before encoding starts:

- Titles: keep the printed capitalization, fix only OCR artifacts.
- Author order: exactly as printed, never alphabetical.
- Middle names: include the initial if printed; do not invent.
- Abstract: verbatim. Strip page numbers, headers, and hyphenation. Do not
  paraphrase.
- Academic year: the year on the title page, mapped to the `YYYY-YYYY` label.

## 7. OCR and embedding notes

### 7.1 Measured OCR quality

Tested on this machine against a synthetic A4 thesis title page + abstract
(~190 words, Times, signatures/stamps not simulated), rendered to image and then
degraded to imitate a phone photo. Word accuracy = matched words / ground-truth
words.

| Input | Word acc. | Char ratio | Time/page |
|---|---|---|---|
| 300 DPI clean | 1.000 | 1.000 | 0.8-1.6 s |
| 200 DPI clean (current route) | 1.000 | 1.000 | 0.75 s |
| Photocopy: washed out, noisy, blurred | 1.000 | 1.000 | 0.8-0.9 s |
| Uneven lighting + 2° skew | 1.000 | 1.000 | 0.8 s |
| 150 DPI photocopy | 0.944 | 0.983 | 0.6 s |
| 15% show-through + 2° skew | **0.631** | 0.689 | 1.4 s |

Five pages at 200 DPI took **4.5 seconds** total.

Read this as a bracket, not a promise: the source was computer-rendered text, so
it is the optimistic end. Real paper adds handwriting, stamps, torn edges, and
uneven photocopy history. The show-through row is the conservative end, and it is
the one to design around — hence the black backing sheet in §5.

Conclusions:

- OCR is not the bottleneck. It is fast enough to treat as free, and accurate
  enough that the abstract survives intact at 150 DPI and above.
- 94% word accuracy is far more than semantic search needs; a few mangled words
  change a paragraph's meaning less than the embedding's 200-word window.
- The thing that breaks OCR is paper and lighting, not the software. Fix it at
  the scanner, not with Tesseract flags.
- Only English (`eng`) and orientation (`osd`) language data is installed. That is
  fine for English thesis front matter; do not plan on Tagalog/Cebuano text.

Remaining validation: run 5 **real** theses through this before Phase 3. Synthetic
pages cannot predict a 2019 photocopy with a rusty staple.

### 7.2 Batch settings

- `backend/scripts/ocr_folder.py` does this for a folder today: one `.txt` per
  PDF, text-layer PDFs read directly, results cached so re-runs skip finished
  files. Use it for the pilot instead of uploading to `/docs` one at a time.
- The app itself now OCRs scans during indexing: `services/indexing.py` falls
  back to Tesseract when PyMuPDF extracts fewer than 200 characters, caches the
  text as `<file>.ocr.txt`, and caps at 300 pages. Scanned uploads no longer fail;
  `/api/upload/pdf` returns `ocr_pending: true` and the background worker indexes
  the full manuscript a minute or two later. Tesseract must be installed on the
  machine running the backend, or scans fall back to title + abstract only.
- Use Tesseract directly in the import script (`-l eng`, `--psm 3`), at 300 DPI.
  `--psm 6` was no better and slightly worse on degraded input.
- The current route's 200 DPI is acceptable — measured no accuracy loss — so the
  existing `/api/ocr/pdf` is fine for one-off admin use.
- Crop page headers/footers where possible. The page number and running header
  end up inside the chunk text otherwise.
- Cache OCR text next to the PDF. Re-OCR is the most expensive step; never repeat
  it because of a database mistake.
- Keep the raw OCR text even after embedding. If the chunker or model changes, the
  corpus can be re-indexed without rescanning anything.
- Scan quality beats OCR settings. Blurry, skewed, shadowed pages are the main
  cause of bad text, and no flag fixes them.

## 8. Schema gap: accession number

Add to `theses`:

```sql
ALTER TABLE ceit_repo.theses
  ADD COLUMN accession_no VARCHAR(50) UNIQUE;
```

Why: without it, a record cannot be traced back to a physical volume, and
duplicate detection has no stable external key. This is the only schema change the
corpus itself requires; the optional view log in Appendix A is separate.

Follow-through when added: update `db/schema.sql`, `docs/data_dictionary.md`,
`docs/ERD.md`, and the 84-attribute total.

## 9. Roles and throughput

| Role | People | Responsibility |
|---|---|---|
| Scanner | 2-3 | Pull volumes, scan front matter, name and upload files |
| Encoder | 1-2 | Transcribe the CSV from the scans |
| Developer | 1 | Build and run the importer, fix data issues |
| QA / librarian | 1 | Verify abstracts against originals, approve publication |

Rough budget at 5 pages per thesis:

- Scanning: ~10 minutes including pulling and reshelving
- Encoding: ~10 minutes
- Import + OCR: ~1-2 minutes of machine time, unattended

So ~25 person-minutes per thesis. For 300 theses that is roughly **125 person-hours** —
two people for about four weeks of part-time work. Full-text scanning would
multiply the scanning portion by 10-30x.

## 10. Risks

| Risk | Mitigation |
|---|---|
| Shelf count is much larger than expected | Cap wave 1 by year, newest first; publish in batches |
| OCR unusable on old or dark photocopies | Re-scan at higher DPI; do not push unreadable text into embeddings |
| Missing abstracts | Record the thesis with a short factual summary marked `notes='no printed abstract'`, or exclude it — decide in Phase 0 |
| Name spelling varies across documents | Normalize once in the importer, keep the printed form in `authors` |
| Duplicate imports | Idempotency key on normalized title + year + first author; dry-run report |
| Scans lost | Daily upload to shared folder plus one offline copy |
| Physical volumes unavailable mid-project | Batch by program; work around missing volumes rather than waiting |
| Wrong `program_code` mapping | Validate against `programs.code` in dry-run, fail the batch on unknowns |

## 11. Decisions

Resolved:

1. **Scope of text.** Front matter (5 pages) for the whole corpus; full manuscripts
   for a 3-5 book showcase subset. OCR is not the constraint; scanning is.
2. **Programs.** BSIT, BSEE, BSCpE. Written to `db/bootstrap.sql` and applied.
3. **Manuscript access.** Login-only viewing, no download for students/faculty,
   admin download, per-viewer watermark. See Appendix A.
4. **Mock data.** All 12 demo theses were purged on 2026-11-17; the database holds
   reference data only. `db/seed.sql` remains a dev fixture and must never run
   against the real corpus.

Still open:

1. **Theses with no printed abstract.** Include with a short factual summary, or
   exclude from the corpus?
2. **Ongoing intake.** Who scans and encodes new theses each term after the
   project ends?

## 12. Data hygiene

Mock data was removed on 2026-11-17: 12 demo theses, their authors, advisers and
embeddings, plus the duplicate BSCE program. The database now holds reference
data only — 3 programs, 5 academic years, and the user accounts. Everything added
from here is real.

Rules:

1. Never run `db/seed.sql` against the real database. It exists for local demos.
2. On a clean database, run `db/schema.sql`, then `db/bootstrap.sql`, then
   `backend/scripts/bootstrap_admin.py`. Without the last step there is no admin
   and no way to create one through the API.
3. Import in `draft`, publish after QA. Nothing reaches students unreviewed.
4. Never delete `programs` or `academic_years` while clearing theses; the import
   depends on them.
5. Back up before bulk operations. The pre-purge backup of the demo rows is at
   `%TEMP%\cscholar_mock_backup_20261117_114002.json`.

## 13. First three actions

1. Ask the librarian for the shelf list of CEIT theses for the target years, per
   program. This is the number that sizes everything.
2. Get the written data-use note from the library and file it in `docs/`.
3. Scan 5 theses today — with a black card behind each page — and OCR the
   abstracts. The text must come out readable enough to contain whole sentences,
   not just keywords. If it does, the pipeline is viable as planned. If it does
   not, the plan changes before any tooling gets built.

## Appendix A — Manuscript access: view-only (Plan A)

Status: approved design, not built. Build after the pilot.

### A.1 Policy

| Viewer | Abstract + metadata | Manuscript |
|---|---|---|
| Anonymous | Yes | No |
| Student / faculty (logged in) | Yes | View only, watermarked |
| Admin | Yes | View + download |

The abstract is public. The manuscript is readable but not downloadable.

### A.2 What this can and cannot do

It cannot prevent copying. A browser that renders a PDF has the file; DevTools,
print-to-PDF, and screenshots all defeat any server-side control. Do not describe
this to the panel as DRM.

What it does provide:

- No download affordance in the UI for students or faculty.
- A short-lived, single-purpose link instead of the session token.
- A per-viewer watermark, so a leaked file identifies who leaked it.
- No caching of manuscripts in shared proxies.

That is enough to stop casual sharing, which is the realistic threat here.

### A.3 Current state and its two gaps

Served today by `GET /api/theses/{id}/pdf` in `routes/auth.py`, authenticated by a
Bearer header or a `?token=` query parameter.

1. **The session JWT is placed in the URL.** `thesis_detail_screen.dart`
   (`_openPdfInNewTab`) appends `?token=<24-hour JWT>`. Anyone who obtains that
   link obtains the account. This must be removed regardless of the download
   question.
2. **The PDF opens in a new tab,** so the browser's own toolbar offers Download
   and Print. `#toolbar=0` is only reliable for embedded viewers, not top-level
   tabs.

### A.4 Design

**A4.1 View ticket instead of a session token**

```http
POST /api/theses/{id}/view-ticket      (login_required)
-> 200 { "url": "/api/theses/42/pdf?v=<ticket>", "expires_in": 120 }
```

Ticket claims, signed with the existing `SECRET_KEY` via PyJWT:

```json
{ "sub": "7", "thesis": 42, "aud": "pdf-view", "exp": "<now + 120s>", "jti": "<random>" }
```

Validation on the PDF route: correct audience, thesis id matches the path, user
still active, thesis still viewable by that user. A copied URL is worthless after
two minutes and grants nothing but that one document.

Do not keep `?token=` as a fallback. Remove it from the frontend and the route.

**A4.2 Serve inline, never cached**

```http
Content-Disposition: inline; filename="thesis-42.pdf"
Cache-Control: private, no-store
X-Content-Type-Options: nosniff
Content-Security-Policy: frame-ancestors 'self'
```

**A4.3 Watermark every page**

Open the stored PDF with PyMuPDF, stamp each page with the viewer's email and
timestamp in the bottom margin, save to memory, return those bytes. The stored
file is never modified.

- Text: `viewer email · 2026-11-17 14:22`
- Size 7 pt, grey (`0.55`), `fill_opacity` around 0.35
- Applied per request, so the embedding index and the original file are untouched

Cost is roughly 0.2-1.0 s for a 100-page manuscript. No cache needed; `no-store`
already forbids it.

**A4.4 Admin download is a separate path**

```http
GET /api/theses/{id}/pdf?download=1    (admin only)
-> Content-Disposition: attachment
```

Students and faculty never receive that header. The admin action stays available
for record management.

**A4.5 Frontend**

- Hide the "View PDF" action for anonymous users.
- Request a ticket, then open the embedded viewer, not a new tab:
  - Web: `iframe`/pdf.js with `#toolbar=0&navpanes=0`
  - Mobile: in-app PDF viewer
- No download button anywhere for non-admins.
- Optional: a view event log (`thesis_views`: user, thesis, time) for traceability.

### A.5 Acceptance checks

- A ticket URL copied and opened after 2 minutes returns 401.
- No URL shown to the user contains the session JWT.
- The PDF response carries `inline` and `no-store`.
- Every page shows the viewer's email.
- A student receives no `attachment` response; an admin does.
- Anonymous and logged-out requests cannot fetch the file.
- `thesis_embeddings` and chunk text are unchanged (watermarking is per request).

### A.6 Non-goals

- Blocking screenshots or print-to-image.
- Offline reading.
- Any claim of DRM.

### A.7 Effort

| Piece | Estimate |
|---|---|
| Ticket issuance + validation, inline headers | 2 h |
| Watermarking | 1-2 h |
| Admin download route | 30 min |
| Frontend viewer + ticket flow | 2-3 h |
| Tests (expiry, audience, access matrix) | 1 h |

Total: roughly one working day.

### A.8 Scope note

This only matters for manuscripts that exist. Front-matter-only records (5 pages)
have nothing sensitive to protect and can keep the current viewer. Build Plan A
together with the full-text showcase subset, not before it.
