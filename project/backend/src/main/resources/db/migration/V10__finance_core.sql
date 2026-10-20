-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V10: Finance Core Hardening (Precision, Soft-Delete & Category Integrity)
-- ═══════════════════════════════════════════════════════════════════

-- 1. Upgrade monetary amount column to NUMERIC(19, 4) for high-precision / 3-decimal currencies (TND, KWD, BHD, OMR)
ALTER TABLE transactions ALTER COLUMN amount TYPE NUMERIC(19, 4);

-- 2. Add soft-delete column to transactions (Decision D6)
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_transactions_deleted_at ON transactions (deleted_at);

-- 3. Add unique constraint on custom categories per business, name, and type
-- Prevents duplicate custom category names for the same business
CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_business_name_type 
ON categories (business_id, LOWER(name), type) 
WHERE business_id IS NOT NULL;

-- 4. Index for filtering non-deleted transactions by business and date
CREATE INDEX IF NOT EXISTS idx_transactions_business_active_date 
ON transactions (business_id, transaction_date DESC) 
WHERE deleted_at IS NULL;
