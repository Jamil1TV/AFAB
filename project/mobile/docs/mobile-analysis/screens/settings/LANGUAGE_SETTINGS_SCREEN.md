# SET-08 — Language Settings Screen (`LanguageSettingsScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-08` |
| **Screen Name** | Language & Region Direction (`LanguageSettingsScreen`) |
| **Route Path** | `/settings/language` |
| **Feature Module** | `lib/features/settings/presentation/language_settings_screen.dart` |
| **Web Equivalent** | `settings/[...slug]/page.tsx` (Coming Soon placeholder for `/dashboard/settings/language`) + Header `LanguageSwitcher` |
| **Priority** | P1 (Full Bilingual EN/AR & RTL Support) |

---

## 2. Purpose and User Goal

Deliver a functional, first-class English / Arabic (`LTR` / `RTL`) language selector inside Settings—resolving Web's incomplete `[...slug]` Coming Soon placeholder on `/dashboard/settings/language`—so mobile users can switch UI language, layout direction, and localized date/calendar labels instantaneously without restarting the app.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/settings/[...slug]/page.tsx` | Renders `"Language — Coming Soon"` card when navigating to `/dashboard/settings/language`, even though `LanguageSwitcher` exists in headers via `next-intl` URL routing (`/en/...` ↔ `/ar/...`). | **Resolved on Mobile (`Implemented`):** Replaces the Web Coming Soon stub with a real, instant runtime EN/AR language switcher inside Settings (`SharedPreferences` `afab_locale`), keeping 100% parity with `app_en.arb` & `app_ar.arb`. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `SettingsHomeScreen` (`SET-01`) → **Language** (shows current selection pill `English` / `العربية`).
  - Tablet Settings rail → **Language**.
  - Deep link `/dashboard/settings/language`.
- **Optional Quick Access:** Auth screens (`LoginScreen`, `SignUpScreen`) also host a compact EN/AR switcher pill sharing the same `localeProvider`.

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone & Tablet (`< 600dp` & `>= 600dp`)
1. **Top AppBar:** Title `"Language"` (`t("tabs.language")`).
2. **Language Selection Cards (`AfabCard` group):**
   - **System Default** (`afab_locale = 'system'`): Follows OS device language (`ar` if OS Arabic, else `en` fallback).
   - **English** (`afab_locale = 'en'`): Native label `"English"`, subtitle `"Left-to-Right (LTR) • Gregorian Calendar • Western Digits (0-9)"`, active checkmark ring.
   - **العربية (Arabic)** (`afab_locale = 'ar'`): Native label `"العربية"`, subtitle `"من اليمين إلى اليسار (RTL) • التقويم الميلادي • أرقام قياسية (0-9)"`, active checkmark ring.
3. **Live Formatting & Directionality Preview Card (`AfabCard`):**
   - Shows live preview of how the selected language renders:
     - Layout Direction badge (`LTR` vs `RTL`)
     - Sample Gregorian date (`Oct 20, 2026` / `20 أكتوبر 2026`)
     - Sample monetary value (`$1,250.00` / `DT 1,250.000` rendered LTR inside RTL sentence)
4. **AI Copilot Language Independence Notice (`AfabInsetPanel`):**
   - Informative note explaining that app interface language (`English` / `العربية`) is independent from AI Copilot's 5 response languages (`English`, `French`, `Arabic MSA`, `Tunisian Arabic Script`, `Arabizi`), which can be selected directly inside `AiCopilotScreen`.

---

## 6. UI Components and Interactive Elements

| Component | Details |
|---|---|
| `LanguageOptionCard` | Tappable `AfabCard` (`>= 64dp` height) with circular flag/script emblem (`EN` / `ع` / `Globe`), localized & native language names, layout direction subtitle, and animated radio/checkmark indicator. |
| `DirectionFormattingPreview` | `AfabInsetPanel` demonstrating live `Directionality`, `DateFormatter`, and `MoneyFormatter` (`tabularFigures`, Western digits `0-9`) output for the active locale. |
| `CopilotLanguageInfoNote` | `AfabInsetPanel` with `Sparkles` icon noting AI Copilot's separate 5-language response selector. |

---

## 7. Data Requirements and API Contracts

- **Backend APIs:** **None** (zero backend user-locale endpoint exists; matches Web's client-side `next-intl` locale switch).
- **Local Persistence (`SharedPreferences`):**
  - Key: `afab_locale` (`String`: `'en' | 'ar' | 'system'`, default `'system'` or `'en'`).
- **Downstream API Consumer Alignment:**
  - `AiChatRequest.locale` (`POST /api/v1/ai/chat`, `POST /api/v1/ai/chat/stream`) reads current resolved locale (`'en'` or `'ar'`).
  - `StripeBillingController` (`POST /api/v1/billing/checkout`, `/portal`, `/upgrade`) passes resolved `locale` (`'en'` or `'ar'`).

---

## 8. State Management and Caching

- **`localeProvider` (`NotifierProvider<LocaleNotifier, LocaleSetting>`):**
  - Reads `afab_locale` from `SharedPreferences` synchronously at app bootstrap (`main.dart`) so initial frame renders in the user's chosen language and direction with zero flash.
  - Exposes `resolvedLocale` (`Locale('en')` or `Locale('ar')`) bound directly to `MaterialApp.router(locale: ...)`.
  - Switching language updates `SharedPreferences` and triggers an immediate `MaterialApp` rebuild across the entire widget tree—no navigation reset or app restart required.

---

## 9. User Actions, Validation, and Error Handling

- **Select Language:** Tapping a language card updates `localeProvider` immediately and shows a brief localized confirmation toast (`"Language updated to Arabic"` / `"تم تغيير اللغة إلى الإنجليزية"`).
- **Unsupported OS Locale Fallback:** When `'system'` is chosen and OS locale is neither `en` nor `ar` (e.g., `fr`), `MaterialApp.localeResolutionCallback` resolves cleanly to `Locale('en')` and displays `"System Default (English fallback)"`.
- **Storage Write Failure:** Falls back to updating in-memory state and logs non-fatal warning via `AppLogger`.

---

## 10. Permissions, Security, and Tenant Isolation

- **Device-Local Preference:** No sensitive data, no permissions required, persists across workspace switches (`X-Business-Id` changes do not reset user's UI language).

---

## 11. Localization (EN/AR) and RTL Behavior

- **Immediate RTL Flip:** Selecting `العربية` flips `Directionality` to `TextDirection.rtl` across `NavigationBar` / `NavigationRail`, `SettingsHomeScreen` master-detail panes, back arrows, chevrons, and margins (`EdgeInsetsDirectional`).
- **Western Digits (`0-9`) Enforced:** Even when `Locale('ar')` is active, numbers and monetary figures remain Western Arabic digits (`0-9`) wrapped in `Directionality(textDirection: TextDirection.ltr)` (`08_LOCALIZATION_AND_RTL.md` §3.2).
- **Gregorian Calendar Enforced:** Never switches to Hijri calendar on `Locale('ar')`.
- **Native Self-Labels:** The `"English"` card always displays `"English"` and the `"العربية"` card always displays `"العربية"` regardless of which language is currently active, so a user who accidentally switched languages can always recognize and switch back!

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Responsive:** Max content width `640dp` centered on tablets; single-column cards on phones (`16dp` padding).
- **Accessibility:** Each option card declares `Semantics(selected: isSelected, button: true)` and announces both native name and layout direction.
- **No Network Dependency:** Never enters a loading or network-error state because locale data (`app_en.arb` / `app_ar.arb`) is compiled into the app binary.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Resolves Web Coming Soon Gap:** Navigating to `/settings/language` renders the live EN/AR switcher instead of a Coming Soon card.
2. **Instant RTL Switch:** Selecting `العربية` flips app `Directionality` to `TextDirection.rtl` and updates all labels immediately without losing navigation stack.
3. **Persistence Across Cold Start:** Killing and relaunching the app restores `afab_locale` from `SharedPreferences` before first frame.
4. **Native Labels Always Recognizable:** Even when UI is in Arabic, the English card remains readable as `"English"` (and vice versa).
5. **Western Digits & Gregorian Check:** Preview card displays `0-9` digits and Gregorian month names in both `en` and `ar`.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Packages** | `flutter_localizations` (SDK), `intl: ^0.20.2`, `shared_preferences: ^2.5.4` | Verified in `06_FLUTTER_ARCHITECTURE.md`. |
| **Font & ARB Parity** | All `1,376` non-home ARB keys + extracted hardcoded strings must exist in both `app_en.arb` and `app_ar.arb`. | Enforce `flutter gen-l10n` zero-untranslated-message check in CI (`P0-05`). |
| **Risk: `MaterialApp` Rebuild State Loss** | Rebuilding `MaterialApp.router` on locale change must not recreate `GoRouter`. | Keep `GoRouter` instance cached inside a `Provider` (`routerProvider`) outside `build()` so locale changes preserve current route & navigation stack. |
