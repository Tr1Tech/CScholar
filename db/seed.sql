-- =============================================================
-- CScholar — Phase 2: Mock seed data (SAMPLE ONLY, not real CSU)
-- =============================================================
-- Run AFTER schema.sql:
--   psql -U postgres -d cscholar -f seed.sql
-- All data here is FICTIONAL and for development/demo only.
-- =============================================================

-- Use the same schema as schema.sql
SET search_path TO ceit_repo;

-- ---- Academic year (limited scope) ----
INSERT INTO academic_years (name, start_year, end_year, is_active)
VALUES ('2025-2026', 2025, 2026, TRUE);

-- ---- CEIT programs (departments) ----
INSERT INTO programs (name, code, description) VALUES
    ('BS Information Technology', 'BSIT', 'Bachelor of Science in Information Technology'),
    ('BS Computer Science', 'BSCS', 'Bachelor of Science in Computer Science'),
    ('BS Information Systems', 'BSIS', 'Bachelor of Science in Information Systems');

-- ---- Sample users (passwords are placeholders; hash in Phase 4) ----
INSERT INTO users (username, email, password_hash, role, is_active) VALUES
    ('admin.ceit', 'admin@ceit.csu.edu.ph', 'PLACEHOLDER_HASH', 'admin', TRUE),
    ('jdelarmente', 'radj.delarmente@csu.edu.ph', 'PLACEHOLDER_HASH', 'student', TRUE),
    ('prof.reyes', 'm.reyes@ceit.csu.edu.ph', 'PLACEHOLDER_HASH', 'faculty', TRUE);

-- ---- Categories ----
INSERT INTO categories (name, description) VALUES
    ('Machine Learning', 'ML and predictive modeling'),
    ('Web Development', 'Web applications and services'),
    ('Mobile Development', 'Mobile applications'),
    ('Data Analytics', 'Data analysis and visualization');

-- ---- Keywords ----
INSERT INTO keywords (term) VALUES
    ('student dropout'), ('prediction'), ('academic performance'),
    ('recommendation system'), ('semantic search'), ('flutter');

-- ---- Authors ----
INSERT INTO authors (first_name, last_name, email) VALUES
    ('Maria', 'Santos', 'maria.santos@student.csu.edu.ph'),
    ('John', 'Cruz', 'john.cruz@student.csu.edu.ph'),
    ('Anna', 'Lopez', 'anna.lopez@student.csu.edu.ph');

-- ---- Advisers ----
INSERT INTO advisers (first_name, last_name, email) VALUES
    ('Manuel', 'Reyes', 'm.reyes@ceit.csu.edu.ph'),
    ('Elena', 'Garcia', 'e.garcia@ceit.csu.edu.ph');

-- ---- Theses (FICTIONAL) ----
INSERT INTO theses (title, abstract, research_type, program_id, academic_year_id, status, creator_id) VALUES
    ('Student Academic Performance Risk Prediction Using Machine Learning',
     'This study predicts students at risk of poor academic performance using historical grades and engagement data. A gradient boosting model is trained and evaluated.',
     'Capstone', 1, 1, 'published', 2),
    ('Semantic Search System for CEIT Thesis Repository',
     'This project builds a semantic search engine for CEIT theses using sentence embeddings and vector similarity, improving discovery over keyword search.',
     'Thesis', 1, 1, 'published', 2),
    ('Flutter-Based Mobile Attendance Tracker for CEIT Classes',
     'A cross-platform mobile app for classroom attendance using Flutter and QR codes, with offline sync and reporting.',
     'Capstone', 1, 1, 'approved', 2);

-- ---- Thesis <-> Authors ----
INSERT INTO thesis_authors (thesis_id, author_id, order_index) VALUES
    (1, 1, 1), (1, 2, 2),
    (2, 2, 1), (2, 3, 2),
    (3, 3, 1);

-- ---- Thesis <-> Advisers ----
INSERT INTO thesis_advisers (thesis_id, adviser_id) VALUES
    (1, 1), (2, 1), (3, 2);

-- ---- Thesis <-> Categories ----
INSERT INTO thesis_categories (thesis_id, category_id) VALUES
    (1, 1), (1, 4), (2, 1), (2, 2), (3, 3);

-- ---- Thesis <-> Keywords ----
INSERT INTO thesis_keywords (thesis_id, keyword_id) VALUES
    (1, 1), (1, 2), (1, 3),
    (2, 4), (2, 5), (2, 6),
    (3, 6);
