# `FIN-01` — Transactions Screen (`TransactionsScreen`)

> **Domain:** Financial Core (`features/transactions`)
> **Priority:** P1 (Core Ledger Hub — Primary Root of Bottom Nav Tab 1 `Finance`)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-01` |
| **Screen Name** | `TransactionsScreen` (Master-Detail with `TransactionDetailsPane` on `>= 840dp` tablets) |
| **Route Path (`GoRouter`)** | `/transactions` (Root destination of Bottom Nav Tab 1 `Finance`; Tablet Rail item `Transactions`) |
| **Feature Module** | `lib/features/transactions/presentation/screens/transactions_screen.dart` |
| **Web Source Equivalent** | `Web/project/frontend/app/[locale]/(dashboard)/dashboard/transactions/page.tsx` + `components/dashboard/QuickAddBar.tsx` + `lib/nlp-transaction-parser.ts` + `lib/csv-export.ts` |
| **Backend Controllers** | `TransactionController.java` (`/api/v1/transactions`), `CategoryController.java` (`/api/v1/categories`) |
| **Access Level** | Authenticated + Verified + Onboarded (`EDITABLE` required for Create, Quick-Add, Edit, Duplicate, Split, Delete; `READ_ONLY` allows viewing & CSV export only) |

---

## 2. Purpose & User Jobs

1. **Monitor Business Cash Ledger:** View real-time `Total Inflow`, `Total Outflow`, `Net Balance`, and `Total Transactions` KPIs alongside a chronological ledger of all business transactions.
2. **Search & Multi-Facet Filter:** Quickly locate transactions using debounced description search, period selector (`WEEKLY` / `MONTHLY` / `YEARLY` or custom date range), type (`INCOME` / `EXPENSE`), category, status (`COMPLETED` / `PENDING` / `CANCELLED`), payment method (`BANK_TRANSFER`, `CARD`, `CREDIT_CARD`, `CASH`, `OTHER`), and tax-deductible toggle.
3. **Rapid Natural-Language Entry (Quick-Add):** Log expenses or income in seconds using a natural-language input bar/sheet (e.g., `"Received $1,500 from Client yesterday via bank"` or `"Paid 45.50 TND to Figma"`), fixing Web's unmounted `QuickAddBar` and broken comma-thousands parser.
4. **Launch Financial Workflows:** Open transaction details (`FIN-02`), record/edit/duplicate a transaction (`FIN-03`), create a multi-category split (`FIN-04`), manage categories (`FIN-05`), or export filtered records to UTF-8 CSV via native share sheet.

---

## 3. Navigation & Entry/Exit Flows

### Entry Points
- **Phone (`< 600dp`):** Bottom Navigation Tab `1` (`Finance` / `المالية`).
- **Tablet (`>= 600dp`):** `NavigationRail` primary item `Transactions`.
- **Deep Links / Cross-Links:** `DashboardScreen` `"View All"` on Recent Transactions card; `GlobalCopilotSheet` action `"View in Ledger"`.

### Exit Points & Sub-Flows
| Trigger | Destination | Presentation |
|---|---|---|
| Tap transaction row / `Eye` action | `FIN-02` (`TransactionDetailsScreen`) | Push route on `< 840dp`; updates right-hand `TransactionDetailsPane` on `>= 840dp` |
| Tap `+ Add Transaction` / FAB | `FIN-03` (`AddEditTransactionScreen`, `mode: create`) | Full-screen modal on phone; centered dialog (`maxWidth: 640dp`) on tablet |
| Row action `Edit` | `FIN-03` (`AddEditTransactionScreen`, `mode: edit`) | Full-screen modal / dialog |
| Row action `Duplicate` | `FIN-03` (`AddEditTransactionScreen`, `mode: duplicate`) | Full-screen modal / dialog (uses `POST`, never `PUT`) |
| Tap `Split Expense` / `Split` | `FIN-04` (`SplitTransactionScreen`) | Full-screen modal / dialog |
| Tap `Manage Categories` | `FIN-05` (`ManageCategoriesScreen`) | Push route / sheet |
| Tap `Quick Add` chip/bar | `QuickAddSheet` (or inline expandable bar) | Draggable bottom sheet / inline card |
| Tap `Delete` row action | `DeleteTransactionConfirmDialog` | AlertDialog confirmation → `DELETE /api/v1/transactions/{id}` |
| Tap `Export CSV` | Native OS Share Sheet (`share_plus`) | Exports generated `.csv` file with UTF-8 BOM |
| Tap `Ask Copilot` (AppBar) | `GlobalCopilotSheet` | Preloaded with `screenContext: { page: "transactions", period, filters }` |

---

## 4. Layout & Visual Architecture

### Phone Layout (`< 600dp`)
- **Persistent Shell AppBar:** Business Switcher pill (leading), `Ask Copilot` + `Notifications` bell (trailing).
- **Sticky/Top Header Block:**
  - Screen title + subtitle (collapsed cleanly under `SliverAppBar` on scroll).
  - Horizontal scrollable action toolbar: `PeriodSelector` (`WEEKLY` / `MONTHLY` / `YEARLY`), `Manage Categories`, `Split`, `Export CSV`, plus primary `+ Add` FAB (anchored bottom-end above `NavigationBar` with `SafeArea` clearance).
- **Quick-Add Banner Card:** Compact `"Magic Quick-Add"` trigger bar (`Sparkles` icon + hint `"Paid $120 to Figma yesterday..."`) that expands inline or opens `QuickAddSheet` with live entity preview chips.
- **2x2 KPI Summary Grid:** `Total Inflow`, `Total Outflow`, `Net Balance`, `Total Transactions` (`AfabKpiCard` with `fl_chart` sparkline and `MoneyText`).
- **Search & Filter Strip:**
  - Full-width `AfabTextField` search input (`350ms` debounce, clear icon).
  - Horizontal filter pill bar: `Filters` button (shows active count badge, opens `TransactionFilterSheet` with all 7 filters) + quick-toggle chips (`Type`, `Status`, `Tax Write-offs`, `Payment Method`, `Clear All`).
- **Ledger List (`SliverList`):** Structured touch cards (`TransactionCard`) with infinite scroll / pagination footer (`Page X of Y`). No horizontal-scrolling desktop HTML tables on phones.

### Tablet Layout (`>= 600dp` / `>= 840dp`)
- **`600–839dp`:** `NavigationRail` (`72dp`) + 2-column KPI grid + single-column card/compact table list; tapping row pushes `FIN-02`.
- **`>= 840dp` Landscape Split Pane:**
  - **Left Master Pane (`58%` width):** Header actions, `QuickAddBar` inline, 4-column KPI strip, full inline filter bar (Search + Type + Category + Status + Payment Method + Date Range + Tax Write-off toggle), and structured interactive ledger table/list with sortable `Date` and `Amount` headers.
  - **Right Detail Pane (`42%` width):** Embedded `TransactionDetailsPane` (`FIN-02`) showing the currently selected transaction (`selectedTxProvider`), or an `AfabEmptyState` prompt (`"Select a transaction to inspect FX, splits, and receipts"`) when none is selected.

---

## 5. UI Components & Interactive Controls

| Component | Widget / Spec | Behavior & Actions |
|---|---|---|
| **Period Selector** | `AfabSegmentedBar` (`WEEKLY`, `MONTHLY`, `YEARLY`) | Computes `startDate` & `endDate` (see Section 8) and triggers `GET /transactions` (`page = 0`). |
| **KPI Cards (4)** | `AfabKpiCard` | `Total Inflow` (`success`), `Total Outflow` (`danger` / primary), `Net Balance` (`>= 0 ? success : danger`), `Total Transactions` (count). Note: Backend returns business-wide all-time totals on `TransactionResponseDTO`; see Section 6 caveat. |
| **Quick-Add Bar / Sheet** | `QuickAddBarWidget` | Live-parses text on every keystroke via `NlpTransactionParser`, displays preview chips (`Type`, `Amount`, `Description`, `Category`, `Date`, `PaymentMethod`, `TaxDeductible`), submits `POST /transactions`. |
| **Search Field** | `AfabTextField` | `350ms` debounce timer; suffix clear icon; resets `page = 0`. |
| **Filter Controls** | Quick chips + `TransactionFilterSheet` | Exposes `type`, `categoryId`, `status`, `paymentMethod`, `taxDeductible`, `startDate`, `endDate`, and `"Reset Filters"`. |
| **Transaction Row / Card** | `TransactionListCard` | Displays direction icon tile (`ArrowUpRight` emerald for `INCOME`, `ArrowDownLeft` `primary` for `EXPENSE`), `description`, short ref `#id.substring(0,8)`, anomaly/meta badges (`Duplicate` amber, `+X%` hike indigo/primary, `Tax` teal, `Split` primary), category color dot + name, `transactionDate`, `paymentMethod`, signed `MoneyText`, `AfabStatusBadge` (`COMPLETED`/`PENDING`/`CANCELLED`), and overflow menu (`View`, `Duplicate`, `Edit`, `Delete`). |
| **Sort Toggle** | Header buttons / Sort pill (`Date ↓/↑`, `Amount ↓/↑`) | Sorts loaded page items cleanly; resets when server filter changes. |
| **Pagination Controls** | `PaginationBar` (`Prev`, `Page X / Y`, `Next`, `Showing A–B of N`) | Shown when `totalPages > 1`; scrolls list to top on page change. |
| **Delete Confirmation** | `DeleteTransactionDialog` | Shows description, category, type, signed `MoneyText`, date; disables buttons while `deleting`; calls `DELETE /transactions/{id}`. |

---

## 6. Data Requirements & API Contracts

### 6.1 `GET /api/v1/transactions`
- **Headers:** `Authorization: Bearer <jwt>`, `X-Business-Id: <uuid>`
- **Query Parameters:**
  - `type`: `INCOME` | `EXPENSE` (optional)
  - `categoryId`: `UUID` (optional)
  - `status`: `COMPLETED` | `PENDING` | `CANCELLED` (optional)
  - `paymentMethod`: `BANK_TRANSFER` | `CARD` | `CREDIT_CARD` | `CASH` | `OTHER` (optional)
  - `taxDeductible`: `true` | `false` (optional)
  - `startDate`: `YYYY-MM-DD` (ISO-8601 `LocalDate`, optional)
  - `endDate`: `YYYY-MM-DD` (ISO-8601 `LocalDate`, optional)
  - `search`: `String` (case-insensitive substring on `description`, optional)
  - `page`: `int` (default `0`, clamped `>= 0`)
  - `size`: `int` (default `15` on mobile ledger, backend clamps `1..100`)
- **Response (`200 OK` — `TransactionResponseDTO`):**
  ```json
  {
    "content": [ /* TransactionDTO[] */ ],
    "pageNumber": 0,
    "pageSize": 15,
    "totalElements": 42,
    "totalPages": 3,
    "totalInflow": 12500.0000,
    "totalOutflow": 4200.5000,
    "netBalance": 8299.5000,
    "currency": "TND"
  }
  ```
- **Backend Accounting Caveat (`TransactionService.java:130-132`):** `totalInflow`, `totalOutflow`, and `netBalance` on `TransactionResponseDTO` are summed across all non-deleted root transactions of the business (regardless of active `status`/`period`/`search` filters), whereas `content` and `totalElements` reflect the active query filters. Label KPIs clearly (`All-time Ledger Totals` vs `Filtered Results: N`).

### 6.2 `GET /api/v1/categories`
- Returns `List<CategoryDTO>` (`id`, `businessId`, `name`, `type`, `icon`, `color`, `systemDefault`). Used for category filter dropdown & Quick-Add NLP category matching.

### 6.3 `POST /api/v1/transactions` (Quick-Add)
- Sends `CreateTransactionRequest`: `{ type, amount, originalCurrency, description, transactionDate, categoryId?, paymentMethod, status: "COMPLETED", taxDeductible }`.
- Returns `201 Created` (`TransactionDTO`).

### 6.4 `DELETE /api/v1/transactions/{id}`
- Soft-deletes parent transaction and any child split items (`TransactionService.java:411-421`). Returns `204 No Content`.
- Guarded by `BusinessAccessGuard.assertEditable(business)` → returns `403 BUSINESS_READ_ONLY` if workspace is locked.

---

## 7. State Management & Data Flow

```text
transactionFilterProvider (Notifier<TransactionFilterState>)
  ├── period: ApiPeriod? (weekly | monthly | yearly | custom | all)
  ├── startDate / endDate: DateTime?
  ├── search: String (debounced 350ms -> debouncedSearchProvider)
  ├── type: TransactionType?
  ├── categoryId: String?
  ├── status: TransactionStatus?
  ├── paymentMethod: PaymentMethod?
  ├── taxDeductible: bool?
  ├── page: int (default 0, size 15)
  └── sortField: TransactionSortField? (date | amount), sortOrder: SortOrder
        │
        ▼
transactionListProvider (AsyncNotifier<TransactionPageResult>)
  ├── watches: activeBusinessIdProvider, transactionFilterProvider
  └── calls: TransactionRepository.getTransactions(...)
        │
        ├──► quickAddController (AsyncNotifier) -> POST /transactions -> invalidates transactionListProvider & dashboardSummaryProvider
        └──► deleteTransactionController -> DELETE /transactions/{id} -> clears selectedTxIdProvider if deleted & invalidates list/dashboard
```

- **Business Switch Invalidation:** Switching `activeBusinessIdProvider` automatically disposes/invalidates `transactionListProvider`, `categoryListProvider`, and clears `selectedTxIdProvider` on tablet split view.
- **Pull-to-Refresh:** `RefreshIndicator` invalidates `transactionListProvider` and `categoryListProvider`.

---

## 8. Business Logic, Validation & Edge Cases

1. **Period-to-Date Range Mapping:**
   - `WEEKLY`: `startDate = today - 6 days`, `endDate = today` (matches `FinanceStatsService.java:377` 7-day window).
   - `MONTHLY`: `startDate = firstDayOfMonth(today)`, `endDate = lastDayOfMonth(today)` (matches `FinanceStatsService.java:374`).
   - `YEARLY`: `startDate = Jan 1 of current year`, `endDate = Dec 31 of current year` (matches `FinanceStatsService.java:381`).
   - `ALL` (optional clear pill): `startDate = null`, `endDate = null` so users can inspect historical entries outside the current period.
2. **Quick-Add NLP Parser (`NlpTransactionParser`):**
   - **Type detection:** Checks income keywords (`received`, `earned`, `income`, `invoiced`, `deposit`, `sold`, `revenue`, `got paid`, `salary`, `refund from`, `client`, plus Arabic equivalents `استلمت`, `إيراد`, `دفعة عميل`) → `INCOME`, else `EXPENSE`.
   - **Amount extraction (Fixed):** Matches:
     1. Formatted thousands: `1,500`, `1,500.50`, `12,345.678` (`\b\d{1,3}(?:,\d{3})+(?:\.\d{1,4})?\b`) → strip `,`, parse `Decimal`.
     2. Decimal comma (EU/AR): `45,50` (`\b\d+,\d{1,3}(?!\d)`) → replace `,` with `.`, parse `Decimal`.
     3. Standard decimal/integer: `45`, `45.50`, `45.500` (`\b\d+(?:\.\d{1,4})?\b`).
     4. Optional currency symbols/codes (`$`, `€`, `£`, `¥`, `DT`, `TND`, `USD`, `EUR`, `GBP`, `AED`, `SAR`, `KWD`, `MAD`, `د.ت`).
   - **Payment method:** Matches `cash`/`bills` → `CASH`; `credit card` → `CREDIT_CARD`; `card`/`debit`/`visa`/`mastercard`/`amex` → `CARD`; `bank`/`wire`/`transfer`/`ach`/`direct deposit` → `BANK_TRANSFER`; `paypal`/`stripe`/`crypto` → `OTHER`.
   - **Validation:** Requires `parsed.amount != null && parsed.amount >= Decimal.parse('0.0001')` and `parsed.description.isNotEmpty`.
3. **CSV Export:**
   - Generates UTF-8 with BOM (`\uFEFF`) so Excel renders Arabic and special characters cleanly.
   - Escapes double quotes (`"` → `""`) and wraps fields in quotes; formats `amount` using `MoneyFormatter.rawDecimal(tx.amount, currency)` (preserving 3 decimals for `TND`/`KWD`, etc.).
   - If `totalElements > content.length`, offers choice in a quick prompt: *"Export current page (N rows)"* vs *"Export up to 100 matching rows"* (`size=100`).
4. **Read-Only Workspace:** When `activeBusiness.editable == false`, hide/disable `+ Add`, `Quick-Add`, `Split`, `Edit`, `Duplicate`, and `Delete`, and show an inline info chip explaining the workspace is in vault `READ_ONLY` mode.
5. **Client-Side Sort Caveat:** Backend `GET /transactions` always sorts by `transactionDate DESC, createdAt DESC`. Tapping `Date` or `Amount` sort sorts the currently fetched page; display a subtle tooltip/caption noting page-level sorting when `totalPages > 1`.

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **Dead `PeriodSelector`:** `period` state updates UI tabs, but `fetchTransactions` never passes `startDate` or `endDate` to `GET /transactions`. | `transactions/page.tsx:58,90-108` | Mobile maps `WEEKLY` / `MONTHLY` / `YEARLY` (plus optional `All` & custom range) to `startDate` and `endDate` query params. |
| **Missing Backend Filters in UI:** Web omits `paymentMethod`, `startDate`, and `endDate` filter controls despite `TransactionController.java:31-34` supporting them. | `transactions/page.tsx:379-442` | Mobile exposes all 7 backend filters (`type`, `categoryId`, `status`, `paymentMethod`, `taxDeductible`, `startDate`, `endDate`). |
| **Unmounted `QuickAddBar` + `"$1,500"` Comma Bug:** `QuickAddBar.tsx` is never imported anywhere; `nlp-transaction-parser.ts:50-54` turns `"$1,500"` into `1.5`. | `QuickAddBar.tsx`, `nlp-transaction-parser.ts:50-54` | Mobile mounts Quick-Add natively in Transactions and fixes the thousands-separator regex to parse `$1,500` as `1500`. |
| **Duplicate Calls `PUT /transactions/`:** `handleDuplicate` passes `{ ...tx, id: "" }` to `AddTransactionModal`, which treats non-null `transactionToEdit` as Edit mode. | `transactions/page.tsx:165-172` | Mobile passes explicit `TransactionFormMode.duplicate` to `FIN-03` so it invokes `POST /transactions`. |
| **Hardcoded `.toFixed(2)` in CSV Export:** Truncates 3-decimal currencies (`TND`, `KWD`) in CSV export. | `csv-export.ts:40` | Mobile formats CSV amounts using the currency's ISO-4217 minor-unit precision (`3` for `TND/KWD/BHD/OMR`, `0` for `JPY/KRW`, `2` default). |
| **Un-debounced Search:** Every keystroke immediately triggers an HTTP request. | `transactions/page.tsx:367` | Mobile applies a `350ms` debounce before triggering `GET /transactions`. |
| **Hardcoded English Strings in Table Pagination & Tax Pill:** `"Showing X to Y of Z results"`, `"Total items"`, `"Tax"`. | `transactions/page.tsx:349,666` | All strings localized in `app_en.arb` and `app_ar.arb`. |

---

## 10. Design Tokens & Visual Styling

- **Surfaces:** `AfabColors.background` (`#F8F9FB` light / `#060813` dark midnight), `AfabCard` (`surface`), `AfabInsetPanel` (`surfaceInset` for filter container and Quick-Add preview bar).
- **Direction & Amount Colors:**
  - `INCOME`: Icon tile `#10B981` (`success`), amount `+` in `#10B981` (light) / `#34D399` (dark).
  - `EXPENSE`: Icon tile `AfabColors.primary`, amount `-` in `textPrimary`.
- **Status Pills (`AfabStatusBadge`):**
  - `COMPLETED`: `success` (`#10B981` / `#34D399`)
  - `PENDING`: `warning` (`#F59E0B` / `#FBBF24`)
  - `CANCELLED`: `danger` (`#EF4444`)
- **Anomaly & Meta Badges:**
  - `Duplicate`: `warning` 10% tint + border
  - `Price Hike`: `primary` 10% tint + border
  - `Tax`: Teal (`#0D9488` / `#2DD4BF`) 10% tint
  - `Split`: `primary` 10% tint
- **Typography:** `tabularFigures` mandatory on all KPI figures, row amounts, and pagination counts; `MoneyText` with `FittedBox.scaleDown`.

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** `transactions.json` (`116` keys) + new keys for `paymentMethod` filter (`CREDIT_CARD` label), `All Time` period option, `pageLevelTotals` caption, and `QuickAddBar` labels/errors (`txQuickAddPlaceholder`, `txQuickAddButton`, `txQuickAddParsedAs`, `txQuickAddNoAmount`).
- **RTL Layout:**
  - Directional icons (`ChevronLeft`, `ChevronRight`, `ArrowRight`) use `matchTextDirection: true`.
  - Currency amounts inside `TransactionListCard`, KPIs, and `QuickAddBar` preview chips are wrapped in `Directionality(textDirection: TextDirection.ltr)` so `-$150.00` or `+DT 1,500.000` never reorders in Arabic RTL.
  - Dates use localized Gregorian formatting respecting `business.dateFormat`.
  - Quick-Add NLP parser accepts English keywords plus common Arabic triggers (`استلمت`, `دفعت`, `نقدا`, `تحويل`).

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` (`< 360dp`) | 1-col KPI stack or compact 2-col wrap; single-line compact `TransactionListCard`; filters inside bottom sheet only; FAB cleared above nav bar. |
| `compact` (`360–599dp`) | 2x2 KPI grid; horizontal quick-filter chips + filter sheet; full-width `TransactionListCard` with swipe/overflow actions. |
| `medium` (`600–839dp`) | `NavigationRail` (`72dp`); 2x2 or 4-col KPI row; `TransactionListCard` list; `FIN-02` opens as push route or side sheet. |
| `expanded` (`>= 840dp`) | Extended `NavigationRail` (`248dp` at `>= 1024dp`); inline `QuickAddBar`; 4-col KPI strip; **2-pane Master-Detail** (`58%` ledger table + `42%` live `TransactionDetailsPane`). |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** Minimum `48x48dp` touch targets on FAB, filter pills, pagination buttons, and row action triggers; semantic labels announcing `"Income 1,500 dollars, Client Payment, Completed"` per row.
- **Security:** All API calls require RAM-stored JWT + `X-Business-Id`; `app_logger` redacts transaction descriptions/amounts in release logs; temporary CSV export files are written to `getTemporaryDirectory()` and never left in public shared storage unnecessarily.
- **Performance:** `SliverList.builder` with `ValueKey(tx.id)` for smooth 60fps scrolling; `350ms` search debounce cancels pending requests with `Dio` `CancelToken`; category list cached per business session via Riverpod `keepAlive`.

---

## 14. Dependencies and Risks

- **Dependencies:** `FIN-02` (`TRANSACTION_DETAILS_SCREEN.md`), `FIN-03` (`ADD_EDIT_TRANSACTION_SCREEN.md`), `FIN-04` (`SPLIT_TRANSACTION_SCREEN.md`), `FIN-05` (`MANAGE_CATEGORIES_SCREEN.md`), `share_plus`, `path_provider`, `decimal`, `fl_chart`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  1. **KPI Totals vs Filtered List Mismatch:** `TransactionResponseDTO.totalInflow/totalOutflow/netBalance` are all-time business totals while `content` is filtered. *Mitigation:* Subtitle KPIs as `"All-time ledger"` and show filtered count separately.
  2. **Page-Only CSV & Page-Only Sorting:** Web exports only the current 15-row page and sorts only the current page. *Mitigation:* Support optional `size=100` batch fetch for filtered CSV export (or delegate full-period accounting export to `GET /reports/export/csv` on `REPORTS_SCREEN`).
  3. **Quick-Add Currency Assumption:** Ambiguous currency text defaults to `activeBusiness.currency`. *Mitigation:* Display parsed currency explicitly in the preview chip before submission.
