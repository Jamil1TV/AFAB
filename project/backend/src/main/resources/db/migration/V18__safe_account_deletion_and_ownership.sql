-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V18: Safe Account Deletion & Business Ownership Integrity
-- ═══════════════════════════════════════════════════════════════════

-- 1. Replace ON DELETE CASCADE on businesses(user_id) with ON DELETE RESTRICT
--    so ordinary user deletion can NEVER silently destroy a business's financial ledger.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'businesses'::regclass
          AND conname = 'fk_businesses_user'
    ) THEN
        ALTER TABLE businesses DROP CONSTRAINT fk_businesses_user;
    END IF;
END $$;

ALTER TABLE businesses
    ADD CONSTRAINT fk_businesses_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT;

-- 2. Index users(deleted_at) for fast active-account queries
CREATE INDEX IF NOT EXISTS idx_users_deleted_at ON users (deleted_at) WHERE deleted_at IS NULL;

-- 3. Index businesses(archived_at) for active vs archived queries
CREATE INDEX IF NOT EXISTS idx_businesses_archived_at ON businesses (archived_at) WHERE archived_at IS NULL;
