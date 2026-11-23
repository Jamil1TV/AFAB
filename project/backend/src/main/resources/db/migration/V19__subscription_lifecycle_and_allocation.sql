-- ═══════════════════════════════════════════════════════════════════════════════
-- AFAB — Flyway V19: Complete Subscription Lifecycle, Grace Period,
-- Business Allocation & Read-Only Mode, History, and Notifications
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Enforce official trial & business allocation rules:
--    Free: 1 editable business, 0 trial days
--    Plus: 3 editable businesses, 7-day trial (EXCLUSIVELY on Plus)
--    Pro:  5 editable businesses, 0 trial days
UPDATE plan_entitlements
SET value = '0'
WHERE feature_key = 'trial.days'
  AND plan_id IN (SELECT id FROM plans WHERE slug IN ('free', 'pro'));

UPDATE plan_entitlements
SET value = '7'
WHERE feature_key = 'trial.days'
  AND plan_id = (SELECT id FROM plans WHERE slug = 'plus');

UPDATE plan_entitlements
SET value = '1'
WHERE feature_key = 'business.max'
  AND plan_id = (SELECT id FROM plans WHERE slug = 'free');

UPDATE plan_entitlements
SET value = '3'
WHERE feature_key = 'business.max'
  AND plan_id = (SELECT id FROM plans WHERE slug = 'plus');

UPDATE plan_entitlements
SET value = '5'
WHERE feature_key = 'business.max'
  AND plan_id = (SELECT id FROM plans WHERE slug = 'pro');

-- 2. Extend businesses with primary designation & access_mode (EDITABLE | READ_ONLY)
ALTER TABLE businesses
    ADD COLUMN IF NOT EXISTS is_primary  BOOLEAN     NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS access_mode VARCHAR(20) NOT NULL DEFAULT 'EDITABLE';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_businesses_access_mode'
    ) THEN
        ALTER TABLE businesses
            ADD CONSTRAINT chk_businesses_access_mode
            CHECK (access_mode IN ('EDITABLE', 'READ_ONLY'));
    END IF;
END $$;

-- Backfill is_primary for existing users who do not yet have a primary business:
-- prefer active_business_id when it is non-archived and owned by the user,
-- otherwise pick the oldest non-archived business owned by the user.
WITH ranked_businesses AS (
    SELECT
        b.id,
        b.user_id,
        ROW_NUMBER() OVER (
            PARTITION BY b.user_id
            ORDER BY
                CASE WHEN u.active_business_id = b.id THEN 0 ELSE 1 END,
                b.created_at ASC,
                b.id ASC
        ) AS rn
    FROM businesses b
    JOIN users u ON u.id = b.user_id
    WHERE b.archived_at IS NULL
      AND NOT EXISTS (
          SELECT 1
          FROM businesses bp
          WHERE bp.user_id = b.user_id
            AND bp.is_primary = true
            AND bp.archived_at IS NULL
      )
)
UPDATE businesses b
SET is_primary = true
FROM ranked_businesses rb
WHERE b.id = rb.id
  AND rb.rn = 1;

CREATE INDEX IF NOT EXISTS idx_businesses_user_access
    ON businesses(user_id, access_mode);

-- 3. Extend subscriptions with lifecycle, pending downgrade, grace period & out-of-order guards
ALTER TABLE subscriptions
    ADD COLUMN IF NOT EXISTS trial_start                   TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS canceled_at                   TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS effective_cancel_at           TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS pending_plan_id               UUID REFERENCES plans(id),
    ADD COLUMN IF NOT EXISTS pending_billing_interval      VARCHAR(20),
    ADD COLUMN IF NOT EXISTS pending_change_effective_at   TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS stripe_schedule_id            VARCHAR(255),
    ADD COLUMN IF NOT EXISTS first_payment_failure_at      TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS grace_period_ends_at          TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_payment_failure_reason   TEXT,
    ADD COLUMN IF NOT EXISTS last_stripe_event_created     BIGINT,
    ADD COLUMN IF NOT EXISTS allocation_attention_required BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS trial_reminder_sent_at        TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS grace_reminder_sent_at        TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_subscriptions_status_grace
    ON subscriptions(status, grace_period_ends_at);

CREATE INDEX IF NOT EXISTS idx_subscriptions_status_trial
    ON subscriptions(status, trial_end);

-- 4. Pending business allocations (configured in advance for scheduled downgrades)
CREATE TABLE IF NOT EXISTS pending_business_allocations (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id      UUID        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    target_plan_slug VARCHAR(50) NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pending_alloc_user_business UNIQUE (user_id, business_id)
);

CREATE INDEX IF NOT EXISTS idx_pending_alloc_user
    ON pending_business_allocations(user_id);

-- 5. Subscription audit history
CREATE TABLE IF NOT EXISTS subscription_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type      VARCHAR(60) NOT NULL,
    from_plan_slug  VARCHAR(50),
    to_plan_slug    VARCHAR(50),
    from_status     VARCHAR(30),
    to_status       VARCHAR(30),
    stripe_event_id VARCHAR(255),
    effective_at    TIMESTAMPTZ,
    details         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sub_history_user_created
    ON subscription_history(user_id, created_at DESC);

-- 6. Stripe invoice / payment history
CREATE TABLE IF NOT EXISTS payment_history (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stripe_invoice_id      VARCHAR(255) NOT NULL UNIQUE,
    stripe_subscription_id VARCHAR(255),
    amount_cents           BIGINT       NOT NULL DEFAULT 0,
    currency               VARCHAR(10)  NOT NULL DEFAULT 'USD',
    status                 VARCHAR(30)  NOT NULL,
    failure_reason         TEXT,
    hosted_invoice_url     TEXT,
    invoice_pdf_url        TEXT,
    paid_at                TIMESTAMPTZ,
    failed_at              TIMESTAMPTZ,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_history_user_created
    ON payment_history(user_id, created_at DESC);

-- 7. Persisted user notifications for subscription lifecycle & business allocation alerts
CREATE TABLE IF NOT EXISTS notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type       VARCHAR(60)  NOT NULL,
    severity   VARCHAR(20)  NOT NULL DEFAULT 'INFO',
    title      VARCHAR(255) NOT NULL,
    message    TEXT         NOT NULL,
    action_url VARCHAR(500),
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
    ON notifications(user_id, read_at, created_at DESC);
