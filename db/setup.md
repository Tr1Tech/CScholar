# Setting up PostgreSQL + pgvector for CScholar

You need a running PostgreSQL server with the **pgvector** extension.
Two options below. **pgAdmin is NOT required** (it is only a viewer).

---

## Option A — Local PostgreSQL (recommended for students)

1. Download & install PostgreSQL (includes `psql`):
   https://www.postgresql.org/download/windows/
   - Remember the `postgres` superuser password you set during install.
2. Install pgvector. Easiest on Windows: use the prebuilt PGXN / Chocolatey path,
   or build from source. A simple route:
   - Using Chocolatey (run as Admin):
     ```powershell
     choco install pgvector
     ```
   - Or follow the official pgvector Windows build steps:
     https://github.com/pgvector/pgvector#windows
3. Create the database and apply the schema:
   ```bash
   psql -U postgres -c "CREATE DATABASE cscholar;"
   psql -U postgres -d cscholar -f db/schema.sql
   psql -U postgres -d cscholar -f db/seed.sql
   ```
4. Verify:
   ```bash
   psql -U postgres -d cscholar -c "\dt"      # list tables
   psql -U postgres -d cscholar -c "SELECT COUNT(*) FROM theses;"   # should be 3
   ```

> If `CREATE EXTENSION vector` fails, pgvector is not installed in your
> Postgres `lib` directory. Re-check Option A step 2.

---

## Option B — Docker (one command, but Docker must be installed)

If you have Docker Desktop: create `docker-compose.yml` at repo root:

```yaml
services:
  db:
    image: pgvector/pgvector:pg17
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: cscholar
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
```

Then:
```bash
docker compose up -d
psql -h localhost -U postgres -d cscholar -f db/schema.sql
psql -h localhost -U postgres -d cscholar -f db/seed.sql
```

(The `pgvector/pgvector` image already includes the extension, so
`CREATE EXTENSION vector` works out of the box.)

---

## Updating backend/.env later (Phase 3)
```
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/cscholar
```
(Use your real username/password from the install above.)
