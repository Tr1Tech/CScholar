# CScholar

CScholar is a website and phone app where CEIT students, faculty, and admins can
search for thesis and capstone projects. It can find projects by meaning, not
just by exact words, and recommends related studies.

This page explains how to get it running on your own computer. Follow the steps
in order. After each step there is a **"You should see"** note so you know it
worked. You do not need to understand the code.

> If you get stuck, jump to [If something goes wrong](#if-something-goes-wrong)
> at the bottom. Most problems have a simple fix.

---

## Step 1 — Install three free tools

You only do this once per computer.

| Tool | What it is for | Where to get it |
|---|---|---|
| **Python 3.11** | Runs the server that stores and searches the data | https://www.python.org/downloads/ |
| **Flutter** | Builds the website and app screens | https://docs.flutter.dev/get-started/install |
| **PostgreSQL 18** | The database (where the thesis records live) | https://www.postgresql.org/download/windows/ |

**Important during the Python install:** tick the box that says
**"Add python.exe to PATH"** before clicking Install.

**During the PostgreSQL install:** you will be asked to create a password for
the `postgres` user. Write it down — you need it in Step 4.

PostgreSQL also needs a small add-on called **pgvector**. The friendly install
guide for that is in [`db/setup.md`](db/setup.md).

### Check that they installed

Open a **new** terminal window:

- Windows: press the Start button, type `PowerShell`, press Enter.
- macOS: open Terminal.
- Linux: open Terminal.

Type each line below and press Enter:

```bash
python --version
flutter --version
psql --version
```

**You should see** something like:

```
Python 3.11.x
Flutter 3.47.x
psql (PostgreSQL) 18.x
```

If Windows says `psql is not recognized`, see
[psql is not recognized](#psql-is-not-recognized) below.

---

## Step 2 — Download the project

In the same terminal, type:

```bash
git clone https://github.com/Tr1Tech/CScholar.git
cd CScholar
```

**You should see** a new folder named `CScholar`, and the terminal prompt now
ends with `CScholar`.

> No Git? Go to the GitHub page, click the green **Code** button, choose
> **Download ZIP**, unzip it, then open a terminal inside that folder. Every
> command below still works.

---

## Step 3 — Set up the database (one time)

This creates the tables and adds three sample theses so the app has something to
show.

First, make sure PostgreSQL is running. On Windows it runs as a service called
`postgresql-x64-18`, which usually starts automatically.

From the `CScholar` folder, run these four commands **one at a time**. Replace
`YOUR_PASSWORD` with the password you wrote down in Step 1.

```bash
psql -U postgres -c "CREATE DATABASE cscholar;"
```

```bash
psql -U postgres -d cscholar -f db/schema.sql
```

```bash
psql -U postgres -d cscholar -f db/seed.sql
```

```bash
psql -U postgres -d cscholar -f db/logic/cscholar_lab5_logic.sql
```

Each command may ask for the `postgres` password. Type it (the screen stays
blank while you type — that is normal) and press Enter.

**You should see** messages ending in `CREATE DATABASE`, `CREATE TABLE`,
`INSERT 0 3`, and so on. Warnings that say `does not exist, skipping` are normal.

### Check that it worked

```bash
psql -U postgres -d cscholar -c "SELECT COUNT(*) FROM ceit_repo.theses;"
```

**You should see** `3`.

> `ceit_repo.` is not a typo. All CScholar tables live in a section of the
> database called `ceit_repo`, so you must include it when typing queries by
> hand. The app already knows this.

Having trouble with PostgreSQL? Follow the step-by-step guide in
[`db/setup.md`](db/setup.md).

---

## Step 4 — Start the server

The server is the part that reads the database and answers the app.

Open a terminal in the `CScholar` folder and run:

```bash
cd backend
python -m venv venv
```

**You should see** a new `venv` folder inside `backend`. This holds the Python
libraries so they do not interfere with other projects.

Now switch the terminal into that environment:

```bash
venv\Scripts\activate
```

On **macOS/Linux**, use this instead:

```bash
source venv/bin/activate
```

**You should see** `(venv)` at the start of the prompt.

Install the libraries (this can take several minutes the first time):

```bash
pip install -r requirements.txt
```

Create your settings file:

```bash
copy .env.example .env
```

On **macOS/Linux**, use `cp .env.example .env` instead.

Now open `.env` in Notepad (or any text editor) and change the password:

```bash
notepad .env
```

Find this line:

```ini
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/cscholar
```

Replace `YOUR_PASSWORD` with your real PostgreSQL password, save, and close
Notepad.

> If your password contains `@`, `:` or `/`, write it in encoded form:
> `@` becomes `%40`, `:` becomes `%3A`, `/` becomes `%2F`.

Start the server:

```bash
python run.py
```

**You should see** a line ending with:

```
Uvicorn running on http://0.0.0.0:5000
```

**Leave this window open.** Closing it stops the server.

---

## Step 5 — Check the server

Open your browser and go to:

**http://localhost:5000/api/db-test**

**You should see** a page of text that includes:

```json
"connection": "ok"
```

If it says anything else, or the page spins for about 30 seconds and fails,
see [The server hangs or the database will not connect](#the-server-hangs-or-the-database-will-not-connect).

---

## Step 6 — Start the app

Open a **second** terminal window (keep the server running in the first one).
Go to the project folder and then the frontend:

```bash
cd CScholar
cd frontend
flutter pub get
```

**You should see** `Got dependencies!`

Now start the app in Chrome:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

The first run downloads and builds the app, which can take **5–10 minutes**.
After that it opens a Chrome window with the CScholar login screen.

### Sign in with the sample account

```
Email:    admin@csu.edu.ph
Password: admin123
```

These come from the sample data and are for local testing only.

---

## Starting it again tomorrow

You do not need to repeat the database or install steps. Open two terminals:

**Terminal 1 — server**

```bash
cd CScholar\backend
venv\Scripts\activate
python run.py
```

**Terminal 2 — app**

```bash
cd CScholar\frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

---

## If something goes wrong

### `psql is not recognized`

Windows did not add PostgreSQL to PATH. Either:

1. Use the full path:
   ```bash
   "C:\Program Files\PostgreSQL\18\bin\psql.exe" --version
   ```
2. Or add this folder to PATH permanently:
   `C:\Program Files\PostgreSQL\18\bin`
   (Start → search "environment variables" → Path → Edit → New).

### The server hangs or the database will not connect

The `.env` file still has the placeholder password, or PostgreSQL is not
running.

1. Open `backend/.env` and check that `DATABASE_URL` has your real password,
   not the word `YOUR_PASSWORD`.
2. On Windows, open **Services** (Start → type `services`) and make sure
   `postgresql-x64-18` says **Running**.
3. Restart the server: press `Ctrl+C` in the server window, then
   `python run.py` again.

### `relation "theses" does not exist`

The tables are there, but you typed a query without the `ceit_repo.` prefix.
Use `ceit_repo.theses` instead of `theses`. This does not affect the app.

### `CREATE EXTENSION vector` fails

The pgvector add-on is missing. Follow the pgvector part of
[`db/setup.md`](db/setup.md).

### Flutter says there are dependency conflicts

Delete the `frontend/.dart_tool` folder and run `flutter pub get` again.

**Never** run `flutter create` inside this project. It regenerates files and
causes conflicts with the shared code.

### The app opens but there is no data

The server is not running, or it is not on port 5000. Check
[http://localhost:5000/api/health](http://localhost:5000/api/health) in the
browser. If that fails, go back to Step 4.

### The first server start is very slow

The AI model downloads about 90 MB the first time. Later starts use the saved
copy and are much faster.

---

## Technical details (for developers)

<details>
<summary>Click to open</summary>

**Stack:** Flutter (web + mobile) → FastAPI/Python → PostgreSQL + pgvector →
Sentence Transformers `all-MiniLM-L6-v2` (384 dimensions).

**Folders**

```
backend/     FastAPI app, routes, services, tests
frontend/    Flutter app (web + mobile, one codebase)
db/          schema.sql, seed.sql, setup.md, Lab 5 logic
docs/        ERD, normalization, data dictionary, traceability
```

**Useful URLs while the server runs**

- Health: `http://localhost:5000/api/health`
- Database check: `http://localhost:5000/api/db-test`
- API docs: `http://localhost:5000/docs`

**The documented API is locked**

The Swagger UI at `/docs` is final: its 61 operations are listed in
[`backend/api_contract.json`](backend/api_contract.json) and no endpoint may be
added. The server refuses to start if a route is added, removed, re-tagged, or
has its allowed roles changed. Check it offline (no server needed) with:

```bash
cd backend
venv\Scripts\python scripts\check_api_contract.py
```

**Environment variables** (`backend/.env`)

| Key | Meaning |
|---|---|
| `SECRET_KEY` | Signs login tokens; change for production |
| `DEBUG` | `1` for development |
| `DATABASE_URL` | PostgreSQL connection string (required) |
| `EMBEDDING_MODEL` / `EMBEDDING_DIM` | Must match `db/schema.sql` (384) |
| `CORS_ORIGINS` | Optional comma-separated allowed browser origins |

**Docker instead of a local PostgreSQL**

`docker-compose.yml` starts PostgreSQL 17 with pgvector and applies schema,
seed, and logic automatically:

```bash
docker compose up -d
```

If port 5432 is already used by a local PostgreSQL, change the compose port to
`"5433:5432"` and use 5433 in `DATABASE_URL`.

**Tests**

```bash
cd frontend
flutter test
```

**Schema note:** all objects are created in the `ceit_repo` schema. Manual
queries need `ceit_repo.` prefixes or `SET search_path TO ceit_repo;`.

**⚠️ The database schema is locked.** `db/schema.sql` is the complete, frozen
set of tables. Do not add, alter, or drop tables/columns, and do not create
migrations — this applies to AI agents as well. Use the existing tables, keep
new state on the client, or ask the project owner before changing DDL. See the
“Schema is locked — do not add tables” section in [`db/README.md`](db/README.md).

**More docs**

| File | Contents |
|---|---|
| `docs/ERD.md` | Entity-relationship diagram |
| `docs/normalization.md` | Normalization notes |
| `docs/data_dictionary.md` | Column-level reference |
| `docs/requirements_traceability.md` | Requirements → tables |
| `docs/pdf_token_check.md` | Why PDF opens in a new tab with `?token=` |
| `db/logic/README.md` | Views, functions, procedure, triggers |

</details>
