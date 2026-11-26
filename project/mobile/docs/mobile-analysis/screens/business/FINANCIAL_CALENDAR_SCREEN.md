# FINANCIAL_CALENDAR_SCREEN (`BIZ-09`)

> **Domain:** Business Operations (`calendar`)
> **Task Reference:** `P4-01`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/calendar/page.tsx`, `Web/project/frontend/lib/api/transactions.ts`
> **Backend Source:** `TransactionController.java` (`GET /api/v1/transactions`), `InvoiceController.java` (optional overlay), `RecurringTransactionController.java` (optional overlay)

---

## 1. Screen Identity

- **Screen ID:** `BIZ-09`
- **Screen Name:** `FinancialCalendarScreen`
- **Flutter File Path:** `lib/features/calendar/presentation/financial_calendar_screen.dart`
- **Supporting Sheet:** `DayActivitySheet` (`lib/features/calendar/presentation/widgets/day_activity_sheet.dart`)
- **Route Path (`GoRouter`):** `/calendar`
- **Navigation Placement:**
  - **Phone (`< 600dp`):** Accessed from `MoreHubScreen` (Tab 4 → *Money & Operations* → *Financial Calendar*).
  - **Tablet (`>= 600dp`):** Direct Workspace section item in `NavigationRail` (*Calendar*); on `>= 840dp`, renders Two-Pane (`62%` Month Grid + KPIs / `38%` Selected Date Ledger Panel).

---

## 2. Purpose and Functional Scope

Provides a localized Gregorian monthly calendar visualizing daily cash inflows, outflows, pending obligations, and day-by-day recorded transactions, paired with 4 monthly KPI summary cards, a clickable day activity ledger sheet/panel, and an optional overlay toggle for upcoming invoice due dates and recurring rule schedules.

### Confirmed Web Bugs & Gaps Fixed on Mobile
1. **Per-Month Server-Side Date Range Query (`startDate` & `endDate`):** On Web (`calendar/page.tsx:49`), `TransactionService.getTransactions({ page: 0, size: 100 })` runs **once on mount without `startDate` or `endDate`**! Navigating to previous/next months shows empty days if transactions fall outside the newest 100 entries. Mobile queries `GET /api/v1/transactions?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&page=0&size=100` for the visible month (and automatically fetches subsequent pages if `totalPages > 1` so high-volume months are never truncated).
2. **Clickable Day Transaction Items:** On Web, transactions listed in *Selected Date Activity* are non-clickable `div`s. Mobile makes every transaction row tappable → pushes `TransactionDetailsScreen` (`/transactions/:txId`).
3. **Zero Hardcoded Strings:** Web's `calendar/page.tsx` uses inline `isAr ? ... : ...` ternaries (zero keys in `messages/`). Mobile extracts all strings into `app_en.arb` / `app_ar.arb`.
4. **Prefilled Quick-Add Transaction:** Tapping `+ Add Transaction` passes `initialDate: selectedDate` into `AddEditTransactionScreen` instead of discarding the user's selected calendar day.
5. **Optional Overlay Notice:** Explicitly informs users when toggling **Invoices Due** / **Recurring Scheduled Runs** overlays that AFAB has no dedicated backend calendar API and overlays are client-composed from `/transactions`, `/invoices`, and `/recurring-transactions`.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - `MoreHubScreen` → *Money & Operations* → *Financial Calendar*
  - Tablet `NavigationRail` → *Calendar*
- **Exit / Forward Flows:**
  - Tap a transaction row in `DayActivitySheet` / side panel → pushes `TransactionDetailsScreen` (`/transactions/:txId`).
  - Tap an overlaid Invoice Due item (when overlay enabled) → pushes `InvoiceDetailsScreen` (`/invoices/:invoiceId`, `BIZ-04`).
  - Tap `+ Add Transaction` → pushes `AddEditTransactionScreen` prefilled with `transactionDate = selectedDate`.
  - Tap *Ask Copilot* (`Sparkles` in AppBar) → opens `GlobalCopilotSheet` with `screenContext: { page: "calendar", month: "YYYY-MM", selectedDate }`.

---

## 4. Layout and Responsive Behavior

| Breakpoint | Layout Structure | Calendar Cell Density | Day Activity Display |
|---|---|---|---|
| `compactSmall` (`< 360dp`) | Compact 2x2 KPI grid + 7-col Month Grid (`aspectRatio: 0.85`) | Day number + count badge + colored dot indicators (`+` green / `-` red) to prevent text truncation | Opens `DayActivitySheet` (`AfabBottomSheet`) on day tap + inline summary strip |
| `compact` (`360–599dp`) | 2x2 KPI grid + 7-col Month Grid | Day number + count pill + compact `+$X` / `-$Y` or indicator dots | Inline compact preview below grid OR `DayActivitySheet` (`AfabBottomSheet`) on day tap |
| `medium` (`600–839dp`) | `NavigationRail` (`72dp`) + 4-col KPI row + Month Grid | Day number + count badge + compact inflow/outflow amounts | Inline panel below grid or bottom sheet |
| `expanded` (`>= 840dp`) | `NavigationRail` (`248dp` at `>= 1024dp`) + 4-col KPI row + Two-Pane (`62%` Grid / `38%` Selected Date Panel) | Full cell with day number, count badge, `+inflow`, `-outflow`, and overlay markers | Persistent right-hand `Selected Date Activity` panel |

---

## 5. UI Components and Visual Hierarchy

1. **Month Navigator Header & Quick Actions:**
   - Month stepper pill: `<` (`Previous Month`), localized Gregorian month & year (`intl` `DateFormat.yMMMM(locale)` with Western digits), `>` (`Next Month`), plus `"Today"` quick-jump chip when viewing another month.
   - Primary CTA: `+ Add Transaction` (prefills `selectedDate`).
   - **Optional Overlay Toggle Chips + Info Pill:**
     - Filter chips: `Transactions` (always on), `Invoices Due` (optional toggle), `Recurring Runs` (optional toggle).
     - When either optional overlay is active, show a compact info banner: *"Calendar overlays combine settled ledger entries with open invoice due dates and scheduled recurring rules."*
2. **4 Monthly KPI Cards (`AfabStatCard`):**
   - **Monthly Inflow:** Sum of `INCOME` transactions with `status == "COMPLETED"` in visible month (`MoneyText`, Emerald).
   - **Monthly Outflow:** Sum of `EXPENSE` transactions with `status == "COMPLETED"` in visible month (`MoneyText`, Danger).
   - **Pending Items:** Count of `status == "PENDING"` transactions in visible month (Amber, `"Awaiting settlement"`).
   - **Recorded Entries:** Total count of transactions in visible month (`monthTransactions.length`, Primary Violet).
3. **Localized 7-Column Gregorian Month Grid (`AfabCard`):**
   - Weekday header row (`Sun`..`Sat` localized in EN/AR via `DateFormat.E(locale)`).
   - Day cells (`48dp+` height):
     - Empty leading padding cells for `firstDayWeekday`.
     - Active day cells:
       - Day number (Western digits `1..31`); highlighted ring/text if `isToday`; `primary` border + `primary` `10%` tint if `isSelected`.
       - Top-end badge: entry count when `dayTxs.isNotEmpty`.
       - Bottom indicators:
         - On `>= 600dp` (or `>= 400dp` when compact): `+$in` (Emerald) / `-$out` (Red) in `MoneyText`.
         - On `< 400dp` narrow phones: crisp Emerald/Red dot indicators + count badge so numbers never clip or wrap awkwardly, while full amounts appear immediately in `DayActivitySheet`!
       - Optional Amber/Violet dot if overlaid Invoice Due or Recurring Run falls on that day.
4. **Day Activity Sheet / Side Panel (`DayActivitySheet`):**
   - Header: `"Selected Date Activity"` + localized `selectedDate` + `"${entries.length} entries"` badge + `+ Add on this date` icon button.
   - Empty state: `AfabEmptyState` (`Receipt` icon, `"No transactions on this date"`).
   - Settled/Pending Transaction rows (`AfabInsetPanel`, clickable → `TransactionDetailsScreen`):
     - `ArrowUpRight` (Emerald) for `INCOME` / `ArrowDownLeft` (Primary) for `EXPENSE`.
     - `tx.description`, `${tx.categoryName ?? "Uncategorized"} • ${tx.status}`.
     - `MoneyText` with `+`/`-` prefix in `tx.currency ?? businessCurrency` (LTR).
   - Optional Overlaid Sections (only when overlay toggles enabled and items exist for `selectedDate`):
     - *Invoices Due (`dueDate == selectedDate`)* → clickable to `InvoiceDetailsScreen` (`BIZ-04`).
     - *Scheduled Recurring Runs (`nextExecutionDate == selectedDate`)* → clickable to `RecurringTransactionsScreen` (`BIZ-08`).

---

## 6. Interactive States and User Flows

- **Month Navigation Flow:**
  1. User taps `<` or `>` (or swipes horizontally on the calendar grid) → updates `visibleMonth` (`YearMonth`).
  2. Computes `startDate = visibleMonth.firstDay` (`YYYY-MM-DD`) and `endDate = visibleMonth.lastDay` (`YYYY-MM-DD`).
  3. Fetches `GET /api/v1/transactions?startDate=...&endDate=...&page=0&size=100` (if `totalPages > 1`, loops remaining pages in parallel up to a safe cap or shows pagination warning).
  4. Defaults `selectedDate` to today (if visible month is current month) or 1st of the visible month.
- **Loading:** Shows `AfabLoader` inside calendar card while fetching the month window; keeps header & month stepper responsive so rapid month stepping cancels stale in-flight requests (`CancelToken`).
- **Error:** Retryable error banner (`Retry` button) if `/transactions` fails.
- **Overlay Toggle Flow:** Enabling `Invoices Due` lazily fetches `GET /api/v1/invoices?size=100` (filtering non-`PAID`, non-`CANCELLED`, non-`DRAFT` where `dueDate` falls in `visibleMonth`); enabling `Recurring Runs` lazily fetches `GET /api/v1/recurring-transactions` (filtering `active == true` where `nextExecutionDate` falls in `visibleMonth`).

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Query Params | Response DTO | Notes |
|---|---|---|---|---|
| Month Transactions | `GET /api/v1/transactions` | `startDate=YYYY-MM-DD`, `endDate=YYYY-MM-DD`, `page=0..N`, `size=100` | `200 TransactionResponseDTO` | Backend caps `size` at `100` (`TransactionController`); loops pages if `totalPages > 1`. |
| Optional Invoice Overlay | `GET /api/v1/invoices` | `page=0`, `size=100` | `200 InvoicePageDTO` | Client filters `dueDate` within visible month & unpaid statuses. |
| Optional Recurring Overlay | `GET /api/v1/recurring-transactions` | — | `200 List<RecurringTransactionDTO>` | Client filters `active == true` and `nextExecutionDate` within visible month. |

---

## 8. State Management and Caching

- **`visibleMonthProvider` (`StateProvider<DateTime>`):** Normalized to first day of month.
- **`selectedCalendarDateProvider` (`StateProvider<String>`):** `YYYY-MM-DD`.
- **`calendarOverlaysProvider` (`StateProvider<CalendarOverlaySettings>`):** `{ showInvoicesDue: false, showRecurringRuns: false }`.
- **`calendarMonthTransactionsProvider(YearMonth month)` (`FutureProvider.autoDispose.family`):** Watches `activeBusinessIdProvider`, cancels via `ref.onDispose` (`CancelToken`) on rapid month changes, and groups results by `transactionDate`.
- **Invalidation:** Transaction, Invoice payment, or Recurring `run-due` mutations invalidate `calendarMonthTransactionsProvider`.

---

## 9. Validation, Error Handling, and Edge Cases

- **Month Boundary & Leap Year Handling:** Always calculate `daysInMonth` via `DateUtils.getDaysInMonth(year, month)` (`28/29/30/31` days).
- **Large Transaction Volume (> 100 in 1 Month):** If `response.totalPages > 1`, fetch pages `1..min(totalPages - 1, 9)` (up to 1,000 entries/month) and show a subtle banner if `totalElements > 1000`.
- **Foreign Currency Transactions:** Note `TransactionDTO.amount` vs `convertedAmount` (base currency): when computing monthly KPI totals (`monthIncome`, `monthExpense`), sum `tx.convertedAmount ?? tx.amount` in `business.currency` (or document exact parity with backend `totalInflow`/`totalOutflow` returned on `TransactionResponseDTO`!). Specifically, `TransactionResponseDTO` returns filtered `totalInflow` & `totalOutflow`, or client computes over `COMPLETED` items using `convertedAmount` in `business.currency` while showing each row's `tx.currency` inside `DayActivitySheet`.
- **Gregorian Only:** Never auto-switch to Hijri (`um_al_qura`) even when OS device calendar is Arabic (`08_LOCALIZATION_AND_RTL.md` §3.4).

---

## 10. Localization and RTL Support

- Extract all Web-hardcoded EN/AR strings (`Financial Calendar`, subtitle, `Monthly Inflow`, `Monthly Outflow`, `Pending Items`, `Recorded Entries`, `Awaiting settlement`, `Selected Date Activity`, `No transactions on this date`, `entries`, plus new overlay toggle strings) into `app_en.arb` and `app_ar.arb`.
- Gregorian weekday headers (`Sun`..`Sat` / `الأحد`..`السبت`) and month names (`January`..`December` / `يناير`..`ديسمبر`) formatted via `intl` with **Western digits (`0–9`)**.
- Month stepper chevrons mirror cleanly in RTL (`matchTextDirection: true`), and `GridView` flows right-to-left naturally in Arabic (`Directionality` inherited from `MaterialApp`).

---

## 11. Accessibility and Touch Ergonomics

- Each calendar day cell has minimum `48dp` height and full `Semantics` label (e.g., `"November 15, 2026: 3 transactions, inflow 500 USD, outflow 120 USD"`).
- Day tap on phones opens `DayActivitySheet` with smooth drag handle and `SafeArea` padding.
- High-contrast selected-day ring and today badge pass WCAG AA (`>= 4.5:1`) in Light and Dark (`midnight`/`oled`) modes.

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- All queries attach `Authorization` + `X-Business-Id`; switching businesses immediately invalidates `calendarMonthTransactionsProvider` and overlay caches.
- `READ_ONLY` workspaces disable `+ Add Transaction` CTA while preserving full calendar browsing.
- No plan gating on calendar browsing.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:**
   - Verify `startDate` and `endDate` bounds for 28-, 29- (leap Feb 2024/2028), 30-, and 31-day months.
   - Verify multi-page aggregation when `totalPages > 1`.
   - Verify KPI calculations (`COMPLETED` `INCOME`, `COMPLETED` `EXPENSE`, `PENDING` count).
2. **Widget Tests:**
   - Verify stepping to Previous Month fires `GET /transactions?startDate=...&endDate=...` with the exact prior month's date range.
   - Verify tapping a day opens `DayActivitySheet` on phone (`< 600dp`) and updates right pane on tablet (`>= 840dp`).
   - Verify tapping a transaction item navigates to `TransactionDetailsScreen`.
   - Verify Light/Dark and EN/AR (`320dp` & `1024dp`) zero overflow and Western digits `0–9`.
3. **Integration Test:** Open Calendar → step back 1 month → tap day with entries → tap transaction → inspect `TransactionDetailsScreen` → toggle `Invoices Due` overlay → verify notice and due markers render.

---

## 14. Dependencies and Risks

- **Dependencies:** `intl`, `flutter_riverpod`, `go_router`, `TransactionDetailsScreen`, `AddEditTransactionScreen`, `InvoiceDetailsScreen` (`BIZ-04`), `RecurringTransactionsScreen` (`BIZ-08`).
- **Risks:**
  - **No Dedicated Backend Calendar Endpoint:** Composing overlays from 3 endpoints (`transactions`, `invoices`, `recurring-transactions`) adds extra requests when overlays are toggled on. Mitigated by keeping overlays off by default, lazy-loading only when enabled, and caching per visible business.
  - **Cell Overflow on `320dp` Phones:** Fitting currency amounts inside `7` columns at `320dp` (`~40dp` per column) causes clipping; mitigated by rendering semantic dot indicators + count badges on `< 400dp` phones and showing full `MoneyText` breakdown inside `DayActivitySheet`.
