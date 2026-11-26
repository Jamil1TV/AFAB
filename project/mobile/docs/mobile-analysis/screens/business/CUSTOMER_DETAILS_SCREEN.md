# CUSTOMER_DETAILS_SCREEN (`BIZ-02`)

> **Domain:** Business Operations (`customers`)
> **Task Reference:** `P3-05`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/customers/page.tsx` (Detail Drawer & Add Order Modal), `Web/project/frontend/lib/api/customers.ts`
> **Backend Source:** `CustomerController.java`, `CustomerService.java`, `CustomerFinancialMetricsProviderImpl.java`, `CustomerDTO.java`, `InvoiceController.java`

---

## 1. Screen Identity

- **Screen ID:** `BIZ-02`
- **Screen Name:** `CustomerDetailsScreen`
- **Flutter File Path:** `lib/features/customers/presentation/customer_details_screen.dart`
- **Supporting Sheets:** `AddOrderSheet` (`lib/features/customers/presentation/widgets/add_order_sheet.dart`)
- **Route Path (`GoRouter`):** `/customers/:customerId` (pushed full screen on `< 840dp`; rendered as right-hand inline pane on `>= 840dp` tablet landscape)

---

## 2. Purpose and Functional Scope

Displays the complete customer profile, authoritative financial summary (paid revenue, total invoiced, outstanding balance, order count), contact details, linked invoice/order history, internal notes, and actions to add an order (real invoice + optional immediate payment), edit the customer, or soft-archive the customer.

### Critical Confirmed Web Bugs Fixed on Mobile
1. **Always Fetch `GET /api/v1/customers/{id}`:** On Web, clicking a customer row passes the list-page `Customer` object straight into the drawer without calling `GET /customers/{id}`. Because `CustomerService.listCustomers()` passes `includeOrders = false`, `orders` is always `[]` on Web (`No orders recorded yet`)! Mobile **always fetches `GET /api/v1/customers/{id}`** on open (passing list DTO only as initial header preview while loading full details).
2. **Bind Authoritative `outstandingBalance` from DTO:** Web computes `pendingBalance` client-side by filtering `orders` for `status === "PENDING" || "PROCESSING"` — which is always `$0.00` because backend `CustomerFinancialMetricsProviderImpl` populates real `InvoiceStatus` (`DRAFT`, `SENT`, `UNPAID`, `PARTIALLY_PAID`, `PAID`, `OVERDUE`). Mobile binds `customer.outstandingBalance`, `customer.invoicedAmount`, `customer.totalRevenue`, and `customer.ordersCount` directly from `CustomerDTO`.
3. **Complete `InvoiceStatus` Badges & Localization:** Web's drawer badge switch only styles `COMPLETED`, `PENDING`, `PROCESSING`, falling back to `danger` for `PAID`/`SENT`/`UNPAID`/`DRAFT`, and `customers.json` lacks keys for `draft`, `sent`, `unpaid`, `partially_paid`, `paid`, `overdue`. Mobile maps all 7 `InvoiceStatus` values with accurate semantic colors and complete EN/AR labels.
4. **Honest `paymentMethod` Rendering:** Backend `CustomerInvoiceLinkDTO` sets `paymentMethod` to `null` (`CustomerFinancialMetricsProviderImpl.java:82`). Web falls back to displaying `"Bank Transfer"` for every row. Mobile hides the payment method chip when `paymentMethod == null`.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - `CustomersScreen` (`BIZ-01`): tap customer card/row, Top Customer item, Activity item, or *View Details* menu action.
  - `InvoiceDetailsScreen` (`BIZ-04`): optional tap on linked customer name (if `customerId != null`).
- **Exit / Forward Flows:**
  - Tap `+ Add Order` → opens `AddOrderSheet` (`BIZ-02` sub-sheet).
  - Tap an Order / Invoice card → pushes `InvoiceDetailsScreen` (`/invoices/:invoiceId`, `BIZ-04`) so the user can inspect line items, generate PDF, issue, or record payment.
  - Tap `Edit` → opens `AddEditCustomerSheet` (`BIZ-01` shared sheet) prefilled with full `CustomerDTO` (including `companyName`).
  - Tap `Archive` (Delete) → confirmation dialog → `DELETE /api/v1/customers/{id}` → pops back to `CustomersScreen` (or clears tablet detail pane).
  - Tap phone/email → launches OS dialer (`tel:`) or email client (`mailto:`) via `url_launcher`.

---

## 4. Layout and Responsive Behavior

- **Phone (`< 600dp`):** Full-screen `Scaffold` with back button, customer name + `customerCode` header, scrollable body (`SafeArea`), and sticky bottom action bar (`Archive`, `+ Add Order`, `Edit`).
- **Tablet Portrait (`600–839dp`):** Full-screen or `maxWidth: 680dp` centered scrollable layout with 2x2 or 4-col financial metrics strip.
- **Tablet Landscape (`>= 840dp`):** Embedded `45%` right-hand pane inside `CustomersScreen` Master-Detail split (`BorderDirectional.start` divider), with an optional expand-to-full button.

---

## 5. UI Components and Visual Hierarchy

1. **Profile Header Card:**
   - Initial avatar (`48x48dp`), Customer Name (`titleMedium` bold), `companyName` (if non-null), Status badge (`Active`/`Inactive`/`New`/`Lead`), Group badge (`Standard`/`Business`/`Premium`/`Enterprise`).
   - **Copyable `customerCode` Pill:** Displays `CST-1001` in monospace LTR with `Copy` icon (`Semantics`: *"Copy customer code"*). Tapping copies to clipboard and triggers `AfabToast.success(l10n.customersDrawerIdCopied(code))`.
2. **Financial Summary Strip (`AfabInsetPanel` cards):**
   - **Total Paid Revenue:** `MoneyText(customer.totalRevenue, currency)` (Emerald).
   - **Total Invoiced:** `MoneyText(customer.invoicedAmount ?? 0, currency)`.
   - **Outstanding Balance:** `MoneyText(customer.outstandingBalance ?? 0, currency)` (Amber when `> 0`, neutral when `0`).
   - **Invoices / Orders Count:** `customer.ordersCount`.
3. **Contact Information Section (`AfabCard`):**
   - Email (`Mail` icon, tappable `mailto:`)
   - Phone (`Phone` icon, tappable `tel:`, or `"No phone provided"`)
   - Address (`MapPin` icon, or `"No address on file"`)
   - Registered Date (`Calendar` icon, localized date from `customer.createdAt`)
4. **Order & Invoice History List (`customer.orders`):**
   - Section header: `"Order History & Invoices"` + count badge + `+ Add Order` soft button.
   - Each card (`AfabInsetPanel`, tappable → `InvoiceDetailsScreen`):
     - Top row: `orderNumber` / `invoiceNumber` monospace badge + `InvoiceStatus` semantic pill:
       - `PAID` / `COMPLETED` → Emerald (`success`)
       - `PARTIALLY_PAID` → Sky (`info`)
       - `SENT` / `UNPAID` / `PENDING` → Amber (`warning`)
       - `OVERDUE` → Red (`danger`)
       - `DRAFT` / `PROCESSING` → Primary Violet
       - `CANCELLED` → Neutral Grey
     - Middle row: `description` + `MoneyText(amount, businessCurrency)`.
     - Bottom row: `orderDate` (localized) + optional `paymentMethod` (only rendered when non-null).
5. **Internal Notes Card:** Rendered when `customer.notes` is non-blank.
6. **Sticky Bottom Action Bar:**
   - `Archive` (danger text/outlined button)
   - `+ Add Order` (soft secondary button)
   - `Edit` (primary button)

---

## 6. Interactive States and User Flows

- **Initial Load:** Immediately renders cached summary header if navigated from list while showing `AfabLoader` / skeleton for financial stats and `orders[]` until `GET /api/v1/customers/{id}` resolves.
- **Empty Orders State:** Dashed `AfabInsetPanel` with `Receipt` icon, `"No orders recorded yet"`, and `+ Add Order` CTA.
- **Error State:** Retry card if `GET /customers/{id}` fails (or `404` if customer was archived on another device → pops back with toast).
- **Add Order Flow (`AddOrderSheet`):**
  - Mimics and improves `CustomerService.addOrder` (`customers.ts:228-279`) backed by real Invoice endpoints:
    1. Fields: `amount` (`Decimal > 0`), `orderDate` (defaults to today), `status` (`COMPLETED` / `PAID` vs `DRAFT` vs `UNPAID` / `ISSUED`), `description` (required, `<= 255`), `paymentMethod` (`BANK_TRANSFER`, `CARD`, `CASH`, `OTHER` — shown when `COMPLETED`/`PAID`), `reference` / `orderNumber` (optional reference for payment).
    2. **Execution:**
       - Always creates `POST /api/v1/invoices` (`customerId`, `issueDate: orderDate`, `dueDate: orderDate`, `notes: description`, single item `{ description, quantity: 1, unitPrice: amount, taxRate: 0 }`).
       - If user selected `UNPAID` (Issued): additionally calls `POST /api/v1/invoices/{invoiceId}/issue?sent=false`.
       - If user selected `COMPLETED` / `PAID`: calls `POST /api/v1/invoices/{invoiceId}/issue?sent=false` then `POST /api/v1/invoices/{invoiceId}/payments` with a session-unique `Idempotency-Key` (`Uuid().v4()`) so a 1:1 `INCOME` transaction is recorded.
       - If payment step fails after invoice creation, surface explicit error showing the created `invoiceNumber` and offering to open `InvoiceDetailsScreen` to complete payment without creating duplicate invoices!
    3. On success: invalidate `customerDetailProvider(id)`, `customerListProvider`, `customerSummaryProvider`, `invoicesProvider`, `transactionsProvider`, and `dashboardSummaryProvider`.
- **Archive Flow:** Shows `AlertDialog` (`deleteConfirm.title` / `message` noting historical invoices and transaction logs remain preserved) → `DELETE /api/v1/customers/{id}` → toast + invalidate providers + pop.

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Request / Headers | Response DTO | Notes |
|---|---|---|---|---|
| Get Customer Detail | `GET /api/v1/customers/{id}` | `X-Business-Id` | `200 CustomerDTO` | Populates `orders: CustomerInvoiceLinkDTO[]`, `invoicedAmount`, `outstandingBalance`, `totalRevenue`. |
| Update Customer | `PUT /api/v1/customers/{id}` | `UpdateCustomerRequest` | `200 CustomerDTO` | Triggered via shared `AddEditCustomerSheet`. |
| Archive Customer | `DELETE /api/v1/customers/{id}` | — | `204 No Content` | Soft-archive (`archivedAt`, `status = "Archived"`). |
| Add Order (Step 1) | `POST /api/v1/invoices` | `CreateInvoiceRequest` | `201 InvoiceDTO` | Creates draft invoice linked to `customerId`. |
| Add Order (Step 2) | `POST /api/v1/invoices/{id}/issue?sent=false` | — | `200 InvoiceDTO` | Required before recording payment. |
| Add Order (Step 3) | `POST /api/v1/invoices/{id}/payments` | `Idempotency-Key: <uuid>`, `RecordPaymentRequest` | `201 PaymentDTO` | Only when `status` is `COMPLETED`/`PAID`; creates 1:1 `INCOME` transaction. |

---

## 8. State Management and Caching

- **`customerDetailProvider(String customerId)` (`FutureProvider.autoDispose.family`):** Watches `activeBusinessIdProvider` and calls `CustomerRepository.getById(customerId)`.
- **`addOrderControllerProvider` (`AsyncNotifier`):** Tracks multi-step invoice/issue/payment progress (`createdInvoiceId` saved in controller state so retrying a failed payment step does NOT create a duplicate `POST /invoices`!).

---

## 9. Validation, Error Handling, and Edge Cases

- **`AddOrderSheet` Validation:** `amount > 0` (`Decimal`), `description` non-blank (`<= 255` chars), `orderDate` valid ISO date.
- **Partial Step Failure in `AddOrderSheet`:** If `POST /invoices` succeeds (`201`) and `POST /payments` fails (network drop or validation), keep the `createdInvoiceId` in memory and retry only `/issue` + `/payments` with the same `Idempotency-Key`!
- **`READ_ONLY` Business:** Disable `+ Add Order`, `Edit`, and `Archive` buttons and show read-only tooltip/banner.
- **Empty `customerCode`:** Backend always assigns `CST-XXXX` on create, but defensively fall back to `CST-${id.substring(0, 4).toUpperCase()}` if ever null.

---

## 10. Localization and RTL Support

- Add missing `orderStatuses` keys (`draft`, `sent`, `unpaid`, `partiallyPaid`, `paid`, `overdue`) and `outstandingBalance`, `invoicedAmount`, `archivedNotice` to `app_en.arb` and `app_ar.arb`.
- Wrap `customerCode`, `invoiceNumber`, `email`, `phone`, and `MoneyText` in `Directionality(textDirection: TextDirection.ltr)`.
- Date formatting respects `business.dateFormat` in Gregorian calendar (`intl`).

---

## 11. Accessibility and Touch Ergonomics

- Minimum `48x48dp` targets for copy code button, phone/email links, order cards, and bottom action buttons.
- Copy action provides haptic feedback (`HapticFeedback.lightImpact()`) + semantic announcement (`AfabToast`).
- Sticky bottom action bar respects `MediaQuery.paddingOf(context).bottom` (`SafeArea`).

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- Backend validates `customer.business.id == activeBusiness.id` (`403 ForbiddenException` otherwise).
- Multi-step Add Order uses `Idempotency-Key` header on `/payments` to prevent duplicate `INCOME` transactions on retry.
- `BusinessAccessGuard.assertEditable(business)` enforced on Edit, Archive, and Add Order endpoints.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:** `CustomerDTO` deserialization with populated `orders[]` (`CustomerInvoiceLinkDTO`), mapping all 7 `InvoiceStatus` enum values, `AddOrderController` retry state preserving `createdInvoiceId` & `idempotencyKey`.
2. **Widget Tests:**
   - Verify `GET /customers/{id}` is invoked on screen mount even when navigated from list.
   - Verify `outstandingBalance` from DTO renders accurately (not `$0.00`).
   - Verify tapping `customerCode` copies exact code to clipboard and shows toast.
   - Verify all 7 `InvoiceStatus` badges render localized EN & AR labels without fallback errors.
   - Verify `paymentMethod: null` does not render a fake `"Bank Transfer"` label.
3. **Integration Test:** Open customer details → Add Order (`COMPLETED`) → verify `POST /invoices`, `POST /issue`, `POST /payments` fire in sequence → verify `orders[]`, `totalRevenue`, and `ordersCount` increment.

---

## 14. Dependencies and Risks

- **Dependencies:** `CustomersScreen` (`BIZ-01`), `InvoiceDetailsScreen` (`BIZ-04`), `url_launcher`, `uuid`, `decimal`.
- **Risks:**
  - **Multi-Step Add Order Atomicity:** Backend has no single `/customers/{id}/orders` endpoint, requiring 1–3 sequential HTTP calls. Mitigated by persisting `createdInvoiceId` + `idempotencyKey` during the sheet lifecycle.
  - **Raw Cross-Currency Aggregation:** If a customer has invoices in both `USD` and `EUR`, backend sums raw totals without FX conversion (`CustomerFinancialMetricsProviderImpl`). Display business currency with a subtle multi-currency disclaimer if linked invoices vary in currency.
