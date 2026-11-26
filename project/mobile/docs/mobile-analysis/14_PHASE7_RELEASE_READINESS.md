# AFAB Mobile — Phase 7 Verification & Release Readiness Report (`P7-01`)

**Date:** 2026-11-26  
**Flutter SDK:** `3.44.8` (stable)  
**App Workspace:** `C:\Users\MSI\Desktop\DEV\AFAB\Mobile`  
**Web Reference Workspace:** `C:\Users\MSI\Desktop\DEV\AFAB\Web` (unmodified; `git status --porcelain` clean)

---

## 1. Phase 7 Production Hardening & Global App-State Parity

All global error, maintenance, routing, logging, and subscription boundary behaviors were hardened and brought to parity with the Web application:

- **Log Redaction (`lib/core/utils/app_logger.dart`):**
  - `AppLogger` sanitizes `Bearer` tokens, cookie values (`refreshToken`, `afab_csrf`), raw 3-segment JWT payloads (`<JWT_REDACTED>`), and email addresses (`<EMAIL_REDACTED>`) via `_sanitize(...)`, exposed via `@visibleForTesting sanitizeForTest(...)`.
  - Raw `print(` call audit across `lib/`: **`0` occurrences**.
- **HTTP Error & Maintenance Differentiation (`lib/core/network/error_interceptor.dart`):**
  - Differentiates HTTP `403`: `PLAN_LIMIT_REACHED` emits `PlanLimitReachedEvent`; `BUSINESS_READ_ONLY` clears active workspace state in `ActiveBusinessHolder` and `PrefsStore` and emits `BusinessReadOnlyEvent`; plain role/permission `403 FORBIDDEN` does not emit global upgrade/lock events.
  - Differentiates HTTP `503`: gateway/infrastructure `503` responses emit `MaintenanceDetectedEvent`, while domain-specific `503` codes (`AI_SERVICE_UNAVAILABLE`, `EMAIL_DELIVERY_FAILED`, `RATE_LIMIT_UNAVAILABLE`, `BILLING_NOT_CONFIGURED`) are excluded and handled locally by feature screens.
- **Global Event Deduplication & Crash Boundaries (`lib/app/afab_app.dart`, `lib/main.dart`, `lib/features/app_states/`):**
  - `AfabApp` deduplicates modal presentation via `_planLimitSheetOpen`, `_readOnlySheetOpen`, and `_handlingSessionExpiry` (reset when `SessionStatus.authenticated` resumes) and guards against re-navigating to `/maintenance` when already on `/maintenance`.
  - `main.dart` registers `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `ErrorWidget.builder` rendering `AfabSafeErrorCard`.
  - `ErrorAndNotFoundScreen` (`APP-04`) is auth-aware (`"Go to Dashboard"` when authenticated vs `"Log In"` when unauthenticated, plus optional `"Back"` when `canPop()`).
  - `PlanLimitSheet` (`APP-02`) maps backend feature keys (e.g., `business.max` → `Workspaces`) and renders a quota `LinearProgressIndicator`.
  - `MaintenanceScreen` (`APP-03`) checks backend health on foreground resume (`WidgetsBindingObserver`), displays `mail.status` telemetry from `/actuator/health`, and launches `mailto:support@afab.ai` with automatic clipboard fallback.
- **Deep-Link Locale Prefix Stripping (`lib/app/router/app_router.dart`):**
  - `GoRouter.redirect` strips `/en` and `/ar` Web locale prefixes (including `/en/...` and `/ar/...`) while preserving full query strings (`token`, `checkout`, `session_id`, `changePlan`) and resolving Web aliases such as `/dashboard/plans` → `/plans`.
- **Splash & Navigation Hero Integrity:**
  - `AuthScaffold` header logo uses `Flexible` to eliminate horizontal overflow on compact phone viewports (`320px`).
  - Unique `heroTag` values were assigned across all 7 `FloatingActionButton.extended` widgets (`transactions_new_fab`, `invoices_new_fab`, `expenses_new_fab`, `revenue_new_fab`, `customers_new_fab`, `budgets_new_fab`, `recurring_new_fab`) so `StatefulShellRoute.indexedStack` and modal/404 `PageRoute` transitions never trigger duplicate Hero tag assertions.

---

## 2. Automated Verification Matrix

### Static Analysis & Hygiene
| Check | Command / Scope | Observed Result |
|---|---|---|
| Dart Static Analyzer | `flutter analyze --no-pub` | `No issues found! (ran in 4.3s)` |
| ARB Translation Parity | `lib/core/l10n/app_en.arb` vs `app_ar.arb` | **1,452 EN keys / 1,452 AR keys** (`0` missing, `0` extra) |
| Logging Hygiene | `Select-String "^\s*print\("` across `lib/**/*.dart` | **`0` raw `print(` calls** |
| Web Repo Integrity | `git -C "C:\Users\MSI\Desktop\DEV\AFAB\Web" status --porcelain` | **Clean** (empty output) |

### Automated Test Suite (`flutter test --no-pub`)
- **Result:** **`+110: All tests passed!`** (`0` failed, `0` skipped, wall time `22s`).
- **Suite Inventory (30 test files + 1 shared E2E harness):**
  - **Unit Tests (`test/unit/`, 13 files):**
    `auth_interceptor_test.dart`, `business_ops_dtos_test.dart`, `dashboard_dto_test.dart`, `env_test.dart`, `financial_dtos_and_csv_test.dart`, `money_formatter_test.dart`, `nlp_transaction_parser_test.dart`, `phase4_intelligence_test.dart`, `phase5_ai_copilot_test.dart`, `phase6_plans_and_settings_test.dart`, `phase7_security_and_errors_test.dart`, `receipt_validator_test.dart`, `validators_test.dart`.
  - **Widget, Screen & Responsive Matrix Tests (`test/widget/`, 16 files):**
    `ai_copilot_screen_test.dart`, `app_states_screens_test.dart`, `auth_screens_test.dart`, `budgets_and_recurring_test.dart`, `calendar_screen_test.dart`, `currencies_screens_test.dart`, `customers_screens_test.dart`, `dashboard_shell_test.dart`, `financial_core_screens_test.dart`, `global_copilot_and_memory_test.dart`, `invoices_screens_test.dart`, `plans_screens_test.dart`, `reports_screen_test.dart`, `responsive_rtl_accessibility_sweep_test.dart` (`7` screens × 2 extreme matrices = 14 rendered frames with captured `FlutterError.onError` assertions), `settings_screens_test.dart`, `splash_screen_test.dart`.
  - **End-to-End Integration Harness (`test/integration/` + `integration_test/`):**
    - `test/integration/app_e2e_flows_test.dart` + `test/integration/e2e_harness.dart`: Full unmocked DI/Router/Interceptor flow (`Splash -> Login -> 2FA -> Dashboard -> Finance -> Invoices -> Copilot -> More/Settings -> 404 NotFound recovery -> 503 Maintenance health recovery -> SessionExpiredEvent -> Login`).
    - `integration_test/app_e2e_test.dart`: Device/emulator integration runner invoking `runAllAfabE2eJourneys` via `IntegrationTestWidgetsFlutterBinding` (wired with `integration_test` SDK dev dependency in `pubspec.yaml`).

---

## 3. Responsive, RTL & Accessibility Sweep Findings Fixed

Tested across two boundary configurations in `test/widget/responsive_rtl_accessibility_sweep_test.dart`:
- **Matrix A (Compact Accessibility Phone):** `320x568` logical px, `textScale = 1.3`, Light theme, `en` LTR
- **Matrix B (OLED Dark Tablet RTL):** `1280x800` logical px, `textScale = 1.0`, OLED Dark theme (`AfabDarkSurface.oled`), `ar` RTL

| Widget / Screen | Root Issue Surfaced | Fix Applied |
|---|---|---|
| `lib/features/auth/presentation/widgets/auth_scaffold.dart` | Top header logo `Row` overflowed on `320px` compact width | Wrapped logo container with `Flexible` |
| `lib/shared/widgets/afab_kpi_card.dart` | Top header icon + AI button + `46px` sparkline overflowed 2-column KPI cells on `320px` | Compact `30x30` icon badge + `Expanded` trailing `Row` with `Flexible(child: FittedBox(fit: BoxFit.scaleDown, ...))` around sparkline |
| `lib/features/transactions/presentation/widgets/quick_add_bar.dart` | Unflexed `Text(l10n.txQuickAddTitle)` overflowed header `Row` by `40px` at `1.3x` scale | Wrapped title `Text` in `Expanded(..., maxLines: 2, overflow: TextOverflow.ellipsis)` |
| `lib/features/transactions/presentation/transactions_screen.dart` | `OutlinedButton.icon` Filters button + search `TextFormField` overflowed `320px` by `124px` | Renders compact `IconButton.outlined` (with localized tooltip & filter count `Badge`) when viewport width `< 380` |
| `lib/features/dashboard/presentation/widgets/budget_overview_card.dart` | Header `Row` (`Expanded(Column)` + `TextButton`) squeezed title text and overflowed `250px` inner card width by `28px` | Replaced with `LayoutBuilder` that stacks title block cleanly above end-aligned `TextButton` when card width `< 310` |
| `lib/features/ai/presentation/widgets/copilot_composer.dart` | Bottom toolbar `Row` overflowed `266px` inner width by `1.6px` at `1.3x` scale | Tightened attach/send `minimumSize` (`34`/`38`), inter-item spacing, and `MaterialTapTargetSize.shrinkWrap` |
| 7 Feature FABs (`budgets`, `customers`, `expenses`, `invoices`, `recurring`, `revenue`, `transactions`) | Duplicate `<default FloatingActionButton tag>` runtime crash when pushing routes over `IndexedStack` | Assigned distinct explicit `heroTag` strings to each `FloatingActionButton.extended` |

---

## 4. Security, Privacy & Platform Release Config Audit

- **Android Activity & Biometrics (`android/app/src/main/kotlin/com/example/afab_mobile/MainActivity.kt`):** Uses `FlutterFragmentActivity` required by `local_auth ^3.0.2`.
- **Android Manifest Security (`android/app/src/main/AndroidManifest.xml`, `src/debug/AndroidManifest.xml`, `src/profile/AndroidManifest.xml`):**
  - Production manifest enforces `android:allowBackup="false"`, `android:usesCleartextTraffic="false"` (HTTPS-only), `android:enableOnBackInvokedCallback="true"` (predictive back), and `afab://` deep-link intent filter.
  - Debug & profile manifests override `tools:replace="android:usesCleartextTraffic"` to `true` for local `http://10.0.2.2:8080` API development.
- **Android R8, Shrinking & Conditional Signing (`android/app/build.gradle.kts`, `android/app/proguard-rules.pro`):**
  - Release build enables `isMinifyEnabled = true` and `isShrinkResources = true`.
  - Keep rules cover Flutter engine/embedding classes, AndroidX Biometric, Google Tink encrypted storage, `speech_to_text`, networking (`okhttp3`/`okio`), and optional Play Core deferred component `-dontwarn` suppressions.
  - Conditionally loads `android/key.properties` for Play Store upload signing and falls back cleanly to debug signing locally when `key.properties` is absent.
- **iOS Config (`ios/Runner/Info.plist`):**
  - Configures usage descriptions (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSFaceIDUsageDescription`), `NSAllowsLocalNetworking`, and `CFBundleURLTypes` (`ai.afab.mobile` / scheme `afab`).
- **Secrets Hygiene (`.gitignore`, `.env.example`):**
  - `.gitignore` excludes `.env`, `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, `app.*.symbols`, `app.*.map.json`, and `build/debug-info/`. `.env.example` provides safe non-secret templates only.

---

## 5. Release Build Smoke-Test Results

1. **Android Release APK (R8 + Code Shrinking + Dart Obfuscation + Split Debug Info):**
   - **Command:** `flutter build apk --release --obfuscate --split-debug-info=build/debug-info`
   - **Result:** **PASSED** (`exit code 0`, `181.3s` Gradle `assembleRelease`)
   - **Output Artifact:** `build\app\outputs\flutter-apk\app-release.apk` (`87,712,708` bytes / `83.6 MB`, icon fonts tree-shaken 94.5%–99.8%)
   - **Split Debug Symbol Files (`build/debug-info/`):**
     - `app.android-arm.symbols` (`5,530,440` bytes)
     - `app.android-arm64.symbols` (`6,384,200` bytes)
     - `app.android-x64.symbols` (`6,391,696` bytes)
2. **Windows Desktop AOT Release Build (Host Secondary Check):**
   - **Command:** `flutter build windows --release`
   - **Result:** **FAILED (`exit code 1`) in third-party C++ plugin `local_auth_windows`**
   - **Cause:** Visual Studio Build Tools 2026 (`MSVC 14.51.36231`) rejects `<experimental/coroutine>` inside the upstream `local_auth_windows` C++ plugin (`error C2338: STL1011`). All AFAB Dart code and Flutter assets target Android/iOS cleanly.

---

## 6. Pre-Store Submission Checklist

### Android (Google Play)
- [ ] Replace placeholder `com.example.afab_mobile` (`namespace` / `applicationId` in `android/app/build.gradle.kts`, AndroidManifest/Kotlin package) with production reverse-domain application ID.
- [ ] Generate a production Play upload keystore (`.jks`), create `android/key.properties` (git-ignored), and verify signed Play App Bundle build:
  `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`
- [ ] Archive `build/debug-info/*.symbols` and `build/app/outputs/mapping/release/mapping.txt` per release version for Play Console deobfuscation/symbolication.
- [ ] Host `https://<web-domain>/.well-known/assetlinks.json` (Play App Signing SHA-256) if enabling HTTPS App Links in addition to `afab://`.
- [ ] Install Android SDK `cmdline-tools` and run `flutter doctor --android-licenses` if configuring CI/local `adb`/`sdkmanager` tooling on Windows.

### iOS (Apple App Store)
- [ ] Build, sign, and archive on macOS + Xcode (`flutter build ipa --release --obfuscate --split-debug-info=build/debug-info`) with production Bundle ID and Apple Developer Team provisioning.
- [ ] Host `https://<web-domain>/.well-known/apple-app-site-association` for HTTPS Universal Links (`afab://` custom URL scheme already configured in `ios/Runner/Info.plist`).
- [ ] Confirm App Store Review Guidelines 3.1.1 strategy before submission for Stripe Checkout flows opened from `/plans` (`PlansAndSubscriptionScreen`).

### Device Integration CI
- [ ] Run end-to-end device suite against an Android Emulator or iOS Simulator:
  `flutter test integration_test/app_e2e_test.dart`
