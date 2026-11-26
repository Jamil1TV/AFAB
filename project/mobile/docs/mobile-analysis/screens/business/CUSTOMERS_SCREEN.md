# CUSTOMERS_SCREEN (`BIZ-01`)

> **Domain:** Business Operations (`customers`)
> **Task Reference:** `P3-05`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/customers/page.tsx`, `Web/project/frontend/lib/api/customers.ts`
> **Backend Source:** `CustomerController.java`, `CustomerService.java`, `CustomerSummaryDTO.java`, `CustomerDTO.java`, `CustomerPageDTO.java`

---

## 1. Screen Identity

- **Screen ID:** `BIZ-01`
- **Screen Name:** `CustomersScreen`
- **Flutter File Path:** `lib/features/customers/presentation/customers_screen.dart`
- **Supporting Sheets / Modals:** `AddEditCustomerSheet` (`lib/features/customers/presentation/widgets/add_edit_customer_sheet.dart`)
- **Route Path (`GoRouter`):** `/customers`
- **Navigation Placement:**
  - **Phone (`< 600dp`):** Accessed from `MoreHubScreen` (Tab 4 → *Money & Operations* → *Customers*) or via quick-link from `InvoicesScreen` (Tab 3). Pushes onto the active shell branch stack.
  - **Tablet (`>= 600dp`):** Direct primary destination in `NavigationRail` (*Customers*). On `>= 840dp`, renders a Two-Pane Master-Detail layout (`55%` directory + analytics / `45%` inline `CustomerDetailsPane`).

---

## 2. Purpose and Functional Scope

Provides the business's customer directory, real-time customer financial KPIs, status distribution analytics, top-revenue customer rankings, recent customer activity feed, CSV export, and full Customer CRUD (create, edit, soft-archive).

### Mobile Adaptations & Confirmed Web Fixes
1. **Omit Dead Bulk Selection Checkboxes:** Web renders row checkboxes (`selectedIds`, `toggleSelectAll`, `toggleSelectOne`) and a `"X selected"` banner with zero bulk actions (no bulk delete, export, or group change). Mobile omits checkboxes completely to reclaim horizontal space and touch clarity.
2. **Expose `companyName` in Add/Edit Form:** `CreateCustomerRequest`, `UpdateCustomerRequest`, and `CustomerDTO` all support `companyName` (`<= 255` chars), which Web's modal omitted. Mobile includes `companyName` in `AddEditCustomerSheet` and displays it beneath the customer name when present.
3. **Top Customers Navigation Fix:** On Web, tapping a Top Customer in the widget only opens the drawer if that customer happens to exist in the current paginated `customers` array (`customers.find(...)`). Mobile navigates directly to `CustomerDetailsScreen` (`BIZ-02`) by `top.id`, which always fetches `GET /api/v1/customers/{id}`.
4. **Honest KPI Delta Badges:** Backend `CustomerService.getSummary()` returns `0.0` hardcoded for `totalRevenueChangePct`, `avgRevenueChangePct`, and `repeatCustomersChangePct`, and reuses `newDelta` for both `totalCustomersChangePct` and `newCustomersChangePct`. Mobile displays explicit period context (e.g., `"This Week"` / `"This Month"`) and renders neutral badges rather than misleading `"vs last month"` copy on `0.0%` metrics.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - `MoreHubScreen` → *Money & Operations* → *Customers*
  - Tablet `NavigationRail` → *Customers*
  - `DashboardScreen` → *Top Customers* card → `"View All"`
- **Exit / Forward Flows:**
  - Tap customer card/row, Top Customer row, or Activity item → pushes `CustomerDetailsScreen` (`/customers/:id`, `BIZ-02`) on phone/tablet portrait, or updates right-hand detail pane on `>= 840dp` tablet landscape.
  - Tap `+ Add Customer` (FAB / header button) → opens `AddEditCustomerSheet` (Create mode).
  - Row/card overflow menu → *View Details* (`BIZ-02`), *Add Order* (`AddOrderSheet` from `BIZ-02`), *Edit* (`AddEditCustomerSheet` prefilled), *Archive* (confirmation dialog → `DELETE /customers/{id}`).
  - Tap *Ask Copilot* (`Sparkles` in AppBar) → opens `GlobalCopilotSheet` with `screenContext: { page: "customers", period }`.
- **Business Switch Behavior:** Changing active workspace invalidates `customerSummaryProvider` and `customerListProvider`, closes any open detail pane/sheet, resets page to `0`, and reloads for the new `X-Business-Id`.

---

## 4. Layout and Responsive Behavior

| Breakpoint | Layout Structure | Directory Presentation | Analytics Widgets |
|---|---|---|---|
| `compactSmall` (`< 360dp`) | Single-column `CustomScrollView` + sticky search/filter bar + FAB | Vertical `AfabCard` customer cards (1 col) | Stacked below directory: Overview Donut → Top Customers → Recent Activity |
| `compact` (`360–599dp`) | `CustomScrollView`, 2-col horizontal-scroll or 2x3 KPI grid + FAB | Vertical `AfabCard` customer cards (1 col) | Stacked below directory |
| `medium` (`600–839dp`) | `NavigationRail` (`72dp`) + 3-col KPI grid | Structured card list or compact 6-col table | 3-column grid below directory |
| `expanded` (`>= 840dp`) | `NavigationRail` (`248dp` at `>= 1024dp`) + Two-Pane (`55%` left / `45%` right `CustomerDetailsPane`) | Full 8-col `DataTable` (no checkbox col) + pagination footer | Stacked in left column below table (or collapsible analytics header) |

---

## 5. UI Components and Visual Hierarchy

1. **Top Action Strip:**
   - **Period Selector (`AfabSegmentedBar`):** `week` (*This Week*), `month` (*This Month*), `quarter` (*This Quarter*), `year` (*This Year*). Note: Web initializes to `"week"` while backend defaults to `"month"` — mobile defaults to `"week"` for parity and passes `?period=` explicitly.
   - **Primary CTA:** `+ Add Customer` button (Header CTA on tablet; floating `FloatingActionButton.extended` or top button on phone).
   - **Secondary CTA:** `Export CSV` icon/button in filter toolbar.
2. **5 KPI Cards (`AfabKpiCard`):**
   - **Total Customers:** integer count (`summary.totalCustomers`) + `newDelta` badge + sparkline.
   - **New Customers:** integer count (`summary.newCustomers`) + `newDelta` badge + period label.
   - **Total Revenue:** `MoneyText(summary.totalRevenue, currency)` + neutral period label.
   - **Avg. Revenue / Customer:** `MoneyText(summary.avgRevenuePerCustomer, currency)` + neutral period label.
   - **Repeat Customers:** `${summary.repeatCustomersPct}%` + neutral period label.
3. **Search & Filter Toolbar:**
   - Debounced (`350ms`) search input (`searchPlaceholder`: code, name, email, phone).
   - Group filter chips / dropdown (`ALL`, `Standard`, `Business`, `Premium`, `Enterprise`).
   - Status filter chips / dropdown (`ALL`, `Active`, `Inactive`, `New`, `Lead`).
4. **Customer Directory (Cards on Phone / Table on Tablet):**
   - **Phone Card (`AfabCard`):**
     - Header: Initial avatar (`40x40dp` tinted container), Customer Name (`titleSmall` bold), optional `companyName` subtitle, clickable `customerCode` pill (`CST-1001` with `Copy` icon), Status badge (`Active` success, `Inactive` neutral, `New` primary, `Lead` warning), Group badge (`Standard` neutral, `Business` info, `Premium` primary, `Enterprise` success), and 3-dot overflow button (`48x48dp`).
     - Metrics inset (`AfabInsetPanel`, 2 cols): *Total Revenue* (`MoneyText`) and *Orders* (`ordersCount`).
     - Footer strip: Quick-tap `phone` (`tel:`), `email` (`mailto:`), and `+ Add Order` soft pill button.
   - **Pagination Controls:** `Showing X to Y of Z`, page size selector (`10`, `25`, `50`), Previous / Next buttons (`rtl`-mirrored chevrons).
5. **3 Analytics & Insight Cards:**
   - **Customer Overview Donut (`fl_chart` `PieChart`):** Center overlay showing *Total* + `summary.totalCustomers`. Segments: Active (`#10B981`), Inactive (`primary`), New (`#0EA5E9`), with percentage legend.
   - **Top Customers:** Up to 5 items (`topCustomers[]`) with avatar, name, `customerCode`, `ordersCount`, and `MoneyText(revenue)`. Includes `"View All"` button filtering `group = Premium` (or clearing filters).
   - **Recent Customer Activity:** Up to 6 items (`recentActivity[]`) mapping `NEW_CUSTOMER`, `INVOICE_PAID`, `PAYMENT_RECEIVED`, `NEW_ORDER` to semantic icon tiles, customer name, optional `MoneyText(amount)`, and localized short date.

---

## 6. Interactive States and User Flows

- **Loading:** Initial load shows `AfabLoader` / shimmer KPI + card skeletons; pull-to-refresh (`RefreshIndicator`) triggers parallel refetch of summary + list.
- **Empty:**
  - Zero customers overall → `AfabEmptyState` with `Users` icon + `"Add Customer"` CTA.
  - Filtered search/group/status empty → `"No customers found matching your criteria"` + `"Clear Filters"` CTA.
- **Error:** Inline `AfabCard` danger banner with backend message + `Retry` button.
- **Create / Edit Flow (`AddEditCustomerSheet`):**
  1. Fields: `customerCode` (optional; prefilled suggestion `CST-XXXX` or left blank for backend auto-generation `CST-1001`+), `name` (required), `companyName` (optional), `email` (optional on backend DTO, validated email format if provided; Web marks required — mobile validates format when non-empty and matches Web prompt or allows optional per backend `@Email`? Wait: Web `handleSaveCustomer` enforces `email` required with `@`, while `CreateCustomerRequest.java` has `@Email` without `@NotBlank`. Mobile enforces valid email required on create/edit for parity with Web, or displays clear inline message), `phone`, `group` (`Standard`/`Business`/`Premium`/`Enterprise`), `status` (`Active`/`Inactive`/`New`/`Lead`), `address` (`<= 1000`), `notes` (`<= 2000`).
  2. Submit → `POST /api/v1/customers` or `PUT /api/v1/customers/{id}` → close sheet, show `AfabToast.success`, invalidate `customerSummaryProvider`, `customerListProvider`, and `customerDetailProvider(id)`.
- **Archive Flow:** Overflow menu → *Archive Customer* → `AlertDialog` explaining historical invoices/payments remain intact → `DELETE /api/v1/customers/{id}` → `204` → toast + refresh.
- **CSV Export Flow:** Generates UTF-8 BOM CSV of currently loaded customers (plus an optional `"Export All"` fetch loop if `totalElements > customers.length`) and opens native OS share sheet via `share_plus`.

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Query / Body | Response DTO | Notes |
|---|---|---|---|---|
| List Customers | `GET /api/v1/customers` | `search`, `status`, `group`, `page=0`, `size=10 (1..100)`, `sortBy=createdAt`, `sortOrder=desc` | `200 CustomerPageDTO` (`content[]`, `totalElements`, `totalPages`, `pageNumber`, `pageSize`) | `orders` is always `[]` in list items. |
| Summary & Widgets | `GET /api/v1/customers/summary` | `period=week\|month\|quarter\|year` | `200 CustomerSummaryDTO` | Returns 5 KPIs, `currency`, `overviewDonut`, `topCustomers[<=5]`, `recentActivity[<=6]`. |
| Create Customer | `POST /api/v1/customers` | `CreateCustomerRequest` (`name*`, `companyName?`, `email?`, `customerCode?`, `phone?`, `group`, `status`, `address?`, `notes?`) | `201 CustomerDTO` | `409 ConflictException` on duplicate email or code within business. |
| Update Customer | `PUT /api/v1/customers/{id}` | `UpdateCustomerRequest` | `200 CustomerDTO` | `409` on email/code collision; `404` if archived/missing. |
| Archive Customer | `DELETE /api/v1/customers/{id}` | — | `204 No Content` | Soft-archives (`archivedAt = now`, `status = "Archived"`). |

---

## 8. State Management and Caching

- **`customerFilterProvider` (`NotifierProvider`):** Holds `{ period, search, statusFilter, groupFilter, page, pageSize, sortBy, sortOrder }`.
- **`customerSummaryProvider` (`FutureProvider.autoDispose`):** Watches `activeBusinessIdProvider` + `period`; fetches `GET /customers/summary`.
- **`customerListProvider` (`FutureProvider.autoDispose`):** Watches `activeBusinessIdProvider` + `customerFilterProvider`; fetches `GET /customers`.
- **Cache Invalidation:** Mutating a customer, adding an order, recording an invoice payment, or switching business invalidates `customerSummaryProvider`, `customerListProvider`, and `dashboardSummaryProvider`.

---

## 9. Validation, Error Handling, and Edge Cases

- **Client Validation (Matching `CreateCustomerRequest.java` & `UpdateCustomerRequest.java`):**
  - `name`: required (`@NotBlank`), max `255` chars.
  - `companyName`: max `255` chars.
  - `email`: valid email syntax (`@Email`), max `255` chars.
  - `customerCode`: max `40` chars; trimmed & uppercased server-side.
  - `phone`: max `50` chars.
  - `address`: max `1000` chars; `notes`: max `2000` chars.
- **Backend Error Handling:**
  - `409 Conflict`: Highlight `email` or `customerCode` field inline with server message (`"A customer with email '...' already exists"` / `"Customer code '...' is already in use"`).
  - `400 Bad Request`: Bind `ApiError.fieldErrors` directly to `AfabTextField.errorText`.
  - `403 BUSINESS_READ_ONLY`: Disable `+ Add Customer`, Edit, Add Order, and Archive CTAs in `READ_ONLY` mode and show global `BusinessReadOnlySheet` if attempted.
- **Edge Case — Multi-Currency Invoices:** Backend `CustomerFinancialMetricsProviderImpl` sums `totalPaidRevenue` across all non-cancelled customer invoices in their raw amounts without FX conversion. Mobile documents/displays the business base currency from `summary.currency` and notes mixed-currency caveat if customer holds foreign-currency invoices.

---

## 10. Localization and RTL Support

- **ARB Namespace:** Migrate all `153` keys from `Web/project/frontend/messages/{en,ar}/customers.json` into `app_en.arb` / `app_ar.arb`, plus add missing keys (`companyName`, `companyNamePlaceholder`, `clearFilters`, `exportAll`).
- **RTL Rules:**
  - `customerCode` (`CST-1001`), email addresses, phone numbers (`+1 555...`), and `MoneyText` amounts are wrapped in `Directionality(textDirection: TextDirection.ltr)`.
  - Pagination chevrons (`ChevronLeft` / `ChevronRight`) use `matchTextDirection: true`.
  - Western digits (`0–9`) enforced for all counts, percentages, and currency figures in both EN and AR.

---

## 11. Accessibility and Touch Ergonomics

- Minimum `48x48dp` touch targets on customer card tap area, copy-code pill, phone/email chips, overflow menu button, and pagination buttons.
- `Semantics` labels on Donut chart segments (e.g., `"Active customers: 65%"`) and icon-only buttons (`"Copy customer code"`, `"Customer actions"`).
- `AddEditCustomerSheet` wraps form fields in `SafeArea` + `SingleChildScrollView` + `AnimatedPadding(viewInsets.bottom)` with `TextInputAction.next` chaining across fields.
- Zero `TextOverflow.ellipsis` on monetary totals (`MoneyText` uses `FittedBox.scaleDown`).

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- All requests pass `Authorization: Bearer <token>` and `X-Business-Id: <activeBusinessId>`.
- Backend enforces tenant ownership (`customer.business.id == currentBusiness.id`) and `BusinessAccessGuard.assertEditable(business)` on `POST`/`PUT`/`DELETE`.
- Customer CRUD has **no plan-quota limit** (`FREE`, `PLUS`, `PRO` all have unlimited customers), though `READ_ONLY` workspaces block all writes (`403 BUSINESS_READ_ONLY`).
- No PII (emails, phones, amounts) logged by `AppLogger`.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:** `CustomerDTO` & `CustomerSummaryDTO` deserialization (including nullable `companyName`, `invoicedAmount`, `outstandingBalance`, `Decimal` parsing), validator limits (`255`, `40`, `50`, `1000`, `2000`).
2. **Widget Tests:**
   - Loading, empty, filtered-empty, error-retry, and populated states in Light/Dark (`midnight`/`oled`) and EN/AR (`320dp` phone & `1024dp` tablet).
   - Verify bulk checkboxes are absent on both phone and tablet.
   - Verify `companyName` input appears in `AddEditCustomerSheet` and submits in `POST`/`PUT` payload.
   - Verify `409` duplicate email/code displays inline error without closing sheet.
3. **Integration Test:** Create customer → verify appears in directory & summary → tap Top Customer → opens `CustomerDetailsScreen` (`GET /customers/{id}`) → archive customer → removed from active directory.

---

## 14. Dependencies and Risks

- **Dependencies:** `flutter_riverpod`, `go_router`, `fl_chart`, `decimal`, `intl`, `share_plus`, `url_launcher` (`tel:`/`mailto:`), `lucide_icons_flutter`.
- **Risks:**
  - **CSV Export Scope:** Exporting only the current page (`size=10`) surprises users with `> 10` customers; mitigate by offering *"Current Page"* vs *"All Customers"* (paging `size=100`) when `totalElements > customers.length`.
  - **Zeroed KPI Deltas:** Backend returns `0.0` change pct for Revenue, Avg Revenue, and Repeat %; mitigate by not displaying fake `"vs last month"` trend arrows for `0.0` placeholder deltas.
