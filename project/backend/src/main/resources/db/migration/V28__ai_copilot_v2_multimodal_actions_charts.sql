-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V28: AFAB Copilot v2 (Language Continuity, Deep Mode,
--        Multimodal File/Image Staging, Interactive Charts & Action Drafts)
-- ═══════════════════════════════════════════════════════════════════

-- 1. Sticky per-conversation detected language (EN | FR | AR_MSA | AR_DERJA_SCRIPT | AR_DERJA_ARABIZI)
ALTER TABLE ai_conversations
    ADD COLUMN IF NOT EXISTS active_language VARCHAR(24) NOT NULL DEFAULT 'EN';

-- 2. Rich structured payloads on assistant messages (thinking trace, interactive charts, action drafts, attachments)
ALTER TABLE ai_messages
    ADD COLUMN IF NOT EXISTS thinking_content   TEXT,
    ADD COLUMN IF NOT EXISTS charts_json        TEXT,
    ADD COLUMN IF NOT EXISTS action_drafts_json TEXT,
    ADD COLUMN IF NOT EXISTS attachments_json   TEXT,
    ADD COLUMN IF NOT EXISTS reasoning_mode     VARCHAR(16) NOT NULL DEFAULT 'fast',
    ADD COLUMN IF NOT EXISTS response_language  VARCHAR(24);

-- 3. Temporary tenant-isolated MinIO staging table for multimodal receipt/invoice photos & documents
CREATE TABLE IF NOT EXISTS ai_staged_attachments (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id         UUID         NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    user_id             UUID         NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    kind                VARCHAR(16)  NOT NULL DEFAULT 'IMAGE',
    object_key          VARCHAR(512) NOT NULL UNIQUE,
    original_filename   VARCHAR(255) NOT NULL,
    content_type        VARCHAR(100) NOT NULL,
    file_size_bytes     BIGINT       NOT NULL,
    sha256_checksum     VARCHAR(64)  NOT NULL,
    extracted_text      TEXT,
    status              VARCHAR(24)  NOT NULL DEFAULT 'STAGED', -- STAGED | PROMOTED | EXPIRED
    promoted_receipt_id UUID,
    expires_at          TIMESTAMPTZ  NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_staged_attachments_biz_status
    ON ai_staged_attachments (business_id, status, expires_at);

-- 4. Plan entitlement gate for Deep Reasoning Mode (Free: false, Plus/Pro: true)
INSERT INTO plan_entitlements (plan_id, feature_key, type, value) VALUES
    ('11111111-1111-1111-1111-111111111111', 'ai.deep_reasoning', 'BOOLEAN', 'false'),
    ('22222222-2222-2222-2222-222222222222', 'ai.deep_reasoning', 'BOOLEAN', 'true'),
    ('33333333-3333-3333-3333-333333333333', 'ai.deep_reasoning', 'BOOLEAN', 'true')
ON CONFLICT (plan_id, feature_key) DO NOTHING;
