# AFAB Backend — AI Engineering Context

> Read `AFAB_AI_PROJECT_CONTEXT.md` first. This describes backend source found in the supplied archive. Static inspection only; compilation, automated tests, and live API verification were not performed.

## 1. Role
The backend is authoritative for identity, authorization, business ownership, financial persistence, reporting, and future subscription entitlements. Never trust the frontend to enforce access control, financial rules, tenant isolation, or plan limits.

## 2. Actual stack
- Java 21
- Spring Boot 4.1.0 declared in `pom.xml`
- Spring Web / REST, Spring Security
- Spring Data JPA / Hibernate
- PostgreSQL driver, Flyway core + PostgreSQL support
- Jakarta Bean Validation
- Spring Mail, Spring Data Redis
- JJWT 0.12.6, Bucket4j, MinIO SDK
- Springdoc OpenAPI 3.0.2
- Maven

Runtime configuration is `src/main/resources/application.yml`; environment example is `project/.env.example`. Never copy credentials or secret values from these files into docs or source.

## 3. Package-by-feature structure
```text
backend/src/main/java/com/afab/
├── AfabApplication.java
├── auth/              # controller/service/DTOs/JWT/tokens
├── business/          # business entity/repository/controller/DTOs
├── common/            # base entity, API errors, global exception handler
├── config/             # security, CORS, Flyway, OpenAPI, startup logging
├── dashboard/          # summary controller/service/DTO
├── finance/
│   ├── controller/    # transactions, expenses, revenue, invoices
│   ├── domain/        # Transaction, Category
│   ├── dto/
│   ├── repository/
│   └── service/       # TransactionService
├── health/
├── mail/               # EmailService + SMTP implementation
├── security/           # AuditService and AuditLog
├── subscription/       # Plan, PlanEntitlement, Subscription, UsageCounter, EntitlementService, SubscriptionController
└── user/               # User entity/controller/repository/profile/session DTOs
```
Maintain package-by-feature organization. Keep controllers thin, rules in services, persistence in repositories, and public contracts in DTOs.

## 4. Modules and endpoints found in source

### Authentication — `/api/v1/auth`
- `POST /register`
- `POST /login`
- `POST /refresh`
- `POST /logout`
- `POST /verify-email`
- `POST /resend-verification`
- `POST /forgot-password`
- `POST /reset-password`
- `POST /forgot-password-link`
- `POST /validate-reset-token`
- `POST /reset-password-token`
- `POST /change-password`

Relevant files: `auth/AuthController.java`, `auth/AuthService.java`, `auth/security/JwtService.java`, `auth/security/JwtAuthenticationFilter.java`, `auth/security/UserDetailsServiceImpl.java`, `auth/domain/*`, `auth/dto/*`.

The project uses bearer JWT authentication and refresh-token persistence. Verify expiry, rotation, reuse, and revocation semantics before changing token logic.

### Business — `/api/v1/business`
- `GET /` — list all businesses/workspaces the authenticated user belongs to.
- `POST /` — create a new business workspace (enforces plan limits: Free=1, Plus=3, Pro=5; assigns user email as default `businessEmail`).
- `GET /mine` — active business for the current context.
- `GET /{id}` — business retrieval after membership authorization check.
- `PUT /{id}` — business update after membership check (OWNER or ADMIN only).
- `DELETE /{id}` — archive business (OWNER only, soft delete).
- `PUT /{id}/switch` — switch user's active business context.

`Business` supports multi-workspace operations via `business_members` (storing `business_id`, `user_id`, `role`, and `status`).

### User — `/api/v1/user`
- `GET /me` — current profile, active business context, and plan tier (`planTier`).
- `PUT /me` — profile update.
- `GET /me/sessions` — list sessions.
- `DELETE /me/sessions/{tokenId}` — revoke one session.
- `DELETE /me/sessions` — revoke all sessions.

### Dashboard — `/api/v1/dashboard`
- `GET /summary`

`DashboardService` is connected to `FinanceStatsService`. It calculates live cash-basis metrics (total revenue, total expenses, net income, profit margin, percentage changes vs previous period, trailing 6-month performance charts, and category breakdowns) directly from persisted transactions.

### Subscription & Entitlements — `/api/v1/subscription`
- `GET /me` — active subscription snapshot, trial status, remaining days, entitlement limits, and current monthly usage counters. Automatically reconciles expired trials.
- `POST /trial` — start 7-day free trial on Plus or Pro (strictly once per user account).
- `POST /switch` — switch active subscription tier (Free, Plus, Pro) and synchronize `users.plan_tier`.

### Finance endpoints
- `/api/v1/categories`: `GET` list (combines global read-only defaults + business custom categories), `POST` create, `PUT /{id}`, `DELETE /{id}` (blocked with 409 + count when referenced by active transactions).
- `/api/v1/transactions`: `GET` list (`type`, `categoryId`, `status`, `paymentMethod`, `startDate`, `endDate`, `taxDeductible`, `search`, `page`, `size`); `POST` create (HTTP 201, supports `taxDeductible`, `taxRate`, and `splitItems`); `PUT /{id}` update; `DELETE /{id}` (soft-delete with deleted_at timestamp); `GET /categories` (backward compatible). Root transactions filter `parentTransaction IS NULL` to prevent split line duplication.
- `/api/v1/expenses`: `GET` list and `GET /summary` (period-aware summaries via FinanceStatsService).
- `/api/v1/revenue`: `GET` list and `GET /summary` (period-aware summaries via FinanceStatsService).
- `/api/v1/invoices`: `GET` list and `GET /summary` (period-aware summaries).
- `/api/v1/currencies`: `GET /rates` (real-time 166-currency FX engine), `GET /convert`, `GET /alerts`, `POST /alerts`.
- `/api/v1/health`: health endpoint.

## 5. API contract conventions
- Base path `/api/v1`. OpenAPI specifications maintained in `contracts/finance.openapi.yaml`, `contracts/identity.openapi.yaml`, and `contracts/subscription.openapi.yaml`.
- Use typed request/response DTOs and Jakarta validation.
- Return correct HTTP status codes and stable error shapes (`common/exception/ApiError`, `GlobalExceptionHandler`, `ResourceNotFoundException` [404], `ForbiddenException` [403], `ConflictException` [409]).
- Quota/Plan enforcement error: HTTP 403 with `code: "PLAN_LIMIT_REACHED"`, including `feature`, `limit`, `used`, and `upgradeTo`.
- UUIDs are used for IDs in inspected entities.
- Validate pagination and impose a maximum page size (<= 100).
- Multi-tenancy header: `X-Business-Id` is resolved and membership validated on every request.

## 6. Database and migrations
Flyway migrations found:
- `V1__init.sql`
- `V2__verification_tokens.sql`
- `V3__business_onboarding_fields.sql`
- `V4__add_user_avatar.sql`
- `V5__extend_business_profile.sql`
- `V6__add_user_preferences.sql`
- `V7__transactions.sql`
- `V8__password_reset_tokens.sql`
- `V9__add_updated_at_to_categories.sql`
- `V10__finance_core.sql` (transactions.amount NUMERIC(19,4), deleted_at TIMESTAMPTZ, unique index on custom categories per business)
- `V11__transaction_tax_and_splits.sql` (tax rate, tax deductible, split line items table)
- `V12__security_lockout_and_2fa.sql` (TOTP 2FA secret/backup codes, failed login counter, lockout_until)
- `V13__business_members.sql` (business_members table, OWNER backfill, dropped single-business unique constraint, users.active_business_id, businesses.archived_at)
- `V14__add_user_plan_tier.sql` (users.plan_tier column for subscription limit enforcement)
- `V15__plans_and_entitlements.sql` (plans, plan_entitlements, subscriptions, usage_counters with atomic increment; Free/Plus/Pro matrices; backfill existing users)

Flyway is enabled at `classpath:db/migration`; Hibernate `ddl-auto` is `none`.

## 7. Business ownership and multi-business model (Phase 4 Completed)
- Multi-business is fully operational.
- The `business_members` table handles many-to-many relationships and permissions.
- Limits per subscription tier:
  - **Free**: 1 business
  - **Plus**: up to 3 businesses
  - **Pro**: up to 5 businesses
- `CurrentBusinessService` resolves `X-Business-Id` and throws `ForbiddenException` (403) on unauthorized cross-tenant requests.
- `AuthService.resolveUserActiveBusiness` safely resolves the active business on login/refresh without 1:1 unique constraint assumptions.

This conflicts with the current data model. Do not merely remove the unique constraint.

### Design required before implementation
1. One-to-many user/business ownership, or explicit membership model if collaboration is planned.
2. Business membership/role model if users can access businesses owned by others.
3. Server-side plan/entitlement source of truth.
4. Transactional business-creation limit check safe under concurrent requests.
5. Active-business selection and secure context propagation.
6. Scope all transactions/categories/reports to the authorized business.
7. Forward-only migration and backfill.
8. APIs to list/create/select/update/delete businesses.
9. Cross-business/cross-user access and plan-cap tests.
10. A plan for existing users/subscriptions.

Until implemented, do not claim multi-business support is functional.

## 8. Security architecture and critical cautions

Mechanisms found: Spring Security filter chain, JWT filter/service, BCrypt encoder, CORS config, Bucket4j rate-limit bucket in auth controller, audit service/log repository, verification/reset token persistence, SMTP service. `PRODUCTION_CHECKLIST.md` records hardening work.

Critical items:
- **Credential exposure:** archive config includes credential-like values. If real or committed/shared, revoke and rotate. Do not reproduce them in docs.
- **JWT defaults:** configuration contains a default signing secret. Production must fail fast if a strong `JWT_SECRET` is missing; use high entropy and secret management.
- **SMTP credentials:** do not use committed credentials; rotate any exposed app password.
- **One-time tokens:** production checklist says verification/reset token values are stored in plain form. Hash them before persistence and verify securely.
- **CORS:** development origins are defaults and `allowCredentials` is true. Restrict production origins and review necessity. `CorsConfig` explicitly exposes `Content-Disposition`, `Content-Type`, and `X-Business-Id` to allow clients to receive export filenames and tenant IDs.
- **Rate limiting:** a bucket created inside the controller is local to that instance, not a shared distributed limiter. Verify its scope and behavior; add tests.
- **JWT lifecycle:** test refresh rotation/reuse/revocation, logout, expiry, and concurrent refreshes.
- **Authorization:** every UUID-addressed resource must be ownership-checked server-side.
- **Audit logs:** do not record secrets or sensitive financial payloads.
- **Validation:** validate enum/type, dates, amounts, currencies, text lengths, and page sizes.
- **Money:** use `BigDecimal`, not binary floating point, for authoritative monetary calculations.
- **Privacy:** least privilege; minimize PII in logs/responses.

## 9. Configuration and local runtime
`application.yml` reads environment variables for PostgreSQL, JWT, mail, Redis, frontend URL, CORS, and MinIO. Default backend port is 8080. Swagger/OpenAPI paths are configured there.

Before local run:
1. Review `project/docker-compose.yml`.
2. Create a local untracked `.env` from a sanitized template and replace every secret with local-only values.
3. Never commit `.env`.
4. Confirm PostgreSQL, Redis, MinIO, and SMTP settings match services actually running.
5. Apply Flyway migrations and inspect logs.
6. Use synthetic finance data only.

The checked-in `.env.example` includes credential-like content and should be sanitized before sharing. Examples should be clearly fake and require real values through environment variables.

## 10. AI and subscriptions
Product docs say AI is excluded from MVP and third-party AI/LLM APIs are prohibited; future AI is envisioned as self-hosted/internal. No complete AI controller/service was found.

- Do not add third-party AI without explicit approval.
- Do not describe deterministic summaries as model-generated AI.
- If AI is approved later, define privacy, tenant isolation, model hosting, auditability, failure modes, and inference cost controls.

The inspected backend controller inventory has no complete subscription, checkout, webhook, or entitlement API:
- Do not trust plan names from the client.
- Store subscription state server-side when implemented.
- If payment provider is added, verify webhook signatures, idempotency, and lifecycle events.
- Enforce feature limits server-side.
- Do not fake payment success or claim billing is live.

## 11. Testing expectations
Add/update tests according to risk:
- Service unit tests and financial calculation tests.
- Controller/API tests for validation, status codes, response shape.
- Security tests for unauthenticated access and ownership boundaries.
- PostgreSQL/Flyway integration tests.
- Token lifecycle tests.
- Tenant-isolation tests for every business-owned endpoint.
- Multi-business/plan-limit tests before release.
- Currency precision, date boundaries, empty datasets, and pagination tests.

Useful checks from `project/backend/`:
```bash
./mvnw test
./mvnw verify
```
Use the wrapper only if present; otherwise use `mvn test` / `mvn verify`. Never claim a check passed unless run.

## 12. AI agent rules
1. Read shared context and inspect controller, service, repository, entity, DTO, migration, and tests before editing.
2. Treat source/migrations as implementation evidence and PRD docs as intent.
3. Keep controllers thin; rules belong in services.
4. Use constructor injection, DTOs, validation, and consistent errors.
5. Derive business scope server-side.
6. Use transactions for atomic multi-step changes.
7. Use `BigDecimal` for money and explicit timezone/date semantics.
8. Use forward-only Flyway migrations.
9. Update frontend contracts/OpenAPI when public APIs change.
10. Avoid unrelated refactors and unnecessary dependencies.
11. Never add or reveal credentials.
12. Never claim AI, billing, or multi-business support exists without end-to-end verification.
13. Run relevant tests and report actual results.
14. Summarize changed files, migrations, security implications, and manual deployment steps.

## 13. Endpoint quick reference

| Area | Endpoint(s) observed | Notes |
|---|---|---|
| Health | `GET /api/v1/health` | Verify response/probes before deployment |
| Auth | `POST /api/v1/auth/register`, `/login`, `/refresh`, `/logout`, `/verify-email`, `/resend-verification`, `/forgot-password`, `/reset-password`, `/forgot-password-link`, `/validate-reset-token`, `/reset-password-token`, `/change-password` | Review DTOs and lifecycle security |
| Business | `GET /api/v1/business/`, `POST /`, `GET /mine`, `GET /{id}`, `PUT /{id}`, `DELETE /{id}`, `PUT /{id}/switch` | Multi-workspace management with plan limits (1/3/5) |
| User | `GET /api/v1/user/me`, `PUT /me`, `GET /me/sessions`, `DELETE /me/sessions/{tokenId}`, `DELETE /me/sessions` | Profile/session and planTier |
| Dashboard | `GET /api/v1/dashboard/summary` | Cash-basis live financial KPIs via FinanceStatsService |
| Subscription | `GET /api/v1/subscription/me`, `POST /trial`, `POST /switch` | Entitlements, usage quotas, 7-day trials, plan tier switching |
| Transactions | `GET/POST /api/v1/transactions`, `DELETE /{id}`, `GET /categories` | Read/create/delete/categories |
| Expenses | `GET /api/v1/expenses`, `GET /summary` | Via transaction service |
| Revenue | `GET /api/v1/revenue`, `GET /summary` | Income-type transactions |
| Invoices | `GET /api/v1/invoices`, `GET /summary` | Income transactions summary & invoices list |
| Reports | `GET /api/v1/reports/profit-loss`, `/cash-flow`, `/comparison`, `/export/csv`, `/export/pdf` | P&L, Cash Flow, Comparative stats, RFC 4180 CSV & OpenPDF exports with quota consumption |

## 14. Backend change checklist
- [ ] Existing behavior and relevant code inspected.
- [ ] Product-rule conflicts identified.
- [ ] DTO validation/error contracts handled.
- [ ] Ownership/tenant authorization tested.
- [ ] Monetary calculations use safe precision.
- [ ] Schema changes are forward-only Flyway migrations.
- [ ] No secrets/sensitive data in source or logs.
- [ ] OpenAPI/frontend contracts updated where needed.
- [ ] Unit/integration/security tests added.
- [ ] Build/tests actually run and results reported.
- [ ] Deployment/configuration/migration steps documented.

## Mandatory API Contract Documentation Rule

**Every new, modified, or removed API endpoint MUST be reflected in the backend's `contract/` folder whenever the change affects the public API. This requirement is mandatory and must not be skipped.**

### Before implementing an endpoint
1. Inspect the existing `contract/` folder and identify the relevant contract file.
2. Check whether the endpoint already exists in the documented API.
3. Follow the existing contract structure, naming conventions, and documentation format.
4. Determine whether the proposed change affects existing consumers or requires a versioned contract update.

### After implementing an endpoint
Update the relevant contract documentation to accurately reflect the implementation, including:

- HTTP method and complete endpoint path.
- Purpose and expected behavior.
- Authentication and authorization requirements.
- Path parameters, query parameters, headers, and request body.
- Request and response schemas, including field types and nullability.
- Successful HTTP status codes and error responses.
- Validation rules and relevant business constraints.
- Pagination, filtering, sorting, and examples where applicable.
- Business ownership and tenant-isolation requirements.
- Subscription-plan restrictions and usage limits when applicable.

### Contract synchronization requirements
1. The contract must describe the actual implemented behavior, not an intended or hypothetical implementation.
2. Update existing contract files rather than creating duplicate documentation.
3. If the project uses OpenAPI, update the appropriate OpenAPI specification and keep it synchronized with the contract documentation.
4. If the frontend consumes the endpoint, update its API types, service interfaces, and relevant integration tests.
5. Never silently introduce breaking API changes. Document the impact and obtain approval when required.
6. If an endpoint is removed or deprecated, update the contract and clearly document its status.
7. Never mark contract documentation as complete if it has not been verified against the implementation.

### Definition of Done

A backend endpoint change is not complete until:

- The implementation is complete.
- Request and response contracts are accurate.
- The relevant files in `contract/` are updated.
- Related frontend contracts are synchronized when necessary.
- Appropriate tests are added or updated.
- Relevant tests and build checks have been executed, with their actual results reported.

**Final reporting:** Always list the contract files created or updated alongside the implementation files. If no contract file was changed, explain why and identify any remaining documentation work.