# Dependency Map — AFAB Mobile

> **Package Verification:** All versions verified compatible with Flutter `3.44.8` & Dart `3.12.2` on `pub.dev`. *(Not installed yet during documentation phase.)*

---

## 1. Runtime & Dev Dependencies Matrix

| Package | Version Constraint | Layer / Feature Owner | Replaces Web Dependency |
|---|---|---|---|
| `flutter_riverpod` | `^3.5.0` | `app/`, all `features/` | React Context, `useSyncExternalStore`, `client.ts` cache |
| `go_router` | `^18.1.3` | `app/router/` | Next.js App Router, `proxy.ts`, `next-intl` routing |
| `dio` | `^5.9.2` | `core/network/` | `fetchClient`, `fetchRawClient`, `fetchCachedClient` |
| `dio_cookie_manager` + `cookie_jar` | `^3.4.0` / `^4.0.9` | `core/network/`, `core/storage/` | Browser `credentials: "include"` cookie engine |
| `flutter_secure_storage` | `^10.2.0` | `core/storage/` | Browser `HttpOnly` cookie vault + Keychain/Keystore |
| `shared_preferences` | `^2.5.4` | `core/storage/`, `settings/`, `currencies/` | Non-sensitive `localStorage` (`appearance`, `locale`, local alerts, signature vault) |
| `freezed_annotation` | `^3.x` *(matches `freezed` 4)* | `features/*/data/models/` | TypeScript DTO interfaces |
| `json_annotation` | `^4.9.x` | `features/*/data/models/` | `JSON.parse` / `JSON.stringify` |
| `decimal` | `^3.2.6` | `core/money/`, `transactions/`, `invoices/`, `budgets/` | JS `Number` *(upgraded to exact decimal math)* |
| `intl` | `^0.20.2` | `core/l10n/`, `core/money/` | `next-intl`, `date-fns`, `Intl.NumberFormat` |
| `fl_chart` | `^1.3.1` | `shared/widgets/`, `dashboard/`, `currencies/`, `reports/`, `ai/` | `recharts`, custom SVG charts (`BinanceLiveChart`, `FxTrajectoryChart`) |
| `lucide_icons_flutter` | `^3.1.25` | `shared/`, all screens | `lucide-react` |
| `google_fonts` | `^8.2.1` | `core/theme/` | `next/font/google` + Google Fonts CSS |
| `flutter_markdown_plus` | `^1.0.0` | `features/ai/` | `CopilotMarkdown.tsx` |
| `image_picker` | `^1.2.4` | `receipts/`, `ai/`, `settings/` (avatar) | `<input type="file" accept="image/*">` |
| `file_picker` | `^13.4.1` | `receipts/`, `ai/` | `<input type="file" accept=".pdf,.xlsx,.csv,...">` |
| `flutter_image_compress` | latest compatible | `receipts/`, `ai/`, `settings/` | `lib/image-compress.ts` (Canvas resize) |
| `speech_to_text` | `^7.5.0` | `features/ai/` | Web Speech API (`VoiceDictationButton.tsx`) |
| `local_auth` | `^3.0.0` | `features/auth/`, `settings/security` | Native mobile enhancement (Biometric App Lock) |
| `qr_flutter_plus` | `^1.0.1` | `settings/security` | `qrcode.react` (`QRCodeSVG`) |
| `signature` | `^5.5.0` | `settings/signature` | HTML5 `<canvas>` drawing (`SignatureSettings.tsx`) |
| `pdf` + `printing` | `^3.11.0` / `^5.15.0` | `invoices/`, `reports/`, `settings/data_export` | `jspdf`, `openPrintableInvoiceWindow`, backend PDF preview |
| `excel_community` | `^2.6.2` | `settings/data_export` | `xlsx` (`exportMasterToExcel`, `exportDatasetToExcel`) |
| `share_plus` + `open_filex` + `path_provider` | `^13.3.1` / `^5.0.0` / `^2.1.5` | `receipts/`, `reports/`, `invoices/`, `settings/` | `<a download>` Blob URL trigger |
| `flutter_custom_tabs` + `url_launcher` | `^2.6.0` / `^6.3.3` | `plans/`, `ai/` (`mailto:`, `wa.me`) | `window.location.assign`, `mailto:` / `wa.me` links |
| `cached_network_image` | `^4.0.7` | `shared/`, `settings/`, `ai/` | `<img>` browser caching |
| `connectivity_plus` | `^6.1.0` | `core/network/`, `app_states/` | `navigator.onLine` / fetch error checks |
| `shimmer` | `^3.0.0` | `shared/widgets/`, `ai/` | Tailwind `animate-pulse` / `.ai-shimmer-text` |
| `uuid` | `^4.5.3` | `invoices/`, `receipts/` | Client `pay-{id}-{ts}-{rand}` idempotency generator |
| **Dev:** `build_runner`, `freezed`, `json_serializable`, `mocktail` | latest / `^4.0.2` / `^6.15.1` / `^1.0.5` | Codegen & Testing | TypeScript compiler & Jest/Vitest equivalents |

---

## 2. Internal Feature Dependency Graph

```text
app_states & auth ──► core/network, core/storage, core/l10n
        │
        ▼
business & notifications ──► activeBusinessProvider (X-Business-Id)
        │
        ├──► dashboard (reads DashboardSummary + AiPulse + CustomerSummary)
        ├──► transactions ◄──► categories, receipts, currencies/convert
        │       ├──► expenses & revenue (filtered Transaction + FinanceStats views)
        │       ├──► budgets (reads expense categories + transaction spend)
        │       ├──► recurring (reads categories, generates transactions)
        │       └──► calendar (reads date-ranged transactions + optional invoices/recurring)
        ├──► customers ◄──► invoices (Add Order creates invoice; invoices link customerId; payment creates INCOME tx)
        ├──► currencies & reports (independent read/FX/export modules)
        ├──► ai (context-aware across all domains; drafts approve into transactions/invoices/budgets/memory)
        └──► plans & settings (consumes subscription entitlements & global user/business/appearance state)
```
