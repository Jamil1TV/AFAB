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
- `GET /mine` — current user's business.
- `GET /{id}` — business retrieval after ownership check.
- `PUT /{id}` — business update after ownership check.

`Business` currently has a one-to-one relation to `User` and a unique `user_id`. It contains name, currency, country, timezone, fiscal-year start month, industry/type, contact details, address, logo, status, onboarding, and formatting preferences.

### User — `/api/v1/user`
- `GET /me` — current profile and business/onboarding information.
- `PUT /me` — profile update.
- `GET /me/sessions` — list sessions.
- `DELETE /me/sessions/{tokenId}` — revoke one session.
- `DELETE /me/sessions` — revoke all sessions.

Verify response shapes and resource ownership when touching profile/session functionality.

### Dashboard — `/api/v1/dashboard`
- `GET /summary`

`DashboardService` currently constructs zero-valued KPI metrics and empty transaction/category/reminder/customer lists. This is placeholder-oriented, not evidence of live financial aggregation. Live metrics must derive from persisted transactions and be tested.

### Finance endpoints
- `/api/v1/transactions`: `GET` list (`type`, `categoryId`, `search`, `page`, `size`); `POST` create; `DELETE /{id}`; `GET /categories`.
- `/api/v1/expenses`: `GET` list and `GET /summary`.
- `/api/v1/revenue`: `GET` list and `GET /summary`.
- `/api/v1/invoices`: `GET` list and `GET /summary`.

Expense/revenue/invoice controllers reuse transaction service/query structures. The inspected invoice endpoints query income-type transactions; do not assume a separate invoice entity/workflow exists.

- `/api/v1/health`: health endpoint.

## 5. API contract conventions
- Base path `/api/v1`.
- Use typed request/response DTOs and Jakarta validation.
- Return correct HTTP status codes and stable error shapes (`common/exception/ApiError`, `GlobalExceptionHandler`, `auth/dto/ErrorResponse`).
- UUIDs are used for IDs in inspected entities.
- Validate pagination and impose a maximum page size.
- Preserve contract compatibility or update frontend service interfaces at the same time.
- Export/update OpenAPI specs when contracts change.
- Never leak SQL errors, stack traces, tokens, or sensitive finance data.

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

Flyway is enabled at `classpath:db/migration`; Hibernate `ddl-auto` is `none`. Do not change it to `update` to work around schema mismatch.

Observations:
- Core tables include users, businesses, refresh tokens, audit logs, KYC verifications, verification/reset tokens, categories, and transactions.
- Transactions include business ownership, type, amount, currency, category, description/date, payment method/status, receipt URL, and notes.
- Category `business_id` appears nullable in V7 despite the rule that financial records belong to a business; review system-default category semantics.
- PRD concepts such as budgets, savings goals, investments, notifications, dedicated invoices, and subscriptions do not have complete backend modules in the inspected source/migrations.
- PRD schema documentation may be aspirational; migrations/entity mappings are the operational contract.

Migration rules:
1. Never edit a migration already applied in shared environments.
2. Add a forward-only migration.
3. Review mappings, constraints, indexes, deletion behavior, and backfill.
4. Plan backward compatibility and existing-record handling.
5. Test on target PostgreSQL.
6. Never remove financial data without explicit authorization and a backup plan.

## 7. Business ownership and requested multi-business model

### Current behavior
One business per user is enforced in the product rules and `Business` entity (one-to-one + unique `user_id`).

### Requested limits
- Free: 1 business
- Plus: up to 3 businesses
- Pro: up to 5 businesses

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
- **CORS:** development origins are defaults and `allowCredentials` is true. Restrict production origins and review necessity.
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
| Business | `GET /api/v1/business/mine`, `GET /{id}`, `PUT /{id}` | One business per user currently |
| User | `GET /api/v1/user/me`, `PUT /me`, `GET /me/sessions`, `DELETE /me/sessions/{tokenId}`, `DELETE /me/sessions` | Profile/session |
| Dashboard | `GET /api/v1/dashboard/summary` | Currently zeroed/empty summary structure |
| Transactions | `GET/POST /api/v1/transactions`, `DELETE /{id}`, `GET /categories` | Read/create/delete/categories |
| Expenses | `GET /api/v1/expenses`, `GET /summary` | Via transaction service |
| Revenue | `GET /api/v1/revenue`, `GET /summary` | Income-type transactions |
| Invoices | `GET /api/v1/invoices`, `GET /summary` | Reuses income-type transactions; not a dedicated invoice lifecycle |

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
