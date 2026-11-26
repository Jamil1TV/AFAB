# APP-02 — Maintenance & Service Outage Screen (`MaintenanceScreen`)

> **Spec ID:** `APP-02`
> **Phase / Task:** Phase 0 (`P0-06`)
> **Verified Web Sources:** `Web/project/frontend/app/[locale]/(dashboard)/maintenance/page.tsx`
> **Verified Backend Sources:** `HealthController.java` (`GET /api/v1/health`)
> **Verified Mobile Architecture Refs:** `03_API_CONTRACT_CATALOG.md`, `05_MOBILE_INFORMATION_ARCHITECTURE.md`, `08_LOCALIZATION_AND_RTL.md`

---

## 1. Screen Identity

- **Screen Name:** `MaintenanceScreen`
- **Route Name & Path:** `AppRoutes.maintenance` (`/maintenance`) — **top-level public out-of-shell route** (explicitly outside `AdaptiveShell` / `(dashboard)`)
- **Feature Module:** `lib/features/app_states/presentation/maintenance_screen.dart`
- **Access Control:** Public (accessible whether authenticated or unauthenticated)

---

## 2. Purpose and Functional Parity

Informs users cleanly when the AFAB backend API is undergoing scheduled maintenance or experiencing a service outage (`503 Service Unavailable` infrastructure outage or unreachable health check), while actively polling `GET /api/v1/health` so the app recovers automatically the moment service is restored.

---

## 3. Navigation and Entry/Exit Paths

- **Entry Paths:**
  - Global `GoRouter` redirect / outage signal when:
    - Repeated `503` gateway/maintenance HTML or non-JSON `503` responses occur (distinguished carefully from domain-specific JSON `503` codes like `AI_SERVICE_UNAVAILABLE`, `EMAIL_DELIVERY_FAILED`, `RATE_LIMIT_UNAVAILABLE`, or `BillingNotConfiguredException`, which are handled locally without locking out the app!).
    - Or remote health/maintenance flag marks backend unavailable during `SplashScreen` or active usage.
- **Exit Paths:**
  - **Automatic Recovery:** When `GET /api/v1/health` returns `200` with `status == "UP"`, `maintenanceModeProvider` resets to `false` and `GoRouter` navigates back to the prior route (if session active) or `/splash` → `/login`.
  - **Manual `"Check Status"` Button:** Triggers immediate `GET /api/v1/health` probe.
  - **`"Go to Sign In"` / `"Back to Dashboard"` Secondary CTA:** Enabled if user wants to return/re-authenticate (if health is `UP`, proceeds; if still down, shows current outage timestamp).
  - **`"Contact Support"` Link:** Launches `mailto:support@afab.ai?subject=AFAB%20Service%20Status` via `url_launcher`.

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

- **Canvas:** Full-screen `Scaffold` (no `BottomNavigationBar`, no `NavigationRail`, no `ShellAppBar` — fixing Web's `(dashboard)/maintenance` bug) with subtle ambient `primary` radial glow blobs (`0.06` light / `0.12` dark).
- **Top Utility Bar (inside `SafeArea`):**
  - Trailing: Quick `LanguageToggle` (`EN` / `العربية`) and `ThemeMode` toggle so users stuck on maintenance can still switch language/theme cleanly.
- **Centered Content Column (`ConstrainedBox(maxWidth: 520dp)` inside `SingleChildScrollView`):**
  1. **Brand Header:** `56x56dp` rounded-`16dp` AFAB logo badge (`afablogo.png` / `afablogo_dark.png`) + `"AFAB"` wordmark + `"AI Finance Assistant"` subtitle.
  2. **Headline & Copy:**
     - Title (`headlineLarge` Bold): `"We're Under Maintenance"`
     - Subtitle (`bodyMedium` `textMuted`): `"We're performing scheduled maintenance to improve your experience and bring you smarter financial insights. We'll be back shortly!"`
  3. **Live Health Status Card (`AfabCard` — Replacing Fake Progress Bar):**
     - Pulsing `Activity` icon + live status label (`"Checking service health..."` / `"Service Temporarily Unavailable"` / `"Service Restored"`).
     - Live `GET /api/v1/health` telemetry row (`AfabInsetPanel`):
       - `API Service`: `"afab-backend"` (`UP` emerald badge / `DOWN` or `Unreachable` red-amber badge)
       - `Mail Service`: `UP` / `DOWN` (from `health.mail.status`, only shown when backend responds)
       - `Last Checked`: localized timestamp (`HH:mm:ss`) + next auto-retry countdown (`"Auto-checking in {seconds}s"`).
     - Indeterminate subtle progress bar **only while an active health probe HTTP request is in flight** (zero fake `65% -> 98%` progress!).
  4. **Primary Actions Cluster:**
     - Primary `AfabButton`: `"Check Status Now"` (`RefreshCw`, shows spinner while probing).
     - Secondary `AfabButton`: `"Back to Home"` / `"Go to Sign In"` (`Home` / `LogIn`, enabled when `status == "UP"` or to re-enter `/splash`).
  5. **Footer Help:** `"Need urgent help?"` + `"Contact Support"` (`mailto:support@afab.ai`) + overall status badge (`"System Status: Maintenance"` / `"Degraded"`).

---

## 5. UI Components and Design System Mapping

- `AfabCard` (`surface`, `1px border`, `20dp` padding).
- `AfabInsetPanel` for live service telemetry (`service`, `mail.status`, `lastCheckedAt`).
- `AfabStatusBadge` (`#F59E0B` amber for `Maintenance` / `Mail Degraded`, `#EF4444` red for `Unreachable`, `#10B981` emerald for `Operational`).
- `AfabButton` (Primary `"Check Status Now"`, Secondary `"Go to Dashboard"` / `"Go to Sign In"`).

---

## 6. Data Models and State Management

### 6.1 `HealthStatus` Model (`freezed`)
Matches `HealthController.java`:
```dart
class HealthStatus {
  final String status;       // "UP" or "DOWN"
  final DateTime timestamp;  // ISO-8601 Instant
  final String service;      // "afab-backend"
  final String mailStatus;   // "UP" | "DOWN"
}
```
### 6.2 `maintenanceControllerProvider` (`NotifierProvider`)
- State:
  - `bool isMaintenanceActive`
  - `bool isChecking`
  - `HealthStatus? lastHealth`
  - `String? lastError`
  - `DateTime? lastCheckedAt`
  - `int nextRetryInSeconds`
  - `int consecutiveFailures`
- **Polling Timer:** Starts when `MaintenanceScreen` mounts; polls `GET /api/v1/health` with backoff (`10s`, `15s`, `20s`, `30s` max), pauses automatically when `AppLifecycleState.paused`, and triggers immediately on `AppLifecycleState.resumed` or manual `"Check Status Now"`.

---

## 7. API Contracts and Data Flow

- **`GET /api/v1/health`** (Public endpoint — `SecurityConfig` permits without JWT)
  - Response `200 OK`:
    ```json
    {
      "status": "UP",
      "timestamp": "2026-11-25T17:30:00Z",
      "service": "afab-backend",
      "mail": { "status": "UP" }
    }
    ```
  - Note: Do **not** attach expired `Authorization` or trigger `401` refresh logic when calling `/health` (`requireAuth: false` / unauthenticated `Dio` call).
  - **503 Differentiation Rule:**
    - `503` with JSON `code == "AI_SERVICE_UNAVAILABLE"` → handled inside AI Copilot (`AI unavailable` notice), **never** triggers `/maintenance`.
    - `503` with `code == "EMAIL_DELIVERY_FAILED"` or `code == "RATE_LIMIT_UNAVAILABLE"` or `BillingNotConfiguredException` → handled on respective screen, **never** triggers `/maintenance`.
    - `503` from reverse proxy / load balancer (non-AFAB JSON or explicit maintenance code `MAINTENANCE_MODE`) → activates `maintenanceControllerProvider` and navigates to `/maintenance`.

---

## 8. User Interactions and Event Handling

- **Tap `"Check Status Now"`:** Cancels pending countdown, sends immediate `GET /api/v1/health` (timeout `8s`).
  - If `200` and `status == "UP"`: shows `"Service restored!"` toast, clears `isMaintenanceActive`, navigates to `/splash` (if unauthenticated) or pops/returns to previous route.
  - If still failing: updates `lastCheckedAt`, increments backoff countdown, announces status update.
- **Tap `"Contact Support"`:** Calls `launchUrl(Uri(scheme: 'mailto', path: 'support@afab.ai', ...))` with fallback copy-email toast if no mail app is configured on emulator/device.
- **Tap Theme / Language Quick Toggle:** Updates `appearanceProvider` / `localeProvider` immediately.

---

## 9. Validation, Error, Loading, and Empty States

- **Checking In Flight:** Button displays spinner, progress indicator animates smoothly, telemetry shows `"Checking..."`.
- **Unreachable / Timeout:** Displays `"Unable to reach backend server"` with `lastCheckedAt` timestamp; keeps `"Auto-checking in Xs"` active.
- **Partial Outage (`status == "UP"` yet `mail.status == "DOWN"`):** If user navigated manually to `/maintenance` or during mail outage, clearly reports `API: UP`, `Email Delivery: Degraded` and lets the user proceed into the app since core financial features remain operational.

---

## 10. Localization (EN/AR) and RTL Behavior

- **Fixes Web Hardcoded English (`maintenance/page.tsx:48-108`):** Every label is localized in `app_en.arb` and `app_ar.arb`:
  - `maintenanceTitle`: `"We're Under Maintenance"` / `"نحن تحت الصيانة الآن"`
  - `maintenanceSubtitle`: `"We're performing scheduled maintenance to improve your experience and bring you smarter financial insights. We'll be back shortly!"` / `"نجري حالياً صيانة مجدولة لتحسين تجربتك وتقديم رؤى مالية أذكى. سنعود قريباً!"`
  - `maintenanceStatusLabel`: `"System Status"` / `"حالة النظام"`
  - `maintenanceCheckStatus`: `"Check Status Now"` / `"تحقق من الحالة الآن"`
  - `maintenanceAutoRetry`: `"Auto-checking in {seconds}s"` / `"إعادة الفحص تلقائياً خلال {seconds} ث"`
  - `maintenanceContactSupport`: `"Contact Support"` / `"تواصل مع الدعم"`
- Full RTL layout mirroring, directional arrow (`matchTextDirection: true`), Western digits `0-9` for countdowns and timestamps.

---

## 11. Accessibility and Responsive Guardrails

- `SingleChildScrollView` + `SafeArea` ensures zero clipping on `320x568dp` small phones even at `1.4x` font scale.
- Countdown updates do **not** fire `SemanticsService.announce` every second (would spam screen readers); announce only when check transitions state (`Checking` → `Unavailable` or `Restored`).
- Minimum `48dp` button heights and `>= 4.5:1` contrast on status badges.

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **Moved Out of `(dashboard)` Shell (`app/[locale]/(dashboard)/maintenance/page.tsx`):** Web renders the Desktop Sidebar, Header, Notifications Bell, and LifecycleBanners around the maintenance page (causing authenticated API calls to fail in a loop!). Mobile places `/maintenance` at the root `GoRouter` level with **zero** authenticated shell chrome.
2. **Replaced Fake Progress Bar (`maintenance/page.tsx:10-22,70-75`):** Web runs `setInterval` incrementing `65% -> 98%` indefinitely and claims `"30 – 60 Minutes"` statically. Mobile removes all fake progress/ETA claims and polls the real `GET /api/v1/health` endpoint with real timestamps and auto-recovery.
3. **Full EN/AR Localization (`maintenance/page.tsx`):** Web is 100% hardcoded English despite importing `LanguageSwitcher`. Mobile translates all copy into `app_en.arb` and `app_ar.arb`.
4. **Safe `mailto:` Fallback:** Handles devices without a configured email client by copying `support@afab.ai` to clipboard with a toast.

---

## 13. Testing and Verification Plan

- **Unit Tests (`test/unit/app_states/health_polling_test.dart`):**
  - `HealthStatus.fromJson` parses `status`, `timestamp`, `service`, `mail.status`.
  - Backoff sequence `10s -> 15s -> 20s -> 30s` and resets on manual check or recovery.
  - Domain `503` (`AI_SERVICE_UNAVAILABLE`) does **not** activate `isMaintenanceActive`.
- **Widget Tests (`test/widget/app_states/maintenance_screen_test.dart`):**
  - Renders without `NavigationBar` / `NavigationRail` / `ShellAppBar`.
  - Tapping `"Check Status Now"` calls `GET /api/v1/health` and clears maintenance on `200 UP`.
  - Verified in Light/Dark and `en`/`ar` RTL at `320x568` and `768x1024`.

---

## 14. Dependencies and Risks

- **Package Dependencies:** `dio`, `flutter_riverpod`, `go_router`, `url_launcher`, `intl`, `lucide_icons_flutter`.
- **Technical Risks:**
  - **False Positive Outage on Cellular Drop:** A local device offline state (`SocketException` / `connectionError`) must trigger `OfflineBanner` (`APP-04`), **not** `/maintenance` — `/maintenance` is reserved for server-returned `503` outage or explicit maintenance probe results so users don't lose offline context when passing through a tunnel.
