# 01 — Complete Web Screen, Layout, Component & Overlay Inventory

> **Source Directory:** `C:\Users\MSI\Desktop\DEV\AFAB\Web\project\frontend\app\`
> **Total Files under `app/`:** 41 files (`31 page.tsx` routes, `4 layout.tsx` wrappers, `4 special boundary files`, `1 favicon.ico`, `1 globals.css`).

---

## 1. Exhaustive Web Route Inventory (`app/[locale]/`)

| # | Web File (`app/[locale]/...`) | URL Path | Role & Wrapper | Web Status | Mobile Destination (`screens/...`) |
|---|---|---|---|---|---|
| 1 | `page.tsx` | `/[locale]` | Public marketing landing page (`Navbar`, `HeroSection`, `LogosSection`, `FeaturesSection`, `HowItWorksSection`, `StatsTestimonialSection`, `CTASection`) | UI Only / Marketing (has dead `#pricing`/`#about`/CTA buttons) | **Excluded from Mobile** (Mobile starts at `Splash` → `Login`/`Sign Up`) |
| 2 | `layout.tsx` | `/[locale]/*` | Root locale `<html lang dir>`, Google Fonts, FOUC `<script>`, `NextIntlClientProvider`, `ThemeProvider`, `AppearanceInitializer`, `ChunkErrorRecovery`, `Toaster` | Implemented and Connected | App Root (`AfabApp`, `ThemeEngine`, `LocaleNotifier`) |
| 3 | `loading.tsx` | `/[locale]/*` | Global Suspense fallback (`AfabLoader`) | Implemented (hardcoded EN) | `application/LOADING_AND_SKELETON_STATES.md` |
| 4 | `error.tsx` | `/[locale]/*` | Locale error boundary + chunk recovery + Try Again / Reload | Implemented (hardcoded EN) | `application/ERROR_AND_NOT_FOUND_STATES.md` |
| 5 | `not-found.tsx` | `*` | Bilingual 404 UFO screen (broken `/support` link) | Implemented but Incomplete | `application/ERROR_AND_NOT_FOUND_STATES.md` |
| 6 | `(auth)/layout.tsx` | `/(auth)/*` | Auth split-screen shell + `AnimatedStars` + `AuthHeroGraphic` + `LanguageSwitcher` + `ThemeToggle` | Implemented | Shared `AuthScaffold` |
| 7 | `(auth)/login/page.tsx` | `/login` | Email/password login + inline 2FA OTP/backup challenge (inert Google button) | Implemented but Incomplete | `authentication/LOGIN_SCREEN.md` + `authentication/TWO_FACTOR_CHALLENGE_SCREEN.md` |
| 8 | `(auth)/signup/page.tsx` | `/signup` | Registration (`firstName`, `lastName`, `businessName`, `email`, `password`; inert Google button) | Implemented but Incomplete | `authentication/SIGNUP_SCREEN.md` |
| 9 | `(auth)/verify-email/page.tsx` | `/verify-email` | 6-digit OTP verification + 60s resend cooldown (`devOtp` UI commented out) | Implemented but Incomplete | `authentication/EMAIL_VERIFICATION_SCREEN.md` |
| 10 | `(auth)/forgot-password/page.tsx` | `/forgot-password` | Request password reset link via email | Implemented and Connected | `authentication/FORGOT_PASSWORD_SCREEN.md` |
| 11 | `(auth)/reset-password/page.tsx` | `/reset-password?token=` | Token validation + password reset + `PasswordStrengthIndicator` (**strips `_` bug**) | Implemented but Incomplete | `authentication/RESET_PASSWORD_SCREEN.md` |
| 12 | `(auth)/onboarding/page.tsx` | `/onboarding` | 3-step business setup wizard (Country/Industry/Type → Currency/Timezone/FY → Confirm) | Implemented and Connected | `authentication/ONBOARDING_SCREEN.md` |
| 13 | `(dashboard)/layout.tsx` | `/(dashboard)/*` | Authenticated shell: `Sidebar`, `DashboardHeader`, `LifecycleBanners`, `GlobalCopilotDrawer`, `CopilotContextProvider` | Implemented and Connected | `dashboard/APP_SHELL_AND_MORE_HUB_SCREEN.md` |
| 14 | `(dashboard)/error.tsx` | `/(dashboard)/*` | Re-exports `../error.tsx` | Implemented | `application/ERROR_AND_NOT_FOUND_STATES.md` |
| 15 | `(dashboard)/maintenance/page.tsx` | `/maintenance` | Static fake progress bar placeholder (**wrongly nested inside `(dashboard)` layout**, EN only) | UI Only (broken placement) | `application/MAINTENANCE_SCREEN.md` |
| 16 | `(dashboard)/dashboard/page.tsx` | `/dashboard` | KPIs, RevenueChart, AIInsightsCard, RecentTransactions, ExpenseCategories, Budgets, Reminders, TopCustomers, UpgradeBanner | Implemented but Incomplete | `dashboard/DASHBOARD_SCREEN.md` |
| 17 | `(dashboard)/dashboard/transactions/page.tsx` | `/dashboard/transactions` | Ledger table, filters, KPIs, Manage Categories, Split, Add/Edit/Duplicate, Detail Drawer + Receipts, CSV export | Implemented but Incomplete | `financial/TRANSACTIONS_SCREEN.md` (+ 4 flow specs) |
| 18 | `(dashboard)/dashboard/expenses/page.tsx` | `/dashboard/expenses` | Expense KPIs, Area & Donut charts, table, inline detail modal (`recurringList` stubbed empty) | Implemented but Incomplete | `financial/EXPENSES_SCREEN.md` |
| 19 | `(dashboard)/dashboard/revenue/page.tsx` | `/dashboard/revenue` | Revenue KPIs, Area & Donut charts, table, Gross/Net card, inline modal (`topProducts` stubbed empty) | Implemented but Incomplete | `financial/REVENUE_SCREEN.md` |
| 20 | `(dashboard)/dashboard/customers/page.tsx` | `/dashboard/customers` | Customer KPIs, directory table/mobile cards, donut, Top Customers, Activity, Detail Drawer, Add Customer & Add Order | Implemented but Incomplete | `business/CUSTOMERS_SCREEN.md` + `business/CUSTOMER_DETAILS_SCREEN.md` |
| 21 | `(dashboard)/dashboard/invoices/page.tsx` | `/dashboard/invoices` | Invoice KPIs, table, status filters, Receivables Donut, Upcoming Due, Create/Edit Draft, Detail Drawer, Print/PDF, Record Payment | Implemented but Incomplete | `business/INVOICES_SCREEN.md` + `INVOICE_DETAILS_SCREEN.md` + `CREATE_EDIT_INVOICE_SCREEN.md` + `RECORD_PAYMENT_SHEET.md` |
| 22 | `(dashboard)/dashboard/budgets/page.tsx` | `/dashboard/budgets` | Budget summary KPIs, active budget progress cards, Create/Edit Budget modal, Ask AI, Archive | Implemented and Connected | `business/BUDGETS_SCREEN.md` |
| 23 | `(dashboard)/dashboard/recurring/page.tsx` | `/dashboard/recurring` | Recurring schedules table, Create/Edit modal, Pause/Resume, Run Due Now, Delete/Deactivate | Implemented and Connected | `business/RECURRING_TRANSACTIONS_SCREEN.md` |
| 24 | `(dashboard)/dashboard/calendar/page.tsx` | `/dashboard/calendar` | Client-side Month calendar grid + selected date panel (fetches 100 txs once on mount; hardcoded EN/AR header) | Implemented but Incomplete | `business/FINANCIAL_CALENDAR_SCREEN.md` |
| 25 | `(dashboard)/dashboard/currencies/page.tsx` | `/dashboard/currencies` | Live FX ticker, Featured pairs, BinanceLiveChart (simulated), FxTrajectoryChart (simulated), Converter, Portfolio Impact, Risk Simulator, Alerts (`localStorage`), Directory | Implemented but Incomplete | `intelligence/CURRENCIES_SCREEN.md` + `intelligence/CURRENCY_MIGRATION_SHEET.md` |
| 26 | `(dashboard)/dashboard/reports/page.tsx` | `/dashboard/reports` | Export quota badge, Explain Report, P&L / Cash Flow / Comparison tabs, Backend CSV & OpenPDF download | Implemented but Incomplete | `intelligence/REPORTS_SCREEN.md` |
| 27 | `(dashboard)/dashboard/ai/page.tsx` | `/dashboard/ai` | AFAB Copilot Studio: conversation sidebar, search, quota meter, health badge, RAG sync, Memory drawer, SSE streaming, attachments, voice dictation, drafts, charts | Implemented and Connected | `ai/AI_COPILOT_SCREEN.md` + `ai/BUSINESS_MEMORY_SCREEN.md` |
| 28 | `(dashboard)/dashboard/plans/page.tsx` | `/dashboard/plans` | Client redirect stub → `/dashboard/settings/subscription` | Implemented (Redirect) | Merged into `plans/PLANS_AND_SUBSCRIPTION_SCREEN.md` |
| 29 | `(dashboard)/dashboard/upgrade/page.tsx` | `/dashboard/upgrade` | Client redirect stub → `/dashboard/settings/subscription` | Implemented (Redirect) | Merged into `plans/PLANS_AND_SUBSCRIPTION_SCREEN.md` |
| 30 | `(dashboard)/dashboard/settings/layout.tsx` | `/dashboard/settings/*` | `SettingsProvider` (`/user/me` + `/business/mine`) + 11-tab sidebar / mobile horizontal bar | Implemented and Connected | `settings/SETTINGS_HOME_SCREEN.md` |
| 31 | `(dashboard)/dashboard/settings/page.tsx` | `/dashboard/settings` | Server redirect → `/dashboard/settings/general` | Implemented (Redirect) | `settings/SETTINGS_HOME_SCREEN.md` (Phone Menu) / `GENERAL_SETTINGS_SCREEN.md` |
| 32 | `(dashboard)/dashboard/settings/general/page.tsx` | `/dashboard/settings/general` | Business basics, Currency migration trigger, Regional date/number formats, Profile card, Preferences, Export/Delete triggers | Implemented and Connected | `settings/GENERAL_SETTINGS_SCREEN.md` (+ `ACCOUNT_DELETION_FLOW.md`) |
| 33 | `(dashboard)/dashboard/settings/business-profile/page.tsx` | `/dashboard/settings/business-profile` | Business details, Logo (broken 500-char limit), Fiscal ID, Address, Mock Document Uploads card | Implemented but Incomplete | `settings/BUSINESS_PROFILE_SCREEN.md` |
| 34 | `(dashboard)/dashboard/settings/security/page.tsx` | `/dashboard/settings/security` | Security score card, Change Password modal, 2FA setup/manage/disable modals, Active Sessions table, UI-only Login Alerts & Contact Support | Implemented but Incomplete | `settings/SECURITY_SETTINGS_SCREEN.md` |
| 35 | `(dashboard)/dashboard/settings/appearance/page.tsx` | `/dashboard/settings/appearance` | Theme mode, 8+custom accents, 6 fonts, 4 scales, 3 radii, density, glow, transitions, Live Preview (`localStorage` except `compactMode`) | Implemented but Incomplete | `settings/APPEARANCE_SETTINGS_SCREEN.md` |
| 36 | `(dashboard)/dashboard/settings/signature/page.tsx` | `/dashboard/settings/signature` | Multi-signature vault, PNG/JPEG upload with background removal, HTML5 canvas drawing, auto-apply (`localStorage` only) | UI Only (`localStorage` only) | `settings/SIGNATURE_SETTINGS_SCREEN.md` |
| 37 | `(dashboard)/dashboard/settings/data-export/page.tsx` | `/dashboard/settings/data-export` | Period filter, display currency switcher, Master Excel/PDF/Print, Modular exports (`xlsx`/`jsPDF` client + backend reports) | Implemented but Incomplete | `settings/DATA_EXPORT_SETTINGS_SCREEN.md` |
| 38 | `(dashboard)/dashboard/settings/subscription/page.tsx` | `/dashboard/settings/subscription` | Full `PlansScreen`: current plan, AI quota meter, business allocation, billing toggle, plan cards, comparison table, Stripe history | Implemented and Connected | `plans/PLANS_AND_SUBSCRIPTION_SCREEN.md` + `plans/BUSINESS_ALLOCATION_AND_CANCEL_FLOWS.md` |
| 39 | `(dashboard)/dashboard/settings/[...slug]/page.tsx` | `/dashboard/settings/users-permissions`, `/notifications`, `/integrations`, `/language` | Catch-all `"Coming Soon"` card with Settings back link | Coming Soon | `settings/LANGUAGE_SETTINGS_SCREEN.md` (functional native override for `language`) + `settings/SETTINGS_COMING_SOON_SCREEN.md` (remaining 3 tabs) |

*(Plus root `app/favicon.ico` and `app/globals.css`, and `app/layout.tsx` pass-through if present — `Get-ChildItem` enumerated 41 files inside `Web/project/frontend/app/`.)*

---

## 2. Major Reusable Components & Overlays Inventory

### 2.1 Global & Shell Components (16)
- `Sidebar.tsx`, `DashboardHeader.tsx`, `BusinessSwitcher.tsx`, `LifecycleBanners.tsx`, `UpgradeBanner.tsx`, `PageHeader.tsx`, `KpiCard.tsx`, `StatCard.tsx`, `PeriodSelector.tsx`, `EmptyState.tsx`, `afab-loader.tsx`, `ThemeToggle`, `LanguageSwitcher`, `AppearanceInitializer`, `ChunkErrorRecovery`, `NotificationsDropdown` (inside `DashboardHeader`).

### 2.2 Modals, Drawers & Sheets (27 distinct overlays across features)
1. **Business Switcher Popover + Create Business Dialog + Plan Limit Dialog + Locked Business Dialog** (`BusinessSwitcher.tsx`)
2. **Notifications Bell Dropdown** (`DashboardHeader.tsx`)
3. **Add / Edit / Duplicate Transaction Modal** (`AddTransactionModal.tsx`)
4. **Split Transaction Modal** (`SplitTransactionModal.tsx`)
5. **Delete Transaction Confirmation Modal** (`DeleteTransactionModal.tsx`)
6. **Transaction Detail Drawer** (`TransactionDetailDrawer.tsx` — includes Receipt upload/download/delete)
7. **Manage Categories Modal** (`ManageCategoriesModal.tsx`)
8. **Expense / Revenue Inline Detail Modal** (`expenses/page.tsx`, `revenue/page.tsx` — unified into `TRANSACTION_DETAILS_SCREEN.md` on mobile)
9. **Add / Edit Customer Modal** (`customers/page.tsx`)
10. **Customer Detail Slide-Over Drawer** (`customers/page.tsx`)
11. **Add Order Modal** (`customers/page.tsx`)
12. **Delete Customer Confirmation Modal** (`customers/page.tsx`)
13. **Create / Edit Draft Invoice Modal** (`invoices/page.tsx`)
14. **Invoice Detail Slide-Over Drawer + Printable Window** (`invoices/page.tsx`)
15. **Record Payment Modal** (`invoices/page.tsx`)
16. **Create / Edit Budget Modal** (`budgets/page.tsx`)
17. **Create / Edit Recurring Schedule Modal** (`recurring/page.tsx`)
18. **Currency Migration Confirmation Modal** (`CurrencyMigrationModal.tsx`)
19. **Global Copilot Slide-Over Drawer** (`GlobalCopilotDrawer.tsx`)
20. **Business Memory Drawer** (`BusinessMemoryDrawer.tsx`)
21. **AI Model Status Diagnostic Popover** (`AiModelStatusBadge.tsx`)
22. **Business Allocation Modal** (`BusinessAllocationModal.tsx`)
23. **Cancel Subscription Modal** (`CancelSubscriptionModal.tsx`)
24. **Edit Profile Modal** (`EditProfileModal.tsx`)
25. **Change Password Modal** (`SecuritySettings.tsx`)
26. **2FA Setup 3-Step Modal & Manage/Disable 2FA Modal** (`SecuritySettings.tsx`)
27. **Delete Account 3-Step Preflight Modal** (`DeleteAccountModal.tsx`) & **Export Period Confirmation Modal** (`ExportPeriodModal.tsx`)

---

## 3. Complete Mobile Screen Specification Index (51 Files)

All 51 individual specifications reside under `C:\Users\MSI\Desktop\DEV\AFAB\Mobile\docs\mobile-analysis\screens\`:

1. **Authentication (8):** `SPLASH_SCREEN.md`, `LOGIN_SCREEN.md`, `TWO_FACTOR_CHALLENGE_SCREEN.md`, `SIGNUP_SCREEN.md`, `EMAIL_VERIFICATION_SCREEN.md`, `FORGOT_PASSWORD_SCREEN.md`, `RESET_PASSWORD_SCREEN.md`, `ONBOARDING_SCREEN.md`
2. **Dashboard & Shell (4):** `DASHBOARD_SCREEN.md`, `APP_SHELL_AND_MORE_HUB_SCREEN.md`, `BUSINESS_SWITCHER_SHEET.md`, `NOTIFICATIONS_SCREEN.md`
3. **Financial Core (8):** `TRANSACTIONS_SCREEN.md`, `TRANSACTION_DETAILS_SCREEN.md`, `ADD_EDIT_TRANSACTION_SCREEN.md`, `SPLIT_TRANSACTION_SCREEN.md`, `MANAGE_CATEGORIES_SCREEN.md`, `EXPENSES_SCREEN.md`, `REVENUE_SCREEN.md`, `RECEIPT_VIEWER_AND_UPLOAD_FLOW.md`
4. **Business Operations (9):** `CUSTOMERS_SCREEN.md`, `CUSTOMER_DETAILS_SCREEN.md`, `INVOICES_SCREEN.md`, `INVOICE_DETAILS_SCREEN.md`, `CREATE_EDIT_INVOICE_SCREEN.md`, `RECORD_PAYMENT_SHEET.md`, `BUDGETS_SCREEN.md`, `RECURRING_TRANSACTIONS_SCREEN.md`, `FINANCIAL_CALENDAR_SCREEN.md`
5. **Financial Intelligence (3):** `CURRENCIES_SCREEN.md`, `CURRENCY_MIGRATION_SHEET.md`, `REPORTS_SCREEN.md`
6. **AI Copilot (3):** `AI_COPILOT_SCREEN.md`, `GLOBAL_COPILOT_SHEET.md`, `BUSINESS_MEMORY_SCREEN.md`
7. **Plans & Billing (2):** `PLANS_AND_SUBSCRIPTION_SCREEN.md`, `BUSINESS_ALLOCATION_AND_CANCEL_FLOWS.md`
8. **Settings & Account (10):** `SETTINGS_HOME_SCREEN.md`, `GENERAL_SETTINGS_SCREEN.md`, `BUSINESS_PROFILE_SCREEN.md`, `SECURITY_SETTINGS_SCREEN.md`, `APPEARANCE_SETTINGS_SCREEN.md`, `SIGNATURE_SETTINGS_SCREEN.md`, `DATA_EXPORT_SETTINGS_SCREEN.md`, `LANGUAGE_SETTINGS_SCREEN.md`, `SETTINGS_COMING_SOON_SCREEN.md`, `ACCOUNT_DELETION_FLOW.md`
9. **Application States (4):** `LOADING_AND_SKELETON_STATES.md`, `MAINTENANCE_SCREEN.md`, `ERROR_AND_NOT_FOUND_STATES.md`, `SESSION_NETWORK_PLAN_LIMIT_STATES.md`
