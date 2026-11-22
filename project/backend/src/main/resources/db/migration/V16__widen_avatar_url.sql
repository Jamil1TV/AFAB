-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V16: Allow uploaded data-URI profile avatars
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE users ALTER COLUMN avatar_url TYPE TEXT;
