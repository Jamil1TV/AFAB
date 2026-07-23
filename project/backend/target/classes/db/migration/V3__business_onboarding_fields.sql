-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V3: Add business onboarding fields
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE businesses ADD COLUMN IF NOT EXISTS industry VARCHAR(100);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS business_type VARCHAR(50);
