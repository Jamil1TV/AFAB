# SET-03 — Business Profile Screen (`BusinessProfileScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-03` |
| **Screen Name** | Business Profile (`BusinessProfileScreen`) |
| **Route Path** | `/settings/business-profile` |
| **Feature Module** | `lib/features/settings/presentation/business_profile_screen.dart` |
| **Web Equivalent** | `settings/business-profile/page.tsx` + `BusinessProfile.tsx` |
| **Priority** | P1 (Enterprise Identity & Tax Metadata) |

---

## 2. Purpose and User Goal

Enable authorized workspace owners and admins (`OWNER` / `ADMIN`) on `EDITABLE` businesses to manage official company identity details—name, industry, business email, phone, website, Fiscal Matricule / Tax ID (`MF`), full street address, logo URL, and description—which are displayed across invoices, financial exports, and workspace summaries.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `BusinessProfile.tsx` (Form Fields & Summary Card) | Edits `name`, `industry`, `businessEmail`, `phoneNumber`, `website`, `taxId`, `addressLine`, `city`, `state`, `postalCode`, `description`, `logoUrl`; renders right-hand Business Summary card. | **Implemented and Connected (Bug-Fixed):** Maps all `UpdateBusinessRequest` fields cleanly and syncs updates back to `activeBusinessProvider`. |
| `BusinessProfile.tsx:107-139` (Base64 Logo Upload) | **Confirmed Bug:** Uses `FileReader.readAsDataURL()` with no size guard and sends multi-KB/MB base64 strings to `PUT /business/{id}`, which fails backend `@Size(max = 500)` (`UpdateBusinessRequest.java:54`). | **Fixed on Mobile:** **Omits broken binary/base64 file upload.** Accepts HTTPS Logo URL (`<= 500` chars) + one-tap DiceBear initials generator (`https://api.dicebear.com/7.x/initials/svg?seed=...`). Documents MinIO `POST /business/{id}/logo` as a backend enhancement proposal. |
| `BusinessProfile.tsx:275` (Cancel Button) | **Confirmed Bug:** Cancel `<Button>` has no `onClick` handler and no `isDirty` tracking. | **Fixed on Mobile:** Wires `Cancel` button to revert all fields to baseline server state and guards back navigation when `isDirty == true`. |
| `BusinessProfile.tsx:355-398` (Document Uploads Card) | **UI Only / Mock Data:** Hardcodes fake `tax_certificate_2026.pdf` (2.4 MB) and `business_license.pdf` (1.1 MB) rows and a dead Upload button with zero backend API. | **Omitted on Mobile:** Mock Document Uploads card is intentionally removed so users are never shown fake compliance files. |
| `BusinessProfile.tsx` (Role & Read-Only Guards) | Only sets `disabled={isLoading || isReadOnly}` on Save button; leaves all inputs editable and ignores `MEMBER` role. | **Fixed on Mobile:** Enforces both `userRole in {'OWNER', 'ADMIN'}` AND `business.editable == true` across all inputs and Save CTA. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `SettingsHomeScreen` (`SET-01`) → **Business Profile**.
  - Tablet Settings rail → **Business Profile**.
  - Deep link `/dashboard/settings/business-profile`.
- **Exit / Back Behavior:**
  - Pops back to `SettingsHomeScreen` (Phone) or switches Settings tab (Tablet), prompting `"Discard unsaved changes?"` if `isDirty == true`.

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone Layout (`< 600dp`)
1. **Top AppBar:** Title `"Business Profile"` + `Unsaved changes` warning chip when `isDirty`.
2. **Permission / Read-Only Banner (Conditional):**
   - If `editable == false`: Amber `BUSINESS_READ_ONLY` notice with link to `BusinessAllocationSheet` / `Plans`.
   - If `userRole == 'MEMBER'`: Neutral info banner explaining only `OWNER` and `ADMIN` roles can modify business profile.
3. **Business Summary Header Card (Collapsible / Compact `AfabCard`):**
   - Displays current Logo preview (`64x64dp` rounded square), Business Name, localized Industry, Member Since year (`createdAt.year`), Location (`city, country`), and localized Timezone.
4. **Logo URL & Initials Generator Card (`AfabCard`):**
   - `64x64dp` live logo preview (`CachedNetworkImage` with fallback initials).
   - `Logo URL` text field (`LTR`, `maxLength: 500`, live character counter `X/500`).
   - `"Use Monogram Avatar"` button generating `https://api.dicebear.com/7.x/initials/svg?seed=<encodedName>`.
   - Helper note explaining custom image uploads require a hosted HTTPS URL (`<= 500` chars).
5. **Business Information Form Card (`AfabCard`):**
   - `Business Name` (`maxLength: 255`)
   - `Industry` picker (`11` localized `INDUSTRIES` + alias mapping from `business-data.ts`)
   - `Business Email` (`LTR`, `maxLength: 255`)
   - `Phone Number` (`LTR`, `maxLength: 50`)
   - `Website` (`LTR`, `maxLength: 255`)
   - `Fiscal Matricule / Tax ID (MF)` (`LTR`, `maxLength: 100`, helper text noting invoice/export usage)
   - `Business Address` (`addressLine`)
   - `City` (`maxLength: 100`), `State / Region` (`maxLength: 100`), `Postal Code` (`LTR`, `maxLength: 20`)
   - `Country` picker (`COUNTRIES` 16 items, `maxLength: 100`) — exposed cleanly since `UpdateBusinessRequest` supports `country`.
   - `Business Description (Optional)` multiline field (`maxLength: 500`, live `{count}/500` counter).
6. **Sticky Bottom Action Bar (when `canEdit`):**
   - `Cancel` (`isDirty` resets to baseline) + `Save Changes` (active when `isDirty && !isSaving`).

### Tablet Layout (`>= 600dp` / `>= 840dp`)
- Matches Web's `2:1` split (`xl:grid-cols-3`): Left 2/3 form card (`Logo` + 2-col `Business Info` grid + `Cancel`/`Save`), Right 1/3 sticky **Business Summary Card** (without the omitted mock Document Uploads card).

---

## 6. UI Components and Interactive Elements

| Component | Details |
|---|---|
| `BusinessLogoField` | `CachedNetworkImage` preview (`64dp`, `baseRadius` corners), `AfabTextField` (`maxLength: 500`, `TextDirection.ltr`, HTTP/HTTPS URL validator), `"Reset to Initials"` chip, `"Clear"` button. |
| `IndustryPickerSheet` | Bottom sheet displaying the 11 localized `INDUSTRIES` (resolving legacy aliases like `"Software"` → `"Technology & Software"` via `getLocalizedIndustry`). |
| `CountryPickerSheet` | Searchable bottom sheet displaying `COUNTRIES` (`EN`/`AR`). |
| `CharacterCounterLabel` | Trailing `"{count}/500"` counter on `description` and `logoUrl` fields turning amber near limit and red on error. |
| `BusinessSummaryCard` | `AfabCard` showing 5 icon-badged metadata rows (`Name`, `Industry`, `Member Since`, `Location`, `Timezone`). |

---

## 7. Data Requirements and API Contracts

### Endpoints
- **`GET /api/v1/business/mine`** (or `activeBusinessProvider` hydrated from `GET /api/v1/business/{id}`):
  - Response: `200 BusinessDTO` (28 fields).
- **`PUT /api/v1/business/{id}`** (`BusinessController.updateBusiness`):
  - Guards: Active member, `member.isAdminOrOwner()` (`OWNER`/`ADMIN`), `BusinessAccessGuard.assertEditable(business)`.
  - Request (`UpdateBusinessRequest` — all fields optional):
    - `name` (`@Size(max = 255)`)
    - `country` (`@Size(max = 100)`)
    - `industry` (`String`)
    - `businessEmail` (`@Size(max = 255)`)
    - `phoneNumber` (`@Size(max = 50)`)
    - `website` (`@Size(max = 255)`)
    - `taxId` (`@Size(max = 100)`)
    - `addressLine` (`String`)
    - `city` (`@Size(max = 100)`)
    - `state` (`@Size(max = 100)`)
    - `postalCode` (`@Size(max = 20)`)
    - `description` (`@Size(max = 500)`)
    - `logoUrl` (`@Size(max = 500)`)
  - Response: `200 BusinessDTO`.
- **Local Sync (`SharedPreferences`):** On successful save, also cache `afab_business_logo`, `afab_fiscal_matricule`, `afab_business_purpose`, and `afab_business_address` keyed by `businessId` for offline PDF/Excel export headers (`SET-07`).

---

## 8. State Management and Caching

- **`businessProfileFormProvider(businessId)` (`AutoDisposeNotifier`):**
  - Initializes `baseline` and `draft` from `activeBusinessProvider`.
  - Computes `isDirty` across all 13 editable fields.
  - On `save()` success: updates `activeBusinessProvider` and `businessListProvider` with returned `BusinessDTO`, resets `baseline = draft`, and emits success toast (`t("saved")`).
  - On `cancel()`: resets `draft = baseline` and clears field errors.

---

## 9. User Actions, Validation, and Error Handling

- **Client Validation:**
  - Reject `logoUrl` values starting with `data:` (base64) or exceeding `500` characters with an explicit helpful message (`"Logo URL must be a valid HTTPS link up to 500 characters"`).
  - Validate `businessEmail` format if non-empty; validate `website` URL format (`http://` or `https://`) if non-empty; enforce `@Size` max lengths (`255`, `100`, `50`, `20`, `500`).
- **Backend Error Handling:**
  - `400 Bad Request` (`fieldErrors`) → maps field-level validation errors directly onto matching `AfabTextField`s.
  - `403 ForbiddenException` (`"Only business owners and admins..."`) → displays permission banner and disables edit mode.
  - `403 BUSINESS_READ_ONLY` → triggers `BusinessReadOnlySheet`.

---

## 10. Permissions, Security, and Tenant Isolation

- **Role & Editability Matrix:**
  - `OWNER` + `editable == true`: Full read/write access.
  - `ADMIN` + `editable == true`: Full read/write access.
  - `MEMBER` + `editable == true`: Read-only view + permission notice banner; Save CTA hidden/disabled.
  - Any role + `editable == false`: Read-only view + `READ_ONLY` workspace lock banner; Save CTA disabled.
- **Tenant Isolation:** Updates explicitly target `business.id` with `X-Business-Id` attached; local export header caches (`taxId`, `logoUrl`, `address`) MUST be keyed by `businessId` (fixing Web's unkeyed `localStorage` keys that could leak across workspaces!).

---

## 11. Localization (EN/AR) and RTL Behavior

- Localizes all `settings.businessProfile.*` keys (`logo`, `businessInfo`, `taxId`, `taxIdHelp`, `summary*`, `cancel`, `saveChanges`, `saved`).
- **LTR Isolation:** `logoUrl`, `businessEmail`, `phoneNumber`, `website`, `taxId` (`1234567/A/B/M/000`), and `postalCode` force `TextDirection.ltr`.
- Industry, Country, and Timezone display localized AR/EN names via `business-data.ts` lookup tables.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Responsive:** `State/Region` and `Postal Code` sit side-by-side on `>= 360dp`, stacking vertically on `< 360dp` (`compactSmall`). Keyboard insets push scrollable content cleanly above IME.
- **Image Fallback:** If `logoUrl` fails to load (offline, 404, or invalid SVG/network), `CachedNetworkImage` error builder falls back cleanly to a branded monogram square (`business.name` initials).
- **Loading / Error:** Shimmer form skeleton on initial fetch; inline spinner on `Save Changes`; retryable error banner if business fetch fails.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Logo 500-Char Enforcement:** Entering a `data:image/...` string or URL `> 500` chars fails client validation before hitting `PUT /business/{id}`; entering a valid `<= 500` char HTTPS URL succeeds.
2. **Cancel Button Wired:** Modifying `taxId` and tapping `Cancel` restores the original `taxId` and clears `isDirty`.
3. **Mock Documents Omitted:** No hardcoded `tax_certificate_2026.pdf` or `business_license.pdf` appears anywhere in the widget tree.
4. **Guards (`MEMBER` & `READ_ONLY`):** Inputs and Save button are disabled for `MEMBER` users and `READ_ONLY` businesses.
5. **Cross-Tenant Cache Keying:** Switching from Business A to Business B updates `BusinessProfileScreen` fields and local export metadata independently.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Backend Limitation (`logoUrl` `@Size(max=500)`)** | Backend stores `logoUrl` in `VARCHAR(500)` with no MinIO upload endpoint. | Accept URL + DiceBear monogram on mobile; propose `POST /api/v1/business/{id}/logo` (MinIO upload) for future backend sprint. |
| **SVG Rendering for DiceBear URLs** | Default DiceBear URLs return SVG (`https://api.dicebear.com/7.x/initials/svg?...`). | Use `https://api.dicebear.com/7.x/initials/png?...` for native `CachedNetworkImage` compatibility OR include `flutter_svg` when rendering `.svg` logo URLs. |
| **Web Unkeyed `localStorage` Parity** | Web wrote `afab_business_logo` / `afab_fiscal_matricule` globally without `businessId`. | Mobile keys all cached export metadata by `businessId` to prevent cross-business leakage. |
