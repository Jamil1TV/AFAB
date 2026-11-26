# PLAN-02 — Business Allocation & Subscription Cancel Flows Specification

> **Verified Sources:**
> - Web Components: `Web/project/frontend/components/plans/BusinessAllocationModal.tsx`, `CancelSubscriptionModal.tsx`, `PlansScreen.tsx` (lines 585–711, 1678–1724)
> - Web API: `Web/project/frontend/lib/api/business.ts`, `Web/project/frontend/lib/api/subscription.ts`
> - Backend: `BusinessController.java` (lines 464–500), `BusinessAllocationService.java` (lines 1–506), `BusinessAllocationDTO.java`, `StripeBillingController.java` (lines 61–86), `StripeBillingService.java` (lines 213–551)
> - Mobile Core Docs: `03_API_CONTRACT_CATALOG.md`, `07_DESIGN_SYSTEM.md`, `08_LOCALIZATION_AND_RTL.md`, `10_USER_FLOWS_AND_NAVIGATION.md`, `13_RISKS_AND_TECHNICAL_DECISIONS.md`

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `PLAN-02` |
| **Screen Names** | `BusinessAllocationSheet` (`DOWNGRADE` / `MANAGE` / `PENDING_EDIT`) + `CancelSubscriptionSheet` + `ResumeSubscriptionAction` |
| **Feature Module** | `lib/features/plans/` (shared with `lib/features/business/`) |
| **Presentation Style** | Modal `AfabBottomSheet` on phone (`< 600dp`); centered `Dialog` (`maxWidth: 560dp`) on tablet (`>= 600dp`) |
| **Parent Triggers** | `PlansAndSubscriptionScreen` (`PLAN-01`), `AllocationAttentionBanner`, `LockedBusinessDialog` (from `BusinessSwitcherSheet`) |

---

## 2. Purpose and Web Parity Status

- **Purpose:** Governs all workspace-slot allocation and subscription termination/reversal workflows:
  1. **`BusinessAllocationSheet`:** Lets users choose which owned businesses stay `EDITABLE` (unlocked) vs `READ_ONLY` (vaulted with all data preserved) under `MANAGE` (immediate swap), `DOWNGRADE` (Pro → Plus period-end or immediate local downgrade), or `PENDING_EDIT` (edit already-scheduled future selection).
  2. **`CancelSubscriptionSheet`:** Explains trial/paid cancellation guarantees (zero data loss, end-of-period access) and, when the user owns `> 1` business, requires choosing the **1 business to remain `EDITABLE`** on the Free plan.
  3. **`ResumeSubscription` Flow:** Reverses any scheduled cancellation (`cancelAtPeriodEnd`) or scheduled downgrade (`pendingPlanSlug` / Stripe `SubscriptionSchedule`) via `POST /api/v1/billing/resume`.
- **Web Parity Status:** **Implemented and Connected** — Mobile replicates 100% of backend state transitions while adding native touch ergonomics, `READ_ONLY` active-business auto-switching, and explicit handling of `allocationAttentionRequired`.

---

## 3. Navigation, Entry Points, and Deep Links

- **Entry Points:**
  - `PLAN-01` → `"Change Editable Businesses"` (`BusinessAllocationSheet`, mode: `MANAGE`).
  - `PLAN-01` → `"Downgrade to Plus"` (`BusinessAllocationSheet`, mode: `DOWNGRADE`, `targetPlanSlug: "plus"`, `maxAllowed: 3`).
  - `PLAN-01` → `"Configure Future Businesses"` inside Pending Change banner (`BusinessAllocationSheet`, mode: `PENDING_EDIT`, `initialSelectedIds: allocation.pendingBusinessIds`).
  - `PLAN-01` → `"Cancel Free Trial"` / `"Cancel Subscription"` / `"Downgrade to Free"` (`CancelSubscriptionSheet`).
  - `AllocationAttentionBanner` ("Manage Workspaces") → navigates to `PLAN-01` or opens `BusinessAllocationSheet(mode: MANAGE)` directly.
  - `LockedBusinessDialog` ("Manage Allocation") → opens `BusinessAllocationSheet(mode: MANAGE)`.
- **Post-Submit Navigation & Provider Updates:**
  - If `MANAGE` or immediate `DOWNGRADE` moves the currently active business (`activeBusinessId`) to `READ_ONLY`, automatically switch `activeBusinessIdProvider` to `selectedBusinessIds.first` (mirroring `PlansScreen.tsx:660-663, 686-689` and `BusinessAllocationService.java:212-215`), invalidate all business-scoped providers, and refresh `subscriptionSnapshotProvider`, `businessAllocationProvider`, `businessListProvider`, and `billingHistoryProvider`.

---

## 4. Layout and Visual Hierarchy

### 4.1 `BusinessAllocationSheet`
1. **Header:**
   - Leading `44x44dp` icon tile (`Building2`, `primary` 10% fill) + Trailing counter pill (`"Selected {count} / {requiredCount}"` — green when `isValid`, amber when invalid).
   - Dynamic Title & Description by `mode`:
     - `DOWNGRADE`: *"Select Editable Businesses for {targetPlanName}"*
     - `PENDING_EDIT`: *"Update Scheduled {targetPlanName} Business Allocation"*
     - `MANAGE`: *"Manage Editable Business Allocation"*
     - Subtitle: Explains `maxAllowed` unlocked slots vs vaulted read-only preservation.
2. **Scrollable Business Selection List:**
   - Each `BusinessAllocationItem` row card (`surface` / `primary` 10% tint + `primary` border when checked; dimmed `65%` opacity when unselected & cap reached):
     - Checkbox (`maxAllowed > 1`) or Radio indicator (`maxAllowed == 1`).
     - Business avatar (`cached_network_image` `logoUrl` or `Building2` icon).
     - Business `name` + `Primary` badge (if `primary`) + `Current` badge (if `active`).
     - Subtitle: `{currency} • {industry} • {country} • Current: Active (Unlocked) / Locked (Data Saved)`.
     - Trailing outcome pill: `"Unlocked"` (green `Check`) vs `"Locked"` (amber `Lock`).
3. **Outcome Summary Panel (`AfabInsetPanel`):**
   - `ShieldCheck` (green): **"Will remain Active (Unlocked):"** comma-separated selected names.
   - `Lock` (amber, shown if `readOnlyBusinesses.isNotEmpty`): **"Will be Locked (all data safely vaulted):"** comma-separated unselected names.
   - Validation warning (amber `AlertCircle`, if `!isValid`): *"Please select exactly {requiredCount} business(es) to continue."*
4. **Sticky Footer:** `Cancel` (`AfabButton.secondary`) + Submit (`AfabButton.primary`: `"Confirm Downgrade to {targetPlanName}"` for `DOWNGRADE`, `"Save Business Allocation"` for `MANAGE` / `PENDING_EDIT`).

### 4.2 `CancelSubscriptionSheet`
1. **Header:**
   - `48x48dp` amber `AlertTriangle` icon tile.
   - Title: `isTrial ? "Cancel Your {planName} 7-Day Free Trial?" : "Cancel Your {planName} Subscription?"`.
   - Subtitle: *"Please review when your access ends and how your businesses will be preserved."*
2. **3 Lifecycle Guarantee Rows (`AfabInsetPanel`):**
   - `Calendar` (`primary`): **When paid access ends:** Keep full `{planName}` access until `{effectiveEndDate}` (or end of current period).
   - `CreditCard` (emerald): **Future payments & billing:** Trial → *"No payment will be collected when your trial ends"*; Paid → *"Will not renew and no additional charges will be collected."*
   - `ShieldCheck` (sky): **What happens to your businesses:** *"Zero data is deleted. 1 business remains active; additional businesses are locked with all financial data safely stored until you upgrade or swap."*
3. **1-of-N Free Business Selector (`primary` 5% tint card, shown only when `businesses.length > 1`):**
   - Header: *"Select the 1 business to keep Editable on Free (1 of {N}):"* + `"1 / 1"` badge.
   - Scrollable radio-style cards for each owned business (`Building2` tile, `name`, `currency • industry`, trailing `"Remains Active"` green pill vs `"Becomes Locked"` amber pill).
4. **Sticky Footer:**
   - Primary safe action: `"Keep Subscription"` (`AfabButton.primary`, closes sheet).
   - Destructive confirm action: `"Confirm Cancellation"` (`AfabButton.danger`, disabled if `isSubmitting || (businesses.length > 1 && selectedBusinessId.isEmpty)`).

### 4.3 `ResumeSubscription` Confirmation
- Triggered by `"Keep / Resume Subscription"` or `"Cancel Scheduled Downgrade"` on `PLAN-01`.
- Optional quick confirmation dialog (or direct call with loading spinner matching Web `PlansScreen.tsx:624`) calling `POST /api/v1/billing/resume`, clearing `pendingPlanSlug`/`cancelAtPeriodEnd`, and restoring renewal toast.

---

## 5. UI Components and Design System Mapping

| UI Element | Shared / Feature Widget | Design Token & Styling (`07_DESIGN_SYSTEM.md`) |
|---|---|---|
| Modal Presentation | `AfabBottomSheet` / `Dialog` | `surface` bg, `24dp` corner radius, `SafeArea` + `viewInsets.bottom` |
| Business Select Row | `SelectableBusinessCard` | Selected: `primary` 10% tint + `1.5dp primary` border; Unselected: `surfaceInset`, `1dp border` |
| Outcome Summary | `AfabInsetPanel` | `surfaceInset` bg, semantic icons (`#10B981` ShieldCheck, `#F59E0B` Lock) |
| Status Pills | `AfabStatusBadge` | `Unlocked` / `Remains Active` (`success`), `Locked` / `Becomes Locked` (`warning`), `Primary` (`primary`), `Current` (`info`) |
| Cancel Sheet Danger CTA | `AfabButton.danger` | `danger` (`#EF4444`) `10%` fill + `30%` border, min height `48dp` |

---

## 6. State Management and Data Flow

- **`businessAllocationSheetControllerProvider` (`Notifier`):**
  - Initial pre-selection logic (mirrors `BusinessAllocationModal.tsx:58-77`):
    1. If `initialSelectedIds` is non-empty (`PENDING_EDIT`), use `initialSelectedIds.take(maxAllowed)`.
    2. Else use currently `editable` businesses if `1 <= count <= maxAllowed`.
    3. Else sort `businesses` by `primary` desc → `active` desc and take `requiredCount = min(businesses.length, maxAllowed)`.
  - `toggleBusiness(id)`:
    - If `selectedIds.contains(id)` → remove `id`.
    - Else if `maxAllowed == 1` → replace `[id]` (radio behavior).
    - Else if `selectedIds.length < maxAllowed` → add `id`.
  - `submit()`:
    - `DOWNGRADE`: calls `POST /api/v1/billing/downgrade` (`{ targetPlanSlug, selectedBusinessIds, billingInterval, deferAllocation: false }`). Checks if `updatedSub.planSlug == targetPlanSlug` (immediate local non-Stripe downgrade) vs scheduled period-end downgrade, and displays tailored toast.
    - `PENDING_EDIT`: calls `PUT /api/v1/business/allocations/pending` (`{ targetPlanSlug, selectedBusinessIds }`).
    - `MANAGE`: calls `PUT /api/v1/business/allocations` (`{ selectedBusinessIds }`).
- **`cancelSubscriptionControllerProvider`:**
  - Pre-selects `primary ?? active ?? businesses.first`.
  - Calls `POST /api/v1/billing/cancel` (`{ selectedBusinessIds: selectedId != null ? [selectedId] : [] }`).
  - Handles both scheduled period-end cancellation (Stripe active) and immediate Free transition (non-Stripe local DB subscription).
- **`resumeSubscriptionControllerProvider`:**
  - Calls `POST /api/v1/billing/resume` → refreshes all billing & business allocation providers.

---

## 7. API Contracts and DTO Mapping

| Endpoint | Request DTO | Response DTO | Backend Behavior & Guards |
|---|---|---|---|
| `GET /api/v1/business/allocations` | — | `BusinessAllocationDto` (`currentPlanSlug`, `currentPlanName`, `editableLimit`, `editableCount`, `readOnlyCount`, `totalOwnedCount`, `allocationAttentionRequired`, `pendingPlanSlug?`, `pendingPlanName?`, `pendingEditableLimit?`, `pendingChangeEffectiveAt?`, `pendingBusinessIds[]`, `businesses[]`) | Only includes `OWNER` active (non-archived) businesses (`findAllOwnedActiveByUserId`) |
| `PUT /api/v1/business/allocations` | `{ selectedBusinessIds: List<UUID>, primaryBusinessId?: UUID }` | `BusinessAllocationDto` | Sets selected `EDITABLE`, others `READ_ONLY`; updates `primary` if needed; clears `allocationAttentionRequired`; records `ALLOCATION_UPDATED` history |
| `PUT /api/v1/business/allocations/pending` | `{ targetPlanSlug: "free"\|"plus"\|"pro", selectedBusinessIds: List<UUID> }` | `BusinessAllocationDto` | Saves rows in `pending_business_allocations`; requires exact `min(owned.size, targetLimit)` |
| `POST /api/v1/billing/downgrade` | `{ targetPlanSlug: "free"\|"plus", billingInterval?: "monthly"\|"yearly", selectedBusinessIds?: List<UUID>, deferAllocation: bool }` | `SubscriptionSnapshotDto` | Validates `tierRank(target) < tierRank(current)`; if `target == "free"` delegates to `cancelSubscription`; if active Stripe sub, creates/updates Stripe `SubscriptionSchedule` (no immediate downgrade); if local sub, downgrades immediately & applies `READ_ONLY` |
| `POST /api/v1/billing/cancel` | `{ selectedBusinessIds?: List<UUID> }` | `SubscriptionSnapshotDto` | Releases any `SubscriptionSchedule`; sets Stripe `cancel_at_period_end = true` (keeps paid access until `periodEnd`/`trialEnd`) and saves `pending_business_allocations` for `"free"`; if non-Stripe local sub, moves immediately to `free` |
| `POST /api/v1/billing/resume` | — | `SubscriptionSnapshotDto` | Releases `SubscriptionSchedule`, sets `cancel_at_period_end = false`, clears `pendingPlan*` and `pending_business_allocations`, emits `SUBSCRIPTION_RESUMED` notification |

---

## 8. Form Fields, Validation, and Business Rules

1. **Exact Selection Validation (`BusinessAllocationSheet`):**
   - `requiredCount = min(businesses.length, maxAllowed)`.
   - `isExactSelectionRequired = (mode == DOWNGRADE || mode == PENDING_EDIT || businesses.length >= maxAllowed)`.
   - `isValid`: if `isExactSelectionRequired`, `selectedIds.length == requiredCount`; else `1 <= selectedIds.length <= maxAllowed`.
   - Submit button disabled until `isValid && !isSubmitting`.
2. **Free Cancel Selection (`CancelSubscriptionSheet`):**
   - If `businesses.length > 1`, user **must** have `selectedBusinessId` chosen (`1 / 1`). If `businesses.length <= 1`, `selectedBusinessIds` sends `[businesses[0].id]` (or `[]` if 0).
3. **Owner-Only Constraint (`BusinessAllocationService.java:448-451`):**
   - Only `OWNER` businesses are allocatable; non-owned `ADMIN`/`MEMBER` workspaces are never returned by `/business/allocations` and cannot be passed in `selectedBusinessIds`.
4. **Trial vs Paid Cancel Copy:**
   - When `isTrial == true`, emphasize `"you will not be charged when your 7-day trial ends"`.

---

## 9. User Interactions and Edge Cases

- **Cap Reached in Multi-Select (`maxAllowed == 3`, e.g., Plus):** When 3 businesses are checked, remaining unchecked cards visually dim (`opacity: 0.65`) and ignore tap-to-add until the user unchecks one of the 3 selected cards (matching `BusinessAllocationModal.tsx:167, 187`).
- **Single-Slot Radio Swap (`maxAllowed == 1`, e.g., Free):** Tapping another business immediately switches selection to that business without requiring the user to uncheck the previous one first (`BusinessAllocationModal.tsx:84-86`).
- **Active Business Becomes `READ_ONLY`:** Immediately switch `activeBusinessIdProvider` to `selectedIds.first` and reset business-scoped caches so the user doesn't hit `403 BUSINESS_READ_ONLY` on the next Dashboard/Transactions API call.
- **No Active Paid Subscription on Cancel (`400`/`500`):** Backend throws `IllegalStateException("No active paid subscription is available to cancel.")` — sheet shows error toast and closes or hides Cancel CTA when `!hasStripeSubscription`.
- **Defer Allocation (`deferAllocation`):** `BusinessAllocationSheet` always collects selection upfront (`deferAllocation: false`), matching Web.

---

## 10. Loading, Empty, Error, and Offline States

- **Submitting State:** Submit / Confirm Cancellation button shows `CircularProgressIndicator` (`16dp`); backdrop dismiss and Cancel button disabled while in flight.
- **Empty Businesses (`businesses.isEmpty`):** Should rarely occur (since registration creates 1 business), but if all owned businesses were archived, `CancelSubscriptionSheet` hides the 1-of-N selector and submits `selectedBusinessIds: []`.
- **API Error:** `AfabToast.error` displays backend validation or Stripe error (`400`, `403`, `502`/`503`) without losing the user's current selection in the sheet.
- **Offline State:** Disable Confirm/Save CTAs while offline with inline notice.

---

## 11. Localization (EN/AR) and RTL Behavior

- **Translation Keys:** Migrate all inline `isAr ? ... : ...` strings from `BusinessAllocationModal.tsx` and `CancelSubscriptionModal.tsx` into `app_en.arb` and `app_ar.arb` (covering all 3 modes, `Active (Unlocked)`, `Locked (Data Saved)`, `Primary`, `Current`, trial cancellation copy, paid cancellation copy, `Keep Subscription`, `Confirm Cancellation`).
- **RTL & BiDi:**
  - `Selected {X} / {Y}` badge and `{currency}` codes wrap numbers/codes in `Directionality(textDirection: TextDirection.ltr)` when embedded in Arabic strings.
  - Formatted `effectiveEndDate` uses localized Gregorian date (`intl`).
  - Trailing status pills (`Unlocked` / `Locked`) and leading checkboxes mirror cleanly via `EdgeInsetsDirectional` / `AlignmentDirectional`.

---

## 12. Responsive and Tablet Adaptation

- **Phone (`< 600dp`):**
  - `AfabBottomSheet` (`isScrollControlled: true`, max height `90%`), scrollable business list (`maxHeight: 280–340dp` flexible), sticky bottom footer with `SafeArea` padding.
  - On `< 360dp`, footer buttons stack vertically (`Keep Subscription` on top, `Confirm Cancellation` below, or full-width equal row with concise labels).
- **Tablet (`>= 600dp`):**
  - Centered `Dialog` (`maxWidth: 560dp` for `BusinessAllocationSheet`, `512dp` for `CancelSubscriptionSheet`) with comfortable `24dp` internal padding and inline horizontal footer actions.

---

## 13. Acceptance Criteria and Test Scenarios

1. **`MANAGE` Swap (`Free` user with 3 owned businesses):** Opening `BusinessAllocationSheet(mode: MANAGE, maxAllowed: 1)`, tapping another business switches selection radio-style (`1 / 1`), saving calls `PUT /business/allocations`, updates active business if swapped out, and updates `allocationAttentionRequired` to `false`.
2. **`DOWNGRADE` (`Pro` → `Plus` with 5 owned businesses):** Selecting 3 of 5 businesses disables the 4th tap until one is deselected; confirming calls `POST /billing/downgrade` and surfaces scheduled downgrade banner on `PLAN-01`.
3. **`PENDING_EDIT`:** Re-opening `"Configure Future Businesses"` pre-selects `allocation.pendingBusinessIds` and saves changes via `PUT /business/allocations/pending`.
4. **Cancel Trial & Paid Subscription (`> 1` business):** `CancelSubscriptionSheet` requires choosing 1 business to keep editable, displays trial no-charge guarantee when `isTrial == true`, calls `POST /billing/cancel`, and schedules cancellation.
5. **Resume Subscription:** Tapping `"Keep / Resume Subscription"` calls `POST /billing/resume`, clears scheduled cancellation/downgrade, and restores normal renewal status.

---

## 14. Dependencies and Risks

- **Dependencies:** `flutter_riverpod`, `cached_network_image`, `PlansRepository`, `BusinessAllocationRepository`, `activeBusinessProvider`, `PlansAndSubscriptionScreen` (`PLAN-01`).
- **Technical Risks & Mitigations:**
  - **Local Non-Stripe Immediate Downgrade (`StripeBillingService.java:237-267, 420-450`):** In dev/local setups without an active `stripeSubscriptionId`, `/billing/cancel` and `/billing/downgrade` apply immediately rather than at period end! **Mitigation:** Inspect `returnedSnapshot.planSlug` after `/cancel` or `/downgrade`; if it already changed to `"free"` or `"plus"`, immediately switch `activeBusinessId` if needed and display `"Downgraded immediately"` toast (matching `PlansScreen.tsx:658-673`).
  - **Account Deletion Deadlock on `READ_ONLY` Businesses (`13_RISKS_AND_TECHNICAL_DECISIONS.md` #8):** Locked businesses created by downgrading cannot be deleted via `DELETE /business/{id}` (`403 BUSINESS_READ_ONLY`). **Mitigation:** Ensure `BusinessAllocationSheet(mode: MANAGE)` is easily reachable from both `PLAN-01` and `AccountDeletionFlow` so users can swap a `READ_ONLY` business back to `EDITABLE` (or transfer ownership) when needed.
