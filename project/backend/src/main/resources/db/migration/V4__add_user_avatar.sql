-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V4: Add user avatar URL
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500);
