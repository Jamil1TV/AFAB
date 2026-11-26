# `FIN-02` — Transaction Details Screen (`TransactionDetailsScreen`)

> **Domain:** Financial Core (`features/transactions` + `features/receipts`)
> **Priority:** P1 (Unified Detail Inspector for Transactions, Expenses, Revenue, Dashboard & Calendar)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-02` |
| **Screen Name** | `TransactionDetailsScreen` (and embedded `TransactionDetailsPane` on `>= 840dp` tablets) |
| **Route Path (`GoRouter`)** | `/transactions/:transactionId` (also pushed from `/expenses`, `/revenue`, `/dashboard`, `/calendar`) |
| **Feature Module** | `lib/features/transactions/presentation/screens/transaction_details_screen.dart` |
| **Web Source Equivalent** | `Web/project/frontend/components/dashboard/TransactionDetailDrawer.tsx` + inline modals in `expenses/page.tsx:621-687` & `revenue/page.tsx:614-680` |
| **Backend Controllers** | `TransactionController.java` (`GET /api/v1/transactions/{id}`, `DELETE /api/v1/transactions/{id}`), `ReceiptController.java` (`/api/v1/receipts/*`) |
| **Access Level** | Authenticated + Active Business Member (`EDITABLE` required for Duplicate, Edit, Delete, Upload Receipt, Delete Receipt) |

---

## 2. Purpose & User Jobs

1. **Unified Inspection Across Finance Modules:** Provide one complete, consistent detail screen whether opened from Transactions (`FIN-01`), Expenses (`FIN-06`), Revenue (`FIN-07`), Dashboard (`RecentTransactions`), or Financial Calendar — eliminating Web's stripped-down inline modals on Expenses and Revenue.
2. **Audit FX Snapshot Provenance:** Inspect the converted amount in `baseCurrency`, original foreign amount/currency, locked `exchangeRate`, `fxRateSource`, `fxRateTimestamp`, and `legacyFx` status.
3. **Review Anomaly Alerts & Split Breakdowns:** Surface backend-detected `potentialDuplicate` charges (±48h) and `priceHikePercentage` increases (`>= 5%` on expenses), plus multi-category `splitItems[]`.
4. **Manage Private Receipts:** View, upload, preview, share/download, and delete private encrypted receipt files (`PDF`, `JPEG`, `PNG`, `WEBP` up to `10 MB`) via `FIN-08`.

---

## 3. Navigation & Entry/Exit Flows

### Entry Points
- Row tap / `View` action on `TRANSACTIONS_SCREEN.md` (`FIN-01`), `EXPENSES_SCREEN.md` (`FIN-06`), or `REVENUE_SCREEN.md` (`FIN-07`).
- Tap on recent transaction item on `DashboardScreen` or day-panel item on `FinancialCalendarScreen`.
- Deep link `/transactions/:transactionId` (validated against `activeBusinessId`; if 403/404 after business switch, falls back cleanly).

### Exit Points
| Trigger | Destination | Behavior |
|---|---|---|
| Back button / Close | Previous route (`FIN-01` / `FIN-06` / `FIN-07`) | Pops stack on `< 840dp` (clears selection on tablet split pane) |
| Tap `Duplicate` | `FIN-03` (`AddEditTransactionScreen`, `mode: duplicate`) | Opens pre-filled form with today's date (`POST`) |
| Tap `Edit` | `FIN-03` (`AddEditTransactionScreen`, `mode: edit`) | Opens edit form with locked currency (`PUT`); refreshes `FIN-02` on save |
| Tap `Delete` | `DeleteTransactionConfirmDialog` | Calls `DELETE /api/v1/transactions/{id}` → pops `FIN-02` & refreshes list |
| Tap `Attach Receipt` | `FIN-08` (`ReceiptUploadSheet`) | Opens Camera / Gallery / PDF picker → uploads → updates receipts list |
| Tap receipt row / preview | `FIN-08` (`ReceiptViewerScreen`) | Streams authenticated image/PDF preview & share options |
| Tap `Ask Copilot` | `GlobalCopilotSheet` | Preloaded with `transactionId` and summary context |

---

## 4. Layout & Visual Architecture

- **Top App Bar (Phone):** Back arrow (`matchTextDirection: true`), title `Transaction Details`, trailing `Ask Copilot` icon + overflow menu (`Duplicate`, `Edit`, `Delete`).
- **Hero Header Card (`AfabCard`):**
  - Badge row: Type pill (`INCOME` emerald / `EXPENSE` rose), Status badge (`COMPLETED` / `PENDING` / `CANCELLED`), optional `Tax Write-off` teal badge, optional `Split` badge.
  - Hero signed `MoneyText` in `baseCurrency` (`+` emerald or `-` rose/primary, `28sp` bold, `tabularFigures`).
  - Foreign FX line (when `originalCurrency != null && originalCurrency != baseCurrency && exchangeRate != null`): `Globe` icon + `"Original: EUR 500.00 @ 3.350000 EUR/TND"`.
  - Transaction `description` (`16sp` SemiBold, wraps freely).
- **Anomaly Alert Banners (Conditional):**
  - `potentialDuplicate == true`: Amber warning panel (`AlertTriangle`) with title & explanation.
  - `priceHikePercentage != null && priceHikePercentage > 0`: Primary-tinted panel (`TrendingUp`) with `+{pct}%` title & explanation.
- **Metadata Panel (`AfabInsetPanel`):** Key-value rows:
  - `Category` (color dot + name, or `"Uncategorized"`)
  - `Date` (localized via `business.dateFormat`)
  - `Payment Method` (humanized label: `Bank Transfer`, `Card`, `Credit Card`, `Cash`, `Other`)
  - `FX Snapshot` (`legacyFx ? "Legacy (USD)" : "{origCurr} -> {baseCurr} ({fxRateSource})"`, plus optional `fxRateTimestamp`)
  - `Tax / VAT Rate` (shown when `taxDeductible == true && taxRate != null`)
- **Private Receipts Section (`ReceiptSectionWidget`):**
  - Header: `Paperclip` + `Receipts (N)` + `+ Attach Receipt` button (`Upload` / spinner while uploading).
  - States: Loading shimmer/spinner, empty dashed card (`"No receipts attached. Upload PDF, PNG, JPEG, or WEBP (max 10 MB)."`), error banner with Retry, or list of `ReceiptCard` items (`originalFilename`, `contentType • formattedBytes`, Preview/Download icon, Delete icon).
- **Split Allocation Section (Conditional on `isSplit && splitItems.isNotEmpty`):**
  - Header: `Layers` + `Split Allocation`.
  - List of `AfabInsetPanel` rows showing `categoryColor` dot, `categoryName`, optional line `description`, and `MoneyText(item.amount, baseCurr)`.
- **Notes & Context (Conditional on `notes != null && notes.isNotBlank`):**
  - `AfabInsetPanel` preserving whitespace/newlines.
- **Audit Footer:**
  - Full `transaction.id` (monospaced LTR, copyable on long-press) + `createdAt` / `updatedAt` formatted timestamps.
- **Sticky Bottom Action Bar (`SafeArea`):**
  - `Duplicate` (secondary outlined), `Edit` (primary filled), `Delete` (danger icon/outlined button). Hidden/disabled when `activeBusiness.editable == false`.

---

## 5. UI Components & Interactive Controls

| Component | Behavior |
|---|---|
| **`TransactionHeroCard`** | Renders type/status/tax/split pills, signed `MoneyText`, foreign FX sub-line, and description. |
| **`AnomalyBanner` (x2)** | Dismissible? **No** — informational backend flags remain visible for audit clarity. |
| **`ReceiptListCard`** | Tap card or `Eye`/`Download` icon → launches `FIN-08` viewer; tap `Trash2` → confirmation dialog → `DELETE /api/v1/receipts/{id}`. |
| **`AttachReceiptButton`** | Opens `FIN-08` source sheet (`Camera`, `Gallery`, `PDF/File`). Disabled during active upload or `READ_ONLY` business. |
| **`SplitLinesList`** | Read-only allocation breakdown; matches `TransactionDTO.splitItems`. |
| **`DetailActionFooter`** | Sticky footer on phone; inline top/bottom toolbar inside tablet split pane (`FIN-01`). |

---

## 6. Data Requirements & API Contracts

### 6.1 `GET /api/v1/transactions/{id}`
- **Headers:** `Authorization: Bearer <jwt>`, `X-Business-Id: <uuid>`
- **Response (`200 OK` — `TransactionDTO`):**
  - Core: `id (UUID)`, `type (INCOME|EXPENSE)`, `amount (BigDecimal)`, `currency (String)`, `description (String)`, `transactionDate (LocalDate)`, `paymentMethod (String)`, `status (String)`.
  - FX Snapshot: `originalAmount (BigDecimal?)`, `originalCurrency (String?)`, `baseCurrency (String?)`, `exchangeRate (BigDecimal?)`, `convertedAmount (BigDecimal?)`, `fxRateSource (String)`, `fxRateTimestamp (Instant?)`, `legacyFx (bool)`.
  - Category & Tax: `categoryId (UUID?)`, `categoryName (String)`, `categoryColor (String)`, `categoryIcon (String)`, `notes (String?)`, `taxDeductible (bool)`, `taxRate (BigDecimal?)`.
  - Splits & Anomalies: `isSplit (bool)`, `parentTransactionId (UUID?)`, `splitItems (List<SplitItemDTO>)`, `potentialDuplicate (bool)`, `priceHikePercentage (BigDecimal?)`, `createdAt (Instant?)`, `updatedAt (Instant?)`.
- **Errors:** `404 ResourceNotFoundException`, `403 ForbiddenException` (different business).

### 6.2 `GET /api/v1/receipts/transactions/{transactionId}`
- **Response (`200 OK` — `List<ReceiptDTO>`):**
  - Fields: `id (UUID)`, `businessId (UUID)`, `transactionId (UUID)`, `originalFilename (String)`, `contentType (String)`, `fileSizeBytes (long)`, `sha256Checksum (String)`, `createdAt (Instant)`.
- **Note:** Always fetch `GET /transactions/{id}` directly when entering by route/ID (and refresh receipts on entry) rather than relying solely on stale list-item state.

### 6.3 `DELETE /api/v1/transactions/{id}`
- **Response:** `204 No Content`. Soft-deletes parent + split children.

### 6.4 `DELETE /api/v1/receipts/{id}`
- **Response:** `204 No Content`. Removes object from MinIO/S3 and soft-deletes DB metadata.

---

## 7. State Management & Data Flow

```dart
// Family provider keyed by transactionId (autoDispose)
final transactionDetailProvider = FutureProvider.autoDispose.family<TransactionEntity, String>((ref, id) async {
  ref.watch(activeBusinessIdProvider);
  return ref.read(transactionRepositoryProvider).getTransactionById(id);
});

final transactionReceiptsProvider = AsyncNotifierProvider.autoDispose.family<TransactionReceiptsNotifier, List<ReceiptEntity>, String>(...);
```

- **Optimistic/Clean Updates:**
  - When `FIN-03` completes an `edit`, it invalidates `transactionDetailProvider(id)`, `transactionListProvider`, `expenseSummaryProvider`, `revenueSummaryProvider`, and `dashboardSummaryProvider`.
  - When `FIN-08` uploads or deletes a receipt, `transactionReceiptsProvider(id)` updates its list in place (prepend on upload, remove by ID on delete) and shows `AfabToast`.
  - **Initial Argument Optimization:** Route may pass `TransactionEntity? initialPreview` via `GoRouter` `extra` so hero fields render immediately while `GET /transactions/{id}` and `GET /receipts/transactions/{id}` fetch fresh server state in parallel.

---

## 8. Business Logic, Validation & Edge Cases

1. **Duplicate & Price Hike Semantics (Read-Only Display):**
   - `potentialDuplicate`: Backend `TransactionRepository.findPotentialDuplicates` checks active transactions in same business within `transactionDate ± 2 days` having exact `amount` and case-insensitive `description`.
   - `priceHikePercentage`: Backend `TransactionService` checks the most recent prior `EXPENSE` with the same description; populated if increase `>= 5.0%`.
2. **FX Display Rules:**
   - Base currency resolves as `tx.baseCurrency ?? tx.currency ?? activeBusiness.currency`.
   - Show foreign FX sub-line only when `originalCurrency != null && originalCurrency != baseCurr && exchangeRate != null`.
   - Note: `TransactionDTO.exchangeRate` represents `1 originalCurrency = X baseCurrency` (`origAmt * appliedRate = converted`). Display `1 {origCurr} = {exchangeRate} {baseCurr}` clearly alongside `{origCurr}/{baseCurr}`.
3. **Deleted / Cross-Business Transaction:**
   - If `GET /transactions/{id}` returns `404` or `403` (e.g., user switched businesses via AppBar pill while viewing a detail route), show `AfabEmptyState` with `"Transaction unavailable in current workspace"` and a `"Back to Ledger"` button (auto-pop on business switch when pushed).
4. **Child Split Transaction:**
   - If `parentTransactionId != null` (opened directly by ID), display a clickable `"Part of Split Transaction"` banner linking to `/transactions/${tx.parentTransactionId}`.
5. **Read-Only Workspace:**
   - Hide or disable `Edit`, `Duplicate`, `Delete`, `Attach Receipt`, and `Delete Receipt`; allow `Preview` and `Download/Share Receipt`.

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **Inconsistent Expenses & Revenue Modals:** `expenses/page.tsx` and `revenue/page.tsx` render stripped-down inline modals missing FX provenance, anomaly banners, split items, receipts, `Duplicate`, and `Edit`. | `expenses/page.tsx:621-687`, `revenue/page.tsx:614-680` | All 3 modules (`Transactions`, `Expenses`, `Revenue`) route to the unified `FIN-02` `TransactionDetailsScreen`. |
| **Missing `loadingReceipts` Reset on Re-open:** `TransactionDetailDrawer.tsx:59,66-85` never sets `setLoadingReceipts(true)` before fetching `ReceiptApi.listForTransaction(txId)`. | `TransactionDetailDrawer.tsx:59,66-85` | Mobile `AsyncNotifier` automatically enters `AsyncLoading` state per `txId` when fetching receipts. |
| **Stale Transaction Snapshot on Edit:** Web drawer binds only the list row object passed as prop; editing doesn't refresh the drawer if kept open. | `TransactionDetailDrawer.tsx:49` | Mobile `transactionDetailProvider(id)` refetches `GET /transactions/{id}` on edit completion. |
| **No Receipt Inline Preview:** Web only triggers browser blob download without inline image/PDF preview. | `TransactionDetailDrawer.tsx:134-140` | Mobile opens `FIN-08` `ReceiptViewerScreen` with zoomable image / PDF viewer + share sheet. |
| **Window `confirm()` on Expenses/Revenue Delete:** Web uses native browser `confirm()`. | `expenses/page.tsx:663`, `revenue/page.tsx:656` | Mobile uses styled `DeleteTransactionDialog` across all entry points. |

---

## 10. Design Tokens & Visual Styling

- **Card & Inset Styling:** `AfabCard` (`surface`, `1px border`, `baseRadius * 1.33`), `AfabInsetPanel` (`surfaceInset`, `1px border`, `baseRadius`).
- **Semantic Badges:**
  - `INCOME`: `#10B981` (10% tint bg, 20% border, crisp text).
  - `EXPENSE`: `#EF4444` (`danger` 10% tint) in detail header hero badge (matching `TransactionDetailDrawer.tsx:177`), while ledger direction tile uses `AfabColors.primary`.
  - `COMPLETED` / `PENDING` / `CANCELLED`: `success` / `warning` / `danger` via `AfabStatusBadge`.
  - `Tax Write-off`: Teal `#0D9488` (`#2DD4BF` dark).
- **FX Provenance Highlight:** `AfabColors.primary` text with `Globe` icon (`14dp`).
- **Delete CTA:** `AfabColors.danger` border & foreground (`48dp` min touch target).

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** `transactions.json` → `drawer.*` (`33` keys, 100% EN/AR parity) + new keys for `Payment Method` enum display (`CREDIT_CARD` → `"Credit Card"` / `"بطاقة ائتمان"`) and `"Part of split transaction"`.
- **BiDi Rules:**
  - Wrap hero `MoneyText`, foreign FX rate equation (`1 EUR = 3.350000 TND`), split line amounts, and `transaction.id` UUID in `Directionality(textDirection: TextDirection.ltr)`.
  - `txDrawerPriceIncrease` uses ICU placeholder `{pct}`.
  - Receipt filenames (`originalFilename`) wrap safely with `TextOverflow.ellipsis` and `maxLines: 1`.

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` (`< 360dp`) | Single-column scrollable body; compact `20sp–24sp` scaled hero `MoneyText` via `FittedBox`; sticky footer buttons stack icons/labels cleanly (`Expanded`). |
| `compact` (`360–599dp`) | Full-screen pushed route; `SafeArea` sticky bottom bar (`Duplicate`, `Edit`, `Delete`). |
| `medium` (`600–839dp`) | Centered constrained column (`maxWidth: 640dp`) or slide-over side sheet (`440dp`). |
| `expanded` (`>= 840dp`) | Embedded inline in right `42%` pane of `TransactionsScreen` (`FIN-01`), or pushed/side-drawer (`440dp`) from `Expenses`/`Revenue`. |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** Long-press UUID copies to clipboard with `"Copied"` toast; all icon-only buttons (`Preview`, `Download`, `Delete Receipt`) have explicit `Semantics` / `tooltip` labels; `48dp` minimum hit targets.
- **Security:** Receipts are **never** fetched via unauthenticated public URLs in-app; `FIN-08` streams bytes with `Authorization: Bearer` + `X-Business-Id` and obeys `Cache-Control: private, no-store`.
- **Performance:** `GET /transactions/{id}` and `GET /receipts/transactions/{id}` execute concurrently (`Future.wait`).

---

## 14. Dependencies and Risks

- **Dependencies:** `FIN-03` (`ADD_EDIT_TRANSACTION_SCREEN.md`), `FIN-08` (`RECEIPT_VIEWER_AND_UPLOAD_FLOW.md`), `GlobalCopilotSheet`, `MoneyFormatter`, `DateFormatter`.
- **Risks & Mitigations:**
  1. **Large Split Lists:** A split transaction could have 20+ lines. *Mitigation:* Render inside the parent `CustomScrollView` / `ListView` without nested fixed-height scroll conflicts.
  2. **Legacy Transactions Without FX Fields:** Older rows have `legacyFx == true` and `exchangeRate == null`. *Mitigation:* Gracefully hide foreign-rate equation and display `Legacy ({baseCurrency})` provenance badge matching backend `TransactionService.java:544-546`.
