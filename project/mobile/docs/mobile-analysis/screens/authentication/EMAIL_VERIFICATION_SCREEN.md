# EMAIL_VERIFICATION_SCREEN (`AUTH-05`)

## 1. Screen Identity
- **Screen ID:** `AUTH-05`
- **Screen Name:** Email Verification (6-Digit OTP)
- **Flutter Route Name & Path:** `AppRoutes.verifyEmail` — `/verify-email` (optional `VerifyEmailArgs { devOtp?, emailDeliveryFailed? }` via `GoRouter.extra`)
- **Feature Module:** `lib/features/auth/presentation/email_verification_screen.dart`
- **Web Equivalent(s):**
  - `Web/project/frontend/app/[locale]/(auth)/verify-email/page.tsx` (`VerifyEmailPage`)
- **Priority:** P0 (Mandatory Account Activation Gate)
- **Status Parity:** Implemented but Incomplete on Web (`verify-email` & `resend-verification` work end-to-end, `devOtp` helper banner is commented out in JSX at lines `294-317`, and there is no "Sign out / Use different email" escape hatch if session email is wrong).

---

## 2. Purpose
`EmailVerificationScreen` verifies the newly registered (or unverified returning) user's email address using a 6-digit numeric OTP (15-minute backend TTL, BCrypt-hashed in `verification_tokens`), supports clipboard paste & OS OTP autofill, enforces a 60-second client cooldown on resending verification emails, and routes upon success to `OnboardingScreen` (`/onboarding`) or `/dashboard` if already onboarded.

---

## 3. Original Web Structure
In `Web/project/frontend/app/[locale]/(auth)/verify-email/page.tsx`:
1. **Top Animated Icon Badge:** `64x64px` circular badge morphing between `MailCheck` (primary tint), `XCircle` (red tint + shake on error), and `CheckCircle2` (emerald tint + celebration confetti particles on success).
2. **Title & Subtitle:**
   - Default: `verifyEmailTitle` (`"Verify your email"`) + `verifyEmailSubtitle` (`"We sent a 6-digit code to"` + `user?.email`).
   - Success: `"Email Verified!"` + `"Your account is verified! Preparing your workspace..."` (hardcoded English in Web!).
3. **Commented-Out Dev OTP Banner (`lines 294–317`):** Displays `devOtp` in local/dev profiles with an auto-fill button (`handleAutoFill`).
4. **Error & Success Banners:** Animated slide-in red error banner / emerald success banner.
5. **6-Digit OTP Input Row:** 6 individual `inputMode="numeric"` `maxLength={1}` inputs with horizontal shake (`shakeKey`) on error, active bottom indicator dot, backspace retreat, `onPaste` 6-digit handler, and auto-submit when all 6 digits are entered.
6. **Submit Button:** Full-width button (`verifyButton`: `"Verify Email"`), morphing to `"Verifying code..."` (loading) and `"Success! Redirecting..."` (emerald success) — *note: Web hardcoded these two status labels in English*.
7. **Resend Code Footer:** `"Didn't receive the code?"` + `Resend Code` button or `"Resend in {countdown}s"` (starts at `60` seconds on initial mount and resets to `60` after each successful resend).

---

## 4. Complete Functional Inventory

| # | Control / Feature | Behavior & Rules |
|---|---|---|
| 1 | **Session & Email Resolution** | Reads `user.email` from `sessionProvider` (`UserProfileDTO` / `AuthUserDto`). If `user?.email` is null/empty, renders `noEmailFound` error with a CTA back to `/login`. |
| 2 | **Email Delivery Failure Notice** | If navigated from `/signup` with `verificationEmailSent == false`, immediately shows a non-blocking warning banner explaining the initial email could not be sent and highlighting `"Resend Code"` (optionally setting initial countdown to `0` so the user doesn't have to wait 60s to retry!). |
| 3 | **6-Digit OTP Input + Paste** | Six individual `46x54dp` numeric cells (`TextDirection.ltr` forced in all locales).<br>- Typing a digit `0–9` fills the slot and advances focus.<br>- Backspace on empty slot moves focus to previous slot and clears it.<br>- **Paste:** Stripping whitespace/non-digits (`cleaned = raw.replaceAll(RegExp(r'\D'), '')`), if `cleaned.length >= 6`, fills all 6 boxes with `cleaned.substring(0, 6)` and triggers `verifyEmail()` automatically.<br>- **OS Autofill:** Supports `AutofillHints.oneTimeCode` (iOS/Android SMS/Mail quick-fill). |
| 4 | **Verify Action (`POST /api/v1/auth/verify-email`)** | Triggered automatically on 6th digit entry or tap on `verifyButton`. Sends `{ email: user.email, code }`.<br>- `200 OK`: Updates `sessionProvider` (`emailVerified = true`), shows localized success state (`1.2–1.5s`), then routes:<br>  - `!user.onboardingComplete` → `context.go('/onboarding')`<br>  - `user.onboardingComplete` → `context.go('/dashboard')`.<br>- `400 VERIFICATION_FAILED`: Triggers error shake + haptic + localized error (`verifyFailed` or backend `"Invalid or expired verification code"`). Note: Backend returns `"Invalid or expired verification code"` even if already verified (`AuthService.java:459-461`), so if `/user/me` shows `emailVerified == true`, recover gracefully to `/onboarding`. |
| 5 | **60-Second Resend Cooldown Timer** | Counts down from `60` to `0` (`Timer.periodic(Duration(seconds: 1))`). Resets to `60` on every successful `POST /api/v1/auth/resend-verification`. Disabled while `countdown > 0` or `resending == true`. |
| 6 | **Resend Verification (`POST /api/v1/auth/resend-verification`)** | Sends `{ email: user.email }`.<br>- `200 OK`: Shows `codeResent` green banner, resets `60s` timer; if `devOtp` is returned, updates local dev helper banner.<br>- `503 EMAIL_DELIVERY_FAILED`: Shows backend message `"We couldn't send the verification email right now. Please try again in a few minutes."` without starting the 60s lock if delivery failed.<br>- `429 RATE_LIMITED` (`VERIFY_EMAIL` 10/min): Shows `errorRateLimited`. |
| 7 | **Dev OTP Helper Note (Debug/Local Only)** | Only rendered when `kDebugMode && EnvironmentConfig.isLocal && devOtp != null` (matching backend `isDevOtpExposed()` which requires `local`/`dev` profile AND `afab.auth.allow-dev-otp=true`). **Strictly stripped from release/staging/prod builds (`!kReleaseMode`).** Provides one-tap auto-fill for QA/developer speed. |
| 8 | **Sign Out / Change Account Escape (Mobile Improvement)** | Web traps an unverified user on `/verify-email` without a visible logout button. Mobile adds a subtle `"Sign out / Use a different email"` text button in the footer calling `logout()` → `/login`. |

---

## 5. Data Requirements

### 5.1 Request DTOs (`VerifyEmailRequest.java` & `ResendVerificationRequest.java`)
```dart
@freezed
class VerifyEmailRequest with _$VerifyEmailRequest {
  const factory VerifyEmailRequest({
    required String email, // @NotBlank @Email
    required String code,  // @NotBlank @Size(min: 6, max: 6)
  }) = _VerifyEmailRequest;
}

@freezed
class ResendVerificationRequest with _$ResendVerificationRequest {
  const factory ResendVerificationRequest({
    required String email, // @NotBlank @Email
  }) = _ResendVerificationRequest;
}
```

### 5.2 Resend Response DTO
```dart
@freezed
class ResendVerificationResponse with _$ResendVerificationResponse {
  const factory ResendVerificationResponse({
    required bool success,
    required String message,
    String? devOtp, // Present only when backend allow-dev-otp=true & profile in {local, dev}
  }) = _ResendVerificationResponse;
}
```

---

## 6. API Integration

| Endpoint | Method | Auth / Rate Limit | Request | Response / Errors |
|---|---|---|---|---|
| `/api/v1/auth/verify-email` | `POST` | Public<br>Rate Limit: `VERIFY_EMAIL` = **10 req/min** per IP & per email | `{ "email": "...", "code": "123456" }` | - `200 OK`: `{ "success": true, "message": "Email verified successfully." }`<br>- `400 VERIFICATION_FAILED`: `"Invalid or expired verification code"` (15-min TTL, BCrypt verified)<br>- `429 RATE_LIMITED` |
| `/api/v1/auth/resend-verification` | `POST` | Public<br>Rate Limit: `VERIFY_EMAIL` = **10 req/min** per IP & per email | `{ "email": "..." }` | - `200 OK`: `{ "success": true, "message": "...", "devOtp"?: "123456" }`<br>- `503 EMAIL_DELIVERY_FAILED`: SMTP failure<br>- `429 RATE_LIMITED` |

---

## 7. Modal, Drawer and Dialog Inventory
- **Sign Out Confirmation Dialog (Optional):** Simple AlertDialog if user taps `"Use a different email"` confirming local session sign-out and returning to `/login`.

---

## 8. Mobile Adaptation
- **OTP Input Architecture:** Instead of 6 fragile separate `TextField`s that fight iOS/Android soft keyboards on backspace and paste, implement a **single invisible/backed `TextField` (`maxLength: 6`, `keyboardType: TextInputType.number`) or `pinput`-equivalent custom `EditableText` backed by 6 styled visual boxes**, ensuring flawless cursor handling, iOS `oneTimeCode` autofill, Android clipboard paste, and TalkBack/VoiceOver accessibility.
- **No Unlocalized Strings:** Localize Web's hardcoded `"Email Verified!"`, `"Your account is verified!..."`, `"Verifying code..."`, and `"Success! Redirecting..."` via ARB keys.
- **Responsive Slot Widths:** On `compactSmall (< 360dp)`, size boxes `42x50dp` with `6dp` gap; on `>= 360dp`, size `48x56dp` with `10dp` gap inside `maxWidth: 440dp` `AfabCard`.

---

## 9. Visual Design
- **Top Status Avatar (`64x64dp` circle):**
  - Idle/Loading: `primary.withValues(alpha: 0.10)` + `LucideIcons.mailCheck` (`primary`)
  - Error: `danger.withValues(alpha: 0.12)` + `LucideIcons.xCircle` (`danger`)
  - Success: `success.withValues(alpha: 0.12)` + `LucideIcons.checkCircle2` (`success`)
- **OTP Boxes:** `12dp` radius, `2dp` `primary` border + `20%` ring when active slot; `2dp` `success` border + tint on verified; `2dp` `danger` border + tint on error; `20sp` Bold tabular numerals.
- **Dev OTP Note (Debug Only):** Dashed `primary` border inset pill displaying code in monospace + `"Tap to auto-fill"` action (`!kReleaseMode` only).
- **Submit Button:** `AfabButton` morphing background from `primary` (`#8B5CF6`) → `danger` (`#EF4444`) briefly on error → `success` (`#10B981`) on verification.

---

## 10. Localization
Keys from `Web/project/frontend/messages/{en,ar}/auth.json`:
- `verifyEmailTitle`: `"Verify your email"` / `"تأكيد البريد الإلكتروني"`
- `verifyEmailSubtitle`: `"We sent a 6-digit code to"` / `"أرسلنا رمز تأكيد مكون من 6 أرقام إلى"`
- `verifyButton`: `"Verify Email"` / `"تأكيد البريد الإلكتروني"`
- `didntReceiveCode`: `"Didn't receive the code?"` / `"لم تصلك الرسالة؟"`
- `resendCode`: `"Resend Code"` / `"إعادة إرسال الرمز"`
- `resendIn`: `"Resend in"` / `"إعادة الإرسال بعد"`
- `codeResent`: `"Verification code sent! Check your inbox."` / `"تم إرسال رمز التأكيد! تحقق من صندوق الوارد."`
- `verifySuccess`: `"Email verified successfully! Redirecting..."` / `"تم تأكيد البريد الإلكتروني بنجاح! جاري التوجيه..."`
- `verifyFailed`: `"Invalid verification code."` / `"رمز التأكيد غير صالح."`
- `verifyCodeIncomplete`: `"Please enter the full 6-digit code."` / `"يرجى إدخال الرمز الكامل المكون من 6 أرقام."`
- `noEmailFound`: `"Session invalid. Please sign up or log in again."` / `"الجلسة غير صالحة. يرجى إنشاء حساب أو تسجيل الدخول مجدداً."`
- `resendFailed`: `"Failed to resend code."` / `"فشل إعادة إرسال الرمز."`
- **New Mobile Keys (Fixing Web Hardcoded EN Strings):**
  - `verifyEmailSuccessTitle`: `"Email Verified!"` / `"تم تأكيد البريد الإلكتروني!"`
  - `verifyEmailSuccessBody`: `"Your account is verified! Preparing your workspace..."` / `"تم تأكيد حسابك! جاري تجهيز مساحة عملك..."`
  - `verifyingCodeStatus`: `"Verifying code..."` / `"جاري التحقق من الرمز..."`
  - `verifyEmailDeliveryWarning`: `"We couldn't send the verification email automatically. Tap Resend Code to try again."` / `"تعذر إرسال رمز التحقق تلقائياً. اضغط على إعادة إرسال الرمز للمحاولة مرة أخرى."`
  - `verifySignOutDifferentEmail`: `"Use a different email"` / `"استخدام بريد إلكتروني مختلف"`
- **RTL Rules:** The 6-digit OTP box container and countdown seconds (`60s`) enforce `TextDirection.ltr` so digits always flow left-to-right.

---

## 11. Animation and Interaction Design
- **Slot Pop:** Filled OTP box scales `1.0 → 1.08 → 1.0` (`180 ms`).
- **Error Shake:** Horizontal damped oscillation (`±12 dp`, `450 ms`) + `HapticFeedback.heavyImpact()`.
- **Success Celebration:** Lightweight `CustomPainter` particle burst (respecting `MediaQuery.disableAnimationsOf(context)`) + `CheckCircle2` spring scale + `HapticFeedback.mediumImpact()`.
- **Cooldown Timer:** Uses `FontFeature.tabularFigures()` so `"Resend in 59s"` does not jitter horizontally as digits tick down.

---

## 12. Accessibility
- Single accessible OTP field announces `"6-digit verification code, X of 6 digits entered"`, `TextInputType.number`.
- Displayed target email wrapped in `Semantics` read clearly.
- Cooldown timer avoids announcing every second to TalkBack/VoiceOver (announces only when `"Resend Code"` becomes enabled).
- Error and success banners use `Semantics(liveRegion: true)`.

---

## 13. Acceptance Criteria
1. Entering or pasting a valid 6-digit code calls `POST /api/v1/auth/verify-email`, updates `emailVerified = true` in session state, shows success feedback, and navigates to `/onboarding` (or `/dashboard` if already onboarded).
2. Pasting a 6-digit code from clipboard (e.g. `"123456"` or `"123 456"`) populates all 6 slots and triggers verification automatically.
3. Initial 60-second resend timer blocks resend until reaching `0s` (unless initial `verificationEmailSent == false` from registration), and `POST /api/v1/auth/resend-verification` restarts the 60s countdown on `200 OK`.
4. Invalid/expired OTP triggers horizontal shake, haptic feedback, and `verifyFailed` error banner without clearing the user's session.
5. `devOtp` helper banner is **never** compiled/shown in release or production builds (`!kReleaseMode && isLocal`).
6. User can tap `"Use a different email"` to sign out cleanly and return to `/login`.

---

## 14. Dependencies and Risks
- **Dependencies:** `dio`, `flutter_riverpod`, `go_router`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  - **Risk:** `resending` during SMTP outage (`503 EMAIL_DELIVERY_FAILED`) could lock the user out for 60s if timer resets blindly. **Mitigation:** Only reset `countdown = 60` on `200 OK`.
  - **Risk:** Returning unverified user logs in via `/login` and is routed to `/verify-email` where the original OTP from signup may be >15m old. **Mitigation:** Allow user to tap **Resend Code** cleanly once initial 60s expires (or start countdown at `0s` when arriving from `/login` rather than `/signup`).
