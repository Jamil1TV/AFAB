# RESET_PASSWORD_SCREEN (`AUTH-07`)

## 1. Screen Identity
- **Screen ID:** `AUTH-07`
- **Screen Name:** Reset Password (Token Validation & New Password Entry)
- **Flutter Route Name & Path:** `AppRoutes.resetPassword` — `/reset-password` (query param `token=<rawToken>`, plus Universal/App Link alias `/:locale(en|ar)/reset-password`)
- **Feature Module:** `lib/features/auth/presentation/reset_password_screen.dart`
- **Web Equivalent(s):**
  - `Web/project/frontend/app/[locale]/(auth)/reset-password/page.tsx` (`ResetPasswordPage` + `ResetPasswordContent`)
  - `Web/project/frontend/components/auth/PasswordStrengthIndicator.tsx` (`PasswordStrengthIndicator`)
- **Priority:** P0 (Core Account Recovery + **Confirmed Critical Web Bug Fix**)
- **Status Parity:** Implemented but Incomplete on Web — **confirmed critical bug** at `reset-password/page.tsx:24` (`rawToken.replace(/[^a-zA-Z0-9-]/g, "").trim()`) strips `_` from Base64URL tokens! Mobile **fixes** this bug by preserving `_`.

---

## 2. Purpose
`ResetPasswordScreen` handles incoming password reset links (`/reset-password?token=...`), validates the single-use 15-minute reset token via `POST /api/v1/auth/validate-reset-token`, guides the user to create a strong new password using the 5-rule `PasswordStrengthIndicator` + confirmation match, submits `POST /api/v1/auth/reset-password-token` (which revokes all active refresh tokens across all devices), and routes cleanly back to `/login`.

---

## 3. Original Web Structure
In `Web/project/frontend/app/[locale]/(auth)/reset-password/page.tsx`:
1. **Token Extraction (`lines 22–24` — BUGGY ON WEB):**
   - `const rawToken = searchParams.get("token") || "";`
   - `const token = rawToken.replace(/[^a-zA-Z0-9-]/g, "").trim();` *(BUG: omits `_` from Base64URL character class!)*
2. **4 View States (`tokenStatus` + `success`):**
   - **`loading`:** Centered `AfabLoader(size="md")` + `resetPasswordValidating` (`"Validating your reset link..."`).
   - **`expired` (`TOKEN_EXPIRED`):** `64x64px` amber circle (`AlertTriangle`), `tokenExpiredTitle` (`"Link expired"`), `tokenExpiredMessage`, CTA button `requestNewLink` → `/forgot-password`.
   - **`invalid` (`INVALID_TOKEN` or missing token):** `64x64px` red circle (`ShieldX`), `tokenInvalidTitle` (`"Invalid link"`), `tokenInvalidMessage`, CTA button `requestNewLink` → `/forgot-password`.
   - **`success` (`success == true`):** `64x64px` emerald circle (`CheckCircle2`), `passwordResetSuccessTitle`, `passwordResetSuccessMessage`, `backToLogin` link (auto-redirects to `/login` after `3000 ms`).
   - **`valid` (Form):**
     - `backToLogin` link
     - `Lock` icon badge (`56x56px`), `resetPasswordTitle` (`"Set a new password"`), `resetPasswordSubtitle`
     - `newPassword` input (`#reset-password`) with `Eye`/`EyeOff` toggle + inline `passwordError`
     - `<PasswordStrengthIndicator password={password} />` (5 rules)
     - `confirmPassword` input (`#reset-confirm-password`) with `Eye`/`EyeOff` toggle + inline `confirmError`
     - Submit button (`#reset-submit`): `resetButton` (`"Reset Password"`), disabled when `loading || !password || !confirmPassword`.

---

## 4. Complete Functional Inventory

| # | Control / Feature | Behavior & Rules |
|---|---|---|
| 1 | **Critical Bug Fix: Base64URL Token Preservation** | Backend `AuthService.generateSecureToken()` (`AuthService.java:709-713`) generates 32 random bytes encoded with `Base64.getUrlEncoder().withoutPadding()`, whose alphabet is **`A-Z`, `a-z`, `0-9`, `-`, `_`** (~64% of 43-char tokens contain at least one `_`!).<br>**Mobile Implementation:**<br>```dart<br>final decoded = Uri.decodeComponent(rawToken).trim();<br>final token = decoded.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');<br>```<br>This strips trailing email punctuation/spaces/quotes while **strictly preserving `_` and `-`**. |
| 2 | **Automatic Token Validation on Mount** | If `token.isEmpty`, immediately set state to `invalid` without hitting the API. Otherwise call `POST /api/v1/auth/validate-reset-token` with `{ token }`:<br>- `200 OK` → transition to `valid` form state.<br>- `400 TOKEN_EXPIRED` → transition to `expired` state.<br>- `400 INVALID_TOKEN` (used or unknown token) → transition to `invalid` state.<br>- Network error / `429 RATE_LIMITED` → show retryable network error view (do NOT falsely label a valid link as "Invalid link" when offline!). |
| 3 | **5-Rule Password Strength Validation** | Mirrors `reset-password/page.tsx:66-74` and `PasswordStrengthIndicator.tsx`:<br>1. `pw.length >= 8`<br>2. `RegExp(r'[A-Z]').hasMatch(pw)` (uppercase)<br>3. `RegExp(r'[a-z]').hasMatch(pw)` (lowercase)<br>4. `RegExp(r'[0-9]').hasMatch(pw)` (number)<br>5. `RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>/?`~]').hasMatch(pw)` (special char)<br>All 5 rules MUST pass before submit; otherwise show `resetPasswordWeak` inline under `newPassword`. |
| 4 | **Confirm Password Match Validation** | `password == confirmPassword`; otherwise show `resetPasswordMismatch` inline under `confirmPassword`. Both errors clear live as soon as user fixes the condition. |
| 5 | **Reset Password Submission (`POST /api/v1/auth/reset-password-token`)** | Sends `{ token, password }`.<br>- `200 OK`: Clears any local `PersistCookieJar` / `SessionTokenHolder` if user happened to be signed in previously (since backend revokes all user refresh tokens via `refreshTokenRepository.revokeAllUserTokens()`), renders `success` state, shows `passwordResetSuccess` toast, and auto-navigates via `context.go('/login')` after `2.5–3s` (with immediate `"Back to login"` button).<br>- `400 TOKEN_EXPIRED` → switches view to `expired`.<br>- `400 INVALID_TOKEN` → switches view to `invalid`.<br>- `400 RESET_FAILED` / `429 RATE_LIMITED` / Network error → shows `AfabToast.error(...)`. |
| 6 | **Request New Link CTA** | Shown on both `expired` and `invalid` views (`requestNewLink`), navigating to `/forgot-password`. |

---

## 5. Data Requirements

### 5.1 Request DTOs (`ValidateTokenRequest.java` & `ResetPasswordByTokenRequest.java`)
```dart
@freezed
class ValidateTokenRequest with _$ValidateTokenRequest {
  const factory ValidateTokenRequest({
    required String token, // @NotBlank — Base64URL [A-Za-z0-9_-]
  }) = _ValidateTokenRequest;
}

@freezed
class ResetPasswordByTokenRequest with _$ResetPasswordByTokenRequest {
  const factory ResetPasswordByTokenRequest({
    required String token,    // @NotBlank
    required String password, // @NotBlank @Size(min: 8)
  }) = _ResetPasswordByTokenRequest;
}
```

### 5.2 View State (`ResetPasswordState`)
```dart
enum ResetTokenStatus { loading, valid, expired, invalid, networkError, success }
```

---

## 6. API Integration

| Endpoint | Method | Auth / Rate Limit | Request | Responses & Errors |
|---|---|---|---|---|
| `/api/v1/auth/validate-reset-token` | `POST` | Public<br>Rate Limit: `RESET_PASSWORD` = **5 req/min** per IP | `{ "token": "<rawBase64UrlToken>" }` | - `200 OK`: `{ "success": true, "message": "Token is valid." }`<br>- `400 TOKEN_EXPIRED`: `"This reset link has expired."`<br>- `400 INVALID_TOKEN`: `"Invalid reset link."`<br>- `429 RATE_LIMITED` |
| `/api/v1/auth/reset-password-token` | `POST` | Public<br>Rate Limit: `RESET_PASSWORD` = **5 req/min** per IP | `{ "token": "<rawBase64UrlToken>", "password": "..." }` | - `200 OK`: `{ "success": true, "message": "Password has been reset successfully." }` (revokes all user refresh tokens)<br>- `400 TOKEN_EXPIRED`<br>- `400 INVALID_TOKEN`<br>- `400 RESET_FAILED`<br>- `429 RATE_LIMITED` |

> **Critical Deep-Link Routing Note:**
> Backend email links look like `https://<web-host>/en/reset-password?token=<43-char-Base64URL>`.
> `GoRouter` must accept both `/reset-password` and `/en/reset-password` / `/ar/reset-password` from Universal Links / App Links and forward `state.uri.queryParameters['token']` intact without mangling `_` or `-`.

---

## 7. Modal, Drawer and Dialog Inventory
- **None.** State transitions (`loading` → `valid` / `expired` / `invalid` / `networkError` → `success`) render cleanly within the main `AfabCard`.

---

## 8. Mobile Adaptation
- **Autofill Context:** Wrap `newPassword` and `confirmPassword` in `AutofillGroup` with `AutofillHints.newPassword` so iOS Keychain / Android Password Manager updates the saved credential upon reset.
- **Scroll & Keyboard:** `SingleChildScrollView` + `AnimatedPadding(viewInsets.bottom)` ensures `PasswordStrengthIndicator` + `Confirm Password` + `Reset Password` button remain visible and scrollable while the keyboard is open.
- **Forced LTR on Password Fields:** Both password fields use `TextDirection.ltr`; strength indicator & labels adapt to EN (LTR) / AR (RTL).

---

## 9. Visual Design
- **Validating State:** `AfabCard` containing `AfabLoader(size: AfabLoaderSize.md)` + `resetPasswordValidating` muted text.
- **Expired State:** `64x64dp` circle (`warning` `#F59E0B` 10% tint) + `LucideIcons.alertTriangle` (`32dp`, `#D97706`/`#FBBF24`) + `tokenExpiredTitle` + `AfabButton.primary` (`"Request a new link"`).
- **Invalid State:** `64x64dp` circle (`danger` `#EF4444` 10% tint) + `LucideIcons.shieldX` (`32dp`, `#DC2626`/`#F87171`) + `tokenInvalidTitle` + `AfabButton.primary` (`"Request a new link"`).
- **Success State:** `64x64dp` circle (`success` `#10B981` 10% tint) + `LucideIcons.checkCircle2` + `passwordResetSuccessTitle` + `backToLogin` link.
- **Valid Form State:** `56x56dp` `primary` 10% tile with `LucideIcons.lock`, two `AfabTextField` password inputs with eye toggles, shared `PasswordStrengthIndicator` (5-rule meter), and `AfabButton.primary` (`"Reset Password"`).

---

## 10. Localization
Keys from `Web/project/frontend/messages/{en,ar}/auth.json`:
- `resetPasswordValidating`: `"Validating your reset link..."` / `"جاري التحقق من رابط إعادة التعيين..."`
- `resetPasswordTitle`: `"Set a new password"` / `"تعيين كلمة مرور جديدة"`
- `resetPasswordSubtitle`: `"Your new password must meet all requirements below."` / `"يجب أن تستوفي كلمة المرور الجديدة جميع المتطلبات أدناه."`
- `newPassword`, `newPasswordPlaceholder`, `confirmPassword`, `confirmPasswordPlaceholder`
- `resetButton`: `"Reset Password"` / `"إعادة تعيين كلمة المرور"`
- `resetPasswordWeak`, `resetPasswordMismatch`
- `passwordResetSuccess`, `passwordResetSuccessTitle`, `passwordResetSuccessMessage`
- `tokenExpiredTitle`, `tokenExpiredMessage`, `tokenInvalidTitle`, `tokenInvalidMessage`, `requestNewLink`, `backToLogin`
- Plus all 12 `pwStrength*` and `pwReq*` keys for `PasswordStrengthIndicator`.

---

## 11. Animation and Interaction Design
- **State Switcher:** `AnimatedSwitcher` (`280 ms` fade) between loading, error states, form, and success.
- **Password Strength Meter:** Smooth animated bar width + requirement badge check pop (shared with `SIGNUP_SCREEN.md`).
- **Auto-Redirect Countdown:** Cancelable `Timer` (`3s`) on `success` screen — cancelled cleanly in `dispose()` or if user taps `"Back to login"` early so it never double-navigates.

---

## 12. Accessibility
- Explicit `Semantics` labels for `newPassword`, `confirmPassword`, and both visibility toggles.
- Inline error labels (`reset-password-error`, `reset-confirm-error`) marked `liveRegion: true`.
- Expired / Invalid / Success headings receive initial accessibility focus on transition.

---

## 13. Acceptance Criteria
1. Opening `/reset-password?token=<token_with_underscores>` preserves `_` and `-` characters intact and validates successfully against `POST /api/v1/auth/validate-reset-token`.
2. Expired tokens show `tokenExpiredTitle` + `"Request a new link"` CTA; used/malformed/missing tokens show `tokenInvalidTitle`.
3. Network failure during validation shows a retryable error state rather than mislabeling the link as invalid.
4. Submitting a password that fails any of the 5 strength rules or mismatches `confirmPassword` is blocked client-side with localized inline error messages.
5. Valid submission calls `POST /api/v1/auth/reset-password-token`, wipes any lingering local auth cookies/tokens, displays `passwordResetSuccessTitle`, and navigates to `/login`.

---

## 14. Dependencies and Risks
- **Dependencies:** `dio`, `flutter_riverpod`, `go_router`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  - **Risk:** Replicating Web's `replace(/[^a-zA-Z0-9-]/g, "")` regex would silently break ~64% of Base64URL reset tokens containing `_`. **Mitigation:** Regex explicitly includes `_`: `RegExp(r'[^A-Za-z0-9_-]')`, covered by mandatory unit tests in `test/unit/auth/reset_token_sanitizer_test.dart`.
  - **Risk:** Auto-redirect `Timer` firing after the user manually tapped `"Back to login"` or left the screen. **Mitigation:** Cancel timer on dispose / manual navigation.
