-- V15__plans_and_entitlements.sql
-- Phase 5: Plans and Server-Side Entitlements Engine

CREATE TABLE IF NOT EXISTS plans (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name           VARCHAR(100) NOT NULL,
    slug           VARCHAR(50)  NOT NULL UNIQUE,
    price_monthly  NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    price_yearly   NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    currency       VARCHAR(3)   NOT NULL DEFAULT 'USD',
    is_active      BOOLEAN      NOT NULL DEFAULT true,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS plan_entitlements (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id     UUID         NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    feature_key VARCHAR(100) NOT NULL,
    type        VARCHAR(50)  NOT NULL, -- BOOLEAN, LIMIT, QUOTA, LEVEL
    value       VARCHAR(255) NOT NULL,
    CONSTRAINT uq_plan_feature UNIQUE (plan_id, feature_key)
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id               UUID        NOT NULL REFERENCES plans(id),
    status                VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, TRIALING, PAST_DUE, CANCELED, EXPIRED
    period_start          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    period_end            TIMESTAMPTZ,
    trial_end             TIMESTAMPTZ,
    cancel_at_period_end  BOOLEAN     NOT NULL DEFAULT false,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ,
    CONSTRAINT uq_user_active_sub UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS usage_counters (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_key  VARCHAR(100) NOT NULL,
    period_start TIMESTAMPTZ  NOT NULL DEFAULT date_trunc('month', NOW()),
    used         INTEGER      NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_feature_period UNIQUE (user_id, feature_key, period_start)
);

CREATE INDEX IF NOT EXISTS idx_plan_entitlements_plan ON plan_entitlements(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_counters_user ON usage_counters(user_id, feature_key);

-- ── Seed Core Plans ──────────────────────────────────────────────
INSERT INTO plans (id, name, slug, price_monthly, price_yearly, currency, is_active)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'Free', 'free', 0.00, 0.00, 'USD', true),
    ('22222222-2222-2222-2222-222222222222', 'Plus', 'plus', 9.99, 7.99, 'USD', true),
    ('33333333-3333-3333-3333-333333333333', 'Pro',  'pro',  19.99, 15.99, 'USD', true)
ON CONFLICT (slug) DO NOTHING;

-- ── Seed Entitlements: FREE ─────────────────────────────────────
INSERT INTO plan_entitlements (plan_id, feature_key, type, value) VALUES
    ('11111111-1111-1111-1111-111111111111', 'ai.chat.queries_per_month', 'QUOTA', '10'),
    ('11111111-1111-1111-1111-111111111111', 'invoices.per_month',        'QUOTA', '5'),
    ('11111111-1111-1111-1111-111111111111', 'export.per_month',          'QUOTA', '5'),
    ('11111111-1111-1111-1111-111111111111', 'business.max',              'LIMIT', '1'),
    ('11111111-1111-1111-1111-111111111111', 'team.users',                'LIMIT', '1'),
    ('11111111-1111-1111-1111-111111111111', 'reports.level',             'LEVEL', 'basic'),
    ('11111111-1111-1111-1111-111111111111', 'forecast.cashflow',         'BOOLEAN', 'false'),
    ('11111111-1111-1111-1111-111111111111', 'ai.recommendations',        'BOOLEAN', 'false'),
    ('11111111-1111-1111-1111-111111111111', 'trial.days',                'LIMIT', '0')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

-- ── Seed Entitlements: PLUS ─────────────────────────────────────
INSERT INTO plan_entitlements (plan_id, feature_key, type, value) VALUES
    ('22222222-2222-2222-2222-222222222222', 'ai.chat.queries_per_month', 'QUOTA', '100'),
    ('22222222-2222-2222-2222-222222222222', 'invoices.per_month',        'QUOTA', '50'),
    ('22222222-2222-2222-2222-222222222222', 'export.per_month',          'QUOTA', '15'),
    ('22222222-2222-2222-2222-222222222222', 'business.max',              'LIMIT', '3'),
    ('22222222-2222-2222-2222-222222222222', 'team.users',                'LIMIT', '3'),
    ('22222222-2222-2222-2222-222222222222', 'reports.level',             'LEVEL', 'advanced'),
    ('22222222-2222-2222-2222-222222222222', 'forecast.cashflow',         'BOOLEAN', 'true'),
    ('22222222-2222-2222-2222-222222222222', 'ai.recommendations',        'BOOLEAN', 'true'),
    ('22222222-2222-2222-2222-222222222222', 'trial.days',                'LIMIT', '7')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

-- ── Seed Entitlements: PRO ──────────────────────────────────────
INSERT INTO plan_entitlements (plan_id, feature_key, type, value) VALUES
    ('33333333-3333-3333-3333-333333333333', 'ai.chat.queries_per_month', 'QUOTA', '300'),
    ('33333333-3333-3333-3333-333333333333', 'invoices.per_month',        'QUOTA', '-1'),
    ('33333333-3333-3333-3333-333333333333', 'export.per_month',          'QUOTA', '-1'),
    ('33333333-3333-3333-3333-333333333333', 'business.max',              'LIMIT', '5'),
    ('33333333-3333-3333-3333-333333333333', 'team.users',                'LIMIT', '5'),
    ('33333333-3333-3333-3333-333333333333', 'reports.level',             'LEVEL', 'custom'),
    ('33333333-3333-3333-3333-333333333333', 'forecast.cashflow',         'BOOLEAN', 'true'),
    ('33333333-3333-3333-3333-333333333333', 'ai.recommendations',        'BOOLEAN', 'true'),
    ('33333333-3333-3333-3333-333333333333', 'trial.days',                'LIMIT', '7')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

-- ── Backfill Existing Users with Free Subscription ──────────────
INSERT INTO subscriptions (user_id, plan_id, status, period_start)
SELECT u.id, '11111111-1111-1111-1111-111111111111', 'ACTIVE', NOW()
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM subscriptions s WHERE s.user_id = u.id
);
