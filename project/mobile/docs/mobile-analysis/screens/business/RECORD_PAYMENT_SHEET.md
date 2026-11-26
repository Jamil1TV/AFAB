# RECORD_PAYMENT_SHEET (`BIZ-06`)

> **Domain:** Business Operations (`invoices`)
> **Task Reference:** `P3-06`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/invoices/page.tsx` (Record Payment Modal), `Web/project/frontend/lib/api/invoices.ts`
> **Backend Source:** `InvoiceController.java`, `InvoiceService.java` (`recordPayment`), `RecordPaymentRequest.java`, `InvoiceDTO.java` (`PaymentDTO`)

---

## 1. Screen Identity

- **Screen ID:** `BIZ-06`
- **Screen Name:** `RecordPaymentSheet`
- **Flutter File Path:** `lib/features/invoices/presentation/widgets/record_payment_sheet.dart`
- **Presentation Style:** `AfabBottomSheet` (`isScrollControlled: true`) on phones (`< 600dp`), centered `Dialog` (`maxWidth: 480dp`) on tablets (`>= 600dp`).
- **Route / Trigger:** Modal sheet opened from `InvoiceDetailsScreen` (`BIZ-04`) when `invoice.status` is `SENT`, `UNPAID`, `PARTIALLY_PAID`, or `OVERDUE` and `outstandingBalance > 0`.

---

## 2. Purpose and Functional Scope

Atomically and idempotently records a full or partial payment against an issued invoice (`POST /api/v1/invoices/{id}/payments`), generating a single UUID v4 `Idempotency-Key` per sheet session, supporting optional manual FX rate override when the invoice currency differs from the business base currency, and clearly informing the user that recording a payment creates a 1:1 linked `COMPLETED` `INCOME` transaction in the ledger.

### Confirmed Web Gaps Addressed on Mobile
1. **Expose Optional `exchangeRate` Input:** `RecordPaymentRequest.java` accepts `exchangeRate` (`@DecimalMin("0.000001")`) which `InvoiceService.java:499` passes to `TransactionService.applyFxSnapshot(...)`. Web omits this field entirely! Mobile exposes an optional **Manual Exchange Rate** field whenever `invoice.currency != activeBusiness.currency` (with clear hint: *"Leave blank to use live FX spot rate"*).
2. **Cryptographic UUID v4 `Idempotency-Key`:** Uses `Uuid().v4()` generated **once when the sheet opens** (stored in sheet state and reused on any retry of the same payment submission until the sheet succeeds or is dismissed), replacing Web's `Math.random()`.
3. **Explicit 1:1 `INCOME` Transaction Accounting Notice:** Clearly communicates to the user before confirming that this payment creates an immutable `INCOME` ledger transaction with an FX snapshot and transitions the invoice to `PARTIALLY_PAID` or `PAID`.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Point:** `InvoiceDetailsScreen` (`BIZ-04`) → `Record Payment` button.
- **Exit Flows:**
  - Confirm succeeds (`201 PaymentDTO`) → closes sheet, shows `AfabToast.success("Payment recorded and income transaction created.")`, refreshes `InvoiceDetailsScreen` (`BIZ-04`), `InvoicesScreen` (`BIZ-03`), `CustomersScreen`/`CustomerDetailsScreen` (`BIZ-01`/`BIZ-02`), `TransactionsScreen`, and `DashboardScreen`.
  - Cancel / Dismiss → closes sheet and discards the session's `idempotencyKey`.

---

## 4. Layout and Responsive Behavior

- **Phone (`< 600dp`):** Draggable/scrollable `AfabBottomSheet` (`maxHeight: 90%` screen height) with `SafeArea` and `AnimatedPadding(viewInsets.bottom)`.
- **Tablet (`>= 600dp`):** Centered `Dialog` (`maxWidth: 480dp`, `24dp` radius) with `SingleChildScrollView`.

---

## 5. UI Components and Visual Hierarchy

1. **Sheet Header:**
   - Title: `"Record Payment"`
   - Subtitle: `${invoice.invoiceNumber} · Remaining: ${MoneyText(invoice.outstandingBalance, invoice.currency)}`
   - Close button (`X`).
2. **1:1 Linked Income Notice (`AfabInsetPanel` with `info` tint):**
   - Info icon + concise message: *"Recording this payment automatically creates a 1:1 COMPLETED Income transaction in your ledger and updates the invoice balance."*
3. **Amount Input & Quick-Fill Chips:**
   - **Amount (`invoice.currency`) *:** `AfabTextField` with `TextInputType.numberWithOptions(decimal: true)`, prefilled with `invoice.outstandingBalance` formatted to the currency's minor units.
   - **Quick-Fill Chips:** `"Full Balance"` (`100%`) and `"50%"` (`outstandingBalance / 2` rounded `HALF_UP` to currency minor units) for effortless 1-tap partial/full entry.
   - Helper caption: *"Supports full or partial payment up to ${MoneyText(outstandingBalance, invoice.currency)}."*
4. **Date & Payment Method Row (2 columns):**
   - **Payment Date *:** Native date picker defaulting to `LocalDate.now()`.
   - **Payment Method:** `AfabSelectField` (`BANK_TRANSFER` / *"Bank Transfer"*, `CARD` / *"Card"*, `CASH` / *"Cash"*, `OTHER` / *"Other"*).
5. **Conditional FX Override Field (Visible ONLY when `invoice.currency != activeBusiness.currency`):**
   - **Exchange Rate (`1 ${invoice.currency} = ? ${activeBusiness.currency}`):** Optional decimal numeric input (`>= 0.000001`).
   - Helper text: *"Optional manual FX rate for the linked ${activeBusiness.currency} income transaction. Leave blank for automatic spot rate."*
   - Live converted preview (when manual rate entered): `≈ ${MoneyText(amount * rate, activeBusiness.currency)}`.
6. **Reference & Notes:**
   - **Reference:** Optional text field (`maxLength: 255`, placeholder `"Wire transfer # or receipt reference"`).
   - **Notes:** Optional text field (`maxLength: 1000`).
7. **Footer Action Row:**
   - `Cancel` (`AfabButton.secondary`)
   - `Confirm Payment` (`AfabButton` emerald primary, disabled + inline spinner while `paySubmitting`).

---

## 6. Interactive States and User Flows

- **Session Idempotency Lifecycle:**
  1. Sheet initializes `_idempotencyKey = const Uuid().v4()` in `initState` / controller constructor.
  2. When user taps `Confirm Payment`, app sends `POST /api/v1/invoices/${invoice.id}/payments` with **both** HTTP header `Idempotency-Key: $_idempotencyKey` and JSON body field `idempotencyKey: $_idempotencyKey`.
  3. If a network timeout or `5xx` occurs and the user taps `Confirm Payment` again inside the same open sheet, the **exact same `_idempotencyKey`** is sent. Backend `InvoiceService.java:448-453` checks `(businessId, invoiceId, idempotencyKey)` and safely replays the existing `PaymentDTO` without creating duplicate `Payment` or `INCOME` `Transaction` rows!
  4. If the backend rejects with `400` or `409` (e.g. currency mismatch or over-balance), user fixes input and retries; because backend only persists `idempotencyKey` on committed payments, the same key remains valid for the corrected retry.
- **Validation Before Submit:**
  - `Decimal.tryParse(amountStr)` must exist, `>= Decimal.parse('0.0001')`, and `<= invoice.outstandingBalance`.
  - If `exchangeRateStr` is non-empty, `Decimal.tryParse` must be `>= Decimal.parse('0.000001')`.

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Headers & Request Body | Response DTO | Notes |
|---|---|---|---|---|
| Record Payment | `POST /api/v1/invoices/{id}/payments` | Header: `Idempotency-Key: <uuid>`<br>Body (`RecordPaymentRequest`): `{ amount, currency, paymentDate, paymentMethod, reference?, notes?, idempotencyKey, exchangeRate? }` | `201 PaymentDTO` | Uses pessimistic row lock (`findByIdForUpdate`); creates 1:1 `INCOME` transaction; transitions invoice to `PARTIALLY_PAID` or `PAID`. |

---

## 8. State Management and Caching

- **`recordPaymentControllerProvider(String invoiceId)` (`Notifier.autoDispose`):** Holds `idempotencyKey`, form field values, `isSubmitting`, and `errorMessage`.
- **Post-Success Cache Invalidation:** Invalidates `invoiceDetailProvider(invoiceId)`, `invoiceListProvider`, `invoiceSummaryProvider`, `customerListProvider`, `customerSummaryProvider`, `customerDetailProvider(customerId)`, `transactionsProvider`, `revenueProvider`, and `dashboardSummaryProvider`.

---

## 9. Validation, Error Handling, and Edge Cases

- **Backend Validation Rules (`RecordPaymentRequest.java` & `InvoiceService.java`):**
  - `amount`: `@NotNull`, `@DecimalMin("0.0001")`, and `<= invoice.outstandingBalance` (overpayment strictly rejected).
  - `currency`: Must match `invoice.currency` (`400` if mismatched). Mobile always passes `invoice.currency` directly.
  - `paymentDate`: `@NotNull`.
  - `paymentMethod`: `^(BANK_TRANSFER|CARD|CREDIT_CARD|CASH|OTHER)$`.
  - `reference`: `<= 255` chars; `notes`: `<= 1000` chars; `idempotencyKey`: `<= 128` chars.
  - `exchangeRate`: `@DecimalMin("0.000001")` when provided.
- **Invoice Status Conflicts (`409`):** If invoice was paid or cancelled elsewhere while the sheet was open, surface server `409` message, disable confirm, and offer `"Refresh Invoice"`.
- **Precision Rounding:** Note `50%` quick-fill chip rounds `HALF_UP` to the currency's minor unit (`2` or `3` decimals) and ensures `amount <= outstandingBalance`.

---

## 10. Localization and RTL Support

- Extract all Web-hardcoded payment strings (`Record Payment`, `Remaining`, `Amount`, `Supports full or partial payment up to ...`, `Payment Date`, `Method`, `Bank Transfer`, `Card`, `Cash`, `Other`, `Reference`, `Notes`, `Confirm Payment`, `Recording...`, plus new strings for `Manual Exchange Rate` and `1:1 Income Transaction Notice`) into `app_en.arb` and `app_ar.arb`.
- Wrap `invoiceNumber`, `amount` input, `exchangeRate` input, and `MoneyText` values in `Directionality(textDirection: TextDirection.ltr)` with Western digits (`0–9`).

---

## 11. Accessibility and Touch Ergonomics

- `48dp` minimum height for quick-fill chips, date/method pickers, and action buttons.
- Clear `Semantics` label on the 1:1 `INCOME` transaction notice and `Full Balance` / `50%` chips.
- `viewInsets.bottom` animation ensures `Reference` and `Notes` fields remain visible above the soft keyboard.

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- Requires `Authorization` + `X-Business-Id` and `EDITABLE` business (`BusinessAccessGuard.assertEditable`).
- Backend pessimistic lock (`findByIdForUpdate`) + unique DB constraint on `(business_id, invoice_id, idempotency_key)` guarantees atomic balance allocation and prevents race-condition double-payments on flaky mobile networks.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:**
   - Verify `Uuid().v4()` is generated once per controller session and remains identical across simulated network-error retries.
   - Verify `Decimal` validation rejects `0`, negative values, and `outstandingBalance + 0.0001`, and validates `exchangeRate >= 0.000001`.
2. **Widget Tests:**
   - Verify `exchangeRate` field is hidden when `invoice.currency == business.currency` and visible when different (e.g., `EUR` invoice in `TND` business).
   - Verify `1:1 INCOME transaction` notice renders visibly.
   - Verify `Full Balance` and `50%` chips populate exact formatted `Decimal` strings.
3. **Integration Test:** Open `RecordPaymentSheet` on `SENT` invoice → enter partial amount → simulate timeout retry → verify same `Idempotency-Key` sent → verify invoice becomes `PARTIALLY_PAID` and linked `INCOME` transaction appears once.

---

## 14. Dependencies and Risks

- **Dependencies:** `uuid: ^4.5.3`, `decimal: ^3.2.6`, `intl`, `flutter_riverpod`, `InvoiceDetailsScreen` (`BIZ-04`).
- **Risks:**
  - **Closing & Reopening Sheet on Timeout:** If a user closes the sheet after an ambiguous network timeout and opens a fresh sheet, a new UUID is generated. Mitigated by showing an inline `"Retry Same Payment"` prompt on ambiguous timeouts before allowing dismissal, and refreshing `GET /invoices/{id}` on sheet close if any request was dispatched.
