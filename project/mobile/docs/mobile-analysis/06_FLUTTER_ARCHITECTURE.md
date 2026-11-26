# 06 — Flutter Software Architecture

> **Target SDK:** Flutter `3.44.8` (stable), Dart `3.12.2` (`sdk: ^3.12.2`).
> **Paradigm:** Feature-First Clean Architecture (pragmatic 3-layer separation per feature: `data` / `domain` / `presentation`, avoiding redundant boilerplate where a repository interface or simple notifier suffices).

---

## 1. Recommended Package Stack (Verified Dart 3.12.2 / Flutter 3.44.8 Compatible)

| Concern | Package & Constraint | Rationale |
|---|---|---|
| **State Management & DI** | `flutter_riverpod: ^3.5.0` | Compile-safe provider graph, built-in `AsyncValue` loading/error/data states, clean invalidation on business switch or logout (`ref.invalidate`), zero `BuildContext` coupling in repositories. |
| **Routing & Deep Links** | `go_router: ^18.1.3` | Declarative `StatefulShellRoute.indexedStack` (5 bottom-nav branches + tablet rail), auth/verification/onboarding redirect guards, Universal/App Link support. |
| **HTTP Client & SSE** | `dio: ^5.9.2` | Interceptors for `Authorization`, `X-Business-Id`, single-flight `401` refresh, global `403 PLAN_LIMIT_REACHED`/`BUSINESS_READ_ONLY` events, `ResponseType.stream` for `POST /ai/chat/stream` SSE, `CancelToken`, multipart uploads. |
| **Cookie Persistence** | `dio_cookie_manager: ^3.4.0` + `cookie_jar: ^4.0.9` | Replays backend `HttpOnly` `refreshToken` (`Path=/api/v1/auth`) and `afab_csrf` (`Path=/`) cookies without altering backend auth contract. |
| **Secure Storage** | `flutter_secure_storage: ^10.2.0` | Custom `EncryptedCookieStorage` backend for `PersistCookieJar`, plus biometric lock toggle. Uses Android Keystore AES-GCM and iOS Keychain. |
| **Preferences** | `shared_preferences: ^2.5.4` | Non-sensitive UI state: locale (`en`/`ar`), `AppearanceSettings`, date/number format cache, local-only FX rate alerts, wet signature registry metadata. |
| **Immutable Models & JSON** | `freezed_annotation` + `freezed: ^4.0.2` (dev) + `json_serializable: ^6.15.1` (dev) + `build_runner` (dev) | Type-safe DTOs matching Spring Boot contracts, custom `DecimalJsonConverter` (`String`/`num` → `Decimal`). |
| **Financial Math** | `decimal: ^3.2.6` + `intl: ^0.20.2` | Exact decimal arithmetic matching PostgreSQL `NUMERIC(19,4)` & `NUMERIC(19,6)` without IEEE-754 floating-point drift; localized dates/numbers. |
| **Charts** | `fl_chart: ^1.3.1` | Native touch-interactive Area, Bar, Line, Donut/Pie, and Candlestick/Sparkline charts replacing Recharts & custom SVGs. |
| **Icons & Fonts** | `lucide_icons_flutter: ^3.1.25` + `google_fonts: ^8.2.1` | 1:1 icon parity with `lucide-react` and AFAB's 6 typography presets (`Inter`, `Poppins`, `Playfair Display`, `Amiri`, `JetBrains Mono`, `Cairo`, `Montserrat`, `Reem Kufi`, `Cinzel`). |
| **Media, Files & Voice** | `image_picker: ^1.2.4`, `file_picker: ^13.4.1`, `flutter_image_compress`, `speech_to_text: ^7.5.0` | Receipt camera/gallery, PDF/XLSX/CSV picking (`file_picker` v13+ API: `pickFile()`), pre-upload compression, native STT dictation (`en-US`, `fr-FR`, `ar-TN`). |
| **Exports, PDF & Share** | `pdf: ^3.11.0`, `printing: ^5.15.0`, `excel_community: ^2.6.2`, `share_plus: ^13.3.1`, `open_filex: ^5.0.0`, `path_provider: ^2.1.5` | Native Invoice/Master PDF generation (with Arabic Cairo TTF), `.xlsx` export, CSV/PDF viewing & system share sheet. |
| **Auth, QR, Signature & Misc** | `local_auth: ^3.0.0`, `qr_flutter_plus: ^1.0.1`, `signature: ^5.5.0`, `flutter_markdown_plus: ^1.0.0`, `flutter_custom_tabs: ^2.6.0`, `url_launcher: ^6.3.3`, `cached_network_image: ^4.0.7`, `connectivity_plus: ^6.1.0`, `shimmer: ^3.0.0`, `uuid: ^4.5.3` | Biometrics, 2FA QR, wet-signature pad, AI Markdown, Stripe Custom Tabs, `mailto:`/`wa.me`, network detection, idempotency UUIDs. |
| **Testing (dev)** | `mocktail: ^1.0.5`, `http_mock_adapter` / custom Dio interceptor stubs | Clean unit, provider, widget, and integration tests without codegen mocks. |

---

## 2. Top-Level Directory & Layer Rules

```text
lib/
├── main.dart                     # Bootstrap: WidgetsFlutterBinding, EnvironmentConfig, ProviderScope
├── app/                          # App shell, GoRouter, global theme/locale wiring, lifecycle banners
├── core/                         # Cross-cutting infrastructure (network, auth/CSRF, storage, decimal, errors, l10n, responsive)
├── shared/                       # Reusable AFAB UI kit (KpiCard, AfabCard, AfabLoader, EmptyState, Chart wrappers, Pickers)
└── features/                     # 16 domain modules, each split into data/ domain/ presentation/
```

### Dependency Direction (Enforced by Code Review & Lints)
- `presentation/` → depends on `domain/` (entities, validators, use-cases/notifiers) and `shared/` + `core/theme` + `core/l10n`. **Never** imports `dio` or raw DTOs directly.
- `domain/` → pure Dart (`Decimal`, entities, failure types, validators). **Never** imports Flutter `material.dart` or `dio`.
- `data/` → DTOs (`fromJson`/`toJson`), remote data sources (`Dio`), local stores (`SharedPreferences`/`FlutterSecureStorage`), and repository implementations mapping DTOs → domain entities.
- Features **never** cross-import another feature's `data/` layer; cross-feature communication flows through `core/` events (`sessionProvider`, `activeBusinessProvider`, `subscriptionQuotaProvider`, `copilotLauncherProvider`) or shared `domain/` contracts.

---

## 3. Core Infrastructure Modules (`lib/core/`)

1. **`core/config/env.dart`:** `--dart-define=API_BASE_URL=...` (default `http://10.0.2.2:8080/api/v1` for Android emulator / `http://127.0.0.1:8080/api/v1` for iOS simulator), `WEB_APP_URL` for Stripe return matching, `ENVIRONMENT` (`local`/`staging`/`prod`).
2. **`core/network/dio_client.dart`:** Configures `BaseOptions(connectTimeout: 15s, receiveTimeout: 30s)`, plus dedicated `sseDio` (`receiveTimeout: 130s` matching backend 120s SSE timeout + 6s ping).
3. **`core/network/interceptors/`:**
   - `CookieManager` (`PersistCookieJar` backed by `EncryptedCookieStorage`)
   - `AuthInterceptor` (attaches `Authorization: Bearer`, handles single-flight `POST /auth/refresh` with `X-CSRF-Token` on 401, triggers logout on `REFRESH_TOKEN_REUSE`)
   - `TenantInterceptor` (attaches `X-Business-Id` from `activeBusinessIdProvider`)
   - `ApiErrorInterceptor` (maps `GlobalExceptionHandler` JSON into typed `AppFailure`: `ValidationFailure` with `fieldErrors`, `PlanLimitReachedFailure`, `BusinessReadOnlyFailure`, `RateLimitedFailure` with `retryAfterSeconds`, `AiUnavailableFailure`, `NetworkFailure`).
4. **`core/network/sse_client.dart`:** Parses `POST /api/v1/ai/chat/stream` `ByteStream` chunks into strongly typed `AiSseEvent` sealed union (`Status`, `Ping`, `Thought`, `ToolStart`, `ToolDone`, `Delta`, `Replace`, `Done`, `Error`).
5. **`core/money/money_formatter.dart` & `decimal_utils.dart`:** `Decimal` parsing/rounding (`scale 4` money, `scale 6` FX, `HALF_UP`), minor-unit map (`3` for `TND/KWD/BHD/OMR/JOD/LYD/IQD`, `0` for `JPY/KRW`, `2` default), and `US/EU/SI/DOT/RAW` format styles.
6. **`core/validation/validators.dart`:** Reusable validators matching Jakarta Bean Validation rules (`@Size`, `@DecimalMin`, email regex, 5-rule password strength, Base64URL token preservation).
7. **`core/logging/app_logger.dart`:** Redacts `Authorization`, cookies, tokens, emails, and financial amounts in debug/release logs (mirroring backend `LogSanitizer`).
