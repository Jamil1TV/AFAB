# 00 — Workspace & Repository Discovery

> **Phase:** Architecture & Reverse-Engineering Blueprint (Documentation Only)
> **Generated:** 2026-11-25
> **Source Hierarchy Followed:** Live source code (`Web/project/frontend/`, `Web/project/backend/`) > Controllers/Services/DTOs/Migrations (`V1`–`V28`) > `Web/project/contracts/*.openapi.yaml` > Package manifests (`package.json`, `pom.xml`, `pubspec.yaml`) > `Web/project/Context/*.md` > `Web/project/AFAB_Master_Roadmap.md`.

---

## 1. Workspace Root Map

The local development workspace (`C:\Users\MSI\Desktop\DEV\AFAB`) contains two side-by-side directories:

| Directory | Purpose | Git Repository Status |
|---|---|---|
| `C:\Users\MSI\Desktop\DEV\AFAB\Mobile\` | Target Flutter application scaffold (`afab_mobile`) | **Not a Git repository** (`git status` returns `not a git repository`). |
| `C:\Users\MSI\Desktop\DEV\AFAB\Web\` | Existing AFAB Web & Spring Boot monorepo (`https://github.com/Jamil1TV/AFAB`) | Clean working tree on branch `master`, tracking `origin/master`, HEAD commit `78faa7b` (`fix(ai): lock Copilot page to viewport height for zero-scroll layout`). |

---

## 2. Flutter Project Scaffold Inspection (`Mobile/`)

### 2.1 SDK & Toolchain
- **Flutter SDK:** `3.44.8` (channel `stable`, revision `058e0af2c2`, 2026-07-23)
- **Dart SDK:** `3.12.2` (stable, `windows_x64`)
- **DevTools:** `2.57.0`
- **Package Name (`Mobile/pubspec.yaml`):** `afab_mobile`
- **Version:** `1.0.0+1` (`publish_to: 'none'`)
- **Dart SDK Constraint:** `^3.12.2`

### 2.2 Existing Dependencies (`Mobile/pubspec.yaml`)
- **Runtime:** `flutter` (SDK), `cupertino_icons: ^1.0.8`
- **Dev:** `flutter_test` (SDK), `flutter_lints: ^6.0.0`
- **Assets / Custom Fonts:** None configured yet.
- **Linter Config (`Mobile/analysis_options.yaml`):** Includes `package:flutter_lints/flutter.yaml` with no custom rule overrides.

### 2.3 Platform Scaffolding & Current Entry Point
- **Entry Point (`Mobile/lib/main.dart`):** Standard default Flutter counter demo (`MyApp`, `MyHomePage`, `Colors.deepPurple`, 122 lines).
- **Test (`Mobile/test/widget_test.dart`):** Default counter smoke test (30 lines).
- **Android (`Mobile/android/`):**
  - Gradle Kotlin DSL (`build.gradle.kts`, `settings.gradle.kts`).
  - `namespace = "com.example.afab_mobile"`, `applicationId = "com.example.afab_mobile"`.
  - Java 17 (`JavaVersion.VERSION_17`), Kotlin `JVM_17`, `compileSdk`/`minSdk`/`targetSdk` inherited from `flutter.*`.
  - `AndroidManifest.xml`: single `MainActivity` (`launchMode="singleTop"`, `windowSoftInputMode="adjustResize"`), default launcher icons, `PROCESS_TEXT` query intent. Note: No `INTERNET` permission or deep-link `<intent-filter>` added yet.
- **iOS (`Mobile/ios/`):**
  - `Runner/Info.plist`: `CFBundleDisplayName = Afab Mobile`, `CFBundleName = afab_mobile`, `UIApplicationSceneManifest` (`SceneDelegate`), iPhone portrait + landscape, iPad all 4 orientations.
  - Swift `AppDelegate.swift` (`FlutterImplicitEngineDelegate`) and `SceneDelegate.swift` (`FlutterSceneDelegate`).
- **Desktop / Web Scaffolds Present:** `linux/`, `macos/`, `windows/`, `web/` directories exist from `flutter create`. Primary target for AFAB Mobile is **Android and iOS** (phones and tablets).

---

## 3. Source Repository Inspection (`Web/project/`)

### 3.1 Top-Level Layout
- `Web/.github/workflows/` — CI pipeline configuration.
- `Web/project/frontend/` — Next.js App Router web client.
- `Web/project/backend/` — Spring Boot modular monolith REST/SSE backend.
- `Web/project/contracts/` — 4 OpenAPI 3.x YAML specifications (`identity`, `finance`, `reports`, `subscription`).
- `Web/project/Context/` — Engineering context documents (`README.md`, `AFAB_AI_PROJECT_CONTEXT.md`, `AFAB_FRONTEND_CONTEXT.md`, `AFAB_BACKEND_CONTEXT.md`).
- `Web/project/AI roadmap/AFAB_AI_Features_Specification_v1.2.pdf` — AI feature specification.
- `Web/project/AFAB_Master_Roadmap.md`, `AFAB_AUDIT_REPORT.md`, `full_analyse.md`, `P0_P1_TESTING_GUIDE.md`, `docker-compose.yml`, `.env.example`, `README.md`.

### 3.2 Web Frontend Stack (`Web/project/frontend/package.json`)
- **Framework:** Next.js `^16.4.6` (App Router, Turbopack, `proxy.ts` middleware rewriting/gating routes; `next.config.ts` rewrites `/api/v1/:path*` → `http://127.0.0.1:8080/api/v1/:path*` with `proxyTimeout: 120_000`).
- **UI Runtime:** React `19.2.4`, TypeScript `^5`, Tailwind CSS `^4`, `@base-ui/react ^1.6.0`, `@shadcn/react ^0.2.1`, `lucide-react ^1.25.0`, `framer-motion ^12.42.2`.
- **Charts & Exports:** `recharts ^3.8.0`, `jspdf ^4.2.1`, `xlsx ^0.18.5`, `qrcode.react ^4.2.0`, `input-otp ^1.4.2`, `date-fns ^4.4.0`, `sonner ^2.0.7`.
- **Localization & Theming:** `next-intl ^4.13.2` (`en`, `ar`), `next-themes ^0.4.6`.
- **Route Surface (`frontend/app/`):**
  - **41 total files** under `app/`: **31 `page.tsx` routes**, **4 `layout.tsx` files**, **4 special boundary files** (`[locale]/loading.tsx`, `[locale]/error.tsx`, `(dashboard)/error.tsx`, `[locale]/not-found.tsx`), plus `favicon.ico` and `globals.css`.
  - Additionally, `settings/[...slug]/page.tsx` handles **4 Coming Soon settings tabs** (`users-permissions`, `notifications`, `integrations`, `language`).

### 3.3 Backend Stack (`Web/project/backend/pom.xml` & `src/main/resources/`)
- **Runtime:** Java `21` LTS, Spring Boot `4.1.0` (`spring-boot-starter-parent`).
- **Persistence & Migrations:** PostgreSQL 16 + `pgvector`, Spring Data JPA / Hibernate (`ddl-auto: none`, `jdbc.time_zone: UTC`), **Flyway `V1`–`V28`** (`src/main/resources/db/migration/`).
- **Security & Auth:** Spring Security (stateless JWT), `jjwt 0.12.6`, BCrypt (work factor 12), TOTP 2FA (`TotpService`), HttpOnly `refreshToken` cookie + double-submit `afab_csrf` / `X-CSRF-Token` + `Origin` check (`AuthCookieService`), Redis 7 Lua atomic `DistributedRateLimiter` + `Bucket4j 8.10.1`.
- **Storage, PDF & Billing:** MinIO `9.0.3` (private bucket `afab-receipts`, 10 MB max file size), OpenPDF `2.0.3`, Stripe Java SDK `34.2.0`, Spring Mail (SMTP).
- **AI Engine:** Self-hosted Ollama gateway (`OllamaModelGateway`) calling `gemma4:e4b` (chat, `numCtx=6144`/`8192`) and `embeddinggemma-2:270m` (768-d embeddings stored in `ai_rag_chunks` with HNSW cosine + PostgreSQL FTS hybrid search).
- **API Documentation:** `springdoc-openapi-starter-webmvc-ui 3.0.2` (served at `/api-docs` and `/swagger-ui.html`, disabled in `prod` by default).
- **Controller Surface:** **20 REST controllers exposing 132 endpoints** under `/api/v1/*`.

---

## 4. Contradictions Found Between Context Docs, Contracts, and Actual Source Code

Per the Source-of-Truth Hierarchy, the actual source code supersedes all documentation. Major discrepancies verified:

| Area | What Older Docs / Context Claim | What Actual Source Code Implements |
|---|---|---|
| **AI Copilot** | `AFAB_AI_PROJECT_CONTEXT.md` §6.1 & `AFAB_Master_Roadmap.md` §1 state AI is deferred to P2/P3 and `/dashboard/ai` renders a placeholder. | **Fully implemented (`V27`–`V28`)**: `AiController` has **21 endpoints** (`/api/v1/ai/*`) wired to Ollama (`gemma4:e4b`, `embeddinggemma-2:270m`), `pgvector` hybrid RAG, 16 tools, SSE streaming, multimodal staging, action drafts, business memory, and pulse alerts. |
| **Stripe Billing** | `AFAB_AI_PROJECT_CONTEXT.md` §6.3 states Stripe is scheduled for Phase 19 and Plan UI is local. | **Fully implemented (`V17`–`V19`)**: `StripeBillingController` has **9 endpoints** (`/api/v1/billing/*`) using `stripe-java 34.2.0` (Checkout, Billing Portal, Verify, Upgrade, Downgrade Schedule, Cancel, Resume, History, Webhook) plus `BusinessAllocationService`. |
| **Calendar & Notifications** | `AFAB_Master_Roadmap.md` §1 marks Calendar and Notifications as `❌ Missing` (Phase 14). | `NotificationController` (`/api/v1/notifications`, 3 endpoints) and `DashboardHeader` bell are **implemented & connected** (fed by Stripe billing events). `/dashboard/calendar` exists as a **client-side Month grid** over the first 100 transactions from `GET /api/v1/transactions` (no dedicated calendar backend). |
| **Flyway Migration Count** | `Context/README.md` & `AFAB_BACKEND_CONTEXT.md` mention `V1–V16` or `V1–V23`. | Actual `db/migration/` contains **28 migrations (`V1` through `V28`)**. |
| **Frontend API Client & Proxy** | `AFAB_AI_PROJECT_CONTEXT.md` §4 warns that `fetchClient` calls the backend directly without a Next.js proxy. | `frontend/lib/api/client.ts` uses `/api/v1` in the browser, and `next.config.ts` rewrites `/api/v1/:path*` → `http://127.0.0.1:8080/api/v1/:path*` (`proxyTimeout: 120_000`). |
| **Auth Token Storage** | `AFAB_FRONTEND_CONTEXT.md` §6 claims `lib/auth-store.ts` stores tokens in `localStorage` and writes an `accessToken` cookie. | Refactored in P0: `AuthStore` keeps `accessToken` and `csrfToken` strictly in **JS memory**, actively purges legacy `localStorage` keys, and uses `sessionStorage` only for `afab_user` and `afab_active_business_id`. Refresh token is exclusively an `HttpOnly` cookie. |
| **Customers & `localStorage`** | `AFAB_FRONTEND_CONTEXT.md` §8 says `CustomerService` has a `localStorage` fallback. | Removed in P1.2: `lib/api/customers.ts` calls `/api/v1/customers` directly with explicit error states; only `addOrder` composes invoice + payment APIs. |
| **OpenAPI Contracts** | `AFAB_BACKEND_CONTEXT.md` implies `contracts/*.openapi.yaml` reflect current endpoints. | Only **44 of 132 endpoints (33.3%)** are documented in `contracts/*.openapi.yaml`; **88 endpoints across 14 controllers are missing**, and `identity.openapi.yaml` still documents JSON-body refresh tokens instead of HttpOnly cookies + CSRF. |
| **Settings Tabs (`Signature`, `Language`)** | `AFAB_Master_Roadmap.md` §1 marks Wet Signature as `✅ Built & Verified` and claims `fr` is planned. | `SignatureSettings.tsx` is **100% browser `localStorage`-only** (zero backend persistence, despite claiming encryption). `settings/language` still hits the **Coming Soon** catch-all (`[...slug]/page.tsx`), even though `LanguageSwitcher` exists in headers. |
| **Currencies (`Binance Live`)** | `currencies/page.tsx` & `BinanceLiveChart.tsx` label charts as `"Binance Live Tick"`, `"Live WebStream Active"`, `"Orderbook Synced"`. | **Zero Binance API/WebSocket calls.** `BinanceLiveChart.tsx` generates deterministic sine-wave candles and fake trade volumes client-side. Backend `/currencies/history` & 24h volatility/sparklines are also deterministic math simulations anchored to `open.er-api.com` spot quotes. |
| **FX Rate Alerts** | `/dashboard/currencies` exposes an Alerts tab (`FxRateAlerts.tsx`). | **100% `localStorage`-only** (`afab_fx_rate_alerts`); zero backend persistence, zero evaluation or push/email triggers. |

---

## 5. Summary Inventory Metrics

| Metric | Verified Count |
|---|---|
| Web `app/` files | **41** (`31 page.tsx`, `4 layout.tsx`, `4 error/loading/not-found`, `favicon.ico`, `globals.css`) |
| Coming Soon settings sub-routes (`[...slug]`) | **4** (`users-permissions`, `notifications`, `integrations`, `language`) |
| Backend Controllers | **20** |
| Backend REST & SSE Endpoints | **132** (44 in OpenAPI YAML, 88 undocumented) |
| Flyway Database Migrations | **28** (`V1`–`V28`) |
| Localization Namespaces (`en` & `ar`) | **15** JSON files (**1,419** leaf keys in EN, **1,419** leaf keys in AR) |
| Target Mobile Screen/Flow Specifications | **51** individual `.md` files across 9 feature folders |
| Total Blueprint Documents (`docs/mobile-analysis/`) | **70** `.md` files (19 core/architecture docs + 51 screen specs) |
