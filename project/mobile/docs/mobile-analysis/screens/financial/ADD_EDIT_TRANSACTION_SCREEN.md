# `FIN-03` — Add / Edit / Duplicate Transaction Screen (`AddEditTransactionScreen`)

> **Domain:** Financial Core (`features/transactions`)
> **Priority:** P1 (Core Data Entry — Fixes Confirmed Web Duplicate `PUT` Bug & Missing Fields)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-03` |
| **Screen Name** | `AddEditTransactionScreen` |
| **Route Path (`GoRouter`)** | `/transactions/new`, `/transactions/:transactionId/edit`, `/transactions/:transactionId/duplicate` (Full-screen modal on phone; Dialog on tablet) |
| **Feature Module** | `lib/features/transactions/presentation/screens/add_edit_transaction_screen.dart` |
| **Web Source Equivalent** | `Web/project/frontend/components/dashboard/AddTransactionModal.tsx` |
| **Backend Controllers** | `TransactionController.java` (`POST /api/v1/transactions`, `PUT /api/v1/transactions/{id}`), `CurrencyController.java` (`GET /api/v1/currencies/convert`), `CategoryController.java` (`GET /api/v1/categories`) |
| **Access Level** | Authenticated + `EDITABLE` business (`BusinessAccessGuard.assertEditable`) |

---

## 2. Purpose & User Jobs

1. **Create New Transaction (`mode: create`):** Record an `INCOME` or `EXPENSE` transaction in the business base currency or any supported foreign currency with live FX conversion preview (and optional manual FX rate override).
2. **Duplicate Existing Transaction (`mode: duplicate`):** Pre-fill all attributes from an existing transaction, reset `transactionDate` to today, allow changing currency, and submit a **new** `POST /api/v1/transactions` entry (fixing Web's `PUT /transactions/` empty-ID bug).
3. **Edit Existing Transaction (`mode: edit`):** Update description, original amount, type, date, category, payment method, status, notes, or tax deductibility via `PUT /api/v1/transactions/{id}`, while enforcing backend historical FX currency immutability.

---

## 3. Navigation & Entry/Exit Flows

### Entry Points & Route Arguments (`TransactionFormArgs`)
- **From `FIN-01` (`TransactionsScreen`):** `mode: create` (default `type: EXPENSE`), `mode: edit`, or `mode: duplicate`.
- **From `FIN-02` (`TransactionDetailsScreen`):** `mode: edit` or `mode: duplicate`.
- **From `FIN-06` (`ExpensesScreen`):** `mode: create`, `initialType: TransactionType.expense`.
- **From `FIN-07` (`RevenueScreen`):** `mode: create`, `initialType: TransactionType.income` (fixes Web Revenue page defaulting to `EXPENSE`).
- **From `DashboardScreen`:** Quick-create CTA (`mode: create`).

### Exit Points
| Trigger | Behavior |
|---|---|
| `Cancel` / System Back | If `isDirty == true`, show `"Discard unsaved changes?"` dialog; otherwise pop route. |
| `Save / Record / Update` Success | Shows `AfabToast` confirmation, pops route returning saved `TransactionEntity`, invalidates `transactionListProvider`, `transactionDetailProvider`, `expenseSummaryProvider`, `revenueSummaryProvider`, `dashboardSummaryProvider`, and `budgetListProvider`. |
| `403 BUSINESS_READ_ONLY` | Shows `BusinessReadOnlySheet` and blocks mutation. |

---

## 4. Layout & Visual Architecture

- **Phone (`< 600dp`):** Full-screen modal `Scaffold` (`fullscreenDialog: true`) with:
  - **AppBar:** Close (`X`) button, dynamic title (`Add New Transaction` / `Duplicate Transaction` / `Edit Transaction`), subtitle.
  - **Scrollable Form Body (`SingleChildScrollView` + `AnimatedPadding` for `viewInsets.bottom`):**
    1. **Type Segmented Switch:** `Income (+)` (`#10B981` active) vs `Expense (-)` (`AfabColors.primary` active).
    2. **Description Input:** `AfabTextField` (`maxLength: 255`, required).
    3. **Amount & Currency Row:**
       - `Amount` decimal input (`TextInputType.numberWithOptions(decimal: true)`).
       - `Currency` selector pill (`Lock` icon + disabled in `edit` mode; active in `create` and `duplicate` modes).
    4. **FX Banner (Conditional):**
       - In `create`/`duplicate` when `originalCurrency != baseCurrency && amount > 0`: Live FX Snapshot card (`"1 {orig} = {rate} {base} ≈ {converted} {base}"`) + expandable `"Custom FX Rate (Optional)"` numeric field (`exchangeRate >= 0.000001`).
       - In `edit` mode: Locked Historical FX Snapshot banner (`Lock` icon + `legacyFx` or `Locked FX rate: {rate} ({orig} -> {base}) • Base: {converted}`).
    5. **Split-Parent Edit Notice (Conditional):** When `mode == edit && transaction.isSplit == true`, informational banner explaining split allocations cannot be modified via Edit (`UpdateTransactionRequest` ignores `splitItems`); only metadata/total may be adjusted or user can delete & re-split.
    6. **Date & Status Row:**
       - `Transaction Date` native date picker (`MM/DD/YYYY` / `business.dateFormat`, Gregorian calendar).
       - `Status` picker (`COMPLETED` default, `PENDING`, `CANCELLED`).
    7. **Category & Payment Method:**
       - `Category` bottom-sheet picker (filtered strictly to active `type == INCOME | EXPENSE`, showing color dot + icon + name, plus `"Uncategorized"` option).
       - `Payment Method` picker (`BANK_TRANSFER`, `CARD`, `CREDIT_CARD`, `CASH`, `OTHER`).
    8. **Notes Input:** Multi-line `AfabTextField` (`maxLength: 1000`, optional).
    9. **Tax Deductible Card (`AfabInsetPanel`):** Switch/checkbox `"Tax Deductible Business Expense"` + conditional `VAT / Tax %` decimal field (`taxRate`).
  - **Sticky Bottom Action Bar (`SafeArea`):** `Cancel` (secondary) + `Record Transaction` / `Update Transaction` (primary `AfabButton` with inline loading spinner).

- **Tablet (`>= 600dp`):** Centered modal dialog (`maxWidth: 600dp`, `maxHeight: 88%` viewport) with 2-column field groupings matching Web layout.

---

## 5. UI Components & Interactive Controls

| Control | Details |
|---|---|
| **`TransactionTypeSegmentedControl`** | Switching between `INCOME` and `EXPENSE` clears `categoryId` if the selected category belongs to the other type (matching `AddTransactionModal.tsx:160,175`). |
| **`CurrencyPickerSheet`** | Searchable ISO currency list (`USD`, `EUR`, `TND`, `GBP`, `AED`, `SAR`, `CAD`, `CHF`, `QAR`, `KWD`, `JPY`, plus business currency marked `(Base)` and any `originalCurrency` on duplicated/edited tx). |
| **`FxPreviewBanner`** | Displays debounced (`300ms`) live `GET /currencies/convert` result, loading shimmer, or graceful fallback notice if offline/quote fails. |
| **`ManualFxRateField`** | Collapsible optional override (`CreateTransactionRequest.exchangeRate`) shown only when `!isEditing && originalCurrency != baseCurrency`. |
| **`CategoryPickerSheet`** | Lists `filteredCategories` (`c.type == type`) with color dot; includes quick link `"Manage Categories"` (`FIN-05`) if desired category is missing. |
| **`StatusSelector`** | Segmented/dropdown for `COMPLETED`, `PENDING`, `CANCELLED` (backend default `COMPLETED`). |
| **`PaymentMethodSelector`** | All 5 backend-validated enum values: `BANK_TRANSFER`, `CARD`, `CREDIT_CARD`, `CASH`, `OTHER`. |

---

## 6. Data Requirements & API Contracts

### 6.1 `POST /api/v1/transactions` (`mode: create | duplicate`)
- **Request (`CreateTransactionRequest.java`):**
  ```json
  {
    "type": "EXPENSE",
    "amount": 150.00,
    "originalCurrency": "EUR",
    "exchangeRate": null,
    "description": "Figma Pro",
    "transactionDate": "2026-11-25",
    "categoryId": "uuid-or-null",
    "paymentMethod": "CREDIT_CARD",
    "status": "COMPLETED",
    "notes": "Annual team seat",
    "taxDeductible": true,
    "taxRate": 19.0
  }
  ```
- **Response:** `201 Created` (`TransactionDTO`).

### 6.2 `PUT /api/v1/transactions/{id}` (`mode: edit`)
- **Request (`UpdateTransactionRequest.java`):** Same fields EXCEPT **never** send a changed `originalCurrency` and omit `exchangeRate` (rejected/not supported on update). Backend recalculates `convertedAmount = updatedOrig * tx.exchangeRate` using the locked historical rate (`TransactionService.java:330-343`).
- **Response:** `200 OK` (`TransactionDTO`).

### 6.3 `GET /api/v1/currencies/convert?from={orig}&to={base}&amount={amt}`
- **Public / Authenticated:** Returns `{ from, to, amount, exchangeRate, convertedAmount }`.
- Called only when `!isEditing && originalCurrency != baseCurrency && parsedAmount > 0`.

### 6.4 `GET /api/v1/categories`
- Hydrates category dropdown; cached in `categoryListProvider`.

---

## 7. State Management & Data Flow

```text
addEditTransactionController (AutoDisposeNotifierProvider.family<AddEditTxState, TransactionFormArgs>)
  ├── mode: TransactionFormMode { create, duplicate, edit }
  ├── form fields: type, description, amountText, originalCurrency, manualRateText,
  │                transactionDate, categoryId, paymentMethod, status, notes, taxDeductible, taxRateText
  ├── fxQuoteState: AsyncValue<FxConvertResult?> (debounced 300ms via CancelToken)
  ├── isDirty: bool (tracks diff from initial state)
  └── submitting: bool, serverFieldErrors: Map<String, String>
```

- **Key Isolation:** Using `.family` keyed by `(mode, transactionId, initialType)` guarantees fresh state on every open — preventing stale form state across Create/Duplicate/Edit transitions.

---

## 8. Business Logic, Validation & Edge Cases

Exact client-side validation rules matching Jakarta Bean Validation (`CreateTransactionRequest.java` / `UpdateTransactionRequest.java`):

| Field | Rule & Constraints | Error / Edge Behavior |
|---|---|---|
| `type` | Required: `INCOME` \| `EXPENSE` | Segmented toggle always populated |
| `description` | Required, trimmed non-blank, `1..255` chars | Inline field error; `maxLength: 255` counter |
| `amount` | Required, valid `Decimal` `>= 0.0001` | Validates positive decimal; supports up to 4 fractional digits (`NUMERIC(19,4)`) |
| `originalCurrency` | 3-letter ISO code (`^[A-Za-z]{3}$`), defaults to `activeBusiness.currency` | Locked in `edit` mode; unlocked in `create` & `duplicate` |
| `exchangeRate` | Optional in `create`/`duplicate`, if entered `>= 0.000001` | Ignored if `originalCurrency == baseCurrency` |
| `transactionDate` | Required `LocalDate` (`YYYY-MM-DD`) | Defaults to `DateTime.now()` in `create` and `duplicate` |
| `categoryId` | Optional `UUID` | Must match `type` (`INCOME`/`EXPENSE`); auto-cleared if `type` changes |
| `paymentMethod` | `BANK_TRANSFER` \| `CARD` \| `CREDIT_CARD` \| `CASH` \| `OTHER` | Defaults to `BANK_TRANSFER` (`CreateTransactionRequest.java:42`) |
| `status` | `COMPLETED` \| `PENDING` \| `CANCELLED` | Defaults to `COMPLETED` (`CreateTransactionRequest.java:45`) |
| `notes` | Optional, trimmed, `<= 1000` chars | Character counter near limit |
| `taxDeductible` & `taxRate` | `taxDeductible` bool (default `false`); if `true` and `taxRate` entered, `0 <= taxRate <= 100` | When `taxDeductible` is toggled `false`, hide `taxRate` input and send `taxRate: null` |

- **Server `fieldErrors` Mapping:** If backend returns `400` with `ApiError.fieldErrors`, map field keys (`amount`, `description`, `transactionDate`, `categoryId`, `paymentMethod`, `status`, `notes`, `originalCurrency`, `exchangeRate`) directly onto matching form inputs.

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **Duplicate Calls `PUT /transactions/` with Empty ID:** `transactions/page.tsx:165` passes `id: ""` to `AddTransactionModal`, which sets `isEditing = Boolean(transactionToEdit)` (`true`) and calls `PUT /transactions/`! | `transactions/page.tsx:165-172`, `AddTransactionModal.tsx:53,103-105` | Mobile introduces explicit `TransactionFormMode { create, duplicate, edit }`. `duplicate` sets `isEditing = false`, unlocks currency, and calls `POST /transactions`. |
| **Missing `status` Selector:** Backend DTO supports `COMPLETED`, `PENDING`, `CANCELLED`, but Web `AddTransactionModal` provides no UI field for `status`. | `AddTransactionModal.tsx` vs `CreateTransactionRequest.java:44-45` | Mobile exposes `status` selector (`COMPLETED`, `PENDING`, `CANCELLED`). |
| **Missing `CREDIT_CARD` Payment Method:** `CreateTransactionRequest.java:41` & `UpdateTransactionRequest.java:31` allow `CREDIT_CARD`, omitted by Web `<select>`. | `AddTransactionModal.tsx:323-326` | Mobile includes `CREDIT_CARD` alongside `BANK_TRANSFER`, `CARD`, `CASH`, `OTHER`. |
| **Revenue Page Create Defaults to `EXPENSE`:** `revenue/page.tsx:683` opens `AddTransactionModal` which defaults to `"EXPENSE"`. | `AddTransactionModal.tsx:31`, `revenue/page.tsx:683` | Mobile accepts `initialType` parameter; Revenue screen passes `TransactionType.income`. |
| **Unvalidated Negative `taxRate` & Float Parsing:** Web `taxRate` input has no `min="0"` or `max="100"`. | `AddTransactionModal.tsx:363-370` | Mobile validates `0 <= taxRate <= 100` using `Decimal`. |
| **No Manual FX Rate Override UI:** Backend `CreateTransactionRequest.exchangeRate` supports manual rate override, unexposed on Web. | `CreateTransactionRequest.java:29-30`, `TransactionService.java:177-180` | Mobile offers optional `"Custom Exchange Rate"` input when foreign currency differs from base currency. |
| **Hardcoded English Strings:** `"Currency"`, `"FX Snapshot"`, `"Tax Deductible Business Expense"`, `"VAT / Tax %"`, `"Please enter a valid description..."`. | `AddTransactionModal.tsx:83,224,264,357,362` | All strings localized in `app_en.arb` and `app_ar.arb`. |

---

## 10. Design Tokens & Visual Styling

- **Modal Surface:** `AfabColors.surface` (`#FFFFFF` light / `#0C101C` dark), `AfabTextField` uses `surfaceInset` + `1px inputBorder` + `primary` focus ring.
- **Type Switcher:** `INCOME` uses `#10B981` fill; `EXPENSE` uses `AfabColors.primary` fill.
- **FX Live Banner:** `primary` 5% tint background, `primary` 25% border, `12dp` radius.
- **Locked Historical FX Banner:** `surfaceInset` background, `border` stroke, muted `Lock` icon (`14dp`).
- **Error Banner:** `AfabColors.danger` 10% tint, `1px` border, `12dp` radius.

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** `transactions.json` → `modal.*` (`25` keys) + new ARB keys for `Duplicate Transaction` title, `Status` labels (`Completed`, `Pending`, `Cancelled`), `Credit Card`, `Custom Exchange Rate`, `Discard Changes` prompt, and FX/Tax validation messages.
- **BiDi Rules:**
  - Currency codes (`USD`, `TND`, `EUR`), numeric amount/rate inputs, and FX preview equations (`1 EUR = 3.350000 TND`) forced `TextDirection.ltr`.
  - Localized Gregorian `showDatePicker` (`locale: activeLocale`).

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` (`< 360dp`) | Single-column vertical stack for Amount + Currency + Date + Status; sticky bottom bar with `Cancel` and `Save`. |
| `compact` (`360–599dp`) | 2-column paired rows (`Amount` + `Currency`, `Date` + `Status`); full-screen route with keyboard-aware scroll padding. |
| `medium` & `expanded` (`>= 600dp`) | Centered modal dialog (`maxWidth: 600dp`), 3-column (`Amount` / `Currency` / `Date`) + 2-column (`Category` / `Method` / `Status`) layout. |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** `Semantics` labels on Currency lock icon (`"Currency locked on existing transaction"`), logical `TextInputAction.next` focus traversal (`Description → Amount → Notes`), `48dp` minimum controls.
- **Security:** Never submits `originalCurrency` mutation on `PUT`; client validates lengths/ranges before network round-trip.
- **Performance:** `300ms` debounce + `CancelToken` on `GET /currencies/convert` prevents race conditions when typing amounts rapidly.

---

## 14. Dependencies and Risks

- **Dependencies:** `FIN-05` (`MANAGE_CATEGORIES_SCREEN.md`), `CurrencyRepository` (`/currencies/convert`), `Decimal` package, `intl`.
- **Risks & Mitigations:**
  1. **Offline FX Preview:** `GET /currencies/convert` fails if device is offline. *Mitigation:* Show subtle `"Live FX preview unavailable offline — backend will resolve rate on submit (or enter custom rate)"` without blocking form submission if online later, or block submit offline via `OfflineBanner` guard.
  2. **Editing Split Parent Amounts:** Changing `amount` on an already-split parent via `PUT /transactions/{id}` updates parent `amount` without updating child `splitItems` (backend `TransactionService.updateTransaction` ignores `splitItems`). *Mitigation:* Warn clearly on split-parent edit and recommend deleting & recreating split if line allocations changed.
