# APP-03 — Global Error Boundary & Bilingual 404 Screen (`GlobalErrorScreen` & `NotFoundScreen`)

> **Spec ID:** `APP-03`
> **Phase / Task:** Phase 0 (`P0-06`)
> **Verified Web Sources:** `Web/project/frontend/app/[locale]/error.tsx`, `app/[locale]/(dashboard)/error.tsx`, `app/[locale]/not-found.tsx`, `components/ChunkErrorRecovery.tsx`, `messages/{en,ar}/not-found.json`
> **Verified Mobile Architecture Refs:** `01_COMPLETE_WEB_SCREEN_INVENTORY.md`, `05_MOBILE_INFORMATION_ARCHITECTURE.md`, `08_LOCALIZATION_AND_RTL.md`

---

## 1. Screen Identity

- **Screen Names:** `GlobalErrorScreen` (Global Flutter & Async Error Boundary) and `NotFoundScreen` (404 / Unknown Route Screen)
- **Route Names & Paths:**
  - `GlobalErrorScreen`: Rendered by `ErrorWidget.builder` (in-widget render failures), `Zone` / `PlatformDispatcher.instance.onError`, `GoRouter.onException`, or top-level `ProviderScope` error boundary
  - `NotFoundScreen`: `AppRoutes.notFound` (`/not-found` and `GoRouter.errorBuilder` fallback for unmatched routes / invalid deep links)
- **Feature Module:** `lib/features/app_states/presentation/{global_error_screen.dart,not_found_screen.dart}`

---

## 2. Purpose and Functional Parity

Provides resilient, user-friendly recovery for both unexpected runtime/rendering exceptions (Web's `[locale]/error.tsx`) and unmatched routes or stale deep links (Web's `[locale]/not-found.tsx`), while eliminating browser-only concepts (`ChunkErrorRecovery`) and Web's broken `/support` route.

---

## 3. Navigation and Entry/Exit Paths

- **Entry Paths:**
  - **`GlobalErrorScreen`:** Uncaught widget build exception (`ErrorWidget.builder`), fatal provider initialization failure before shell mounts, or unhandled `GoRouter` navigation exception.
  - **`NotFoundScreen`:** Unmatched Universal/App Link URI (e.g., invalid `afab://...` or `https://<domain>/{en|ar}/unknown-path`), malformed entity route missing required parameters, or explicit `/not-found` push.
- **Exit Paths:**
  - **`GlobalErrorScreen`:**
    - `"Try Again"` (`RotateCcw`): Resets error boundary state / invalidates failing root provider and retries current route.
    - `"Reload App"` / `"Go to Home"` (`RefreshCw` / `Home`): Navigates safely to `/dashboard` (if authenticated) or `/login` (if unauthenticated), clearing transient navigation stack.
  - **`NotFoundScreen`:**
    - Primary CTA: **Auth-aware** — `"Go to Dashboard"` (`/dashboard`) when authenticated, or `"Go to Sign In"` (`/login`) when unauthenticated *(replacing Web's marketing `/` link which does not exist in Mobile)*.
    - Secondary CTA (only when authenticated): `"Go Back"` (pops if `context.canPop()`, else `/dashboard`) or `"Explore More"` (`/more`).
    - **Omitted:** Web's broken `/${locale}/support` link (`not-found.tsx:146`) is **removed** (optionally replaced only by safe `mailto:support@afab.ai` help action if desired, never an internal `/support` route).

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

- **`GlobalErrorScreen`:**
  - Centered `AfabCard` (`maxWidth: 420dp`, `24dp` padding, `24dp` radius) on `#F8F9FB` / `#060813`:
    1. `48x48dp` rounded-`16dp` amber warning icon tile (`AlertTriangle`, `#F59E0B` 10% tint).
    2. Title (`titleLarge` Bold): `"Something went wrong loading this view"`.
    3. Sanitized description (`bodySmall` `textMuted`, max 4 lines): User-safe message in release mode (no raw Dart stack traces or PII!).
    4. Horizontal action row (`Wrap` on `< 360dp`):
       - Secondary `AfabButton`: `"Try Again"` (`RotateCcw`)
       - Primary `AfabButton`: `"Go to Home"` (`Home` / `RefreshCw`)
- **`NotFoundScreen` (Faithful Flutter Vector Translation of `not-found.tsx`):**
  - Full-screen `Scaffold` (`#F8F9FB` light / `#060813` dark) with subtle floating background `"4"`, `"0"`, `"4"`, `"0"` numerals (`#E9D5FF` light / `#1E1B4B` dark, 50% opacity) and twinkling stars (`AnimatedStars` painter).
  - **UFO & Tractor Beam Illustration (`CustomPaint` + gentle `4s` vertical bobbing):**
    - Purple gradient glass dome (`#D8B4FE -> #8B5CF6`), saucer disc with 3 glowing lights, tapered translucent tractor beam (`clipPath` trapezoid), and dashed floating `"404"` pill badge inside the beam.
  - **Content Block (`maxWidth: 440dp`):**
    - Display `"404"` (`displayLarge` Black)
    - Headline `"Page Not Found"` / `"الصفحة غير موجودة"`
    - Subtitle `"Sorry, the screen you're looking for doesn't exist or has been moved."`
    - Action buttons (`Column` full-width on `< 600dp`, `Row` on `>= 600dp`):
      - Primary `AfabButton`: `"Go to Dashboard"` (auth) or `"Go to Sign In"` (unauth)
      - Secondary `AfabButton`: `"Go Back"` (when `canPop()` is true)
    - Optional clean footer: `"Need help? Contact Support"` launching `mailto:support@afab.ai` (zero broken `/support` route).

---

## 5. UI Components and Design System Mapping

- `AfabCard` & `AfabButton` (`primary` & `secondary`, `48dp` min height).
- `Ufo404Illustration` (`CustomPainter` + `AnimationController` with `MediaQuery.disableAnimationsOf` guard).
- `ErrorWidget.builder` custom release fallback (replaces Flutter's red/grey "Error widget" box in release builds).

---

## 6. Data Models and State Management

- **`GlobalErrorHandler` Setup (`main.dart`):**
  - `FlutterError.onError`: Logs sanitized error via `AppLogger` (redacting tokens/emails/amounts per `06_FLUTTER_ARCHITECTURE.md`) and reports to optional crash telemetry.
  - `PlatformDispatcher.instance.onError`: Catches uncaught async isolate errors cleanly.
  - `ErrorWidget.builder`: In `kDebugMode`, shows concise widget error card; in `kReleaseMode`, shows localized `CompactInlineErrorCard` (`"Unable to render this section"` + retry).
- **`NotFoundScreen` Auth Check:** Reads `sessionStatusProvider` (`isAuthenticated`) to choose `"Go to Dashboard"` vs `"Go to Sign In"`.

---

## 7. API Contracts and Data Flow

- Neither screen requires backend API calls to render.
- `"Try Again"` on `GlobalErrorScreen` invokes caller callback (`ref.invalidate(...)` on the failed provider) or reloads `/splash` if root state failed.

---

## 8. User Interactions and Event Handling

- **Tap `"Try Again"`:** Resets boundary error flag and retries failed operation.
- **Tap `"Go to Dashboard"` / `"Go to Sign In"`:** Calls `context.go(AppRoutes.dashboard)` or `context.go(AppRoutes.login)`.
- **Tap `"Go Back"` (`NotFoundScreen`):** Calls `context.pop()` if stack has prior entry.
- **Tap `"Contact Support"` (if rendered as `mailto:`):** Opens OS email composer for `support@afab.ai` (never pushes `/support`).

---

## 9. Validation, Error, Loading, and Empty States

- **Stack Trace Privacy:** Release builds MUST NOT display raw `error.toString()` containing internal URLs, UUIDs, or stack frames; display a generic localized message (`errorUnexpectedDesc`) and log full scrubbed diagnostics internally.
- **Reduced Motion:** `NotFoundScreen` disables floating `4`, `0`, UFO bobbing, and star pulse animations when `MediaQuery.disableAnimationsOf(context)` is `true`.

---

## 10. Localization (EN/AR) and RTL Behavior

- **Fixes Web Hardcoded English (`error.tsx:28-52`):** Localizes all `GlobalErrorScreen` strings in `app_en.arb` and `app_ar.arb`:
  - `errorBoundaryTitle` (`"Something went wrong loading this page"` / `"حدث خطأ أثناء تحميل هذه الصفحة"`)
  - `errorBoundaryDesc` (`"An unexpected error occurred while rendering this view."` / `"حدث خطأ غير متوقع أثناء عرض هذه الواجهة."`)
  - `errorTryAgain` (`"Try Again"` / `"حاول مرة أخرى"`)
  - `errorGoHome` (`"Go to Home"` / `"العودة للرئيسية"`)
- **Migrates `not-found.json` (10 keys EN/AR):**
  - Adapts `"Go Back Home"` (`العودة للرئيسية`) to `"Go to Sign In"` (`تسجيل الدخول`) when unauthenticated since no marketing home page exists in Mobile.
  - `"404"` numeral stays LTR Western digits `404` (`TextDirection.ltr`).

---

## 11. Accessibility and Responsive Guardrails

- Background floating `"4"`, `"0"`, UFO, and stars are wrapped in `ExcludeSemantics` so TalkBack/VoiceOver reads only `"404. Page Not Found. Sorry, the page you're looking for doesn't exist or has been moved."` followed by the action buttons.
- `SingleChildScrollView` prevents vertical overflow on `320x568dp` landscape or `1.4x` font scaling (UFO illustration scales down proportionally via `FittedBox` / `LayoutBuilder`).

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **Broken `/support` Link Removed (`not-found.tsx:146`):** Web links to `/${locale}/support`, which does not exist and causes an infinite 404 loop! Mobile **omits** the internal `/support` route completely (using only optional `mailto:support@afab.ai`).
2. **Hardcoded English `error.tsx` Fixed (`error.tsx:28-52`):** Localized for EN & AR.
3. **Browser `ChunkErrorRecovery` Replaced (`ChunkErrorRecovery.tsx`):** Native Flutter AOT binaries do not have Next.js JS chunk loading failures; `ChunkErrorRecovery` is omitted and replaced with Dart `ErrorWidget.builder` + `PlatformDispatcher.instance.onError` + Riverpod `AsyncError` retry boundaries.
4. **No Dead Marketing `/` Link:** Unauthenticated 404 users route to `/login` rather than a non-existent marketing homepage.

---

## 13. Testing and Verification Plan

- **Widget Tests (`test/widget/app_states/error_and_not_found_test.dart`):**
  - Navigating `GoRouter` to `/non-existent-route` renders `NotFoundScreen`.
  - Authenticated state displays `"Go to Dashboard"`; unauthenticated displays `"Go to Sign In"`; zero `/support` link exists.
  - `GlobalErrorScreen` invokes `onRetry` on `"Try Again"` and navigates home on `"Go to Home"`.
  - Verified in `en` (LTR) and `ar` (RTL), Light & Dark (`midnight` / `oled`), at `320x568` and `1024x768`, and with `disableAnimations: true`.

---

## 14. Dependencies and Risks

- **Package Dependencies:** `go_router`, `flutter_riverpod`, `url_launcher`, `lucide_icons_flutter`.
- **Technical Risks:**
  - **Infinite Error Loop on Root Crash:** If the error occurs inside `MaterialApp` theme/locale initialization itself, `GlobalErrorScreen` must use safe fallback `Directionality` + `MediaQuery` + basic material colors (`#060813` / `#FFFFFF`) so the error screen itself never throws a secondary `No MaterialLocalizations found` exception.
