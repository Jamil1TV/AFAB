-- ═══════════════════════════════════════════════════════
-- V9: Add updated_at to categories
-- ═══════════════════════════════════════════════════════

ALTER TABLE categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;
