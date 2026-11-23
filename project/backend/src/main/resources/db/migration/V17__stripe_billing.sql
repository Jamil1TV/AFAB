-- ═══════════════════════════════════════════════════════════════════════════════
-- AFAB — Flyway V17: Stripe Billing Integration (Sandbox Products, Prices & Sync)
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE plans
    ADD COLUMN IF NOT EXISTS stripe_product_id       VARCHAR(255),
    ADD COLUMN IF NOT EXISTS stripe_price_id_monthly VARCHAR(255),
    ADD COLUMN IF NOT EXISTS stripe_price_id_yearly  VARCHAR(255);

UPDATE plans
SET stripe_product_id       = 'prod_Vg6WlEo7xZLzHu',
    stripe_price_id_monthly = 'price_1UekJm3F29j0Fcd3gSMVczQx',
    stripe_price_id_yearly  = 'price_1UekJo3F29j0Fcd3XRfc2MCa',
    updated_at              = NOW()
WHERE slug = 'plus';

UPDATE plans
SET stripe_product_id       = 'prod_Vg6W83QR7bR3iN',
    stripe_price_id_monthly = 'price_1UekJr3F29j0Fcd33GeEZc33',
    stripe_price_id_yearly  = 'price_1UekJt3F29j0Fcd3IRv7MGZ2',
    updated_at              = NOW()
WHERE slug = 'pro';

ALTER TABLE subscriptions
    ADD COLUMN IF NOT EXISTS stripe_customer_id     VARCHAR(255),
    ADD COLUMN IF NOT EXISTS stripe_subscription_id VARCHAR(255),
    ADD COLUMN IF NOT EXISTS stripe_price_id        VARCHAR(255),
    ADD COLUMN IF NOT EXISTS billing_interval       VARCHAR(20),
    ADD COLUMN IF NOT EXISTS trial_used             BOOLEAN NOT NULL DEFAULT false;

UPDATE subscriptions
SET trial_used = true
WHERE trial_end IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_subscriptions_stripe_customer_id
    ON subscriptions(stripe_customer_id)
    WHERE stripe_customer_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_subscriptions_stripe_subscription_id
    ON subscriptions(stripe_subscription_id)
    WHERE stripe_subscription_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS stripe_webhook_events (
    event_id     VARCHAR(255) PRIMARY KEY,
    event_type   VARCHAR(100) NOT NULL,
    processed_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
