-- ==============================================================================
-- V11: Transaction Advanced Features - Tax Deductibility & Split Transactions
-- ==============================================================================

-- 1. Add tax-deductible flag and optional tax rate (VAT/Sales tax %)
ALTER TABLE transactions
    ADD COLUMN IF NOT EXISTS tax_deductible BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS tax_rate NUMERIC(5, 2);

-- 2. Add split transaction support (parent-child relationship)
ALTER TABLE transactions
    ADD COLUMN IF NOT EXISTS parent_transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS is_split BOOLEAN NOT NULL DEFAULT FALSE;

-- 3. Indexes for fast tax audits and split retrieval
CREATE INDEX IF NOT EXISTS idx_transactions_tax_deductible
    ON transactions (business_id, tax_deductible)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_parent_split
    ON transactions (parent_transaction_id)
    WHERE parent_transaction_id IS NOT NULL;
