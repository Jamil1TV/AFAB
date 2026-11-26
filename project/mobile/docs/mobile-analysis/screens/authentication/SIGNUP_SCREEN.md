# SIGNUP_SCREEN (`AUTH-04`)

## 1. Screen Identity
- **Screen ID:** `AUTH-04`
- **Screen Name:** Sign Up (Business & Account Registration)
- **Flutter Route Name & Path:** `AppRoutes.signup` — `/signup`
- **Feature Module:** `lib/features/auth/presentation/signup_screen.dart` (with shared `PasswordStrengthMeter` widget)
- **Web Equivalent(s):**
  - `Web/project/frontend/app/[locale]/(auth)/signup/page.tsx` (`SignupPage`)
  - `Web/project/frontend/components/auth/PasswordStrengthIndicator.tsx` (`PasswordStrengthIndicator`)
  - *(Note: `Web/project/frontend/components/auth/SignupCard.tsx` is an older unused component with full-name/terms fields; `app/[locale]/(auth)/signup/page.tsx` is the live routed page.)*
- **Priority:** P0 (Core Entry Flow)
- **Status Parity:** Implemented but Incomplete on Web (`POST /api/v1/auth/register` works end-to-end, but `signup/page.tsx` omits `PasswordStrengthIndicator` even though `PasswordStrengthIndicator.tsx` exists and renders an inert Google button). Mobile **adds** `PasswordStrengthIndicator` and **omits** the dead Google button.

---

## 2. Purpose
`SignupScreen` creates a new AFAB user account AND automatically initializes the user's primary `EDITABLE` business workspace (`OWNER` role, default currency `"USD"` until updated in Onboarding), triggers a 6-digit email verification OTP (`verificationEmailSent`), stores the issued JWT in RAM + encrypted refresh/CSRF cookies, and routes immediately to `EmailVerificationScreen` (`/verify-email`).

---

## 3. Original Web Structure
In `Web/project/frontend/app/[locale]/(auth)/signup/page.tsx`:
1. **Tab Switcher:** `loginTab` (link to `/login`) vs `signupTab` (active underline).
2. **Header:** `signupTitle` (`"Create your account"`) + `signupSubtitle` (`"Join thousands of business owners today."`).
3. **Error Alert:** `AlertCircle` icon + red banner when registration fails.
4. **Form Fields:**
   - **Row (`flex-col sm:flex-row`):**
     - `firstName` (`User` icon, placeholder `"Jane"` / `"سارة"`, `required`)
     - `lastName` (no icon, placeholder `"Doe"` / `"أحمد"`, `required`)
   - `businessName` (`Building` icon, placeholder `"Acme Corp"` / `"شركة التقنية"`, `required`)
   - `email` (`Mail` icon, `type="email"`, placeholder `"you@example.com"`, `required`)
   - `password` (`Lock` icon, `type="password|text"`, `Eye`/`EyeOff` toggle, placeholder `"Create a password"`, `minLength={8}`, `required`)
5. **Submit Button:** `signupButton` (`"Sign Up"`) + directional `ArrowRight` (`AfabLoader` while loading).
6. **Dead Social Section (OMIT ON MOBILE):** `"or continue with"` divider + inert `"Continue with Google"` button (`signup/page.tsx:248-276`).
7. **Footer Link:** `hasAccount` + `loginTab` link to `/login`.
8. **Post-Submit Redirect:** If `res.devOtp` is present (local/dev profile when `afab.auth.allow-dev-otp=true`), routes to `/verify-email?devOtp={res.devOtp}`; otherwise `/verify-email`.

---

## 4. Complete Functional Inventory

| # | Control / Feature | Behavior & Rules |
|---|---|---|
| 1 | **Header Controls & Tabs** | Language Switcher (`EN`/`AR`) + Theme Toggle at top; `Log In` / `Sign Up` underline tab bar below brand mark. |
| 2 | **First Name & Last Name** | Side-by-side on width `>= 380dp` (`Row` with `12dp` gap) or stacked vertically on `compactSmall (< 360dp)` to prevent cramped Arabic/English inputs. Trimmed on submit; non-blank required (`@NotBlank`). |
| 3 | **Business Name** | `LucideIcons.building` prefix icon; trimmed on submit; non-blank required (`@NotBlank`). Creates the initial `Business` (`primary = true`, `accessMode = "EDITABLE"`, `role = "OWNER"`). |
| 4 | **Email Address** | `LucideIcons.mail` prefix icon; `TextInputType.emailAddress`, `TextDirection.ltr`, `autocorrect: false`; validated via email regex before submit. |
| 5 | **Password + `PasswordStrengthIndicator`** | `LucideIcons.lock` prefix + `Eye`/`EyeOff` visibility toggle, `TextDirection.ltr`.<br>**Mobile Parity Fix:** Integrates Web's `PasswordStrengthIndicator.tsx` directly below the password field once `password.isNotEmpty`. Displays:<br>- Progress bar (`0–5` passed rules)<br>- Localized strength label: `Weak` (`<=1`), `Fair` (`2`), `Good` (`3`), `Strong` (`4`), `Very Strong` (`5`)<br>- 5-rule live checklist: `>= 8 chars`, `uppercase [A-Z]`, `lowercase [a-z]`, `number [0-9]`, `special char [!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?\`~]`. |
| 6 | **Client Validation Rules** | Backend `@Size(min=8)` enforces minimum 8 chars (`RegisterRequest.java`); Mobile enforces non-blank fields, valid email format, and either enforces all 5 strength rules (recommended for security parity with `ResetPassword`) or minimum 8 chars + visual strength warning. *(Decision: enforce `length >= 8` + warn or require strong password? Let's match Web's `minLength={8}` hard requirement on submit while highlighting all 5 strength rules visually so existing backend test accounts with 8-char passwords remain compatible, OR document clearly that backend requires `@Size(min=8)` while UI encourages all 5 rules.)* |
| 7 | **Submit (`POST /api/v1/auth/register`)** | Sends `{ firstName, lastName, businessName, email, password }`. Disables all fields & shows `AfabLoader` (`xs`). |
| 8 | **Post-Registration Session & Routing** | On `200 AuthResponse`:<br>- Stores `accessToken` in `SessionTokenHolder` (RAM)<br>- `PersistCookieJar` captures `refreshToken` (default 7d) and `afab_csrf`<br>- Stores `activeBusinessId = res.user.businessId`<br>- Checks `res.verificationEmailSent`: if `false` (SMTP unreachable during registration, `AuthService.java:162-166`), passes `emailDeliveryFailed: true` flag to `/verify-email` so the user knows to tap **Resend Code**!<br>- Passes `res.devOtp` (if non-null in local/dev) via transient `GoRouter.extra` (not URL query in prod) and routes to `/verify-email`. |
| 9 | **Error Handling** | - `400 REGISTRATION_FAILED` (e.g., duplicate email `"Unable to complete registration. If you already have an account, please sign in."`) → inline error banner.<br>- `400` `ApiError.fieldErrors` → map per-field backend validation errors directly under matching inputs.<br>- `429 RATE_LIMITED` (5 req/min on `REGISTER`) → `errorRateLimited`.<br>- `503 RATE_LIMIT_UNAVAILABLE` / network error → localized banner. |
| 10 | **Omitted Dead Controls** | **Omit** `"or continue with"` divider and `"Continue with Google"` button. |

---

## 5. Data Requirements

### 5.1 Request DTO (`RegisterRequest.java`)
```dart
@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String firstName,     // @NotBlank
    required String lastName,      // @NotBlank
    required String email,         // @NotBlank @Email
    required String password,      // @NotBlank @Size(min: 8)
    required String businessName,  // @NotBlank
  }) = _RegisterRequest;
}
```

### 5.2 Response DTO (`AuthResponse.java`)
- `accessToken: String`
- `csrfToken: String?`
- `user: AuthUserDto` (`emailVerified: false`, `onboardingComplete: false`, `businessId: UUID`)
- `devOtp: String?` (only exposed when backend `spring.profiles.active` is `local`/`dev` AND `afab.auth.allow-dev-otp=true`)
- `verificationEmailSent: bool` (defaults to `true`; `false` if SMTP send failed non-fatally during `register()`)

---

## 6. API Integration

| Endpoint | Method | Auth / Rate Limit | Request Body | Responses & Errors |
|---|---|---|---|---|
| `/api/v1/auth/register` | `POST` | Public<br>Rate Limit: `REGISTER` = **5 req/min** per IP & per email | `{ firstName, lastName, email, password, businessName }` | - `200 OK`: `AuthResponse` + `Set-Cookie: refreshToken` (7d), `afab_csrf`<br>- `400 REGISTRATION_FAILED`: enumeration-safe duplicate email message<br>- `400`: `ApiError.fieldErrors` (`firstName`, `lastName`, `email`, `password`, `businessName`)<br>- `429 RATE_LIMITED`: `Retry-After` header<br>- `503 RATE_LIMIT_UNAVAILABLE` |

---

## 7. Modal, Drawer and Dialog Inventory
- **None.** Inline field validation, `PasswordStrengthIndicator` expansion, and top error alert banner handle all feedback in-place.

---

## 8. Mobile Adaptation
- **Responsive Name Fields:** `firstName` & `lastName` sit side-by-side (`Row`) on screens `>= 360dp` and stack vertically (`Column`) on `compactSmall (< 360dp)` or when font scale `>= 1.3x`.
- **Keyboard Flow (`TextInputAction.next` chain):** `firstName` → `lastName` → `businessName` → `email` → `password` (`done` submits).
- **Autofill:** `AutofillGroup` with `AutofillHints.givenName`, `AutofillHints.familyName`, `AutofillHints.organizationName`, `AutofillHints.email`, `AutofillHints.newPassword`.
- **Tablet (`>= 600dp`):** Centered `maxWidth: 460dp` card (or split hero + form on `>= 840dp` landscape).

---

## 9. Visual Design
- **Tokens (`AfabColors`):** Same `AuthScaffold` surface (`background`, `AfabCard` `surface`, `surfaceInset` fields, `12dp` control radius).
- **PasswordStrengthIndicator Visual Spec (`PasswordStrengthIndicator.tsx`):**
  - Hidden when `password.isEmpty`; smoothly expands below password input.
  - Top row: uppercase `"PASSWORD STRENGTH"` (`11sp`, `textMuted`) on start + color-coded level (`Weak` red `#EF4444`, `Fair`/`Good` amber `#F59E0B`, `Strong`/`Very Strong` emerald `#10B981`) on end.
  - `6dp` rounded track (`#E5E7EB` light / `#1F2937` dark) with animated fill width `(passed / 5) * 100%`.
  - 5-item checklist: `16x16dp` circular badge (`#10B981` + white `Check` when met; bordered `X` when unmet) + `12sp` label.
- **Icons (`lucide_icons_flutter`):** `LucideIcons.user`, `LucideIcons.building`, `LucideIcons.mail`, `LucideIcons.lock`, `LucideIcons.eye`, `LucideIcons.eyeOff`, `LucideIcons.check`, `LucideIcons.x`, `LucideIcons.alertCircle`.

---

## 10. Localization
All keys verified in `Web/project/frontend/messages/{en,ar}/auth.json`:
- `signupTitle`: `"Create your account"` / `"إنشاء حساب جديد"`
- `signupSubtitle`: `"Join thousands of business owners today."` / `"انضم إلى آلاف أصحاب الأعمال اليوم."`
- `firstName`, `firstNamePlaceholder`, `lastName`, `lastNamePlaceholder`
- `businessName`, `businessNamePlaceholder`
- `email`, `emailPlaceholder`
- `password`, `passwordSignupPlaceholder`
- `signupButton`: `"Sign Up"` / `"إنشاء حساب"`
- `hasAccount`: `"Already have an account?"` / `"لديك حساب بالفعل؟"`
- `signupFailed`, `errorRateLimited`, `errorNetworkFailure`, `errorServerFailure`
- **Password Strength Keys (`12` keys):** `pwStrengthLabel`, `pwStrengthWeak`, `pwStrengthFair`, `pwStrengthGood`, `pwStrengthStrong`, `pwStrengthVeryStrong`, `pwRequirementsLabel`, `pwReqLength`, `pwReqUppercase`, `pwReqLowercase`, `pwReqNumber`, `pwReqSpecial`.
- **RTL Rules:** Email & Password fields forced LTR (`TextDirection.ltr`); Name, Business Name, and Password Strength Checklist align naturally with `TextDirection.rtl`.

---

## 11. Animation and Interaction Design
- **Card Entrance:** `280 ms` fade + `12 dp` slide up.
- **Password Strength Expand:** `AnimatedSize` + `AnimatedOpacity` (`250 ms`) when user types first character; progress bar width & color animate over `300 ms`; check badges pop (`1.0 → 1.2 → 1.0`) when a requirement flips from unmet to met.
- **Submit:** Button disables and renders `AfabLoader(size: AfabLoaderSize.xs)`; on error, error banner slides down (`200 ms`) and scrolls to top of card so it's never hidden below keyboard.

---

## 12. Accessibility
- Explicit `Semantics` labels for every input (including `lastName` which has no leading icon), password visibility toggle, and each requirement row (`"At least 8 characters, met"` / `"not met"`).
- Announce strength level changes politely (`Semantics(liveRegion: true)` throttled to level changes only so TalkBack/VoiceOver is not noisy on every keystroke).
- Minimum `48dp` touch targets on submit button, tab switcher, visibility toggle, and footer `"Log In"` link.

---

## 13. Acceptance Criteria
1. All 5 fields (`firstName`, `lastName`, `businessName`, `email`, `password`) validate before network submission and trim whitespace cleanly.
2. Typing into `password` reveals the 5-rule `PasswordStrengthIndicator` with live progress bar and localized EN/AR strength labels.
3. Successful registration calls `POST /api/v1/auth/register`, stores `accessToken` in RAM, persists `refreshToken` + `afab_csrf` in `PersistCookieJar`, sets `activeBusinessId`, and navigates to `/verify-email`.
4. Duplicate email returns `400 REGISTRATION_FAILED` and displays the backend's enumeration-safe error message without leaking account existence.
5. Exceeding 5 registrations/minute triggers `429 RATE_LIMITED` and shows `errorRateLimited`.
6. No inert Google OAuth button is displayed.
7. If `verificationEmailSent == false`, `/verify-email` is notified so the user sees an actionable Resend prompt.

---

## 14. Dependencies and Risks
- **Dependencies:** `dio`, `dio_cookie_manager`, `flutter_riverpod`, `go_router`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  - **Risk:** `signup/page.tsx` does not prevent submitting a weak 8-character password (only `minLength={8}`), while `reset-password/page.tsx` enforces all 5 rules. **Mitigation:** Document whether product wants strict 5-rule enforcement on Sign Up too; enforce `>= 8` chars at minimum (matching `RegisterRequest.java`) and highlight unmet rules visually in `PasswordStrengthIndicator` (optionally gating submit behind all 5 rules if confirmed by product).
  - **Risk:** `AuthService.register()` sets initial `business.currency = "USD"` (`AuthService.java:145`). **Mitigation:** Ensure Onboarding (`AUTH-08`) always runs before `/dashboard` so users in MENA/Europe select their true base currency (including `TND`).
