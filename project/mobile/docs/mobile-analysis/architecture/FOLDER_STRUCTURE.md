# Folder Structure — AFAB Mobile (`lib/` & `test/`)

> Feature-First Clean Architecture tailored for Flutter `3.44.8` / Dart `3.12.2`.

```text
Mobile/
├── assets/
│   ├── images/                   # AFAB logos (light/dark), plan headers
│   └── fonts/                    # Bundled Cairo TTF for offline/PDF Arabic rendering
├── lib/
│   ├── main.dart                 # ProviderScope + EnvironmentConfig bootstrap
│   ├── app/
│   │   ├── afab_app.dart         # MaterialApp.router, Theme, Locale, Global Event Listeners
│   │   ├── router/
│   │   │   ├── app_router.dart   # GoRouter + Auth/Verification/Onboarding/Maintenance guards
│   │   │   └── app_routes.dart   # Typed route constants & path builders
│   │   └── shell/
│   │       ├── adaptive_shell.dart      # Switches NavigationBar (<600dp) <-> NavigationRail (>=600dp)
│   │       ├── shell_app_bar.dart       # Business Switcher Pill, Ask Copilot, Notification Bell
│   │       └── lifecycle_banners.dart   # Past-Due Grace, Allocation Attention, Offline banners
│   ├── core/
│   │   ├── config/               # env.dart, app_constants.dart, business_constants.dart
│   │   ├── error/                # app_failure.dart, error_mapper.dart
│   │   ├── l10n/                 # app_en.arb, app_ar.arb, generated/
│   │   ├── logging/              # app_logger.dart (PII/token redaction)
│   │   ├── money/                # decimal_converter.dart, money_formatter.dart, currency_minor_units.dart
│   │   ├── network/              # dio_client.dart, sse_client.dart, interceptors/{auth,tenant,error}_interceptor.dart
│   │   ├── storage/              # session_token_holder.dart, encrypted_cookie_storage.dart, prefs_store.dart
│   │   ├── theme/                # afab_colors.dart, appearance_settings.dart, appearance_theme_builder.dart
│   │   ├── utils/                # responsive.dart, date_formatter.dart, file_utils.dart, nlp_transaction_parser.dart
│   │   └── validation/           # validators.dart (email, password strength, limits)
│   ├── shared/
│   │   ├── models/               # page_result.dart, api_period.dart
│   │   └── widgets/              # afab_card.dart, afab_kpi_card.dart, money_text.dart, afab_loader.dart,
│   │                             # afab_button.dart, afab_text_field.dart, afab_status_badge.dart,
│   │                             # afab_bottom_sheet.dart, afab_empty_state.dart, afab_charts.dart
│   └── features/
│       ├── app_states/           # Splash (with auth), Maintenance, Error/404, PlanLimit/ReadOnly sheets
│       ├── auth/                 # data/ domain/ presentation/ (Login, 2FA, SignUp, VerifyEmail, Forgot/Reset, Onboarding)
│       ├── dashboard/            # data/ domain/ presentation/ (DashboardScreen, MoreHubScreen, widgets)
│       ├── business/             # data/ domain/ presentation/ (BusinessSwitcher, CreateBusiness, OwnershipTransfer)
│       ├── notifications/        # data/ domain/ presentation/ (NotificationsScreen, unread badge provider)
│       ├── transactions/         # data/ domain/ presentation/ (Ledger, Details, Add/Edit/Duplicate, Split, QuickAdd)
│       ├── categories/           # data/ domain/ presentation/ (ManageCategoriesScreen, CategoryPicker)
│       ├── receipts/             # data/ domain/ presentation/ (Upload, Compression, Authenticated Preview, Share)
│       ├── expenses/             # data/ domain/ presentation/ (ExpensesScreen, charts, summary)
│       ├── revenue/              # data/ domain/ presentation/ (RevenueScreen, charts, summary)
│       ├── customers/            # data/ domain/ presentation/ (CustomersScreen, CustomerDetailsScreen, AddOrder)
│       ├── invoices/             # data/ domain/ presentation/ (InvoicesScreen, Details, CreateEdit, RecordPayment, PDF)
│       ├── budgets/              # data/ domain/ presentation/ (BudgetsScreen, CreateEditBudget)
│       ├── recurring/            # data/ domain/ presentation/ (RecurringTransactionsScreen, CreateEditSchedule)
│       ├── calendar/             # data/ domain/ presentation/ (FinancialCalendarScreen)
│       ├── currencies/           # data/ domain/ presentation/ (Markets, Converter, Risk, Alerts, MigrationSheet)
│       ├── reports/              # data/ domain/ presentation/ (ReportsScreen: P&L, CashFlow, Comparison, Exports)
│       ├── ai/                   # data/ domain/ presentation/ (Copilot Studio, Global Sheet, Memory, Voice, Drafts)
│       ├── plans/                # data/ domain/ presentation/ (PlansScreen, BusinessAllocation, Cancel, BillingHistory)
│       └── settings/             # data/ domain/ presentation/ (Home, General, Profile, BusinessProfile, Security/2FA,
│                                 # Appearance, Signature, DataExport, Language, ComingSoon, AccountDeletion)
├── test/
│   ├── unit/                     # Core math, auth refresh, SSE parser, repositories
│   └── widget/                   # All 51 screens/flows x Light/Dark x EN/AR x Phone/Tablet
└── integration_test/             # End-to-end user journeys
```

### Naming Conventions
- Files: `snake_case.dart` (`add_edit_transaction_screen.dart`, `transaction_repository_impl.dart`).
- Classes: `PascalCase`; Providers: `camelCaseProvider` (`activeBusinessProvider`, `transactionListProvider`).
- Feature boundaries: Only `domain/` entities/repositories and `presentation/` screens/widgets may be imported by `app_router.dart`.
