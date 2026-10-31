-- V14__add_user_plan_tier.sql
-- Add plan_tier column to users table to support subscription plan limits (FREE = 1, PLUS = 3, PRO = 5)

ALTER TABLE users ADD COLUMN IF NOT EXISTS plan_tier VARCHAR(20) NOT NULL DEFAULT 'FREE';

CREATE INDEX IF NOT EXISTS idx_users_plan_tier ON users (plan_tier);
