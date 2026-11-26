# LOGIN_SCREEN (`AUTH-02`)

## 1. Screen Identity
- **Screen ID:** `AUTH-02`
- **Screen Name:** Login (Email & Password Sign-In)
- **Flutter Route Name & Path:** `AppRoutes.login` — `/login`
- **Feature Module:** `lib/features/auth/presentation/login_screen.dart`
- **Web Equivalent(s):**
  - `Web/project/frontend/app/[locale]/(auth)/layout.tsx` (`AuthLayout`)
  - `Web/project/frontend/app/[locale]/(auth)/login/page.tsx` (`LoginPage`)
  - *(Note: `Web/project/frontend/components/auth/LoginCard.tsx` is an older unused component referencing `Auth.login.*` keys; `app/[locale]/(auth)/login/page.tsx` is the live routed page.)*
- **Priority:** P0 (Core Entry Flow)
- **Status Parity:** Implemented and Connected on Web (`POST /api/v1/auth/login`), with one inert UI element (`continueGoogle` Google button with no `onClick` handler) that is **explicitly omitted on Mobile**.

---

## 2. Purpose
`LoginScreen` authenticates an existing AFAB user with email and password, manages session persistence duration via `rememberMe` (`7 days` default vs `30 days`), surfaces backend brute-force lockout (`15 minutes` after 5 failed attempts) and Redis rate-limit errors (`10 req/min`), and transitions either to `TwoFactorChallengeScreen` (`/two-factor`) when `requiresTwoFactor == true` or directly to `/verify-email`, `/onboarding`, or `/dashboard`.

---

## 3. Original Web Structure
In `Web/project/frontend/app/[locale]/(auth)/layout.tsx` and `login/page.tsx`:
- **Shell (`(auth)/layout.tsx`):**
  - Animated stars background (`AnimatedStars`), top-right (top-left in RTL) `LanguageSwitcher` + `ThemeToggle`.
  - Desktop two-column split (`45%/50%` branding hero + `AuthHeroGraphic` + testimonial; `55%/50%` form card). On mobile viewports (`< lg`), hero panel is hidden and replaced by a compact centered AFAB logo + `"AFAB"` wordmark above the form card (`afab-card max-w-[440px]`).
- **Card Content (`login/page.tsx`):**
  1. **Tab Switcher:** Two-tab underline bar (`loginTab` active vs `signupTab` linking to `/signup`).
  2. **Header:** `loginTitle` (`"Log in to your account"`) + `loginSubtitle` (`"Welcome back! Please enter your details."`).
  3. **Inline Error Alert Banner:** Red pill/box showing mapped `ApiError` text (plus `sonner` toast error for `5000 ms`).
  4. **Email Field (`#login-email`):** `Mail` icon, `type="email"`, `autoComplete="email"`, `required`.
  5. **Password Field (`#login-password`):** `Lock` icon, `type="password|text"`, `Eye`/`EyeOff` visibility toggle with `aria-label`, `autoComplete="current-password"`, `required`.
  6. **Options Row:** `rememberMe` checkbox (`"Remember for 30 days"` / `"تذكرني"`) + `forgotPassword` link (`/forgot-password`).
  7. **Primary Submit Button (`#login-submit`):** Full-width `afab-btn-primary` with `AfabLoader(size="xs")` while loading, or `loginButton` + directional `ArrowRight`.
  8. **Dead Social Section (OMIT ON MOBILE):** `"or continue with"` divider + `#login-google` button (`Continue with Google`) — has no `onClick`, no OAuth endpoint, and no backend integration.
  9. **Footer Link:** `noAccount` + `signupTab` link to `/signup`.

---

## 4. Complete Functional Inventory

| # | Control / Feature | Behavior & Validation |
|---|---|---|
| 1 | **Header Utility Controls** | Compact top bar inside `SafeArea` with **Language Switcher** (`EN` ↔ `AR`, updates `localeProvider` immediately) and **Theme Mode Toggle** (`Light` / `Dark` / `System`). |
| 2 | **Login / Sign Up Tab Switcher** | Segmented / underline tab bar at top of form switching between `/login` (`AUTH-02`) and `/signup` (`AUTH-04`). Preserves typed email if switching tabs (optional UX polish). |
| 3 | **Email Input** | Trims leading/trailing whitespace on submit; validates non-empty & email format (`^[^\s@]+@[^\s@]+\.[^\s@]+$`) inline on submit/blur; `TextInputType.emailAddress`, `AutofillHints.email`, `TextDirection.ltr` forced even in Arabic RTL. |
| 4 | **Password Input** | Obscured by default (`obscureText: true`); trailing `Eye` / `EyeOff` icon button toggles visibility; `AutofillHints.password`, `TextDirection.ltr` forced; non-empty required check. |
| 5 | **Remember Me Checkbox (`rememberMe`)** | Boolean toggle (`false` default). Passed to `POST /api/v1/auth/login` (`rememberMe`). Backend sets `refreshToken` & `afab_csrf` cookie `maxAge` to **30 days (`2,592,000 s`)** when `true`, or **7 days (`604,800 s`)** (`afab.jwt.refresh-expiration-ms`) when `false`. Also passed forward to `TwoFactorChallengeScreen` if 2FA is required! |
| 6 | **Forgot Password Link** | Navigates to `/forgot-password` (`AUTH-06`), pre-filling the email field if the user already entered a valid email. |
| 7 | **Submit (`POST /api/v1/auth/login`)** | Disables form inputs & button while in flight; displays `AfabLoader` (`xs`) inside button. Unfocuses keyboard (`FocusScope.of(context).unfocus()`) before request. |
| 8 | **2FA Branching** | If response has `requiresTwoFactor == true` and non-empty `twoFactorToken`: **does NOT persist session cookies** (none are returned). Navigates to `/two-factor` passing `{ twoFactorToken, rememberMe, email }` in route extra/state (never in URL query string). |
| 9 | **Direct Authenticated Routing** | If `requiresTwoFactor == false`: stores `accessToken` in `SessionTokenHolder` (RAM), cookies (`refreshToken`, `afab_csrf`) are captured by `PersistCookieJar`, sets `activeBusinessId = user.businessId`, invalidates stale cached providers, and routes:<br>- `!user.emailVerified` → `context.go('/verify-email')`<br>- `!user.onboardingComplete` → `context.go('/onboarding')`<br>- Else → `context.go('/dashboard')`. |
| 10 | **Lockout & Rate-Limit Error Mapping** | Maps backend error codes accurately (see Section 6):<br>- `401 INVALID_CREDENTIALS` → `t("errorInvalidPassword")` (Note: backend returns enumeration-safe `"Invalid email or password."` for both missing email and wrong password; mobile should show localized invalid-credentials text or backend message cleanly without claiming email was/wasn't found).<br>- `403 ACCOUNT_DISABLED` → `t("errorAccountDisabled")`.<br>- `403 ACCOUNT_LOCKED` → displays backend's exact remaining-minutes message (`"Account is temporarily locked... Please try again in X minute(s)."` / `"15 minutes"`) or localized `t("errorAccountLocked")` fallback.<br>- `429 RATE_LIMITED` → `t("errorRateLimited")` + optionally displays `Retry-After` seconds countdown.<br>- `503 RATE_LIMIT_UNAVAILABLE` → localized temporary unavailability message.<br>- Network error → `t("errorNetworkFailure")`. |
| 11 | **Omitted Dead Web Controls** | **Do NOT render** the `"or continue with"` divider or `"Continue with Google"` button (`login/page.tsx:422-450`). No Google/Apple OAuth provider exists in Spring Boot backend. |

---

## 5. Data Requirements

### 5.1 Request DTO (`LoginRequest.java`)
```dart
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,      // @NotBlank @Email
    required String password,   // @NotBlank
    @Default(false) bool rememberMe,
  }) = _LoginRequest;
}
```

### 5.2 Response DTO (`AuthResponse.java`)
- `accessToken: String?` (null when `requiresTwoFactor == true`)
- `csrfToken: String?` (also sent as `Set-Cookie: afab_csrf=...`)
- `user: AuthUserDto?` (`id`, `firstName`, `lastName`, `email`, `businessId`, `avatarUrl`, `emailVerified`, `onboardingComplete`, `twoFactorEnabled`)
- `requiresTwoFactor: bool` (default `false`)
- `twoFactorToken: String?` (5-min JWT with claim `type="2FA_CHALLENGE"`)
- `verificationEmailSent: bool` (default `true`)

### 5.3 Form Controller State (`LoginFormState`)
- `email: String`, `password: String`, `rememberMe: bool`, `obscurePassword: bool`
- `isSubmitting: bool`, `bannerError: String?`, `emailFieldError: String?`, `passwordFieldError: String?`, `rateLimitSecondsRemaining: int?`

---

## 6. API Integration

| Endpoint | Method | Auth / Rate Limit | Headers | Status Codes & Error Mapping |
|---|---|---|---|---|
| `/api/v1/auth/login` | `POST` | Public<br>Rate Limit: `LOGIN` = **10 req/min** per IP & per email (`DistributedRateLimiter`) | `Content-Type: application/json`<br>`CookieManager` captures `Set-Cookie: refreshToken` (`Path=/api/v1/auth`, `HttpOnly`, `SameSite=Lax`) and `afab_csrf` (`Path=/`) | - `200 OK`: `AuthResponse`<br>- `400`: `ApiError` (`fieldErrors` from `@Valid LoginRequest`)<br>- `401 INVALID_CREDENTIALS`: wrong password or unknown email<br>- `403 ACCOUNT_DISABLED`: inactive/deleted user<br>- `403 ACCOUNT_LOCKED`: 5 consecutive wrong passwords → 15-min lockout (`Account temporarily locked...`)<br>- `429 RATE_LIMITED`: `Retry-After` header<br>- `503 RATE_LIMIT_UNAVAILABLE`: Redis rate limiter unavailable |

> **Security Note:** Wrap login submission in `AutofillGroup` so iOS Keychain / Android Credential Manager offers to save credentials only after successful non-2FA login (or after 2FA completion) via `TextInput.finishAutofillContext(shouldSave: true)`.

---

## 7. Modal, Drawer and Dialog Inventory
- **None on Login itself** (errors render inline inside an alert banner at top of the form card + optional `AfabToast` error).
- If the user taps the header **Language Switcher**, switching `en` ↔ `ar` happens immediately inline (or via a compact bottom sheet if additional locale metadata is shown).

---

## 8. Mobile Adaptation
- **Phone (`< 600dp`):** Single-column scrollable `SafeArea` layout (`SingleChildScrollView` + `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`), AFAB monogram header (`56x56dp` icon tile + `"AFAB"` wordmark), `AfabCard` containing Tabs, Title, Error Banner, Form, and Footer link.
- **Tablet (`>= 600dp`):** Reintroduces Web's split layout on landscape (`>= 840dp`) with branding/hero column (`45%`) + centered form card (`maxWidth: 440dp` in `55%` pane), or centered `maxWidth: 460dp` card on portrait tablets (`600–839dp`).
- **Keyboard Ergonomics:**
  - Email field: `textInputAction: TextInputAction.next`
  - Password field: `textInputAction: TextInputAction.done`, `onFieldSubmitted` triggers login submit.
  - `AnimatedPadding` responds to `MediaQuery.viewInsetsOf(context).bottom` so the Submit button remains reachable above the soft keyboard.
- **No Dead Social Buttons:** Omitting the inert Google button eliminates dead-tap confusion and App Store Review rejection for non-functional sign-in buttons.

---

## 9. Visual Design
- **Tokens (`AfabColors`):**
  - Scaffold background: `AfabColors.background` (`#F8F9FB` light / `#060813` dark `midnight`)
  - Card: `AfabCard` (`#FFFFFF` light / `#0C101C` dark, `1px AfabColors.border`, `16dp` radius default, `20–24dp` padding)
  - Inputs: `AfabTextField` (`AfabColors.surfaceInset` `#F9FAFB` / `#080C18`, `1px AfabColors.inputBorder`, `12dp` radius, `primary` `#8B5CF6` focus border + subtle focus ring)
  - Error Banner: `10%` `danger` (`#EF4444`) tint fill, `1px` `danger` (`20%` alpha) border, `12dp` radius, `8dp` dot or `AlertCircle` icon + `12sp` medium text (`#B91C1C` light / `#F87171` dark).
  - Primary CTA: `AfabButton.primary` (`#8B5CF6` fill, `#7C3AED` pressed, min height `48dp`, `12dp` radius, bold `14sp` white text + trailing directional `ArrowRight`).
- **Icons (`lucide_icons_flutter`):** `LucideIcons.mail`, `LucideIcons.lock`, `LucideIcons.eye`, `LucideIcons.eyeOff`, `LucideIcons.arrowRight`, `LucideIcons.globe`.

---

## 10. Localization
All strings map 1:1 from `Web/project/frontend/messages/{en,ar}/auth.json`:
- `loginTab`: `"Log In"` / `"تسجيل الدخول"`
- `signupTab`: `"Sign Up"` / `"إنشاء حساب"`
- `loginTitle`: `"Log in to your account"` / `"تسجيل الدخول إلى حسابك"`
- `loginSubtitle`: `"Welcome back! Please enter your details."` / `"مرحباً بعودتك! يرجى إدخال بياناتك."`
- `email`: `"Email address"` / `"البريد الإلكتروني"`
- `emailPlaceholder`: `"you@example.com"` / `"you@example.com"`
- `password`: `"Password"` / `"كلمة المرور"`
- `passwordPlaceholder`: `"Enter your password"` / `"أدخل كلمة المرور"`
- `rememberMe`: `"Remember for 30 days"` / `"تذكرني"` *(Note: AR text in `auth.json` says `"تذكرني"`; consider adding `(30 يوماً)` or keeping exact Web parity `"تذكرني"`)*
- `forgotPassword`: `"Forgot password?"` / `"هل نسيت كلمة المرور؟"`
- `loginButton`: `"Log In"` / `"تسجيل الدخول"`
- `noAccount`: `"Don't have an account?"` / `"ليس لديك حساب؟"`
- `errorInvalidPassword` / `errorInvalidCredentials`, `errorAccountDisabled`, `errorAccountLocked`, `errorRateLimited`, `errorNetworkFailure`, `errorServerFailure`.
- **RTL & BiDi Rules:** Email and password `TextFormField`s enforce `textDirection: TextDirection.ltr` so email addresses (`user@domain.com`) and password symbols never scramble in Arabic mode, while labels, placeholders, error banners, and checkbox alignment mirror cleanly to RTL.

---

## 11. Animation and Interaction Design
- **Entrance:** Subtle `280 ms` fade + `12 dp` upward slide on the auth card (`Curves.easeOutCubic`), skipped when `MediaQuery.disableAnimationsOf(context)` is true.
- **Tab Indicator:** Animated `2dp` primary underline sliding smoothly between `Log In` and `Sign Up` tabs (`200 ms`).
- **Error Banner:** `AnimatedSize` + fade slide-down when `bannerError != null`.
- **Loading State:** Primary button retains full width and swaps label/arrow for `AfabLoader(size: AfabLoaderSize.xs)` (`20x20dp`).
- **Haptics:** `HapticFeedback.selectionClick()` on `rememberMe` toggle & show-password toggle; `HapticFeedback.heavyImpact()` on lockout/error response.

---

## 12. Accessibility
- `Semantics` labels on email field, password field, password visibility toggle (`"Show password"` / `"Hide password"` localized), `rememberMe` checkbox (entire row tappable with `>= 48dp` hit target), and `forgotPassword` link.
- Error alert banner sets `Semantics(liveRegion: true)` so screen readers announce login errors immediately.
- Focus traversal order: Language/Theme toggles → Tabs → Email → Password → Visibility toggle → Remember Me → Forgot Password → Log In button → Sign Up footer link.

---

## 13. Acceptance Criteria
1. Submitting valid credentials with `rememberMe = false` returns `200 AuthResponse`, stores `accessToken` in RAM, saves 7-day `refreshToken` + `afab_csrf` cookies in `PersistCookieJar`, and navigates to `/verify-email`, `/onboarding`, or `/dashboard`.
2. Submitting valid credentials with `rememberMe = true` results in 30-day (`2,592,000 s`) cookie persistence in `PersistCookieJar`.
3. Submitting credentials for a 2FA-enabled account navigates to `/two-factor` with `twoFactorToken` and `rememberMe`, without writing any partial session cookies.
4. Five consecutive wrong passwords trigger `403 ACCOUNT_LOCKED`, displaying the 15-minute lockout message inline.
5. Exceeding 10 login attempts/minute triggers `429 RATE_LIMITED`, displaying `errorRateLimited`.
6. No Google OAuth button or `"or continue with"` divider appears anywhere on the mobile Login screen.
7. Both Light/Dark themes and EN (LTR) / AR (RTL) render without text clipping at `1.3x` OS text scale.

---

## 14. Dependencies and Risks
- **Dependencies:** `dio`, `dio_cookie_manager`, `flutter_riverpod`, `go_router`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  - **Risk:** Web's `login/page.tsx` maps `INVALID_CREDENTIALS` to `t("errorInvalidPassword")` (`"Incorrect password."`) even when the email doesn't exist, which slightly contradicts backend enumeration resistance (`"Invalid email or password."`). **Mitigation:** Map `INVALID_CREDENTIALS` to `loginFailed` (`"Invalid credentials"` / `"بيانات الدخول غير صحيحة"`) or display backend's safe message rather than confirming email existence.
  - **Risk:** Email keyboard autocorrect or trailing space causes false credential failure. **Mitigation:** Set `autocorrect: false`, `enableSuggestions: false`, and `.trim()` email before sending.
