-- =============================================================
-- CScholar — bootstrap reference data
-- =============================================================
-- Run after schema.sql, before the first admin account and
-- before any thesis import:
--
--   psql -U postgres -d cscholar -f db/bootstrap.sql
--   cd backend && venv\Scripts\python scripts\bootstrap_admin.py
--
-- Idempotent: safe to re-run. Existing rows are left untouched.
--
-- Theses require a program and an academic year (NOT NULL FKs), so
-- these two tables must exist before anything can be created. They
-- are real reference data, not mock data: do not delete them when
-- clearing sample theses.
--
-- EDIT THE PROGRAMS BELOW to match the CEIT program list confirmed
-- with the college before the real import.
-- =============================================================

SET search_path TO ceit_repo;

-- ---- Programs (CEIT) ----------------------------------------
-- Confirmed list: BSIT, BSEE, BSCpE.
INSERT INTO programs (name, code, description) VALUES
    ('Bachelor of Science in Information Technology',  'BSIT',  'BS Information Technology'),
    ('Bachelor of Science in Electrical Engineering',  'BSEE',  'BS Electrical Engineering'),
    ('Bachelor of Science in Computer Engineering',    'BSCpE', 'BS Computer Engineering')
ON CONFLICT (code) DO UPDATE
    SET name = EXCLUDED.name,
        description = EXCLUDED.description;

-- ---- Academic years -----------------------------------------
-- Covers the five years targeted by the first import wave.
-- Only the current year is flagged active.
INSERT INTO academic_years (name, start_year, end_year, is_active) VALUES
    ('2021-2022', 2021, 2022, FALSE),
    ('2022-2023', 2022, 2023, FALSE),
    ('2023-2024', 2023, 2024, FALSE),
    ('2024-2025', 2024, 2025, FALSE),
    ('2025-2026', 2025, 2026, TRUE)
ON CONFLICT (name) DO NOTHING;

-- ---- Verify --------------------------------------------------
-- Expect: three programs and five academic years.
SELECT 'programs' AS table_name, count(*) FROM programs
UNION ALL
SELECT 'academic_years', count(*) FROM academic_years;
