-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V5: Extend Business Profile, User password tracking,
--                    and Refresh Token IP tracking
-- ═══════════════════════════════════════════════════════════════════

-- ── Extend businesses table ──────────────────────────
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS business_email VARCHAR(255);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS phone_number VARCHAR(50);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS website VARCHAR(255);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS tax_id VARCHAR(100);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS address_line TEXT;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS state VARCHAR(100);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS postal_code VARCHAR(20);
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS logo_url VARCHAR(500);

-- ── Extend users table ───────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ;

-- ── Extend refresh_tokens table ──────────────────────
ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS ip_address VARCHAR(45);
