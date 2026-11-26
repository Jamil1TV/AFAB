# BUDGETS_SCREEN (`BIZ-07`)

> **Domain:** Business Operations (`budgets`)
> **Task Reference:** `P3-07`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/budgets/page.tsx`, `Web/project/frontend/lib/api/budgets.ts`
> **Backend Source:** `BudgetController.java`, `BudgetService.java`, `BudgetDTO.java`, `BudgetSummaryDTO.java`, `BudgetRequest.java`

---

## 1. Screen Identity

- **Screen ID:** `BIZ-07`
- **Screen Name:** `BudgetsScreen`
- **Flutter File Path:** `lib/features/budgets/presentation/budgets_screen.dart`
- **Supporting Sheets / Modals:** `CreateEditBudgetSheet` (`lib/features/budgets/presentation/widgets/create_edit_budget_sheet.dart`)
- **Route Path (`GoRouter`):** `/budgets`
- **Navigation Placement:**
  - **Phone (`< 600dp`):** Accessed from `MoreHubScreen` (Tab 4 → *Money & Operations* → *Budgets*) or from `DashboardScreen` *BudgetOverviewCard*.
  - **Tablet (`>= 600dp`):** Direct primary destination in `NavigationRail` (*Budgets*).

---

## 2. Purpose and Functional Scope

Manages overall and category-scoped business expense budgets (`MONTHLY`, `QUARTERLY`, `YEARLY`, `CUSTOM`), tracks real-time actual spending computed server-side from `COMPLETED` `EXPENSE` transactions, surfaces deterministic rule-based threshold alerts (`OK`, `APPROACHING`, `OVER_BUDGET`), integrates with AI Copilot for budget spend diagnostics, and supports creating, editing, viewing archived budgets, and archiving budgets.

### Confirmed Web Gaps & Edge Cases Fixed on Mobile
1. **Confirmation Dialog Before Archive:** On Web, tapping the trash icon calls `BudgetApi.archive(b.id)` immediately with zero confirmation! Mobile presents a clear confirmation dialog before calling `DELETE /api/v1/budgets/{id}`.
2. **Expose Active / Archived Filter Toggle:** `BudgetController.list(@RequestParam(defaultValue="false") boolean includeArchived)` already supports showing archived budgets, which Web hardcodes to `false`. Mobile adds an `Active` / `All (incl. Archived)` segmented filter chip bar.
3. **Smart Date Window Handling on Edit (`BudgetService.java:185-189`):** On Web, `openEditModal` pre-populates `form.startDate` and `form.endDate` with the existing budget's dates; if the user changes `periodType` (e.g., `MONTHLY` → `QUARTERLY`), `BudgetService.update` sees non-null `startDate`/`endDate` and preserves the old 1-month window instead of recalculating the new quarter! On mobile, switching `periodType` in `CreateEditBudgetSheet` (unless `CUSTOM`) resets `startDate`/`endDate` to blank (*auto-calculate for period*) unless the user explicitly enters custom dates.
4. **Summary Double-Count Awareness:** If a business has both an *"All Business Expenses"* budget and category-specific budgets, `BudgetSummaryDTO` sums all active budgets' `budgetAmount` and `actualSpending`. Mobile displays an optional info tooltip explaining this aggregation.

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - `MoreHubScreen` → *Money & Operations* → *Budgets*
  - Tablet `NavigationRail` → *Budgets*
  - `DashboardScreen` → *BudgetOverviewCard* / `ReminderCard` budget alert
- **Exit / Forward Flows:**
  - Tap `+ New Budget` → opens `CreateEditBudgetSheet` (Create mode).
  - Tap Edit (`Pencil`) on a budget card → opens `CreateEditBudgetSheet` (Edit mode).
  - Tap Ask Copilot (`Sparkles`) on a budget card → opens `GlobalCopilotSheet` pre-seeded with budget analysis prompt.
  - Tap Archive (`Trash2`) → confirmation dialog → `DELETE /api/v1/budgets/{id}`.

---

## 4. Layout and Responsive Behavior

| Breakpoint | Layout Structure | Summary Cards Grid | Budget Cards Grid |
|---|---|---|---|
| `compactSmall` (`< 360dp`) | Single-column `CustomScrollView` + FAB | 1-col or 2x2 compact wrap | 1-column list |
| `compact` (`360–599dp`) | 2x2 Summary grid + segmented Active/Archived toggle + FAB | 2 columns × 2 rows | 1-column list |
| `medium` (`600–839dp`) | `NavigationRail` (`72dp`) + 2x2 Summary grid | 2 columns × 2 rows | 2-column grid |
| `expanded` (`>= 840dp`) | `NavigationRail` (`248dp` at `>= 1024dp`) | 4 columns × 1 row | 2-column grid (`3`-col at `>= 1280dp`) |

---

## 5. UI Components and Visual Hierarchy

1. **Header & Filter Strip:**
   - Title, subtitle, `+ New Budget` CTA button (FAB on `< 600dp`).
   - **Active / Archived Filter (`AfabSegmentedBar`):** `Active Only` (`includeArchived=false`, default) vs `Include Archived` (`includeArchived=true`).
2. **4 Summary Cards (`AfabStatCard`):**
   - **Active Budgets:** `summary.activeBudgetCount` + hint `"Total Limit: ${MoneyText(summary.totalBudgeted, currency)}"`.
   - **Actual Spending:** `MoneyText(summary.totalSpent, currency)` + hint `"Remaining: ${MoneyText(summary.totalRemaining, currency)}"`.
   - **Approaching Limit:** `summary.approachingCount` (Amber `#F59E0B` / `#FBBF24`) + hint `"At or above alert threshold"`.
   - **Over Budget:** `summary.overBudgetCount` (Danger `#EF4444`) + hint `"Exceeds allocated limit"`.
3. **Budget Progress Cards (`AfabCard`):**
   - **Header:**
     - `b.name` (bold) + Alert Level `AfabStatusBadge`:
       - `OVER_BUDGET` → Danger (`XCircle` + *"Over Budget"*)
       - `APPROACHING` → Warning (`AlertTriangle` + *"Approaching"*)
       - `OK` → Success (`CheckCircle2` + *"On Track"*)
       - Plus `"Archived"` neutral pill when `b.status == "ARCHIVED"`.
     - Subtitle: `${categoryName or "All Business Expenses"} • ${periodLabel} (${startDate} → ${endDate})` with optional category color dot (`b.categoryColor`).
     - Action icons (`48x48dp` hit targets): `Sparkles` (Ask Copilot), `Pencil` (Edit — hidden when `ARCHIVED`), `Trash2` (Archive — hidden when `ARCHIVED`).
   - **Progress Bar:**
     - Row: `${MoneyText(b.actualSpending, b.currency)} of ${MoneyText(b.budgetAmount, b.currency)}` | `${b.percentageConsumed.toStringAsFixed(1)}%` (colored by `alertLevel`).
     - Rounded `LinearProgressIndicator` (`10dp` height, clamped `0..100%`, Emerald/Amber/Red fill).
   - **Bottom Row:**
     - Left: If `b.overBudgetAmount > 0` → `"Over by ${MoneyText(b.overBudgetAmount, b.currency)}"` (Danger); else → `"Remaining: ${MoneyText(b.remainingAmount, b.currency)}"`.
     - Right: `"Alert at ${b.alertThresholdPercent}%"`.
4. **Create / Edit Modal (`CreateEditBudgetSheet`):**
   - `AfabBottomSheet` on phone (`isScrollControlled: true`) / centered `Dialog` (`maxWidth: 520dp`) on tablet.
   - Fields:
     - **Budget Name *:** `AfabTextField` (`maxLength: 150`, e.g., `"Monthly Marketing Budget"`).
     - **Limit (`businessCurrency`) *:** `Decimal` input (`>= 0.0001`). Displays note that budget currency always matches business base currency (`BudgetService.java:142`).
     - **Alert Threshold (%) *:** Integer `1..100` (default `80`).
     - **Expense Category:** `AfabSelectField` populated with `GET /api/v1/categories` filtered strictly to `type == "EXPENSE"`, plus `"All Business Expenses"` (`null`).
     - **Period *:** `MONTHLY`, `QUARTERLY`, `YEARLY`, `CUSTOM`.
     - **Start Date & End Date:** Required when `periodType == "CUSTOM"`; optional overrides when `MONTHLY`/`QUARTERLY`/`YEARLY` (helper text: *"Leave blank to auto-calculate current period"*). Changing `periodType` away from `CUSTOM` clears auto-populated dates unless user edits them.
     - **Description:** Optional multiline (`maxLength: 1000`).

---

## 6. Interactive States and User Flows

- **Loading:** Initial load shows `AfabLoader` (`"Calculating real-time budget consumption..."`) / skeleton cards.
- **Empty:** `AfabEmptyState` with `PiggyBank` icon + `"Create First Budget"` CTA.
- **Error:** Retryable danger banner (`loadError` + `Retry` button).
- **Ask Copilot Flow:** Tapping `Sparkles` opens `GlobalCopilotSheet` with:
  - `prompt`: `"Analyze my budget \"${b.name}\" (${b.percentageConsumed.toStringAsFixed(1)}% consumed: ${b.actualSpending} / ${b.budgetAmount} ${b.currency}, ${b.startDate} to ${b.endDate}) and list the transactions driving it."`
  - `autoSend: true`
  - `screenContext`: `{ "page": "budgets", "budgetId": b.id, "budgetName": b.name }`
- **Archive Flow:** Tapping `Trash2` opens `AlertDialog` (`"Archive Budget?"`, `"Archive \"${b.name}\"? Archived budgets stop tracking active alerts while preserving historical records."`) → `DELETE /api/v1/budgets/{id}` → toast + refresh.

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Query / Body | Response DTO | Notes |
|---|---|---|---|---|
| List Budgets | `GET /api/v1/budgets` | `?includeArchived=false\|true` | `200 List<BudgetDTO>` | Real-time spending evaluated per request from `COMPLETED` `EXPENSE` transactions. |
| Summary | `GET /api/v1/budgets/summary` | — | `200 BudgetSummaryDTO` | Evaluates current-date active budgets (`currency`, counts, totals, `budgets[]`). |
| Get Budget | `GET /api/v1/budgets/{id}` | — | `200 BudgetDTO` | Available for deep-link / single refresh. |
| Create Budget | `POST /api/v1/budgets` | `BudgetRequest` (`name*`, `amount*`, `currency?`, `categoryId?`, `periodType`, `startDate?`, `endDate?`, `alertThresholdPercent`, `description?`) | `201 BudgetDTO` | Rejects non-`EXPENSE` category (`400`) or currency mismatch (`400`). |
| Update Budget | `PUT /api/v1/budgets/{id}` | `BudgetRequest` | `200 BudgetDTO` | Cannot diverge from business base currency (`400`). |
| Archive Budget | `DELETE /api/v1/budgets/{id}` | — | `204 No Content` | Sets `status = "ARCHIVED"`, `archivedAt = now`. |
| Expense Categories | `GET /api/v1/categories` | — | `200 List<CategoryDTO>` | Client filters `type == "EXPENSE"`. |

---

## 8. State Management and Caching

- **`includeArchivedBudgetsProvider` (`StateProvider<bool>`):** Defaults to `false`.
- **`budgetSummaryProvider` (`FutureProvider.autoDispose`):** Watches `activeBusinessIdProvider` + `GET /budgets/summary`.
- **`budgetListProvider` (`FutureProvider.autoDispose`):** Watches `activeBusinessIdProvider` + `includeArchivedBudgetsProvider` + `GET /budgets?includeArchived=...`.
- **`expenseCategoriesProvider` (`FutureProvider.autoDispose`):** Filters `categoriesProvider` to `EXPENSE`.
- **Invalidation:** Any budget CRUD, transaction mutation, split, category deletion, or AI `approve-budget` / `approve-transaction` invalidates `budgetSummaryProvider`, `budgetListProvider`, and `dashboardSummaryProvider`.

---

## 9. Validation, Error Handling, and Edge Cases

- **Validation Parity (`BudgetRequest.java` & `BudgetService.java`):**
  - `name`: `@NotBlank`, `<= 150` chars.
  - `amount`: `@NotNull`, `>= 0.0001`.
  - `alertThresholdPercent`: integer `1..100` (default `80`).
  - `periodType`: `MONTHLY | QUARTERLY | YEARLY | CUSTOM`.
  - `CUSTOM` dates: Both `startDate` and `endDate` required, and `endDate >= startDate`.
  - Non-`CUSTOM` custom dates: If both `startDate` and `endDate` are provided, validate `endDate >= startDate`.
  - `description`: `<= 1000` chars.
- **Currency Lock:** Never send a mismatched `currency`; omit or pass `activeBusiness.currency` so backend currency check always succeeds cleanly.
- **Archived Budgets Read-Only:** When viewing `includeArchived = true`, budgets with `status == "ARCHIVED"` hide Edit & Archive buttons.

---

## 10. Localization and RTL Support

- Migrate all `59` keys from `Web/project/frontend/messages/{en,ar}/budgets.json` into `app_en.arb` and `app_ar.arb`, plus add missing keys for `Active Only`, `Include Archived`, `Archive Confirmation`, `Ask Copilot`, and `Auto-calculated if blank`.
- Progress bar direction respects `Directionality.of(context)` (fills start→end).
- Wrap `MoneyText` values, percentages (`80.0%`), and ISO date ranges in LTR spans with Western digits (`0–9`).

---

## 11. Accessibility and Touch Ergonomics

- Minimum `48x48dp` targets on `Sparkles`, `Pencil`, `Trash2`, filter toggle, and modal pickers.
- `Semantics` on progress bar: `"${b.name}: ${b.percentageConsumed.toStringAsFixed(1)} percent consumed, ${b.alertLevel}"`.
- Sheet form wraps inputs in `SafeArea` + `AnimatedPadding(viewInsets.bottom)`.

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- All endpoints scoped by `X-Business-Id`; backend validates budget and category belong to the active business (`403` otherwise).
- `READ_ONLY` workspaces disable `+ New Budget`, `Edit`, and `Archive` (`BusinessAccessGuard.assertEditable`).
- No plan quota restriction on number of budgets.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:** `BudgetDTO` & `BudgetSummaryDTO` parsing (`Decimal` `actualSpending`, `remainingAmount`, `overBudgetAmount`), date validation (`endDate < startDate`, `CUSTOM` required dates), `CreateEditBudgetSheet` period-change date reset logic.
2. **Widget Tests:**
   - Verify 4 summary cards and progress bars render correctly for `OK`, `APPROACHING`, and `OVER_BUDGET` states.
   - Verify tapping Archive opens confirmation dialog (and Cancel aborts `DELETE`).
   - Verify Active/Archived toggle refetches `GET /budgets?includeArchived=true`.
   - Verify `CUSTOM` period marks Start Date & End Date required.
3. **Integration Test:** Create `CUSTOM` budget → record `EXPENSE` transaction within range → verify `actualSpending` & `percentageConsumed` update → trigger Ask Copilot → archive budget with confirmation.

---

## 14. Dependencies and Risks

- **Dependencies:** `flutter_riverpod`, `decimal`, `intl`, `GlobalCopilotSheet`, `categoriesProvider`.
- **Risks:**
  - **Budget Currency Mismatch After Business Currency Change:** Historical budgets created prior to a base-currency migration remain in their stored currency; `BudgetService.update` rejects currency divergence. Mobile keeps budget's existing `b.currency` display and never sends a conflicting `currency` on `PUT`.
