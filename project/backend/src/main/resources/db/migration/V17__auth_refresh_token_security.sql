-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V17: Refresh Token Security Hardening (Hashing & Families)
-- ═══════════════════════════════════════════════════════════════════

-- 1. Add token_family_id and remember_me columns for refresh token rotation & reuse detection
ALTER TABLE refresh_tokens
    ADD COLUMN IF NOT EXISTS token_family_id UUID,
    ADD COLUMN IF NOT EXISTS remember_me BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Backfill token_family_id for any existing rows
UPDATE refresh_tokens
SET token_family_id = gen_random_uuid()
WHERE token_family_id IS NULL;

ALTER TABLE refresh_tokens
    ALTER COLUMN token_family_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_family ON refresh_tokens (token_family_id);

-- 3. Hash any legacy plaintext UUID tokens in-place using SHA-256 (pgcrypto installed in V1).
--    SHA-256 hex strings are 64 lowercase hex chars; legacy UUIDs are 36 chars with hyphens.
UPDATE refresh_tokens
SET token_hash = encode(digest(token_hash, 'sha256'), 'hex')
WHERE length(token_hash) <> 64 OR token_hash !~ '^[0-9a-f]{64}$';
