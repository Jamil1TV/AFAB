-- ═══════════════════════════════════════════════════════
-- V8: Password Reset Tokens (URL-based token flow)
-- ═══════════════════════════════════════════════════════
-- Stores hashed password reset tokens for the link-based
-- forgot-password flow. Tokens are SHA-256 hashed, expire
-- after 15 minutes, and are single-use.
-- ═══════════════════════════════════════════════════════

CREATE TABLE password_reset_tokens (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(128)    NOT NULL,
    expires_at  TIMESTAMPTZ     NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),
    used_at     TIMESTAMPTZ
);

-- Index for fast token lookup during validation
CREATE INDEX idx_prt_token_hash ON password_reset_tokens(token_hash);

-- Index for fast invalidation of all tokens for a user
CREATE INDEX idx_prt_user_id ON password_reset_tokens(user_id);
