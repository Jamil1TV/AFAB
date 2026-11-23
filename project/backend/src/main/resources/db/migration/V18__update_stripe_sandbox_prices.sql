-- ═══════════════════════════════════════════════════════════════════════════════
-- AFAB — Flyway V18: Point Plus & Pro plans to AFAB sandbox catalog (acct_1Udcbi38YkKVFSSm)
-- ═══════════════════════════════════════════════════════════════════════════════

UPDATE plans
SET stripe_product_id       = 'prod_Vg720G91ZfutTV',
    stripe_price_id_monthly = 'price_1Uekny38YkKVFSSmyRzHVjnW',
    stripe_price_id_yearly  = 'price_1Uekny38YkKVFSSmfo4jwyzP',
    updated_at              = NOW()
WHERE slug = 'plus';

UPDATE plans
SET stripe_product_id       = 'prod_Vg722itgHItYl7',
    stripe_price_id_monthly = 'price_1Uekny38YkKVFSSmcIS2KW1G',
    stripe_price_id_yearly  = 'price_1Ueknz38YkKVFSSmSZOER1m2',
    updated_at              = NOW()
WHERE slug = 'pro';
