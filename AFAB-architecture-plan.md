# AFAB Architecture and Build Plan

Status: approved direction (v2) — supersedes the original Laravel/React draft
Project: AFAB - AI Finance Assistant for Business
Stack: Spring Boot 4.1, Java 21 (LTS), PostgreSQL 18, Spring Security (JWT), Next.js 16 (App Router), shadcn/ui, TailwindCSS
Team: Farouk (backend), Jamil (frontend)
Brand source of truth: uploaded AFAB identity image

## 1. Complete Software Architecture

AFAB is a production-ready business finance platform: a Spring Boot REST API backend and a Next.js frontend, communicating over a versioned REST contract.

Core principles:
- Modular monolith on the backend — package-by-feature (income, expenses, budgets, goals, investments, reports, notifications, settings, assistant), not microservices. Each module is self-contained enough to be split out later if it ever needs to scale independently.
- REST API versioned under `/api/v1`.
- Spring Security + JWT (access + refresh tokens), proxied through Next.js as a backend-for-frontend (BFF) layer so the browser never talks to Spring Boot directly and Spring Boot never needs to open CORS to public origins.
- Server-side validation via Jakarta Bean Validation.
- Business logic in Services, data access via Spring Data JPA repositories (native SQL for reporting/aggregation queries).
- springdoc-openapi generates the OpenAPI contract; the frontend generates a typed client from it.
- Next.js App Router: Server Components for first-paint data (dashboard, reports), TanStack Query for interactive client state (tables, filters, mutations).
- shadcn/ui + Tailwind for UI; React Hook Form + Zod for forms (shadcn's `<Form>` is built on both).
- No global client-side store (Redux) needed — server state lives in TanStack Query, UI-only state in React state/context, with a small Zustand store only if a specific cross-cutting UI concern actually needs one later.
- AI Assistant is placeholder-only in V1, and will be a self-hosted model service in future versions — no third-party AI APIs, ever.

High-level layers:
- Client: Next.js App Router, shadcn/ui, Tailwind, shadcn charts (Recharts), lucide-react.
- API: Spring Boot controllers, DTOs, Spring Security filters, `@ControllerAdvice` exception handling.
- Domain: services, JPA repositories, scheduled jobs (recurring transactions), events.
- Data: PostgreSQL 18, Flyway migrations, JPA entities, indexes, foreign keys.
- Infrastructure: Docker Compose, `.env`, MinIO (S3-compatible receipt storage), Mailpit, optional Redis.

Brand implementation (unchanged):
- Primary: `#0A2540`
- Secondary: `#2563EB`
- Accent: `#10B981`
- White: `#FFFFFF`
- Dark gray: `#1F2937`
- Light gray: `#F5F7FA`
- Font: Inter
- UI feel: clean dashboard, rounded corners, soft shadows, generous spacing, Stripe/Linear/Notion quality.

## 2. Folder Structure

Backend (`afab-backend`):

```text
src/main/java/com/afab/
  config/                # SecurityConfig, CorsConfig, OpenApiConfig, JacksonConfig
  common/
    exception/           # GlobalExceptionHandler, ApiError
    response/            # ApiResponse<T>, PageResponse<T>
    security/            # JwtService, JwtAuthFilter, CurrentUser resolver
  auth/                  # AuthController, AuthService, dto/
  business/              # BusinessController, BusinessService, Business, BusinessRepository
  user/                  # profile, password, delete account, UserSettings
  category/
  income/                # + IncomeRecurringRule
  expense/                # + ExpenseReceipt, ReceiptStorageService (MinIO/S3)
  budget/
  goal/
  investment/
  report/                # ReportQueryRepository (native SQL), export/ (Pdf, Csv)
  notification/
  settings/
  assistant/              # AI placeholder module, flagged off in V1
src/main/resources/
  db/migration/            # Flyway V1__init.sql, V2__..., etc.
  application.yml
  application-local.yml
src/test/java/com/afab/     # mirrors main, feature-based, Testcontainers for Postgres
```

Frontend (`afab-frontend`):

```text
src/
  app/
    (marketing)/           # landing, features, pricing (coming soon), about, contact
    (auth)/                # login, register, forgot/reset password, verify email
    (app)/                 # dashboard, income, expenses, budgets, goals, investments,
                            # reports, notifications, settings, profile
    api/auth/               # Route Handlers acting as the BFF proxy to Spring Boot
    proxy.ts                # route protection (Next.js 16's renamed middleware)
  components/
    ui/                    # shadcn-generated primitives
    forms/
    charts/
    finance/
    layout/
  hooks/
  lib/
    api-client.ts           # typed client generated from the OpenAPI spec
    queries/                # TanStack Query hooks per module
  styles/
```

## 3. Database ER Diagram - Text

```text
users 1--1 businesses
users 1--1 user_settings
users 1--many refresh_tokens

businesses 1--many categories
businesses 1--many incomes
businesses 1--many expenses
businesses 1--many budgets
businesses 1--many savings_goals
businesses 1--many investments
businesses 1--many notifications

categories 1--many incomes
categories 1--many expenses
categories 1--many budgets

incomes 1--0/1 income_recurring_rules
expenses 1--0/1 expense_recurring_rules
expenses 1--0/1 expense_receipts
```

> Fix applied vs the original draft: every financial record now hangs off `businesses`, not `users`, directly implementing PR-001 ("dedicated businesses table") and PR-004 ("every financial record must belong to a business"). `user_settings` keeps only personal preferences (theme, notification prefs); currency/country/timezone move onto `businesses`.

## 4. Database Schema

Main tables:

```text
users
- id, name, email, email_verified_at, password_hash, created_at, updated_at, deleted_at
- unique: email

businesses
- id, user_id, name, currency, country, timezone, fiscal_year_start_month, created_at, updated_at
- FK: user_id -> users.id
- unique: user_id   -- V1 constraint only; drop to unlock multi-business in a future version

user_settings
- id, user_id, dark_mode, locale, notification_preferences_json, created_at, updated_at
- unique: user_id

refresh_tokens
- id, user_id, token_hash, expires_at, revoked_at, device_info, created_at

categories
- id, business_id, name, type(income|expense), color, icon, is_default, created_at, updated_at, deleted_at
- indexes: business_id, type

incomes
- id, business_id, category_id, title, amount, received_at, source, notes, is_recurring, created_at, updated_at, deleted_at
- indexes: business_id, category_id, received_at

income_recurring_rules
- id, income_id, frequency(daily|weekly|monthly|yearly), interval, starts_at, ends_at, next_run_at, created_at
- unique: income_id

expenses
- id, business_id, category_id, title, amount, spent_at, merchant, payment_method, notes, is_recurring, created_at, updated_at, deleted_at
- indexes: business_id, category_id, spent_at, amount

expense_recurring_rules
- id, expense_id, frequency(daily|weekly|monthly|yearly), interval, starts_at, ends_at, next_run_at, created_at
- unique: expense_id

expense_receipts
- id, expense_id, object_key, original_name, mime_type, file_size, created_at
- unique: expense_id

budgets
- id, business_id, category_id nullable, name, amount, period(monthly|yearly|custom), starts_at, ends_at, alert_threshold_percent, created_at, updated_at, deleted_at
- indexes: business_id, category_id, starts_at, ends_at

savings_goals
- id, business_id, name, target_amount, current_amount, deadline, status(active|completed|paused), created_at, updated_at, deleted_at
- indexes: business_id, status, deadline

investments
- id, business_id, name, type(stock|crypto|fund|real_estate|other), quantity, purchase_price, current_value, invested_amount, notes, created_at, updated_at, deleted_at
- indexes: business_id, type
- note: return_percent is computed on read, not stored, to avoid drift against current_value

notifications
- id, business_id, type, title, body, data_json, read_at, created_at
- indexes: business_id, read_at, type

-- AI placeholder tables (flagged off via AI_ASSISTANT_ENABLED=false in V1)
assistant_conversations
assistant_messages
financial_insights
```

Conventions: `numeric(14,2)` for all money columns (never float), `timestamptz` everywhere, `citext` for case-insensitive email matching.

Spring/Postgres support tables: handled by Spring Security (no `personal_access_tokens` table needed — JWTs are stateless; only `refresh_tokens` needs persistence) plus Flyway's own `flyway_schema_history`.

## 5. User Flow

```text
Visitor
-> Landing page
-> Register/Login
-> Email verification
-> Dashboard onboarding
-> Create categories or use defaults
-> Add income and expenses
-> Set budgets and savings goals
-> Add investments manually
-> Review dashboard charts
-> Generate reports or export CSV/PDF
-> Manage notifications and settings
```

Auth flow (BFF pattern):

```text
Browser -> Next.js Route Handler (/api/auth/login) -> Spring Boot (/api/v1/auth/login)
Spring Boot returns { accessToken, refreshToken }
Next.js sets both as httpOnly, Secure, SameSite=Lax cookies on its own domain
Browser never sees a raw token
Subsequent requests: Next.js server forwards the access token to Spring Boot; proxy.ts guards protected routes
```

Account management:

```text
Profile -> edit name/email -> verify changed email if needed
Security -> change password
Danger zone -> delete account confirmation (cascades to business + all financial records)
Forgot password -> email reset link -> reset password
```

## 6. API Endpoints

Authentication:

```text
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
GET    /api/v1/auth/user
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password
POST   /api/v1/auth/email/verification-notification
GET    /api/v1/auth/email/verify/{id}/{hash}
```

Profile, business, and settings:

```text
GET    /api/v1/profile
PATCH  /api/v1/profile
PATCH  /api/v1/profile/password
DELETE /api/v1/profile
GET    /api/v1/business
PATCH  /api/v1/business
GET    /api/v1/settings
PATCH  /api/v1/settings
```

Dashboard:

```text
GET    /api/v1/dashboard/summary
GET    /api/v1/dashboard/recent-transactions
GET    /api/v1/dashboard/charts/income-expense
GET    /api/v1/dashboard/charts/expense-breakdown
```

Finance modules:

```text
GET    /api/v1/categories
POST   /api/v1/categories
GET    /api/v1/categories/{category}
PATCH  /api/v1/categories/{category}
DELETE /api/v1/categories/{category}

GET    /api/v1/incomes
POST   /api/v1/incomes
GET    /api/v1/incomes/{income}
PATCH  /api/v1/incomes/{income}
DELETE /api/v1/incomes/{income}

GET    /api/v1/expenses
POST   /api/v1/expenses
GET    /api/v1/expenses/{expense}
PATCH  /api/v1/expenses/{expense}
DELETE /api/v1/expenses/{expense}
POST   /api/v1/expenses/{expense}/receipt
DELETE /api/v1/expenses/{expense}/receipt

GET    /api/v1/budgets
POST   /api/v1/budgets
GET    /api/v1/budgets/{budget}
PATCH  /api/v1/budgets/{budget}
DELETE /api/v1/budgets/{budget}

GET    /api/v1/goals
POST   /api/v1/goals
GET    /api/v1/goals/{goal}
PATCH  /api/v1/goals/{goal}
DELETE /api/v1/goals/{goal}

GET    /api/v1/investments
POST   /api/v1/investments
GET    /api/v1/investments/{investment}
PATCH  /api/v1/investments/{investment}
DELETE /api/v1/investments/{investment}
```

Reports and notifications:

```text
GET    /api/v1/reports/monthly
GET    /api/v1/reports/yearly
GET    /api/v1/reports/category-analysis
GET    /api/v1/reports/export/csv
GET    /api/v1/reports/export/pdf

GET    /api/v1/notifications
PATCH  /api/v1/notifications/{notification}/read
PATCH  /api/v1/notifications/read-all
DELETE /api/v1/notifications/{notification}
```

AI placeholder:

```text
GET    /api/v1/assistant/status
POST   /api/v1/assistant/feedback-placeholder
```

Every endpoint above (other than auth/register) is scoped server-side to the caller's `business_id` — never trusted from the request body.

## 7. UI Pages

Marketing:
- Landing
- Features
- Pricing coming soon
- About
- Contact

Auth:
- Login
- Register
- Forgot Password
- Reset Password
- Email Verification

Application:
- Dashboard
- Income
- Expenses
- Budgets
- Goals
- Investments
- Reports
- Notifications
- Settings
- Profile Settings
- Change Password
- Delete Account
- AI Assistant placeholder

## 8. Components List

Layout:
- AppShell, Sidebar, Topbar, MobileNav, PageHeader, Breadcrumbs, ThemeToggle

shadcn/ui primitives (generated via `shadcn add`, Base UI by default as of mid-2026, Radix optional):
- Button, Card, Dialog, Drawer, Sheet, Toast (Sonner), Badge, Progress, Tabs, Pagination, Input, Select, Combobox, DatePicker, DataTable

Forms (React Hook Form + Zod + shadcn `<Form>`):
- MoneyInput, CategorySelect, RecurringRuleFields, ReceiptUploader, ConfirmDeleteDialog

Charts (shadcn charts / Recharts):
- LineChartCard, DonutChartCard, BarChartCard, IncomeExpenseChart, ExpenseBreakdownChart

Finance:
- TransactionTable, IncomeForm, ExpenseForm, BudgetForm, GoalForm, InvestmentForm, BudgetProgressCard, GoalProgressCard, InvestmentPerformanceCard, NotificationList

## 9. Development Roadmap

Phase 1: Foundation
- Spring Boot 4.1 + Maven project setup
- Next.js 16 + shadcn/ui setup
- Docker Compose (Postgres 18, MinIO, Mailpit)
- Flyway baseline migration (corrected schema, incl. `businesses`)
- API versioning, `ApiResponse<T>` error format, OpenAPI generation

Phase 2: Authentication
- Register, login, logout, refresh
- Forgot/reset password, email verification
- Profile, change password, delete account
- BFF proxy (Next.js Route Handlers) + JWT flow end-to-end

Phase 3: Core Finance
- Businesses, categories
- Income CRUD, expense CRUD, receipt upload (MinIO)
- Search, filters, pagination

Phase 4: Planning
- Budgets, savings goals
- Alerts and notifications

Phase 5: Investments and Reports
- Manual investment tracking
- Monthly/yearly reports, category analysis
- CSV/PDF export

Phase 6: Dashboard and Polish
- Dashboard summary, charts
- Responsive layouts, dark mode
- Accessibility pass
- Testing (Testcontainers, Vitest, Playwright) and deployment readiness

Phase 7: AI placeholder wiring
- Flagged-off assistant page + backend stub, ready for the self-hosted model service later

## 10. Milestones

Milestone 1: Approve this architecture.
Milestone 2: Scaffold Spring Boot and Next.js projects, Docker Compose, Flyway baseline.
Milestone 3: Implement auth and profile flows end-to-end (incl. BFF proxy).
Milestone 4: Implement businesses, income, expenses, categories.
Milestone 5: Implement budgets, goals, investments, notifications.
Milestone 6: Implement dashboard, reports, exports.
Milestone 7: Final QA, tests, Docker, deployment documentation.

Each milestone should be approved before moving to the next.

## 11. Suggested Infrastructure

Shared tooling:
- Docker Compose (Postgres 18, MinIO, Mailpit, optional Redis)
- GitHub Actions per repo (backend: `mvn verify` incl. Testcontainers; frontend: `vitest` + `next build` + lint)

Quality:
- ESLint, Prettier (frontend)
- Checkstyle or Spotless (backend)
- Pest/PHPUnit — n/a; use JUnit 5 + Mockito + Testcontainers instead
- Playwright (e2e)

## 12. Backend (Java/Spring) Packages

Required:
- `spring-boot-starter-web`
- `spring-boot-starter-security`
- `spring-boot-starter-data-jpa`
- `spring-boot-starter-validation`
- `spring-boot-starter-mail`
- `org.postgresql:postgresql`
- `io.jsonwebtoken:jjwt` (or Spring Authorization Server, if preferred later)
- `org.flywaydb:flyway-core` + `flyway-database-postgresql`

Recommended:
- `org.springdoc:springdoc-openapi-starter-webmvc-ui` (OpenAPI + Swagger UI)
- `com.github.librepdf:openpdf` or `itext` for PDF export
- `org.apache.commons:commons-csv` for CSV export
- `org.testcontainers:postgresql` + `org.testcontainers:junit-jupiter` for integration tests
- `io.minio:minio` (or the AWS S3 SDK, since MinIO is S3-API-compatible) for receipt storage
- `org.quartz-scheduler:quartz` if recurring-transaction generation needs persistence across restarts

## 13. Frontend (Next.js) Packages

Required:
- `next`, `react`, `react-dom`
- `tailwindcss`
- shadcn/ui (installed via CLI, not an npm dependency in the traditional sense — components are copied into `components/ui`)
- `@tanstack/react-query`
- `react-hook-form`, `zod`, `@hookform/resolvers`
- `lucide-react`

Recommended:
- `clsx`, `tailwind-merge`
- `date-fns`
- `recharts` (via shadcn charts)
- `openapi-typescript` (generate a typed client from the backend's OpenAPI spec)
- `zustand` — optional, only if a specific cross-cutting UI state (e.g. a dashboard-wide date-range filter) actually needs one; not a default dependency

## 14. Future AI Integration Plan

V1 must not include any chatbot, LLM calls, or calls to OpenAI, Claude, Gemini, or any other third-party AI API. This restriction is permanent for AFAB, not just a V1 scope limit — the AI roadmap is built entirely on self-hosted/self-trained models.

For now:
- Add an AI Assistant placeholder page.
- Add disabled dashboard insight cards with static copy such as "Coming soon".
- Add a backend placeholder status endpoint only.
- Keep all AI-related code behind a feature flag such as `AI_ASSISTANT_ENABLED=false`.

Future architecture (self-hosted, no external AI vendors):
- `AssistantController` / `AssistantService` in Spring Boot, calling an internal-only Python service over the Docker network (never exposed publicly, never calling out to a third-party AI API).
- The Python service (FastAPI) serves small, purpose-built models: a text classifier for expense categorization, a lightweight time-series model for spending forecasts, a rules+ML blend for the financial health score, an anomaly detector for large-expense alerts.
- Receipt OCR (if pursued) uses a self-hosted OCR engine (e.g. Tesseract or a fine-tuned open-weight vision model), not a cloud OCR/vision API.
- Models are trained offline (versioned artifacts, e.g. ONNX), not inside the request path.
- `assistant_conversations`, `assistant_messages`, `financial_insights` tables (unchanged in shape from the original placeholder design).
- Consent controls for using financial data in AI workflows.
- Audit logs for generated insights.
- Rate limits and usage tracking.

Approval checkpoint:
- No application code should be written until this architecture is approved.
