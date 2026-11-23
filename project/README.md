# AFAB — AI Finance Assistant for Business

AFAB is a multi-tenant **Business Financial Management & Intelligence Platform** for Small and Medium-Sized Businesses (SMEs).

## Architecture & Stack
- **Backend:** Java 21 LTS, Spring Boot 4.1.0 (Modular Monolith / Package-by-Feature), Spring Security, Spring Data JPA / Hibernate (`ddl-auto: none`), OpenPDF 2.0.3
- **Frontend:** Next.js 16.2.10 (App Router, `proxy.ts`), React 19, TypeScript 5, Tailwind CSS v4, `next-intl` (English & Arabic RTL), Recharts
- **Database:** PostgreSQL 16 (`postgres:16-alpine`), Flyway forward-only schema migrations (`V1`–`V23`)
- **Cache & Rate Limiting:** Redis 7 (`redis:7-alpine`) with atomic Lua distributed rate limiting
- **Private Object Storage:** MinIO / S3-compatible private bucket storage (receipts)
- **Planned AI Direction (P2/P3):** Self-hosted Gemma 4 E4B via Ollama, EmbeddingGemma 2, and `pgvector` (no external LLM APIs)

---

## Implemented Modules (P0 & P1 Foundation)

### P0 — Security & Reliability Foundation
- **Secrets & Config Hardening:** No hardcoded production secrets in `application.yml` or `.env.example`; fail-fast `SecurityConfigurationValidator` rejects missing/weak/placeholder `JWT_SECRET`, insecure cookies outside `local`/`dev`/`test`, and dev OTP bypass outside `local`/`dev`.
- **Sanitized Logging:** `LogSanitizer` masks emails and strips tokens/OTPs/reset links from application logs (`SmtpEmailServiceImpl`, `MailHealthMonitor`, `AuditService`, `JwtAuthenticationFilter`).
- **Authentication & Session Security (`V17`):** Short-lived JWT access tokens held strictly in frontend JS memory (zero `localStorage` token storage); refresh tokens stored SHA-256 hashed in DB, delivered exclusively via `HttpOnly`, `SameSite`, `Secure` cookies (`Path=/api/v1`) with double-submit CSRF (`afab_csrf` + `X-CSRF-Token`) and `Origin` verification, refresh token rotation, and token-family reuse revocation.
- **Distributed Rate Limiting:** Redis-backed atomic Lua sliding/fixed-window rate limiting (`DistributedRateLimiter`) across auth endpoints (`LOGIN`, `REGISTER`, `FORGOT_PASSWORD`, `VERIFY_EMAIL`, `OTP_VERIFY`, `RESET_PASSWORD`, `REFRESH`) with trusted-proxy IP resolution (`ClientIpResolver`) and explicit `fail_closed` / `fail_open` handling.
- **Safe Account Deletion & Business Ownership (`V18`):** Replaced `ON DELETE CASCADE` on `businesses.fk_businesses_user` with `ON DELETE RESTRICT`; preflight checks (`GET /api/v1/user/me/deletion-preflight`), ownership transfer (`POST /api/v1/business/{id}/transfer-ownership`), sole-owner guard (`409 Conflict`), and soft-delete tombstone anonymization preserving business financial records.
- **Multi-Tenant Isolation:** Strict server-side `CurrentBusinessService` membership and active-user checks across every tenant-scoped endpoint (`X-Business-Id` verified against active `business_members`).

### P1 — Core Business Finance Foundation
- **Immutable Transaction FX Snapshots (`V19`):** Records `original_amount`, `original_currency`, `base_currency`, `exchange_rate`, `converted_amount`, `fx_rate_source`, and `fx_rate_timestamp`. Changing business base currency applies to future transactions only and never overwrites historical values.
- **Real Customer Backend (`V20`):** Full multi-tenant CRUD, search/filtering, soft archive, real invoice/payment financial aggregates (`/api/v1/customers`), and removal of frontend `localStorage` fallback.
- **Real Invoice Lifecycle & Payments (`V21`):** `DRAFT → UNPAID / ISSUED → PARTIALLY_PAID → PAID / OVERDUE / CANCELLED`, atomic concurrent per-business numbering (`invoice_sequences`), strict cash-basis accounting (unpaid invoices never create Income Transactions), idempotent Payment recording (`Idempotency-Key` + DB unique constraint) creating 1:1 Income Transactions with FX snapshots (`/api/v1/invoices`).
- **Recurring Transactions & Private Receipts (`V22`):** Idempotent timezone-aware recurring engine (`WEEKLY`/`MONTHLY`/`QUARTERLY`/`YEARLY`) guarded by pessimistic locking and DB `UNIQUE (recurring_transaction_id, scheduled_date)` (`/api/v1/recurring-transactions`); private MinIO receipt storage with magic-byte + MIME validation, size limits, SHA-256 checksums, tenant-prefixed keys, authenticated streaming, and short-lived signed URLs (`/api/v1/receipts`).
- **Business Budgets (`V23`):** Overall and expense-category budgets (`MONTHLY`/`QUARTERLY`/`YEARLY`/`CUSTOM`), split-safe real-time spending calculations, deterministic `OK`/`APPROACHING`/`OVER_BUDGET` alerts, and Dashboard integration (`/api/v1/budgets`, `/api/v1/dashboard/summary`).

---

## Local Setup & Verification

### 1. Environment Variables
Copy `project/.env.example` to `project/.env` and replace every `CHANGE_ME_...` placeholder with locally generated values. Never commit `.env` or real credentials.

### 2. Infrastructure
```bash
cd project
docker compose up -d postgres redis minio mailpit
```

### 3. Backend Tests
Unit tests (fast, no external services required):
```bash
cd project/backend
mvn -B test
```

Full unit + end-to-end integration tests against PostgreSQL 16 (Flyway `V1`–`V23`), Redis 7, and MinIO:
```bash
RUN_INTEGRATION_TESTS=true mvn -B test
```
*(In CI, `.github/workflows/ci.yml` provisions PostgreSQL 16, Redis 7, and MinIO service containers automatically.)*

### 4. Frontend Checks
```bash
cd project/frontend
npm ci
npx tsc --noEmit
npm run build
```
