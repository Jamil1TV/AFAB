-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V22: Recurring Transactions & Private Receipt Storage
-- ═══════════════════════════════════════════════════════════════════

-- 1. Recurring Transaction Rules
CREATE TABLE recurring_transactions (
    id                  UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id         UUID           NOT NULL,
    type                VARCHAR(20)    NOT NULL, -- 'INCOME', 'EXPENSE'
    description         VARCHAR(255)   NOT NULL,
    amount              NUMERIC(19, 4) NOT NULL,
    currency            VARCHAR(3)     NOT NULL,
    category_id         UUID,
    payment_method      VARCHAR(50)    NOT NULL DEFAULT 'BANK_TRANSFER',
    frequency           VARCHAR(20)    NOT NULL, -- 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY'
    start_date          DATE           NOT NULL,
    end_date            DATE,
    next_execution_date DATE           NOT NULL,
    active              BOOLEAN        NOT NULL DEFAULT TRUE,
    notes               TEXT,
    last_executed_at    TIMESTAMPTZ,
    version             BIGINT         NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ,

    CONSTRAINT fk_recurring_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT,
    CONSTRAINT fk_recurring_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
    CONSTRAINT chk_recurring_amount CHECK (amount > 0)
);

CREATE INDEX idx_recurring_business ON recurring_transactions (business_id);
CREATE INDEX idx_recurring_due ON recurring_transactions (active, next_execution_date) WHERE active = TRUE;

-- 2. Recurring Transaction Executions (Idempotency ledger preventing duplicate occurrences)
CREATE TABLE recurring_transaction_executions (
    id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id              UUID        NOT NULL,
    recurring_transaction_id UUID        NOT NULL,
    scheduled_date           DATE        NOT NULL,
    transaction_id           UUID        NOT NULL UNIQUE,
    executed_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_rec_exec_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT,
    CONSTRAINT fk_rec_exec_rule FOREIGN KEY (recurring_transaction_id) REFERENCES recurring_transactions (id) ON DELETE RESTRICT,
    CONSTRAINT fk_rec_exec_tx FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT,
    CONSTRAINT uq_recurring_execution_occurrence UNIQUE (recurring_transaction_id, scheduled_date)
);

CREATE INDEX idx_rec_exec_business ON recurring_transaction_executions (business_id);

-- 3. Private Receipt Storage Metadata (MinIO / S3 private object store)
CREATE TABLE receipts (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id         UUID         NOT NULL,
    transaction_id      UUID         NOT NULL,
    uploaded_by_user_id UUID         NOT NULL,
    object_key          VARCHAR(512) NOT NULL UNIQUE,
    original_filename   VARCHAR(255) NOT NULL,
    content_type        VARCHAR(100) NOT NULL,
    file_size_bytes     BIGINT       NOT NULL,
    sha256_checksum     VARCHAR(64)  NOT NULL,
    deleted_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_receipts_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT,
    CONSTRAINT fk_receipts_transaction FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT,
    CONSTRAINT fk_receipts_user FOREIGN KEY (uploaded_by_user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT chk_receipts_size CHECK (file_size_bytes > 0)
);

CREATE INDEX idx_receipts_business_tx ON receipts (business_id, transaction_id) WHERE deleted_at IS NULL;
