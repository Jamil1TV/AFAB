# SET-02 — General Settings Screen (`GeneralSettingsScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-02` |
| **Screen Name** | General Settings (`GeneralSettingsScreen` + `EditProfileSheet`) |
| **Route Path** | `/settings/general` |
| **Feature Module** | `lib/features/settings/presentation/general_settings_screen.dart` & `edit_profile_sheet.dart` |
| **Web Equivalent** | `settings/general/page.tsx` + `GeneralSettings.tsx` + `EditProfileModal.tsx` |
| **Priority** | P1 (Core Account & Workspace Preferences) |

---

## 2. Purpose and User Goal

Allow users to view and edit core business configuration (name, billing email, base currency migration, timezone, fiscal year start month with Q1–Q4 accounting cycle preview), regional date/number display formats, personal profile details (name, phone, avatar photo or DiceBear preset), 4 AI/density user toggles, GDPR-style JSON data export, and account deletion entry.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `GeneralSettings.tsx` (Business & Regional Cards) | Edits `name`, `businessEmail`, `currency` (opens `CurrencyMigrationModal`), `timezone`, `fiscalYearStartMonth` (with Q1–Q4 card), `dateFormat`, `numberFormat`. Tracks `isDirty` for Cancel/Save. | **Implemented and Connected (Bug-Fixed):** Mirrors all fields and Q1–Q4 cycle preview; fixes Web's missing `OWNER`/`ADMIN` role check (`userRole`) alongside `editable == false` guard, and extracts hardcoded `isArabic` ternaries (`"Live FX Engine"`, `"Unsaved changes"`, quarter strings) into ARB l10n keys. |
| `EditProfileModal.tsx` | Modal editing `firstName`, `lastName`, `phoneNumber`, `avatarUrl` (256x256 JPEG compressed data URI <= 5MB or 5 DiceBear presets), read-only `email` + `emailVerified` badge. | **Implemented and Connected:** Presented as `EditProfileSheet` (full-screen / bottom sheet) using `image_picker` + `flutter_image_compress` (<= 500KB limit matching backend `@Size(max=500000)`) and DiceBear presets. |
| `GeneralSettings.tsx` (Preferences Card) | 4 switches (`enableAiInsights`, `compactMode`, `autoCategorizeTransactions`, `showTips`) persisted via `PUT /user/me`. | **Implemented and Connected:** Keeps `compactMode` synchronized bidirectionally with `AppearanceSettings.density` (`compact` <-> `comfortable`). |
| `GeneralSettings.tsx` (Other Settings Card) | `Export My Data` (`GET /user/me/export` JSON download) + `Delete Account` (`DeleteAccountModal`). | **Implemented and Connected:** Saves `afab-account-export-YYYY-MM-DD.json` to temp/app file and opens native OS share/save sheet (`share_plus`), plus launches `AccountDeletionFlow` (`SET-10`). |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - From `SettingsHomeScreen` (`SET-01`) → tap **General**.
  - Tablet `/settings` default right-hand detail pane.
  - Deep link `/dashboard/settings/general`.
- **Child Sheets / Flows:**
  - `CurrencyMigrationSheet` (`INT-02`, triggered automatically when user selects a different base currency).
  - `EditProfileSheet` (modal bottom sheet / full-screen form).
  - `AccountDeletionFlow` (`SET-10`, pushed full-screen modal flow).

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone Layout (`< 600dp`, Single-Column Scrollable)
1. **Top AppBar:** Title `"General Settings"` + unsaved-changes warning pill (`isDirty`) when edits exist.
2. **Read-Only / Role Notice Banner (Conditional):** Displayed if `business.editable == false` or `business.userRole == 'MEMBER'`.
3. **Section 1 — Account Profile Summary Card (`AfabCard`):**
   - Centered/row avatar (`64dp`), full name, email (`LTR`), optional phone (`LTR`), and `"Edit Profile"` secondary button (`EditProfileSheet`).
4. **Section 2 — Business Settings Card (`AfabCard`):**
   - `Business Name` text field
   - `Business Email` text field (`LTR`, email keyboard)
   - `Currency` picker field with `"Live FX Engine"` badge → selecting a new currency launches `CurrencyMigrationSheet`
   - `Timezone` searchable picker sheet (`TIMEZONES`)
   - `Fiscal Year Start` month selector (`MONTHS` 1–12) + `AfabInsetPanel` displaying `"Active Accounting Cycle"` span and 2x2 grid of Q1–Q4 date ranges.
5. **Section 3 — Regional Formats Card (`AfabCard`):**
   - `Date Format` picker (`7` `DATE_FORMATS`) with live monospace preview (`datePreview`).
   - `Number Format` picker (`5` `NUMBER_FORMATS`: `US`, `EU`, `SI`, `DOT`, `RAW`) with live `MoneyFormatter` preview (`1,234,567.89` in selected currency).
6. **Section 4 — Preferences Card (`AfabCard`):**
   - 4 `SwitchListTile` toggles:
     - `Enable AI Insights` (`enableAiInsights`)
     - `Compact Mode` (`compactMode`)
     - `Auto-categorize Transactions` (`autoCategorizeTransactions`)
     - `Show Tips & Tutorials` (`showTips`)
7. **Section 5 — Other Settings / Account Actions (`AfabCard`):**
   - `Export My Data` row (`Download` icon, subtitle, loading spinner, inline summary banner on completion + Share button).
   - `Delete Account` danger row (`Trash2` icon, red tint) → opens `AccountDeletionFlow` (`SET-10`).
8. **Sticky Bottom Save Bar (Visible/Active when `isDirty`):**
   - `Cancel` (`RotateCcw` icon, resets form & user prefs to baseline) + `Save Changes` (`Check` icon, disabled unless `isDirty && !isLoading`). Note: If user is `MEMBER` or workspace is `READ_ONLY`, business fields are disabled while user preferences remain saveable via `PUT /user/me`!

### Tablet Layout (`>= 600dp`)
- Inside the Settings detail pane: 2-column grid for Business & Regional fields, followed by a 2-col or 3-col bottom grid for **Account Card**, **Preferences Card**, and **Other Settings Card** (mirroring `GeneralSettings.tsx:578`).

---

## 6. UI Components and Interactive Elements

| Component | Details |
|---|---|
| `EditProfileSheet` | Bottom sheet / full-screen modal with `Avatar` preview, `"Upload Photo"` (`image_picker` gallery/camera → compressed 256x256 JPEG), `"Remove"` button, 5 horizontal DiceBear preset circles (`avataaars`, `notionists`, `lorelei`, `thumbs`, `initials`), `First Name`, `Last Name`, `Phone Number` (`LTR`), read-only `Email` + `Verified` badge, `Cancel` & `Save Profile`. |
| `CurrencyPickerField` | Tapping opens searchable currency sheet (`CURRENCIES` + `TND`, `JOD`, `LYD`, `IQD` ISO list). Selecting a currency != current opens `CurrencyMigrationSheet` rather than mutating locally without conversion preview. |
| `FiscalCycleCard` | `AfabInsetPanel` dynamically computing Q1–Q4 month ranges and end-of-year day (`28`/`30`/`31`) whenever `fiscalYearStartMonth` changes. |
| `FormatPreviewPill` | Live monospace (`tabularFigures`) preview next to Date Format and Number Format labels. |

---

## 7. Data Requirements and API Contracts

### Endpoints
1. **`PUT /api/v1/business/{id}`** (Requires `OWNER`/`ADMIN` + `EDITABLE`):
   - Request (`UpdateBusinessRequest` partial fields):
     `{ name, businessEmail, currency, timezone, fiscalYearStartMonth (Integer 1..12), dateFormat, numberFormat }`
   - Response: `200 BusinessDTO`.
2. **`PUT /api/v1/user/me`** (Authenticated):
   - Request (`UpdateUserRequest` partial fields):
     - From General Preferences Save: `{ enableAiInsights, compactMode, autoCategorizeTransactions, showTips }`
     - From `EditProfileSheet`: `{ firstName, lastName, phoneNumber, avatarUrl }`
   - Validation constraints (`UpdateUserRequest.java`):
     - `firstName`: `@Size(min = 1, max = 255)` (non-blank)
     - `lastName`: `@Size(min = 1, max = 255)` (non-blank)
     - `phoneNumber`: `@Size(max = 50)` (unique across users, else `400 PHONE_TAKEN`)
     - `avatarUrl`: `@Size(max = 500000)` (`"Avatar image is too large"`)
   - Response: `200 UserProfileDTO`.
3. **`GET /api/v1/user/me/export`** (Authenticated):
   - Response: `200 application/json` (`Content-Disposition: attachment; filename="afab-account-export-YYYY-MM-DD.json"`), containing `{ schemaVersion: "1.1", exportedAt, summary: { businessesCount, categoriesCount, transactionsCount, activeSessionsCount }, account, subscription, businesses, activeSessions }`.
4. **Currency Migration (delegated to `CurrencyMigrationSheet`):**
   - `GET /api/v1/currencies/business/preview?newCurrency=...`
   - `POST /api/v1/currencies/business/change` (`{ newCurrency, convertExistingTransactions: false }`).

---

## 8. State Management and Caching

- **`generalSettingsControllerProvider` (`AutoDisposeAsyncNotifier`):**
  - Holds `baselineBusiness`, `draftBusiness`, `baselinePrefs`, `draftPrefs`, `isDirty`, `isSaving`, `isExporting`, `exportResult`.
- **Cache Synchronization on Save:**
  - `PUT /business/{id}` updates `activeBusinessProvider`, writes `afab_number_format` and `afab_date_format` to `SharedPreferences`, and triggers `MoneyFormatter` / `DateFormatter` rebuilds across the app.
  - `PUT /user/me` updates `userProfileProvider` and syncs `compactMode` into `appearanceProvider` (`DensityId.compact` vs `DensityId.comfortable`).
  - `CurrencyMigrationSheet` success updates `baselineBusiness.currency` and invalidates dashboard/transaction/report providers.

---

## 9. User Actions, Validation, and Error Handling

- **Client Validation:**
  - `EditProfileSheet`: `firstName.trim()` and `lastName.trim()` required (`1..255` chars); image size `<= 5 MB` pre-compression and base64 length `<= 500,000` chars post-compression (re-compress at lower JPEG quality `0.70` if needed).
  - `BusinessSettings`: `name` `<= 255` chars; `businessEmail` `<= 255` chars & valid email syntax if non-empty.
- **Backend Error Handling:**
  - `400 INVALID_FIRST_NAME` / `INVALID_LAST_NAME` / `PHONE_TAKEN` → inline field error inside `EditProfileSheet`.
  - `403 BUSINESS_READ_ONLY` → triggers `BusinessReadOnlySheet` and reverts business draft edits while still allowing user-level preference saves.
  - `403 Forbidden` (non-admin `MEMBER`) → prevented proactively by disabling business fields; if triggered, shows localized permission error toast.
- **Dirty Back Navigation:** Leaving `/settings/general` while `isDirty == true` shows a `"Discard unsaved changes?"` dialog.

---

## 10. Permissions, Security, and Tenant Isolation

- **Role Guard (Fixing Web Gap):** Web `GeneralSettings.tsx` only disables Save when `business?.editable === false`, letting `MEMBER` users attempt `PUT /business/{id}` and hit a `403` error. Mobile checks `canEditBusiness = (business.userRole == 'OWNER' || business.userRole == 'ADMIN') && business.editable`.
- **Two-Layer Save Separation:** If `!canEditBusiness`, business & regional inputs are read-only, while the 4 User Preferences (`PUT /user/me`) and Profile Edit (`PUT /user/me`) remain fully functional and save independently!
- **Data Privacy:** `GET /user/me/export` excludes password hashes, 2FA secrets, backup codes, and token hashes (`UserAccountService.java:110`); mobile writes the exported JSON to a temporary cache file for immediate `share_plus` export and cleans up temp files securely.

---

## 11. Localization (EN/AR) and RTL Behavior

- Localizes all strings from `settings.general.*`, `settings.account.*`, `settings.preferences.*`, `settings.otherSettings.*`, plus Web's hardcoded `isArabic` strings (`"Live FX Engine"`, `"Active Accounting Cycle"`, `"Unsaved changes"`, Q1–Q4 names, `"Edit Profile"` modal copy, `"Data exported"` banner).
- **LTR Isolation:** Email inputs, phone numbers, DiceBear URLs, and numeric/currency previews (`1,234,567.89`) use `TextDirection.ltr` inside RTL Arabic layouts.
- **Dates:** Gregorian months (`January`–`December` / `يناير`–`ديسمبر`) used in fiscal year quarters and date previews; Western digits (`0-9`) enforced.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Keyboard & Viewport:** `EditProfileSheet` uses `isScrollControlled: true` + `viewInsetsOf(context).bottom` padding so the `Save Profile` CTA stays above the software keyboard on `320dp` phones.
- **Touch Targets:** All switches, dropdown triggers, DiceBear avatar circles (`44–48dp` hit area), and action buttons meet `>= 48dp` height.
- **Loading & Error States:** Shimmer placeholders while profile/business load; inline spinner inside `Save Changes` and `Export My Data`; retryable error banner on failure.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Dirty State & Cancel:** Changing timezone enables `Unsaved changes` badge + `Cancel`/`Save`; tapping `Cancel` restores baseline values cleanly.
2. **Currency Migration Guard:** Selecting `EUR` when currency is `USD` opens `CurrencyMigrationSheet` without mutating `formData.currency` until confirmed.
3. **Edit Profile & Avatar Compression:** Picking a photo compresses to 256x256 JPEG (`< 500,000` chars), sends `PUT /user/me`, and handles `400 PHONE_TAKEN` inline.
4. **Role Guard (`MEMBER` vs `OWNER`):** A `MEMBER` user sees business fields disabled with a clear notice, yet can still toggle and save `enableAiInsights` / `compactMode` via `PUT /user/me`.
5. **JSON Data Export:** Tapping `Export My Data` calls `GET /user/me/export`, parses summary counts, writes `.json`, and invokes `share_plus`.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Packages** | `image_picker`, `flutter_image_compress`, `share_plus`, `path_provider`, `cached_network_image` | Verified in `06_FLUTTER_ARCHITECTURE.md`. |
| **Shared Local Storage** | `afab_number_format` and `afab_date_format` in `SharedPreferences` must sync with `MoneyFormatter`. | Update `formatPreferencesProvider` atomically on save and on business switch. |
| **Risk: Dual-Request Partial Failure** | `handleSave` on Web calls `PUT /business/{id}` then `PUT /user/me` sequentially (`GeneralSettings.tsx:195-210`). | Handle partial failure gracefully: update baseline only for whichever request succeeded so dirty state accurately reflects remaining unsaved changes. |
