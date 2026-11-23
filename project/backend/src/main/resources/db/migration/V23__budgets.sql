-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V23: Business Budgets
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE budgets (
    id                      UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id             UUID           NOT NULL,
    name                    VARCHAR(150)   NOT NULL,
    amount                  NUMERIC(19, 4) NOT NULL,
    currency                VARCHAR(3)     NOT NULL,
    category_id             UUID,
    period_type             VARCHAR(20)    NOT NULL DEFAULT 'MONTHLY', -- MONTHLY, QUARTERLY, YEARLY, CUSTOM
    start_date              DATE           NOT NULL,
    end_date                DATE           NOT NULL,
    alert_threshold_percent INTEGER        NOT NULL DEFAULT 80,
    description             TEXT,
    status                  VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE, ARCHIVED
    archived_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ,

    CONSTRAINT fk_budgets_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT,
    CONSTRAINT fk_budgets_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
    CONSTRAINT chk_budgets_amount CHECK (amount > 0),
    CONSTRAINT chk_budgets_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_budgets_threshold CHECK (alert_threshold_percent BETWEEN 1 AND 100)
);

CREATE INDEX idx_budgets_business_status ON budgets (business_id, status, start_date, end_date);
CREATE INDEX idx_budgets_business_category ON budgets (business_id, category_id);
