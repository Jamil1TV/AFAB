# DASH-03 — Business Switcher Sheet (`BusinessSwitcherSheet`)

> **Spec ID:** `DASH-03`
> **Phase / Task:** Phase 2 (`P2-02`)
> **Verified Web Sources:** `Web/project/frontend/components/dashboard/BusinessSwitcher.tsx`, `lib/api/business.ts`, `lib/api/subscription.ts`
> **Verified Backend Sources:** `BusinessController.java`, `BusinessAllocationService.java`, `CurrentBusinessService.java`, `BusinessAccessGuard.java`, `GlobalExceptionHandler.java`

---

## 1. Screen Identity

- **Screen Name:** `BusinessSwitcherSheet` (+ nested `CreateBusinessSheet`, `LockedBusinessDialog`, `PlanLimitDialog`)
- **Route / Presentation:** Modal `AfabBottomSheet` on phones (`< 600dp`), anchored `Dialog` / popover (`maxWidth: 440dp`) on tablets (`>= 600dp`), also accessible via `/more` → `"Switch or Create Business"`
- **Feature Module:** `lib/features/business/presentation/widgets/business_switcher_sheet.dart`
- **Backend Scope:** Multi-tenant workspace listing, switching, creation, and `READ_ONLY` enforcement

---

## 2. Purpose and Functional Parity

Allows users to inspect all businesses they belong to (`OWNER`, `ADMIN`, or `MEMBER`), view each workspace's currency, role, and access state (`Active`/`EDITABLE` vs `Locked`/`READ_ONLY`), switch the active workspace (`X-Business-Id`), create a new independent business workspace within plan limits, or navigate directly to Business Settings / Plans & Upgrades.

---

## 3. Navigation and Entry/Exit Paths

- **Entry Paths:**
  - Tapping the `BusinessSwitcherPill` in `ShellAppBar` (phones) or `NavigationRail` header (tablets).
  - Tapping `"Switch or Create Business"` in `MoreHubScreen` (`DASH-02`).
- **Exit Paths:**
  - **Tap an `EDITABLE` business:** Calls `PUT /api/v1/business/{id}/switch`, closes sheet, invalidates all business-scoped Riverpod providers, stays on current top-level tab (or falls back to tab root if viewing a single-item detail ID from the previous workspace).
  - **Tap a `READ_ONLY` (Locked) business:** Closes switcher sheet and opens `LockedBusinessDialog` → `"Swap Active Business"` or `"Upgrade to Unlock"` → pushes `PlansAndSubscriptionScreen` (`/plans`).
  - **Tap `"Add Business"` when below OWNER-editable cap:** Opens `CreateBusinessSheet` → on `201 Created`, sets new business active, refreshes list, closes sheet.
  - **Tap `"Add Business"` when at OWNER-editable cap (or `403 PLAN_LIMIT_REACHED`):** Opens `PlanLimitDialog` → `"Upgrade Plan"` → pushes `PlansAndSubscriptionScreen` (`/plans`).
  - **Tap `"Business Settings"`:** Closes sheet → pushes `GeneralSettingsScreen` (`/settings/general`).
  - **Tap `"Plans & Upgrades"`:** Closes sheet → pushes `PlansAndSubscriptionScreen` (`/plans`).

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

- **`BusinessSwitcherSheet`:**
  1. **Drag Handle & Sheet Header:** `"Workspaces"` title + live quota pill (`"{ownedEditableCount} / {maxBusinesses} Active"` in emerald when `< max`, or `Lock` + `"{ownedEditableCount} / {maxBusinesses} Max"` in `primary` when at cap).
  2. **Workspace List (`ListView` constrained max height `50%` screen):**
     - Each row (`AfabInsetPanel` or highlighted `primary` 10% fill when selected):
       - Leading `36x36dp` icon box (`Building2` for editable, `Lock` in amber for `READ_ONLY`).
       - Title row: Business name + `Active` (emerald) or `Locked` (amber) `AfabStatusBadge` + optional `Primary` subtle tag.
       - Subtitle row: `"{currency} • {roleOrSavedLabel}"` (e.g., `"TND • OWNER"` or `"EUR • Data Saved"` when locked).
       - Trailing: Circular `primary` checkmark (`Check`) on the currently active workspace.
  3. **Add Business Row:** Dashed `+` icon tile + `"Add Business"` + either `+` arrow (under cap) or `Crown UPGRADE` pill (at cap).
  4. **Quick Shortcuts Footer:** `"Business Settings"` (`Settings`) and `"Plans & Upgrades"` (`CreditCard` + directional `ArrowRight`).
- **`CreateBusinessSheet`:**
  - Header (`Building2` icon + `"Create New Business Workspace"`).
  - Fields: `Business Name` (required), `Base Currency` (searchable picker covering all 18+ AFAB currencies, not Web's truncated 7-item list), optional collapsible `"More Details"` (`Country`, `Industry`, `Business Type`, `Timezone`).
  - Inline API error banner (e.g., validation or unexpected failure) + sticky `"Cancel"` / `"Create Business"` (`AfabButton` with loading spinner).
- **`LockedBusinessDialog`:**
  - Amber `Lock` icon badge, `"{name}" is Locked`, explanation that all transactions, invoices, customers, and reports remain safely preserved, two highlight bullets (upgrade to Plus 3 / Pro 5, or swap allocation in Subscription Settings), `"Swap Active Business"` secondary CTA + `"Upgrade to Unlock"` primary CTA.
- **`PlanLimitDialog`:**
  - `Crown` gradient badge, `"Workspace Plan Limit Reached"`, exact `ownedEditableCount / maxBusinesses` explanation for `FREE (1)` / `PLUS (3)` / `PRO (5)`, feature highlights box, `"Maybe Later"` + `"Upgrade to {Plus|Pro}"`.

---

## 5. UI Components and Design System Mapping

- `AfabBottomSheet` (drag handle, sticky header, `SafeArea` + keyboard `viewInsets.bottom` padding).
- `AfabStatusBadge` (`Active` `#10B981` tint, `Locked` `#F59E0B` tint, `UPGRADE` `primary` tint).
- `AfabTextField` (Business Name) & `CurrencyPickerSheet` (searchable ISO currency selector with `TND`, `USD`, `EUR`, `GBP`, `AED`, `SAR`, `QAR`, `KWD`, `BHD`, `OMR`, `MAD`, `EGP`, `DZD`, `JOD`, `CAD`, `AUD`, `CHF`, `TRY`, `JPY`, etc.).
- `AfabButton` (48dp touch height, inline spinner during `switchActive` and `create`).

---

## 6. Data Models and State Management

### 6.1 Models
- `BusinessItem` (`BusinessDTO` from `GET /api/v1/business`):
  - `String id`, `String name`, `String currency`, `String? country`, `String? timezone`, `String? industry`, `String? businessType`, `String? userRole` (`OWNER`, `ADMIN`, `MEMBER`), `bool active`, `String? accessMode` (`EDITABLE`, `READ_ONLY`), `bool editable`, `bool primary`, `bool onboardingComplete`.
- `CreateBusinessRequest`: `{ name, currency, country?, timezone?, industry?, businessType? }`.

### 6.2 Cap & Active Resolution Logic (Riverpod)
- `businessListProvider`: `AsyncNotifierProvider<BusinessListNotifier, List<BusinessItem>>` (calls `GET /api/v1/business`).
- `activeBusinessIdProvider`: `NotifierProvider<ActiveBusinessIdNotifier, String?>` (persisted per user in app/secure storage and injected into `X-Business-Id` via `TenantInterceptor`).
- **OWNER-Only Editable Cap Calculation:**
  - `maxBusinesses`: resolved from `subscriptionSnapshotProvider.planSlug` (`pro`/`enterprise` -> `5`, `plus` -> `3`, `free` -> `1`, or `businessAllocations.editableLimit` if loaded).
  - `ownedEditableCount = businesses.where((b) => (b.userRole ?? '').toUpperCase() == 'OWNER' && b.editable).length`.
  - `isAtLimit = ownedEditableCount >= maxBusinesses`.
- **Stale `READ_ONLY` Self-Healing:** On `fetchBusinesses()`, if `activeBusinessId` points to a business with `editable == false`, automatically clear or fall back to the first `active && editable` (or `primary && editable`) workspace, matching `BusinessSwitcher.tsx:104-112` and backend `BusinessController.java:108-120`.

---

## 7. API Contracts and Data Flow

1. **`GET /api/v1/business`**
   - Note: `BusinessController.listMyBusinesses` intentionally catches `BusinessReadOnlyException` so this endpoint **succeeds even if the client's `X-Business-Id` header points to a locked workspace**.
   - Returns `200 List<BusinessDTO>`.
2. **`PUT /api/v1/business/{id}/switch`**
   - Guard: Active member + `EDITABLE` (`403 BUSINESS_READ_ONLY` if locked).
   - Returns `200 BusinessDTO` with `active = true`.
3. **`POST /api/v1/business`**
   - Request: `CreateBusinessRequest` (`name` required, `currency` 3-char ISO code).
   - Backend calls `businessAllocationService.assertCanCreateEditableBusiness(user, maxAllowed)` counting **owned active editable** businesses (`403 PLAN_LIMIT_REACHED` with `feature: "business.max"`, `limit`, `used`, `upgradeTo` if exceeded).
   - Returns `201 BusinessDTO` and sets `user.activeBusinessId = created.id` server-side.
4. **Post-Switch/Create Cache Invalidation:**
   - Immediately updates `activeBusinessIdProvider` and runs `ref.invalidate` on all business-scoped providers (`dashboard`, `transactions`, `categories`, `expenses`, `revenue`, `customers`, `invoices`, `budgets`, `recurring`, `reports`, `ai`) — **no app restart or page reload**.

---

## 8. User Interactions and Event Handling

- **Tap Currently Active Business:** Closes `BusinessSwitcherSheet` immediately without redundant API call.
- **Tap Another `EDITABLE` Business:** Shows inline loading spinner on that row, prevents double-taps, calls `PUT /business/{id}/switch`, updates `activeBusinessIdProvider`, closes sheet, and shows subtle confirmation toast (`"Switched to {name}"`).
- **Tap `READ_ONLY` Business:** Closes sheet and presents `LockedBusinessDialog`.
- **Submit `CreateBusinessSheet`:** Validates non-empty `name` (`<= 100` chars) and 3-letter `currency`, disables button with spinner, calls `POST /business`. On `201`, switches `activeBusinessIdProvider` to `created.id`, refreshes `businessListProvider`, closes sheet. On `403 PLAN_LIMIT_REACHED`, closes `CreateBusinessSheet` and opens `PlanLimitDialog` populated from server response (`limit`, `used`, `upgradeTo`).

---

## 9. Validation, Error, Loading, and Empty States

- **Loading State:** While `businessListProvider` is loading, displays 2–3 shimmer workspace tiles; pull/retry available if initial load failed.
- **Validation (`CreateBusinessSheet`):** Empty business name shows inline error `"Business name is required"` / `"اسم الشركة مطلوب"`.
- **API Errors:**
  - `403 PLAN_LIMIT_REACHED` → opens `PlanLimitDialog` (never silently fails).
  - `403 BUSINESS_READ_ONLY` on `switch` (stale list race) → refreshes `businessListProvider` and opens `LockedBusinessDialog`.
  - `400` / `500` / `NetworkFailure` → inline `AfabAlertBanner` inside `CreateBusinessSheet` or toast inside `BusinessSwitcherSheet`.
- **Empty State:** If API returns empty list (edge case), hides switch list and offers `"Create New Business Workspace"`.

---

## 10. Localization (EN/AR) and RTL Behavior

- Extracts all inline `isArabic` ternaries from `BusinessSwitcher.tsx` (`"Workspaces"`, `"Active"`, `"Max"`, `"Locked"`, `"Data Saved"`, `"Add Business"`, `"Business Settings"`, `"Plans & Upgrades"`, limit/locked dialog copy, form labels, `"Create Business"`) into `app_en.arb` and `app_ar.arb`.
- Uses parameterized ICU messages for `"Your current {plan} plan allows up to {max} workspace(s) ({used}/{max} used)"` in both English and Arabic.
- Currency codes (`USD`, `TND`) display LTR (`TextDirection.ltr`); directional arrows mirror in RTL.

---

## 11. Accessibility and Responsive Guardrails

- Every workspace tile has minimum height `56dp` and `Semantics` announcing `"{name}, {currency}, {Active|Locked}, {selected|not selected}"`.
- `CreateBusinessSheet` uses `SingleChildScrollView` + `viewInsets.bottom` so the keyboard never covers the currency picker or submit button on small phones (`320x568dp`).
- Currency picker provides search filter instead of a giant native spinner.

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **OWNER-Only Workspace Cap Fix (`BusinessSwitcher.tsx:169-173,480` vs `BusinessController.java:176-180`):** Web counts all `editable` businesses (`businesses.filter((b) => b.editable).length`), falsely blocking users who are `MEMBER`/`ADMIN` in someone else's workspace from creating their own business, and prints `businesses.length` (including `READ_ONLY` ones) in the modal body. **Mobile Fix:** Counts strictly `userRole == 'OWNER' && editable` (`ownedEditableCount`) for both the cap check and the UI counter.
2. **Swallowed Errors & Missing Loading State in Create Business (`BusinessSwitcher.tsx:223-241`):** Web has no loading spinner, allows double-submits, and only logs `console.error` if `POST /business` fails. **Mobile Fix:** Full loading guard, inline error banner, and automatic `403 PLAN_LIMIT_REACHED` handling.
3. **Hardcoded 7 Currencies in Create Business (`BusinessSwitcher.tsx:573-581`):** Mobile exposes the complete supported currency catalog (`18+` currencies matching Onboarding & General Settings).
4. **Zero Hard Reload (`BusinessSwitcher.tsx:208,237`):** Replaces `window.location.reload()` with clean Riverpod `activeBusinessIdProvider` invalidation.
5. **Dynamic Upgrade Target in `PlanLimitDialog` (`BusinessSwitcher.tsx:526`):** Web hardcodes `"Upgrade to Pro"` even when user is on Free (where Plus unlocks 3 workspaces). Mobile renders `upgradeTo` dynamically (`"Upgrade to Plus"` or `"Upgrade to Pro"`).

---

## 13. Testing and Verification Plan

- **Unit Tests (`test/unit/business/business_cap_test.dart`):**
  - User on `FREE` (`max=1`) with 1 `OWNER` editable business + 1 `MEMBER` editable business → `ownedEditableCount == 1` (`isAtLimit = true`).
  - User on `FREE` (`max=1`) with 0 `OWNER` businesses + 2 `MEMBER` editable businesses → `ownedEditableCount == 0` (`isAtLimit = false`, allowed to create own business).
  - User on `FREE` with 1 `OWNER` editable + 2 `OWNER` `READ_ONLY` businesses → `ownedEditableCount == 1` (`isAtLimit = true`).
- **Widget Tests (`test/widget/business/business_switcher_sheet_test.dart`):**
  - Tapping `EDITABLE` row calls `switchActive(id)` and updates `activeBusinessIdProvider`.
  - Tapping `READ_ONLY` row opens `LockedBusinessDialog` without calling `switchActive`.
  - Submitting `CreateBusinessSheet` validates empty name, shows spinner, handles `403 PLAN_LIMIT_REACHED` → `PlanLimitDialog`.
  - EN & AR RTL rendering check on `360dp` phone.

---

## 14. Dependencies and Risks

- **Package Dependencies:** `flutter_riverpod`, `go_router`, `lucide_icons_flutter`, `freezed_annotation`.
- **Technical Risks:**
  - **Mid-Detail Business Switch:** If a user opens `BusinessSwitcherSheet` while on a pushed child route (e.g., `InvoiceDetailsScreen(id)`), switching business must pop back to the branch root (`/invoices` or `/dashboard`) so the screen does not display a `404` or stale entity from the previous workspace.
  - **Multi-Tab / External Plan Change:** If subscription changes via Stripe Custom Tabs, `businessListProvider` and `subscriptionSnapshotProvider` must both refresh on app resume so `editable` flags and `maxBusinesses` stay synchronized.
