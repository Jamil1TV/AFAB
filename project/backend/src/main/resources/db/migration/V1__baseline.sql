-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway Baseline Migration V1
-- Database: PostgreSQL 18
-- Conventions: numeric(14,2) for money, timestamptz everywhere,
--              citext for case-insensitive email
-- ═══════════════════════════════════════════════════════════════════

-- Enable citext extension for case-insensitive text
CREATE EXTENSION IF NOT EXISTS citext;

-- ────────────────────────────────────────────────
-- USERS
-- ────────────────────────────────────────────────
CREATE TABLE users (
    id              BIGSERIAL       PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    email           CITEXT          NOT NULL UNIQUE,
    email_verified_at TIMESTAMPTZ,
    password_hash   VARCHAR(255)    NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ              DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_deleted_at ON users (deleted_at);

-- ────────────────────────────────────────────────
-- BUSINESSES
-- ────────────────────────────────────────────────
CREATE TABLE businesses (
    id                      BIGSERIAL       PRIMARY KEY,
    user_id                 BIGINT          NOT NULL UNIQUE,
    name                    VARCHAR(200)    NOT NULL,
    currency                VARCHAR(3)      NOT NULL DEFAULT 'USD',
    country                 VARCHAR(100),
    timezone                VARCHAR(50)     DEFAULT 'UTC',
    fiscal_year_start_month INTEGER         NOT NULL DEFAULT 1,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ              DEFAULT NOW(),

    CONSTRAINT fk_businesses_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ────────────────────────────────────────────────
-- USER SETTINGS
-- ────────────────────────────────────────────────
CREATE TABLE user_settings (
    id                          BIGSERIAL       PRIMARY KEY,
    user_id                     BIGINT          NOT NULL UNIQUE,
    dark_mode                   BOOLEAN         NOT NULL DEFAULT FALSE,
    locale                      VARCHAR(10)     DEFAULT 'en',
    notification_preferences_json JSONB         DEFAULT '{}',
    created_at                  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ              DEFAULT NOW(),

    CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ────────────────────────────────────────────────
-- REFRESH TOKENS
-- ────────────────────────────────────────────────
CREATE TABLE refresh_tokens (
    id          BIGSERIAL       PRIMARY KEY,
    user_id     BIGINT          NOT NULL,
    token_hash  VARCHAR(255)    NOT NULL,
    expires_at  TIMESTAMPTZ     NOT NULL,
    revoked_at  TIMESTAMPTZ,
    device_info VARCHAR(500),
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);

-- ────────────────────────────────────────────────
-- CATEGORIES
-- ────────────────────────────────────────────────
CREATE TABLE categories (
    id          BIGSERIAL       PRIMARY KEY,
    business_id BIGINT          NOT NULL,
    name        VARCHAR(100)    NOT NULL,
    type        VARCHAR(20)     NOT NULL CHECK (type IN ('income', 'expense')),
    color       VARCHAR(7),
    icon        VARCHAR(50),
    is_default  BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ              DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,

    CONSTRAINT fk_categories_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
);

CREATE INDEX idx_categories_business_id ON categories (business_id);
CREATE INDEX idx_categories_type ON categories (type);

-- ────────────────────────────────────────────────
-- INCOMES
-- ────────────────────────────────────────────────
CREATE TABLE incomes (
    id          BIGSERIAL       PRIMARY KEY,
    business_id BIGINT          NOT NULL,
    category_id BIGINT,
    title       VARCHAR(200)    NOT NULL,
    amount      NUMERIC(14, 2)  NOT NULL CHECK (amount > 0),
    received_at TIMESTAMPTZ     NOT NULL,
    source      VARCHAR(200),
    notes       TEXT,
    is_recurring BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ              DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,

    CONSTRAINT fk_incomes_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE,
    CONSTRAINT fk_incomes_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
);

CREATE INDEX idx_incomes_business_id ON incomes (business_id);
CREATE INDEX idx_incomes_category_id ON incomes (category_id);
CREATE INDEX idx_incomes_received_at ON incomes (received_at);

-- ────────────────────────────────────────────────
-- INCOME RECURRING RULES
-- ────────────────────────────────────────────────
CREATE TABLE income_recurring_rules (
    id          BIGSERIAL       PRIMARY KEY,
    income_id   BIGINT          NOT NULL UNIQUE,
    frequency   VARCHAR(20)     NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
    interval    INTEGER         NOT NULL DEFAULT 1,
    starts_at   TIMESTAMPTZ     NOT NULL,
    ends_at     TIMESTAMPTZ,
    next_run_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_income_recurring_income FOREIGN KEY (income_id) REFERENCES incomes (id) ON DELETE CASCADE
);

-- ────────────────────────────────────────────────
-- EXPENSES
-- ────────────────────────────────────────────────
CREATE TABLE expenses (
    id              BIGSERIAL       PRIMARY KEY,
    business_id     BIGINT          NOT NULL,
    category_id     BIGINT,
    title           VARCHAR(200)    NOT NULL,
    amount          NUMERIC(14, 2)  NOT NULL CHECK (amount > 0),
    spent_at        TIMESTAMPTZ     NOT NULL,
    merchant        VARCHAR(200),
    payment_method  VARCHAR(50),
    notes           TEXT,
    is_recurring    BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ              DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT fk_expenses_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE,
    CONSTRAINT fk_expenses_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
);

CREATE INDEX idx_expenses_business_id ON expenses (business_id);
CREATE INDEX idx_expenses_category_id ON expenses (category_id);
CREATE INDEX idx_expenses_spent_at ON expenses (spent_at);
CREATE INDEX idx_expenses_amount ON expenses (amount);

-- ────────────────────────────────────────────────
-- EXPENSE RECURRING RULES
-- ────────────────────────────────────────────────
CREATE TABLE expense_recurring_rules (
    id          BIGSERIAL       PRIMARY KEY,
    expense_id  BIGINT          NOT NULL UNIQUE,
    frequency   VARCHAR(20)     NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
    interval    INTEGER         NOT NULL DEFAULT 1,
    starts_at   TIMESTAMPTZ     NOT NULL,
    ends_at     TIMESTAMPTZ,
    next_run_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_expense_recurring_expense FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE
);

-- ────────────────────────────────────────────────
-- EXPENSE RECEIPTS
-- ────────────────────────────────────────────────
CREATE TABLE expense_receipts (
    id              BIGSERIAL       PRIMARY KEY,
    expense_id      BIGINT          NOT NULL UNIQUE,
    object_key      VARCHAR(500)    NOT NULL,
    original_name   VARCHAR(255)    NOT NULL,
    mime_type       VARCHAR(100)    NOT NULL,
    file_size       BIGINT          NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_receipts_expense FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE
);

-- ────────────────────────────────────────────────
-- BUDGETS
-- ────────────────────────────────────────────────
CREATE TABLE budgets (
    id                      BIGSERIAL       PRIMARY KEY,
    business_id             BIGINT          NOT NULL,
    category_id             BIGINT,
    name                    VARCHAR(200)    NOT NULL,
    amount                  NUMERIC(14, 2)  NOT NULL CHECK (amount > 0),
    period                  VARCHAR(20)     NOT NULL CHECK (period IN ('monthly', 'yearly', 'custom')),
    starts_at               TIMESTAMPTZ     NOT NULL,
    ends_at                 TIMESTAMPTZ,
    alert_threshold_percent INTEGER         DEFAULT 80,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ              DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,

    CONSTRAINT fk_budgets_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE,
    CONSTRAINT fk_budgets_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
);

CREATE INDEX idx_budgets_business_id ON budgets (business_id);
CREATE INDEX idx_budgets_category_id ON budgets (category_id);
CREATE INDEX idx_budgets_starts_at ON budgets (starts_at);
CREATE INDEX idx_budgets_ends_at ON budgets (ends_at);

-- ────────────────────────────────────────────────
-- SAVINGS GOALS
-- ────────────────────────────────────────────────
CREATE TABLE savings_goals (
    id              BIGSERIAL       PRIMARY KEY,
    business_id     BIGINT          NOT NULL,
    name            VARCHAR(200)    NOT NULL,
    target_amount   NUMERIC(14, 2)  NOT NULL CHECK (target_amount > 0),
    current_amount  NUMERIC(14, 2)  NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    deadline        TIMESTAMPTZ,
    status          VARCHAR(20)     NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ              DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT fk_goals_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
);

CREATE INDEX idx_goals_business_id ON savings_goals (business_id);
CREATE INDEX idx_goals_status ON savings_goals (status);
CREATE INDEX idx_goals_deadline ON savings_goals (deadline);

-- ────────────────────────────────────────────────
-- INVESTMENTS
-- ────────────────────────────────────────────────
CREATE TABLE investments (
    id              BIGSERIAL       PRIMARY KEY,
    business_id     BIGINT          NOT NULL,
    name            VARCHAR(200)    NOT NULL,
    type            VARCHAR(30)     NOT NULL CHECK (type IN ('stock', 'crypto', 'fund', 'real_estate', 'other')),
    quantity        NUMERIC(14, 4),
    purchase_price  NUMERIC(14, 2),
    current_value   NUMERIC(14, 2),
    invested_amount NUMERIC(14, 2)  NOT NULL CHECK (invested_amount >= 0),
    notes           TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ              DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT fk_investments_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
);

CREATE INDEX idx_investments_business_id ON investments (business_id);
CREATE INDEX idx_investments_type ON investments (type);

-- ────────────────────────────────────────────────
-- NOTIFICATIONS
-- ────────────────────────────────────────────────
CREATE TABLE notifications (
    id          BIGSERIAL       PRIMARY KEY,
    business_id BIGINT          NOT NULL,
    type        VARCHAR(50)     NOT NULL,
    title       VARCHAR(200)    NOT NULL,
    body        TEXT,
    data_json   JSONB           DEFAULT '{}',
    read_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_notifications_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_business_id ON notifications (business_id);
CREATE INDEX idx_notifications_read_at ON notifications (read_at);
CREATE INDEX idx_notifications_type ON notifications (type);

-- ────────────────────────────────────────────────
-- AI PLACEHOLDER TABLES (flagged off in V1)
-- ────────────────────────────────────────────────
CREATE TABLE assistant_conversations (
    id          BIGSERIAL       PRIMARY KEY,
    business_id BIGINT          NOT NULL,
    title       VARCHAR(200),
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ              DEFAULT NOW(),

    CONSTRAINT fk_assistant_conv_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
);

CREATE TABLE assistant_messages (
    id              BIGSERIAL       PRIMARY KEY,
    conversation_id BIGINT          NOT NULL,
    role            VARCHAR(20)     NOT NULL CHECK (role IN ('user', 'assistant')),
    content         TEXT            NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_assistant_msg_conv FOREIGN KEY (conversation_id) REFERENCES assistant_conversations (id) ON DELETE CASCADE
);

CREATE TABLE financial_insights (
    id          BIGSERIAL       PRIMARY KEY,
    business_id BIGINT          NOT NULL,
    type        VARCHAR(50)     NOT NULL,
    title       VARCHAR(200)    NOT NULL,
    content     TEXT,
    data_json   JSONB           DEFAULT '{}',
    generated_at TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_insights_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
);

CREATE INDEX idx_insights_business_id ON financial_insights (business_id);
