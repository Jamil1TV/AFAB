-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway Migration V2
-- Adds the businesses table
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE businesses (
    id                      BIGSERIAL       PRIMARY KEY,
    user_id                 BIGINT          NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    name                    VARCHAR(255)    NOT NULL,
    currency                VARCHAR(3)      NOT NULL,
    country                 VARCHAR(100),
    timezone                VARCHAR(50),
    fiscal_year_start_month INTEGER         NOT NULL DEFAULT 1,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ
);
