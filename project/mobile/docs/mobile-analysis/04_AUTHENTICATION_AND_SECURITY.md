# 04 — Authentication, Session Security & Multi-Tenant Isolation

> **Critical Reference:** Verified against `AuthController.java`, `AuthService.java`, `AuthCookieService.java`, `JwtService.java`, `JwtAuthenticationFilter.java`, `TotpService.java`, `SecurityConfig.java`, `CorsConfig.java`, `CurrentBusinessService.java`, `BusinessAccessGuard.java`, `UserAccountService.java`, and `Web/project/frontend/lib/api/client.ts` + `auth-store.ts`.

---

## 1. Current Backend Authentication & Cookie Architecture

| Mechanism | Backend Implementation (`com.afab.auth` & `com.afab.config`) |
|---|---|
| **Access Token** | HMAC-SHA JWT (`jjwt 0.12.6`), key >= 256 bits (`JWT_SECRET`). TTL: **15 minutes** (`900,000 ms`). Returned in `AuthResponse.accessToken` JSON. Sent via `Authorization: Bearer <token>`. |
| **Refresh Token** | Opaque random secret stored **SHA-256 hashed** in `refresh_tokens` with `token_family_id`. TTL: **7 days** default (`604,800,000 ms`), **30 days** when `rememberMe = true`. **Marked `@JsonIgnore` in `AuthResponse`** — transported **exclusively** via `Set-Cookie: refreshToken=...; HttpOnly; SameSite=Lax; Path=/api/v1/auth` (`Secure=true` in prod, `false` in `local`). |
| **CSRF Protection** | Double-submit nonce (`afab_csrf`, 32-byte random Base64URL, `HttpOnly=false`, `Path=/`, `SameSite=Lax`). Returned both as `Set-Cookie: afab_csrf=...` AND in `AuthResponse.csrfToken`. Validated in constant time (`MessageDigest.isEqual`) on `/auth/refresh` and `/auth/logout` (when refresh cookie is present) via `X-CSRF-Token` header == `afab_csrf` cookie. |
| **Origin Check** | `AuthCookieService.verifyCsrfAndOrigin()` inspects `Origin` header **only if non-blank**. When absent (native HTTP clients), Origin check passes; when present, checks allowlist. |
| **Rotation & Reuse Detection** | Every `POST /auth/refresh` issues a new refresh token in the same `token_family_id` and revokes the previous one. Reusing a revoked token revokes the entire family and returns `401 REFRESH_TOKEN_REUSE`. |
| **2FA Challenge** | `POST /auth/login` with 2FA enabled returns `{ requiresTwoFactor: true, twoFactorToken }` (5-min JWT with `type="2FA_CHALLENGE"`, rejected for normal endpoints). Completed via `POST /auth/2fa/verify-login` (6-digit TOTP `+/- 30s` window or 1-time SHA-256 backup code). |
| **Lockout & Rate Limits** | 5 consecutive wrong passwords lock account for **15 minutes**. Redis Lua `DistributedRateLimiter` enforces IP+email quotas (`login=10/m`, `register=5/m`, `forgot-password=5/m`, `verify-email=10/m`, `otp=10/m`, `reset-password=5/m`, `refresh=30/m`). |

---

## 2. Native Flutter Session & Cookie Architecture (No Backend Rewrite Required)

Flutter mobile clients do not run inside a browser sandbox, so `dio` does not persist cookies automatically unless paired with a cookie manager. The design below mirrors the Web client's exact security guarantees **without weakening CSRF or storing refresh tokens in plaintext**:

1. **In-Memory Access Token (`SessionTokenHolder`):**
   - Short-lived `accessToken` (15m) is held **strictly in Dart RAM** inside a Riverpod state/holder object. Never written to `SharedPreferences`, Hive, SQLite, or unencrypted files.
2. **Encrypted Persistent Cookie Jar (`EncryptedCookieStorage` + `PersistCookieJar`):**
   - `dio ^5.9.2` + `dio_cookie_manager ^3.4.0` + `cookie_jar ^4.0.9` with a custom `Storage` implementation backed by `flutter_secure_storage ^10.2.0` (Android Keystore AES-GCM `EncryptedSharedPreferences`/Keystore; iOS Keychain `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
   - Automatically captures `Set-Cookie: refreshToken=...` (`Path=/api/v1/auth`) and `Set-Cookie: afab_csrf=...` (`Path=/`) on `/login`, `/register`, `/2fa/verify-login`, and `/refresh`, and replays them automatically on `/auth/refresh` and `/auth/logout`.
   - Note: In `local` dev (`http://10.0.2.2:8080` or LAN IP), `cookieSecure=false` lets the cookie jar attach `refreshToken` over HTTP; in staging/production HTTPS, `Secure=true` works seamlessly.
3. **CSRF Double-Submit Echo:**
   - On `/auth/refresh` and `/auth/logout`, `AuthInterceptor` reads `afab_csrf` from `PersistCookieJar` (or in-memory fallback from last `AuthResponse.csrfToken`) and attaches `X-CSRF-Token: <value>`.
   - Mobile requests **do NOT send a spoofed `Origin` header** — `AuthCookieService.verifyCsrfAndOrigin()` permits empty/absent `Origin` and validates the double-submit cookie+header pair cleanly.
4. **Single-Flight Refresh Lock (Preventing Token-Family Revocation):**
   - Parallel API calls failing with `401` share a single `Completer<bool>? _inFlightRefresh` inside `AuthInterceptor`.
   - Because backend refresh tokens rotate on every use and trigger `401 REFRESH_TOKEN_REUSE` (revoking the entire family) if the same old token is presented twice concurrently, the single-flight lock is **mandatory**.
   - Requests queued behind `_inFlightRefresh` await its `Future<bool>` and retry with the newly updated in-memory `accessToken`.
5. **Cold-Start Session Restoration (`SplashScreen`):**
   - App checks if `EncryptedCookieStorage` contains a non-expired `refreshToken` cookie for the API host.
   - If absent → route immediately to `/login` (no wasted network round-trip).
   - If present → call `POST /api/v1/auth/refresh` with cookie jar + `X-CSRF-Token`. On success → restore `SessionState`, fetch `GET /user/me` (routing to `/verify-email` or `/onboarding` if incomplete, else `/dashboard`). On `401`/`403` → clear jar & route to `/login`. On network timeout/offline → show retryable offline/session state rather than wiping valid cookies.
6. **Logout & Password Change Cleanup:**
   - `POST /auth/logout` (with cookie + `X-CSRF-Token`) + `SessionTokenHolder.clear()` + `cookieJar.deleteAll()` + clear active business ID + reset Riverpod caches + clear image/API caches.
   - On `POST /auth/change-password` (`200 OK`), **immediately execute full local sign-out** and route to `/login` (fixing the Web bug in `SecuritySettings.tsx` where stale JWT remained in memory).
7. **Optional Biometric App Lock (`local_auth ^3.0.0`):**
   - Device-local convenience lock (Face ID / Touch ID / Android BiometricPrompt) gating app unlock on resume/cold start when enabled in Security Settings, backed by a boolean flag in `flutter_secure_storage`. It wraps access to the encrypted session rather than replacing backend JWT/refresh authentication.

---

## 3. Multi-Tenant Business Isolation Rules

AFAB enforces workspace isolation strictly server-side (`CurrentBusinessService.java`, `BusinessAccessGuard.java`):

| Rule | Implementation | Mobile Requirement |
|---|---|---|
| **Workspace Header** | Client sends `X-Business-Id: <uuid>` on every authenticated business-scoped request. | Attach active workspace UUID via `TenantInterceptor` on all non-`/auth/` requests; store `activeBusinessId` per user in secure/app state. |
| **Role Matrix** | `OWNER`, `ADMIN`, `MEMBER` in `business_members`. `PUT /business/{id}` & `POST /currencies/business/change` require `OWNER`/`ADMIN`. `DELETE /business/{id}`, `POST /transfer-ownership`, `PUT /business/allocations*` require `OWNER`. | Display role badge in `BusinessSwitcherSheet`; hide/disable Owner-only & Admin-only controls when user role lacks permission. |
| **Plan Workspace Caps** | `FREE = 1`, `PLUS = 3`, `PRO = 5` **owned editable** businesses (`BusinessAllocationService`). | Show accurate `ownedEditableCount / editableLimit` (fixing Web bug that counted `MEMBER`/`ADMIN` workspaces). |
| **`READ_ONLY` Enforcement** | Excess businesses on downgrade become `accessMode = "READ_ONLY"`, `editable = false`. Backend throws `403 BUSINESS_READ_ONLY` on writes AND on `GET /business/mine`, `GET /business/{id}`, `GET /business/{id}/members`, `PUT /business/{id}/switch`. | On `403 BUSINESS_READ_ONLY`, clear invalid `activeBusinessId`, refresh `/business`, show global `BusinessReadOnlySheet` linking to `BusinessAllocationSheet` / `PlansScreen`. Never cache across businesses! |
| **Cache Partitioning** | All cached queries/providers must key by `(userId, activeBusinessId)` and invalidate completely on switch or logout. | Riverpod `activeBusinessIdProvider` watched by all business-scoped providers so switching business atomically resets & refetches state. |

---

## 4. Minimal Backend Compatibility Proposals (Documented Only — NOT Implemented)

While core login/refresh/finance APIs work out-of-the-box with the encrypted cookie jar, **5 minor backend issues** affect mobile UX and are proposed for backend review:

1. **Active Session Detection & "Log Out Other Sessions" (`UserController.java` + `application.yml`):**
   - **Problem:** `refreshToken` cookie has `Path=/api/v1/auth`, so neither browsers nor `dio_cookie_manager` send it to `GET /api/v1/user/me/sessions` or `DELETE /api/v1/user/me/sessions`. Thus `currentSession` is always `false`, and "Log Out All Other Sessions" revokes the current session too.
   - **Minimal Fix:** Add an optional `X-Refresh-Family` or derive current session from a JWT `sid` (session/family ID) claim embedded into the access token during login/refresh, allowing `GET /user/me/sessions` and `DELETE /user/me/sessions` to identify the current session without widening the refresh cookie path.
2. **Stripe Checkout & Billing Portal Mobile Return URL (`StripeBillingService.java`):**
   - **Problem:** `sanitizeReturnPath` rejects non-`/dashboard` paths and `://` schemes, returning only `{frontendUrl}/{locale}/dashboard/settings/subscription?...`.
   - **Minimal Fix (Zero-Backend Option vs Minimal Backend Option):** Mobile uses Universal Links (iOS) / App Links (Android) on `{frontendUrl}/{locale}/dashboard/settings/subscription` OR `flutter_custom_tabs` + web bridge page; alternatively, allow an allowlisted `afab://billing/return` redirect URI when `client=mobile` is explicitly validated.
3. **Business Logo Upload Size (`Business.java` / `UpdateBusinessRequest.java`):**
   - **Problem:** `logoUrl` is `@Size(max=500)` (`VARCHAR(500)`), rejecting base64 uploads (`BusinessProfile.tsx` bug).
   - **Minimal Fix:** Add `POST /api/v1/business/{id}/logo` backed by `MinioStorageService` (matching `ReceiptController`), or keep URL-only input on mobile until implemented.
4. **Account Deletion Deadlock on `READ_ONLY` Owned Businesses (`UserAccountService.java` vs `BusinessController.java`):**
   - **Problem:** Owned `READ_ONLY` businesses block account deletion (`409`), yet `DELETE /api/v1/business/{id}` blocks archiving `READ_ONLY` businesses (`403 BUSINESS_READ_ONLY`).
   - **Minimal Fix:** Allow `OWNER` to archive a `READ_ONLY` business during deletion preflight, or allow `DELETE /user/me` when blocking businesses are solely `READ_ONLY`.
5. **Cross-Device Sync for Appearance & Wet Signatures:**
   - **Problem:** `UpdateUserRequest` ignores `appearanceSettings` and has no signature endpoint.
   - **Minimal Fix (Optional P3):** Add `appearance_json` column on `users` and `signature_object_key` on `businesses`. Until then, mobile persists both locally in `SharedPreferences` / secure app storage and marks them device-local.
