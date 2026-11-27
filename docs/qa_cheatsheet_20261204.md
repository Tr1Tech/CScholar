# Q&A cheat sheet — December 4, 2026

| Field | Value |
|---|---|
| Use | Spoken answers for the 3-minute Q&A (and any mid-demo question) |
| Build | P0 demo build, frozen 2026-12-01 |
| Corpus | 19 published CEIT theses/capstones |
| Last verified | 2026-11-21 (preflight 11/11, restore drill, live keyword logging) |

Say the answers in your own words. The numbers and the "don't say" list are the
parts to keep exact.

## 0. Numbers to have ready

| Fact | Value |
|---|---|
| Physical tables | **19 = 16 domain + 3 operational** |
| Operational tables | `thesis_reviews` (lifecycle trail), `import_jobs` (bulk-import state), `security_audit_log` (sign-ins and admin actions) |
| Published records | 19 |
| Authors / advisers / users | 58 / 10 / 23 |
| Embedding chunks | 462 |
| Embedding model | `all-MiniLM-L6-v2`, 384 dimensions |
| Keyword retrieval | hit@1 6/10, hit@3 6/10, MRR 0.60, ~10 ms |
| Semantic retrieval | hit@1 8/10, hit@3 9/10, MRR 0.85, ~32 ms |
| Semantic-only wins | 3 of 10 queries; keyword-only wins: 0 |

## 1. Database and ERD

**"The ERD says 16 tables. Why does the database have 19?"**
> "The ERD models the 16 domain relations. Three operational tables sit outside
> that model: `thesis_reviews` keeps the lifecycle audit trail, `import_jobs`
> keeps bulk-import state, and `security_audit_log` records sign-ins, account
> changes, and taxonomy edits."

**"What exactly is in `thesis_reviews`?"**
> "One row per decision — who approved, published, archived, or returned a study,
> with the note and timestamp. `theses.review_notes` only keeps the latest note;
> the table keeps the history, so re-approving can't erase why a study was
> returned before."

**"Why does import state need a table?"**
> "The Bulk Import screen polls progress across separate requests, and a server
> restart must not lose a running job. In-memory state would; the table is the
> shared, restart-safe record."

**"Is the schema normalized?"**
> "All 16 domain relations are in 3NF and BCNF. The three operational tables are
> verified separately and also pass 1NF–BCNF; they're excluded from the 16 count
> because they're workflow records, not domain entities."

**"Why PostgreSQL instead of MongoDB?"**
> "The data is highly relational — theses, authors, advisers, categories, and
> keywords are many-to-many. Foreign keys and junctions give us integrity the
> app would otherwise have to enforce. JSONB covers the log/report payloads, and
> pgvector keeps semantic search in the same database."

## 2. Search and "AI"

**"Is this actually AI?"**
> "It's semantic retrieval, not a generative model. Each thesis chunk is embedded
> with all-MiniLM-L6-v2 into a 384-dimension vector; a query is embedded the same
> way and ranked by cosine similarity in pgvector. It never generates an answer
> or invents a citation."

**"Why does the rail say 'AI Recommendations' but the badge says 'Semantic match'?"**
> "'AI Recommendations' is the product label; 'Semantic match' is what the score
> actually is. We keep the label honest by never claiming a learned user profile."

**"How do you know semantic search is better?"**
> "Ten labeled queries on the 19-record pilot. Keyword hit@3 is 6/10 with MRR
> 0.60; semantic is 9/10 with MRR 0.85. Semantic won three queries that keyword
> missed, all paraphrases like 'detecting cars on the road' for the YOLO thesis.
> It's a smoke test, not a blind benchmark — the queries were written from the
> titles."

**"Isn't hit@3 on 19 records easy?"**
> "Fair. It's a pilot-scale check, not a claim of production accuracy. The useful
> signal is the gap: keyword mode matches one contiguous substring, so paraphrases
> return nothing; semantic recovers them. That's why the capstone plan is to grow
> the corpus and run a blind evaluation."

**"Keyword versus semantic — when does each win?"**
> "Keyword wins on exact names and phrases, like `Vistal` for an adviser's four
> theses. Semantic wins on meaning, like 'monitoring electricity of a
> transformer' returning the IoT transformer study. Both stay available; the
> user toggles."

## 3. Recommendations

**"How personalized is 'Recommended for You'?"**
> "It's content-based, anchored on your last action. Opening or saving a study
> stores its id on the device; the server ranks the nearest published studies to
> that one. There's no per-user profile table and no learned interest model. With
> no history yet, the card falls back to the newest published studies."

**"So it's not machine learning on the user?"**
> "No. The only model is the sentence embedder. The personalization is one anchor
> id kept in `SharedPreferences`; the caption says exactly why a row is there —
> 'Because you viewed X' or 'New in the repository.'"

**"Do you log what was shown?"**
> "Yes — impressions go to the existing `recommendation_logs` table. The feature
> added no tables or columns."

## 4. Lifecycle, roles, and review

**"Who can create and publish?"**
> "Faculty and admins can create. Faculty submissions and admin Add Thesis both
> save as drafts. An admin approves, then publishes. Students are read-only for
> the corpus."

**"Can a student see a draft by guessing the URL?"**
> "No. The public list filters to published, and the detail and PDF endpoints
> return 404 for an unpublished record unless the caller is authorized for it."

**"How do you prove a record was reviewed?"**
> "`thesis_reviews` has one row per decision with the reviewer and timestamp.
> The demo line is 'nothing goes public without review' — both entry paths now
> create drafts, and only an admin can move draft → approved → published."

**"What happens when a study is returned?"**
> "It goes back to draft, the approval stamp is cleared, and the return note is
> kept both as the latest note on the record and in the review history."

## 5. Security and privacy

**"How are passwords stored?"**
> "Bcrypt hashes, never plaintext. Sessions use signed JWT bearer tokens, and the
> server checks role and active status on every protected route."

**"Are author and adviser emails exposed?"**
> "No. The anonymous `/api/authors` and `/api/advisers` payloads omit email. Only
> one adviser email is seeded, to link the temporary `demo_faculty` account, and
> it's removed on Dec 5."

**"Are PDFs public?"**
> "No. The PDF endpoint requires a valid token, and unpublished PDFs are limited
> to authorized users."

**"Do you log searches?"**
> "Yes, in the existing `search_logs` table: query text, JSONB filters, result
> count, and the user id when signed in (NULL for anonymous). Keyword and
> semantic calls are tagged with `mode` so they're distinguishable."

**"Do you audit admin and security events?"**
> "Yes. `security_audit_log` is append-only and records sign-ins, failed and
> throttled sign-ins, password changes, user create/update/deactivate, thesis
> create/update/delete, taxonomy edits, imports, and index backfills. It stores
> the actor, action, target, IP, and time — never passwords, tokens, or query
> strings. The admin Activity & Logs page reads it through the admin-only
> audit endpoint."

## 6. Data, import, and limits

**"Where did the corpus come from?"**
> "Nineteen CEIT thesis/capstone PDFs with a metadata CSV. The backend OCRs and
> chunks the PDFs, then embeds each chunk — 462 chunks in the current corpus."

**"How does bulk import work?"**
> "Upload a CSV plus PDFs, preview the mapped rows, confirm, and a background
> worker imports them as drafts with a per-row report. One batch runs at a time
> so the OCR and embedding model aren't fighting each other."

**"How do you detect duplicates?"**
> "Today it's an exact normalized-title check with a confirmation dialog.
> Embedding-based near-duplicate detection is a capstone item — I won't claim it
> works now."

**"What isn't finished?"**
> "People/adviser pages, the faculty/admin repository search UI, embedding-based
> duplicate detection, and scheduled cleanup of abandoned import staging folders.
> They're scoped for the capstone, not hidden gaps."

## 7. Engineering

**"Why Flutter?"**
> "One codebase for web and mobile. The role separation is enforced by the API,
> not just by hiding buttons in the client."

**"How is it tested?"**
> "366 frontend tests, a backend compile/import check, an 11-check demo preflight
> against the live API, and a database restore drill with verified row counts."

**"What happens if the database is lost?"**
> "Restore the Nov 21 dump into `cscholar`, unzip the PDFs into
> `backend/app/uploads/`, start the backend, and run the preflight. The restore
> path was exercised and the counts matched."

## 8. If something fails live

| Failure | Say / do |
|---|---|
| Semantic rail unavailable | "The embedding service is down; keyword search and filters still work." Switch off Semantic Search and continue. |
| Search returns nothing | Clear filters, try a known term (`library`, `scholar tracking`, `driver's license`), or switch modes. |
| A PDF won't open | Move to a record verified by preflight (ids 59, 50, 41) and continue; mention the token-protected endpoint. |
| Backend stops | Restart `venv\Scripts\python.exe run.py`, run `scripts\demo_preflight.py`, resume at the next section. |
| Database corrupted | Restore `backups\cscholar_20261121_0015.dump` (Nov 21). **Do not use the Nov 20 dump** — it contains the Lab 5 audit table. |
| Login fails | Restart the backend (a stale auto-reloader caused this on Nov 20), then retry. |

## 9. Don't say

- "99% accurate." Say **hit@3 9/10 on ten labeled queries, 19 records**.
- "The AI understands / recommends." Say **semantic similarity ranks the nearest published studies**.
- "Personalized to your interests." Say **anchored on your last viewed or saved study**.
- "We have 16 tables." Say **16 domain + 3 operational**.
- "Students can upload." Say **faculty and admins create; students are read-only**.
- "Add Thesis publishes immediately." Say **it saves a draft; an admin approves and publishes**.
- "Production-ready." Say **pilot build with a 19-record corpus**.
- Anything about blockchain or citation generation — none of it is in the build.

## 10. Reset before Q&A

- Sign out; leave the app on the login screen.
- Clear search text and filters.
- Browser at 100% zoom, notifications off, only demo tabs open.
- If asked to show the database: run `\dt` and point at **19** — 16 domain + 3 operational.
