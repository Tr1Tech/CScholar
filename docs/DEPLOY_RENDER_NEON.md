# Deploy CScholar for free — Render + Neon

This is the runbook for running CScholar on a public HTTPS URL you can open on
any phone, with no server of your own and no monthly bill. It uses:

| Piece | Service | Free allowance |
|---|---|---|
| Database (Postgres + pgvector) | Neon | 1 GB storage, 100 CU-hours/month per project |
| PDF storage | Neon Object Storage (S3-compatible) | 5 GB per project |
| Backend (FastAPI) | Render, Free instance | 512 MB RAM, 750 instance hours/month |
| Web app (Flutter) | GitHub Pages | Free for public repositories |

> **Why the backend installs `requirements-render.txt` instead of
> `requirements.txt`:** torch + sentence-transformers measured **520 MB RSS**
> after loading the MiniLM model, and Render Free has 512 MB. The ONNX runtime
> (`fastembed`) runs the same weights in ~170 MB. Search results are unchanged:
> cosine similarity against the torch vectors measured **1.00000** (max abs
> difference 1.1e-07). Locally you can keep using torch.

Free-tier realities to plan around:

- Render spins the API down after **15 idle minutes**. The next request takes
  **~30–60 s** (ONNX loads faster than torch, but it is still a cold start).
- Render Free has **no persistent disk**. PDFs live in Neon Object Storage; the
  local `app/uploads` copy is disposable.
- Neon suspends idle compute after 5 minutes. The connection pool is configured
  to reconnect on checkout, so the first query after a pause just takes ~1 s.
- **Do not run a 24/7 uptime pinger.** Keeping Neon awake around the clock uses
  ~186 CU-hours/month at the smallest compute, which exceeds the 100 CU-hour
  allowance. Warm the app up manually before a session instead.
- Render may restart the service at any time. That is fine: the database and
  PDFs are external.

---

## 0. Prerequisites

- The pending work committed and pushed to `main` (Render deploys from GitHub).
- Accounts: [Neon](https://neon.com/signup) and [Render](https://dashboard.render.com/register)
  (sign in with GitHub), plus this repository on GitHub.
- PostgreSQL client tools matching your local install (for the one-time copy).
  On Windows they are in `C:\Program Files\PostgreSQL\18\bin`.

Before deploying, confirm the API surface still matches its frozen contract
(the server refuses to start otherwise):

```powershell
cd backend
venv\Scripts\python scripts\check_api_contract.py
```

---

## 1. Create the Neon database

1. Create a project on the **Free** plan in **AWS Asia Pacific (Singapore)**
   (`aws-ap-southeast-1`) — closest region to the Philippines. Choose
   **PostgreSQL 18**, the same major version as your local install, so the dump
   restores without version surprises.
2. Open **Connect** and copy the **direct** connection string, not the
   `-pooler` one. It looks like:

   ```
   postgresql://neondb_owner:PASSWORD@ep-xxxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
   ```

   The app keeps a psycopg connection pool and sets `search_path` per
   connection; Neon's transaction-mode pooler does not guarantee that setting
   survives between statements. Use the direct endpoint. One free Render
   instance will not exceed Neon's direct-connection limit. If you use the Neon
   CLI, `neon env pull` writes both as `DATABASE_URL` (pooled) and
   `DATABASE_URL_UNPOOLED` (direct), and the backend prefers the unpooled one
   automatically.

3. Enable object storage for the branch: **Project → branch → Object storage →
   New bucket**. Name it `cscholar-pdfs`, access level **private**.
4. Create a storage credential with read + write scope. In the Neon console use
   the credentials page, or with the API:

   ```bash
   curl -X POST "https://console.neon.tech/api/v2/projects/PROJECT_ID/branches/BRANCH_ID/credentials" \
     -H "Authorization: Bearer $NEON_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"scopes": ["storage:read", "storage:write"], "principal_type": "user"}'
   ```

   Save the returned `token_id` (access key) and `s3_secret_access_key`
   (secret key) immediately — the secret is shown once.

5. Get the branch's storage endpoint and region:

   ```bash
   curl "https://console.neon.tech/api/v2/projects/PROJECT_ID/branches/BRANCH_ID/storage" \
     -H "Authorization: Bearer $NEON_API_KEY"
   ```

   ```json
   {
     "s3_endpoint": "https://br-xxxx.storage.c-2.ap-southeast-1.aws.neon.tech",
     "region": "ap-southeast-1",
     "force_path_style": true
   }
   ```

   Path-style addressing is already enabled in the app.

> **CLI fast path.** Instead of the console steps above, link the project and
> provision both services from the repo root:
>
> ```bash
> neon init -y --org-id <org-id> --project-id <project-id> \
>   --branch production --services postgres,object-storage
> neon deploy
> ```
>
> This creates `neon.ts` and `package.json` and pulls nine variables into the
> git-ignored `.env.local`, including `DATABASE_URL_UNPOOLED`. The backend now
> loads that file automatically (root first, then `backend/.env`), so a local
> `python run.py` uses Neon whenever `.env.local` exists. Delete or rename it
> to go back to the local PostgreSQL. Continue at step 2.

---

## 2. Copy the real database to Neon (one time)

`db/seed.sql` is fictional demo data — **do not load it** into the cloud
database. Copy your local `cscholar` database instead, which already holds the
19 published theses, authors, users, and the 462 embedding chunks.

```powershell
$PG = "C:\Program Files\PostgreSQL\18\bin"
$env:NEON_URL = "postgresql://neondb_owner:PASSWORD@ep-xxxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"

# 1) Dump the local database
& "$PG\pg_dump.exe" -U postgres -d cscholar -Fc -f "$env:TEMP\cscholar.dump"

# 2) Restore into the empty Neon database
& "$PG\pg_restore.exe" --no-owner --no-privileges -d $env:NEON_URL "$env:TEMP\cscholar.dump"
```

The dump includes `CREATE SCHEMA ceit_repo`, `CREATE EXTENSION vector`, every
table, the views/functions/triggers from `db/logic/`, and the data.

Verify in the Neon SQL editor:

```sql
SELECT count(*) FROM ceit_repo.theses;   -- 19
SELECT count(*) FROM ceit_repo.thesis_embeddings;  -- 462 (or your current count)

SELECT extname, nspname
FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
WHERE extname = 'vector';                -- vector | ceit_repo
```

The extension **must** be in `ceit_repo`. `db/schema.sql` runs
`SET search_path TO ceit_repo` and then uses the bare `vector(384)` type, so the
type is only found in that schema.

If `pg_restore` reports that it cannot create the extension, create it first
and restore again, ignoring only `already exists` errors:

```sql
CREATE SCHEMA IF NOT EXISTS ceit_repo;
CREATE EXTENSION IF NOT EXISTS vector SCHEMA ceit_repo;
-- If the extension already exists in another schema, move it instead:
-- ALTER EXTENSION vector SET SCHEMA ceit_repo;
```

---

## 3. Copy the PDFs to Neon Object Storage (one time)

Put the storage settings in `backend/.env`:

```ini
AWS_ENDPOINT_URL_S3=https://br-xxxx.storage.c-2.ap-southeast-1.aws.neon.tech
AWS_REGION=ap-southeast-1
AWS_ACCESS_KEY_ID=nak_live_...
AWS_SECRET_ACCESS_KEY=nsk_live_...
S3_BUCKET=cscholar-pdfs
```

Then, from `backend/`:

```powershell
venv\Scripts\python scripts\upload_pdfs_to_object_storage.py --dry-run
venv\Scripts\python scripts\upload_pdfs_to_object_storage.py
```

The script uploads each file under its stored name (`<uuid>_<original>.pdf`),
which is already what `theses.pdf_url` points at, so **no database rows change**.
Re-running is safe.

From now on, a single PDF upload is mirrored to the bucket automatically, and
`GET /api/theses/{id}/pdf` keeps its login check before redirecting to a
short-lived presigned URL.

---

## 4. Deploy the backend on Render

1. In Render: **New → Blueprint**, connect this repository, pick `main`.
   Render reads [`render.yaml`](../render.yaml) and creates `cscholar-api` on
   the Free plan.
2. When prompted for the `sync: false` variables, enter:

   | Variable | Value |
   |---|---|
   | `DATABASE_URL_UNPOOLED` | the Neon **direct** string from step 1 (required) |
   | `DATABASE_URL` | optional; the pooled string, only if you want a fallback |
   | `CORS_ORIGINS` | `https://tr1tech.github.io` (no trailing slash, no path) |
   | `AWS_ENDPOINT_URL_S3` | the branch storage endpoint |
   | `AWS_REGION` | `ap-southeast-1` |
   | `AWS_ACCESS_KEY_ID` | `token_id` from the credential |
   | `AWS_SECRET_ACCESS_KEY` | `s3_secret_access_key` |
   | `S3_BUCKET` | `cscholar-pdfs` |

   `SECRET_KEY` is generated automatically. `DEBUG=0`, `EMBEDDING_BACKEND=fastembed`
   and `FASTEMBED_THREADS=1` are set in the blueprint.
3. Watch the build. It installs the ONNX runtime and pre-downloads the model
   into `backend/.fastembed_cache` (a few minutes the first time).
4. When it is live, open:

   - `https://<your-service>.onrender.com/api/health` → `{"status":"ok",...}`
   - `https://<your-service>.onrender.com/api/db-test` → `"connection": "ok"`,
     `theses: 19`
   - `https://<your-service>.onrender.com/docs` → Swagger, 63 operations

   The first request after a deploy is slow; that is the cold start, not a bug.

If the log says `Out of memory` / `Killed`, the build installed torch by
mistake. Check that Render is running `pip install -r requirements-render.txt`
and that `EMBEDDING_BACKEND=fastembed`.

---

## 5. Publish the web app on GitHub Pages

1. Repository **Settings → Pages → Build and deployment → Source:
   GitHub Actions**.
2. Repository **Settings → Secrets and variables → Actions → Variables → New
   repository variable**:

   | Name | Value |
   |---|---|
   | `API_BASE_URL` | `https://<your-service>.onrender.com` (no trailing slash) |

3. **Actions → Deploy web app → Run workflow** (or push a change under
   `frontend/`). The workflow builds with
   `--base-href /CScholar/ --dart-define=API_BASE_URL=...` and publishes to:

   ```
   https://tr1tech.github.io/CScholar/
   ```

4. If the browser console shows a CORS error, the origin in Render must be
   exactly `https://tr1tech.github.io` (the app is served from a subpath but the
   origin has no path). Changing the variable restarts the API.

> Deploys are tied to the repository name. If the repo is renamed, update
> `--base-href` in `.github/workflows/deploy-web.yml`; if you add a custom
> domain, rebuild with `--base-href /`.

---

## 6. Put it on your phone

1. Open `https://tr1tech.github.io/CScholar/` in Chrome (Android) or Safari
   (iOS). Flutter web uses hash routing, so no server-side rewrite is needed.
2. Add it to the home screen:
   - Android Chrome: **⋮ → Add to Home screen**
   - iOS Safari: **Share → Add to Home Screen**
3. Sign in. Existing accounts and password hashes were copied with the dump.

For a survey session, open the app once **a minute before** respondents start so
the API is awake. After 15 idle minutes it sleeps again.

---

## 7. Pre-session checklist

Run this against the public URL, not localhost:

- [ ] `/api/health` returns OK (warm-up request).
- [ ] Login works for the account you will use.
- [ ] Keyword search returns published theses.
- [ ] Semantic search / recommendations return results (proves the ONNX model
      loaded).
- [ ] A thesis detail opens and **Open PDF** downloads from the presigned URL.
- [ ] The app is installed on the phone's home screen and opens offline-ish
      (the shell loads; data needs the API).
- [ ] Neon dashboard shows compute awake and storage usage well under 5 GB.
- [ ] Render dashboard shows the service live and memory comfortably below
      512 MB.

---

## 8. Deploying updates

- Backend: `git push` to `main` → Render rebuilds automatically. Uploaded PDFs
  survive because they are in Neon, not on the instance.
- Frontend: `git push` to `main` with changes under `frontend/` → GitHub Pages
  workflow rebuilds. To force a rebuild after changing `API_BASE_URL`, run the
  workflow manually.
- Contract guard: if you change routes, the API refuses to start until
  `backend/api_contract.json` is regenerated deliberately with
  `venv\Scripts\python scripts\check_api_contract.py --write`.

---

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| First load hangs ~60 s | Render Free cold start after 15 idle minutes | Expected. Warm it with `/api/health` before the session. |
| `502` for a minute after a push | New instance starting | Wait, then retry. |
| `Out of memory` in Render logs | torch installed, or two instances | Use `requirements-render.txt`; confirm `EMBEDDING_BACKEND=fastembed`; keep one instance. |
| Search returns `503` / no AI rail | Model failed to load | Check Render logs for the fastembed download; the first boot needs outbound access to the Hugging Face Hub. |
| `/api/db-test` shows `connection` missing | Wrong `DATABASE_URL`/`DATABASE_URL_UNPOOLED` or password | Use the direct Neon string with `?sslmode=require`; re-copy it. |
| `relation "theses" does not exist` | `search_path` is wrong on a manual query | Prefix with `ceit_repo.` or `SET search_path TO ceit_repo;`. |
| PDF opens 404 | File not in the bucket, or storage env vars missing | Re-run `scripts/upload_pdfs_to_object_storage.py`; check all five `AWS_*`/`S3_BUCKET` vars. |
| CORS error in the browser | Origin not allowed | Set `CORS_ORIGINS=https://tr1tech.github.io` in Render and let it redeploy. |
| Login says `Session expired` after deploy | `SECRET_KEY` changed (new service or generated value) | Sign in again; tokens are intentionally invalidated. |
| Render suspends all services mid-month | 750 free instance hours used | Free hours reset at the start of the month; keep the service asleep when idle. |
| Neon compute suspended | 100 CU-hours or 5 GB transfer used | Resets next billing period; upgrade or wait. |

---

## 10. What is intentionally not on the free host

- **Admin bulk import.** It stages uploaded files on local disk
  (`app/uploads/_import_jobs`) and a free instance can restart mid-job. Use
  single-PDF upload, or run bulk import locally and copy the results.
- **Guaranteed uptime.** Render Free may restart at any time and sleeps when
  idle. That is acceptable for a survey window, not for a production archive.
- **Long-term PDF privacy beyond the app.** The bucket is private and access
  goes through the authenticated endpoint, but anyone with the storage
  credential can read objects. Keep the credential in Render's environment
  only.
