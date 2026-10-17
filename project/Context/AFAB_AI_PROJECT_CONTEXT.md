# AFAB — AI Project Context
> **Purpose:** Read this file before changing AFAB. It is the shared source of truth for AI coding agents working across the frontend and backend.
>
> **Audit basis:** Static inspection of the supplied `AFAB-master.zip`, including application source, package/build files, database migrations, PRD notes, and design assets. No build, tests, database migration, or live runtime verification was performed. Treat anything marked “needs verification” as unverified.

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

## 5. Current implementation status (static source review)

### Backend modules evident in source
- Authentication: registration, login, refresh, logout, email verification, resend verification, forgot/reset password, password change.
- User profile and session management.
- Business profile and onboarding fields.
- Dashboard summary endpoint.
- Transactions and categories; expense/revenue/invoice read endpoints and summaries.
- Health endpoint.
- Audit-log infrastructure and SMTP email service.

### Frontend areas evident in source
- Public landing page and dashboard UI.
- Signup/login, forgot/reset password, email verification, onboarding.
- Dashboard, transactions, expenses, revenue, invoices, AI screen, plans/upgrade, settings.
- English/Arabic localized routing.
- Theme provider/toggle and design-system CSS.
- API service wrappers under `frontend/lib/api/`.
- Sample data in `frontend/lib/mock-data.ts`; audit individual screens to determine whether they use API data, placeholders, or local sample data.

### Not proven complete
The PRD and mockups mention budgets, savings goals, investments, recurring transactions, notifications, customer management, integrations, report exports, receipts, subscriptions/billing, team management, and AI recommendations/forecasting. The current backend controller inventory does not show complete API modules for many of these. Verify source, persistence, endpoints, and tests before describing them as implemented.

## 6. Product decisions and inconsistencies

### 6.1 AI scope
Product summaries and rules say AI is excluded from MVP and prohibit third-party AI/LLM APIs; future AI is envisioned as self-hosted/internal. The frontend contains AI-themed UI, but the inspected backend does not show a complete AI inference service.

**Agent rule:** Do not integrate OpenAI, Anthropic, Gemini, or another third-party AI API unless the owner explicitly changes this rule. Distinguish UI, placeholders, deterministic analytics, and actual model-backed capabilities. Never fabricate AI outputs or imply a model is connected when it is not.

### 6.2 Multi-business support
Existing product rule PR-001 and backend `Business` entity enforce **one business per user** (one-to-one relation and unique `user_id`). The user has since requested pricing limits:
- Free: 1 business
- Plus: up to 3 businesses
- Pro: up to 5 businesses

The backend does not yet show a complete subscription/entitlement system or multi-business model.

**Agent rule:** Treat this as a new product requirement requiring backend/database/authz work, not merely pricing-card text. Design ownership/membership, active-business context, tenant isolation, and server-enforced limits. UI-only limits are not security controls. Preserve current behavior until a migration is planned and approved.

### 6.3 Pricing and checkout
Plan UI contains locally defined data and local UI state. A visual “trial” or “checkout success” state is not proof of payment-provider integration. Mockup prices are Free `$0`, Plus `$9.99/month`, Pro `$19.99/month`; treat these as proposals until confirmed. Do not claim subscriptions, renewals, cancellations, trials, invoices, or entitlements work without verified backend/payment integration.

### 6.4 Requirements vs implementation
PRD/schema documents include aspirational features. A requirement document is not implementation evidence. Prefer current source and migrations for actual behavior; preserve future requirements separately.

## 7. API conventions
- Backend base path: `/api/v1`.
- Use request/response DTOs, validation, correct status codes, and consistent errors.
- Do not expose JPA entities directly as public API contracts.
- Use pagination/filtering for growing lists.
- Financial calculations must derive from persisted data and be tested for currency, rounding, and date edge cases.
- Update frontend wrappers and OpenAPI documentation when contracts change.

Controllers found in source:
- `/api/v1/auth/**`
- `/api/v1/business/**`
- `/api/v1/dashboard/summary`
- `/api/v1/transactions/**`
- `/api/v1/expenses/**`
- `/api/v1/revenue/**`
- `/api/v1/invoices/**`
- `/api/v1/user/**`
- `/api/v1/health`

See `AFAB_BACKEND_CONTEXT.md` for endpoint details and gaps.

## 8. Database and tenant isolation
- Flyway migrations are in `backend/src/main/resources/db/migration/`; migrations V1 through V9 are present.
- Current `Business` model maps one user to one business.
- Transactions are associated with a business. Category `business_id` appears nullable in V7 and should be reviewed against the “every financial record belongs to a business” rule.
- Derive and validate business scope from the authenticated user/server-side authorization. Never trust a client-supplied `businessId` alone.
- Never edit an already-applied Flyway migration; add a forward-only migration.
- Do not delete or rewrite financial data as a shortcut.

## 9. Security and operational warnings
**The supplied archive contains credential-like values in environment/config files.** They are intentionally not reproduced here.

Before sharing or production deployment:
1. Revoke/rotate any real SMTP app password or credential included in the archive or committed to Git.
2. Rotate JWT signing secrets and database/MinIO credentials; use environment variables or a secret manager.
3. Remove unsafe production secret defaults; fail fast when required production secrets are missing.
4. Verify access/refresh token storage, XSS exposure, refresh rotation/revocation, cookie attributes, logout, and expiry.
5. Hash one-time verification/reset tokens; the production checklist says they are currently stored as plain tokens.
6. Restrict CORS to exact production origins and review whether credentials are needed.
7. Never log passwords, tokens, personal data, or financial data.
8. Verify rate limiting across users, IPs, and instances; an in-memory bucket is not a distributed global limiter.
9. Verify authorization for every ID-addressed resource and session-revocation operation.
10. Add automated security and integration tests before production.

The frontend stores access and refresh tokens in `localStorage` and mirrors the access token into a JavaScript-written cookie used by route middleware. This has security trade-offs; evaluate a server-managed `HttpOnly; Secure; SameSite` cookie/BFF design before production. A route redirect is UX only, not backend authorization.

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
