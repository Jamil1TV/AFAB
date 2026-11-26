# 12 — Phased Implementation Roadmap & End-to-End Traceability

> **Complexity Scale:** `S` (1–2 days) · `M` (3–5 days) · `L` (1–2 weeks)
> **Rule:** Never start a phase until all prerequisites in the prior phase pass unit/widget tests and static analysis (`flutter analyze`).

---

## Phase 0 — Project Foundations

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P0-01** | Initialize Git in `Mobile/`, configure `pubspec.yaml`, `.gitignore`, `env.dart`, Android/iOS bundle IDs & permissions | `pubspec.yaml`, `lib/core/config/env.dart`, `android/`, `ios/` | `package.json`, `next.config.ts` | None | None | P0 | S | `flutter pub get` & `flutter analyze` clean; Android/iOS build cleanly | Gradle/Xcode SDK alignment |
| **P0-02** | Build Dio client, `EncryptedCookieStorage` (`PersistCookieJar` + `flutter_secure_storage`), `AuthInterceptor` (single-flight refresh + `X-CSRF-Token`), `TenantInterceptor`, `ApiErrorInterceptor` | `lib/core/network/**`, `lib/core/storage/**`, `lib/core/error/**` | `lib/api/client.ts`, `lib/auth-store.ts` | `/auth/refresh`, `GlobalExceptionHandler` | P0-01 | P0 | L | Concurrent 401 test proves 1 refresh call; `REFRESH_TOKEN_REUSE` wipes jar | Cookie `Path=/api/v1/auth` matching |
| **P0-03** | Implement `Decimal` money engine, 3-decimal ISO minor-unit map, `US/EU/SI/DOT/RAW` formatters & date formatters | `lib/core/money/**` | `lib/currency.ts`, `constants/business-data.ts` | `TransactionService`, `InvoiceService` | P0-01 | P0 | M | Unit tests pass for `TND`/`KWD`/`JPY`/`USD` `HALF_UP` & format styles | 2-dec vs 3-dec parity vs web |
| **P0-04** | Implement Design System (`AfabColors`, `AppearanceThemeBuilder`, 8+custom accents, 4 dark surfaces, 6 Google Fonts, 3 radii) & shared `shared/widgets/` | `lib/core/theme/**`, `lib/shared/widgets/**` | `globals.css`, `design-tokens.ts`, `appearance.ts`, `afab-loader.tsx` | None | P0-01 | P0 | L | Light/Dark + RTL widget tests pass without overflow | Google Fonts offline bundling |
| **P0-05** | Generate `app_en.arb` & `app_ar.arb` (migrating all 14 non-home namespaces + missing keys) & RTL helpers | `lib/core/l10n/**` | `messages/{en,ar}/*.json`, `i18n/request.ts` | None | P0-01 | P0 | M | 100% key parity EN/AR; Western digits `0-9` & LTR `MoneyText` verified | Hardcoded web strings extraction |
| **P0-06** | Configure `GoRouter` (`StatefulShellRoute.indexedStack`), deep links, responsive `AfabBreakpoints`, & app-state screens (Loading/Maintenance/Error/404/PlanLimit/ReadOnly/Offline) | `lib/app/router/**`, `lib/features/app_states/**` | `proxy.ts`, `error.tsx`, `not-found.tsx`, `maintenance/page.tsx` | `/api/v1/health` | P0-02, P0-04, P0-05 | P0 | M | Route guard unit + widget tests for unauth/unverified/onboarded/maintenance | Deep-link token `_` preservation |

---

## Phase 1 — Authentication & Onboarding

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P1-01** | `SplashScreen` & cold-start session restoration + optional Biometric lock gate | `lib/features/auth/presentation/splash_screen.dart`, `auth_notifier.dart` | `proxy.ts`, `client.ts` | `POST /auth/refresh`, `GET /user/me` | P0-02, P0-06 | P0 | M | Integration test: valid cookie → Dashboard; invalid → Login | Offline startup UX |
| **P1-02** | `LoginScreen` (rememberMe, lockout/rate-limit banners) + `TwoFactorChallengeScreen` (6-digit TOTP & 8-char backup code) | `lib/features/auth/presentation/{login,two_factor}_screen.dart` | `(auth)/login/page.tsx` | `POST /auth/login`, `POST /auth/2fa/verify-login` | P1-01 | P0 | M | Widget + integration tests; dead Google button omitted | 5-min 2FA challenge expiry |
| **P1-03** | `SignUpScreen` (with `PasswordStrengthIndicator`) + `EmailVerificationScreen` (6-box OTP + paste + 60s resend timer) | `lib/features/auth/presentation/{signup,verify_email}_screen.dart` | `(auth)/signup/page.tsx`, `(auth)/verify-email/page.tsx` | `POST /auth/register`, `/verify-email`, `/resend-verification` | P1-01 | P0 | M | Full registration → OTP → onboarding test | SMTP / `devOtp` handling |
| **P1-04** | `ForgotPasswordScreen` + `ResetPasswordScreen` (preserving `_` in Base64URL tokens) + optional OTP fallback | `lib/features/auth/presentation/{forgot,reset}_password_screen.dart` | `(auth)/forgot-password/page.tsx`, `(auth)/reset-password/page.tsx` | `/forgot-password-link`, `/validate-reset-token`, `/reset-password-token` | P1-01 | P0 | S | Deep-link token with `_` validates cleanly | Universal Link domain setup |
| **P1-05** | `OnboardingScreen` (3-step Country/Industry/Type → Currency/Timezone/FY → Confirm) | `lib/features/auth/presentation/onboarding_screen.dart` | `(auth)/onboarding/page.tsx`, `business-data.ts` | `PUT /business/{id}` | P1-03 | P0 | M | Completes onboarding & sets `onboardingComplete=true` | Missing `TND` in web constants |

---

## Phase 2 — Main Application Foundation & Dashboard

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P2-01** | Adaptive `AppShell` (5-tab Bottom Nav, `MoreHubScreen`, Tablet `NavigationRail`, `LifecycleBanners`, `GlobalCopilotSheet` trigger) | `lib/app/shell/**`, `lib/features/dashboard/presentation/more_hub_screen.dart` | `(dashboard)/layout.tsx`, `Sidebar.tsx`, `DashboardHeader.tsx`, `LifecycleBanners.tsx` | `GET /user/me`, `/subscription/me`, `/business/mine` | P0-06, P1-01 | P0 | L | Phone & Tablet layout tests; zero horizontal overflow | `PAST_DUE` & `READ_ONLY` banner sync |
| **P2-02** | `BusinessSwitcherSheet` (switch, create workspace, plan cap handling, `READ_ONLY` locked modal) & `NotificationsScreen` (read/read-all) | `lib/features/business/**`, `lib/features/notifications/**` | `BusinessSwitcher.tsx`, `DashboardHeader.tsx` | `GET/POST /business`, `PUT /business/{id}/switch`, `/notifications*` | P2-01 | P1 | M | Switching business resets all Riverpod caches & `X-Business-Id` | Owner-only cap calculation |
| **P2-03** | `DashboardScreen` (4 KPI cards, 6-month `AreaChart`, `ExpenseCategories` donut [fixing `$0.00` bug], `AIInsightsCard`, `RecentTransactions`, `BudgetOverviewCard`, `ReminderCard` [fixing icon/View All], `TopCustomers`) | `lib/features/dashboard/**` | `dashboard/page.tsx`, `components/dashboard/*` | `GET /dashboard/summary`, `GET /ai/pulse`, `GET /customers/summary` | P2-01, P0-03 | P1 | L | Donut totals match numeric `value`; RTL & Dark mode golden tests pass | Pulse latency on cold Ollama |

---

## Phase 3 — Core Financial Operations

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P3-01** | `TransactionsScreen` (filters incl. `PeriodSelector` → `startDate`/`endDate`, `paymentMethod`, `taxDeductible`, debounced search, pagination, CSV export, Quick-Add NLP sheet) | `lib/features/transactions/**` | `transactions/page.tsx`, `QuickAddBar.tsx`, `nlp-transaction-parser.ts` | `GET /transactions`, `DELETE /transactions/{id}` | P2-01, P0-03 | P1 | L | Period filter & pagination hit API; comma NLP `"$1,500"` fixed | Client vs backend totals mismatch |
| **P3-02** | `AddEditTransactionScreen` (fixing Duplicate `POST` vs Edit `PUT` & exposing `status`/`CREDIT_CARD`), `SplitTransactionScreen`, `ManageCategoriesScreen` (fixing `systemDefault` & `"var(--primary)"`) | `lib/features/transactions/presentation/*`, `lib/features/categories/**` | `AddTransactionModal.tsx`, `SplitTransactionModal.tsx`, `ManageCategoriesModal.tsx` | `POST/PUT /transactions`, `GET/POST/PUT/DELETE /categories`, `GET /currencies/convert` | P3-01 | P1 | L | Split exact sum validated in `Decimal`; Duplicate creates new row (`POST`) | `PUT` ignores split edits on backend |
| **P3-03** | `TransactionDetailsScreen` + `ReceiptViewerAndUploadFlow` (Camera/Gallery/PDF, compression, MinIO upload, authenticated stream preview, share, delete) | `lib/features/transactions/presentation/transaction_details_screen.dart`, `lib/features/receipts/**` | `TransactionDetailDrawer.tsx`, `lib/api/receipts.ts` | `GET /transactions/{id}`, `/receipts/**` | P3-01 | P1 | M | 10MB + magic-byte error handling; PDF & image preview works | Memory handling on large scans |
| **P3-04** | `ExpensesScreen` & `RevenueScreen` (filtered `EXPENSE`/`INCOME` category dropdowns, Area/Donut charts, period-synced list warning, unified `TransactionDetailsScreen`) | `lib/features/expenses/**`, `lib/features/revenue/**` | `expenses/page.tsx`, `revenue/page.tsx` | `GET /expenses/*`, `GET /revenue/*` | P3-01, P3-03 | P1 | M | Revenue `+` opens `INCOME` tab; omits stale Phase 13 text | Backend `recurringList`/`topProducts` always empty |
| **P3-05** | `CustomersScreen` & `CustomerDetailsScreen` (always fetching `GET /customers/{id}`, fixing `outstandingBalance` & `InvoiceStatus` badges, Add/Edit Customer, Add Order) | `lib/features/customers/**` | `customers/page.tsx`, `lib/api/customers.ts` | `/customers/**`, `/invoices/**` (for Add Order) | P2-01 | P1 | L | Order history & outstanding balance match backend DTO | Multi-currency customer sum |
| **P3-06** | `InvoicesScreen`, `InvoiceDetailsScreen` (native PDF + share), `CreateEditInvoiceScreen`, `RecordPaymentSheet` (`Idempotency-Key` UUID) | `lib/features/invoices/**` | `invoices/page.tsx`, `lib/api/invoices.ts`, `lib/export-utils.ts` | `/invoices/**` | P3-05 | P1 | L | `SENT` filter present; `subtotal` bug fixed; payment idempotency tested | PDF Arabic font embedding |
| **P3-07** | `BudgetsScreen` (cards, Ask AI, confirm archive, archived toggle) & `RecurringTransactionsScreen` (schedules, pause/resume, run-due, deactivate-vs-delete dialog) | `lib/features/budgets/**`, `lib/features/recurring/**` | `budgets/page.tsx`, `recurring/page.tsx` | `/budgets/**`, `/recurring-transactions/**` | P3-02 | P1 | M | Threshold alerts & `run-due` tested | Edit `periodType` date recalculation |

---

## Phase 4 — Financial Intelligence & Calendar

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P4-01** | `FinancialCalendarScreen` (month grid querying `startDate`/`endDate`, day activity sheet, optional due-invoice/recurring overlay) | `lib/features/calendar/**` | `calendar/page.tsx` | `GET /transactions?startDate=&endDate=` | P3-01 | P2 | M | Month navigation fetches exact month window | No dedicated calendar endpoint |
| **P4-02** | `CurrenciesScreen` (fixing view-base reset bug, honest Simulation labels for Binance/History charts, Converter, Portfolio Impact, Risk Simulator, local Alerts, Directory) & `CurrencyMigrationSheet` | `lib/features/currencies/**` | `currencies/page.tsx`, `components/currencies/*`, `CurrencyMigrationModal.tsx` | `GET /currencies/rates`, `/history`, `/convert`, `/business/preview`, `POST /business/change` | P2-03, P0-03 | P2 | L | Historical immutability verified; simulated feeds clearly badged | `1Y` backend history returns 52 days |
| **P4-03** | `ReportsScreen` (P&L, Cash Flow, Comparison with selectable comparison period, Pro custom date range, backend CSV/OpenPDF download + share + quota meter) | `lib/features/reports/**` | `reports/page.tsx`, `lib/api/reports.ts` | `/reports/*` | P2-03 | P2 | M | Plan gating (`basic`/`advanced`/`custom`) & `PLAN_LIMIT_REACHED` tested | Backend OpenPDF lacks Arabic glyphs |

---

## Phase 5 — AI Copilot v2

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P5-01** | SSE parser, `AiCopilotScreen` (drawer conversation history/search/delete, quota meter, health badge, RAG `Sync Index`, Fast/Deep toggle, streaming Markdown, `fl_chart` cards, evidence, follow-ups) | `lib/features/ai/**` | `dashboard/ai/page.tsx`, `components/ai/*`, `lib/api/ai.ts` | `/api/v1/ai/*` (21 endpoints) | P2-01, P0-02 | P2 | L | Streaming SSE (`thought`/`tool`/`delta`/`replace`/`done`) & cancel tested | 90s Ollama inference timeout on cellular |
| **P5-02** | Multimodal Attachments (Camera/Gallery/FilePicker + compression + preview), Voice Dictation (`speech_to_text` EN/FR/AR-TN), Action Drafts (`CREATE_TRANSACTION`, `CREATE_INVOICE`, `CREATE_BUDGET`, `PAYMENT_REMINDER`, `SAVE_MEMORY`), `GlobalCopilotSheet`, `BusinessMemoryScreen` | `lib/features/ai/presentation/*` | `CopilotActionDraftCard.tsx`, `CopilotReminderCard.tsx`, `VoiceDictationButton.tsx`, `BusinessMemoryDrawer.tsx`, `GlobalCopilotDrawer.tsx` | `/ai/attachments/*`, `/ai/actions/*`, `/ai/memory*` | P5-01 | P2 | L | Receipt staging + approve transaction + memory CRUD + `mailto:`/`wa.me` tested | OS mic permissions & `ar-TN` STT support |

---

## Phase 6 — Plans, Stripe Billing & Settings

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P6-01** | `PlansAndSubscriptionScreen` & `BusinessAllocationAndCancelFlows` (Custom Tabs Checkout/Portal + Universal Link verify, direct upgrade, downgrade schedule, cancel, resume, billing history) | `lib/features/plans/**` | `PlansScreen.tsx`, `BusinessAllocationModal.tsx`, `CancelSubscriptionModal.tsx` | `/subscription/*`, `/billing/*`, `/business/allocations*` | P2-02 | P2 | L | Checkout verify & allocation modals pass integration tests | **Store IAP Policy & Stripe `sanitizeReturnPath`** |
| **P6-02** | `SettingsHomeScreen`, `GeneralSettingsScreen` (Edit Profile, Regional Formats, Preferences, JSON export), `AccountDeletionFlow` (with Ownership Transfer UI & fixed AR copy), `BusinessProfileScreen`, `LanguageSettingsScreen`, `SettingsComingSoonScreen` | `lib/features/settings/**` | `settings/{layout,general,business-profile,[...slug]}/`, `EditProfileModal.tsx`, `DeleteAccountModal.tsx` | `/user/me*`, `/business/{id}*` | P2-02, P0-05 | P1 | L | Account deletion preflight & transfer tested; mock uploads omitted | `logoUrl` 500-char backend limit; `READ_ONLY` delete deadlock |
| **P6-03** | `SecuritySettingsScreen` (Change Password + forced logout, 2FA setup QR + backup codes + disable, Active Sessions, Biometric Lock), `AppearanceSettingsScreen`, `SignatureSettingsScreen` (local vault), `DataExportSettingsScreen` (native `.xlsx` + Arabic `.pdf` + backend CSV/PDF) | `lib/features/settings/presentation/*` | `SecuritySettings.tsx`, `AppearanceSettings.tsx`, `SignatureSettings.tsx`, `DataExportSettings.tsx` | `/auth/change-password`, `/user/2fa/*`, `/user/me/sessions*`, `/reports/export/*` | P6-02, P0-04 | P2 | L | 2FA QR, signature pad, native Excel/PDF share tested | Session `currentSession` always false on backend |

---

## Phase 7 — Verification & Release Preparation

| Task ID | Description | Target Flutter Files | Web Source Refs | Backend Deps | Prereqs | Pri | Size | Acceptance Criteria & Tests | Risks |
|---|---|---|---|---|---|---|---|---|---|
| **P7-01** | Full integration test suite, responsive/RTL/dark-mode sweeps (`320dp..1280dp`), accessibility & performance profiling, Android/iOS release signing & obfuscation | `test/**`, `integration_test/**`, `android/`, `ios/` | All modules | Full Spring Boot + Postgres/Redis/MinIO stack | Phases 0–6 | P0 | L | 0 analyzer issues; all unit/widget/integration tests green; release APK/IPA smoke-tested | App Store review on Stripe billing |

---

## End-to-End Traceability Matrix (Web Source → Screen Spec → API → Flutter Feature → Task)

| Web Source | Screen Spec (`docs/mobile-analysis/screens/...`) | Primary API Endpoints | Flutter Feature (`lib/features/...`) | Task ID |
|---|---|---|---|---|
| `proxy.ts` + `client.ts` | `authentication/SPLASH_SCREEN.md` | `POST /auth/refresh`, `GET /user/me` | `auth` | P1-01 |
| `(auth)/login/page.tsx` | `authentication/LOGIN_SCREEN.md`, `TWO_FACTOR_CHALLENGE_SCREEN.md` | `POST /auth/login`, `POST /auth/2fa/verify-login` | `auth` | P1-02 |
| `(auth)/signup/page.tsx` | `authentication/SIGNUP_SCREEN.md` | `POST /auth/register` | `auth` | P1-03 |
| `(auth)/verify-email/page.tsx` | `authentication/EMAIL_VERIFICATION_SCREEN.md` | `POST /auth/verify-email`, `/resend-verification` | `auth` | P1-03 |
| `(auth)/forgot-password/page.tsx` | `authentication/FORGOT_PASSWORD_SCREEN.md` | `POST /auth/forgot-password-link` | `auth` | P1-04 |
| `(auth)/reset-password/page.tsx` | `authentication/RESET_PASSWORD_SCREEN.md` | `POST /auth/validate-reset-token`, `/reset-password-token` | `auth` | P1-04 |
| `(auth)/onboarding/page.tsx` | `authentication/ONBOARDING_SCREEN.md` | `PUT /business/{id}` | `auth` / `business` | P1-05 |
| `(dashboard)/layout.tsx`, `Sidebar.tsx`, `DashboardHeader.tsx` | `dashboard/APP_SHELL_AND_MORE_HUB_SCREEN.md` | `GET /user/me`, `/subscription/me`, `/business/mine` | `app/shell` | P2-01 |
| `BusinessSwitcher.tsx` | `dashboard/BUSINESS_SWITCHER_SHEET.md` | `GET/POST /business`, `PUT /business/{id}/switch` | `business` | P2-02 |
| `DashboardHeader.tsx` (Bell) | `dashboard/NOTIFICATIONS_SCREEN.md` | `GET /notifications`, `PUT /notifications/{id}/read`, `/read-all` | `notifications` | P2-02 |
| `(dashboard)/dashboard/page.tsx` | `dashboard/DASHBOARD_SCREEN.md` | `GET /dashboard/summary`, `GET /ai/pulse` | `dashboard` | P2-03 |
| `dashboard/transactions/page.tsx` | `financial/TRANSACTIONS_SCREEN.md` | `GET /transactions`, `DELETE /transactions/{id}` | `transactions` | P3-01 |
| `AddTransactionModal.tsx` | `financial/ADD_EDIT_TRANSACTION_SCREEN.md` | `POST /transactions`, `PUT /transactions/{id}`, `GET /currencies/convert` | `transactions` | P3-02 |
| `SplitTransactionModal.tsx` | `financial/SPLIT_TRANSACTION_SCREEN.md` | `POST /transactions` | `transactions` | P3-02 |
| `ManageCategoriesModal.tsx` | `financial/MANAGE_CATEGORIES_SCREEN.md` | `GET/POST/PUT/DELETE /categories` | `categories` | P3-02 |
| `TransactionDetailDrawer.tsx` | `financial/TRANSACTION_DETAILS_SCREEN.md`, `RECEIPT_VIEWER_AND_UPLOAD_FLOW.md` | `GET /transactions/{id}`, `/receipts/**` | `transactions`, `receipts` | P3-03 |
| `dashboard/expenses/page.tsx` | `financial/EXPENSES_SCREEN.md` | `GET /expenses/summary`, `GET /expenses` | `expenses` | P3-04 |
| `dashboard/revenue/page.tsx` | `financial/REVENUE_SCREEN.md` | `GET /revenue/summary`, `GET /revenue` | `revenue` | P3-04 |
| `dashboard/customers/page.tsx` | `business/CUSTOMERS_SCREEN.md`, `CUSTOMER_DETAILS_SCREEN.md` | `/customers/**`, `POST /invoices/**` | `customers` | P3-05 |
| `dashboard/invoices/page.tsx` | `business/INVOICES_SCREEN.md`, `INVOICE_DETAILS_SCREEN.md`, `CREATE_EDIT_INVOICE_SCREEN.md`, `RECORD_PAYMENT_SHEET.md` | `/invoices/**` | `invoices` | P3-06 |
| `dashboard/budgets/page.tsx` | `business/BUDGETS_SCREEN.md` | `/budgets/**` | `budgets` | P3-07 |
| `dashboard/recurring/page.tsx` | `business/RECURRING_TRANSACTIONS_SCREEN.md` | `/recurring-transactions/**` | `recurring` | P3-07 |
| `dashboard/calendar/page.tsx` | `business/FINANCIAL_CALENDAR_SCREEN.md` | `GET /transactions?startDate=&endDate=` | `calendar` | P4-01 |
| `dashboard/currencies/page.tsx`, `CurrencyMigrationModal.tsx` | `intelligence/CURRENCIES_SCREEN.md`, `CURRENCY_MIGRATION_SHEET.md` | `/currencies/**` | `currencies` | P4-02 |
| `dashboard/reports/page.tsx` | `intelligence/REPORTS_SCREEN.md` | `/reports/**` | `reports` | P4-03 |
| `dashboard/ai/page.tsx`, `GlobalCopilotDrawer.tsx`, `BusinessMemoryDrawer.tsx` | `ai/AI_COPILOT_SCREEN.md`, `GLOBAL_COPILOT_SHEET.md`, `BUSINESS_MEMORY_SCREEN.md` | `/api/v1/ai/**` (21 endpoints) | `ai` | P5-01, P5-02 |
| `PlansScreen.tsx`, `BusinessAllocationModal.tsx`, `CancelSubscriptionModal.tsx` | `plans/PLANS_AND_SUBSCRIPTION_SCREEN.md`, `BUSINESS_ALLOCATION_AND_CANCEL_FLOWS.md` | `/subscription/*`, `/billing/*`, `/business/allocations*` | `plans` | P6-01 |
| `settings/layout.tsx`, `general/page.tsx`, `DeleteAccountModal.tsx` | `settings/SETTINGS_HOME_SCREEN.md`, `GENERAL_SETTINGS_SCREEN.md`, `ACCOUNT_DELETION_FLOW.md` | `/user/me*`, `/business/{id}*` | `settings` | P6-02 |
| `settings/business-profile/page.tsx`, `settings/[...slug]/page.tsx` | `settings/BUSINESS_PROFILE_SCREEN.md`, `LANGUAGE_SETTINGS_SCREEN.md`, `SETTINGS_COMING_SOON_SCREEN.md` | `GET/PUT /business/{id}` | `settings` | P6-02 |
| `settings/{security,appearance,signature,data-export}/page.tsx` | `settings/SECURITY_SETTINGS_SCREEN.md`, `APPEARANCE_SETTINGS_SCREEN.md`, `SIGNATURE_SETTINGS_SCREEN.md`, `DATA_EXPORT_SETTINGS_SCREEN.md` | `/auth/change-password`, `/user/2fa/*`, `/user/me/sessions*`, `/reports/export/*` | `settings` | P6-03 |
| `loading.tsx`, `maintenance/page.tsx`, `error.tsx`, `not-found.tsx`, `client.ts` | `application/LOADING_AND_SKELETON_STATES.md`, `MAINTENANCE_SCREEN.md`, `ERROR_AND_NOT_FOUND_STATES.md`, `SESSION_NETWORK_PLAN_LIMIT_STATES.md` | `GET /api/v1/health`, global `401`/`403`/`503` interceptors | `app_states` | P0-06 |
