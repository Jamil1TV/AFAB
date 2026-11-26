# FORGOT_PASSWORD_SCREEN (`AUTH-06`)

## 1. Screen Identity
- **Screen ID:** `AUTH-06`
- **Screen Name:** Forgot Password (Reset Link Request + Optional OTP Recovery Note)
- **Flutter Route Name & Path:** `AppRoutes.forgotPassword` — `/forgot-password` (optional `initialEmail` via `GoRouter.extra`)
- **Feature Module:** `lib/features/auth/presentation/forgot_password_screen.dart`
- **Web Equivalent(s):**
  - `Web/project/frontend/app/[locale]/(auth)/forgot-password/page.tsx` (`ForgotPasswordPage`)
- **Priority:** P0 (Core Account Recovery)
- **Status Parity:** Implemented and Connected on Web (`POST /api/v1/auth/forgot-password-link`). Mobile adds an explicit note/fallback option regarding the backend's 6-digit OTP password reset endpoints (`POST /api/v1/auth/forgot-password` + `POST /api/v1/auth/reset-password`) for environments without Universal/App Links configured.

---

## 2. Purpose
`ForgotPasswordScreen` lets an unauthenticated user request a password reset email without exposing whether an email exists in AFAB (enumeration-safe `200 OK` response). By default it mirrors Web's link-based flow (`POST /api/v1/auth/forgot-password-link`, which sends a 15-minute reset URL `{frontendUrl}/en/reset-password?token={rawToken}` interceptable by iOS Universal Links / Android App Links), while documenting the optional OTP recovery path (`POST /api/v1/auth/forgot-password` → `POST /api/v1/auth/reset-password`) already present in `AuthController.java`.

---

## 3. Original Web Structure
In `Web/project/frontend/app/[locale]/(auth)/forgot-password/page.tsx`:
1. **Top Back Link:** `ArrowLeft` (`rtl:rotate-180`) + `backToLogin` (`"Back to login"`) linking to `/login`.
2. **State A — Form (`!sent`):**
   - `56x56px` rounded-2xl `bg-[var(--primary)]/10` icon badge with `Mail` icon.
   - `forgotPasswordTitle` (`"Forgot your password?"`) + `forgotPasswordSubtitle` (`"Enter your email and we'll send you a link to reset your password."`).
   - Email field (`#forgot-email`, `Mail` icon, `required`, `autoComplete="email"`) with inline client validation on blur/submit (`forgotPasswordEmailRequired`, `forgotPasswordEmailInvalid`).
   - Submit button (`#forgot-submit`): `sendResetLink` (`"Send Reset Link"`) + `ArrowRight` (`AfabLoader` while loading).
3. **State B — Confirmation (`sent == true`):**
   - `64x64px` emerald circle with `CheckCircle2` icon.
   - `resetEmailSent` (`"Check your email"`) + `resetEmailSentSubtitle` (`"We've sent a password reset link to"`) + displayed `email`.
   - `backToLogin` link to `/login`.
4. **Error Toasts:** Maps `RATE_LIMITED` → `errorRateLimited`, `NETWORK_ERROR` → `errorNetworkFailure`, fallback `err.message` or `errorServerFailure`.

---

## 4. Complete Functional Inventory

| # | Control / Feature | Behavior & Rules |
|---|---|---|
| 1 | **Back to Login Navigation** | Top-left (top-right in RTL) directional back button returning to `/login`. Also supports Android system back / iOS edge swipe. |
| 2 | **Email Validation (Live & On-Submit)** | Matches Web `validateEmail()` (`forgot-password/page.tsx:21-33`):<br>- Empty/whitespace → `forgotPasswordEmailRequired`<br>- Fails `^[^\s@]+@[^\s@]+\.[^\s@]+$` → `forgotPasswordEmailInvalid`<br>- Validates on `onFocusLost` (when non-empty), re-validates on change once an error is active, and validates on submit. |
| 3 | **Primary Flow: Send Reset Link (`POST /api/v1/auth/forgot-password-link`)** | Sends `{ email: email.trim() }`.<br>- `200 OK` (always returned for valid email format regardless of whether account exists — enumeration-safe): transitions cleanly via `AnimatedSwitcher` to the `"Check your email"` confirmation view showing the submitted email.<br>- **Deep Link Integration:** When the user taps the emailed link (`{frontendUrl}/en/reset-password?token={rawToken}`), Android App Links / iOS Universal Links open `ResetPasswordScreen` (`AUTH-07`) directly with the exact `token` query parameter intact! |
| 4 | **Optional OTP Recovery Path Note (Backend Supported)** | `AuthController.java:271-310` & `AuthService.java:502-550` expose an unused OTP recovery pair:<br>- `POST /api/v1/auth/forgot-password` (sends 6-digit numeric OTP, 15-min TTL)<br>- `POST /api/v1/auth/reset-password` (`{ email, code, newPassword }`, revokes all refresh tokens).<br>Mobile defaults to `forgot-password-link` for 100% Web parity and Universal Link UX, and may optionally expose a secondary `"Have a 6-digit reset code?"` / `"Use code instead"` bottom-sheet or toggle **if** Universal Links are not yet verified in local/staging builds (never invent a new endpoint — uses existing `/auth/forgot-password` + `/auth/reset-password`). |
| 5 | **Resend / Change Email from Confirmation State** | Mobile improvement over Web: on the `"Check your email"` state, include a subtle `"Didn't receive it? Try again"` action resetting `sent = false` so users who mistyped their email don't have to pop back to Login and re-enter Forgot Password. |
| 6 | **Rate Limit & Network Errors** | - `429 RATE_LIMITED` (`FORGOT_PASSWORD` = **5 req/min** per IP & per email) → `AfabToast.error(errorRateLimited)` + optional `Retry-After` hint.<br>- `503 RATE_LIMIT_UNAVAILABLE` / Network error → `AfabToast.error(errorNetworkFailure)`. |

---

## 5. Data Requirements

### 5.1 Request DTO (`ForgotPasswordRequest.java`)
```dart
@freezed
class ForgotPasswordRequest with _$ForgotPasswordRequest {
  const factory ForgotPasswordRequest({
    required String email, // @NotBlank @Email
  }) = _ForgotPasswordRequest;
}
```

### 5.2 Response DTO (`ErrorResponse.java`)
```dart
@freezed
class ApiSuccessResponse with _$ApiSuccessResponse {
  const factory ApiSuccessResponse({
    required bool success,
    required String message,
  }) = _ApiSuccessResponse;
}
```

### 5.3 Optional OTP Fallback DTO (`ResetPasswordRequest.java`)
`{ required String email, required String code /* 6 digits */, required String newPassword /* >= 8 chars */ }` — used only if optional OTP recovery fallback is enabled.

---

## 6. API Integration

| Endpoint | Method | Auth / Rate Limit | Request | Responses & Errors |
|---|---|---|---|---|
| `/api/v1/auth/forgot-password-link` | `POST` | Public<br>Rate Limit: `FORGOT_PASSWORD` = **5 req/min** per IP & per email | `{ "email": "user@example.com" }` | - `200 OK`: `{ "success": true, "message": "If an account with that email exists, a password reset link has been sent." }` (15-min token TTL via `afab.password-reset.expiration-minutes:15`)<br>- `400`: `ApiError.fieldErrors` (`email`)<br>- `429 RATE_LIMITED`<br>- `503 RATE_LIMIT_UNAVAILABLE` |
| *(Optional fallback)* `/api/v1/auth/forgot-password` | `POST` | Public / `FORGOT_PASSWORD` (5/min) | `{ "email": "user@example.com" }` | `200 OK`: `{ "success": true, "message": "If an account with that email exists, a reset code has been sent." }` |
| *(Optional fallback)* `/api/v1/auth/reset-password` | `POST` | Public / `RESET_PASSWORD` (5/min) | `{ "email", "code", "newPassword" }` | `200 OK` (revokes all refresh tokens) or `400 RESET_FAILED` |

> **Backend Deep-Link Detail (`AuthService.java:570`):**
> `String resetLink = frontendUrl + "/en/reset-password?token=" + rawToken;`
> Notice the backend hardcodes `/en/reset-password?token=` regardless of the user's mobile locale! Therefore, iOS `apple-app-site-association` and Android `assetlinks.json` + `GoRouter` MUST match `/en/reset-password` (and `/ar/reset-password`, `/reset-password`) and route to `ResetPasswordScreen` (`AUTH-07`) while preserving the user's active mobile locale.

---

## 7. Modal, Drawer and Dialog Inventory
- **Optional OTP Reset Sheet (only if OTP fallback toggle is enabled in local/dev or pre-Universal-Link builds):** `AfabBottomSheet` allowing entry of the 6-digit reset OTP + new password (`POST /auth/reset-password`) when a user cannot open the email link directly on the device.

---

## 8. Mobile Adaptation
- **Pre-Fill Email:** If user tapped `"Forgot password?"` on `LoginScreen` after typing an email, pre-populate `email` controller automatically.
- **Open Mail App Convenience (Confirmation Screen):** Optional `"Open Email App"` button on the `"Check your email"` state using platform intent/launcher (if available, non-blocking) alongside `"Back to login"`.
- **Keyboard:** `TextInputType.emailAddress`, `TextInputAction.done` (submits form), `TextDirection.ltr`.

---

## 9. Visual Design
- **Layout:** Centered `AfabCard(maxWidth: 440dp)` inside `AuthScaffold`.
- **Form Header Badge:** `56x56dp` rounded (`16dp` radius) tile (`primary.withValues(alpha: 0.10)`), `LucideIcons.mail` (`28dp`, `primary`).
- **Success Badge:** `64x64dp` circular tile (`success.withValues(alpha: 0.10)`), `LucideIcons.checkCircle2` (`32dp`, `success`).
- **Submitted Email Pill:** Bold `textPrimary` displayed in `Directionality(textDirection: TextDirection.ltr)` below `resetEmailSentSubtitle`.
- **Icons (`lucide_icons_flutter`):** `LucideIcons.arrowLeft` (`matchTextDirection: true`), `LucideIcons.mail`, `LucideIcons.arrowRight` (`matchTextDirection: true`), `LucideIcons.checkCircle2`.

---

## 10. Localization
Keys from `Web/project/frontend/messages/{en,ar}/auth.json`:
- `forgotPasswordTitle`: `"Forgot your password?"` / `"هل نسيت كلمة المرور؟"`
- `forgotPasswordSubtitle`: `"Enter your email and we'll send you a link to reset your password."` / `"أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور."`
- `email`: `"Email address"` / `"البريد الإلكتروني"`
- `emailPlaceholder`: `"you@example.com"` / `"you@example.com"`
- `forgotPasswordEmailRequired`: `"Email address is required."` / `"البريد الإلكتروني مطلوب."`
- `forgotPasswordEmailInvalid`: `"Please enter a valid email address."` / `"يرجى إدخال بريد إلكتروني صالح."`
- `sendResetLink`: `"Send Reset Link"` / `"إرسال رابط إعادة التعيين"`
- `resetEmailSent`: `"Check your email"` / `"تحقق من بريدك الإلكتروني"`
- `resetEmailSentSubtitle`: `"We've sent a password reset link to"` / `"لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى"`
- `backToLogin`: `"Back to login"` / `"العودة لتسجيل الدخول"`
- `errorRateLimited`, `errorNetworkFailure`, `errorServerFailure`.
- **New Mobile Keys:**
  - `forgotPasswordTryAnotherEmail`: `"Try a different email"` / `"تجربة بريد إلكتروني آخر"`
  - `forgotPasswordOtpFallbackHint`: `"Can't open the link? Reset with a 6-digit code instead"` / `"يتعذر فتح الرابط؟ أعد التعيين باستخدام رمز مكون من 6 أرقام"` *(if OTP fallback sheet is mounted)*

---

## 11. Animation and Interaction Design
- **State Transition (`Form` → `Check your email`):** `AnimatedSwitcher` (`300 ms` fade + subtle horizontal slide, direction-aware for LTR/RTL).
- **Success Icon Pop:** Spring scale `0.0 → 1.0` (`Curves.easeOutBack`, `350 ms`) + `HapticFeedback.mediumImpact()`.
- **Validation Error Slide:** `180 ms` fade + `4dp` downward reveal under email field.

---

## 12. Accessibility
- Email field binds `Semantics` error text when `emailError != null` (`liveRegion: true`).
- `"Back to login"` button has minimum `48x48dp` hit box and localized label.
- Confirmation screen focuses the `"Check your email"` heading automatically for TalkBack/VoiceOver announcement.

---

## 13. Acceptance Criteria
1. Submitting an empty or malformed email blocks the API call and shows localized `forgotPasswordEmailRequired` / `forgotPasswordEmailInvalid` inline.
2. Submitting a valid email calls `POST /api/v1/auth/forgot-password-link` and transitions to the confirmation view displaying the submitted email regardless of whether the email exists in DB.
3. Exceeding 5 requests/minute surfaces `errorRateLimited` without crashing or transitioning to the success screen.
4. Network failure shows `errorNetworkFailure` and preserves the typed email for immediate retry.
5. Tapping `"Back to login"` navigates cleanly back to `/login`.

---

## 14. Dependencies and Risks
- **Dependencies:** `dio`, `flutter_riverpod`, `go_router`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  - **Risk:** Backend `AuthService.forgotPasswordLink()` generates `{frontendUrl}/en/reset-password?token={rawToken}`, which requires Universal Links (iOS) / App Links (Android) hosted on `frontendUrl` to open the native app seamlessly. **Mitigation:** Configure `/.well-known/apple-app-site-association` & `/.well-known/assetlinks.json` for `/en/reset-password` and `/ar/reset-password`, AND keep the optional 6-digit OTP fallback (`/auth/forgot-password` + `/auth/reset-password`) documented for pre-production/unverified environments.
  - **Risk:** `AuthService.forgotPasswordLink()` catches `EmailDeliveryException` silently (`AuthService.java:574-577`) and returns `200 OK` even if SMTP is down (for enumeration safety). **Mitigation:** Ensure users can retry after rate-limit window or check spam folder in confirmation copy.
