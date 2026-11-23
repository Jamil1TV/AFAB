# AFAB Production Deployment Checklist

Before deploying AFAB to staging or production, verify every item below.

## 1. Secrets & Credential Rotation (Mandatory)
- [ ] **Rotate all previously exposed credentials** (SMTP App Password, PostgreSQL password, JWT signing secret, MinIO access/secret keys). Never reuse credentials that appeared in local development archives or historical Git commits.
- [ ] Inject `JWT_SECRET` (minimum 32 random bytes / 64+ chars), `POSTGRES_PASSWORD`, `REDIS_PASSWORD`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, and `MAIL_PASSWORD` exclusively via a secret manager or runtime environment variables.
- [ ] Run backend with `SPRING_PROFILES_ACTIVE=prod` (`application-prod.yml` enforces `afab.auth.cookie.secure=true`, `afab.auth.allow-dev-otp=false`, `afab.rate-limit.fail-mode=fail_closed`, and disables Swagger UI by default).
- [ ] Confirm `SecurityConfigurationValidator` startup checks pass cleanly (it fails fast if secrets are weak/placeholder or cookies are insecure).

## 2. Authentication, Cookies, CSRF & CORS (Implemented in P0.2)
- [x] Refresh tokens stored SHA-256 hashed in `refresh_tokens`, transmitted only via `HttpOnly` cookies (`Path=/api/v1`), rotated on every refresh with token-family reuse revocation.
- [x] Access tokens held strictly in frontend memory (no `localStorage` token storage).
- [x] Double-submit CSRF (`afab_csrf` + `X-CSRF-Token`) and `Origin` header validation enforced on cookie-authenticated endpoints.
- [ ] Configure `CORS_ALLOWED_ORIGINS` strictly to exact production HTTPS frontend origins (e.g., `https://app.afab.com`).
- [ ] Configure `AFAB_COOKIE_DOMAIN` and `AFAB_COOKIE_SAME_SITE` (`Lax` for same-site subdomains, `None` with `AFAB_COOKIE_SECURE=true` only if strictly cross-site).
- [ ] Serve frontend and backend exclusively over HTTPS / TLS 1.2+.

## 3. Distributed Rate Limiting & Reverse Proxy (Implemented in P0.3)
- [x] Redis-backed atomic Lua rate limiting (`DistributedRateLimiter`) enabled across login, signup, forgot-password, email verification, OTP, password reset, and refresh endpoints.
- [x] `ClientIpResolver` ignores untrusted `X-Forwarded-For` headers by default.
- [ ] Set `AFAB_TRUSTED_PROXIES` to the exact IP/CIDR of your production reverse proxy / load balancer so client IP identification is accurate and non-spoofable.
- [ ] Provision production Redis with authentication (`REDIS_PASSWORD`), TLS, and high availability (`fail_closed` rejects auth requests with HTTP 503 if Redis is unreachable).

## 4. Transactional Email Provider & OTP Hardening
- [ ] Replace Gmail SMTP (`SmtpEmailServiceImpl`) with a production transactional email provider (AWS SES, Resend, or Postmark) with SPF/DKIM/DMARC configured.
- [x] Sensitive OTP values, password reset links, and raw emails removed from application logs (`LogSanitizer`).
- [ ] Follow-up hardening (post-P0/P1): hash 6-digit email verification OTPs at rest in `verification_tokens` using BCrypt/HMAC (password reset tokens are already SHA-256 hashed).

## 5. Database, Tenant Isolation & Account Deletion (Implemented in P0.4 / P0.5 / P1)
- [x] Flyway manages all schema evolution (`V1`–`V23`), `ddl-auto: none`, `afab.flyway.repair-on-migrate=false` in production.
- [x] `businesses.fk_businesses_user` uses `ON DELETE RESTRICT` (`V18`); sole active business owners must transfer ownership or archive businesses before deleting their user account.
- [x] Historical transaction FX snapshots (`V19`) are immutable; business base currency changes never retroactively rewrite historical values.
- [ ] Configure automated encrypted PostgreSQL backups and point-in-time recovery (PITR).

## 6. Private Receipt Object Storage (Implemented in P1.4)
- [x] MinIO bucket (`afab-receipts`) kept strictly private (no anonymous public read policy); uploads validate MIME + magic bytes + size limits and store under tenant-scoped keys (`businesses/{businessId}/transactions/{transactionId}/{uuid}.{ext}`).
- [ ] Configure production S3/MinIO server-side encryption (SSE-S3 or KMS) and bucket lifecycle/backup policies.
- [ ] Set `MINIO_PUBLIC_ENDPOINT` to the external HTTPS object-storage origin if using direct presigned downloads, or keep browser downloads routed through authenticated `GET /api/v1/receipts/{id}/content`.

## 7. Recurring Scheduler Operations (Implemented in P1.4)
- [x] Multi-instance execution is idempotent via pessimistic row locking and DB `UNIQUE (recurring_transaction_id, scheduled_date)`.
- [ ] Monitor recurring execution logs and configure alerting on failed scheduled runs.
