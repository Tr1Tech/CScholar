# CScholar — Lab Activity 5: Database Logic Portfolio

Schema: `ceit_repo` (see `../schema.sql`). All objects below live in `ceit_repo`.

## Files

| File | Contents | Run order |
|---|---|---|
| `cscholar_lab5_logic.sql` | audit table + 2 views + materialized view + 2 functions + 1 procedure + 2 triggers (+1 helper `users.updated_at` trigger) | 3rd, after `schema.sql` then `seed.sql` |

## How to run (development database only)

```bash
createdb cscholar_dev
psql -U postgres -d cscholar_dev -f db/schema.sql
psql -U postgres -d cscholar_dev -f db/seed.sql
psql -U postgres -d cscholar_dev -f db/logic/cscholar_lab5_logic.sql
```

The logic script is idempotent (`OR REPLACE`, `IF NOT EXISTS`,
`DROP TRIGGER IF EXISTS`) so re-running it is safe.

## Object inventory

| # | Object | Type | Purpose |
|---|---|---|---|
| 1 | `v_published_thesis_listing` | view | browse/search list (Flutter + `GET /api/theses`) |
| 2 | `v_thesis_admin_overview` | view | admin completeness dashboard |
| 3 | `mv_thesis_counts_by_program_year` | materialized view | dashboard counts report |
| 4 | `fn_can_transition_status(text,text)` | function (scalar, IMMUTABLE) | lifecycle rule `draft→approved→published→archived`, archiving reversible (`archived→draft/published`) |
| 5 | `fn_get_thesis_full_info(bigint)` | function (set-returning, STABLE) | thesis detail page |
| 6 | `sp_submit_thesis_with_links(...)` | procedure | atomic thesis + authors + categories submit |
| 7 | `trg_theses_validate_status` (`tg_validate_thesis_status_transition`) | trigger BEFORE UPDATE | enforce lifecycle, maintain `updated_at` |
| 8 | `trg_theses_audit` (`tg_audit_thesis_change`) | trigger AFTER I/U/D | audit trail in `thesis_audit_log` |
| — | `thesis_audit_log` | table (new) | audit store; `thesis_id` has NO FK so DELETE audits survive |
| — | `trg_users_updated_at` | helper trigger | keep `users.updated_at` fresh (not counted in required 2) |

## Materialized-view refresh

```sql
-- Non-blocking (uses uq_mv_counts unique index):
REFRESH MATERIALIZED VIEW CONCURRENTLY ceit_repo.mv_thesis_counts_by_program_year;
-- Blocking fallback (no index needed):
REFRESH MATERIALIZED VIEW ceit_repo.mv_thesis_counts_by_program_year;
-- When: nightly cron + immediately after publish/archive workflow.
-- Staleness guard: show `SELECT * FROM pg_matviews WHERE matviewname='mv_thesis_counts_by_program_year'`
-- or add a refreshed_at timestamp in the API response; never use this MV for search results.
```

## Calling the procedure (example)

```sql
CALL ceit_repo.sp_submit_thesis_with_links(
  'AI Advising Chatbot for CEIT', 'Abstract text...', 'Capstone',
  1, 1, 2, ARRAY[1,2], ARRAY[1,2], NULL);
```

## Safety

Test triggers/procedures only on `cscholar_dev` or a dump copy.
Wrap early experiments in `BEGIN; ... ROLLBACK;`.
Never run destructive tests on a live/production database.
