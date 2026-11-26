# `FIN-07` — Revenue Screen (`RevenueScreen`)

> **Domain:** Financial Core (`features/revenue`)
> **Priority:** P1 (Revenue Analytics & Ledger — Fixes `EXPENSE` Default Bug, Unfiltered Sources, Status Color & `totalInvoices` Clarity)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-07` |
| **Screen Name** | `RevenueScreen` |
| **Route Path (`GoRouter`)** | `/revenue` (Accessed via `MoreHubScreen` on Phone; Tablet Rail item `Revenue`) |
| **Feature Module** | `lib/features/revenue/presentation/screens/revenue_screen.dart` |
| **Web Source Equivalent** | `Web/project/frontend/app/[locale]/(dashboard)/dashboard/revenue/page.tsx` + `lib/api/revenue.ts` |
| **Backend Controllers** | `RevenueController.java` (`GET /api/v1/revenue/summary`, `GET /api/v1/revenue`), `CategoryController.java` (`GET /api/v1/categories`) |
| **Access Level** | Authenticated + Active Business Member (`EDITABLE` required for Create/Edit/Delete; `READ_ONLY` allows viewing & export) |

---

## 2. Purpose & User Jobs

1. **Track Revenue Performance:** View cash-basis `COMPLETED` income KPIs (`Total Revenue`, `Average per Day`, `Highest Revenue Day`, and `Completed Income Entries`) across `WEEKLY`, `MONTHLY`, and `YEARLY` periods.
2. **Visualize Income Velocity & Sources:** Analyze daily inflow via an emerald Area Chart and income category shares via a Donut Chart, alongside Gross vs Net Revenue breakdown.
3. **Filter & Inspect Income Entries:** Search income transactions, filter strictly by `INCOME` categories/sources, inspect unified details (`FIN-02`), record new revenue (`FIN-03` defaulting to `INCOME`), or export revenue CSV.

---

## 3. Navigation & Entry/Exit Flows

### Entry Points
- **Phone (`< 600dp`):** `MoreHubScreen` → `Money & Operations` → `Revenue`, or `DashboardScreen` Revenue KPI card.
- **Tablet (`>= 600dp`):** `NavigationRail` item `Revenue`.

### Exit Points
| Trigger | Destination | Presentation |
|---|---|---|
| Tap `+ Create New Revenue Entry` / FAB | `FIN-03` (`AddEditTransactionScreen`, `mode: create`, **`initialType: TransactionType.income`**) | Full-screen modal / dialog |
| Tap Revenue row / `Eye` action | `FIN-02` (`TransactionDetailsScreen`) | Push route (replaces Web's stripped inline modal) |
| Tap `View Invoices` (optional cross-link) | `InvoicesScreen` (`/invoices`) | Push route |
| Tap `Export CSV` | Native OS Share Sheet (`share_plus`) | Exports UTF-8 BOM CSV |
| Tap `Ask Copilot` | `GlobalCopilotSheet` | Preloaded with `screenContext: { page: "revenue", period }` |

---

## 4. Layout & Visual Architecture

- **AppBar / Header:** Title `Revenue`, subtitle, `PeriodSelector` (`WEEKLY`, `MONTHLY`, `YEARLY`), `Export CSV`, and `+ New Revenue` primary button / FAB.
- **KPI Strip (4 `AfabKpiCard`s):**
  - Phone: 2x2 grid; Tablet `>= 1024dp`: 4-column row.
  1. `Total Revenue`: `summary.totalRevenue` + `"{summary.totalInvoices} completed entries"` subtitle.
  2. `Average per Day`: `summary.avgPerDay` + active `period`.
  3. `Highest Revenue Day`: `summary.highestRevenueAmount` + localized `summary.highestRevenueDate`.
  4. `Completed Income Count` *(Backend field `summary.totalInvoices`)*: `summary.totalInvoices.toString()` + clear clarifying caption `"Completed income entries"` (NOT `/api/v1/invoices` entity count!).
- **Analytics Charts Section (`fl_chart`):**
  - **Revenue Overview Area Chart:** Emerald `#10B981` stroke (`2.5dp`), emerald gradient fill (`35% -> 0%`), header showing `summary.totalRevenue` + `"{summary.totalInvoices} completed ({period})"`. Uses `summary.dailyOverview[]` (or honest empty state when zero).
  - **Revenue by Source Donut Chart:** `PieChart` with center `summary.totalRevenue` + `"TOTAL"`, colored via `ColorParser.parseHex(src.color)` with fallback palette (`#10B981`, `#8B5CF6`, `#059669`, `#64748B`, `#F59E0B`), plus source legend list.
- **Side Analytics Widgets:**
  - **Gross vs Net Revenue Summary Card (`AfabCard`):**
    - `Gross Revenue`: `summary.grossRevenue`
    - `Discounts`: `-{summary.discounts}` (danger dot)
    - `Refunds`: `-{summary.refunds}` (danger dot)
    - Divider + `Net Revenue`: `summary.netRevenue` (bold emerald `MoneyText`).
    - Subtle footnote when `discounts == 0 && refunds == 0`: `"Discounts & refunds are not tracked separately on cash-basis entries"`.
  - **Top Products & Streams Card:** When `summary.topProducts` is empty (current backend `FinanceStatsService.java:245` returns `List.of()`), show honest empty state `"Product-level attribution uses invoice line items"` + optional link to `InvoicesScreen`.
- **Revenue Ledger Section:**
  - Search field (`350ms` debounce) + Source/Category picker (**strictly filtered to `cat.type == 'INCOME'`**).
  - Structured `TransactionListCard`s on `< 840dp` / Data table on `>= 840dp`, with pagination (`size = 15`).

---

## 5. UI Components & Interactive Controls

| Component | Behavior |
|---|---|
| **`CreateRevenueButton` / FAB** | Launches `FIN-03` with `initialType: TransactionType.income` (fixing Web's `EXPENSE` default bug!). |
| **`RevenueSourceFilter`** | Lists only `categories.where((c) => c.type == 'INCOME')`. |
| **`RevenueAreaChart`** | `fl_chart` emerald `LineChart`; handles 0-point empty state and 1-point single-marker rendering cleanly. |
| **`GrossNetSummaryCard`** | Tabular `MoneyText` rows with `Directionality.ltr` amounts. |
| **`RevenueStatusBadge`** | Uses semantic `AfabStatusBadge` (`COMPLETED` → green, `PENDING` → amber, `CANCELLED` → red). |

---

## 6. Data Requirements & API Contracts

### 6.1 `GET /api/v1/revenue/summary?period={week|month|year}`
- **Backend (`FinanceStatsService.java:174-248`):** Cash-basis `COMPLETED` root `INCOME` transactions within resolved period range.
- **Response (`200 OK` — `RevenueSummaryDTO`):**
  ```json
  {
    "totalRevenue": 15200.00,
    "grossRevenue": 15200.00,
    "discounts": 0,
    "refunds": 0,
    "netRevenue": 15200.00,
    "avgPerDay": 608.00,
    "highestRevenueAmount": 5000.00,
    "highestRevenueDate": "2026-11-12",
    "totalInvoices": 14,
    "currency": "USD",
    "revenueBySource": [{ "name": "Sales", "amount": 12000.00, "percentage": 78.9, "color": "#10b981" }],
    "topProducts": [],
    "dailyOverview": [{ "date": "2026-11-12", "amount": 5000.00 }]
  }
  ```
- **Critical Semantic Note (`FinanceStatsService.java:229-238`):**
  - `totalInvoices` is actually `countCompletedByBusinessAndTypeAndDateRange(..., "INCOME", ...)`, i.e. the count of completed `INCOME` transactions (manual + invoice payments) in the period!
  - `discounts` and `refunds` are hardcoded `BigDecimal.ZERO`, so `grossRevenue == netRevenue == totalRevenue`.
  - `topProducts` is hardcoded `List.of()`.

### 6.2 `GET /api/v1/revenue?categoryId=&search=&page=0&size=15`
- **Backend (`RevenueController.java:32-48`):** Delegates to `transactionService.getTransactions(..., "INCOME", categoryId, search, page, size)`. Same period-filter caveat as `Expenses`: `/revenue` lists all-time matching `INCOME` transactions regardless of `period`.

### 6.3 `GET /api/v1/categories`
- Client filters to `type == "INCOME"`.

---

## 7. State Management & Data Flow

```text
revenuePeriodProvider (StateProvider<ApiPeriod>, default monthly)
revenueListFilterProvider (categoryId, search debounced 350ms, page)
  ├──► revenueSummaryProvider -> GET /revenue/summary?period=...
  └──► revenueListProvider -> GET /revenue?categoryId=&search=&page=&size=15
```

- Mutations via `FIN-02` / `FIN-03` invalidate `revenueSummaryProvider`, `revenueListProvider`, `transactionListProvider`, and `dashboardSummaryProvider`.

---

## 8. Business Logic, Validation & Edge Cases

1. **Create Defaults to `INCOME`:** Entering `FIN-03` from `RevenueScreen` must pass `initialType: TransactionType.income` so the user doesn't accidentally log an expense while on the Revenue screen.
2. **Chart Bounds Safety:** Guard `fl_chart` against empty `dailyOverview` (render empty state) and single-day `dailyOverview` (`minX`/`maxX` padding).
3. **`totalInvoices` Clarification:** Display KPI title `"Completed Income"` (or `"Total Invoices / Entries"` with sub-label `"Completed income transactions"`) so users do not confuse it with unpaid/draft invoices on `InvoicesScreen`.
4. **Read-Only Workspace:** Disable `+ Create New Revenue Entry` when `activeBusiness.editable == false`.

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **Create Revenue Button Opens `EXPENSE` Form:** `revenue/page.tsx:683` renders `<AddTransactionModal>` without a default type, and `AddTransactionModal.tsx:31` defaults to `"EXPENSE"`. | `revenue/page.tsx:683-689`, `AddTransactionModal.tsx:31` | Mobile passes `initialType: TransactionType.income` to `FIN-03`. |
| **Shows `EXPENSE` Categories in "All Sources" Filter:** `revenue/page.tsx:96,404` displays all categories. | `revenue/page.tsx:96,404` | Mobile filters source picker strictly to `type == "INCOME"`. |
| **Hardcoded Green Status Badge for ALL Statuses:** `revenue/page.tsx:481-484` shows `PENDING`/`CANCELLED` as emerald green. | `revenue/page.tsx:481-484` | Map `COMPLETED` → green, `PENDING` → amber, `CANCELLED` → red via `AfabStatusBadge`. |
| **Stripped Inline Detail Modal & Misleading `totalInvoices`:** Omits FX/anomalies/receipts/edit; implies `totalInvoices` is invoice count. | `revenue/page.tsx:239,614-680` | Route row taps to unified `FIN-02`; label `totalInvoices` accurately as completed income count. |
| **Hardcoded LTR & English Strings:** `left-3`, `text-left`, `text-right`, `"completed"`, `"entries"`, `"No products or streams configured yet"`. | `revenue/page.tsx:217,263,377,424,585` | Logical directional alignment + full EN/AR localization. |

---

## 10. Design Tokens & Visual Styling

- **Area Chart Accent:** `#10B981` (`AfabColors.success`) stroke + vertical emerald fade.
- **Amount Foreground:** `+` `#10B981` (light) / `#34D399` (dark).
- **Source Donut Fallback Palette:** `[#8B5CF6, #10B981, #059669, #64748B, #F59E0B]` (using `#8B5CF6` & `#10B981` crisp tokens).

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** `revenue.json` (`36` keys) + new ARB keys for `"Completed income entries"`, `"Discounts & refunds tracked via adjustments"`, `"Product-level attribution uses invoice line items"`, and chart empty copy.
- **RTL Rules:** `RevenueAreaChart` X-axis stays chronological LTR; `MoneyText` uses `Directionality.ltr` and `tabularFigures`.

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` & `compact` (`< 600dp`) | 2x2 KPI grid → Area Chart (`220dp`) → Source Donut → Gross/Net Card → Top Products Card → Income `TransactionListCard`s. |
| `medium` (`600–839dp`) | 2x2 KPI grid, 2-col chart row, full-width ledger. |
| `expanded` (`>= 840dp`) | 4-col KPI row, `8:4` Area + Donut split, `9:3` Data Table + Side Cards split. |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** Semantic readouts on KPI deltas, donut slices, and Gross/Net rows; `48dp` minimum controls.
- **Security:** JWT + `X-Business-Id`; no unauthenticated exposure of revenue figures in logs.
- **Performance:** Concurrent fetch of `GET /revenue/summary` and `GET /revenue`; `350ms` search debounce.

---

## 14. Dependencies and Risks

- **Dependencies:** `FIN-02` (`TRANSACTION_DETAILS_SCREEN.md`), `FIN-03` (`ADD_EDIT_TRANSACTION_SCREEN.md`), `InvoicesScreen`, `fl_chart`, `share_plus`.
- **Risks & Mitigations:**
  1. **`totalInvoices` Naming Confusion:** Backend returns completed `INCOME` transaction count under JSON key `totalInvoices`. *Mitigation:* Clarify label in UI without breaking DTO deserialization.
  2. **Empty `topProducts` & Zero `discounts`/`refunds`:** Stubbed on backend (`FinanceStatsService.java:236-245`). *Mitigation:* Render honestly without inventing client-side numbers.
