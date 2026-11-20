-- =============================================================
-- CScholar — one-time cleanup of demo data
-- =============================================================
-- Removes the fictional/test theses created during development and the
-- leftover BSCE program code (which duplicates the real BSCpE).
--
-- Run ONCE, before entering the first real thesis:
--
--   psql -U postgres -d cscholar -f db/clear_mock_data.sql
--
-- It guards on the thesis count: if the database does not hold exactly the 12
-- demo rows, it refuses to run. That way it cannot silently wipe a database
-- that already contains real records.
--
-- Related rows (authors, embeddings, PDF links, junctions) cascade with the
-- theses. Reference data (programs, academic years) is kept.
-- =============================================================

SET search_path TO ceit_repo;

-- ---- Guard ---------------------------------------------------
DO $$
DECLARE
    n integer;
BEGIN
    SELECT count(*) INTO n FROM theses;
    IF n <> 12 THEN
        RAISE EXCEPTION
            'Expected the 12 demo theses, found %. Refusing to delete; inspect first.', n;
    END IF;
END $$;

BEGIN;

-- 1. Demo/test theses (titles include "Demo Thesis", "TEST", "TEST2", "TEST PDF").
DELETE FROM theses
WHERE id IN (1, 2, 3, 4, 15, 19, 20, 32, 36, 37, 38, 40);

-- 2. Orphaned metadata left behind by the deleted theses.
DELETE FROM authors
WHERE NOT EXISTS (SELECT 1 FROM thesis_authors ta WHERE ta.author_id = authors.id);
DELETE FROM advisers
WHERE NOT EXISTS (SELECT 1 FROM thesis_advisers ta WHERE ta.adviser_id = advisers.id);
DELETE FROM keywords
WHERE NOT EXISTS (SELECT 1 FROM thesis_keywords tk WHERE tk.keyword_id = keywords.id);
DELETE FROM categories
WHERE NOT EXISTS (SELECT 1 FROM thesis_categories tc WHERE tc.category_id = categories.id);

-- 3. Duplicate program code (BSCE is civil engineering, not computer engineering).
DELETE FROM programs WHERE code = 'BSCE';

COMMIT;

-- ---- Verify --------------------------------------------------
SELECT 'theses' AS table_name, count(*) FROM theses
UNION ALL SELECT 'authors', count(*) FROM authors
UNION ALL SELECT 'advisers', count(*) FROM advisers
UNION ALL SELECT 'embeddings', count(*) FROM thesis_embeddings
UNION ALL SELECT 'programs', count(*) FROM programs;

SELECT code, name FROM programs ORDER BY code;
