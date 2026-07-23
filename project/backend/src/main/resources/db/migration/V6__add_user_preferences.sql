-- V6__add_user_preferences.sql
-- Add UI preference fields to users table
ALTER TABLE users
ADD COLUMN enable_ai_insights BOOLEAN DEFAULT TRUE,
ADD COLUMN compact_mode BOOLEAN DEFAULT FALSE,
ADD COLUMN auto_categorize_transactions BOOLEAN DEFAULT TRUE,
ADD COLUMN show_tips BOOLEAN DEFAULT TRUE;

-- Update existing records with default values to ensure no nulls
UPDATE users SET enable_ai_insights = TRUE WHERE enable_ai_insights IS NULL;
UPDATE users SET compact_mode = FALSE WHERE compact_mode IS NULL;
UPDATE users SET auto_categorize_transactions = TRUE WHERE auto_categorize_transactions IS NULL;
UPDATE users SET show_tips = TRUE WHERE show_tips IS NULL;

-- Add format preference fields to businesses table
ALTER TABLE businesses
ADD COLUMN date_format VARCHAR(50) DEFAULT 'MM/DD/YYYY',
ADD COLUMN number_format VARCHAR(50) DEFAULT 'US';

-- Update existing records with default values
UPDATE businesses SET date_format = 'MM/DD/YYYY' WHERE date_format IS NULL;
UPDATE businesses SET number_format = 'US' WHERE number_format IS NULL;
