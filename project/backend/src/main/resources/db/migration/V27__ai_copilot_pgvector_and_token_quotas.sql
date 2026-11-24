-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V27: AFAB Copilot Hybrid RAG (pgvector) & AI Token Quotas
-- ═══════════════════════════════════════════════════════════════════

-- 1. Enable pgvector extension for 768-dimensional EmbeddingGemma 2 vectors
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Seed per-plan monthly AI token quotas alongside existing ai.chat.queries_per_month
--    Free: 15,000 tokens/month | Plus: 150,000 tokens/month | Pro: 500,000 tokens/month
INSERT INTO plan_entitlements (plan_id, feature_key, type, value) VALUES
    ('11111111-1111-1111-1111-111111111111', 'ai.chat.tokens_per_month', 'QUOTA', '15000'),
    ('22222222-2222-2222-2222-222222222222', 'ai.chat.tokens_per_month', 'QUOTA', '150000'),
    ('33333333-3333-3333-3333-333333333333', 'ai.chat.tokens_per_month', 'QUOTA', '500000')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

-- 3. Tenant-isolated AI Copilot conversations
CREATE TABLE IF NOT EXISTS ai_conversations (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID         NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    title       VARCHAR(200) NOT NULL,
    locale      VARCHAR(16)  NOT NULL DEFAULT 'en',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    archived_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_ai_conversations_biz_user_updated
    ON ai_conversations (business_id, user_id, updated_at DESC);

-- 4. Copilot conversation messages with evidence, data-coverage flags & exact token telemetry
CREATE TABLE IF NOT EXISTS ai_messages (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id   UUID        NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    business_id       UUID        NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    role              VARCHAR(20) NOT NULL,
    content           TEXT        NOT NULL,
    evidence_json     TEXT,
    tools_used_json   TEXT,
    data_coverage     VARCHAR(50),
    model_id          VARCHAR(120),
    prompt_version    VARCHAR(60),
    prompt_tokens     INTEGER     NOT NULL DEFAULT 0,
    completion_tokens INTEGER     NOT NULL DEFAULT 0,
    total_tokens      INTEGER     NOT NULL DEFAULT 0,
    latency_ms        BIGINT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_messages_conv_created
    ON ai_messages (conversation_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_ai_messages_biz_created
    ON ai_messages (business_id, created_at DESC);

-- 5. Approved durable Business Memory with lifecycle, provenance & 768-dim pgvector index
CREATE TABLE IF NOT EXISTS business_memory (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID         NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    memory_type  VARCHAR(50)  NOT NULL,
    title        VARCHAR(160) NOT NULL,
    content      TEXT         NOT NULL,
    content_hash VARCHAR(64)  NOT NULL,
    source_type  VARCHAR(40)  NOT NULL DEFAULT 'USER_NOTE',
    source_id    UUID,
    status       VARCHAR(20)  NOT NULL DEFAULT 'APPROVED',
    visibility   VARCHAR(20)  NOT NULL DEFAULT 'BUSINESS',
    embedding    vector(768),
    model_id     VARCHAR(120),
    dimension    INTEGER,
    created_by   UUID         REFERENCES users(id) ON DELETE SET NULL,
    approved_by  UUID         REFERENCES users(id) ON DELETE SET NULL,
    expires_at   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_business_memory_biz_status
    ON business_memory (business_id, status);

CREATE INDEX IF NOT EXISTS idx_business_memory_embedding
    ON business_memory USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_business_memory_fts
    ON business_memory USING gin (to_tsvector('simple', coalesce(title, '') || ' ' || content));

-- 6. Tenant-isolated semantic RAG chunks for transactions, invoices, customers, budgets & recurring rules
CREATE TABLE IF NOT EXISTS ai_rag_chunks (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID         NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    source_type  VARCHAR(40)  NOT NULL,
    source_id    UUID         NOT NULL,
    title        VARCHAR(200) NOT NULL,
    content      TEXT         NOT NULL,
    content_hash VARCHAR(64)  NOT NULL,
    embedding    vector(768),
    model_id     VARCHAR(120),
    dimension    INTEGER,
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ai_rag_chunk_source UNIQUE (business_id, source_type, source_id)
);

CREATE INDEX IF NOT EXISTS idx_ai_rag_chunks_biz_type
    ON ai_rag_chunks (business_id, source_type);

CREATE INDEX IF NOT EXISTS idx_ai_rag_chunks_embedding
    ON ai_rag_chunks USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_ai_rag_chunks_fts
    ON ai_rag_chunks USING gin (to_tsvector('simple', coalesce(title, '') || ' ' || content));

-- 7. Tool execution audit log (hashes arguments, never stores prompts or secrets)
CREATE TABLE IF NOT EXISTS ai_tool_audit (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id     UUID        NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    conversation_id UUID,
    tool_name       VARCHAR(80) NOT NULL,
    arguments_hash  VARCHAR(64) NOT NULL,
    result_status   VARCHAR(40) NOT NULL,
    approval_status VARCHAR(30) NOT NULL DEFAULT 'AUTO_READ_ONLY',
    duration_ms     BIGINT      NOT NULL DEFAULT 0,
    executed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_tool_audit_biz_executed
    ON ai_tool_audit (business_id, executed_at DESC);
