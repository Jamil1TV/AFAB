# AFAB — AI Project Context
> **Purpose:** Read this file before changing AFAB. It is the shared source of truth for AI coding agents working across the frontend and backend.
>
> **Last updated:** 23 November 2026 (post P0 Security Hardening & P1 Business Finance Foundation execution; verified with automated backend unit + PostgreSQL 16 / Redis 7 / MinIO integration tests and Next.js production build).

## 1. Product identity
**AFAB** means **AI Finance Assistant for Business**. It is a SaaS financial-management platform for small businesses. Its core purpose is to help owners organize income and expenses, monitor financial performance, and make informed decisions from a clear dashboard.

- AFAB is a financial-management and financial-awareness product, not a replacement for professional accounting software or an ERP.
- Financial records must be isolated by business. A user must never see another user's or another business's records.
- Security, financial correctness, privacy, and UX consistency are core requirements.
- A mockup or UI component does not prove a feature is implemented or connected to production services.

## 2. Repository map
- `project/frontend/` — Next.js application.
- `project/backend/` — Spring Boot application.
- `project/docker-compose.yml` — local infrastructure orchestration.
- `project/.env.example` and `project/.env` — environment configuration. Never copy secrets into documentation or commits.
- `PRD/` — product requirements and schema planning.
- `New MD/` — architecture/product summary and guiding principles.
- `new md for frontend/` — frontend design-system and implementation references.
- `dark mode of AFAB/`, `light mode of AFAB/` — visual references.
- Additional Stitch/mockup assets.

Read this file and the relevant specialized context before editing:
- `AFAB_FRONTEND_CONTEXT.md`
- `AFAB_BACKEND_CONTEXT.md`

## 3. Verified technology stack

### Frontend
From `frontend/package.json` and source:
- Next.js 16.2.10 App Router
- React 19.2.4, TypeScript
- Tailwind CSS v4
- shadcn component ecosystem
- `next-intl` for English/Arabic routing and translations
- `next-themes`
- `lucide-react`, Recharts, Framer Motion
- ESLint 9 and npm lockfile

**Important:** This repository uses **Next.js, not Vite**. Do not migrate frameworks unless explicitly requested.

### Backend
From `backend/pom.xml` and source:
- Java 21, Spring Boot 4.1.0 declared in Maven parent
- Spring Web / REST, Spring Security, Spring Data JPA / Hibernate
- PostgreSQL, Flyway, Jakarta Bean Validation
- JJWT, Spring Mail, Spring Data Redis
- Bucket4j, MinIO SDK, Springdoc OpenAPI
- Maven

PostgreSQL is the primary database. Flyway owns schema evolution; Hibernate `ddl-auto` is `none`. Configuration references Redis, MinIO, SMTP, and JWT signing.

## 4. Architecture at a glance
```text
Browser
  └─ Next.js App Router UI (localized /en and /ar routes)
       └─ frontend/lib/api/* typed service wrappers
            └─ fetchClient
                 └─ Spring Boot REST API (/api/v1)
                      ├─ controllers
                      ├─ services / business logic
                      ├─ repositories (Spring Data JPA)
                      ├─ entities + DTOs
                      ├─ Spring Security + JWT filter
                      └─ PostgreSQL (Flyway-managed schema)
```
This is a modular monolith organized mainly by backend feature/package. Keep business logic out of controllers and separate UI components from API/data-access concerns.

**Integration caveat:** Project documentation describes a Next.js BFF/proxy design, but the inspected `fetchClient` calls the configured backend URL directly. Do not assume a secure server-side BFF exists; inspect the call path and deployment topology before changing auth/CORS/token handling.

## 5. Current implementation status (verified against source & tests)

### Backend modules implemented & tested
- **Authentication & Security (`P0`):** Registration, login, refresh (HttpOnly cookie + SHA-256 hash + token-family reuse detection + double-submit CSRF & Origin check), logout, email verification, resend verification, forgot/reset password, password change, TOTP 2FA, lockout, fail-fast `SecurityConfigurationValidator`, `LogSanitizer`, and Redis-backed Lua `DistributedRateLimiter` with trusted-proxy `ClientIpResolver`.
- **Users & Safe Account Deletion (`P0.4`):** Profile, session management, deletion preflight (`GET /api/v1/user/me/deletion-preflight`), sole-owner guard (`409 Conflict`), ownership transfer (`POST /api/v1/business/{id}/transfer-ownership`), `ON DELETE RESTRICT` (`V18`), and anonymized soft-delete tombstones preserving business financial data.
- **Multi-Business & Tenant Isolation (`P0.5`):** `business_members` (`OWNER`, `ADMIN`, `MEMBER`), `X-Business-Id` server-side verification, active-user enforcement, plan limits (1/3/5).
- **Transactions, Categories & Immutable FX Snapshots (`P1.1`, `V19`):** Multi-currency transactions storing immutable `original_amount`, `original_currency`, `base_currency`, `exchange_rate`, `converted_amount`, `fx_rate_source`, `fx_rate_timestamp`; splits & tax fields; base currency changes apply to future transactions only.
- **Customers (`P1.2`, `V20`):** Real multi-tenant `/api/v1/customers` CRUD, search/filters, soft archive, and live invoice/payment revenue metrics (no frontend `localStorage` fallback).
- **Invoices & Payments (`P1.3`, `V21`):** Real `/api/v1/invoices` lifecycle (`DRAFT`, `UNPAID`, `PARTIALLY_PAID`, `PAID`, `OVERDUE`, `CANCELLED`), atomic concurrent invoice numbering (`invoice_sequences`), cash-basis payment recording (`POST /api/v1/invoices/{id}/payments`) with `Idempotency-Key` deduplication and 1:1 linked Income Transactions.
- **Recurring Transactions & Private Receipt Storage (`P1.4`, `V22`):** Timezone-aware idempotent recurring engine (`/api/v1/recurring-transactions`) and private MinIO receipt storage (`/api/v1/receipts`) with MIME + magic-byte validation, SHA-256 checksums, tenant-prefixed object keys, authenticated streaming, and short-lived presigned URLs.
- **Business Budgets & Dashboard Integration (`P1.5`, `V23`):** Overall and category-scoped expense budgets (`/api/v1/budgets`) with split-safe real spending calculations, `OK`/`APPROACHING`/`OVER_BUDGET` alerts, and live Dashboard summary integration (`/api/v1/dashboard/summary`).
- **Plans & Entitlements (`/api/v1/subscription`) & Reports (`/api/v1/reports`):** Atomic monthly quotas, P&L, Cash Flow, Two-Period Comparisons, CSV & OpenPDF exports.

### Frontend areas implemented & built
- Public landing page, auth flows (memory-only access tokens, HttpOnly cookie refresh with single-flight deduplication, zero `localStorage` tokens), onboarding, English/Arabic RTL support.
- Dashboard (with live KPIs, Budget Progress widget, deterministic budget & overdue invoice reminders, real top customers), Transactions (with FX snapshot preview/lock & private receipt attach/download/delete drawer), Expenses, Revenue, Invoices (real lifecycle & payment recording UI), Customers (backend-only with explicit error states), Budgets (`/dashboard/budgets`), Recurring Transactions (`/dashboard/recurring`), Reports, Currencies, Settings (including account deletion preflight modal).

### Deferred to P2 / P3 (not yet implemented)
- Self-hosted AI features (**Gemma 4 E4B via Ollama, EmbeddingGemma 2, pgvector**), Savings Goals, Investments, Calendar/Notifications, Team Invitations, Billing/Payment Gateway, and external bank/accounting integrations.

## 6. Product decisions and inconsistencies

### 6.1 AI scope
Product summaries and rules say AI is excluded from MVP and prohibit third-party AI/LLM APIs; future AI is envisioned as self-hosted/internal. The frontend contains AI-themed UI, but the inspected backend does not show a complete AI inference service.

**Agent rule:** Do not integrate OpenAI, Anthropic, Gemini, or another third-party AI API unless the owner explicitly changes this rule. Distinguish UI, placeholders, deterministic analytics, and actual model-backed capabilities. Never fabricate AI outputs or imply a model is connected when it is not.

### 6.2 Multi-business support (Implemented in Phase 4)
Multi-business support is active:
- `business_members` table manages memberships (`OWNER`, `ADMIN`, `MEMBER`) across businesses.
- Users can create and switch between multiple workspaces.
- Plan limits are server-enforced (`V14__add_user_plan_tier.sql`):
  - **Free**: 1 business
  - **Plus**: up to 3 businesses
  - **Pro**: up to 5 businesses

### 6.3 Plans & Entitlements Engine (Implemented in Phase 5)
- Flyway `V15__plans_and_entitlements.sql` creates tables `plans`, `plan_entitlements`, `subscriptions`, and `usage_counters`.
- Plans matrix: Free ($0), Plus ($9.99/mo), Pro ($19.99/mo).
- Entitlement features tracked: `business.max`, `invoices.per_month`, `export.per_month`, `ai.chat.queries_per_month`, `ai.recommendations`, `forecast.cashflow`, `reports.level`, `team.users`, `trial.days`.
- Strict 7-day trial once per user account on Plus or Pro; expired trials automatically degrade to Free on reconciliation.
- Atomic counters with SQL upsert (`ON CONFLICT (subscription_id, feature_key, period) DO UPDATE SET used_count = usage_counters.used_count + ?`).
- Backend throws `PlanLimitReachedException` (403) with error code `PLAN_LIMIT_REACHED` when a quota is exceeded.
- `CurrentBusinessService` resolves active business context via `X-Business-Id` header (validated against user memberships, returning 403 Forbidden on foreign access) or fallback to `user.activeBusinessId`.
- Login, session, and profile logic uses `resolveUserActiveBusiness` to support multi-business accounts without 500 errors.

### 6.3 Pricing and checkout
Plan UI contains display data and local React state. The server-enforced entitlements and plan engine is planned in Phase 5. Mockup prices are Free `$0`, Plus `$9.99/month`, Pro `$19.99/month`. Stripe/LemonSqueezy payment gateway integration is scheduled for Phase 19.

### 6.4 Requirements vs implementation
PRD/schema documents include aspirational features. A requirement document is not implementation evidence. Prefer current source and migrations for actual behavior; preserve future requirements separately.

## 7. API conventions
- Backend base path: `/api/v1`.
- Use request/response DTOs, validation, correct status codes, and consistent errors.
- Do not expose JPA entities directly as public API contracts.
- Use pagination/filtering for growing lists.
- Financial calculations derive from persisted transactions and `FinanceStatsService` (cash basis).
- Update frontend wrappers and OpenAPI documentation when contracts change.

Controllers found in source:
- `/api/v1/auth/**` (register, login, cookie refresh, logout, email verify, password reset, change-password, 2FA challenge & verify)
- `/api/v1/business/**` (list, create, update, archive, switch active context, list members, transfer ownership)
- `/api/v1/dashboard/summary` (real-time stats, active budget summary, deterministic reminders, top customers)
- `/api/v1/transactions/**` (list, get by id, create, update, soft-delete, splits, tax, immutable FX snapshots)
- `/api/v1/categories/**` (per-business & global category management)
- `/api/v1/expenses/**` and `/api/v1/revenue/**` (period-aware list and summary via `FinanceStatsService`)
- `/api/v1/customers/**` (real multi-tenant customer CRUD, search, soft archive, financial summary)
- `/api/v1/invoices/**` (real invoice lifecycle, draft editing, issue, cancel, idempotent payment recording, summary)
- `/api/v1/recurring-transactions/**` (CRUD, pause/resume, idempotent manual/scheduled execution)
- `/api/v1/receipts/**` (private MinIO upload with magic-byte validation, list, presigned download URL, streaming download, delete)
- `/api/v1/budgets/**` (overall & category expense budgets, live spending & alerts summary)
- `/api/v1/reports/**` (P&L, Cash Flow, comparisons, CSV & OpenPDF exports)
- `/api/v1/subscription/**` (plans, trials, entitlements, atomic usage quotas)
- `/api/v1/currencies/**` (live FX quotes, rate alerts, non-destructive base currency updates)
- `/api/v1/user/**` (profile, sessions, deletion preflight, safe account deletion)
- `/api/v1/health`

See `AFAB_BACKEND_CONTEXT.md` for endpoint details.

## 8. Database and tenant isolation
- Flyway migrations are in `backend/src/main/resources/db/migration/`; migrations **V1 through V23** are active and verified on PostgreSQL 16.
- `business_members` table provides many-to-many user-to-business mappings with roles (`OWNER`, `ADMIN`, `MEMBER`).
- Every financial record (`Transaction`, `Category`, `Customer`, `Invoice`, `Payment`, `RecurringTransaction`, `Receipt`, `Budget`) is strictly scoped by `business_id`.
- Tenant isolation is strictly enforced server-side: foreign `X-Business-Id` or direct cross-tenant entity IDs return `403 Forbidden`.
- Forward-only migrations rule: Never edit an already-applied Flyway migration; always add a new versioned migration.

## 9. Security posture & operational status (updated post-P0)
- **Completed in P0:** Safe placeholders in `.env.example`, zero hardcoded secrets in `application.yml`, fail-fast `SecurityConfigurationValidator`, sanitized logging (`LogSanitizer`), HttpOnly/Secure/SameSite cookie refresh tokens with SHA-256 DB hashing + rotation + family reuse revocation, memory-only frontend access tokens (zero `localStorage` tokens), double-submit CSRF + Origin checks, Redis Lua `DistributedRateLimiter` + trusted-proxy `ClientIpResolver`, `ON DELETE RESTRICT` + safe account deletion & ownership transfer, and automated security/tenant-isolation/integration tests.
- **Manual external action still required before production:** Rotate/revoke all credentials that previously existed in local `.env` or early Git history (SMTP App Password, PostgreSQL password, JWT secret, MinIO keys). See `project/backend/PRODUCTION_CHECKLIST.md`.

## 10. AI coding-agent protocol
Before changing code:
1. Read this file and the relevant specialized context.
2. Inspect target files and adjacent service/controller/tests/migrations.
3. Determine whether the feature is implemented, partial, mock-only, or only specified in docs.
4. Check naming, DTOs, API conventions, localization, design tokens, and error handling.
5. Identify security, tenant-isolation, migration, and compatibility implications.
6. Make the smallest coherent change; avoid broad rewrites.
7. Add/update tests and docs as appropriate.
8. Run relevant checks and report exact commands/results. Never claim checks passed if they were not run.
9. Summarize changed files, behavior, assumptions, gaps, and manual steps.

### Non-negotiable rules
- Do not invent APIs, fields, integrations, or business behavior.
- Do not use mock data as a production fallback that hides API failures.
- Do not weaken auth, validation, or tenant isolation.
- Do not add third-party AI calls without approval.
- Do not implement subscription entitlements only in the frontend.
- Do not change the stack without explicit approval.
- Do not change schema without a forward-only Flyway migration.
- Do not expose secrets in code, logs, examples, commits, or generated docs.
- Preserve AFAB design and English/Arabic support.
- Ask a focused clarification when a requirement conflicts with product rules or requires a consequential architectural decision.

## 11. Visual identity and UX
The existing UI is a premium fintech dashboard: deep navy/black backgrounds, purple accents, green success states, gold premium emphasis, rounded cards, subtle borders/glows, charts, and Lucide icons. References include `frontend/app/globals.css`, `frontend/lib/design-tokens.ts`, frontend design-system documents, and supplied screenshots.

- Reuse components and design tokens.
- Keep layout responsive and accessible.
- Maintain true RTL support for Arabic.
- Avoid hardcoded English labels in localized screens.
- Use consistent loading, empty, error, and success states.
- Never present sample financial data as real.

## 12. Validation checklist
- [ ] Requirements compared with implementation.
- [ ] Frontend contract matches backend DTOs/status codes.
- [ ] Server-side authorization and business scope verified.
- [ ] Input validation and errors handled.
- [ ] Loading, empty, error, and success states implemented.
- [ ] English/Arabic and RTL checked.
- [ ] Responsive behavior/accessibility checked.
- [ ] Database migration is forward-only and safe.
- [ ] Tests added/updated and checks actually run.
- [ ] OpenAPI/docs updated if API changed.
- [ ] No secrets, real customer data, or false AI/payment claims introduced.

## 13. Source references
- Product overview: `New MD/AFAB_Project_Summary.md`
- Product rules: `New MD/Product Rules & Guiding Principles.md`
- Architecture proposal: `New MD/AFAB-architecture-plan.md`
- PRD: `PRD/1-Product Requirements Document (PRD).md`
- Backend config: `project/backend/pom.xml`, `project/backend/src/main/resources/application.yml`
- Migrations: `project/backend/src/main/resources/db/migration/`
- Frontend routes/dependencies: `project/frontend/package.json`, `project/frontend/app/[locale]/`
- Frontend API: `project/frontend/lib/api/`
- Frontend design: `project/frontend/app/globals.css`, `project/frontend/lib/design-tokens.ts`
- Backend production checklist: `project/backend/PRODUCTION_CHECKLIST.md`
