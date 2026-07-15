# AFAB Architecture and Build Plan

Status: approval draft  
Project: AFAB - AI Finance Assistant  
Stack: Laravel 12, PHP 8.4, MySQL, Sanctum, React 19, Vite, TailwindCSS  
Brand source of truth: uploaded AFAB identity image

## 1. Complete Software Architecture

AFAB will be a production-ready personal finance platform with a Laravel REST API and a React SPA frontend.

Core principles:
- Feature-based modules on both backend and frontend.
- REST API versioned under `/api/v1`.
- Sanctum authentication for SPA/session security.
- Server-side validation through Laravel Form Requests.
- Authorization through Laravel Policies.
- Business logic in Services.
- Data access in Repositories where queries become non-trivial.
- API Resources for consistent response shape.
- TanStack Query for frontend server-state management.
- React Hook Form and Zod for frontend validation.
- TailwindCSS only for UI styling.
- AI Assistant is placeholder-only in v1.

High-level layers:
- Client: React SPA, React Router, Tailwind, Recharts, Heroicons.
- API: Laravel controllers, requests, policies, resources, middleware.
- Domain: services, repositories, events, jobs.
- Data: MySQL, Eloquent models, migrations, indexes, foreign keys.
- Infrastructure: Docker, `.env`, queues, logs, cache, storage.

Brand implementation:
- Primary: `#0A2540`
- Secondary: `#2563EB`
- Accent: `#10B981`
- White: `#FFFFFF`
- Dark gray: `#1F2937`
- Light gray: `#F5F7FA`
- Font: Inter
- UI feel: clean dashboard, rounded corners, soft shadows, generous spacing, Stripe/Linear/Notion quality.

## 2. Folder Structure

Backend:

```text
app/
  Actions/
  Events/
  Exceptions/
  Http/
    Controllers/Api/V1/
      Auth/
      Dashboard/
      Income/
      Expense/
      Budget/
      Goal/
      Investment/
      Report/
      Notification/
      Setting/
    Middleware/
    Requests/
    Resources/
  Jobs/
  Models/
  Policies/
  Repositories/
  Services/
bootstrap/
config/
database/
  factories/
  migrations/
  seeders/
routes/
  api.php
  auth.php
storage/
tests/
  Feature/
  Unit/
```

Frontend:

```text
src/
  assets/
    brand/
  components/
    common/
    forms/
    charts/
    finance/
    layout/
  context/
  hooks/
  layouts/
    AuthLayout.jsx
    AppLayout.jsx
    MarketingLayout.jsx
  pages/
    marketing/
    auth/
    dashboard/
    income/
    expenses/
    budgets/
    goals/
    investments/
    reports/
    notifications/
    settings/
  routes/
  services/
    apiClient.js
    authService.js
    incomeService.js
    expenseService.js
  utils/
  styles/
```

## 3. Database ER Diagram - Text

```text
users 1--1 user_settings
users 1--many categories
users 1--many incomes
users 1--many expenses
users 1--many budgets
users 1--many savings_goals
users 1--many investments
users 1--many notifications

categories 1--many incomes
categories 1--many expenses
categories 1--many budgets

incomes 1--0/1 income_recurring_rules
expenses 1--0/1 expense_recurring_rules
expenses 1--0/1 expense_receipts
```

## 4. Database Schema

Main tables:

```text
users
- id, name, email, email_verified_at, password, remember_token, timestamps, soft_deletes
- unique: email

user_settings
- id, user_id, currency, locale, timezone, dark_mode, monthly_budget_start_day, notification_preferences_json, timestamps
- unique: user_id

categories
- id, user_id, name, type(income|expense), color, icon, is_default, timestamps, soft_deletes
- indexes: user_id, type

incomes
- id, user_id, category_id, title, amount, received_at, source, notes, is_recurring, timestamps, soft_deletes
- indexes: user_id, category_id, received_at

income_recurring_rules
- id, income_id, frequency(daily|weekly|monthly|yearly), interval, starts_at, ends_at, next_run_at, timestamps
- unique: income_id

expenses
- id, user_id, category_id, title, amount, spent_at, merchant, payment_method, notes, is_recurring, timestamps, soft_deletes
- indexes: user_id, category_id, spent_at, amount

expense_recurring_rules
- id, expense_id, frequency(daily|weekly|monthly|yearly), interval, starts_at, ends_at, next_run_at, timestamps
- unique: expense_id

expense_receipts
- id, expense_id, file_path, original_name, mime_type, file_size, timestamps
- unique: expense_id

budgets
- id, user_id, category_id nullable, name, amount, period(monthly|yearly|custom), starts_at, ends_at, alert_threshold_percent, timestamps, soft_deletes
- indexes: user_id, category_id, starts_at, ends_at

savings_goals
- id, user_id, name, target_amount, current_amount, deadline, status(active|completed|paused), timestamps, soft_deletes
- indexes: user_id, status, deadline

investments
- id, user_id, name, type(stock|crypto|fund|real_estate|other), quantity, purchase_price, current_value, invested_amount, return_percent, notes, timestamps, soft_deletes
- indexes: user_id, type

notifications
- id, user_id, type, title, body, data_json, read_at, timestamps
- indexes: user_id, read_at, type
```

Laravel/Sanctum support tables:

```text
personal_access_tokens
password_reset_tokens
cache
jobs
failed_jobs
sessions
```

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

Account management:

```text
Profile -> edit name/email -> verify changed email if needed
Security -> change password
Danger zone -> delete account confirmation
Forgot password -> email reset link -> reset password
```

## 6. API Endpoints

Authentication:

```text
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
GET    /api/v1/auth/user
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password
POST   /api/v1/auth/email/verification-notification
GET    /api/v1/auth/email/verify/{id}/{hash}
```

Profile and settings:

```text
GET    /api/v1/profile
PATCH  /api/v1/profile
PATCH  /api/v1/profile/password
DELETE /api/v1/profile
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
- AppShell
- Sidebar
- Topbar
- MobileNav
- PageHeader
- Breadcrumbs
- ThemeToggle

Common UI:
- Button
- IconButton
- Card
- StatCard
- EmptyState
- Modal
- Drawer
- Toast
- Badge
- ProgressBar
- Tabs
- Pagination
- SearchInput
- FilterMenu
- DateRangePicker

Forms:
- FormField
- MoneyInput
- SelectField
- CategorySelect
- RecurringRuleFields
- ReceiptUploader
- ConfirmDeleteDialog

Charts:
- LineChartCard
- DonutChartCard
- BarChartCard
- IncomeExpenseChart
- ExpenseBreakdownChart

Finance:
- TransactionTable
- IncomeForm
- ExpenseForm
- BudgetForm
- GoalForm
- InvestmentForm
- BudgetProgressCard
- GoalProgressCard
- InvestmentPerformanceCard
- NotificationList

## 9. Development Roadmap

Phase 1: Foundation
- Laravel 12 project setup
- React 19/Vite setup
- Tailwind theme with AFAB brand tokens
- Docker and `.env.example`
- API versioning and base error format

Phase 2: Authentication
- Register, login, logout
- Forgot/reset password
- Email verification
- Profile, change password, delete account
- Sanctum SPA protection

Phase 3: Core Finance
- Categories
- Income CRUD
- Expense CRUD
- Receipt upload
- Search, filters, pagination

Phase 4: Planning
- Budgets
- Savings goals
- Alerts and notifications

Phase 5: Investments and Reports
- Manual investment tracking
- Monthly/yearly reports
- Category analysis
- CSV/PDF export

Phase 6: Dashboard and Polish
- Dashboard summary
- Charts
- Responsive layouts
- Dark mode
- Accessibility pass
- Testing and deployment readiness

## 10. Milestones

Milestone 1:
- Approve this architecture.

Milestone 2:
- Scaffold Laravel and React projects.

Milestone 3:
- Implement auth and profile flows.

Milestone 4:
- Implement income, expenses, and categories.

Milestone 5:
- Implement budgets, goals, investments, notifications.

Milestone 6:
- Implement dashboard, reports, exports.

Milestone 7:
- Final QA, tests, Docker, deployment documentation.

Each milestone should be approved before moving to the next.

## 11. Suggested Packages

Shared tooling:
- Docker Compose
- MySQL 8
- Mailpit for local email
- Redis optional for cache/queues
- GitHub Actions optional for CI

Quality:
- ESLint
- Prettier
- Laravel Pint
- Pest or PHPUnit
- React Testing Library optional

## 12. Laravel Packages

Required:
- `laravel/sanctum`
- `laravel/tinker`

Recommended:
- `barryvdh/laravel-dompdf` for PDF export
- `maatwebsite/excel` for CSV/Excel-style exports, if advanced export formatting is needed
- `spatie/laravel-permission` only if roles/teams are added later
- `spatie/laravel-query-builder` only if filtering becomes complex
- `pestphp/pest` for clean tests, if preferred over PHPUnit

## 13. React Packages

Required:
- `react`
- `react-dom`
- `vite`
- `react-router-dom`
- `axios`
- `@tanstack/react-query`
- `react-hook-form`
- `zod`
- `@hookform/resolvers`
- `@heroicons/react`
- `recharts`
- `tailwindcss`

Recommended:
- `clsx`
- `tailwind-merge`
- `date-fns`
- `lucide-react` only if Heroicons lacks a needed icon

## 14. Future AI Integration Plan

V1 must not include chatbot, LLM calls, OpenAI, Claude, Gemini, or AI recommendations.

For now:
- Add an AI Assistant placeholder page.
- Add disabled dashboard insight cards with static copy such as "Coming soon".
- Add backend placeholder status endpoint only.
- Keep all AI-related code behind a feature flag such as `AI_ASSISTANT_ENABLED=false`.

Future architecture:
- `AssistantController`
- `AssistantService`
- `InsightGenerationJob`
- `assistant_conversations` table
- `assistant_messages` table
- `financial_insights` table
- Provider abstraction for future LLM vendors
- Consent controls for using financial data in AI workflows
- Audit logs for generated insights
- Rate limits and usage tracking

Approval checkpoint:
- No application code should be written until this architecture is approved.
