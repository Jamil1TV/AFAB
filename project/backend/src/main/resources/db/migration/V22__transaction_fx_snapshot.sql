-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V19: Transaction Multi-Currency & Immutable FX Snapshots
-- ═══════════════════════════════════════════════════════════════════
-- Legacy Migration Policy:
--   Existing transactions do NOT have trustworthy original-currency provenance.
--   We NEVER fabricate historical exchange rates using today's rates.
--   All existing monetary amounts are preserved verbatim:
--     - base_currency      = existing currency
--     - converted_amount   = existing amount
--     - original_amount    = existing amount
--     - original_currency  = NULL (explicitly unknown provenance)
--     - exchange_rate      = NULL
--     - fx_rate_source     = 'LEGACY_UNKNOWN'
--     - fx_rate_timestamp  = NULL
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE transactions
    ADD COLUMN IF NOT EXISTS original_amount   NUMERIC(19, 4),
    ADD COLUMN IF NOT EXISTS original_currency VARCHAR(3),
    ADD COLUMN IF NOT EXISTS base_currency     VARCHAR(3),
    ADD COLUMN IF NOT EXISTS exchange_rate     NUMERIC(19, 6),
    ADD COLUMN IF NOT EXISTS converted_amount  NUMERIC(19, 4),
    ADD COLUMN IF NOT EXISTS fx_rate_source    VARCHAR(50) NOT NULL DEFAULT 'LEGACY_UNKNOWN',
    ADD COLUMN IF NOT EXISTS fx_rate_timestamp TIMESTAMPTZ;

-- Preserve all legacy transactions honestly without fabricating FX rates
UPDATE transactions
SET
    base_currency    = COALESCE(base_currency, currency, 'USD'),
    converted_amount = COALESCE(converted_amount, amount),
    original_amount  = COALESCE(original_amount, amount),
    fx_rate_source   = CASE
                           WHEN fx_rate_source IS NULL OR fx_rate_source = '' THEN 'LEGACY_UNKNOWN'
                           ELSE fx_rate_source
                       END
WHERE base_currency IS NULL OR converted_amount IS NULL OR original_amount IS NULL;

ALTER TABLE transactions
    ALTER COLUMN base_currency SET NOT NULL,
    ALTER COLUMN converted_amount SET NOT NULL,
    ALTER COLUMN original_amount SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_business_base_currency
    ON transactions (business_id, base_currency)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_fx_source
    ON transactions (fx_rate_source);
