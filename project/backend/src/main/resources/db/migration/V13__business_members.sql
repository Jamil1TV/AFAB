-- ═══════════════════════════════════════════════════════════════════
-- AFAB — Flyway V13: Multi-Business Foundation (Business Members)
-- ═══════════════════════════════════════════════════════════════════

-- 1. Create business_members table
CREATE TABLE business_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID         NOT NULL,
    user_id     UUID         NOT NULL,
    role        VARCHAR(50)  NOT NULL DEFAULT 'MEMBER',
    status      VARCHAR(50)  NOT NULL DEFAULT 'ACTIVE',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ,

    CONSTRAINT fk_business_members_business FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE,
    CONSTRAINT fk_business_members_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT uq_business_member UNIQUE (business_id, user_id)
);

CREATE INDEX idx_business_members_business ON business_members (business_id);
CREATE INDEX idx_business_members_user ON business_members (user_id);
CREATE INDEX idx_business_members_user_status ON business_members (user_id, status);

-- 2. Backfill existing businesses: Assign OWNER role to the creator
INSERT INTO business_members (business_id, user_id, role, status, created_at)
SELECT id, user_id, 'OWNER', 'ACTIVE', created_at
FROM businesses
ON CONFLICT (business_id, user_id) DO NOTHING;

-- 3. Drop the single-business UNIQUE constraint on businesses.user_id
-- In V1, user_id had a UNIQUE constraint. Find and drop it.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'businesses'::regclass 
          AND contype = 'u' 
          AND conname LIKE '%user_id%'
    ) LOOP
        EXECUTE 'ALTER TABLE businesses DROP CONSTRAINT ' || quote_ident(r.conname);
    END LOOP;
END $$;

-- 4. Add archived_at column to businesses for soft deletion / archiving
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

-- 5. Add active_business_id to users for remembered business context
ALTER TABLE users ADD COLUMN IF NOT EXISTS active_business_id UUID;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_users_active_business'
    ) THEN
        ALTER TABLE users 
        ADD CONSTRAINT fk_users_active_business 
        FOREIGN KEY (active_business_id) REFERENCES businesses (id) ON DELETE SET NULL;
    END IF;
END $$;

-- Backfill active_business_id with the user's existing business
UPDATE users u
SET active_business_id = b.id
FROM businesses b
WHERE b.user_id = u.id AND u.active_business_id IS NULL;
