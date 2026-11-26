# 11 — Testing & Quality Assurance Strategy

> **Target Test Pyramid:** Fast deterministic `Decimal` & domain unit tests → `mocktail`-backed Riverpod/Widget tests for all 51 screens/flows → Integration tests for critical end-to-end journeys → Responsive, RTL, Accessibility, Performance & Security verification on Android & iOS.

---

## 1. Unit Tests (`test/unit/`)

| Area | Mandatory Test Cases |
|---|---|
| **Financial & FX Precision (`Decimal`)** | 3-decimal (`TND`, `KWD`, `BHD`, `OMR`), 0-decimal (`JPY`), 2-decimal (`USD`, `EUR`) rounding (`HALF_UP`); split remainder exact sum invariant; invoice line subtotal/tax/discount/total match backend `InvoiceService`; `US`/`EU`/`SI`/`DOT`/`RAW` number formatters. |
| **Auth & Security Core** | Single-flight `AuthInterceptor` refresh queuing 5 concurrent 401 requests into 1 `POST /auth/refresh` call; `REFRESH_TOKEN_REUSE` wipes `CookieJar` & RAM JWT; `EncryptedCookieStorage` roundtrip; `X-CSRF-Token` echoed without `Origin` header; Base64URL reset token preserving `_`. |
| **Validators & Parsers** | 5-rule password strength; email regex; `delete <email>` confirmation check; `QuickAdd` NLP parser (including `"$1,500"` comma thousands fix); SSE frame parser (`status`, `ping`, `thought`, `tool_start`, `delta`, `replace`, `done`, `error` across chunk splits). |
| **Repositories & Mappers** | DTO → Domain mapping for all 20 modules (including `CategoryDTO.systemDefault`, `CustomerDTO.outstandingBalance`, `InvoiceDTO.subtotal`, `ApiError`, `PlanLimitReachedFailure`, `BusinessReadOnlyFailure`). |

---

## 2. Widget & Golden Tests (`test/widget/`)

Every one of the **51 mobile screen/flow specifications** requires widget tests covering:
- **4 Core States:** Loading (skeleton/`AfabLoader`), Empty (`EmptyState`), Error (+ Retry button), and Populated Data.
- **Forms & Overlays:** Client validation messages, field-error injection from `400 ApiError.fieldErrors`, dirty-state discard prompt, keyboard insets scrolling.
- **Theme & Appearance Matrix:** Light (`#F8F9FB`) vs Dark (`midnight` `#060813`, `oled` `#000000`), custom accent hex derivation, compact vs comfortable density.
- **Localization & RTL Matrix:** Every screen pumped with `Locale('en')` (LTR) and `Locale('ar')` (RTL), verifying zero `RenderFlex` overflow errors, LTR isolation of `MoneyText`/IDs/OTP inputs, and zero missing translation keys.

---

## 3. Integration Tests (`integration_test/`)

Automated E2E flows (against mocked HTTP adapter in CI + local Docker PostgreSQL/Redis/MinIO/Mailpit smoke suite):
1. Splash cold-start restoration (valid cookie → Dashboard; missing/revoked cookie → Login).
2. Sign Up → Email Verification OTP → 3-Step Onboarding → Dashboard.
3. Login → 2FA TOTP Challenge → Change Password (verifies forced local logout).
4. Business Switcher → Create Business → Switch Workspace (verifies `X-Business-Id` changes & caches clear) → `PLAN_LIMIT_REACHED` paywall sheet.
5. Transaction Create + Foreign Currency FX Quote + Edit + Duplicate (`POST`, not `PUT`) + Split + Receipt Camera/File Upload & Download + Soft Delete.
6. Customer Create → Details (`GET /customers/{id}` loads orders) → Add Order → Invoice Create → Issue (`SENT`) → Record Partial & Full Payment (`Idempotency-Key` retry safety) → Verify linked `INCOME` transaction.
7. Budget Create/Threshold Alert & Recurring Schedule Create/Pause/Run-Due.
8. Financial Reports (P&L, Cash Flow, Comparison, CSV/PDF export + `export.per_month` quota).
9. AI Copilot SSE Streaming (`delta` + `thought` + `tool_start` + `done` chart & action draft) + Attachment Stage + Approve Transaction Draft + Business Memory CRUD.
10. Account Deletion Preflight (`409` blocking businesses → Transfer Ownership or Archive → `DELETE /user/me`).

---

## 4. Responsive, Platform, Performance & Security QA

- **Responsive Matrix:** Automated widget surface tests at: `320x568` (SE small phone), `390x844` (standard iPhone), `430x932` (large phone), `768x1024` (tablet portrait rail), `1280x800` (tablet landscape split-pane), and `1.3x` font scale.
- **Platform Specifics (Android & iOS):**
  - Android: Predictive back gesture, `adjustResize` soft keyboard,Scoped Storage / Photo Picker permissions, Chrome Custom Tabs Stripe return, ProGuard/R8 release shrink verification.
  - iOS: Safe area / Dynamic Island, edge-swipe back, Keychain persistence across app kill/relaunch, `SFSafariViewController` / Universal Links, `Info.plist` camera/photo/microphone/biometrics usage strings.
- **Performance Targets:** Cold launch → first frame `< 1.5s`; 60/120fps scrolling on 100+ item transaction/invoice lists (`ListView.builder` + `const` tiles); zero memory leaks on SSE stream cancellation or image preview disposal.
- **Accessibility:** Minimum `48x48dp` touch targets, `Semantics` labels on all icon-only buttons/badges/charts, WCAG AA (`>= 4.5:1`) contrast across all 8 accent presets in Light & Dark modes, `MediaQuery.disableAnimations` respected.
- **Security Verification:** Inspect Android Backup (`allowBackup=false`), confirm zero tokens in `SharedPreferences`/logs, verify `HttpOnly` refresh cookie never exposed in Dart `print`/crash logs, verify SSL pinning readiness & release build obfuscation (`--obfuscate --split-debug-info`).
