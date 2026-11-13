# Database setup, step by step

This guide sets up the database CScholar uses. Do it once. You do not need to
know SQL — you will copy and paste four commands.

There are two ways to do this:

- **Way A — you already installed PostgreSQL on this computer** (most common).
  Follow Part 1 and Part 2 below.
- **Way B — you prefer Docker.** Skip to [Way B](#way-b--docker-easier-if-you-already-use-docker).

---

## Before you start

You need:

1. **PostgreSQL 18 installed** (from Step 1 of the main README).
2. **The `postgres` password** you chose during that install.
3. A terminal window opened in the `CScholar` folder.

To check PostgreSQL is running on Windows: press Start, type `services`, press
Enter, and look for `postgresql-x64-18`. Its Status should say **Running**.

---

## Part 1 — Add the pgvector add-on

CScholar uses a PostgreSQL add-on called **pgvector** for the "search by
meaning" feature. Some installs already include it.

### Check whether you already have it

```bash
psql -U postgres -c "SELECT name FROM pg_available_extensions WHERE name = 'vector';"
```

- If you see one row containing `vector`, **you already have it. Go to Part 2.**
- If you see `0 rows`, install it with one of the options below.

### Install pgvector on Windows

The easiest route is Chocolatey. Open **PowerShell as Administrator**
(Start → type `PowerShell` → right-click → Run as administrator) and run:

```powershell
choco install pgvector
```

If you do not have Chocolatey, install it first from https://chocolatey.org/install
and then run the command above.

If Chocolatey is not an option, follow the official Windows build steps:
https://github.com/pgvector/pgvector#windows

After installing, **restart the PostgreSQL service** (Services → right-click
`postgresql-x64-18` → Restart) and run the check command again.

---

## Part 2 — Create the database and tables

Make sure you are in the `CScholar` folder. Run these four commands **one at a
time**, pressing Enter after each.

### 2.1 Create the database

```bash
psql -U postgres -c "CREATE DATABASE cscholar;"
```

**You should see:** `CREATE DATABASE`

If it says `database "cscholar" already exists`, that is fine — continue.

### 2.2 Create the tables

```bash
psql -U postgres -d cscholar -f db/schema.sql
```

**You should see:** many `CREATE TABLE` lines and `CREATE INDEX` at the end.

### 2.3 Add sample data

```bash
psql -U postgres -d cscholar -f db/seed.sql
```

**You should see:** several `INSERT 0 ...` lines. It adds three sample theses
and a demo admin account.

### 2.4 Add views, functions, and triggers

```bash
psql -U postgres -d cscholar -f db/logic/cscholar_lab5_logic.sql
```

**You should see:** `CREATE VIEW`, `CREATE FUNCTION`, `CREATE TRIGGER`, and
notices ending with `does not exist, skipping`. Those notices are normal and
mean the script is safe to re-run.

> When a command asks for a password, type it and press Enter. Nothing appears
> on screen while you type — that is normal, not a frozen terminal.

---

## Check that it worked

```bash
psql -U postgres -d cscholar -c "SELECT COUNT(*) FROM ceit_repo.theses;"
```

**You should see:**

```
 count
-------
     3
```

> The `ceit_repo.` part matters. CScholar keeps its tables in a named section of
> the database, so hand-written queries need that prefix. The app handles it
> automatically.

You can also list the tables:

```bash
psql -U postgres -d cscholar -c "\dt ceit_repo.*"
```

If you run plain `\dt`, it will say "Did not find any tables". That is expected,
because the tables are in `ceit_repo`, not in the default section.

---

## Part 3 — Tell the server the password

Open `backend/.env` in Notepad and set the password you chose during the
PostgreSQL install:

```ini
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/cscholar
```

- User is usually `postgres`.
- Port is usually `5432`.
- Database name is `cscholar`.
- If the password contains `@`, `:` or `/`, encode it: `@` → `%40`,
  `:` → `%3A`, `/` → `%2F`.

Then start the server (main README, Step 4) and open
**http://localhost:5000/api/db-test**. It should say `"connection": "ok"`.

---

## If something goes wrong

| What you see | What it means | What to do |
|---|---|---|
| `psql is not recognized` | Terminal cannot find PostgreSQL | Add `C:\Program Files\PostgreSQL\18\bin` to PATH, or use the full path to `psql.exe` |
| `password authentication failed` | Wrong password in the command or in `.env` | Use the exact `postgres` password from the install |
| `database "cscholar" already exists` | You ran 2.1 twice | Nothing — continue with 2.2 |
| `permission denied to create extension "vector"` | Your user is not allowed | Run the command as the `postgres` superuser |
| `extension "vector" is not available` | pgvector is not installed | Redo Part 1, then restart PostgreSQL |
| `Did not find any tables` | You used plain `\dt` | Use `\dt ceit_repo.*` |
| `relation "theses" does not exist` | Missing schema prefix | Use `ceit_repo.theses` |

---

## Way B — Docker (easier if you already use Docker)

Use this only if you have **Docker Desktop** installed and running. It avoids
installing PostgreSQL and pgvector by hand.

From the `CScholar` folder:

```bash
docker compose up -d
```

This downloads a PostgreSQL image that already includes pgvector. It also
applies the tables, sample data, and logic automatically the first time.

Wait about 15 seconds, then check:

```bash
psql -h localhost -U postgres -d cscholar -c "SELECT COUNT(*) FROM ceit_repo.theses;"
```

Password: `postgres`.

Then in `backend/.env` use:

```ini
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/cscholar
```

**If Docker complains that port 5432 is already in use**, a local PostgreSQL is
already running. Either stop it, or open `docker-compose.yml`, change
`"5432:5432"` to `"5433:5432"`, run `docker compose up -d` again, and use `5433`
in `DATABASE_URL`.

To wipe the Docker database and start over:

```bash
docker compose down -v
docker compose up -d
```
