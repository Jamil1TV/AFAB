# TWO_FACTOR_CHALLENGE_SCREEN (`AUTH-03`)

## 1. Screen Identity
- **Screen ID:** `AUTH-03`
- **Screen Name:** Two-Factor Authentication Login Challenge
- **Flutter Route Name & Path:** `AppRoutes.twoFactor` — `/two-factor` (receives transient `TwoFactorRouteArgs { twoFactorToken, rememberMe, email }` via `GoRouter.extra`)
- **Feature Module:** `lib/features/auth/presentation/two_factor_challenge_screen.dart`
- **Web Equivalent(s):**
  - `Web/project/frontend/app/[locale]/(auth)/login/page.tsx` (lines `157–280`, conditional `requiresTwoFactor` view inside `LoginPage`)
- **Priority:** P0 (Core Security Flow)
- **Status Parity:** Implemented and Connected on Web (`POST /api/v1/auth/2fa/verify-login`); promoted on Mobile to a dedicated route (`AUTH-03`) with explicit 5-minute challenge token expiry handling and clipboard paste support.

---

## 2. Purpose
`TwoFactorChallengeScreen` completes step 2 of authentication when `POST /api/v1/auth/login` returns `{ requiresTwoFactor: true, twoFactorToken }`. It lets the user enter either:
- A **6-digit TOTP code** from Google Authenticator, Microsoft Authenticator, 1Password, or Authy (`+/- 30s` window validated by `TotpService`), OR
- An **8-character emergency backup recovery code** (`XXXX-XXXX` Base32 format, single-use SHA-256 verified by `AuthService.verifyAndConsumeBackupCode`).

On success, it establishes the full authenticated session (RAM `accessToken` + encrypted `refreshToken` & `afab_csrf` cookies respecting `rememberMe`) and routes to `/verify-email`, `/onboarding`, or `/dashboard`.

---

## 3. Original Web Structure
In `Web/project/frontend/app/[locale]/(auth)/login/page.tsx` (lines `157–280`):
1. **Header Icon Badge:** `56x56px` rounded-2xl container (`bg-[var(--primary)]/10`, `border-[var(--primary)]/20`) with `ShieldCheck` icon.
2. **Title & Subtitle:** `twoFactorTitle` (`"Two-Factor Authentication"`) + `twoFactorSubtitle` (`"Enter the 6-digit code from your authenticator app to complete sign-in."`).
3. **Inline Error Alert:** Red error banner (`error`) when `INVALID_2FA_CODE` or `INVALID_2FA_REQUEST` is returned.
4. **Mode A — TOTP 6-Digit OTP (`!useBackupCode`):**
   - Label `twoFactorEnterCode` (`"Authentication Code"`).
   - `InputOTP` (`maxLength={6}`, 6 individual `InputOTPSlot` boxes, autoFocus).
5. **Mode B — Backup Recovery Code (`useBackupCode`):**
   - Label `backupCodeLabel` (`"Backup Recovery Code"`).
   - `KeyRound` icon + monospaced uppercase input `#login-2fa-backup`, placeholder `backupCodePlaceholder` (`"e.g. ABCD-1234"`).
6. **Mode Toggle Link:** `"Use emergency backup recovery code"` ↔ `"Use 6-digit authenticator code"`.
7. **Submit Button (`#login-2fa-submit`):** Disabled unless `code.trim().length >= (useBackupCode ? 8 : 6)`; displays `AfabLoader(size="xs")` while loading or `twoFactorVerifyButton` (`"Verify & Sign In"`).
8. **Back Link:** `ArrowLeft` + `backToLogin` (`"Back to login"`), resets `requiresTwoFactor = false` and clears `twoFactorCode`.

---

## 4. Complete Functional Inventory

| # | Control / Feature | Behavior & Rules |
|---|---|---|
| 1 | **Guard on Missing Challenge Token** | If `/two-factor` is opened without a valid `twoFactorToken` (e.g. process death or manual deep-link), immediately redirect via `context.go('/login')`. |
| 2 | **6-Digit TOTP Mode (Default)** | Six individual `48x54dp` numeric digit cells arranged strictly **LTR** (`Directionality(textDirection: TextDirection.ltr)` even in Arabic RTL). Supports:<br>- Single-digit auto-advance<br>- Backspace focus retreat<br>- Full 6-digit clipboard paste from authenticator app<br>- OS SMS/OTP autofill hint (`AutofillHints.oneTimeCode`)<br>- Optional auto-submit when the 6th digit is entered (with double-submit lock). |
| 3 | **Backup Recovery Code Mode** | Toggling switches to single `AfabTextField` with `LucideIcons.keyRound`, monospace uppercase input, forced LTR, `hintText: context.l10n.backupCodePlaceholder` (`"e.g. ABCD-1234"`).<br>- **Important Backend Rule (`AuthService.java:278` & `TotpService.java:44`):** Backend generates codes as `XXXX-XXXX` (8 Base32 chars + hyphen = 9 chars) and hashes `code.replace(" ", "").toUpperCase(Locale.ROOT)`. Thus the hyphen `-` MUST NOT be stripped if the user enters `ABCD-1234`, and button enablement allows length `>= 8` (matching Web `twoFactorCode.trim().length >= 8`). |
| 4 | **Mode Toggle Button** | Clears current `code` and inline `error` when switching between TOTP (`6` digits) and Backup Code (`XXXX-XXXX`). |
| 5 | **5-Minute Challenge Token Expiry Handling** | Backend `JwtService.generateTwoFactorChallengeToken()` sets `expiration = 5 * 60 * 1000L` (5 minutes). Mobile tracks a local 5-minute countdown indicator (or detects `400 INVALID_2FA_REQUEST` when expired) and prompts the user to tap `"Back to login"` to re-authenticate. |
| 6 | **Submit (`POST /api/v1/auth/2fa/verify-login`)** | Sends `{ twoFactorToken, code: code.trim(), rememberMe }`. On `200`: stores `accessToken` in RAM, `PersistCookieJar` captures `refreshToken` (7d or 30d per `rememberMe`) & `afab_csrf`, sets `activeBusinessId`, and routes to `/verify-email`, `/onboarding`, or `/dashboard`. |
| 7 | **Invalid Code Error Handling** | On `401 INVALID_2FA_CODE`: clears/shakes OTP boxes (haptic feedback + inline error banner `"Invalid authentication code or backup recovery code."`), keeps `twoFactorToken` intact so user can retry immediately. |
| 8 | **Back to Login** | Clears `twoFactorToken` and `code` from memory and navigates back to `/login`. |

---

## 5. Data Requirements

### 5.1 Route Arguments (`TwoFactorRouteArgs`)
```dart
class TwoFactorRouteArgs {
  final String twoFactorToken; // Transient 5-min JWT (RAM only; never persisted)
  final bool rememberMe;
  final String? maskedEmail;   // Optional display hint
}
```

### 5.2 Request DTO (`TwoFactorVerifyRequest.java`)
```dart
@freezed
class TwoFactorVerifyRequest with _$TwoFactorVerifyRequest {
  const factory TwoFactorVerifyRequest({
    required String twoFactorToken, // @NotBlank
    required String code,           // @NotBlank (6-digit TOTP or XXXX-XXXX backup)
    @Default(false) bool rememberMe,
  }) = _TwoFactorVerifyRequest;
}
```

### 5.3 Response DTO
Same `AuthResponse` as `LOGIN_SCREEN.md`, now with `accessToken`, `csrfToken`, `user`, and `Set-Cookie` headers (`refreshToken`, `afab_csrf`).

---

## 6. API Integration

| Endpoint | Method | Auth / Rate Limit | Request Body | Responses & Errors |
|---|---|---|---|---|
| `/api/v1/auth/2fa/verify-login` | `POST` | Public (gated by signed 5-min `twoFactorToken`)<br>Rate Limit: `OTP_VERIFY` = **10 req/min** per IP | `{ "twoFactorToken": "...", "code": "123456", "rememberMe": true/false }` | - `200 OK`: `AuthResponse` + `Set-Cookie: refreshToken` (`7d` or `30d`), `afab_csrf`<br>- `400 INVALID_2FA_REQUEST`: `"Two-factor authentication session expired or invalid. Please login again."` (or `"Two-factor authentication is not enabled..."`) → disable retry & prompt Back to Login<br>- `401 INVALID_2FA_CODE`: wrong TOTP or already-used/wrong backup code<br>- `403 ACCOUNT_DISABLED`: inactive account<br>- `429 RATE_LIMITED`: too many OTP attempts |

---

## 7. Modal, Drawer and Dialog Inventory
- **None.** All state changes (TOTP ↔ Backup Code toggle, error alert, expiry state) occur inline within the screen.

---

## 8. Mobile Adaptation
- **Dedicated Push Route:** While Web swaps an inline panel inside `/login`, Mobile uses a dedicated GoRouter route `/two-factor` so Android system back / iOS edge swipe cleanly returns to `/login` and resets the challenge state.
- **TOTP Paste & Authenticator App Switching:** Users frequently switch out of AFAB to Google Authenticator/Authy and return to paste the 6-digit code.
  - Preserve `TwoFactorRouteArgs` in route state across brief OS app-switching (while never writing `twoFactorToken` to disk).
  - Support pasting a 6-digit string (stripping spaces like `"123 456"` → `"123456"`) into any of the 6 OTP boxes.
- **Keyboard Ergonomics:**
  - TOTP mode: `TextInputType.number`, `FilteringTextInputFormatter.digitsOnly`.
  - Backup mode: `TextInputType.visiblePassword` / `TextInputType.text`, `autocorrect: false`, `textCapitalization: TextCapitalization.characters`.

---

## 9. Visual Design
- **Card Container:** `AfabCard(maxWidth: 440dp)` centered inside `SafeArea` + scrollable body.
- **Icon Tile:** `56x56dp` rounded (`16dp` radius) container with `primary.withValues(alpha: 0.10)` fill, `1px primary.withValues(alpha: 0.20)` border, centered `LucideIcons.shieldCheck` (`28dp`, `primary`).
- **6-Digit OTP Slots:** 6 equal boxes (`44x52dp` on compact phones `< 360dp`, `48x56dp` standard), `12dp` radius, `1.5–2dp` `primary` border on active slot, `danger` border on error, `surfaceInset` fill when empty, `surface` fill when populated, `20sp` Bold tabular digits.
- **Countdown Pill (Enhancement):** Subtle muted badge below subtitle showing remaining challenge session time (e.g., `4:52` using `FontFeature.tabularFigures()`), turning `warning` under `60s` and prompting re-login at `0:00`.
- **Primary Button:** `AfabButton.primary` (`"Verify & Sign In"` + directional `ArrowRight`), disabled when code incomplete.

---

## 10. Localization
Keys from `Web/project/frontend/messages/{en,ar}/auth.json`:
- `twoFactorTitle`: `"Two-Factor Authentication"` / `"المصادقة الثنائية (2FA)"`
- `twoFactorSubtitle`: `"Enter the 6-digit code from your authenticator app to complete sign-in."` / `"أدخل الرمز المكون من 6 أرقام من تطبيق المصادقة لإتمام تسجيل الدخول."`
- `twoFactorEnterCode`: `"Authentication Code"` / `"رمز المصادقة"`
- `useBackupCode`: `"Use emergency backup recovery code"` / `"استخدام رمز استرداد الطوارئ الاحتياطي"`
- `useTotpCode`: `"Use 6-digit authenticator code"` / `"استخدام رمز المصادقة المكون من 6 أرقام"`
- `backupCodeLabel`: `"Backup Recovery Code"` / `"رمز الاسترداد الاحتياطي"`
- `backupCodePlaceholder`: `"e.g. ABCD-1234"` / `"مثال: ABCD-1234"`
- `twoFactorVerifyButton`: `"Verify & Sign In"` / `"تحقق وتسجيل الدخول"`
- `errorInvalid2FaCode`: `"Invalid authentication code or backup recovery code."` / `"رمز المصادقة أو رمز الاسترداد الاحتياطي غير صالح."`
- `backToLogin`: `"Back to login"` / `"العودة لتسجيل الدخول"`
- **New Mobile Key:** `twoFactorSessionExpired`: `"Two-factor session expired. Please sign in again."` / `"انتهت صلاحية جلسة المصادقة الثنائية. يرجى تسجيل الدخول مجدداً."`
- **LTR Override:** Both the 6-box OTP row and Backup Code input MUST enforce `TextDirection.ltr` in Arabic RTL.

---

## 11. Animation and Interaction Design
- **Screen Transition:** `250 ms` horizontal slide + fade (`SlideTransition` mirrored for RTL).
- **Mode Switch (`TOTP` ↔ `Backup`):** `AnimatedSwitcher` (`220 ms` fade + size transition).
- **Slot Focus & Pop:** Active OTP box scales `1.0 → 1.05` (`150 ms`) with `primary` ring.
- **Error Shake:** Horizontal damped shake (`±10 dp`, `400 ms`) on `401 INVALID_2FA_CODE` + `HapticFeedback.heavyImpact()`.
- **Reduced Motion:** Disables shake/scale transitions when `MediaQuery.disableAnimationsOf(context)` is true.

---

## 12. Accessibility
- Expose the 6-digit OTP entry to screen readers cleanly (either a single hidden/accessible `TextField` backing 6 visual cells so TalkBack/VoiceOver announces `"Authentication Code, 6 digits, 3 of 6 entered"` instead of 6 separate confusing inputs, or explicit `"Digit 1 of 6"` semantics).
- Error banner marked `liveRegion: true`.
- Minimum `48dp` height on `"Use emergency backup recovery code"` and `"Back to login"` touch targets.

---

## 13. Acceptance Criteria
1. Entering a valid 6-digit TOTP code completes login (`POST /auth/2fa/verify-login`), persists `refreshToken` (respecting `rememberMe`), and routes to `/verify-email`, `/onboarding`, or `/dashboard`.
2. Toggling to Backup Recovery Code and entering a valid `XXXX-XXXX` code authenticates and consumes that single-use code on the backend.
3. Pasting a 6-digit code (with or without spaces) fills all 6 OTP slots and submits cleanly.
4. Entering an invalid code displays `errorInvalid2FaCode` without discarding `twoFactorToken`, allowing immediate retry.
5. Submitting after the 5-minute `twoFactorToken` expires handles `400 INVALID_2FA_REQUEST` cleanly and directs the user back to `/login`.
6. OTP boxes and backup code input remain strictly LTR in Arabic (`ar`) mode.

---

## 14. Dependencies and Risks
- **Dependencies:** `flutter_riverpod`, `go_router`, `dio`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  - **Risk:** User strips the hyphen from `ABCD-1234` vs keeping it — `TotpService.generateBackupCodes()` generates `XXXX-XXXX` with a hyphen at index 4, and `AuthService` hashes `c.replace(" ", "").toUpperCase(Locale.ROOT)` (keeping `-`). **Mitigation:** Do not strip `-` on input; keep placeholder `"e.g. ABCD-1234"` and instruct users to enter the code including the hyphen.
  - **Risk:** Android/iOS OS kills app while user switches to Authenticator app. **Mitigation:** If `twoFactorToken` is lost on cold restart, guard safely redirects to `/login` rather than crashing or hanging on an invalid submission.
