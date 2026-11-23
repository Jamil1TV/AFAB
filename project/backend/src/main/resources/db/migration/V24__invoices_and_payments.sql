-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V21: Real Invoice Lifecycle, Numbering & Payments
-- ═══════════════════════════════════════════════════════════════════

-- 1. Concurrency-safe per-business sequential invoice numbering
CREATE TABLE invoice_sequences (
    business_id UUID    NOT NULL,
    year        INTEGER NOT NULL,
    last_number BIGINT  NOT NULL DEFAULT 0,

    PRIMARY KEY (business_id, year),
    CONSTRAINT fk_invoice_sequences_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT
);

-- 2. Invoices (separate from Income Transactions!)
CREATE TABLE invoices (
    id                  UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id         UUID           NOT NULL,
    customer_id         UUID,
    invoice_number      VARCHAR(50)    NOT NULL,
    status              VARCHAR(30)    NOT NULL DEFAULT 'DRAFT',
    issue_date          DATE           NOT NULL,
    due_date            DATE           NOT NULL,
    currency            VARCHAR(3)     NOT NULL,
    subtotal            NUMERIC(19, 4) NOT NULL DEFAULT 0,
    discount_amount     NUMERIC(19, 4) NOT NULL DEFAULT 0,
    tax_amount          NUMERIC(19, 4) NOT NULL DEFAULT 0,
    total_amount        NUMERIC(19, 4) NOT NULL DEFAULT 0,
    paid_amount         NUMERIC(19, 4) NOT NULL DEFAULT 0,
    outstanding_balance NUMERIC(19, 4) NOT NULL DEFAULT 0,
    notes               TEXT,
    issued_at           TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    version             BIGINT         NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ,

    CONSTRAINT fk_invoices_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT,
    CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL,
    CONSTRAINT uq_invoices_business_number UNIQUE (business_id, invoice_number),
    CONSTRAINT chk_invoices_amounts CHECK (
        subtotal >= 0 AND discount_amount >= 0 AND tax_amount >= 0
        AND total_amount >= 0 AND paid_amount >= 0 AND outstanding_balance >= 0
    )
);

CREATE INDEX idx_invoices_business_status ON invoices (business_id, status);
CREATE INDEX idx_invoices_business_customer ON invoices (business_id, customer_id);
CREATE INDEX idx_invoices_business_due_date ON invoices (business_id, due_date);

-- 3. Invoice Line Items
CREATE TABLE invoice_items (
    id            UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id    UUID           NOT NULL,
    description   VARCHAR(255)   NOT NULL,
    quantity      NUMERIC(19, 4) NOT NULL DEFAULT 1,
    unit_price    NUMERIC(19, 4) NOT NULL,
    tax_rate      NUMERIC(5, 2)  NOT NULL DEFAULT 0,
    line_subtotal NUMERIC(19, 4) NOT NULL,
    line_tax      NUMERIC(19, 4) NOT NULL,
    line_total    NUMERIC(19, 4) NOT NULL,
    sort_order    INTEGER        NOT NULL DEFAULT 0,

    CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
    CONSTRAINT chk_invoice_items_positive CHECK (quantity > 0 AND unit_price >= 0 AND tax_rate >= 0)
);

CREATE INDEX idx_invoice_items_invoice ON invoice_items (invoice_id);

-- 4. Payments (1:1 linked to recorded Income Transaction + idempotent per invoice)
CREATE TABLE payments (
    id                    UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id           UUID           NOT NULL,
    invoice_id            UUID           NOT NULL,
    income_transaction_id UUID           NOT NULL UNIQUE,
    idempotency_key       VARCHAR(128)   NOT NULL,
    amount                NUMERIC(19, 4) NOT NULL,
    currency              VARCHAR(3)     NOT NULL,
    payment_date          DATE           NOT NULL,
    payment_method        VARCHAR(50)    NOT NULL DEFAULT 'BANK_TRANSFER',
    reference             VARCHAR(255),
    notes                 TEXT,
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_payments_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT,
    CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE RESTRICT,
    CONSTRAINT fk_payments_transaction FOREIGN KEY (income_transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT,
    CONSTRAINT uq_payments_idempotency UNIQUE (business_id, invoice_id, idempotency_key),
    CONSTRAINT chk_payments_positive CHECK (amount > 0)
);

CREATE INDEX idx_payments_business_invoice ON payments (business_id, invoice_id);
CREATE INDEX idx_payments_date ON payments (business_id, payment_date DESC);
