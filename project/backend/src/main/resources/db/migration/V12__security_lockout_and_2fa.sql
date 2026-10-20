-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V12: Security Enhancements — Account Lockout & 2FA Backup Codes
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS lockout_until TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS two_factor_backup_codes TEXT;

ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS ip_address VARCHAR(45);
