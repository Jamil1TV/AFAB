# APP-04 — Global Session, Network, Plan Limit, Workspace Lock & Empty States

> **Spec ID:** `APP-04`
> **Phase / Task:** Phase 0 (`P0-02`, `P0-06`) & Phase 2 (`P2-01`)
> **Verified Web Sources:** `Web/project/frontend/lib/api/client.ts` (lines 103–406), `components/dashboard/LifecycleBanners.tsx`, `components/dashboard/BusinessSwitcher.tsx`, `components/ui/EmptyState.tsx`
> **Verified Backend Sources:** `GlobalExceptionHandler.java`, `SecurityConfig.java`, `PlanLimitReachedException.java`, `BusinessReadOnlyException.java`, `ForbiddenException.java`, `AuthController.java`
> **Verified Mobile Architecture Refs:** `03_API_CONTRACT_CATALOG.md`, `04_AUTHENTICATION_AND_SECURITY.md`, `06_FLUTTER_ARCHITECTURE.md`

---

## 1. Screen Identity

- **Component / State Names:**
  1. `SessionExpiredHandler` (Single-flight `401` refresh failure / `REFRESH_TOKEN_REUSE` / forced logout redirect)
  2. `OfflineBanner` & `NetworkRetryState` (`connectivity_plus` + `NetworkFailure`)
  3. `PlanLimitPaywallSheet` (`403 PLAN_LIMIT_REACHED` global modal sheet)
  4. `BusinessReadOnlySheet` (`403 BUSINESS_READ_ONLY` global modal sheet)
  5. `PermissionDeniedBanner` / `PermissionDeniedDialog` (`403 ForbiddenException` role restriction)
  6. `RateLimitedBanner` (`429 RATE_LIMITED`) & `AiUnavailableNotice` (`503 AI_SERVICE_UNAVAILABLE`)
  7. `AfabEmptyState` (Canonical empty & no-search-results contract)
- **Feature Module:** `lib/features/app_states/presentation/` + `lib/core/network/interceptors/` + `lib/shared/widgets/afab_empty_state.dart`

---

## 2. Purpose and Functional Parity

Defines every global cross-cutting failure, quota, workspace lock, network, and empty state emitted by `Dio` interceptors (`ApiErrorInterceptor`, `AuthInterceptor`) and device connectivity listeners, ensuring **zero silent failures**, **zero token-family revocation races**, and **consistent user recovery** across all 51 mobile screens.

---

## 3. Navigation and Entry/Exit Paths

| Trigger Condition | Interceptor / Source | UI Presentation | Exit / Recovery Path |
|---|---|---|---|
| `401` + single-flight refresh fails OR `401 REFRESH_TOKEN_REUSE` OR post-`change-password` | `AuthInterceptor` | Non-blocking toast (`"Your session has expired. Please sign in again."`) | Wipe RAM JWT + `EncryptedCookieStorage` + `activeBusinessId` + Riverpod caches → `router.go('/login?redirect=...')` |
| Device offline (`ConnectivityResult.none`) | `connectivity_plus` stream | Persistent slim `OfflineBanner` below `ShellAppBar` | Auto-dismisses on reconnect; triggers passive stale provider refresh |
| `NetworkFailure` (`timeout` / `connectionError`) on screen load | `ApiErrorInterceptor` | Inline `NetworkRetryState` (`WifiOff` icon + `"Retry"`) | Tap `"Retry"` invalidates provider; **never wipes refresh cookies** |
| `403` with `code == "PLAN_LIMIT_REACHED"` | `ApiErrorInterceptor` → `globalAppEventProvider` | Modal `PlanLimitPaywallSheet` | `"Upgrade to {Plus|Pro}"` → `/plans`; `"Maybe Later"` dismisses |
| `403` with `code == "BUSINESS_READ_ONLY"` | `ApiErrorInterceptor` → clears matching `activeBusinessId` → `globalAppEventProvider` | Modal `BusinessReadOnlySheet` | `"Swap Active Business"` (`BusinessSwitcherSheet` / `/plans`); `"Upgrade Plan"` → `/plans` |
| `403` with `ForbiddenException` (`code != PLAN_LIMIT_REACHED && != BUSINESS_READ_ONLY`) | `ApiErrorInterceptor` | Non-destructive `PermissionDeniedDialog` or `AfabToast` | Stays logged in; explains required role (`OWNER`/`ADMIN`) |
| `429 RATE_LIMITED` | `ApiErrorInterceptor` (`Retry-After` header) | Inline cooldown banner (`"Too many attempts. Try again in {s}s"`) | Auto-re-enables button when countdown hits `0` |
| `503 AI_SERVICE_UNAVAILABLE` | `ApiErrorInterceptor` | Inline notice on AI Copilot / Insights | `"Retry"` or deterministic fallback |
| List / Chart / Search returns `0` items | Screen presentation layer | `AfabEmptyState` | `"Add ..."` primary CTA or `"Clear Filters"` when filtered |

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

1. **`OfflineBanner`:**
   - Full-width compact `36dp` bar (`#1F2937` / `#F59E0B` 15% tint with `#F59E0B` icon & text): `WifiOff` (`16dp`) + `"You are offline. Showing cached data where available."` + optional `"Retry"` pill.
2. **`PlanLimitPaywallSheet` (`AfabBottomSheet` phone / centered `maxWidth: 460dp` dialog tablet):**
   - `48x48dp` `Crown` gradient icon badge (`primary -> primaryHover`).
   - Title: `"Plan Limit Reached"` (or feature-specific headline mapped from `feature`: e.g., `business.max`, `ai.messages_per_month`, `export.per_month`).
   - Quota progress pill (`AfabInsetPanel`): `"{used} / {limit} used"` + full `LinearProgressIndicator` (`primary`).
   - Localized server `message` + upgrade benefits summary for `upgradeTo` (`Plus` or `Pro`).
   - Footer CTAs: `"Maybe Later"` (Secondary) + `"Upgrade to {Plus|Pro}"` (Primary `AfabButton`).
3. **`BusinessReadOnlySheet` (`AfabBottomSheet` phone / centered `maxWidth: 460dp` dialog tablet):**
   - `48x48dp` amber `Lock` icon badge (`#F59E0B` 10% tint, 25% border).
   - Title: `"{businessName} is Read-Only"` (falls back to `"Workspace is Locked"` if `businessName` null).
   - Body: Explains plan downgrade lock and reassures that all transactions, invoices, customers, and reports are safely preserved.
   - Footer CTAs: `"Switch Workspace"` (opens `BusinessSwitcherSheet`), `"Manage Allocation"` / `"Upgrade Plan"` (`/plans`).
4. **`AfabEmptyState`:**
   - Centered column (`padding: 24dp`, `maxWidth: 360dp`): `56x56dp` circular `primary` 10% tinted icon container → bold title (`15sp`) → muted subtitle (`13sp`, max 3 lines) → optional primary `AfabButton` (`+ Add ...` or `Clear Filters`).

---

## 5. UI Components and Design System Mapping

- `AfabBottomSheet` / `Dialog` (adaptive per `AfabBreakpoints`).
- `AfabStatusBadge` (`PLAN_LIMIT`, `READ_ONLY`, `FORBIDDEN`, `OFFLINE`).
- `AfabEmptyState` (supports 3 variants: `emptyData`, `emptySearch`, `errorRetry`).
- `AfabToast` (floating `SnackBar` with semantic icon & optional `"Retry"` action).

---

## 6. Data Models and State Management

### 6.1 Typed `AppFailure` Hierarchy (`lib/core/error/app_failure.dart`)
- `UnauthorizedFailure` (`code: UNAUTHORIZED | REFRESH_TOKEN_REUSE`)
- `PlanLimitReachedFailure` (`String feature`, `int limit`, `int used`, `String upgradeTo`, `String message`)
- `BusinessReadOnlyFailure` (`String? businessId`, `String? businessName`, `String message`)
- `ForbiddenFailure` (`String message`)
- `ValidationFailure` (`String message`, `Map<String, String> fieldErrors`)
- `RateLimitedFailure` (`int retryAfterSeconds`, `String message`)
- `AiUnavailableFailure` (`String message`)
- `NetworkFailure` (`bool isTimeout`, `String message`)
- `ServerFailure` (`int statusCode`, `String message`)

### 6.2 Global Event Bus (`globalAppEventProvider`)
- `StreamProvider` / `Notifier` observed inside `AfabApp` (`lib/app/afab_app.dart`):
  - Emits `SessionExpiredEvent`, `PlanLimitReachedEvent(failure)`, `BusinessReadOnlyEvent(failure)`, `MaintenanceOutageEvent`.
  - Uses a **deduplication guard** (`_isRedirectingToLogin` / `_isSheetOpen`) so 4 parallel failing API calls on dashboard mount open **only 1** modal sheet or trigger **only 1** login redirect (matching `client.ts:47,221`).

---

## 7. API Contracts and Data Flow

Verified directly against `GlobalExceptionHandler.java` & `SecurityConfig.java`:
1. **`401` Auth Filter / Refresh Failure:**
   - `{"success":false,"code":"UNAUTHORIZED","message":"Authentication required."}`
   - `POST /api/v1/auth/refresh` failure: `401 INVALID_REFRESH_TOKEN`, `401 REFRESH_TOKEN_REUSE`, or `403 CSRF_VALIDATION_FAILED`.
   - **Single-Flight Lock (`AuthInterceptor`):** Uses `Completer<bool>? _inFlightRefresh`. Concurrent `401` calls await the single refresh; if it returns `true`, all queued requests retry once with updated `Bearer` token; if `false`, emit `SessionExpiredEvent` once.
2. **`403 PLAN_LIMIT_REACHED` (`GlobalExceptionHandler.java:117-130`):**
   ```json
   {
     "status": 403,
     "code": "PLAN_LIMIT_REACHED",
     "message": "...",
     "feature": "business.max",
     "limit": 1,
     "used": 1,
     "upgradeTo": "plus",
     "path": "/api/v1/business"
   }
   ```
3. **`403 BUSINESS_READ_ONLY` (`GlobalExceptionHandler.java:144-156`):**
   ```json
   {
     "status": 403,
     "error": "Forbidden",
     "code": "BUSINESS_READ_ONLY",
     "businessId": "...",
     "businessName": "...",
     "message": "...",
     "path": "/api/v1/..."
   }
   ```
   - On receipt: if `activeBusinessId == null || activeBusinessId == businessId`, clear `activeBusinessIdProvider` and invalidate `/business` + `/subscription` caches (matching `client.ts:380-396`), then present `BusinessReadOnlySheet`.
4. **`403 ForbiddenException` (`GlobalExceptionHandler.java:93-103`) / `SecurityConfig` `403`:**
   - Treated as role/ownership permission denial — **never** triggers logout or `PlanLimitPaywallSheet`.

---

## 8. User Interactions and Event Handling

- **Expired Session Redirect:**
  - User is on any authenticated screen → JWT expires and refresh token is revoked/expired → `AuthInterceptor` clears `SessionTokenHolder`, `EncryptedCookieStorage.deleteAll()`, `activeBusinessIdProvider`, and invalidates all user-scoped Riverpod caches → displays toast `"Session expired. Please sign in again."` → `GoRouter` redirects to `/login`.
  - Also triggered immediately after `200 OK` on `POST /api/v1/auth/change-password` (`04_AUTHENTICATION_AND_SECURITY.md`).
- **Offline Transition:**
  - `connectivity_plus` emits `none` → `OfflineBanner` animates down cleanly (`AnimatedSize`). User can still view already-loaded Riverpod memory state; attempting a mutation shows `"No internet connection. Please check your network and try again."`.
  - When connectivity returns → `OfflineBanner` hides and active screen can optionally soft-refresh.
- **Plan Limit Sheet Actions:**
  - Tapping `"Upgrade to {Plus|Pro}"` closes sheet and pushes `PlansAndSubscriptionScreen` (`/plans`).
- **Read-Only Sheet Actions:**
  - Tapping `"Switch Workspace"` opens `BusinessSwitcherSheet` (`DASH-03`); tapping `"Upgrade Plan"` / `"Manage Allocation"` opens `/plans`.

---

## 9. Validation, Error, Loading, and Empty States

- **Cold-Start Offline Exception:** On `SplashScreen`, if `POST /auth/refresh` fails due to `NetworkFailure` (NOT `401`/`403`), **do NOT wipe `EncryptedCookieStorage`**! Show an inline `"No internet connection"` screen with `"Retry"` so the user keeps their 7/30-day session once network returns (`10_USER_FLOWS_AND_NAVIGATION.md`).
- **Empty State Distinction (`AfabEmptyState`):**
  - **First-Time Empty:** e.g., `"No invoices yet"` + `"Create Invoice"` CTA.
  - **Filtered/Search Empty:** e.g., `"No matching results"` + `"Clear Filters"` CTA (never tells a user who has 500 transactions `"Add your first transaction"` just because their search query matched 0 rows!).

---

## 10. Localization (EN/AR) and RTL Behavior

- All global failure messages, banner copy, sheet headers, button labels, and empty states use `app_en.arb` and `app_ar.arb`:
  - `sessionExpiredToast`, `offlineBannerText`, `planLimitTitle`, `planLimitUsage({used}, {limit})`, `businessReadOnlyTitle({name})`, `businessReadOnlyDesc`, `permissionDeniedTitle`, `rateLimitedMessage({seconds})`, `emptySearchTitle`, `emptyClearFilters`.
- **Feature Key Localization Map:** Map raw backend `feature` keys (`business.max`, `ai.messages_per_month`, `export.per_month`, `invoices.per_month`) to friendly localized EN/AR names inside `PlanLimitPaywallSheet` instead of displaying raw dot-keys.
- Numbers (`used`, `limit`, `seconds`) render in Western digits `0-9` inside RTL sentences.

---

## 11. Accessibility and Responsive Guardrails

- Global sheets (`PlanLimitPaywallSheet`, `BusinessReadOnlySheet`) use `isScrollControlled: true` + `SafeArea` so content never clips on `320x568dp` phones at `1.4x` text scale.
- `OfflineBanner` uses `Semantics(liveRegion: true)` to announce offline/online transitions once (not repeatedly).
- All modal sheets support Android system back / scrim dismiss cleanly (except non-dismissible session redirect).

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **Active Global `PLAN_LIMIT_REACHED` UI Listener (`client.ts:365-376`):** Web dispatches `afab:plan-limit-reached`, yet only `BusinessSwitcher` / `PlansScreen` handle limits locally — any other endpoint hitting `403 PLAN_LIMIT_REACHED` (e.g., `Reports` `export.per_month` or `AI` `ai.messages_per_month`) lacks a unified global paywall modal. Mobile wires a single global `PlanLimitPaywallSheet` for all features.
2. **Stale JWT Retained After Password Change (`SecuritySettings.tsx`):** Mobile executes immediate local session wipe + `/login` redirect on `change-password` success.
3. **Offline Cold-Start Cookie Preservation:** Prevents accidental logout when device launches offline (`NetworkFailure` vs `401`).
4. **Search Empty vs Workspace Empty Distinction:** `AfabEmptyState` prevents misleading onboarding prompts when active filters return 0 rows.

---

## 13. Testing and Verification Plan

- **Unit Tests (`test/unit/core/app_states_interceptor_test.dart`):**
  - Single-flight `AuthInterceptor` queues 5 parallel `401` calls into 1 `POST /auth/refresh`; on failure emits exactly 1 `SessionExpiredEvent` and wipes `EncryptedCookieStorage`.
  - `REFRESH_TOKEN_REUSE` wipes cookies & emits `SessionExpiredEvent`.
  - `ApiErrorInterceptor` maps `403 PLAN_LIMIT_REACHED`, `403 BUSINESS_READ_ONLY`, `403 Forbidden`, `429 RATE_LIMITED` (`Retry-After`), `503 AI_SERVICE_UNAVAILABLE`, and `NetworkFailure` into exact `AppFailure` subtypes.
- **Widget Tests (`test/widget/app_states/global_states_test.dart`):**
  - `PlanLimitPaywallSheet` displays `used / limit` bar and navigates to `/plans`.
  - `BusinessReadOnlySheet` displays workspace name, clears active ID, and offers Switch / Upgrade CTAs.
  - `OfflineBanner` toggles visibility with `connectivity_plus` stream mock.
  - `AfabEmptyState` renders `emptyData` vs `emptySearch` ("Clear Filters") in `en` & `ar`.

---

## 14. Dependencies and Risks

- **Package Dependencies:** `dio`, `dio_cookie_manager`, `cookie_jar`, `flutter_secure_storage`, `connectivity_plus`, `flutter_riverpod`, `go_router`.
- **Technical Risks:**
  - **Concurrent Sheet Stacking:** Rapid user taps or parallel endpoints could emit both `PlanLimitReachedEvent` and `BusinessReadOnlyEvent`; `AfabApp` must serialize global modal presentation (`_activeModalLock`) so sheets never stack blindly on top of each other.
  - **App Store Billing Review Risk:** Displaying `"Upgrade to Plus/Pro"` inside `PlanLimitPaywallSheet` on iOS/Android is subject to Apple App Store Guideline 3.1.1 / Google Play Billing policy; keep CTA copy & checkout flow aligned with the stakeholder billing decision recorded in `13_RISKS_AND_TECHNICAL_DECISIONS.md`.
