# SET-06 — Wet Signature Vault Screen (`SignatureSettingsScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-06` |
| **Screen Name** | Wet Signatures & Signatory Vault (`SignatureSettingsScreen`) |
| **Route Path** | `/settings/signature` |
| **Feature Module** | `lib/features/settings/presentation/signature_settings_screen.dart` |
| **Web Equivalent** | `settings/signature/page.tsx` + `SignatureSettings.tsx` + `lib/signature-utils.ts` |
| **Priority** | P2 (Document Branding & Signatory Vault) |

---

## 2. Purpose and User Goal

Allow users to capture, organize, and preview multiple handwritten wet signatures per business—either by drawing live on a touch pad or picking/photographing an image with automatic paper-background transparency removal—and designate an active signatory seal to stamp onto generated invoices (`InvoiceDetailsScreen`) and financial exports (`DataExportSettingsScreen`).

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `SignatureSettings.tsx` + `lib/signature-utils.ts` | Multi-signature registry (`SignatureRegistry` scoped by `businessId` in `localStorage`), HTML5 `<canvas>` drawing (`#0f172a` & `#1d4ed8`), PNG/JPEG upload with white paper removal (`brightness > 215` → alpha), signatory metadata (`label`, `signatoryName`, `signatoryTitle`), `autoApply` toggle, live certified voucher preview. | **Adapted (`UI Only` — Local Vault):** Replicates the full multi-signature vault, native `signature ^5.5.0` drawing pad, photo/gallery/file capture with Dart background-removal processor, and live document preview. |
| `SignatureSettings.tsx:901-905` (Misleading Encryption Claim) | Claims *"The active signature is encrypted, locally cached..."* despite storing unencrypted base64 in `localStorage` with zero backend APIs. | **Fixed Honestly:** Replaces misleading cloud/encryption copy with an explicit **Device-Local Vault** notice explaining signatures are stored on this device only and are not synced across devices or AFAB servers. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `SettingsHomeScreen` (`SET-01`) → **Wet Signature** (badged `"Device-Local"`).
  - Tablet Settings rail → **Wet Signature**.
  - Cross-links from `InvoiceDetailsScreen` / `DataExportSettingsScreen` when user taps `"Configure Signature"`.
  - Deep link `/dashboard/settings/signature`.

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone Layout (`< 600dp`, Single-Column Scrollable)
1. **Top AppBar:** Title `"Wet Signatures"` + count pill (`N Saved`) + `"New"` (`+`) icon action.
2. **Honest Device-Local Vault Banner (`AfabInsetPanel`):**
   - `Info` / `Shield` icon: *"Stored locally on this device for your active business. Signatures do not sync across devices or AFAB cloud servers."*
3. **Section 1 — Saved Signatures Vault (`AfabCard` / Horizontal Carousel or Vertical Cards):**
   - Empty state (`AfabEmptyState`) when `signatures.isEmpty`: `"No signatures saved yet"` with quick `"Draw"` / `"Upload"` jump actions.
   - Each saved signature card displays:
     - `label` (`Tag` icon), `signatoryName • signatoryTitle`
     - Emerald `"Active & In Use"` badge OR `"Set as Active"` button
     - `100dp`-tall preview box on neutral surface rendering transparent PNG ink
     - Footer actions: `Edit`, `Share / Save PNG` (`share_plus`), `Delete` (with confirm dialog)
4. **Section 2 — Add or Edit Signature Workspace (`AfabCard`):**
   - Edit-mode banner when `editingId != null` (`"Editing: <label>"` + `"Cancel"` button).
   - `AfabSegmentedBar` switching between **"Draw Signature Pad"** (default on touchscreens!) and **"Upload Image (PNG/JPEG)"**.
   - **Draw Tab:**
     - Ink color chips: Black (`#0f172a`) and Royal Blue (`#1d4ed8`), Eraser/Reset button.
     - Touch-locked `Signature` canvas (`200dp` height) inside dashed container (`NeverScrollableScrollPhysics` / gesture-arena lock while drawing so vertical scroll does not hijack strokes!).
     - `"Reset Pad"` + `"Use This Drawing"` emerald CTA.
   - **Upload Tab:**
     - `"Take Photo"` (Camera) + `"Choose from Gallery / Files"` (`image_picker` / `file_picker`, PNG/JPEG `<= 5 MB`).
     - `"Auto-remove paper background (Transparent ink)"` checkbox (`makeTransparent`, default `true`).
   - **Metadata & Auto-Apply Card:**
     - `Signature Label` (`e.g. CEO Primary`)
     - `Full Signatory Name` (defaults to `profile.firstName + lastName` or `business.name`)
     - `Signatory Title / Position` (defaults to `"Authorized Signatory"`)
     - `"Set this signature as active immediately"` checkbox (`makeDefaultOnSave`)
     - Global `"Automatically stamp active signature onto Invoices & Data Exports"` switch (`autoApply`)
   - Primary CTA: `"Save Signature to Vault"` / `"Update Signature"` (disabled until ink `signatureData != null`).
5. **Section 3 — Live Certified Document Preview (`AfabCard`):**
   - Miniature invoice/voucher header showing `business.name`, `CERTIFIED` badge, active signature label, and stamped wet-signature preview box (`image` + underline + `previewName` + `previewTitle`).

### Tablet Layout (`>= 600dp` / `>= 840dp`)
- Vault grid (`2–3` columns) at top, followed by `7:5` two-column editor + sticky Live Certified Document Preview on the right (matching `SignatureSettings.tsx:379, 490`).

---

## 6. UI Components and Interactive Elements

| Component | Package / Widget | Details |
|---|---|---|
| `SignatureDrawPad` | `signature: ^5.5.0` (`SignatureController`) | Smooth Bezier stroke rendering (`penStrokeWidth: 2.5`), supports Black `#0F172A` & Royal Blue `#1D4ED8`, exports crisp transparent PNG bytes (`toPngBytes()`). |
| `BackgroundRemovalProcessor` | Pure Dart Isolate + `image` / `dart:ui` | Replicates `processSignatureFile()`: downscales max dimension to `800px`, converts pixels with `(R+G+B)/3 > 215` to smooth transparent alpha (`max(0, 255 - (brightness - 215) * 8)`), and deepens dark ink (`R-20, G-20, B-15`) for crisp contrast. Runs in `compute()` isolate so UI never janks. |
| `SignatureVaultCard` | `AfabCard` | Highlights active signature with emerald border/ring, editing signature with primary ring. |
| `CertifiedPreviewCard` | `AfabCard` | Live preview updating immediately as user draws, uploads, or types signatory name/title. |

---

## 7. Data Requirements and API Contracts

- **Backend APIs:** **None** (0 endpoints exist in AFAB backend for signatures).
- **Local Storage Schema (`SharedPreferences` + App Documents Directory):**
  - Registry key scoped per business: `afab_wet_signature_registry_<businessId>` (fallback `afab_wet_signature_registry`).
  - JSON payload (`SignatureRegistry`):
    ```json
    {
      "activeId": "sig_1732...",
      "autoApply": true,
      "signatures": [
        {
          "id": "sig_1732...",
          "label": "Primary Signature",
          "filePath": "/.../signatures/<businessId>/sig_1732.png",
          "signatoryName": "Jane Doe",
          "signatoryTitle": "Authorized Signatory",
          "isDefault": true,
          "createdAt": "2026-11-25T18:00:00Z",
          "updatedAt": "2026-11-25T18:00:00Z"
        }
      ]
    }
    ```
  - Storing PNG bytes as files inside `getApplicationDocumentsDirectory()/signatures/<businessId>/` (with `android:allowBackup="false"`) avoids bloating `SharedPreferences` XML/plist limits while enabling direct embedding into `pdf ^3.11.0` documents.

---

## 8. State Management and Caching

- **`signatureVaultProvider(businessId)` (`NotifierProvider.family`):**
  - Keyed strictly by `businessId` (`activeBusinessProvider.id`).
  - Exposes `SignatureRegistry` (`activeSignature`, `signatures`, `autoApply`), plus actions: `setActive(id)`, `saveItem(...)`, `deleteItem(id)`, `setAutoApply(bool)`.
  - Watched by `InvoiceDetailsScreen` (PDF export) and `DataExportSettingsScreen` (`SET-07`) so updates reflect instantaneously.

---

## 9. User Actions, Validation, and Error Handling

- **Upload Validation:** Only PNG/JPEG accepted; reject files `> 5 MB` with localized error toast (`"File size too large (max 5 MB)"`).
- **Save Guard:** `"Save Signature to Vault"` disabled if no drawing/uploaded image is attached.
- **Delete Confirmation:** Deleting a saved signature prompts an alert dialog (`"Are you sure you want to delete signature '<label>'?"`); if active signature is deleted, automatically promotes the first remaining signature (or clears `activeId` if empty) and deletes the orphaned PNG file from disk.
- **Background Removal Failure Fallback:** If image pixel decoding fails, falls back safely to the raw resized PNG/JPEG bytes and notifies user.

---

## 10. Permissions, Security, and Tenant Isolation

- **Per-Business Isolation:** Registry keys and PNG subdirectories are strictly partitioned by `businessId`; switching workspace loads that workspace's own signatures. Deleting an account (`SET-10`) or logging out should retain or wipe local signature files per clear policy (wipe on account deletion; retain per `businessId` or clear on explicit device wipe).
- **OS Permissions:** Camera (`NSCameraUsageDescription`) and Photo Library (`NSPhotoLibraryUsageDescription`) requested just-in-time when user chooses Camera/Gallery upload.
- **Android Backup:** `android:allowBackup="false"` prevents unauthorized ADB/cloud backup extraction of local signature PNGs.

---

## 11. Localization (EN/AR) and RTL Behavior

- Extracts all hardcoded `isAr` ternaries from `SignatureSettings.tsx` (`"Wet Signatures & Signatory Vault"`, `"Saved Signatures Vault"`, `"Draw Signature Pad"`, `"Auto-remove paper background"`, `"Certified"`, etc.) into `app_en.arb` and `app_ar.arb`.
- **Canvas Directionality:** Drawing pad coordinates remain physical screen X/Y regardless of RTL; ink preview box centers the PNG cleanly.
- **Honest Device-Local Notice:** Localized in both English and Arabic, removing Web's inaccurate `"encrypted"` claim.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Touch Scroll Conflict Prevention:** While finger/stylus touches inside the `SignatureDrawPad` bounds, parent `SingleChildScrollView` physics switch or use `Listener`/`GestureDetector` capture so signatures never jitter or scroll the page mid-stroke.
- **Dark Mode Ink Visibility:** Because dark-ink signatures (`#0F172A`) are nearly invisible on dark backgrounds (`#0C101C`), always display saved/preview signature PNGs inside a crisp subtle light paper container or high-contrast surface (`#F8FAFC` / subtle off-white canvas card) in both Light and Dark themes!
- **Accessibility:** Clear/Reset/Upload/Set-Active buttons have `48dp` targets and `Semantics` labels.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Draw & Save Flow:** Drawing a stroke, tapping `"Use This Drawing"`, entering label/name/title, and saving creates a PNG on disk and updates `activeSignature`.
2. **Background Removal:** Importing a signature photo with white background (`RGB > 215`) and `makeTransparent = true` outputs a transparent PNG in an isolate without dropping frames.
3. **Multi-Signature Switch & Delete:** Creating 2 signatures, switching active from #1 to #2, and deleting #2 falls back to #1 cleanly.
4. **Business Isolation:** Switching `activeBusinessId` isolates signature lists per business.
5. **Honest Notice:** UI explicitly informs user that signatures are device-local and not synced to the cloud.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Packages** | `signature: ^5.5.0`, `image_picker: ^1.2.4`, `file_picker: ^13.4.1`, `image` (or `dart:ui`), `share_plus`, `path_provider` | All standard Flutter packages; keep heavy pixel math inside `compute()` isolate. |
| **Risk: Dark Mode Ink Invisibility** | Web renders dark `#0f172a` ink over `dark:bg-white/[0.02]`, making black ink unreadable in Dark Mode! | Render signature preview tiles on a light paper card (`#F8FAFC`) even in Dark Mode so black/blue ink always remains legible. |
| **Risk: Cross-Device Sync Expectation** | Users switching from Web to Mobile may expect signatures to sync. | State clearly in UI notice and propose future `signature_object_key` MinIO endpoint (`04_AUTHENTICATION_AND_SECURITY.md` §4.5). |
