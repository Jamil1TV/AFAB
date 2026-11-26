# `FIN-04` — Split Transaction Screen (`SplitTransactionScreen`)

> **Domain:** Financial Core (`features/transactions`)
> **Priority:** P1 (Multi-Category Allocation — Fixes Stale Category, Hardcoded Type/Method/Currency & Float Math Bugs)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-04` |
| **Screen Name** | `SplitTransactionScreen` |
| **Route Path (`GoRouter`)** | `/transactions/split` (Full-screen modal on phone; Dialog `maxWidth: 680dp` on tablet) |
| **Feature Module** | `lib/features/transactions/presentation/screens/split_transaction_screen.dart` |
| **Web Source Equivalent** | `Web/project/frontend/components/dashboard/SplitTransactionModal.tsx` |
| **Backend Controllers** | `TransactionController.java` (`POST /api/v1/transactions` with `splitItems[]`), `CategoryController.java` (`GET /api/v1/categories`), `CurrencyController.java` (`GET /api/v1/currencies/convert`) |
| **Access Level** | Authenticated + `EDITABLE` business (`BusinessAccessGuard.assertEditable`) |

---

## 2. Purpose & User Jobs

1. **Allocate One Payment Across Multiple Categories:** Split a single receipt or invoice payment (e.g., an Amazon or supplier bill containing both *Office Supplies* and *Software* or *Hardware*) into `>= 2` category lines that sum exactly to the parent transaction total.
2. **Support Both Income & Expense Splits:** Allow splitting either `EXPENSE` or `INCOME` transactions (backend `TransactionService.java:240-294` supports both, unlike Web which hardcoded `EXPENSE`).
3. **Guarantee Exact Accounting Balance:** Use `Decimal` (`decimal` package) arithmetic matching PostgreSQL `NUMERIC(19,4)` so lines balance to `0.00` (or `0.000` for 3-decimal currencies like `TND`/`KWD`) with zero IEEE-754 floating-point drift.

---

## 3. Navigation & Entry/Exit Flows

### Entry Points
- `Split Expense` / `Split Transaction` button on `TRANSACTIONS_SCREEN.md` (`FIN-01`).
- Optional pre-fill from an existing transaction (`initialTransaction`) if duplicating into a split.

### Exit Points
| Trigger | Behavior |
|---|---|
| `Cancel` / Close | Discard confirmation dialog if `isDirty == true`; pops modal. |
| `Confirm Split Transaction` Success | Calls `POST /api/v1/transactions`, shows `AfabToast`, pops route, invalidates `transactionListProvider`, `dashboardSummaryProvider`, `expenseSummaryProvider`, `revenueSummaryProvider`, `budgetListProvider`. |
| `403 BUSINESS_READ_ONLY` | Shows `BusinessReadOnlySheet`. |

---

## 4. Layout & Visual Architecture

- **Phone (`< 600dp`):** Full-screen modal `Scaffold` (`fullscreenDialog: true`):
  - **AppBar:** Close (`X`), title `Split Transaction`, subtitle `"Allocate a single payment across multiple categories"`.
  - **Scrollable Body (`ListView` + `AnimatedPadding` for keyboard):**
    1. **Type Segmented Switch (`INCOME` / `EXPENSE`):** Updates available categories dynamically across all split lines.
    2. **Parent Transaction Card (`AfabInsetPanel`):**
       - `Total Amount` (`Decimal` numeric input) + `Currency` picker (defaults to `activeBusiness.currency`; shows live FX preview banner if foreign currency selected).
       - `Vendor / Master Description` (`maxLength: 255`, required).
       - `Date` picker (`YYYY-MM-DD`, defaults to today) + `Payment Method` picker (`BANK_TRANSFER`, `CARD`, `CREDIT_CARD`, `CASH`, `OTHER` — defaults to `CARD` or `BANK_TRANSFER`).
       - `Status` picker (`COMPLETED` default, `PENDING`, `CANCELLED`) + optional `Tax Deductible` toggle.
    3. **Split Lines Section:**
       - Header: `Split Lines (N)` + `+ Add Line` button.
       - Dynamic list of `SplitLineCard` items (minimum `2` lines):
         - Line index badge (`1`, `2`, ...) + `Trash2` remove button (disabled/shows validation toast when `lines.length <= 2`).
         - `Category` dropdown/sheet picker (filtered to `c.type == activeType`; shows category color dot).
         - `Line Memo` optional `AfabTextField` (`maxLength: 255`).
         - `Allocated Amount` decimal input + inline `Fill` chip (shown when `remaining != 0` and `currentVal + remaining > 0`).
  - **Sticky Bottom Balance & Action Bar (`SafeArea`):**
    - **Balance Summary Strip (`AfabInsetPanel`):**
      - `Total`: `MoneyText(totalAmount, selectedCurrency)`
      - `Allocated`: `MoneyText(allocatedSum, selectedCurrency)`
      - `Remaining`: If `isBalanced` → green check `"Balanced (TND 0.000)"` (dynamically formatted in `selectedCurrency`, **never** hardcoded `"$0.00"`); else danger `MoneyText(remaining, selectedCurrency)` (`Over-allocated` or `Unallocated`).
    - **Action Row:** `Cancel` + `Confirm Split Transaction` (disabled when `!isBalanced || submitting`).

- **Tablet (`>= 600dp`):** Centered dialog (`maxWidth: 680dp`, `maxHeight: 90%`) with horizontal 3-column parent grid and single-row compact split lines.

---

## 5. UI Components & Interactive Controls

| Component | Behavior |
|---|---|
| **`TypeSegmentedSwitch`** | Switches `INCOME` ↔ `EXPENSE`. Automatically reassigns any line `categoryId` that doesn't match the new type to the first available matching category (or empty so validation prompts selection). |
| **`SplitLineCard`** | Reorderable/indexed card containing Category Picker, Memo input, Amount input, `Fill` remaining shortcut, and Delete button. |
| **`FillRemainingButton`** | Computes `target = currentLineAmount + remaining` using exact `Decimal` addition; populates line amount formatted to currency minor units (e.g., `2` or `3` decimals). |
| **`BalanceSummaryBar`** | Live `Decimal` progress indicator (`allocatedSum / totalAmount` clamped `0..1`, green when exact match, amber when under-allocated, red when over-allocated). |

---

## 6. Data Requirements & API Contracts

### 6.1 `POST /api/v1/transactions`
- **Request (`CreateTransactionRequest.java`):**
  ```json
  {
    "type": "EXPENSE",
    "amount": 1000.000,
    "originalCurrency": "TND",
    "description": "Office Depot Bulk Order",
    "transactionDate": "2026-11-25",
    "paymentMethod": "CARD",
    "status": "COMPLETED",
    "taxDeductible": false,
    "splitItems": [
      { "categoryId": "uuid-1", "amount": 650.000, "description": "Desk & Chair" },
      { "categoryId": "uuid-2", "amount": 350.000, "description": "Printer Paper" }
    ]
  }
  ```
- **Backend Handling (`TransactionService.java:240-294`):**
  - Validates `splitSum.compareTo(request.getAmount()) == 0` in `BigDecimal`.
  - Validates every `splitItem.categoryId` exists, belongs to the business (or is system default), and matches `txType` (`INCOME` / `EXPENSE`).
  - Sets `isSplit = true` on parent; creates child `Transaction` rows inheriting `originalCurrency`, `exchangeRate`, `paymentMethod`, `status`, `taxDeductible`, `taxRate`, and `parentTransaction`.
  - Last child absorbs any FX conversion rounding residual (`tx.getConvertedAmount().subtract(runningConverted)`).
- **Response:** `201 Created` (`TransactionDTO` with populated `splitItems[]`).

### 6.2 `GET /api/v1/categories`
- Loaded via `categoryListProvider`; filtered by active `type`.

---

## 7. State Management & Data Flow

```text
splitTransactionController (AutoDisposeNotifierProvider)
  ├── type: TransactionType (EXPENSE default, INCOME selectable)
  ├── totalAmountText, description, transactionDate, originalCurrency, paymentMethod, status
  ├── lines: List<SplitLineDraft> (min 2; auto-hydrates default categoryIds when categories load!)
  └── Computed getters (pure Decimal):
        ├── totalDecimal: Decimal
        ├── allocatedDecimal: Decimal
        ├── remainingDecimal: Decimal (totalDecimal - allocatedDecimal)
        └── isBalanced: bool (totalDecimal > Decimal.zero && remainingDecimal == Decimal.zero)
```

---

## 8. Business Logic, Validation & Edge Cases

1. **Exact `Decimal` Balance Validation:**
   - Backend runs `splitSum.compareTo(request.getAmount()) != 0` (`BigDecimal` exact equality, not tolerance!). Therefore mobile must compute `remainingDecimal = totalDecimal - allocatedDecimal` and require `remainingDecimal == Decimal.zero` (not `abs < 0.001`).
   - Also validate every line `amount >= Decimal.parse('0.0001')` and `categoryId.isNotEmpty`.
2. **Minimum 2 Split Lines:**
   - Prevent deletion when `lines.length <= 2`; display inline warning `"A split transaction must have at least 2 lines."`
3. **Async Category Hydration (Fixing Stale `categoryId`):**
   - If `categoryListProvider` is still loading when `FIN-04` opens, `ref.listen(categoryListProvider, ...)` auto-populates empty `line.categoryId` fields with `availableCategories[0].id` and `availableCategories[1 % len].id` as soon as categories arrive.
4. **Budget Double-Count Awareness:**
   - Backend `TransactionRepository.sumCompletedExpenseByBusinessAndCategoryAndDateRange` (`line 95-96`) counts child split items against category budgets, while `FinanceStatsService` sums root transactions only (`parentTransaction IS NULL`). No duplicate inflation occurs.
5. **Empty Line Memo Fallback:**
   - If a line's `description` is left blank, backend defaults it to the parent `tx.getDescription()`. Mobile should display `"Optional memo"` rather than pre-filling noisy `"Line item 1"` strings unless user wants to type one (or leave optional).

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **Stale `categoryId` on Initial Render:** `useState` captures `availableCategories[0]?.id` on first mount; if `categories` is empty or user later toggles type, `categoryId` stays `""`. | `SplitTransactionModal.tsx:53-66` | Mobile watches `categoryListProvider` and reacts to `type` changes to assign valid `categoryId` defaults. |
| **Hardcoded `EXPENSE` Type:** No UI toggle to switch to `INCOME` even though `availableCategories` filters by `type`. | `SplitTransactionModal.tsx:41-43` | Mobile provides `INCOME` / `EXPENSE` segmented toggle. |
| **Hardcoded `CARD` Payment Method:** `paymentMethod` has no UI control and hardcodes `"CARD"`. | `SplitTransactionModal.tsx:47-49` | Mobile exposes full 5-option `paymentMethod` selector (`BANK_TRANSFER`, `CARD`, `CREDIT_CARD`, `CASH`, `OTHER`). |
| **Hardcoded `Balanced ($0.00)` Currency:** Ignores `currency` prop in the balanced badge! | `SplitTransactionModal.tsx:354` | Mobile renders `Balanced (${MoneyFormatter.format(Decimal.zero, currency)})`, respecting `TND 0.000`, `EUR 0.00`, etc. |
| **IEEE-754 Float Rounding Drift:** Uses `parseFloat` and `Math.round(... * 100) / 100`, breaking 3-decimal currencies (`TND`, `KWD`) and failing backend `BigDecimal.compareTo() == 0`. | `SplitTransactionModal.tsx:73-79` | Mobile uses `Decimal` arithmetic (`decimal` package) for exact equality with Spring Boot `BigDecimal`. |
| **Hardcoded English Copy:** Entire `SplitTransactionModal.tsx` bypasses `useTranslations("Transactions")` (despite importing `t`). | `SplitTransactionModal.tsx:33,178-380` | All labels, errors, and balance badges fully localized in `app_en.arb` and `app_ar.arb`. |

---

## 10. Design Tokens & Visual Styling

- **Header Icon Tile:** `Layers` icon in `AfabColors.primary` 10% tint + 20% border (`40x40dp`).
- **Parent Details & Balance Bar:** `AfabInsetPanel` (`surfaceInset`, `1px border`, `baseRadius`).
- **Balance States:**
  - Exact `0`: `AfabColors.success` (`CheckCircle2` icon + bold text).
  - Unbalanced (`!= 0`): `AfabColors.danger` bold text + `Fill` button in `AfabColors.primary` 10% tint.
- **Line Index Chip:** Monospace `tabularFigures` badge.

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** Add dedicated `txSplit*` ARB keys in `app_en.arb` and `app_ar.arb` (fixing Web's unlocalized `SplitTransactionModal.tsx`).
- **BiDi Rules:**
  - Total, Allocated, Remaining `MoneyText` values and `Balanced (CUR 0.000)` badge wrap amounts in `Directionality(textDirection: TextDirection.ltr)`.
  - Numeric line amount fields align end (`TextAlign.end`) in both LTR and RTL.

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` & `compact` (`< 600dp`) | Full-screen modal; each `SplitLineCard` stacks Category picker on top row, Memo + Amount + `Fill` + Delete cleanly on second row so inputs are never squished. |
| `medium` & `expanded` (`>= 600dp`) | Centered dialog (`maxWidth: 680dp`); horizontal inline split rows (`Index | Category | Memo | Amount | Fill | Delete`) matching Web's spacious grid. |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** Screen readers announce `"Line 1 of 2, Remaining balance 350.00 dollars"`; `Fill` button announces `"Fill remaining amount into line 1"`.
- **Security:** `EDITABLE` business guard; validates `categoryId` ownership/type cleanly before submit.
- **Performance:** Line list uses stable UUID/counter keys (`ValueKey(line.localId)`) so typing in one line never loses focus or rebuilds sibling text controllers.

---

## 14. Dependencies and Risks

- **Dependencies:** `decimal` (`^3.2.6`), `categoryListProvider` (`FIN-05`), `MoneyFormatter`, `CurrencyRepository` (if foreign currency selected).
- **Risks & Mitigations:**
  1. **Parent Category on Split:** Note `SplitTransactionModal` sends `splitItems[]` without a top-level `categoryId` (backend sets parent `category = null` → `"Uncategorized"` while children hold categories). *Mitigation:* Display `"Split (N categories)"` or child category chips cleanly on `FIN-01`/`FIN-02` when `tx.isSplit == true`.
  2. **3-Decimal Currencies in `Fill`:** Calling `.toFixed(2)` on `TND` loses the 3rd decimal place. *Mitigation:* Format `Fill` output using `currencyMinorUnits(selectedCurrency)` (`3` for `TND/KWD/BHD/OMR/JOD/LYD/IQD`).
