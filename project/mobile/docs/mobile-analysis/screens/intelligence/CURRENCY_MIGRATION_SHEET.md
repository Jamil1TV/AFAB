# INT-02 — Business Currency Migration Sheet Specification

> **Verified Sources:**
> - Web Component: `Web/project/frontend/components/settings/CurrencyMigrationModal.tsx`
> - Web Triggers: `Web/project/frontend/app/[locale]/(dashboard)/dashboard/currencies/page.tsx` (lines 306–317, 726–742), `messages/en/currencies.json` (`migrationModal`)
> - Web API: `Web/project/frontend/lib/api/currencies.ts` (`previewChange`, `changeBusinessCurrency`)
> - Backend: `CurrencyController.java` (lines 97–135), `CurrencyConversionService.java` (lines 1–131)
> - Mobile Core Docs: `03_API_CONTRACT_CATALOG.md`, `07_DESIGN_SYSTEM.md`, `08_LOCALIZATION_AND_RTL.md`, `13_RISKS_AND_TECHNICAL_DECISIONS.md`

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `INT-02` |
| **Screen Name** | `CurrencyMigrationSheet` |
| **Feature Module** | `lib/features/currencies/` (shared with `settings` / `business`) |
| **Route / Presentation** | Modal `AfabBottomSheet` on phone (`< 600dp`); centered `Dialog` (`maxWidth: 560dp`) on tablet (`>= 600dp`) |
| **Parent Triggers** | `CurrenciesScreen` (`INT-01` → *"Base: {code}"* button); optionally `GeneralSettingsScreen` / `BusinessProfileScreen` base currency action |

---

## 2. Purpose and Web Parity Status

- **Purpose:** Enables an `OWNER` or `ADMIN` of an `EDITABLE` business to change the business's default accounting currency for **future transactions**, previewing the live spot FX rate, current net balance, projected equivalent net balance, and historical transaction count while strictly enforcing **Historical Financial Immutability (Backend Policy P1.1)**.
- **Web Parity Status:** **Implemented and Connected**, with **2 critical Mobile UX & data improvements**:
  1. **Adds Selectable Target Currency Picker:** On Web (`currencies/page.tsx:310`), clicking `"Base: {baseCurrency}"` hardcodes `pendingCurrency = baseCurrency === "USD" ? "EUR" : "USD"`, and `CurrencyMigrationModal.tsx` provides **no dropdown** to pick any other target currency (`TND`, `QAR`, `GBP`, `AED`, `SAR`, etc.)! Mobile adds an in-sheet `AfabSelectField` allowing selection of any supported ISO currency (`16` core currencies + `BHD`/`OMR`, excluding `oldCurrency`).
  2. **Fixes 3-Decimal Minor-Unit Formatting & Removes Legacy Web Copy:** Web formats balances with `maximumFractionDigits: 2` (`CurrencyMigrationModal.tsx:164, 173`) and contains unused legacy strings in `currencies.json` (`optionConvert` / `optionKeep`) that contradict P1.1 immutability. Mobile formats `oldBalance` using `oldCurrency` minor units (`3` decimals for `TND`/`KWD`/`BHD`/`OMR`, `0` for `JPY`, `2` default) and clearly enforces immutability (`convertExistingTransactions: false`).

---

## 3. Navigation, Entry Points, and Deep Links

- **Entry Points:**
  - `CurrenciesScreen` (`INT-01`) → tap `Base: {baseCurrency}` chip in header.
  - `BusinessProfileScreen` / `GeneralSettingsScreen` → tap `"Change Base Currency"` (if exposed instead of raw `PUT /business/{id}` currency edit, ensuring audit log + immutability preview).
- **Dismissal & Post-Success Callback:**
  - Dismissing via Close (`X`), Cancel button, or backdrop tap (disabled while `submitting == true`) closes the sheet with no changes.
  - On `POST /currencies/business/change` success:
    1. Close sheet.
    2. Update `activeBusinessProvider`, `viewBaseCurrencyProvider` (sync to `newCurrency`), and invalidate `dashboardProvider`, `transactionsProvider`, `reportsProvider`, `currenciesProvider`, `invoicesProvider`, `budgetsProvider`.
    3. Show `AfabToast.success` confirming the new base currency and preserved historical transaction count.

---

## 4. Layout and Visual Hierarchy

1. **Sticky Sheet Header:**
   - Leading `40x40dp` rounded icon tile (`ArrowRightLeft`, `primary` 10% tint).
   - Title: *"Change Business Base Currency"* + subtitle *"Applies to future transactions with live FX preview"*.
   - Trailing Close (`X`) icon button (`disabled` during submission).
2. **Scrollable Body (`SingleChildScrollView` + `SafeArea`):**
   - **Error Banner (conditional):** Red `10%` tint banner with `AlertCircle` icon on preview/submit failure.
   - **Target Currency Selector (`AfabSelectField`):**
     - Label: *"Target Base Currency"* — searchable picker of supported currencies (`USD`, `EUR`, `TND`, `QAR`, `GBP`, `AED`, `SAR`, `CAD`, `JPY`, `CHF`, `KWD`, `MAD`, `TRY`, `EGP`, `AUD`, `CNY`, `BHD`, `OMR`), excluding `oldCurrency`. Changing this immediately triggers `GET /currencies/business/preview?newCurrency={selected}`.
   - **Loading State (while fetching preview):** Centered `AfabLoader` / spinner + *"Fetching real-time market exchange rate..."*.
   - **Preview Content (when loaded):**
     1. **Migration Flow Panel (`AfabInsetPanel`):** `From: {oldCurrency}` | Center pill (`1 {oldCurrency} = {rate.toFixed(4)} {newCurrency}` + pulsing green `"Live Market Rate"` subtitle) | `To: {newCurrency}`.
     2. **Balance Comparison Cards (2-col on `>= 400dp`, stacked on `< 400dp`):**
        - *Current Net Balance:* `MoneyText(oldBalance, currency: oldCurrency)` (e.g., `12,500.000 TND`).
        - *Projected Equivalent (`primary` 5% tint card):* `MoneyText(projectedBalance, currency: newCurrency)`.
     3. **Historical Transactions Badge Row (`AfabInsetPanel`):** `Coins` icon + *"Historical Transactions Preserved"* + neutral badge `"{transactionsCount} transaction(s)"`.
     4. **Historical Financial Immutability Notice (`primary` 5% tint card):**
        - `ShieldCheck` emerald icon + *"Historical Financial Immutability Enforced"*.
        - Copy: *"Updating your business base currency to **{newCurrency}** applies to all future transactions. All **{count}** existing historical transaction(s) will preserve their original amounts and locked historical exchange rates — past ledgers are never overwritten with today's rate."*
3. **Sticky Bottom Footer Bar:**
   - `Cancel` (`AfabButton.secondary`) + `Confirm Currency Change` (`AfabButton.primary`, shows spinner + *"Updating..."* while submitting; disabled if `loading || submitting || targetCurrency == oldCurrency || !canEdit`).

---

## 5. UI Components and Design System Mapping

| UI Element | Shared / Feature Widget | Design Token & Styling (`07_DESIGN_SYSTEM.md`) |
|---|---|---|
| Container | `AfabBottomSheet` (phone) / `Dialog` (tablet) | `surface` bg, `modal` radius (`24dp` default), drag handle on phone |
| Target Currency Picker | `AfabSelectField` / searchable picker sheet | `surfaceInset`, `1px inputBorder`, `primary` focus ring |
| Flow & Balance Panels | `AfabInsetPanel` | `surfaceInset` bg, `1px border`, `baseRadius` |
| Projected Balance & Policy Box | `Container` (`primary` 5% fill, `primary` 30% border) | Matches `CurrencyMigrationModal.tsx:168, 190` |
| Rate Pill | `Container` (`primary` solid fill, white bold text) | Rounded pill (`borderRadius: 999`), `Directionality.ltr` |
| Monetary Figures | `MoneyText` | `FontFeature.tabularFigures()`, `FittedBox.scaleDown`, explicit minor units |
| Action Buttons | `AfabButton.secondary` / `AfabButton.primary` | Min height `48dp`, `baseRadius` |

---

## 6. State Management and Data Flow

- **Controller (`currencyMigrationControllerProvider` — `AutoDisposeAsyncNotifier` / `StateNotifier`):**
  - Initial state: `oldCurrency = activeBusiness.currency`, `targetCurrency = oldCurrency == 'USD' ? 'EUR' : 'USD'`.
  - `selectTargetCurrency(String code)`: Validates `code != oldCurrency`, sets `previewAsync = AsyncLoading()`, calls `CurrencyRepository.previewChange(code)`.
  - `confirmMigration()`:
    1. Guards `submitting == false` and `activeBusiness.isEditable && (role == 'OWNER' || role == 'ADMIN')`.
    2. Calls `CurrencyRepository.changeBusinessCurrency(newCurrency: targetCurrency, convertExistingTransactions: false)`.
    3. On success (`result.success == true`): triggers cross-feature invalidation (`activeBusinessProvider.refresh()`, `businessListProvider`, `viewBaseCurrencyProvider.set(targetCurrency)`, `dashboardSummaryProvider`, `transactionsProvider`, `reportsProvider`), emits `Success` event to close sheet.
    4. On error (`403 ForbiddenException`, `403 BUSINESS_READ_ONLY`, `400 IllegalArgumentException`, network error): populates inline `errorMessage` without closing sheet.

---

## 7. API Contracts and DTO Mapping

| Endpoint | Auth & Permissions | Params / Body | Response DTO |
|---|---|---|---|
| `GET /api/v1/currencies/business/preview` | JWT + `X-Business-Id` (`CurrentBusinessService.getCurrentBusiness`) | `?newCurrency={3-letter ISO}` | `CurrencyChangePreviewDto`: `{ oldCurrency, newCurrency, @DecimalConverter exchangeRate, transactionsCount: int, @DecimalConverter currentNetBalance, @DecimalConverter projectedNetBalance }` |
| `POST /api/v1/currencies/business/change` | JWT + `X-Business-Id` (`OWNER` or `ADMIN` + `EDITABLE` enforced by `requireAdminOrOwnerBusiness` & `BusinessAccessGuard.assertEditable`) | `{ "newCurrency": String, "convertExistingTransactions": false }` | `CurrencyChangeResultDto`: `{ oldCurrency, newCurrency, @DecimalConverter exchangeRate, convertedTransactionsCount: int (always 0), preservedHistoricalTransactionsCount: int, success: boolean, message: String }` |

- **Backend Precision Note:** `CurrencyConversionService.previewCurrencyChange` (`line 54`) computes `projectedNet = currentNet.multiply(rate).setScale(2, RoundingMode.HALF_UP)`. Mobile displays `preview.projectedNetBalance` as returned by the backend (with minor-unit formatting via `MoneyFormatter`) rather than recomputing independently, except when `preview` is null.
- **Audit Side Effect:** `CurrencyConversionService.changeBusinessCurrency` records a `"CURRENCY_CHANGE"` entry in `AuditService` with `historicalMutationBlocked: true` and returns `convertedTransactionsCount: 0`, `preservedHistoricalTransactionsCount: count`.

---

## 8. Form Fields, Validation, and Business Rules

1. **Target Currency (`newCurrency`):**
   - Must match `^[A-Z]{3}$` (`CurrencyConversionService.java:84`).
   - Must differ from `oldCurrency` (`targetCurrency != oldCurrency`).
   - Must be supported by `ExchangeRateService` (`getRate` throws `IllegalArgumentException("Unsupported currency pair")` if absent from `cachedRatesFromUSD`).
2. **Historical Immutability Flag (`convertExistingTransactions`):**
   - Always sent as `false`. Never exposed as an editable toggle in UI (matching `CurrencyMigrationModal.tsx:37`).
3. **Role & Business Access Rules:**
   - Only `OWNER` or `ADMIN` on an `EDITABLE` business can execute `POST /currencies/business/change`.
   - `MEMBER` role receives `403 ForbiddenException`; `READ_ONLY` business receives `403 BUSINESS_READ_ONLY`. Mobile checks `activeBusiness.userRole` and `activeBusiness.editable` upfront and shows a clear read-only/permission notice if unauthorized.

---

## 9. User Interactions and Edge Cases

- **Rapid Target Currency Switching:** Cancel or ignore out-of-order preview responses (monotonic request counter / `CancelToken`) so an earlier slow response never overwrites a newly selected currency's preview.
- **Zero Transactions Business:** `transactionsCount == 0`, `oldBalance == 0`, `projectedBalance == 0` renders cleanly (`"0 transactions"`), and immutability notice remains visible.
- **Negative Net Balance:** `currentNetBalance < 0` formats cleanly in LTR (`-$1,250.00` or `-1,250.000 TND`) without minus-sign inversion in Arabic RTL.
- **Backend `403 BUSINESS_READ_ONLY`:** Intercepted and presented inline + option to open `PlansAndSubscriptionScreen` (`PLAN-01`).

---

## 10. Loading, Empty, Error, and Offline States

- **Preview Loading:** Shows `AfabLoader` inside sheet body while keeping the header and Target Currency picker visible; disables `Confirm` button.
- **Preview Error:** Displays inline red `AfabInsetPanel` alert with a `"Retry"` action button.
- **Submit Loading:** `Confirm` button shows inline `CircularProgressIndicator` (`16dp`) + `"Updating..."`; disables `Cancel`, `Close (X)`, and currency picker to prevent duplicate mutations.
- **Offline State:** Disables `Confirm` and displays offline banner (*"Internet connection required to fetch live FX preview and update business currency"*).

---

## 11. Localization (EN/AR) and RTL Behavior

- **Keys:** Uses `Currencies.migrationModal.*` keys (`title`, `subtitle`, `currentBalance`, `projectedBalance`, `transactionsAffected`, `confirm`, `cancel`) plus newly localized keys for `Target Base Currency`, `Historical Financial Immutability Enforced`, immutability paragraph, `Live Market Rate`, and permission warnings (which are hardcoded English in `CurrencyMigrationModal.tsx:131, 139, 148, 152, 194, 198, 225`!).
- **Do NOT Include:** Obsolete `currencies.json` keys `optionConvert` / `optionKeep` / `optionsTitle`.
- **RTL & BiDi:**
  - Currency codes (`USD`, `TND`), exchange rate equations (`1 USD = 2.9930 TND`), and formatted balances wrap in `Directionality(textDirection: TextDirection.ltr)` inside Arabic prose.
  - Arrows/chevrons between `From` and `To` mirror appropriately (`matchTextDirection: true`) or use centered rate pill layout so layout reads naturally in both LTR and RTL.

---

## 12. Responsive and Tablet Adaptation

- **Phone (`< 600dp`):**
  - Presented via `showModalBottomSheet(isScrollControlled: true)` capped at `88%` viewport height with `SafeArea` bottom clearance and `viewInsets.bottom` padding.
  - `Current Net Balance` and `Projected Balance` cards stack vertically on `< 380dp` (`compactSmall`) and sit side-by-side (`2-col`) on `>= 380dp`.
- **Tablet (`>= 600dp`):**
  - Presented as a centered Material `Dialog` (`maxWidth: 560dp`, `24dp` radius) with `2-col` balance comparison and full horizontal `From → Rate Pill → To` header row.

---

## 13. Acceptance Criteria and Test Scenarios

1. **Target Currency Selection:** Opening sheet when business is `TND` defaults target to `USD`, allows picking `EUR`/`QAR`/`GBP`/etc., and fetches `GET /currencies/business/preview?newCurrency=...` for each selection.
2. **Stale Request Cancellation:** Switching quickly `USD` → `EUR` → `GBP` displays `GBP` preview data even if the `EUR` response arrives late.
3. **Immutability Enforcement:** Submitting sends `{ newCurrency, convertExistingTransactions: false }`; UI displays preserved historical count from `CurrencyChangeResultDTO` and never claims past transactions were converted.
4. **Role & Read-Only Guard:** `MEMBER` user or `READ_ONLY` business sees permission/vault message and cannot submit.
5. **Global Cache Refresh:** After confirming change from `USD` to `TND`, returning to `INT-01` shows `Base: TND`, updated `viewBaseCurrency = TND`, and updated Dashboard/Transactions currency context.

---

## 14. Dependencies and Risks

- **Dependencies:** `CurrenciesRepository`, `activeBusinessProvider`, `viewBaseCurrencyProvider`, `MoneyFormatter`, `ExchangeRateService` (backend), `CurrencyConversionService` (backend).
- **Technical Risks & Mitigations:**
  - *Backend `setScale(2)` on `projectedNetBalance` (`CurrencyConversionService.java:54`):* For 3-decimal target currencies (`TND`, `KWD`, `BHD`, `OMR`), backend rounds `projectedNetBalance` to 2 decimals. **Mitigation:** Display the backend value formatted cleanly, and document this minor backend rounding behavior if exact 3-decimal preview is later desired.
  - *Currency Picker vs `BusinessProfileScreen`:* `PUT /business/{id}` also accepts a `currency` field without audit logging or preview. **Mitigation:** In `BusinessProfileScreen`, route currency changes through `CurrencyMigrationSheet` (`INT-02`) rather than mutating `currency` silently via `PUT /business/{id}`.
