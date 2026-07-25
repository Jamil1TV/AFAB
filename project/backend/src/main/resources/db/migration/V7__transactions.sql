-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V7: Categories & Transactions Module
-- ═══════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────
-- CATEGORIES
-- ────────────────────────────────────────────────
CREATE TABLE categories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID,
    name        VARCHAR(100) NOT NULL,
    type        VARCHAR(20)  NOT NULL, -- 'INCOME', 'EXPENSE'
    icon        VARCHAR(50),
    color       VARCHAR(30),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_categories_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
);

CREATE INDEX idx_categories_business ON categories (business_id);

-- ────────────────────────────────────────────────
-- TRANSACTIONS
-- ────────────────────────────────────────────────
CREATE TABLE transactions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id      UUID            NOT NULL,
    type             VARCHAR(20)     NOT NULL, -- 'INCOME', 'EXPENSE'
    amount           NUMERIC(15, 2)  NOT NULL,
    currency         VARCHAR(3)      NOT NULL DEFAULT 'USD',
    category_id      UUID,
    description      VARCHAR(255)    NOT NULL,
    transaction_date DATE            NOT NULL,
    payment_method   VARCHAR(50),    -- 'BANK_TRANSFER', 'CARD', 'CASH', 'OTHER'
    status           VARCHAR(30)     NOT NULL DEFAULT 'COMPLETED', -- 'COMPLETED', 'PENDING', 'CANCELLED'
    receipt_url      VARCHAR(512),
    notes            TEXT,
    created_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ,

    CONSTRAINT fk_transactions_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
);

CREATE INDEX idx_transactions_business ON transactions (business_id);
CREATE INDEX idx_transactions_date ON transactions (transaction_date);
CREATE INDEX idx_transactions_type ON transactions (type);

-- ────────────────────────────────────────────────
-- DEFAULT GLOBAL CATEGORIES (business_id IS NULL)
-- ────────────────────────────────────────────────
INSERT INTO categories (name, type, icon, color) VALUES
('Sales & Services', 'INCOME', 'DollarSign', '#10b981'),
('Consulting', 'INCOME', 'Briefcase', '#06b6d4'),
('Investments', 'INCOME', 'TrendingUp', '#8b5cf6'),
('Other Income', 'INCOME', 'PlusCircle', '#6366f1'),
('Rent & Utilities', 'EXPENSE', 'Building', '#ef4444'),
('Marketing & Ads', 'EXPENSE', 'Megaphone', '#f59e0b'),
('Software & Tech', 'EXPENSE', 'Laptop', '#8b5cf6'),
('Salaries & Payroll', 'EXPENSE', 'Users', '#3b82f6'),
('Office Supplies', 'EXPENSE', 'Package', '#10b981'),
('Travel & Meals', 'EXPENSE', 'Plane', '#ec4899'),
('Legal & Professional', 'EXPENSE', 'ShieldCheck', '#6b7280'),
('Other Expense', 'EXPENSE', 'MinusCircle', '#64748b');
