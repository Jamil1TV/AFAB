# CREATE_EDIT_INVOICE_SCREEN (`BIZ-05`)

> **Domain:** Business Operations (`invoices`)
> **Task Reference:** `P3-06`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/invoices/page.tsx` (Create / Edit Draft Modal), `Web/project/frontend/lib/api/invoices.ts`
> **Backend Source:** `InvoiceController.java`, `InvoiceService.java`, `CreateInvoiceRequest.java`, `InvoiceDTO.java`

---

## 1. Screen Identity

- **Screen ID:** `BIZ-05`
- **Screen Name:** `CreateEditInvoiceScreen`
- **Flutter File Path:** `lib/features/invoices/presentation/create_edit_invoice_screen.dart`
- **Supporting Picker Sheet:** `CustomerPickerSheet` (`lib/features/customers/presentation/widgets/customer_picker_sheet.dart`)
- **Route Path (`GoRouter`):** `/invoices/new` (Create) and `/invoices/:invoiceId/edit` (Edit Draft) — presented as a full-screen modal route (`fullscreenDialog: true`) on phones and constrained modal/full page (`maxWidth: 760dp`) on tablets.

---

## 2. Purpose and Functional Scope

Provides a multi-item invoice builder for creating new `DRAFT` invoices (`POST /api/v1/invoices`) and editing existing `DRAFT` invoices (`PUT /api/v1/invoices/{id}`), complete with a scalable searchable customer picker, invoice currency selection, issue/due date validation, dynamic line items using exact `Decimal` arithmetic, discount, notes, and live totals calculation matching backend `InvoiceService.applyItemsAndTotals`.

### Confirmed Web Limitation Fixed on Mobile
- **Paginated/Searchable Customer Picker Beyond 100 Customers:** Web fetches `CustomerService.getCustomers({ page: 0, size: 100 })` once on mount and drops any customers past #100! Mobile replaces the flat `<select>` with `CustomerPickerSheet`, which queries `GET /api/v1/customers?search=<query>&page=<p>&size=20` with debounced server-side search and infinite scroll pagination, plus an explicit *"Walk-in / No Customer"* option.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - `InvoicesScreen` (`BIZ-03`) → `+ Create Invoice` CTA (Create mode).
  - `InvoiceDetailsScreen` (`BIZ-04`) → `Edit Draft` CTA (Edit mode, only enabled when `invoice.status == "DRAFT"`).
  - Optional deep-link/shortcut from `CustomerDetailsScreen` (`BIZ-02`) pre-selecting `customerId`.
- **Exit Flows:**
  - Save Draft (`POST` / `PUT`) succeeds → pops back with saved `InvoiceDTO`, refreshes `BIZ-03` & `BIZ-04` (on Create, optionally navigates directly to `InvoiceDetailsScreen` so the user can immediately Issue or export PDF).
  - Back / Close (`X`) when `isDirty == true` → shows `"Discard unsaved invoice changes?"` confirmation dialog.

---

## 4. Layout and Responsive Behavior

- **Phone (`< 600dp`):** Full-screen `Scaffold` with top AppBar (`Close X`, title `"Create Invoice (Draft)"` or `"Edit Draft INV-..."`, `"Save"` action), scrollable `Form` inside `SafeArea` + `AnimatedPadding(viewInsets.bottom)`, and sticky bottom summary & `"Save Draft"` CTA bar.
- **Tablet (`>= 600dp`):** Centered scrollable `maxWidth: 760dp` sheet/page; line items can render in a clean 12-col horizontal row (`Description | Qty | Unit Price | Tax % | Line Total | Delete`) on `>= 720dp`, while stacking cleanly into 2 rows per line card on `< 720dp` phones so no input is cramped below `60dp` width.

---

## 5. UI Components and Visual Hierarchy

1. **Customer & Currency Section (`AfabCard`):**
   - **Customer Selector Field (`AfabSelectField`):** Displays selected `customer.name (customerCode)` or `"Walk-in / No Customer"`. Tapping opens `CustomerPickerSheet` (searchable `GET /customers?search=&page=&size=20`, infinite scroll, `+ Quick Add Customer` optional shortcut, and `"Walk-in / No Customer"` top tile).
   - **Invoice Currency Picker:** Defaults to `activeBusiness.currency` on Create (or `editingInvoice.currency` on Edit). Options include `[activeBusiness.currency, "USD", "EUR", "TND", "GBP", "AED", "SAR", "CAD", "CHF", "QAR", "KWD"]` deduplicated (plus full ISO currency search if needed).
2. **Dates Section (`AfabCard`, 2-column row):**
   - **Issue Date *:** Native date picker, defaults to `LocalDate.now()`.
   - **Due Date *:** Native date picker, defaults to `today + 30 days`. Enforces `dueDate >= issueDate` (auto-advances or flags inline error if user sets `issueDate > dueDate`).
3. **Dynamic Line Items Builder (`AfabCard`):**
   - Header: `"Line Items"` + `"+ Add Line"` button (`TextButton.icon`).
   - Each line item card (`AfabInsetPanel`):
     - **Description *:** Text input (`maxLength: 255`, required).
     - **Quantity *:** Decimal numeric input (`>= 0.0001`, default `"1"`).
     - **Unit Price *:** Decimal numeric input (`>= 0`, placeholder `"0.00"`).
     - **Tax Rate (%):** Decimal numeric input (`0.00` to `100.00`, default `"0"`).
     - **Computed Line Preview:** Live `Decimal` readout (`Line Subtotal` + `Line Tax` = `Line Total` in `formCurrency`).
     - **Remove Line Icon (`Trash2`):** Disabled when `items.length == 1`.
4. **Discount & Live Totals Card (`AfabCard`):**
   - **Discount (`formCurrency`):** Decimal numeric input (`>= 0`, default `"0"`).
   - **Live Summary Panel (`AfabInsetPanel`):**
     - `Subtotal`: `MoneyText(previewSubtotal, formCurrency)`
     - `Tax`: `MoneyText(previewTax, formCurrency)`
     - `Discount` (if `> 0`): `-MoneyText(discount, formCurrency)`
     - `Total`: `MoneyText(previewTotal, formCurrency)` (bold, primary highlight)
5. **Notes Field (`AfabCard`):** Multiline `AfabTextField` (`maxLength: 2000`, placeholder `"Payment terms, bank details, or reference notes..."`).
6. **Sticky Bottom Bar:**
   - Displays compact live `Total` + `Cancel` + primary **`Save Draft Invoice`** / **`Update Draft`** button (with inline spinner while submitting).

---

## 6. Interactive States and User Flows

- **Exact `Decimal` Calculation Rules (1:1 Parity with `InvoiceService.applyItemsAndTotals`):**
  - For each line:
    - `qty = Decimal.parse(q)` (rounded `HALF_UP` to 4 decimals)
    - `unit = Decimal.parse(u)` (rounded `HALF_UP` to 4 decimals)
    - `taxRate = Decimal.parse(tr)` (rounded `HALF_UP` to 2 decimals)
    - `lineSub = (qty * unit)` (scale 4, `HALF_UP`)
    - `lineTax = (lineSub * taxRate / 100)` (scale 4, `HALF_UP`)
    - `lineTotal = lineSub + lineTax`
  - `subtotal = sum(lineSub)`, `taxAmount = sum(lineTax)`.
  - `total = (subtotal + taxAmount - discount)` clamped/validated so `discount <= subtotal + taxAmount`.
- **Edit Draft Guard:** If opened via `/invoices/:id/edit` and fetched `InvoiceDTO.status != "DRAFT"`, show blocking error banner (`"Only DRAFT invoices can be edited"`) and disable submission.
- **Submit Flow:**
  1. Validate dates (`dueDate >= issueDate`), at least 1 valid line item (`description` non-blank, `quantity >= 0.0001`, `unitPrice >= 0`, `taxRate 0..100`), and `discount <= subtotal + taxAmount`.
  2. Call `POST /api/v1/invoices` (Create) or `PUT /api/v1/invoices/{id}` (Edit).
  3. On `201` / `200`: invalidate `invoiceListProvider`, `invoiceSummaryProvider`, `invoiceDetailProvider(id)`, and `customerListProvider`/`customerDetailProvider(customerId)` → pop with success toast (`"Invoice INV-... created as DRAFT"` / `"Draft INV-... updated"`).

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Request Payload (`CreateInvoiceRequest`) | Response DTO | Notes |
|---|---|---|---|---|
| Search Customers | `GET /api/v1/customers` | `?search=&page=&size=20` | `200 CustomerPageDTO` | Used by `CustomerPickerSheet` to scale beyond 100 customers. |
| Create Draft | `POST /api/v1/invoices` | `{ customerId?, issueDate, dueDate, currency, discountAmount, notes?, items[] }` | `201 InvoiceDTO` | Generates sequential `INV-YYYY-XXXX` server-side; status is `DRAFT`; creates NO income transaction. |
| Update Draft | `PUT /api/v1/invoices/{id}` | Same `CreateInvoiceRequest` | `200 InvoiceDTO` | Replaces `items[]` cleanly; `409` if `status != DRAFT`. |

---

## 8. State Management and Caching

- **`invoiceFormControllerProvider(InvoiceDTO? initialDraft)` (`Notifier.autoDispose`):** Manages immutable form state (`customer`, `currency`, `issueDate`, `dueDate`, `items[]`, `discount`, `notes`, `isDirty`, `isSubmitting`, `serverError`) and computes `InvoiceTotalsPreview` deterministically via `Decimal`.
- **`customerPickerProvider` (`AsyncNotifier`):** Handles debounced query + infinite scroll page accumulation inside `CustomerPickerSheet`.

---

## 9. Validation, Error Handling, and Edge Cases

- **Jakarta Bean Validation Parity (`CreateInvoiceRequest.java`):**
  - `issueDate`: `@NotNull`
  - `dueDate`: `@NotNull`, `dueDate >= issueDate`
  - `currency`: `^[A-Za-z]{3}$`
  - `discountAmount`: `>= 0.0000`, and `<= subtotal + taxAmount` (matching `InvoiceService.java:620`)
  - `notes`: `<= 2000` chars
  - `items`: `@NotEmpty` (at least 1 item)
  - `item.description`: `@NotBlank`, `<= 255` chars
  - `item.quantity`: `@NotNull`, `>= 0.0001`
  - `item.unitPrice`: `@NotNull`, `>= 0.0000`
  - `item.taxRate`: `0.00` .. `100.00`
- **409 / 400 Error Mapping:** Surface `ApiError.fieldErrors` or `ApiError.message` in an inline top error banner (`formError`) without losing user's entered line items.
- **Keyboard Decimal Separators:** Normalize comma `,` decimal input in locales or numeric keyboards into `.` before `Decimal.tryParse` (or restrict formatter cleanly).

---

## 10. Localization and RTL Support

- Localize all Web-hardcoded form labels (`Create Invoice (Draft)`, `Edit Draft`, `Customer (Optional)`, `Walk-in / No Customer`, `Invoice Currency`, `Issue Date`, `Due Date`, `Line Items`, `Add Line`, `Qty`, `Unit Price`, `Tax %`, `Discount`, `Subtotal`, `Tax`, `Total`, `Notes`, `Save Draft Invoice`, `Update Draft`) in `app_en.arb` and `app_ar.arb`.
- Wrap currency codes, dates, numeric inputs, and `MoneyText` totals in `Directionality(textDirection: TextDirection.ltr)` with Western digits (`0–9`).

---

## 11. Accessibility and Touch Ergonomics

- Minimum `48x48dp` touch targets for customer picker trigger, date fields, `+ Add Line`, line delete icon (`Trash2`), and sticky `Cancel` / `Save` buttons.
- `FocusNode` & `TextInputAction.next` chaining across item fields (`description` → `quantity` → `unitPrice` → `taxRate`).
- `Scrollable.ensureVisible` when adding a new line item so the newly added row scrolls smoothly into view above the soft keyboard.

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- Requests include `Authorization` + `X-Business-Id`.
- Backend validates `customerId` belongs to the same `businessId` (`403` otherwise) and `BusinessAccessGuard.assertEditable(business)` (`403 BUSINESS_READ_ONLY`).
- Entry routes guard against `READ_ONLY` workspaces before opening Create/Edit form.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:**
   - `Decimal` line subtotal/tax/discount/total calculation matches `InvoiceService.applyItemsAndTotals` (`HALF_UP` scale 4) across fractional quantities (`1.5`), 3-decimal `TND` prices (`12.345`), and tax rates (`19%`).
   - Validation rejects `dueDate < issueDate`, `quantity <= 0`, `taxRate > 100`, `discount > subtotal + tax`, and empty line items.
2. **Widget Tests:**
   - Verify `CustomerPickerSheet` paginates beyond 100 customers (`page=0`, `page=1`) and searches via API.
   - Verify adding/removing line items updates live totals immediately.
   - Verify dirty-state discard dialog triggers on back tap after edits.
   - Verify Light/Dark and EN/AR (`320dp` phone & `1024dp` tablet) zero overflow.
3. **Integration Test:** Create draft with 2 taxed items + discount + customer from page 2 → verify `POST /invoices` → open `BIZ-04` → `Edit Draft` → verify prefilled values and `PUT /invoices/{id}` update.

---

## 14. Dependencies and Risks

- **Dependencies:** `decimal: ^3.2.6`, `intl`, `flutter_riverpod`, `go_router`, `CustomerPickerSheet`, `InvoiceDetailsScreen` (`BIZ-04`).
- **Risks:**
  - **Floating-Point Drift vs Backend `BigDecimal`:** Using Dart `double` like Web (`Number(...)`) causes penny/millime discrepancies on fractional tax & 3-decimal `TND`/`KWD`. Mitigated strictly by `Decimal` math everywhere in `domain/` and `presentation/`.
  - **Soft Keyboard Crowding Multi-Line Forms:** Mitigated by stacking each line item cleanly into 2 spacious rows on `< 600dp` phones and using a sticky bottom total/save bar.
