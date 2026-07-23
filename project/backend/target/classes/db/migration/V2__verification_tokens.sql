-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V2: Verification Tokens (Email, Phone, Password Reset)
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE verification_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID         NOT NULL,
    token       VARCHAR(255) NOT NULL,
    token_type  VARCHAR(50)  NOT NULL,  -- EMAIL_VERIFICATION, PHONE_VERIFICATION, PASSWORD_RESET
    expires_at  TIMESTAMPTZ  NOT NULL,
    used_at     TIMESTAMPTZ,            -- When the token was consumed (NULL = unused)
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_verification_tokens_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Index for fast lookups by user + type (e.g., find active email verification token)
CREATE INDEX idx_verification_tokens_user_type ON verification_tokens (user_id, token_type);

-- Index for fast token lookup (when verifying via link)
CREATE INDEX idx_verification_tokens_token ON verification_tokens (token);
