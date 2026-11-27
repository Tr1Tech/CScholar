-- =============================================================
-- CScholar — apply the approved security audit table
-- =============================================================
-- Run once on an existing database that predates the table:
--
--   psql -U postgres -d cscholar -f db/security_audit_log.sql
--
-- Idempotent. `schema.sql` already contains the same definition for a
-- fresh install; this file only brings an existing database forward.
-- Append-only by convention: no UPDATE/DELETE path is provided.
-- =============================================================

SET search_path TO ceit_repo;

CREATE TABLE IF NOT EXISTS security_audit_log (
    id             BIGSERIAL PRIMARY KEY,
    actor_id       INTEGER REFERENCES users(id) ON DELETE SET NULL,
    actor_username VARCHAR(120),
    actor_role     VARCHAR(20),
    action         VARCHAR(50) NOT NULL,
    entity_type    VARCHAR(30),
    entity_id      INTEGER,
    summary        TEXT,
    details        JSONB,
    ip_address     VARCHAR(45),
    user_agent     VARCHAR(255),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_security_audit_created
    ON security_audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_audit_actor
    ON security_audit_log (actor_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_action
    ON security_audit_log (action, created_at DESC);
