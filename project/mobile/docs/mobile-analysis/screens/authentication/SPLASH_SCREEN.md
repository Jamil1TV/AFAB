# SPLASH_SCREEN (`AUTH-01`)

## 1. Screen Identity
- **Screen ID:** `AUTH-01`
- **Screen Name:** App Splash & Cold-Start Session Restoration
- **Flutter Route Name & Path:** `AppRoutes.splash` — `/splash` (initial `GoRouter` `initialLocation`)
- **Feature Module:** `lib/features/app_states/presentation/splash_screen.dart` (coordinating `lib/features/auth/` & `lib/core/storage/`)
- **Web Equivalent(s):**
  - `Web/project/frontend/proxy.ts` (cookie presence hint check: `afab_session`, `afab_csrf`, `refreshToken`, `accessToken`)
  - `Web/project/frontend/lib/api/client.ts` (`tryRefreshToken()` silent `POST /api/v1/auth/refresh` on hard reload when in-memory `accessToken` is `null`)
  - `Web/project/frontend/app/[locale]/loading.tsx` (`AfabLoader`)
- **Priority:** P0 (Blocking App Entry Gate)
- **Status Parity:** Implemented and Connected on Web (`proxy.ts` + `client.ts`); upgraded on Mobile with Encrypted Cookie Jar pre-check, `GET /api/v1/user/me` hydration, and optional `local_auth` Biometric App Lock.

---

## 2. Purpose
`SplashScreen` is the non-authenticated cold-start gate responsible for:
1. Rendering AFAB's branded entry canvas seamlessly behind the native OS splash transition without any artificial fixed timer (`0 ms` artificial sleep).
2. Inspecting the encrypted `PersistCookieJar` (`EncryptedCookieStorage` backed by `flutter_secure_storage`) for a non-expired `refreshToken` cookie before issuing any network traffic.
3. Silently restoring the short-lived in-memory JWT `accessToken` via `POST /api/v1/auth/refresh` (with `Cookie: refreshToken=...; afab_csrf=...` and `X-CSRF-Token` double-submit header).
4. Hydrating authoritative user & active-workspace state via `GET /api/v1/user/me` (`UserProfileDTO`).
5. Optionally prompting OS biometrics (`local_auth`: Face ID / Touch ID / Android `BiometricPrompt`) when the user has enabled Biometric App Lock in Security Settings (`SECURITY_SETTINGS_SCREEN.md`).
6. Routing deterministically to `/login`, `/verify-email`, `/onboarding`, `/dashboard`, or handling pending deep links (e.g., `/reset-password?token=...`, `/dashboard/settings/subscription?checkout=success&session_id=...`).

---

## 3. Original Web Structure
Web has **no dedicated `/splash` page**. Instead, cold-start session restoration is split across three layers:
1. **Next.js Middleware (`Web/project/frontend/proxy.ts`):**
   - Inspects cookies (`afab_session`, `afab_csrf`, `refreshToken`, `accessToken`) on incoming requests.
   - If accessing `/dashboard`, `/onboarding`, or `/settings` without any session cookie → redirects to `/{locale}/login`.
   - If accessing root `/{locale}` while a session cookie exists → redirects to `/{locale}/dashboard`.
2. **In-Memory Store (`Web/project/frontend/lib/auth-store.ts`):**
   - `inMemoryAccessToken` and `inMemoryCsrfToken` reset to `null` on every browser reload; `afab_user` and `afab_active_business_id` reside in `sessionStorage` (cleared when tab closes).
3. **Silent Refresh (`Web/project/frontend/lib/api/client.ts`):**
   - `fetchRawClient()` checks `requireAuth && !AuthStore.getAccessToken() && !endpoint.includes("/auth/")` and invokes single-flight `tryRefreshToken()` (`POST /api/v1/auth/refresh` with `credentials: "include"` and `X-CSRF-Token`).
   - Retries once after `300 ms` on network error; clears auth and redirects to `/{locale}/login` on `401`/`403`.
4. **Loading Visual (`Web/project/frontend/components/ui/afab-loader.tsx`):**
   - Animated geometric `"A"` monogram (`AfabLoader`) with rising fluid gradient, orbital holographic rings, and optional shimmer text.

---

## 4. Complete Functional Inventory

| # | Capability | Trigger | Behavior & Rules |
|---|---|---|---|
| 1 | **Boot Initialization** | `SplashScreen` mount (`initState` / `splashControllerProvider`) | Reads local non-sensitive prefs (`afab_locale`, `AppearanceSettings`) and checks `EncryptedCookieStorage` for `refreshToken` cookie matching API host & path `/api/v1/auth`. |
| 2 | **Fast-Fail Unauthenticated Path** | No `refreshToken` cookie in jar (or `expires` timestamp already passed) | Skips `POST /auth/refresh` entirely; clears any stale `SessionTokenHolder` / `afab_csrf`; navigates immediately via `context.go('/login')` (or honors unauthenticated deep link like `/reset-password?token=...`). |
| 3 | **Single-Flight Token Refresh** | Valid `refreshToken` cookie exists | Calls `AuthRepository.tryRefreshToken()` inside `AuthInterceptor`'s single-flight lock (`Completer<bool>`). Sends `Cookie: refreshToken=...; afab_csrf=...` and `X-CSRF-Token: <afab_csrf>`. |
| 4 | **Profile & Workspace Hydration** | `POST /auth/refresh` returns `200 AuthResponse` | Stores `accessToken` in RAM (`SessionTokenHolder`), updates `afab_csrf` cookie/holder, sets `activeBusinessId` from `user.businessId`, then calls `GET /api/v1/user/me` to fetch full `UserProfileDTO` (`emailVerified`, `onboardingComplete`, `twoFactorEnabled`, `planTier`, `compactMode`, etc.). |
| 5 | **Optional Biometric App Lock Gate** | `biometricLockEnabled == true` in `flutter_secure_storage` AND session restored | Prompts `LocalAuthentication.authenticate(localizedReason: context.l10n.authBiometricReason, options: AuthenticationOptions(biometricOnly: false))` **before** entering `/dashboard` (allows device PIN/passcode fallback). Provides "Try Again" and "Sign Out & Use Password" buttons if cancelled/failed. |
| 6 | **Verification & Onboarding Gates** | `GET /user/me` succeeds (and biometric check passed or disabled) | 1. If `!user.emailVerified` → `context.go('/verify-email')`.<br>2. Else if `!user.onboardingComplete` → `context.go('/onboarding')`.<br>3. Else → `context.go(pendingDeepLink ?? '/dashboard')`. |
| 7 | **Invalid / Reused Token Recovery** | `POST /auth/refresh` returns `401` (`INVALID_REFRESH_TOKEN`, `REFRESH_TOKEN_REUSE`) or `403` (`CSRF_VALIDATION_FAILED`) | Deletes all cookies from `PersistCookieJar`, clears `SessionTokenHolder` and `activeBusinessId`, clears biometric lock flag only if user explicitly signs out (keeps user preference intact unless account changed), shows brief non-blocking toast (`sessionExpired`), and routes to `/login`. |
| 8 | **Offline / Server Unreachable Handling** | Network timeout, DNS failure, socket exception, or `502`/`504` | **Does NOT wipe valid cookies.** Displays inline retryable offline state with "Retry Connection" button and a secondary "Sign in with another account" link. |
| 9 | **Maintenance / Backend Outage Routing** | `503` (`RATE_LIMIT_UNAVAILABLE` or gateway maintenance) or optional `/api/v1/health` outage | Surfaces retryable service-unavailable banner or routes to `/maintenance` (`MAINTENANCE_SCREEN.md`) without destroying the user's `refreshToken` cookie. |
| 10 | **Deep-Link Preservation** | App cold-started via Universal/App Link or `afab://` | Unauthenticated links (`/reset-password?token=...`, `/verify-email`) bypass auth restoration or run immediately after; authenticated links (`/dashboard/settings/subscription?checkout=success&session_id=...`) are held in `pendingRedirectProvider` until `SplashScreen` completes restoration + biometric check. |

---

## 5. Data Requirements

### 5.1 Local Storage & In-Memory State
| Key / Field | Store | Type | Notes |
|---|---|---|---|
| `accessToken` | `SessionTokenHolder` (RAM only) | `String?` | Never persisted to disk (`04_AUTHENTICATION_AND_SECURITY.md`). |
| `csrfToken` | `SessionTokenHolder` (RAM) + `afab_csrf` in `PersistCookieJar` | `String?` | Echoed in `X-CSRF-Token` header on `/auth/refresh`. |
| `refreshToken` | `PersistCookieJar` → `EncryptedCookieStorage` (`flutter_secure_storage`) | `Cookie` | `HttpOnly`, `Path=/api/v1/auth`, TTL 7d (`604800s`) or 30d (`2592000s` when `rememberMe=true`). |
| `afab_biometric_lock_enabled` | `flutter_secure_storage` | `'true' \| 'false'` | Device-local convenience lock; defaults to `'false'`. |
| `afab_active_business_id` | `flutter_secure_storage` / Riverpod state | `String?` (UUID) | Hydrated from `AuthResponse.user.businessId` or `UserProfileDTO.businessId`. |
| `afab_locale` | `SharedPreferences` | `'en' \| 'ar' \| 'system'` | Loaded before first frame so Splash renders in the user's chosen language & RTL direction. |

### 5.2 Splash State Machine (`SplashState`)
```dart
sealed class SplashState {
  const factory SplashState.checking() = _Checking;
  const factory SplashState.biometricPrompt({required String? failureMessage}) = _BiometricPrompt;
  const factory SplashState.networkError({required String message}) = _NetworkError;
  const factory SplashState.ready({required String targetRoute}) = _Ready;
}
```

### 5.3 Hydrated Models
- `AuthResponse` (`AuthResponse.java`): `accessToken: String`, `csrfToken: String?`, `user: AuthUserDto?`, `requiresTwoFactor: bool`, `verificationEmailSent: bool`.
- `UserProfileDTO` (`UserProfileDTO.java`, 22 fields): `id`, `firstName`, `lastName`, `email`, `phoneNumber`, `avatarUrl`, `emailVerified`, `businessId`, `businessName`, `currency`, `country`, `onboardingComplete`, `createdAt`, `passwordChangedAt`, `twoFactorEnabled`, `lastLoginAt`, `lastLoginIp`, `enableAiInsights`, `compactMode`, `autoCategorizeTransactions`, `showTips`, `planTier`.

---

## 6. API Integration

| Step | Endpoint | Auth / Headers | Request | Response / Mapping | Error Handling |
|---|---|---|---|---|---|
| 1 | `POST /api/v1/auth/refresh` | `Cookie: refreshToken=...; afab_csrf=...`<br>`X-CSRF-Token: <afab_csrf>`<br>*(Do NOT send `Origin` header from native Dio)* | Empty body (`Content-Type: application/json`) | `200 AuthResponse` + `Set-Cookie: refreshToken=...` (rotated) + `Set-Cookie: afab_csrf=...` | `401 INVALID_REFRESH_TOKEN` / `REFRESH_TOKEN_REUSE` / `403 CSRF_VALIDATION_FAILED` → wipe jar + RAM → `/login`.<br>`429 RATE_LIMITED` (30/min) → wait/retry UI.<br>Network error → keep cookies, show Retry UI. |
| 2 | `GET /api/v1/user/me` | `Authorization: Bearer <accessToken>`<br>Optional `X-Business-Id` | None | `200 UserProfileDTO` (22 fields) | `401` → wipe jar + RAM → `/login`.<br>`5xx`/Network → show Retry UI. |

> **Backend Contract Verification (`AuthController.java:156-192` & `AuthCookieService.java:127-154`):**
> `verifyCsrfAndOrigin()` allows empty `Origin` (native mobile) while strictly validating `X-CSRF-Token == afab_csrf` cookie using constant-time `MessageDigest.isEqual`. Every `/auth/refresh` call rotates the refresh token in the same `token_family_id`; concurrent calls without single-flight locking trigger `401 REFRESH_TOKEN_REUSE` and revoke the whole session family.

---

## 7. Modal, Drawer and Dialog Inventory
- **Biometric Unlock Prompt (OS System Sheet):** Invoked via `local_auth` (`Face ID` on iOS, `BiometricPrompt` on Android). No custom PIN dialog is built — OS device credential fallback (`biometricOnly: false`) is used when hardware biometrics are unavailable or locked out.
- **Sign-Out Confirmation Dialog (on Biometric Failure Escape):** If the user taps "Sign Out & Use Password" from the locked biometric state, execute `POST /api/v1/auth/logout` (best-effort) + wipe `PersistCookieJar` & `SessionTokenHolder` and navigate to `/login`.

---

## 8. Mobile Adaptation
- **Native Splash Continuity:** Configure `flutter_native_splash` (or native Android `SplashScreen` API / iOS `LaunchScreen.storyboard`) using the exact AFAB icon and `#F8F9FB` (light) / `#060813` (dark) background so the transition to Flutter `SplashScreen` has zero visual flash.
- **No Marketing Landing Page:** Unlike Web (`/[locale]/page.tsx`), Mobile never renders a marketing page; unauthenticated users land directly on `/login`.
- **Single-Flight Guard:** `SplashController` shares the same `AuthInterceptor.tryRefreshToken()` single-flight `Completer<bool>` so if a deep link or background check triggers simultaneously, two parallel `/auth/refresh` calls can never race and trigger `REFRESH_TOKEN_REUSE`.
- **Resume Biometric Re-Lock (Companion Behavior):** While `SplashScreen` gates cold start, `AppLifecycleListener` (`onPause` → `onResume` after configurable grace e.g. 60s) can route through a biometric lock overlay without wiping tokens.

---

## 9. Visual Design
- **Background:** Full-bleed `AfabColors.background` (`#F8F9FB` light / `#060813` dark `midnight` or active dark surface preset).
- **Centerpiece:**
  - `AfabLoader(size: AfabLoaderSize.lg)` (`80x80dp`) centered vertically (slightly above optical center `-0.08` Y alignment), displaying the animated geometric `"A"` monogram + orbital rings.
  - Below loader (`24dp` spacing): `"AFAB"` wordmark (`28sp`, Bold, `Poppins`/`Cairo`, `AfabColors.textPrimary`) + subtle status subtitle (`13sp`, `AfabColors.textMuted`, e.g., `Restoring your workspace...`).
- **Biometric Locked State:** Replaces status text with lock icon (`Icons.lock_outline` / `LucideIcons.shieldCheck`), `"AFAB is locked"` title, primary `AfabButton` (`"Unlock with Biometrics"`), and text button (`"Use password instead"`).
- **Offline / Error State:** Displays an `AfabCard` (`maxWidth: 360dp`, centered) with `LucideIcons.wifiOff` icon badge, concise localized error description, primary `"Retry"` `AfabButton`, and secondary `"Back to Sign In"` link.
- **Footer:** Subtle version string (`vX.Y.Z`) at bottom inside `SafeArea` (`11sp`, `AfabColors.textMuted`).

---

## 10. Localization
- **Supported Locales:** `en` (LTR), `ar` (RTL). Read `afab_locale` from `SharedPreferences` synchronously/at bootstrap before building `SplashScreen` so loader subtitle, error messages, and biometric reason match the user's preferred language immediately.
- **ARB Keys Required (New Mobile-Specific Keys):**
  - `splashRestoringSession`: `"Restoring your workspace..."` / `"جاري استعادة مساحة عملك..."`
  - `splashBiometricTitle`: `"Unlock AFAB"` / `"فتح قفل AFAB"`
  - `splashBiometricReason`: `"Authenticate to access your AFAB financial workspace"` / `"تحقق من هويتك للوصول إلى مساحتك المالية في AFAB"`
  - `splashBiometricUnlockBtn`: `"Unlock"` / `"فتح القفل"`
  - `splashUsePasswordBtn`: `"Sign in with password"` / `"تسجيل الدخول بكلمة المرور"`
  - `splashOfflineTitle`: `"Connection unavailable"` / `"تعذر الاتصال بالخادم"`
  - `splashRetryBtn`: `"Retry"` / `"إعادة المحاولة"`
  - `splashSessionExpired`: `"Your session expired. Please sign in again."` / `"انتهت صلاحية جلستك. يرجى تسجيل الدخول مجدداً."`
- **RTL Rules:** Center-aligned layout mirrors cleanly; any inline action buttons use `EdgeInsetsDirectional` and `matchTextDirection: true` on directional icons.

---

## 11. Animation and Interaction Design
- **Monogram Animation (`AfabLoader`):**
  - Replicates `afab-loader.tsx`: rising fluid gradient wave inside the clipped `"A"` path (`2.2s` ease-in-out repeat), diagonal shimmer sweep (`1.8s`), pulsing core dot, perimeter laser dash, and dual counter-rotating orbital rings (`4s` CW, `6s` CCW).
  - **Reduced Motion (`MediaQuery.disableAnimationsOf(context)`):** Freezes orbital rotation & shimmer and renders a crisp static gradient `"A"` monogram with a minimal accessible `CircularProgressIndicator.adaptive()`.
- **Route Exit Transition:** `220 ms` fade cross-transition into `/login` or `/dashboard` (no jarring pop).
- **Haptics:** Light impact (`HapticFeedback.lightImpact()`) on biometric unlock success; medium impact on unlock failure or retry tap.

---

## 12. Accessibility
- `Semantics(label: context.l10n.splashRestoringSession, liveRegion: true)` on the loader status block so VoiceOver / TalkBack announces progress without repetitive polling announcements.
- All retry / biometric / sign-out buttons meet minimum `48x48 dp` touch target (`AfabButton` default).
- High-contrast text (`>= 4.5:1`) verified on both `#F8F9FB` light and `#060813` / `#000000` OLED dark backgrounds.
- Respects OS font scaling (`0.85x..1.45x` clamped) inside offline/biometric cards without clipping.

---

## 13. Acceptance Criteria
1. Cold start with **no `refreshToken` cookie** transitions directly to `/login` in `< 150 ms` without issuing any network call to `/auth/refresh`.
2. Cold start with a **valid `refreshToken` cookie** sends `POST /api/v1/auth/refresh` with `Cookie: refreshToken=...; afab_csrf=...` and `X-CSRF-Token` header (and **no** `Origin` header), stores the returned `accessToken` strictly in RAM, hydrates `GET /api/v1/user/me`, and routes to `/verify-email`, `/onboarding`, or `/dashboard` according to `emailVerified` and `onboardingComplete`.
3. Cold start with **expired / revoked / reused refresh token (`401` or `403`)** wipes `PersistCookieJar` and RAM tokens and routes to `/login` with a localized session-expired message.
4. Cold start while **offline** preserves the encrypted cookies in `PersistCookieJar` and presents a working Retry UI that successfully restores the session once connectivity returns.
5. When **Biometric App Lock** is enabled, `/dashboard` is never visible before `local_auth` succeeds; cancelling biometrics keeps the user on the lock gate with Retry and Password Sign-Out options.
6. No `accessToken` or `refreshToken` is ever written to `SharedPreferences`, plaintext logs, or analytics events.

---

## 14. Dependencies and Risks
- **Dependencies:**
  - `dio: ^5.9.2`, `dio_cookie_manager: ^3.4.0`, `cookie_jar: ^4.0.9`, `flutter_secure_storage: ^10.2.0`
  - `local_auth: ^3.0.0`, `go_router: ^18.1.3`, `flutter_riverpod: ^3.5.0`
- **Risks & Mitigations:**
  - **Risk:** In `local` dev (`http://10.0.2.2:8080`), `cookieSecure=true` in Spring Boot would block `PersistCookieJar` from sending `refreshToken` over HTTP. **Mitigation:** Ensure backend runs with `local` profile (`afab.auth.cookie.secure=false`) or use HTTPS in staging/prod; document clearly in `core/config/env.dart`.
  - **Risk:** Android Keystore `AEADBadTagException` after OS backup/restore on some OEMs can make `flutter_secure_storage` throw on first read. **Mitigation:** Wrap `EncryptedCookieStorage` reads in a `try/catch` that safely clears corrupted secure-storage keys and falls back to `/login` instead of crashing at splash.
  - **Risk:** Concurrent `/auth/refresh` calls on cold start + deep link trigger backend `REFRESH_TOKEN_REUSE` (`AuthService.java:379-391`), revoking the token family. **Mitigation:** Route all refresh operations exclusively through the single-flight `Completer` in `AuthInterceptor`.
