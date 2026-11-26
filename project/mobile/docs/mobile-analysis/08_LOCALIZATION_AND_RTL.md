# 08 — Localization (EN / AR) & RTL Architecture

> **Verified Sources:** `Web/project/frontend/i18n/routing.ts`, `i18n/request.ts`, and all 30 JSON files in `Web/project/frontend/messages/en/` and `messages/ar/`.

---

## 1. Existing Web Translation Inventory (100% Parity Baseline)

All **15 namespaces** in `messages/en/` and `messages/ar/` contain **1,419 leaf keys** each (**0 missing keys** in AR or EN, **0 ICU placeholder mismatches**):

| Namespace | Key Count | Domain Coverage |
|---|---:|---|
| `settings.json` | 296 | General, Business Profile, Security, 2FA, Sessions, Appearance, Signature, Data Export, Deletion |
| `ai.json` | 227 | Copilot Studio, thinking phases, tools, evidence, drafts, business memory, voice dictation, quota |
| `customers.json` | 153 | Directory, KPIs, orders, activity log, details drawer, validations |
| `auth.json` | 124 | Login, Sign Up, 2FA, Verify Email, Forgot/Reset Password, Onboarding, auth errors |
| `dashboard.json` | 118 | Navigation/sidebar labels, header, KPIs, charts, reminders, lifecycle banners, notifications |
| `transactions.json` | 116 | Ledger, filters, add/edit/split/delete modals, categories, receipts, anomalies, CSV headers |
| `recurring.json` | 64 | Schedules, frequencies, pause/resume, run due |
| `budgets.json` | 59 | Budget cards, alert levels, thresholds, modals |
| `currencies.json` | 55 | FX markets, converter, trajectory, portfolio impact, risk simulator, alerts, directory |
| `common.json` | 54 | Global buttons, status terms, plans/billing shared strings |
| `home.json` | 43 | Public landing page copy *(excluded from mobile)* |
| `revenue.json` | 36 | Revenue KPIs, charts, gross/net |
| `expenses.json` | 34 | Expense KPIs, charts, spending breakdown |
| `invoices.json` | 30 | Invoice status pills, receivables, actions *(many strings currently hardcoded in `invoices/page.tsx`)* |
| `not-found.json` | 10 | 404 screen copy |
| **Total** | **1,419** | **100% structural parity across EN & AR** |

---

## 2. Flutter Localization Implementation (`app_en.arb` & `app_ar.arb`)

- **Mechanism:** Flutter `flutter_localizations` + `gen-l10n` (`synthetic-package: false`, output `lib/core/l10n/generated/app_localizations.dart`) paired with `intl: ^0.20.2`.
- **Key Migration Strategy:**
  - Convert all 14 applicable Web namespaces (`1,376` keys, excluding marketing `home.json`) into namespaced camelCase ARB keys (e.g., `authLoginTitle`, `txSplitBalanced`, `aiThinkingWarmingModel`), preserving `{placeholder}` ICU parameters.
  - Extract and localize **all hardcoded strings missing from Web `messages/*.json`**:
    - `invoices/page.tsx` English-only labels & missing `SENT` status key.
    - `customers.json` missing `orderStatuses` keys (`draft`, `sent`, `unpaid`, `partially_paid`, `paid`, `overdue`).
    - `GeneralSettings.tsx` inline `isArabic` ternaries (`"Live FX Engine"`, fiscal quarters, save banners).
    - `appearance.ts` & `business-data.ts` embedded `nameEn`/`nameAr`, `labelEn`/`labelAr` constants.
    - `CopilotActionDraftCard.tsx`, `CopilotMarkdown.tsx`, `CopilotChartCard.tsx`, `CopilotReminderCard.tsx` hardcoded labels (`EXPENSE`, `INCOME`, `Copy`, `Download CSV`, `Email`, `WhatsApp`).
    - `loading.tsx`, `error.tsx`, `maintenance/page.tsx` hardcoded English fallback screens.
    - `DeleteAccountModal.tsx` Step 2 Arabic warning (fix inaccurate claim that ledgers are deleted; align with English tombstone/anonymization copy).
- **Zero Hardcoded Strings Rule:** Lint/review gate requires `context.l10n.<key>` for every UI label, validation message, error banner, and accessible `Semantics` label.
- **Runtime Switching & Persistence:** `localeProvider` reads/writes `afab_locale` (`'en'` | `'ar'` | `'system'`) in `SharedPreferences` and passes `locale` to `MaterialApp.router`, `AiChatRequest.locale`, and `StripeBillingService` (`en`/`ar`).

---

## 3. RTL, Numbers, Currencies & Directional Rules

1. **Directionality:** Setting `Locale('ar')` automatically applies `TextDirection.rtl` across Flutter `MaterialApp` (`EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`, `Row` reversal, `NavigationBar`/`NavigationRail` mirroring).
2. **Digits & Number Formatting:**
   - Web formats numbers using **Western Arabic digits (`0-9`)** even in Arabic (`ar-TN` locale / explicit format styles `US`, `EU`, `SI`, `DOT`, `RAW`). Mobile MUST maintain Western digits (`0-9`) for financial readability and consistency across `US/EU/SI/DOT/RAW` format styles.
   - **Always wrap currency amounts in `Directionality(textDirection: TextDirection.ltr)`** inside RTL sentences so minus signs (`-$150.00`), currency prefixes (`DT 1,250.000`), and percentages (`+12.5%`) never invert character order in BiDi layout.
3. **3-Decimal Currency Precision:**
   - Implement explicit minor-unit map in `MoneyFormatter`:
     - **3 decimals:** `TND`, `KWD`, `BHD`, `OMR`, `JOD`, `LYD`, `IQD`
     - **0 decimals:** `JPY`, `KRW`
     - **2 decimals (default):** `USD`, `EUR`, `GBP`, `AED`, `SAR`, `QAR`, `MAD`, `EGP`, `DZD`, `CAD`, `AUD`, `CHF`, `TRY`
4. **Dates & Calendar:**
   - Use **Gregorian calendar** localized in English (`en`) and Arabic (`ar`, e.g., `يناير`..`ديسمبر` or `جانفي` depending on `intl` `ar` defaults; never force Hijri calendar).
   - Respect user's `business.dateFormat` preference (`MM/DD/YYYY`, `DD/MM/YYYY`, `YYYY-MM-DD`, `DD MMM YYYY`, `MMM DD, YYYY`, `DD/MM/YY`, `YYYY/MM/DD`).
5. **Directional Icons & Exceptions:**
   - Directional icons (`ArrowRight`, `ChevronRight`, `Send`, `LogOut`, back arrows) must set `matchTextDirection: true` or use `Icons.adaptive` / directional wrappers so they mirror in RTL.
   - **Force LTR (`TextDirection.ltr`)** on: email inputs, OTP 6-digit boxes, password fields, currency codes, customer/invoice IDs (`CST-1001`, `INV-2026-0001`), IBAN/URLs, hex color inputs (`#8B5CF6`), Markdown code blocks, and charts (`fl_chart` time-series X-axis flows left-to-right chronologically in both EN and AR, matching Web Recharts).
   - **AI Language Resolver Notice:** AI Copilot supports 5 response languages (`EN`, `FR`, `AR_MSA`, `AR_DERJA_SCRIPT`, `AR_DERJA_ARABIZI`) independently of UI locale (`en`/`ar`); `CopilotMessageBubble` detects message script directionality per message (`rtl` for Arabic script, `ltr` for English/French/Arabizi).
