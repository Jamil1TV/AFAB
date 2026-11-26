# DASH-01 — Dashboard Screen (`DashboardScreen`)

> **Spec ID:** `DASH-01`
> **Phase / Task:** Phase 2 (`P2-03`)
> **Verified Web Sources:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/page.tsx`, `components/dashboard/{PeriodSelector,KpiCard,RevenueChart,AIInsightsCard,RecentTransactions,ExpenseCategories,BudgetOverviewCard,ReminderCard,TopCustomers,UpgradeBanner}.tsx`, `lib/api/dashboard.ts`, `messages/{en,ar}/dashboard.json`
> **Verified Backend Sources:** `DashboardController.java`, `DashboardService.java`, `DashboardSummaryDTO.java`, `FinanceStatsService.java`, `AiController.java` (`/api/v1/ai/pulse`)

---

## 1. Screen Identity

- **Screen Name:** `DashboardScreen`
- **Route Name & Path:** `AppRoutes.dashboard` (`/dashboard`, Tab `0` of `StatefulShellRoute`)
- **Feature Module:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- **Parent Container:** `AdaptiveShell` (`DASH-02`) with `ShellAppBar` + `LifecycleBanners`
- **Access Control:** Authenticated, email-verified, onboarding-completed user with an `EDITABLE` active workspace (`X-Business-Id`)

---

## 2. Purpose and Functional Parity

`DashboardScreen` is the primary executive financial overview for the active business workspace. It consolidates cash-basis KPIs, a 6-month revenue-vs-expenses trend, live AI Pulse alerts, recent transactions, expense category breakdown, active budget progress, deterministic reminders (budget alerts and overdue invoices), top revenue-generating customers, and plan upgrade promotion (hidden on Pro).

| Web Feature / Widget | Mobile Parity Status | Key Mobile Adaptation / Fix |
|---|---|---|
| Time-of-day Greeting + `PeriodSelector` | Full Parity | Segmented pill (`WEEKLY` / `MONTHLY` / `YEARLY`) with pull-to-refresh |
| 4 `KpiCard`s + Sparklines + Ask AI | Full Parity + Fix | Dynamic period comparison label (`vs previous 7 days` / `vs last month` / `vs last year`) instead of hardcoded `vs last month` |
| `RevenueChart` (6-month AreaChart) | Full Parity + Fix | `fl_chart` interactive touch scrubber; accurate `"Trailing 6 months cash flow"` subtitle |
| `AIInsightsCard` + `GET /ai/pulse` | Full Parity | Live Pulse alert cards with "Investigate in Copilot" + deterministic ledger fallback |
| `RecentTransactions` (top 5) | Full Parity + Fix | Row tap opens `TransactionDetailsScreen(id)` directly; semantic Flutter colors |
| `ExpenseCategories` Donut | Full Parity + **Critical Fix** | Reads numeric `value` field (`Decimal`) to **fix Web's `$0.00` `parseFloat("USD 500.00")` bug** |
| `BudgetOverviewCard` | Full Parity | Up to 6 budget progress cards + alert icons + `"Manage Budgets"` navigation |
| `ReminderCard` | Full Parity + **2 Fixes** | Maps backend `"budget"` & `"invoice"` types to icons/colors; wires `"View All"` & row taps |
| `TopCustomers` (top 5) | Full Parity + Fix | Tap row opens `CustomerDetailsScreen(id)`; keeps `GET /customers/summary` fallback |
| `UpgradeBanner` | Full Parity | Hidden on `pro` or unresolved tier; navigates to `/plans` |

---

## 3. Navigation and Entry/Exit Paths

- **Entry Paths:**
  - Default authenticated landing destination after `SplashScreen`, `LoginScreen`, `TwoFactorChallengeScreen`, or `OnboardingScreen`.
  - Bottom Navigation Tab `0` (`Home`) on phones or `NavigationRail` index `0` (`Overview`) on tablets.
  - Switching active business in `BusinessSwitcherSheet` (`DASH-03`) keeps the user on `DashboardScreen` and triggers an atomic refetch.
- **Exit / Outbound Paths:**
  - **Ask Copilot on KPI Card or Pulse Alert** → opens `GlobalCopilotSheet` pre-populated with contextual prompt (`autoSend: true`, `screenContext`).
  - **Ask AI Assistant CTA (`AIInsightsCard`)** → switches to Tab `2` (`AiCopilotScreen`, `/ai`).
  - **Recent Transactions `"View all"`** → switches to Tab `1` (`TransactionsScreen`, `/transactions`).
  - **Recent Transactions `"Add Transaction"` (empty state)** → pushes `AddEditTransactionScreen` (`mode: create`).
  - **Transaction Row Tap** → pushes `TransactionDetailsScreen(tx.id)`.
  - **Budget `"Manage Budgets"` / `"Create one now"`** → pushes `BudgetsScreen` (`/budgets`).
  - **Reminder Row Tap:** `"budget"` → pushes `BudgetsScreen`; `"invoice"` → pushes `InvoicesScreen` (filtered `OVERDUE`).
  - **Reminder `"View all"`** → opens `RemindersModalSheet` listing all returned reminders with deep-links.
  - **Top Customers `"View all"`** → pushes `CustomersScreen` (`/customers`).
  - **Customer Row Tap** → pushes `CustomerDetailsScreen(customer.id)`.
  - **Upgrade Banner CTA** → pushes `PlansAndSubscriptionScreen` (`/plans`).

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

- **Scroll Structure:** `RefreshIndicator` wrapping a `CustomScrollView` / `SingleChildScrollView` with `SliverPadding` (`16dp` horizontal on phones, `24dp` on tablets) and `16–20dp` vertical spacing (`12dp` in compact density).
- **Phone (`< 600dp`):**
  1. **Welcome Header:** Greeting (`Good Morning, {firstName}` / localized AR equivalent based on device local hour `< 12` morning, `< 18` afternoon, `>= 18` evening) + subtitle + full-width `AfabSegmentedBar` `PeriodSelector` (`WEEKLY`, `MONTHLY`, `YEARLY`).
  2. **KPI Grid:** `2x2` grid (`360–599dp`) or `1x4` stack (`< 360dp` `compactSmall`) of `AfabKpiCard` widgets.
  3. **Revenue & Expenses Area Chart:** Full-width card (`220dp` chart height).
  4. **AI Assistant Insights Card:** Full-width gradient-tinted card.
  5. **Recent Transactions Card:** Full-width list (max 5 rows).
  6. **Expense Categories Donut:** Full-width card; donut (`156x156dp`) stacked above legend on `< 380dp`, side-by-side on `>= 380dp`.
  7. **Budget Progress Overview:** Full-width card with horizontal-safe vertical stack of up to 6 budget cards.
  8. **Upcoming Reminders Card** followed by **Top Customers Card**.
  9. **Upgrade Banner:** Bottom card (omitted on `pro`).
- **Tablet Portrait (`600–839dp`):**
  - Header & `PeriodSelector` inline (`Row` space-between).
  - KPI Grid: `2x2` (or `4x1` if `>= 760dp`).
  - `RevenueChart` & `AIInsightsCard` stacked or `2:1` above `800dp`; `BudgetOverviewCard` 2-column grid; `ReminderCard` + `TopCustomers` side-by-side (`2` columns).
- **Tablet Landscape (`>= 840dp`):**
  - Exact parity with Web's 12-column grid:
    - KPI Grid: `4` equal columns.
    - Main Analytics Row: `RevenueChart` (`8` cols) + `AIInsightsCard` (`4` cols).
    - Secondary Data Row: `RecentTransactions` (`8` cols) + `ExpenseCategories` (`4` cols).
    - `BudgetOverviewCard`: `3`-column internal grid (up to 6 budgets).
    - Tertiary Data Row: `ReminderCard` (`6` cols) + `TopCustomers` (`6` cols).
    - `UpgradeBanner`: Full-width horizontal banner.

---

## 5. UI Components and Design System Mapping

| Dashboard Section | Flutter Widget | Design System Tokens (`07_DESIGN_SYSTEM.md`) |
|---|---|---|
| Period Selector | `AfabSegmentedBar<ApiPeriod>` | `surfaceInset` track, `primary` active pill, white active text |
| KPI Cards (x4) | `AfabKpiCard` | `AfabCard`, `40x40dp` icon tile, `MoneyText` (`tabularFigures` + `FittedBox`), `fl_chart` `LineChart` sparkline (`#10B981` positive / `#EF4444` negative / `#64748B` flat dashed), always-visible subtle `Sparkles` tap target (`48x48dp` hit area on touch) |
| Revenue & Expenses | `RevenueAreaChartCard` | `AfabCard`, `fl_chart` `LineChart` with `primary` (`Revenue`) & `#0EA5E9` (`Expenses`) cubic curves + gradient fills, dashed horizontal gridlines, dark translucent tooltip (`#E60C101C`, `primary` border) |
| AI Insights | `AiInsightsCard` | `1px primary` (`0.3` alpha) border, subtle `primary` (`0.08` alpha) gradient surface, `AfabInsetPanel` alert rows, `AfabStatusBadge` severity pills (`HIGH` rose, `MEDIUM` amber, `INFO` primary) |
| Recent Transactions | `RecentTransactionsCard` | `AfabCard`, `40x40dp` rounded-`12dp` category/initials avatar, `MoneyText`, `AfabStatusBadge` (`COMPLETED` neutral, `PENDING` amber) |
| Expense Categories | `ExpenseCategoriesDonutCard` | `AfabCard`, `fl_chart` `PieChart` (`centerSpaceRadius: 52`, `sectionsSpace: 3`), center `MoneyText` total + `"Total"` caption, color dot legend rows |
| Budget Progress | `BudgetOverviewCard` | `AfabCard`, `AfabInsetPanel` per budget, `LinearProgressIndicator` (`emerald` / `amber` / `rose` `#EF4444`), `AlertTriangle` / `XCircle` icons |
| Reminders | `ReminderCard` | `AfabCard`, `36x36dp` icon tile (`PiggyBank` for `budget`, `FileText` for `invoice`, `Calendar` for `meeting`, `Repeat` for `subscription`, `Clock` fallback) |
| Top Customers | `TopCustomersCard` | `AfabCard`, `CachedNetworkImage` avatar or initials badge, `MoneyText` revenue, directional `ArrowUpRight` |
| Upgrade Banner | `UpgradeBannerCard` | `primaryHover -> #6D28D9` gradient (`07_DESIGN_SYSTEM.md` allowed Pro CTA gradient), white primary pill button |

---

## 6. Data Models and State Management

### 6.1 Domain Models (`freezed` + `DecimalJsonConverter`)
- `DashboardPeriod` enum: `weekly('weekly')`, `monthly('month')`, `yearly('year')`.
- `DashboardSummary`:
  - `KpiData` (`revenue`, `expenses`, `profit`, `cashFlow` → each `KpiMetric { String value, String change, bool isPositive, Decimal? rawValue, Decimal? rawChange }`)
  - `List<RevenueDataPoint>` (`String month`, `String name`, `Decimal revenue`, `Decimal expenses`)
  - `List<DashboardTransactionItem>` (`String id`, `String name`, `String description`, `String amount`, `Decimal? rawAmount`, `String date`, `String type`, `String status`, `String? color`, `String? initials`, `bool isCredit`)
  - `List<ExpenseCategoryItem>` (`String name`, `String amount`, `Decimal value`, `double percentage`, `String? color`)
  - `List<ReminderItem>` (`String id`, `String title`, `String date`, `String priority`, `String? type`)
  - `List<DashboardCustomerItem>` (`String id`, `String name`, `Decimal revenue`, `String? avatar`, `String? email`, `int? ordersCount`)
  - `String currency`, `String businessName`
  - `BudgetSummary? budgets` (`activeBudgetCount`, `overBudgetCount`, `approachingCount`, `List<BudgetItem> budgets`)
- `AiPulseResponse`: `currency`, `generatedAt`, `highCount`, `mediumCount`, `infoCount`, `monthRevenue`, `monthExpenses`, `monthNetProfit`, `overdueTotal`, `overdueCount`, `missingReceiptCount`, `List<AiPulseAlert> alerts`.

### 6.2 Riverpod Providers (`lib/features/dashboard/presentation/providers/`)
- `dashboardPeriodProvider`: `NotifierProvider<DashboardPeriodNotifier, DashboardPeriod>` (default `DashboardPeriod.monthly`).
- `dashboardSummaryProvider`: `FutureProvider.autoDispose<DashboardSummary>` — watches `activeBusinessIdProvider` and `dashboardPeriodProvider`, calls `DashboardRepository.getSummary(period)`.
- `aiPulseProvider`: `FutureProvider.autoDispose<AiPulseResponse?>` — watches `activeBusinessIdProvider`, non-blocking fetch (`catch -> null` so AI outage never breaks dashboard).
- `topCustomersFallbackProvider`: triggered only when `summary.customers.isEmpty` (`GET /api/v1/customers/summary?period=month`).

---

## 7. API Contracts and Data Flow

1. **`GET /api/v1/dashboard/summary?period={weekly|month|year}`**
   - Headers: `Authorization: Bearer <jwt>`, `X-Business-Id: <uuid>`.
   - Response: `200 DashboardSummaryDTO`.
   - Backend enforces `BusinessAccessGuard.assertEditable` (`403 BUSINESS_READ_ONLY` if locked).
   - **Important Backend Behavior:** `revenueData` always returns the trailing 6 calendar months regardless of `period`, and `transactions` returns the latest 5 transactions regardless of `period`. `kpiData` and `expenseCategories` honor `period` (`weekly` = 7 days, `month` = current calendar month, `year` = Jan 1–Dec 31).
2. **`GET /api/v1/ai/pulse`**
   - Headers: `Authorization: Bearer <jwt>`, `X-Business-Id: <uuid>`.
   - Response: `200 AiPulseDTO`. Non-blocking; failure degrades gracefully to deterministic ledger insights computed from `summary`.
3. **`GET /api/v1/customers/summary?period=month`** *(Conditional Fallback)*
   - Called only if `summary.customers` is empty.
4. **`GET /api/v1/subscription/me` & `GET /api/v1/user/me`** *(Shared Shell Providers)*
   - Provides `firstName` for greeting and `planSlug` for `UpgradeBanner` visibility.

---

## 8. User Interactions and Event Handling

- **Change Period (`WEEKLY` / `MONTHLY` / `YEARLY`):** Updates `dashboardPeriodProvider`, displays subtle top linear indicator or card shimmer while preserving previous data if already loaded (`AsyncValue.isRefreshing`), and updates KPI comparison labels immediately.
- **Pull-to-Refresh:** Invalidates `dashboardSummaryProvider`, `aiPulseProvider`, and `subscriptionSnapshotProvider` in parallel.
- **KPI Card Sparkles Tap:** Opens `GlobalCopilotSheet` with metric-specific prompt (`revenue`, `expenses`, `profit`, `cashflow`) and `screenContext: {'page': 'dashboard', 'metric': ..., 'period': ...}`.
- **Area Chart Touch / Scrub:** Dragging or tapping along the 6-month curve snaps tooltip to that month showing formatted `Revenue` and `Expenses` in `MoneyText`.
- **Donut Slice Tap:** Highlights tapped expense category slice and corresponding legend row with exact amount & percentage.
- **Reminder `"View All"` Tap:** Opens `RemindersSheet` displaying all up to 8 reminders; tapping any reminder navigates to `BudgetsScreen` (`budget`) or `InvoicesScreen` (`invoice`).

---

## 9. Validation, Error, Loading, and Empty States

- **Initial Loading (`loading && !hasValue`):** Renders `DashboardSkeleton` (`APP-01`) mirroring the 4 KPI cards, AreaChart box, AI card, and list rows. Never blocks the entire shell with a modal spinner.
- **Refreshing (`hasValue && isLoading`):** Keeps existing cards interactive with a thin top `LinearProgressIndicator` (`primary`).
- **Fatal Error (`GET /dashboard/summary` fails with no cached data):**
  - `403 BUSINESS_READ_ONLY` → handled globally (`APP-04` `BusinessReadOnlySheet`).
  - `NetworkFailure` / `5xx` → `AfabEmptyState` error variant with `"Unable to load dashboard"`, concise localized message, and `"Retry"` `AfabButton`.
- **Non-Fatal Sub-Failures (`GET /ai/pulse` or `GET /customers/summary` fails):** Silently degrades (`AIInsightsCard` falls back to deterministic `summary` calculations; `TopCustomers` shows empty state).
- **Empty States:**
  - Zero revenue & expenses across 6 months → `RevenueChart` displays `"Awaiting data"` badge and `"Add your first transaction to visualize live cash flow"` subtitle with flat zero baseline.
  - `expenseCategories.isEmpty` → neutral `#374151` empty donut ring with `0.00` center total and localized `"No categorized expenses"` legend notice.
  - `transactions.isEmpty` → `AfabEmptyState` with `"No transactions recorded yet"` + `"Add Transaction"` CTA.
  - `budgets.budgets.isEmpty` → dashed `AfabInsetPanel` with `"Create one now"` link.
  - `reminders.isEmpty` → `"No upcoming reminders"` panel.
  - `customers.isEmpty` → `"No customers yet"` panel.

---

## 10. Localization (EN/AR) and RTL Behavior

- **ARB Keys:** Uses migrated `Dashboard.*` keys (`welcome`, `kpi`, `charts`, `ai`, `transactions`, `reminders`, `customers`, `budgets`, `banner`) plus new keys fixing Web omissions:
  - `kpiVsPrevious7Days` (`"vs previous 7 days"` / `"مقارنة بآخر 7 أيام"`)
  - `kpiVsLastMonth` (`"vs last month"` / `"مقارنة بالشهر الماضي"`)
  - `kpiVsLastYear` (`"vs last year"` / `"مقارنة بالعام الماضي"`)
  - `chartsRevenueSubtitle6m` (`"Trailing 6 months cash flow"` / `"التدفق النقدي لآخر 6 أشهر"`)
  - Localized empty-state copy for `RecentTransactions`, `ReminderCard`, `TopCustomers`, `AIInsightsCard` (removing hardcoded English strings in `RecentTransactions.tsx`, `ReminderCard.tsx`, `TopCustomers.tsx`).
- **Time-of-Day Greeting:** Select `goodMorning` / `goodAfternoon` / `goodEvening` (or `*Generic` when `firstName` is blank) using local time instead of Web's hardcoded `tWelcome("title")`.
- **Month Labels:** Parse `RevenueDataPoint.month` (`"YYYY-MM"`) with `DateFormat.MMM(locale)` using Gregorian calendar (`08_LOCALIZATION_AND_RTL.md`).
- **RTL Rules:**
  - `RevenueChart` time-series X-axis flows **left-to-right chronologically** in both EN and AR (matching Web Recharts).
  - All `MoneyText` values and percentage badges (`+12.5%`, `-4.2%`) are wrapped in `Directionality(textDirection: TextDirection.ltr)` with `FontFeature.tabularFigures()` and Western digits `0-9`.
  - Directional arrows (`ArrowRight` in `AIInsightsCard`, `BudgetOverviewCard`, `UpgradeBanner`) set `matchTextDirection: true`.

---

## 11. Accessibility and Responsive Guardrails

- **Touch Targets:** KPI `Ask Copilot` icon button uses `SizedBox(width: 48, height: 48)` hit target (always visible on touch devices rather than `opacity-0 group-hover:opacity-100` which is unreachable on touchscreens!).
- **Monetary Scaling:** Every `MoneyText` uses `FittedBox(fit: BoxFit.scaleDown)` so large 3-decimal amounts (e.g., `TND 1,245,890.500`) never clip or overflow on `320dp` phones.
- **Semantics:**
  - Charts provide `Semantics(label: ...)` summarizing revenue vs expense range or top expense category for TalkBack/VoiceOver users.
  - Budget progress bars expose semantic percentage values (`"Marketing budget, 85% consumed"`).
- **Reduced Motion:** Disable sparkline/chart entry animations when `MediaQuery.disableAnimationsOf(context)` is `true`.

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **`ExpenseCategories` `$0.00` Bug (`ExpenseCategories.tsx:9,64`):** Web runs `parseFloat("USD 500.00")` which yields `NaN` → displays `$0.00` total and items. **Mobile Fix:** Read numeric `ExpenseCategory.value` (`Decimal`) directly and format via `MoneyFormatter` with 3-decimal ISO-4217 support (`TND`/`KWD`/etc.).
2. **`ReminderCard` Icon Mismatch (`ReminderCard.tsx:10-25`):** Web switches on `"Tax"`, `"Meeting"`, `"Subscription"` while `DashboardService.java` emits `"budget"` and `"invoice"`. **Mobile Fix:** Explicitly handle `"budget"` (`PiggyBank`) and `"invoice"` (`FileText`) case-insensitively alongside legacy types.
3. **`ReminderCard` Dead `"View all"` Button (`ReminderCard.tsx:31`):** Web button has no `onClick`. **Mobile Fix:** Opens `RemindersSheet` with tap-through links to `/budgets` and `/invoices`.
4. **Hardcoded `"vs last month"` on KPIs (`KpiCard.tsx:155`):** Web ignores `WEEKLY`/`YEARLY` selection. **Mobile Fix:** Dynamic comparison caption matching selected `DashboardPeriod`.
5. **Inaccurate `"last 7 days"` Subtitle (`dashboard.json:57`):** `FinanceStatsService` returns 6 months. **Mobile Fix:** Displays `"Trailing 6 months cash flow"`.
6. **Hover-Only `Ask Copilot` Button on KPIs (`KpiCard.tsx:95`):** Hidden via `opacity-0 group-hover:opacity-100`. **Mobile Fix:** Always visible, unobtrusive `28dp` pill inside `48x48dp` tap area.
7. **Tailwind Color Strings in `TransactionItem.color` (`DashboardSummaryDTO.java:196`):** `"bg-emerald-500"` / `"bg-purple-500"` are Web CSS classes. **Mobile Fix:** Map via `tx.isCredit` to `AfabColors.success` / `AfabColors.primary`.
8. **Generic Row Links (`RecentTransactions.tsx:75`, `TopCustomers.tsx:65`):** Web links to list pages instead of detail views. **Mobile Fix:** Direct deep navigation to `TransactionDetailsScreen(id)` and `CustomerDetailsScreen(id)`.

---

## 13. Testing and Verification Plan

- **Unit Tests (`test/unit/dashboard/`):**
  - `DashboardSummary.fromJson` parses `ExpenseCategory.value` (`500.0` while `amount` is `"TND 500.000"`) into `Decimal('500.000')` and sums total accurately.
  - `ReminderItem` maps `"budget"` and `"invoice"` types and priorities.
  - Period mapping (`weekly`, `monthly`, `yearly` → `"weekly"`, `"month"`, `"year"`).
- **Widget & Golden Tests (`test/widget/dashboard/dashboard_screen_test.dart`):**
  - Renders all 4 states: `DashboardSkeleton` loading, error + retry, populated data, and empty workspace.
  - Verifies `ExpenseCategories` donut displays non-zero formatted total (`TND 1,250.000`, never `$0.00`).
  - Verifies `ReminderCard` renders `PiggyBank` / `FileText` icons and opens `RemindersSheet` on `"View all"`.
  - Verifies `UpgradeBanner` hidden when `planSlug == "pro"` and visible on `"free"` / `"plus"`.
  - Responsive & RTL sweep at `320x568`, `390x844`, `768x1024`, `1280x800` in `en` and `ar` with `1.3x` text scale (`0` overflow errors).

---

## 14. Dependencies and Risks

- **Package Dependencies:** `flutter_riverpod`, `go_router`, `fl_chart`, `decimal`, `intl`, `cached_network_image`, `lucide_icons_flutter`, `shimmer`.
- **Technical & Product Risks:**
  - **Cold Ollama Pulse Latency:** `GET /api/v1/ai/pulse` executes deterministic + heuristic checks; if slow or unavailable, `aiPulseProvider` MUST remain non-blocking with independent timeout so dashboard KPIs render immediately.
  - **2-Decimal vs 3-Decimal Formatting Divergence:** Backend `FinanceStatsService.formatMoney()` formats string `value` with `setScale(2)` even for `TND`, whereas `rawValue` (`BigDecimal`) retains full precision (`03_API_CONTRACT_CATALOG.md`, `13_RISKS_AND_TECHNICAL_DECISIONS.md` ADR-03). Mobile always formats `rawValue` / `value` (`Decimal`) using `MoneyFormatter` (`3` decimals for `TND`/`KWD`, etc.).
  - **App Store Billing Policy:** `UpgradeBanner` leads to `/plans`, which triggers Stripe Checkout; mobile release requires stakeholder decision on StoreKit/Play Billing vs companion-app web billing (`13_RISKS_AND_TECHNICAL_DECISIONS.md`).
