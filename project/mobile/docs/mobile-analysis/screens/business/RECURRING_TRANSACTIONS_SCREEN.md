# RECURRING_TRANSACTIONS_SCREEN (`BIZ-08`)

> **Domain:** Business Operations (`recurring`)
> **Task Reference:** `P3-07`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/recurring/page.tsx`, `Web/project/frontend/lib/api/recurring.ts`
> **Backend Source:** `RecurringTransactionController.java`, `RecurringTransactionService.java`, `RecurringTransactionDTO.java`, `RecurringTransactionRequest.java`

---

## 1. Screen Identity

- **Screen ID:** `BIZ-08`
- **Screen Name:** `RecurringTransactionsScreen`
- **Flutter File Path:** `lib/features/recurring/presentation/recurring_transactions_screen.dart`
- **Supporting Sheets / Modals:** `CreateEditRecurringSheet` (`lib/features/recurring/presentation/widgets/create_edit_recurring_sheet.dart`)
- **Route Path (`GoRouter`):** `/recurring`
- **Navigation Placement:**
  - **Phone (`< 600dp`):** Accessed from `MoreHubScreen` (Tab 4 → *Money & Operations* → *Recurring*) or cross-linked from `ExpensesScreen` (where Web's `recurringList` is stubbed empty).
  - **Tablet (`>= 600dp`):** Direct primary destination in `NavigationRail` (*Recurring*).

---

## 2. Purpose and Functional Scope

Manages automated recurring `INCOME` and `EXPENSE` rules (`WEEKLY`, `MONTHLY`, `QUARTERLY`, `YEARLY`) with idempotent occurrence execution: viewing schedules, creating and editing rules, pausing/resuming (`PATCH /status`), manually triggering due occurrences (`POST /run-due`) with `generatedCount` feedback, and deleting/deactivating rules.

### Confirmed Web UX Gaps Fixed on Mobile
1. **Explicit Deactivate-vs-Hard-Delete Confirmation Dialog:** On Web, clicking the delete trash icon calls `RecurringTransactionApi.delete(rule.id)` immediately with zero confirmation, and the toast always claims `"Recurring schedule removed"` even though `RecurringTransactionService.delete()` (`RecurringTransactionService.java:220-231`) **deactivates (`active = false`) instead of deleting** whenever executions exist (to preserve ledger lineage)! Mobile presents an explicit confirmation dialog explaining this exact dual behavior, and refreshes the list accurately.
2. **Touch Cards on Phones (`< 600dp`):** Web renders a `min-w-[680px]` horizontal-scroll table. Mobile renders structured `AfabCard` schedule cards on `< 600dp` (zero horizontal table scrolling) and a clean `DataTable` on `>= 840dp` tablets.
3. **Clear `Run Due Now` Feedback & Multi-Cache Refresh:** Web only calls `loadData()` for recurring rules after `runDue`. When `result.generatedCount > 0`, mobile also invalidates `transactionsProvider`, `expensesProvider`, `revenueProvider`, `budgetsProvider`, `calendarProvider`, and `dashboardSummaryProvider` so newly generated transactions appear immediately across the app.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - `MoreHubScreen` → *Money & Operations* → *Recurring*
  - Tablet `NavigationRail` → *Recurring*
  - `ExpensesScreen` → *Manage Recurring Expenses* banner/link
- **Exit / Forward Flows:**
  - Tap `+ New Schedule` → opens `CreateEditRecurringSheet` (Create mode).
  - Tap `Edit` (`Pencil`) or tap card → opens `CreateEditRecurringSheet` (Edit mode).
  - Tap `Run Due Now` (`RefreshCw`) → triggers `POST /run-due` inline with per-rule loading spinner.
  - Tap `Pause` / `Resume` (`Pause` / `Play`) → triggers `PATCH /status`.
  - Tap `Delete` (`Trash2`) → opens explicit deactivate-vs-delete confirmation dialog → `DELETE /{id}`.
  - Optional post-`runDue` toast action `"View Transactions"` → navigates to `TransactionsScreen` when `generatedCount > 0`.

---

## 4. Layout and Responsive Behavior

| Breakpoint | Layout Structure | Schedule Presentation | Modal Form Presentation |
|---|---|---|---|
| `compactSmall` (`< 360dp`) | Single-column `ListView` + FAB | Stacked `AfabCard` rules with 2-row action bar | Full-screen `AfabBottomSheet` (`isScrollControlled: true`) |
| `compact` (`360–599dp`) | Single-column `ListView` + FAB | `AfabCard` rules | `AfabBottomSheet` (`maxHeight: 92%`) |
| `medium` (`600–839dp`) | `NavigationRail` (`72dp`) + 2-col card grid or compact table | 2-col `AfabCard` grid | Centered `Dialog` (`maxWidth: 540dp`) |
| `expanded` (`>= 840dp`) | `NavigationRail` (`248dp` at `>= 1024dp`) | Full 7-col `DataTable` (`Description`, `Type`, `Amount`, `Frequency`, `Next Run`, `Status`, `Actions`) | Centered `Dialog` (`maxWidth: 560dp`) |

---

## 5. UI Components and Visual Hierarchy

1. **Header & Primary CTA:**
   - Title, subtitle, `+ New Schedule` CTA (FAB on `< 600dp`, header button on `>= 600dp`).
   - Optional quick status filter (`All`, `Active`, `Paused`) computed cleanly client-side over `rules[]`.
2. **Recurring Schedule Card (`AfabCard` on `< 840dp`):**
   - **Top Row:**
     - `rule.description` (bold) + `Type` badge (`INCOME` emerald / `EXPENSE` red) + `Status` badge (`Active` emerald / `Paused` neutral).
   - **Subtitle:** `${rule.categoryName ?? "Uncategorized"} • ${localizedPaymentMethod}`
   - **Metrics Inset (`AfabInsetPanel`):**
     - Left: `MoneyText(rule.amount, rule.currency)` + `tFreq(rule.frequency)` pill (`Weekly` / `Monthly` / `Quarterly` / `Yearly`).
     - Right: `Next Run` (`Calendar` icon + localized `rule.nextExecutionDate`, plus optional `Last Run` if `rule.lastExecutedAt != null` and `End Date` if `rule.endDate != null`).
   - **Action Strip (4 `48x48dp` actions):**
     - **`Run Due`** (`RefreshCw`, rotating animation while `runningRuleId == rule.id`; disabled if `!rule.active` or busy).
     - **`Pause` / `Resume`** (`Pause` / `Play`, amber tint).
     - **`Edit`** (`Pencil`, primary tint).
     - **`Delete`** (`Trash2`, danger tint).
3. **Create / Edit Schedule Sheet (`CreateEditRecurringSheet`):**
   - **Type * & Frequency * (2-col row):**
     - `Type`: `EXPENSE` / `INCOME` (switching `type` clears `categoryId` so mismatched category types are impossible).
     - `Frequency`: `WEEKLY`, `MONTHLY`, `QUARTERLY`, `YEARLY`.
   - **Description *:** `AfabTextField` (`maxLength: 255`, placeholder `"e.g. Office Rent, Cloud Infrastructure"`).
   - **Amount * & Currency:**
     - `Amount`: `Decimal` numeric input (`>= 0.0001`).
     - `Currency`: Picker defaulting to `activeBusiness.currency` (includes `USD, EUR, GBP, TND, CAD, MAD, AED, SAR` + active business currency).
   - **Category & Payment Method:**
     - `Category`: `GET /categories` filtered dynamically by `form.type` (`INCOME` or `EXPENSE`), plus `"Uncategorized"` (`null`).
     - `Payment Method`: `BANK_TRANSFER`, `CARD`, `CREDIT_CARD`, `CASH`, `OTHER`.
   - **Start Date * & End Date (optional):**
     - Native date pickers (`startDate` defaults to today; validates `endDate >= startDate` when `endDate` is set).
   - **Notes:** Optional multiline (`maxLength: 1000`).

---

## 6. Interactive States and User Flows

- **Loading:** `AfabLoader` (`"Loading recurring schedules..."`) on initial fetch; pull-to-refresh supported.
- **Empty:** `AfabEmptyState` with `Repeat` icon + `"Create First Schedule"` CTA.
- **Error:** Retryable danger banner (`loadError` + `Retry`).
- **Pause / Resume Flow:**
  1. User taps `Pause` or `Resume` → `PATCH /api/v1/recurring-transactions/{id}/status` with `{ "active": !rule.active }`.
  2. Note backend edge case (`RecurringTransactionService.java:201-204`): Resuming a rule whose `nextExecutionDate > endDate` throws `400 IllegalArgumentException` (`"Cannot activate a recurring rule whose next execution date is past its end date"`). Surface this server message clearly via `AfabToast.error` and prompt user to edit `endDate`.
- **Run Due Now Flow:**
  1. User taps `Run Due` on an active rule → `POST /api/v1/recurring-transactions/{id}/run-due`.
  2. Backend executes up to `24` due catch-up occurrences idempotently based on the business timezone (`resolveBusinessZone(business)`).
  3. Response `RunResult { rule, generatedCount, transactionIds }`:
     - If `generatedCount > 0`: show `AfabToast.success(l10n.recurringGenerated(generatedCount))` with `"View"` action → `/transactions`, and invalidate transaction/budget/dashboard/calendar caches.
     - If `generatedCount == 0`: show `AfabToast.info(l10n.recurringNoneDue)`.
- **Delete / Deactivate Confirmation Flow:**
  1. Tapping `Delete` opens `AlertDialog`:
     - Title: `"Delete or Deactivate Schedule?"`
     - Body: `"If \"${rule.description}\" has already generated transactions, it will be deactivated (paused) to preserve your financial ledger history. If it has never run, it will be permanently deleted."`
  2. Confirm → `DELETE /api/v1/recurring-transactions/{id}` (`204`) → refresh list → show `AfabToast.success`.
     - Tip: Check `rule.lastExecutedAt != null` beforehand to tailor the success toast (`"Schedule deactivated to preserve history"` vs `"Schedule permanently deleted"`).

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Request Body / Params | Response DTO | Notes |
|---|---|---|---|---|
| List Rules | `GET /api/v1/recurring-transactions` | — | `200 List<RecurringTransactionDTO>` | Sorted/scoped to active business. |
| Get Rule | `GET /api/v1/recurring-transactions/{id}` | — | `200 RecurringTransactionDTO` | Optional detail refresh. |
| Create Rule | `POST /api/v1/recurring-transactions` | `RecurringTransactionRequest` | `201 RecurringTransactionDTO` | Sets `nextExecutionDate = startDate`. |
| Update Rule | `PUT /api/v1/recurring-transactions/{id}` | `RecurringTransactionRequest` | `200 RecurringTransactionDTO` | Auto-deactivates if `nextExecutionDate > endDate`. |
| Pause / Resume | `PATCH /api/v1/recurring-transactions/{id}/status` | `{ "active": boolean }` | `200 RecurringTransactionDTO` | Rejects `active=true` if `nextExecutionDate > endDate`. |
| Run Due Now | `POST /api/v1/recurring-transactions/{id}/run-due` | — | `200 RunResult { rule, generatedCount, transactionIds }` | Idempotent via `(ruleId, scheduledDate)` DB execution constraint; max 24 catch-up occurrences/run. |
| Delete / Deactivate | `DELETE /api/v1/recurring-transactions/{id}` | — | `204 No Content` | Deactivates if executions exist; hard-deletes otherwise. |

---

## 8. State Management and Caching

- **`recurringListProvider` (`FutureProvider.autoDispose`):** Watches `activeBusinessIdProvider`, calls `GET /recurring-transactions`.
- **`recurringActionControllerProvider` (`AsyncNotifier`):** Tracks `runningRuleId` and `togglingRuleId` to prevent concurrent double-taps on `Run Due` or `Pause/Resume`.
- **Cross-Module Invalidation:** When `runDue` returns `generatedCount > 0`, invalidate `transactionsProvider`, `expensesProvider`, `revenueProvider`, `budgetsProvider`, `calendarProvider`, and `dashboardSummaryProvider`.

---

## 9. Validation, Error Handling, and Edge Cases

- **Jakarta Validation Parity (`RecurringTransactionRequest.java`):**
  - `type`: `INCOME | EXPENSE` (`@NotBlank`).
  - `description`: `@NotBlank`, `<= 255` chars.
  - `amount`: `@NotNull`, `@DecimalMin("0.0001")`.
  - `currency`: 3-letter ISO code (`^[A-Za-z]{3}$`).
  - `paymentMethod`: `BANK_TRANSFER | CARD | CREDIT_CARD | CASH | OTHER`.
  - `frequency`: `WEEKLY | MONTHLY | QUARTERLY | YEARLY` (`@NotBlank`).
  - `startDate`: `@NotNull`; `endDate` (optional) must be `>= startDate`.
  - `notes`: `<= 1000` chars.
- **Category Type Mismatch Guard:** Switching `type` clears `categoryId` immediately so client never sends an `EXPENSE` category for an `INCOME` rule (`400` on backend).
- **Empty Execution History API Caveat:** Backend stores `RecurringTransactionExecution` records internally but exposes **no endpoint** to list past execution logs per rule; mobile surfaces `lastExecutedAt` and `nextExecutionDate` from `RecurringTransactionDTO`.

---

## 10. Localization and RTL Support

- Migrate all `64` keys from `Web/project/frontend/messages/{en,ar}/recurring.json` into `app_en.arb` and `app_ar.arb`, plus add keys for the deactivate-vs-delete confirmation dialog and `"Last run"` label.
- Wrap `MoneyText`, `currency`, and ISO dates in `Directionality(textDirection: TextDirection.ltr)` with Western digits (`0–9`).

---

## 11. Accessibility and Touch Ergonomics

- Minimum `48x48dp` targets on `Run Due`, `Pause/Resume`, `Edit`, `Delete`, and form fields.
- Explicit `Semantics` labels including rule description (e.g., `"Run due occurrences for Office Rent"`, `"Pause Office Rent"`).
- `SafeArea` + `AnimatedPadding(viewInsets.bottom)` inside `CreateEditRecurringSheet`.

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- Tenant-isolated via `X-Business-Id`; `BusinessAccessGuard.assertEditable` enforced on all mutations (`POST`/`PUT`/`PATCH`/`DELETE`).
- `READ_ONLY` workspaces disable `+ New Schedule`, `Run Due`, `Pause/Resume`, `Edit`, and `Delete`.
- No plan quota limit on recurring schedules.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:** `RecurringTransactionDTO` & `RunResult` deserialization (`Decimal` amount), date validation (`endDate < startDate`), clearing `categoryId` when `type` switches.
2. **Widget Tests:**
   - Verify `Run Due` button is disabled when `rule.active == false` and shows spinner while running.
   - Verify `generatedCount > 0` toast displays exact count vs `0` showing `"none due"`.
   - Verify Delete action opens explicit dialog explaining deactivate-if-executed vs hard delete.
   - Verify Light/Dark and EN/AR (`320dp` & `1024dp`) zero overflow.
3. **Integration Test:** Create `MONTHLY` `EXPENSE` rule with past `startDate` → `Run Due Now` → verify `generatedCount >= 1` and transaction appears in `TransactionsScreen` → Pause → Delete (deactivates rather than deleting because execution exists).

---

## 14. Dependencies and Risks

- **Dependencies:** `flutter_riverpod`, `decimal`, `intl`, `categoriesProvider`.
- **Risks:**
  - **Timezone Alignment:** `runDue` evaluates due dates against `business.timezone` on the backend (`RecurringTransactionService.currentDateForBusiness`), which may differ by 1 day from the phone's local timezone around midnight UTC. Display `nextExecutionDate` verbatim as returned by the backend without local timezone shifting.
