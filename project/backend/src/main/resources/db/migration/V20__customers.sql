-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V20: Real Business Customer Domain
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE customers (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id    UUID         NOT NULL,
    customer_code  VARCHAR(40)  NOT NULL,
    name           VARCHAR(255) NOT NULL,
    company_name   VARCHAR(255),
    email          CITEXT,
    phone          VARCHAR(50),
    customer_group VARCHAR(50)  NOT NULL DEFAULT 'Standard',
    status         VARCHAR(30)  NOT NULL DEFAULT 'Active',
    address        TEXT,
    notes          TEXT,
    archived_at    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ,

    CONSTRAINT fk_customers_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX uq_customers_business_code
    ON customers (business_id, LOWER(customer_code));

CREATE UNIQUE INDEX uq_customers_business_active_email
    ON customers (business_id, LOWER(email))
    WHERE email IS NOT NULL AND archived_at IS NULL;

CREATE INDEX idx_customers_business_active
    ON customers (business_id, created_at DESC)
    WHERE archived_at IS NULL;

CREATE INDEX idx_customers_business_status
    ON customers (business_id, status)
    WHERE archived_at IS NULL;
