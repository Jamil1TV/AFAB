# `FIN-06` — Expenses Screen (`ExpensesScreen`)

> **Domain:** Financial Core (`features/expenses`)
> **Priority:** P1 (Expense Analytics & Ledger — Fixes Unfiltered Categories, Status Badge Color Bug & Stale Phase 13 Copy)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-06` |
| **Screen Name** | `ExpensesScreen` |
| **Route Path (`GoRouter`)** | `/expenses` (Accessed via `MoreHubScreen` on Phone; Tablet Rail item `Expenses`) |
| **Feature Module** | `lib/features/expenses/presentation/screens/expenses_screen.dart` |
| **Web Source Equivalent** | `Web/project/frontend/app/[locale]/(dashboard)/dashboard/expenses/page.tsx` + `lib/api/expenses.ts` |
| **Backend Controllers** | `ExpenseController.java` (`GET /api/v1/expenses/summary`, `GET /api/v1/expenses`), `CategoryController.java` (`GET /api/v1/categories`) |
| **Access Level** | Authenticated + Active Business Member (`EDITABLE` required for Create/Edit/Delete; `READ_ONLY` allows viewing & export) |

---

## 2. Purpose & User Jobs

1. **Analyze Spending Performance:** Track cash-basis `COMPLETED` expense KPIs (`Total Expenses`, `Avg per Day`, `Highest Expense`, `Categories`, `Recurring`) for `WEEKLY`, `MONTHLY`, or `YEARLY` periods.
2. **Visualize Spend Trends & Category Share:** Inspect daily spending trajectory via an interactive Area Chart and category distribution via a Donut Chart + top spending progress bars.
3. **Filter & Audit Expense Entries:** Search expense records by description or filter strictly by `EXPENSE` categories, inspect unified details (`FIN-02`), record new expenses (`FIN-03` defaulting to `EXPENSE`), or export expense CSV.
4. **Navigate to Recurring Rules:** Replace Web's stale `"Phase 13"` placeholder on the Recurring widget with an honest cross-link to the implemented `RecurringTransactionsScreen` (`/recurring`).

---

## 3. Navigation & Entry/Exit Flows

### Entry Points
- **Phone (`< 600dp`):** `MoreHubScreen` → `Money & Operations` → `Expenses`, or `DashboardScreen` Expense card cross-link.
- **Tablet (`>= 600dp`):** `NavigationRail` item `Expenses`.

### Exit Points
| Trigger | Destination | Presentation |
|---|---|---|
| Tap `+ Create New Expense` / FAB | `FIN-03` (`AddEditTransactionScreen`, `mode: create`, `initialType: EXPENSE`) | Full-screen modal / dialog |
| Tap Expense row / `Eye` action | `FIN-02` (`TransactionDetailsScreen`) | Push route (replaces Web's stripped inline modal) |
| Tap `Recurring Subscriptions` CTA | `RecurringTransactionsScreen` (`/recurring`) | Push route (replaces stale Phase 13 message) |
| Tap `Export` | Native OS Share Sheet (`share_plus`) | Exports UTF-8 BOM CSV of loaded expenses |
| Tap `Ask Copilot` | `GlobalCopilotSheet` | Preloaded with `screenContext: { page: "expenses", period }` |

---

## 4. Layout & Visual Architecture

- **AppBar / Header:** Title `Expenses`, subtitle, `PeriodSelector` (`WEEKLY`, `MONTHLY`, `YEARLY`), `Export` button, and `+ Create Expense` primary button / FAB.
- **KPI Strip (5 `AfabKpiCard`s):**
  - Phone: 2-column horizontal/wrap grid (or swipeable 5-card strip + 2x2 grid). Tablet `>= 1024dp`: 5-column row.
  1. `Total Expenses`: `summary.totalExpenses` + `"{expensesData.totalElements} records"` subtitle.
  2. `Avg per Day`: `summary.avgPerDay` + period label (`WEEKLY` / `MONTHLY` / `YEARLY`).
  3. `Highest Expense`: `summary.highestExpenseAmount` + `summary.highestExpenseTitle`.
  4. `Categories`: `summary.categoryCount` (active expense categories in period).
  5. `Recurring`: `summary.recurringTotal` + `"{summary.recurringPercentage}% of total"` (or honest `"Manage rules ->"` link when `0`).
- **Analytics Charts Section (`fl_chart`):**
  - **Expenses Overview Area Chart:** Smooth curved `LineChart` with `AfabColors.primary` stroke (`2.5dp`), gradient fill (`primary 35% -> 0%`), dashed horizontal gridlines, tap/long-press dark tooltip (`Color(0xE60C101C)`), and header red pill showing `summary.totalExpenses`. Uses real `summary.dailyOverview[]` (or honest `"No expense data in this period"` empty chart state instead of fake zeroed points).
  - **By Category Donut Chart:** `PieChart` (`innerRadius` hollow center displaying `summary.totalExpenses` + `"TOTAL SPEND"`), slices colored via `ColorParser.parseHex(cat.color)` with fallback palette (`#8B5CF6`, `#F59E0B`, `#10B981`, `#F43F5E`, `#0EA5E9`), plus top 3 category legend rows.
- **Side Analytics Widgets:**
  - **Spending Categories Progress Card:** Top 4 categories from `summary.categoryBreakdown` with name, `MoneyText`, and proportional progress bar.
  - **Recurring Subscriptions Card:** If `summary.recurringList` is non-empty, renders items; when empty (current backend `FinanceStatsService.java:168` returns `List.of()`), renders an honest summary card: `"Recurring expense breakdown isn't aggregated here yet"` + `"Manage Recurring Rules"` button routing to `/recurring`.
- **Expenses Ledger Section:**
  - Search field (`350ms` debounce) + Category dropdown/sheet (**strictly filtered to `cat.type == 'EXPENSE'`**).
  - Structured `TransactionListCard`s on `< 840dp` / Data table on `>= 840dp`, with pagination footer (`size = 15`).

---

## 5. UI Components & Interactive Controls

| Component | Behavior |
|---|---|
| **`PeriodSelector`** | Updates `summary` (`GET /expenses/summary?period=week|month|year`). Note: see Section 6 caveat on `/expenses` list endpoint! |
| **`ExpenseAreaChart`** | `fl_chart` `LineChart`; chronological LTR X-axis even in Arabic RTL; interactive touch scrubber tooltip. |
| **`ExpenseCategoryDonut`** | `fl_chart` `PieChart`; tap slice highlights category and filters/scrolls legend. |
| **`ExpenseCategoryFilter`** | Filtered strictly to `categories.where((c) => c.type == 'EXPENSE')`. |
| **`ExpenseStatusBadge`** | Uses semantic `AfabStatusBadge` (`COMPLETED` → green, `PENDING` → amber, `CANCELLED` → red). |

---

## 6. Data Requirements & API Contracts

### 6.1 `GET /api/v1/expenses/summary?period={week|month|year}`
- **Backend (`FinanceStatsService.java:103-171`):** Cash-basis `COMPLETED` root `EXPENSE` transactions within resolved date range.
- **Response (`200 OK` — `ExpenseSummaryDTO`):**
  ```json
  {
    "totalExpenses": 2450.00,
    "avgPerDay": 98.00,
    "highestExpenseTitle": "AWS Cloud",
    "highestExpenseAmount": 850.00,
    "categoryCount": 4,
    "recurringTotal": 0,
    "recurringPercentage": 0.0,
    "currency": "USD",
    "categoryBreakdown": [{ "name": "Hosting", "amount": 850.00, "percentage": 34.7, "color": "#8b5cf6" }],
    "recurringList": [],
    "dailyOverview": [{ "date": "2026-11-01", "amount": 120.00 }]
  }
  ```
- **Backend Stub Note:** `recurringTotal` (`0`), `recurringPercentage` (`0.0`), and `recurringList` (`[]`) are intentionally stubbed in `FinanceStatsService.java:164-168`.

### 6.2 `GET /api/v1/expenses?categoryId=&search=&page=0&size=15`
- **Backend (`ExpenseController.java:32-48`):** Delegates to `transactionService.getTransactions(..., "EXPENSE", categoryId, search, page, size)`.
- **Contract Caveat:** `ExpenseController.getExpenses` does NOT accept `period`, `startDate`, or `endDate` query parameters (unlike `GET /transactions`). Therefore, summary KPIs/charts reflect `period`, while the `/expenses` table lists all-time matching `EXPENSE` entries (or mobile can query `GET /transactions?type=EXPENSE&startDate=...&endDate=...` if period-scoped list parity is desired — document clearly or match `/expenses` with a clear subtitle `"All-time expenses"`).

### 6.3 `GET /api/v1/categories`
- Loaded via `categoryListProvider`; client filters to `type == "EXPENSE"`.

---

## 7. State Management & Data Flow

```text
expensePeriodProvider (StateProvider<ApiPeriod>, default monthly)
expenseListFilterProvider (categoryId, search debounced 350ms, page)
  ├──► expenseSummaryProvider -> GET /expenses/summary?period=...
  └──► expenseListProvider -> GET /expenses?categoryId=&search=&page=&size=15
```

- Creating, editing, or deleting a transaction in `FIN-02` / `FIN-03` invalidates both `expenseSummaryProvider` and `expenseListProvider`.

---

## 8. Business Logic, Validation & Edge Cases

1. **Period Query Value Mapping:** `WEEKLY` → `"weekly"`, `MONTHLY` → `"monthly"`, `YEARLY` → `"yearly"` (`FinanceStatsService.java:370-386` accepts `"week"`, `"weekly"`, `"month"`, `"monthly"`, `"year"`, `"yearly"`).
2. **Chart Empty & Single-Point States:**
   - If `dailyOverview` is empty, show a clean `"No completed expenses in this period"` state inside the chart container instead of fabricating fake non-zero waves.
   - If `dailyOverview` has only 1 point, render a clean single-dot marker + baseline so `fl_chart` `minX == maxX` never crashes (`if (points.length == 1)` pad X bounds safely).
3. **Read-Only Workspace:** Disable `+ Create Expense` when `activeBusiness.editable == false`.
4. **CSV Export:** Reuse shared `CsvExporter` with `MoneyFormatter` minor-unit precision and UTF-8 BOM (`\uFEFF`) via `share_plus`.

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **Shows INCOME Categories in Expense Filter:** `expenses/page.tsx:103,421` renders all categories (`INCOME` + `EXPENSE`). | `expenses/page.tsx:103,421` | Strictly filter category picker to `type == "EXPENSE"`. |
| **Hardcoded Green Status Badge for ALL Statuses:** `expenses/page.tsx:498-501` renders `PENDING` and `CANCELLED` expenses in emerald green! | `expenses/page.tsx:498-501` | Map `COMPLETED` → green, `PENDING` → amber, `CANCELLED` → red via `AfabStatusBadge`. |
| **Stale `"Phase 13"` Copy on Recurring Widget:** Says `"Recurring subscriptions tracking will be active in Phase 13"` even though `/recurring` already exists! | `expenses/page.tsx:593` | Replace with honest empty copy + `"Manage Recurring Rules"` button navigating to `/recurring`. |
| **Stripped-Down Inline Detail Modal + `window.confirm()`:** Omits FX snapshot, anomalies, split items, receipts, edit, duplicate. | `expenses/page.tsx:621-687` | Route row taps to unified `FIN-02` `TransactionDetailsScreen`. |
| **Hardcoded LTR Classes & English Labels:** `left-3`, `text-left`, `text-right`, `"Total Spend"`, `"Visual analysis of business spend over time"`, `"records"`. | `expenses/page.tsx:224,274,362,394,441` | Use `AlignmentDirectional` / `EdgeInsetsDirectional` and ARB localization keys. |

---

## 10. Design Tokens & Visual Styling

- **Area Chart Accent:** Stroke `AfabColors.primary` (`#8B5CF6` or user accent), vertical gradient fill `35% -> 0%`, header total dot `#EF4444`.
- **Category Donut Fallback Palette:** `[#8B5CF6, #F59E0B, #10B981, #F43F5E, #0EA5E9]`.
- **KPI Icons:** `Wallet`, `Calendar`, `TrendingUp`, `Layers`, `Repeat`.

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** `expenses.json` (`34` keys) + new ARB keys for `"Visual analysis of business spend over time"`, `"Total Spend"`, `"Manage Recurring Rules"`, `"No completed expenses in this period"`, and pagination strings.
- **RTL Rules:**
  - `ExpenseAreaChart` X-axis flows left-to-right chronologically in both EN and AR (`Directionality.ltr`).
  - All `MoneyText` values use `Directionality.ltr` + `tabularFigures`.

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` & `compact` (`< 600dp`) | Vertical stack: 2-col KPI wrap → Area Chart (`220dp` height) → Category Donut → Top Categories & Recurring link card → Expense `TransactionListCard`s. |
| `medium` (`600–839dp`) | 3-col KPI wrap, side-by-side Area + Donut charts, card list. |
| `expanded` (`>= 840dp`) | 5-col KPI row, `8:4` Area + Donut split, `9:3` Data Table + Side Widgets split matching Web desktop grid. |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** Chart touch tooltips expose semantic value readouts; progress bars announce `"Hosting, 34.7%, 850 dollars"`; `48dp` minimum touch targets.
- **Security:** JWT + `X-Business-Id`; `app_logger` redacts amounts/descriptions.
- **Performance:** `ExpenseSummary` and `ExpenseList` load concurrently via `Future.wait`; `350ms` search debounce with `CancelToken`.

---

## 14. Dependencies and Risks

- **Dependencies:** `FIN-02` (`TRANSACTION_DETAILS_SCREEN.md`), `FIN-03` (`ADD_EDIT_TRANSACTION_SCREEN.md`), `RecurringTransactionsScreen`, `fl_chart`, `share_plus`.
- **Risks & Mitigations:**
  1. **Period Scope Mismatch Between Summary & List:** `/expenses/summary` filters by `period`, while `/expenses` does not accept `period`/`startDate`/`endDate`. *Mitigation:* Label list header `"All Expense Entries"` (or optionally pass `startDate`/`endDate` to `GET /transactions?type=EXPENSE` if user toggles `"Match Selected Period"`).
  2. **Stubbed `recurringList`:** Backend returns empty `recurringList`. *Mitigation:* Never hide the broken promise with fake data; link directly to `RecurringTransactionsScreen`.
