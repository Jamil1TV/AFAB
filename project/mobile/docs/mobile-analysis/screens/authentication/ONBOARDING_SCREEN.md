# ONBOARDING_SCREEN (`AUTH-08`)

## 1. Screen Identity
- **Screen ID:** `AUTH-08`
- **Screen Name:** 3-Step Business Onboarding Wizard
- **Flutter Route Name & Path:** `AppRoutes.onboarding` — `/onboarding`
- **Feature Module:** `lib/features/auth/presentation/onboarding_screen.dart`
- **Web Equivalent(s):**
  - `Web/project/frontend/app/[locale]/(auth)/onboarding/page.tsx` (`OnboardingPage`)
  - `Web/project/frontend/lib/constants/business-data.ts` (`COUNTRIES`, `INDUSTRIES`, `BUSINESS_TYPES`, `CURRENCIES`, `TIMEZONES`, `MONTHS`, localization helpers)
- **Priority:** P0 (Mandatory Post-Verification Workspace Setup)
- **Status Parity:** Implemented and Connected on Web (`PUT /api/v1/business/{id}`). Mobile preserves full parity **and fixes Web's missing `TND` (Tunisian Dinar) currency** in onboarding pickers (aligning with `ExchangeRateService.POPULAR_CURRENCIES`, `currencies/page.tsx`, and `08_LOCALIZATION_AND_RTL.md`).

---

## 2. Purpose
`OnboardingScreen` configures the newly registered user's primary business workspace before entering the Dashboard. Because `AuthService.register()` sets `currency = "USD"` and leaves `country` and `timezone` `null`, backend `Business.isOnboardingComplete()` (`Business.java:229-232`) evaluates `country != null && !country.isBlank() && timezone != null && !timezone.isBlank()`. Submitting Step 3 persists `country`, `industry`, `businessType`, `currency`, `timezone`, and `fiscalYearStartMonth` via `PUT /api/v1/business/{id}` and unlocks `/dashboard`.

---

## 3. Original Web Structure
In `Web/project/frontend/app/[locale]/(auth)/onboarding/page.tsx`:
- **Card Container:** `afab-card w-full max-w-[540px] p-5 sm:p-8`
- **Step Header:**
  - Top row: `onboardingStep` (`"Step {step} of 3"`) on start + `onboardingStep{1|2|3}Tab` on end (`"Business Info"`, `"Financial Setup"`, `"Review & Complete"`).
  - Progress bar: `6px` height track, animated fill (`33%` → `66%` → `100%`).
- **Error Alert:** `AlertCircle` icon + red banner.
- **3-Step Wizard Body (`AnimatePresence mode="wait"`):**
  - **Step 1 — Business Info:**
    - `Building2` icon + `onboardingStep1Title` + `onboardingStep1Subtitle`
    - `countryLabel` (`Globe2`): native `<select>` of 16 `COUNTRIES` (default `"United Arab Emirates"`, stored as `c.nameEn`)
    - `industryLabel` (`Briefcase`): `<select>` of 11 `INDUSTRIES` (default `"Technology & Software"`, stored as `ind.nameEn`)
    - `businessTypeLabel` (`Building2`): `<select>` of 6 `BUSINESS_TYPES` (default `"Limited Liability Company (LLC)"`, stored as `bt.nameEn`)
  - **Step 2 — Financial Setup:**
    - `Coins` icon + `onboardingStep2Title` + `onboardingStep2Subtitle`
    - `currencyLabel` (`Coins`): `<select>` of `CURRENCIES` (default `"USD"`, stored as `curr.code`)
    - `timezoneLabel` (`Clock`): `<select>` of 12 `TIMEZONES` (default `"Asia/Dubai"`, stored as `tz.value`)
    - `fiscalYearLabel` (`Calendar`): `<select>` of 12 `MONTHS` (`1..12`, default `1` = January)
  - **Step 3 — Review & Complete:**
    - `56x56px` `primary` circle with `Sparkles` icon, `onboardingStep3Title`, `onboardingStep3Subtitle`
    - `afab-inset` summary card with 6 key-value rows (`summaryCountry`, `summaryIndustry`, `summaryBusinessType`, `summaryCurrency`, `summaryTimezone`, `summaryFiscalYear`) using `getLocalized*` helpers.
- **Footer Controls:**
  - `Back` button (`step > 1`) with directional `ArrowLeft`
  - `Continue` button (`step < 3`) with directional `ArrowRight`
  - `Launch Dashboard` button (`step == 3`) with `CheckCircle2` or `AfabLoader(size="xs")`.

---

## 4. Complete Functional Inventory

| # | Step / Control | Behavior, Validation & Data Mapping |
|---|---|---|
| 1 | **Step Progress Header** | Displays localized `"Step X of 3"`, current step tab label, and animated progress bar (`1/3`, `2/3`, `3/3`). Tapping completed step indicator pills (optional) or `"Back"` allows navigating back without losing form selections. |
| 2 | **Step 1 — Country of Operation Picker** | Searchable `AfabBottomSheet` picker (replacing cramped mobile dropdowns) listing all 16 Web `COUNTRIES` (`US`, `AE`, `SA`, `QA`, `KW`, `BH`, `OM`, `EG`, `DZ`, `MA`, `JO`, `LB`, `GB`, `CA`, `DE`, `FR`) **plus recommended Tunisia (`TN` — `"Tunisia"` / `"تونس"`)** alongside `TND`. Stores **`nameEn`** (e.g., `"United Arab Emirates"`) to match Web & `getLocalizedCountry()` compatibility, while displaying `nameAr` in Arabic! |
| 3 | **Step 1 — Industry Picker** | Searchable bottom sheet listing all 11 `INDUSTRIES` (`Technology & Software`, `E-commerce & Retail`, `Professional Services & Consulting`, `Financial Services & Fintech`, `Healthcare & Life Sciences`, `Real Estate & Construction`, `Media & Entertainment`, `Food & Beverage`, `Manufacturing & Logistics`, `Education & Non-profit`, `Other`). Stores `nameEn`. |
| 4 | **Step 1 — Entity Type Picker** | Bottom sheet listing all 6 `BUSINESS_TYPES` (`Sole Proprietorship`, `Limited Liability Company (LLC)`, `Corporation`, `Partnership`, `Freelancer / Individual`, `Non-Profit`). Stores `nameEn`. |
| 5 | **Step 1 Validation** | `country` non-empty required (displays localized `"Please select a country"` / `"يرجى اختيار الدولة"` if cleared). |
| 6 | **Step 2 — Main Currency Picker (Includes `TND`)** | Searchable bottom sheet listing all 15 Web `CURRENCIES` (`USD`, `EUR`, `AED`, `SAR`, `QAR`, `KWD`, `BHD`, `OMR`, `EGP`, `DZD`, `MAD`, `GBP`, `CAD`, `AUD`, `JPY`) **PLUS `TND` (`{ code: "TND", symbol: "DT", nameEn: "Tunisian Dinar", nameAr: "دينار تونسي" }`)** (and optionally `CHF` / `TRY` matching `currencies/page.tsx` & `ExchangeRateService.POPULAR_CURRENCIES`). Displays `"{CODE} ({SYMBOL}) — {Localized Name}"` and notes 3-decimal precision for `TND`/`KWD`/`BHD`/`OMR`. Stores 3-letter ISO code (`@Size(min: 3, max: 3)`). |
| 7 | **Step 2 — Timezone Picker** | Searchable bottom sheet listing all 12 Web `TIMEZONES` (`Asia/Dubai`, `Asia/Riyadh`, `Asia/Qatar`, `Africa/Cairo`, `Africa/Algiers`, `UTC`, `Europe/London`, `Europe/Paris`, `America/New_York`, `America/Los_Angeles`, `Asia/Tokyo`, `Australia/Sydney`) **plus `Africa/Tunis` (`"Africa/Tunis (GMT+1 - Tunis Time)"` / `"إفريقيا/تونس (GMT+1 - توقيت تونس)"`)** (`@Size(max: 50)`). Stores IANA `value`. |
| 8 | **Step 2 — Fiscal Year Starts In Picker** | Bottom sheet listing `MONTHS` (`1..12`, `"January"`..`"December"` / `"يناير"`..`"ديسمبر"`). Stores integer `1..12`. |
| 9 | **Smart Country → Currency / Timezone Suggestion (UX Polish)** | Selecting a country on Step 1 **only if user hasn't manually changed Step 2 yet** can optionally suggest matching currency & timezone (e.g., `Tunisia` → `TND`, `Africa/Tunis`; `Saudi Arabia` → `SAR`, `Asia/Riyadh`), while keeping Web's defaults (`United Arab Emirates`, `USD`, `Asia/Dubai`, `1`) or user manual overrides respected. |
| 10 | **Step 3 — Summary Review** | Displays all 6 localized values inside `AfabInsetPanel`. Shows `currency` with localized currency name/code cleanly. |
| 11 | **Launch Dashboard (`PUT /api/v1/business/{id}`)** | Resolves `businessId` from `sessionProvider` (`user.businessId`); if null, fetches `GET /api/v1/business` fallback before failing. Sends `UpdateBusinessRequest { country, currency, timezone, fiscalYearStartMonth, industry, businessType }`. On `200 BusinessDTO` (where `onboardingComplete == true`), updates `sessionProvider`, invalidates `businessMineProvider` & `dashboardProvider`, and navigates via `context.go('/dashboard')`. |
| 12 | **Sign Out Escape Hatch** | Subtle header/footer `"Sign out"` icon/link in case user wants to switch accounts mid-onboarding. |

---

## 5. Data Requirements

### 5.1 Request DTO (`UpdateBusinessRequest.java`)
```dart
@freezed
class OnboardingBusinessPayload with _$OnboardingBusinessPayload {
  const factory OnboardingBusinessPayload({
    required String country,              // @Size(max: 100) — e.g. "United Arab Emirates"
    required String currency,             // @Size(min: 3, max: 3) — e.g. "TND", "USD"
    required String timezone,             // @Size(max: 50) — e.g. "Africa/Tunis", "Asia/Dubai"
    required int fiscalYearStartMonth,    // 1..12
    required String industry,             // e.g. "Technology & Software"
    required String businessType,         // e.g. "Limited Liability Company (LLC)"
  }) = _OnboardingBusinessPayload;
}
```

### 5.2 Response DTO (`BusinessDTO.java`)
Key fields checked after update: `id`, `name`, `country`, `currency`, `timezone`, `fiscalYearStartMonth`, `industry`, `businessType`, `onboardingComplete` (`true` when `country` and `timezone` are non-blank).

### 5.3 Centralized Constants (`lib/core/config/business_constants.dart`)
Mirrors `Web/project/frontend/lib/constants/business-data.ts` **plus `TND` / `TN` / `Africa/Tunis`**, with `getLocalizedCountry`, `getLocalizedIndustry` (including legacy aliases like `"Software"` → `"technology"`), `getLocalizedBusinessType`, `getLocalizedCurrencyOption`, `getLocalizedTimezone`, `getLocalizedMonth`.

---

## 6. API Integration

| Endpoint | Method | Auth / Headers | Request Body | Responses & Errors |
|---|---|---|---|---|
| `/api/v1/business/{id}` | `PUT` | `Authorization: Bearer <accessToken>`<br>`X-Business-Id: <id>` | `{ country, currency, timezone, fiscalYearStartMonth, industry, businessType }` | - `200 OK`: `BusinessDTO` (`onboardingComplete: true`)<br>- `400`: `ApiError` (`fieldErrors` if currency != 3 chars, etc.)<br>- `403`: not `OWNER`/`ADMIN` or `BUSINESS_READ_ONLY`<br>- `401`: triggers single-flight refresh or `/login` |

---

## 7. Modal, Drawer and Dialog Inventory
- **Searchable Selection Bottom Sheets (`AfabBottomSheet`, 6 total pickers):**
  1. `CountryPickerSheet` (with search bar & optional flag/code badge)
  2. `IndustryPickerSheet` (with search bar)
  3. `BusinessTypePickerSheet` (6 items, no search needed)
  4. `CurrencyPickerSheet` (with search bar by code/EN/AR name, showing `CODE (SYMBOL) — Name` + `3 decimals` badge on `TND`/`KWD`/`BHD`/`OMR`)
  5. `TimezonePickerSheet` (with search bar by city/GMT offset)
  6. `FiscalMonthPickerSheet` (12 Gregorian months localized in EN/AR)

---

## 8. Mobile Adaptation
- **Full-Width Bottom-Sheet Pickers vs HTML `<select>`:** Replaces native HTML `<select>` dropdowns with `AfabSelectField` rows (`52dp` min height, leading icon, selected localized value, trailing chevron) that open smooth `AfabBottomSheet` pickers with search filtering (`Currency`, `Country`, `Timezone`, `Industry`).
- **Sticky Bottom Action Bar:** On small phones (`< 360dp`) or high font scales (`1.3x+`), `Back` and `Continue` / `Launch Dashboard` stay pinned cleanly at the bottom inside `SafeArea` so users never lose the primary CTA below scroll fold.
- **System Back Behavior:** Pressing Android hardware back on Step 2 or Step 3 navigates to the previous step (`step - 1`) instead of abruptly exiting the app; on Step 1, prompts sign-out or minimizes app.
- **Tablet (`>= 600dp`):** Centered `AfabCard(maxWidth: 540dp)` with `AfabBottomSheet` or centered picker dialogs (`maxWidth: 480dp`).

---

## 9. Visual Design
- **Step Header:** Uppercase `11–12sp` `primary` label (`"STEP 1 OF 3"`) + muted/primary step name; `6dp` rounded progress bar (`surfaceInset` track, `primary` `#8B5CF6` fill).
- **Step Icons:**
  - Step 1: `LucideIcons.building2` (header), `LucideIcons.globe2` (country), `LucideIcons.briefcase` (industry), `LucideIcons.building2` (type)
  - Step 2: `LucideIcons.coins` (header & currency), `LucideIcons.clock` (timezone), `LucideIcons.calendar` (fiscal year)
  - Step 3: `56x56dp` filled `primary` circle with white `LucideIcons.sparkles` + `boxShadow` glow (when `enableGlow` is on).
- **Summary Review Panel (Step 3):** `AfabInsetPanel` (`surfaceInset` `#F9FAFB` / `#080C18`, `1px border`, `12dp` radius) containing 6 rows separated by `1px` `border.withValues(alpha: 0.6)` dividers; labels left (`textMuted`), values right (`textPrimary`, SemiBold).

---

## 10. Localization
Keys from `Web/project/frontend/messages/{en,ar}/auth.json`:
- `onboardingStep`: `"Step {step} of 3"` / `"الخطوة {step} من 3"` (ICU `{step}` int param)
- `onboardingStep1Tab`, `onboardingStep2Tab`, `onboardingStep3Tab`
- `onboardingStep1Title`, `onboardingStep1Subtitle`, `onboardingStep2Title`, `onboardingStep2Subtitle`, `onboardingStep3Title`, `onboardingStep3Subtitle`
- `countryLabel`, `industryLabel`, `businessTypeLabel`, `currencyLabel`, `timezoneLabel`, `fiscalYearLabel`
- `summaryCountry`, `summaryIndustry`, `summaryBusinessType`, `summaryCurrency`, `summaryTimezone`, `summaryFiscalYear`
- `back`, `next`, `launchDashboard`
- **New Mobile Keys (Localizing Web Hardcoded Inline `isArabic` Errors in `onboarding/page.tsx:60-115`):**
  - `onboardingCountryRequired`: `"Please select a country"` / `"يرجى اختيار الدولة"`
  - `onboardingFinancialRequired`: `"Please configure currency and timezone"` / `"يرجى تحديد العملة والمنطقة الزمنية"`
  - `onboardingNoBusinessFound`: `"No business profile found. Please log in again."` / `"لم يتم العثور على ملف الشركة. يرجى تسجيل الدخول مرة أخرى."`
  - `onboardingSaveFailed`: `"Failed to save business settings. Please try again."` / `"فشل حفظ إعدادات الشركة. يرجى المحاولة مرة أخرى."`
  - `onboardingPickerSearchPlaceholder`: `"Search..."` / `"بحث..."`
- **RTL & Digits:** Step transitions mirror (`step + 1` slides from start→end in LTR, end→start in RTL); currency codes (`TND`, `USD`) and GMT offsets (`GMT+1`) stay crisp inside BiDi summaries.

---

## 11. Animation and Interaction Design
- **Progress Bar:** `AnimatedFractionallySizedBox` (`300 ms`, `Curves.easeOutCubic`) transitioning `0.33 → 0.66 → 1.0`.
- **Step Content Transitions:** `AnimatedSwitcher` with directional horizontal slide (`±40dp`, flipped in RTL) + fade (`280 ms`).
- **Picker Sheets:** Standard Material 3 bottom sheet spring curve + `HapticFeedback.selectionClick()` when selecting an option.
- **Launch Success:** Brief `AfabLoader` (`xs`) → `HapticFeedback.mediumImpact()` → smooth cross-fade into `/dashboard`.

---

## 12. Accessibility
- Progress bar exposes `Semantics(label: context.l10n.onboardingStep(step), value: "${(step / 3 * 100).round()}%")`.
- Each `AfabSelectField` announces `"{label}, current value: {displayValue}, double tap to change"`.
- Step 3 summary rows pair label and value cleanly in one `MergeSemantics` container per row.
- Minimum `48dp` height on all picker rows, sheet list items, `Back`, `Continue`, and `Launch Dashboard` buttons.

---

## 13. Acceptance Criteria
1. Unonboarded verified users (`emailVerified == true && onboardingComplete == false`) are routed to `/onboarding` after login/splash/email verification and cannot bypass to `/dashboard`.
2. All 16 countries (plus `Tunisia`), 11 industries, 6 entity types, 15+ currencies **including `TND` (`Tunisian Dinar` / `دينار تونسي`)**, 12+ timezones (including `Africa/Tunis`), and 12 Gregorian months render accurately in both English and Arabic.
3. Navigating Back from Step 2 or Step 3 preserves all previously selected values.
4. Step 3 summary reflects exact localized labels for all 6 fields.
5. Tapping `"Launch Dashboard"` sends `PUT /api/v1/business/{id}`, receives `200 BusinessDTO` with `onboardingComplete == true`, updates session state, and navigates to `/dashboard`.
6. Selecting `TND` persists `"TND"` on the business and immediately configures `MoneyFormatter` across the app for 3-decimal precision (`DT 1,250.000`).

---

## 14. Dependencies and Risks
- **Dependencies:** `dio`, `flutter_riverpod`, `go_router`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  - **Risk:** Web's `business-data.ts` omits `TND` (and `TN` / `Africa/Tunis`) even though `ExchangeRateService` and `currencies/page.tsx` feature `TND` prominently (`#3` in `POPULAR_CURRENCIES`). **Mitigation:** `business_constants.dart` explicitly includes `TND`, `TN`, and `Africa/Tunis`, while `getLocalizedCountry`/`getLocalizedCurrencyName`/`getLocalizedTimezone` stay backward-compatible with Web.
  - **Risk:** `PUT /api/v1/business/{id}` requires `X-Business-Id` or valid `user.businessId`; if `user.businessId` is null in stale cache, Web immediately errors out. **Mitigation:** Fall back to `GET /api/v1/business` to resolve the user's primary `EDITABLE` business ID if `user.businessId` is missing before showing an error.
