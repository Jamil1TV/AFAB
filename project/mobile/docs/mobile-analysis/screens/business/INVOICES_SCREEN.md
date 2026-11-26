# INVOICES_SCREEN (`BIZ-03`)

> **Domain:** Business Operations (`invoices`)
> **Task Reference:** `P3-06`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/invoices/page.tsx`, `Web/project/frontend/lib/api/invoices.ts`
> **Backend Source:** `InvoiceController.java`, `InvoiceService.java`, `InvoiceSummaryDTO.java`, `InvoicePageDTO.java`, `InvoiceDTO.java`

---

## 1. Screen Identity

- **Screen ID:** `BIZ-03`
- **Screen Name:** `InvoicesScreen`
- **Flutter File Path:** `lib/features/invoices/presentation/invoices_screen.dart`
- **Route Path (`GoRouter`):** `/invoices`
- **Navigation Placement:**
  - **Phone (`< 600dp`):** Dedicated **Tab 3 (*Invoices* / الفواتير)** in `StatefulShellRoute.indexedStack` bottom `NavigationBar`.
  - **Tablet (`>= 600dp`):** Primary item in `NavigationRail`; on `>= 840dp` landscape, renders Two-Pane Master-Detail (`58%` left list & widgets / `42%` right `InvoiceDetailsPane`).

---

## 2. Purpose and Functional Scope

Manages the business's customer invoicing and accounts receivable: 5 invoice KPIs, searchable and status-filtered invoice register, receivables breakdown donut chart, upcoming/overdue due reminders, AI payment reminder drafting via Copilot, CSV export, and navigation to invoice creation and detail workflows.

### Confirmed Web Bugs & Gaps Fixed on Mobile
1. **Include `SENT` in Status Filter Chips:** Web filters list `ALL, DRAFT, UNPAID, PARTIALLY_PAID, PAID, OVERDUE, CANCELLED`, completely omitting `SENT` even though `issueInvoice(id, true)` creates `SENT` invoices! Mobile includes **`SENT`** (`ALL`, `DRAFT`, `SENT`, `UNPAID`, `PARTIALLY_PAID`, `PAID`, `OVERDUE`, `CANCELLED`).
2. **AI Reminder Trigger Includes `SENT`:** Web only renders the `Sparkles` AI reminder button on `OVERDUE`, `UNPAID`, `PARTIALLY_PAID`. Mobile enables the AI Reminder trigger on **`OVERDUE`, `UNPAID`, `SENT`, and `PARTIALLY_PAID`**.
3. **Clickable Upcoming / Overdue Due Items:** On Web, `Upcoming / Overdue Due` cards are static non-clickable `div`s (and backend `UpcomingInvoiceItem.invoiceId` actually holds `invoiceNumber`!). On mobile, tapping an upcoming due card searches/resolves the invoice (`GET /invoices?search=<invoiceNumber>`) and opens `InvoiceDetailsScreen` (`BIZ-04`).
4. **Honest Period Selector Behavior:** Backend `InvoiceController.getSummary(@RequestParam period)` completely ignores `period` and aggregates all non-`CANCELLED` invoices (`InvoiceService.java:194`). Mobile omits the misleading `PeriodSelector` on Invoices (or labels summary cards explicitly as *"All Active Invoices"*) instead of pretending to filter KPIs by week/month/year.
5. **100% Localized Strings:** Extracts all hardcoded English strings in Web `invoices/page.tsx` (`"Receivables Breakdown"`, `"Upcoming / Overdue Due"`, `"Search invoice # or customer..."`, `"Due:"`, status pills) into `app_en.arb` / `app_ar.arb`.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - Phone Bottom Nav Tab 3 (*Invoices*)
  - Tablet `NavigationRail` → *Invoices*
  - `DashboardScreen` → `ReminderCard` invoice reminder or quick action
- **Exit / Forward Flows:**
  - Tap `+ Create Invoice` (FAB / header button) → pushes `CreateEditInvoiceScreen` (`BIZ-05`, Create mode).
  - Tap any invoice card/row or Upcoming Due item → pushes `InvoiceDetailsScreen` (`/invoices/:id`, `BIZ-04`) on `< 840dp` or opens right-hand detail pane on `>= 840dp`.
  - Tap `Sparkles` AI Reminder button on an unpaid/sent/partially-paid/overdue invoice → opens `GlobalCopilotSheet` pre-seeded with reminder prompt (`Draft an Email & WhatsApp payment reminder for invoice ...`) and `autoSend: true`.
  - Quick shortcut to `CustomersScreen` (`BIZ-01`) via header/overflow action for managing clients.

---

## 4. Layout and Responsive Behavior

| Breakpoint | Layout Structure | Invoice List Presentation | Side Widgets |
|---|---|---|---|
| `compactSmall` (`< 360dp`) | Single-column scroll, horizontal-scroll status filter chips, FAB | Vertical `AfabCard` invoice cards | Stacked below invoice list: Receivables Donut → Upcoming Due |
| `compact` (`360–599dp`) | 2-col KPI wrap + 5th full-width KPI card, horizontal-scroll chips, FAB | Vertical `AfabCard` invoice cards | Stacked below invoice list |
| `medium` (`600–839dp`) | `NavigationRail` (`72dp`), 3-col KPI wrap | Touch cards or compact table | 2-col grid below list |
| `expanded` (`>= 840dp`) | `NavigationRail` (`248dp` at `>= 1024dp`), Two-Pane (`58%` / `42%` `InvoiceDetailsPane`) | Full 7-col `DataTable` + pagination footer | Stacked below table in left pane |

---

## 5. UI Components and Visual Hierarchy

1. **Header & Toolbar Actions:**
   - Title & subtitle, `Export CSV` action, `+ Create Invoice` primary button (FAB on `< 600dp`).
2. **5 KPI Cards (`AfabKpiCard` / `AfabStatCard`):**
   - **Total Invoices:** `summary.totalInvoices` (`"${totalInvoices} active"`, excludes `CANCELLED`).
   - **Paid Invoices:** `summary.paidInvoices` + `MoneyText(summary.paidAmount, summary.currency)`.
   - **Pending Invoices:** `summary.pendingInvoices` + `MoneyText(summary.pendingAmount, summary.currency)` (positive tone when `0`).
   - **Overdue Invoices:** `summary.overdueInvoices` + `MoneyText(summary.overdueAmount, summary.currency)` (danger/warning tone when `> 0`).
   - **Total Invoiced Amount:** `MoneyText(summary.totalInvoiceAmount, summary.currency)` + sub-value `"Due: ${MoneyText(page.totalOutstanding, page.currency)}"`.
3. **Search & Status Filter Strip:**
   - Debounced (`350ms`) search input (`invoiceNumber` or `customerName`).
   - Horizontal scrollable `ChoiceChip` strip: **`ALL`**, **`DRAFT`**, **`SENT`**, **`UNPAID`**, **`PARTIALLY_PAID`**, **`PAID`**, **`OVERDUE`**, **`CANCELLED`**.
4. **Invoice List Cards (Phone) / Table (Tablet):**
   - Each card (`AfabCard`, tappable → `BIZ-04`) shows:
     - Top row: Monospace `invoiceNumber` (LTR) + `AfabStatusBadge` (`PAID` emerald, `PARTIALLY_PAID` sky, `OVERDUE` red, `UNPAID`/`SENT` amber, `DRAFT` primary violet, `CANCELLED` neutral grey).
     - Customer row: `customerName` (fallback `"Walk-in / General"`) + `customerEmail` (if present).
     - Amounts row (`AfabInsetPanel`, 2 cols):
       - *Total:* `MoneyText(inv.totalAmount, inv.currency)` (**strictly uses `inv.currency` per row!**)
       - *Balance Due:* `MoneyText(inv.outstandingBalance, inv.currency)` (**strictly uses `inv.currency` per row!**)
     - Footer row: `Due: <localized dueDate>` + **AI Reminder (`Sparkles`)** icon button (visible when `status` is `OVERDUE | UNPAID | SENT | PARTIALLY_PAID`) + inspect chevron.
   - **Pagination Footer:** `Page X of Y (Z total)` with Previous/Next buttons (`size=15`).
5. **Receivables Breakdown Donut (`AfabCard`):**
   - `fl_chart` `PieChart` donut (`Paid` `#4EDEA3`, `Pending` `#FFB95F`, `Overdue` `#FFB4AB` or semantic theme equivalents) with interactive touch tooltip + legend rows showing `MoneyText(amount, summary.currency)` and `(percentage%)`.
6. **Upcoming / Overdue Due Card (`AfabCard`):**
   - Up to 5 items (`summary.upcomingDueList[]`). Each item is a clickable `AfabInsetPanel` showing `invoiceId` (invoice number), `customerName`, amber `"Due <dueDate>"`, and `MoneyText(amount, summary.currency)`.

---

## 6. Interactive States and User Flows

- **Loading:** Initial load shows `AfabLoader` / skeleton KPIs + list cards; filter/page switches show inline linear progress indicator while keeping previous header visible.
- **Empty:**
  - No invoices → `AfabEmptyState` with `Receipt` icon + `"Create Invoice"` CTA.
  - Active search/status filter with 0 results → `"No invoices found"` + `"Clear Filters"`.
- **Error:** Retryable danger banner (`loadError` + `Retry` button).
- **AI Reminder Flow:** Tapping `Sparkles` on an eligible invoice opens `GlobalCopilotSheet` (`GLOBAL_COPILOT_SHEET.md`) with:
  - `prompt`: `"Draft an Email & WhatsApp payment reminder for invoice ${inv.invoiceNumber} (${inv.customerName ?? 'Client'}, balance ${inv.outstandingBalance} ${inv.currency}, due ${inv.dueDate})."`
  - `autoSend: true`
  - `screenContext`: `{ "page": "invoices", "invoiceId": inv.id, "invoiceNumber": inv.invoiceNumber }`
- **Upcoming Due Tap Flow:** Because `UpcomingInvoiceItem.invoiceId` contains `invoiceNumber` (e.g., `INV-2026-0001`), first check loaded `invoicesPage.content` for matching `invoiceNumber`; if not in current page, call `GET /api/v1/invoices?search=<invoiceNumber>&size=1` to resolve its UUID `id`, then open `InvoiceDetailsScreen` (`BIZ-04`).
- **CSV Export Flow:** Exports loaded invoices (or offers *"All Invoices"* paginated export) with UTF-8 BOM via `share_plus`.

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Query Params | Response DTO | Notes |
|---|---|---|---|---|
| Summary & Widgets | `GET /api/v1/invoices/summary` | `period=month` (optional, ignored by server) | `200 InvoiceSummaryDTO` | Excludes `CANCELLED`. `upcomingDueList` capped at 5, sorted by `dueDate`. |
| List Invoices | `GET /api/v1/invoices` | `customerId?`, `status?`, `search?`, `page=0`, `size=15 (1..100)` | `200 InvoicePageDTO` | `OVERDUE` is computed dynamically in Java (`InvoiceService.java:135-149`); `items`/`payments` omitted (`[]`). |

---

## 8. State Management and Caching

- **`invoiceFilterProvider` (`NotifierProvider`):** Holds `{ statusFilter, search, page, size: 15, customerId? }`.
- **`invoiceSummaryProvider` (`FutureProvider.autoDispose`):** Watches `activeBusinessIdProvider`.
- **`invoiceListProvider` (`FutureProvider.autoDispose`):** Watches `activeBusinessIdProvider` + `invoiceFilterProvider`.
- **Invalidation:** Creating/updating/issuing/cancelling an invoice, recording a payment, adding a customer order, or approving an AI `CREATE_INVOICE` draft invalidates `invoiceSummaryProvider`, `invoiceListProvider`, `dashboardSummaryProvider`, and `customerListProvider`/`customerSummaryProvider`.

---

## 9. Validation, Error Handling, and Edge Cases

- **Invalid Status Query:** Backend throws `400 IllegalArgumentException` if unknown status string sent; mobile uses typed enum `InvoiceStatusFilter`.
- **Multi-Currency Caveat:** Individual invoice rows render in `inv.currency` (including 3-decimal ISO precision for `TND`/`KWD`/`BHD`/`OMR`). Summary cards (`InvoiceSummaryDTO`) and `InvoicePageDTO` (`totalInvoiced`, `totalPaid`, `totalOutstanding`) sum raw invoice amounts without FX conversion on the backend — display a subtle info caption (`"Summary totals reflect raw invoice amounts"`) if mixed currencies are detected in the list.
- **`DRAFT` Inclusion in `totalInvoiceAmount` vs `totalInvoiced`:** Notice `InvoiceService.getSummary()` includes `DRAFT` amounts in `totalInvoiceAmount` & `pendingCount`, whereas `listInvoices()` excludes `DRAFT` from `totalInvoiced`/`totalOutstanding`. Mobile displays both accurately without conflating them.

---

## 10. Localization and RTL Support

- All 30 keys in `invoices.json` + all Web-hardcoded labels (`Receivables Breakdown`, `Upcoming / Overdue Due`, `Draft AI Reminder`, `SENT` and all 7 `InvoiceStatus` labels, `Total`, `Balance`, `Due`) localized in `app_en.arb` and `app_ar.arb`.
- `invoiceNumber` (`INV-2026-0001`) and `MoneyText` rendered with `Directionality(textDirection: TextDirection.ltr)` and Western digits (`0–9`).
- Pagination arrows mirror in RTL.

---

## 11. Accessibility and Touch Ergonomics

- Minimum `48x48dp` touch targets on status filter chips, AI Reminder `Sparkles` button, invoice cards, Upcoming Due cards, and pagination buttons.
- `Semantics` labels on `Sparkles` button (`"Draft AI payment reminder for INV-2026-0001"`) and Donut segments.
- Horizontal `ChoiceChip` strip uses clear padding and never clips text at `1.4x` font scale.

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- All requests carry `Authorization` + `X-Business-Id`.
- `READ_ONLY` workspaces allow viewing/exporting invoices but disable `+ Create Invoice` (`403 BUSINESS_READ_ONLY`).
- Note: Seeded entitlement `invoices.per_month` exists in DB schema/plans copy but is **not enforced** by backend `InvoiceService` (`02_FEATURE_PARITY_MATRIX.md` / `13_RISKS_AND_TECHNICAL_DECISIONS.md` #16); mobile handles `403 PLAN_LIMIT_REACHED` gracefully if ever enabled in future backend versions.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:** `InvoicePageDTO` & `InvoiceSummaryDTO` deserialization (`Decimal` precision for `TND` 3 decimals), `InvoiceStatus` filter enum mapping including `SENT`, Upcoming Due `invoiceNumber` resolution helper.
2. **Widget Tests:**
   - Verify all 8 status chips (`ALL` + 7 statuses including `SENT`) render and trigger `GET /invoices?status=SENT`.
   - Verify `Sparkles` AI Reminder button renders on `SENT`, `UNPAID`, `PARTIALLY_PAID`, `OVERDUE`, and is hidden on `DRAFT`, `PAID`, `CANCELLED`.
   - Verify per-row currency displays `inv.currency` (e.g., `EUR` row inside `USD` business).
   - Verify Light/Dark and EN/AR (`320dp` & `1024dp`) zero overflow.
3. **Integration Test:** Filter by `OVERDUE` → tap Upcoming Due item → resolves UUID and opens `InvoiceDetailsScreen` → trigger AI Reminder → opens `GlobalCopilotSheet` with invoice context.

---

## 14. Dependencies and Risks

- **Dependencies:** `GlobalCopilotSheet`, `InvoiceDetailsScreen` (`BIZ-04`), `CreateEditInvoiceScreen` (`BIZ-05`), `fl_chart`, `share_plus`, `decimal`.
- **Risks:**
  - **`UpcomingInvoiceItem.invoiceId` Naming Trap:** Backend stores `invoiceNumber` in the field named `invoiceId` (`InvoiceService.java:229,241`), NOT a UUID! Calling `GET /invoices/{invoiceNumber}` directly would fail UUID parsing (`400`). Mobile MUST look up UUID from loaded list or `GET /invoices?search=<invoiceNumber>` before navigating to `BIZ-04`.
  - **Raw Cross-Currency Summary Sums:** Mixed-currency businesses see un-converted sums in `InvoiceSummaryDTO`; mitigate with clear info tooltip.
