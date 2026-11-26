# `FIN-08` — Receipt Viewer & Upload Flow (`ReceiptViewerAndUploadFlow`)

> **Domain:** Financial Core (`features/receipts`)
> **Priority:** P1 (Private Encrypted Receipt Attachment, Compression, Magic-Byte Validation & Authenticated Preview)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-08` |
| **Screen / Flow Name** | `ReceiptUploadSheet` + `ReceiptViewerScreen` |
| **Route Path (`GoRouter`)** | `/transactions/:transactionId/receipts/:receiptId` (`ReceiptViewerScreen`) + modal `ReceiptUploadSheet` triggered from `FIN-02` |
| **Feature Module** | `lib/features/receipts/presentation/` (`receipt_upload_sheet.dart`, `receipt_viewer_screen.dart`) |
| **Web Source Equivalent** | `Web/project/frontend/components/dashboard/TransactionDetailDrawer.tsx:104-150,298-375` + `lib/api/receipts.ts` |
| **Backend Controllers** | `ReceiptController.java` (`/api/v1/receipts`: `POST /transactions/{txId}`, `GET /transactions/{txId}`, `GET /{id}/content`, `GET /{id}/download-url`, `DELETE /{id}`) + `ReceiptService.java` |
| **Access Level** | Authenticated + Active Business Member (`EDITABLE` required for Upload & Delete; `READ_ONLY` allows Preview & Download/Share) |

---

## 2. Purpose & User Jobs

1. **Capture & Attach Receipts Natively:** Snap a paper receipt photo with the device camera, pick an existing image from the photo gallery, or select a PDF/image document from device storage.
2. **Optimize & Validate Before Upload:** Compress large camera photos cleanly on-device (`<= 10 MB`), verify allowed types (`PDF`, `JPEG`, `PNG`, `WEBP`) via **magic-byte inspection** matching `ReceiptService.java:230-256`, and show real-time upload progress with cancellation support.
3. **Preview Private Receipts Securely:** Render image receipts inside an interactive pinch-to-zoom viewer and PDF receipts via native PDF preview by streaming authenticated bytes from `GET /api/v1/receipts/{id}/content` (`Cache-Control: private, no-store`).
4. **Share, Save or Delete:** Generate short-lived presigned URLs (`GET /api/v1/receipts/{id}/download-url`, default `300s` expiry) or share/save downloaded files via native `share_plus` / `open_filex`, and delete unwanted receipts with confirmation.

---

## 3. Navigation & Entry/Exit Flows

### Entry Points
- `Attach Receipt` button on `FIN-02` (`TRANSACTION_DETAILS_SCREEN.md`) → opens `ReceiptUploadSheet`.
- Tapping any receipt row on `FIN-02` → pushes `ReceiptViewerScreen` (`/transactions/:transactionId/receipts/:receiptId`).

### Exit Points
| Trigger | Behavior |
|---|---|
| Upload complete (`201 Created`) | Closes upload indicator, prepends `ReceiptDTO` to `transactionReceiptsProvider(transactionId)`, shows `AfabToast` `"Receipt uploaded securely."`. |
| Cancel Upload (`CancelToken`) | Aborts in-flight multipart `POST`, removes temp compressed file, restores idle state. |
| Share / Export inside Viewer | Streams bytes to temp file (`originalFilename`) and opens OS Share Sheet (`share_plus`), or copies short-lived presigned link if requested. |
| Delete Receipt (`DELETE /receipts/{id}`) | Confirmation dialog → `204 No Content` → removes from `transactionReceiptsProvider` & pops `ReceiptViewerScreen`. |

---

## 4. Layout & Visual Architecture

### 4.1 `ReceiptUploadSheet` (`AfabBottomSheet`)
- **Drag Handle + Header:** `"Attach Receipt"` + subtitle `"PDF, JPEG, PNG, or WEBP (max 10 MB)"`.
- **3 Source Tiles (`48dp+` touch height):**
  1. `Take Photo` (`Camera` icon) → `image_picker` (`ImageSource.camera`)
  2. `Photo Library` (`Image` icon) → `image_picker` (`ImageSource.gallery`)
  3. `Browse PDF or File` (`FileText` icon) → `file_picker` (`FileType.custom`, `['pdf', 'jpg', 'jpeg', 'png', 'webp']`)
- **Upload Progress Overlay / Inline Banner (on `FIN-02`):** Linear progress bar (`sent / total` bytes) + `Cancel` icon button.

### 4.2 `ReceiptViewerScreen`
- **Dark-Friendly Viewer AppBar:** Back arrow (`matchTextDirection: true`), truncated `receipt.originalFilename`, trailing actions: `Share` (`share_plus`), `Link` (optional presigned link info/copy), `Delete` (`Trash2`, hidden when `READ_ONLY`).
- **Content Stage:**
  - **Images (`image/jpeg`, `image/png`, `image/webp`):** `InteractiveViewer(minScale: 0.8, maxScale: 5.0)` centering decoded `Uint8List` image with dark neutral backdrop (`#060813`) and double-tap zoom toggle.
  - **PDF (`application/pdf`):** Native PDF viewer/preview (`printing` `PdfPreview` with actions disabled or `open_filex` handoff card displaying PDF icon, filename, size, and `"Open PDF"` / `"Share PDF"` buttons if inline preview is unsupported on an emulator).
  - **Loading State:** `AfabLoader` + `"Decrypting private receipt..."`.
  - **Error State:** Retry button (handles `401` refresh automatically via `Dio` `AuthInterceptor`, `404` not found, network errors).
- **Bottom Metadata Bar (`SafeArea`):**
  - `contentType` badge (`PDF` / `JPEG` / `PNG` / `WEBP`) • `fileSizeBytes` formatted (`B` / `KB` / `MB`) • upload date • collapsible `SHA-256` checksum (LTR monospace).

---

## 5. UI Components & Interactive Controls

| Component | Package / Widget | Behavior |
|---|---|---|
| **`ReceiptSourcePickerSheet`** | `AfabBottomSheet` | Requests Camera permission on demand (`ImagePicker`); handles user cancellation (`null` result) silently without error toast. |
| **`ReceiptUploadProgressChip`** | `LinearProgressIndicator` + `CancelToken` | Tracks `Dio` `onSendProgress` percentage; allows aborting large uploads on slow cellular networks. |
| **`AuthenticatedReceiptImage`** | `InteractiveViewer` + `Image.memory` | Renders `Uint8List` fetched via `Dio` `ResponseType.bytes` with `Authorization` + `X-Business-Id`. |
| **`ReceiptDeleteDialog`** | `AlertDialog` | Explains deletion removes the file permanently from private storage; calls `DELETE /api/v1/receipts/{id}`. |

---

## 6. Data Requirements & API Contracts

### 6.1 `POST /api/v1/receipts/transactions/{transactionId}`
- **Headers:** `Authorization: Bearer <jwt>`, `X-Business-Id: <uuid>`, `Content-Type: multipart/form-data`
- **Form Part:** `file` (`MultipartFile`)
- **Backend Constraints (`ReceiptService.java:41-46,74,87-122`):**
  - Max size: `10,485,760` bytes (`10 MB`, `afab.minio.max-file-size-bytes`).
  - Allowed MIME & Magic Bytes:
    - `application/pdf` (`%PDF-`: `25 50 44 46 2D`)
    - `image/png` (`89 50 4E 47 0D 0A 1A 0A`)
    - `image/jpeg` (`FF D8 FF`)
    - `image/webp` (`RIFF....WEBP`)
  - Declared part `Content-Type` must match magic-byte-detected MIME (or be `application/octet-stream`), otherwise backend throws `400`.
  - Server sanitizes filename (`<= 200` chars), computes `SHA-256` hex checksum, and stores under `businesses/{businessId}/transactions/{transactionId}/{uuid}.{ext}` in private MinIO/S3.
- **Response (`201 Created` — `ReceiptDTO`):**
  `{ id, businessId, transactionId, originalFilename, contentType, fileSizeBytes, sha256Checksum, createdAt }`

### 6.2 `GET /api/v1/receipts/transactions/{transactionId}`
- **Response (`200 OK`):** `List<ReceiptDTO>` ordered newest-first.

### 6.3 `GET /api/v1/receipts/{id}/content`
- **Headers:** `Authorization: Bearer <jwt>`, `X-Business-Id: <uuid>`
- **Response (`200 OK`):** `byte[]` stream (`ResponseType.bytes` in `Dio`), `Content-Type: <detectedMime>`, `Cache-Control: private, no-store`, `X-Content-Type-Options: nosniff`.

### 6.4 `GET /api/v1/receipts/{id}/download-url`
- **Response (`200 OK` — `PresignedDownloadDTO`):**
  `{ receiptId, url, expiresInSeconds (300 default, clamped 30..3600), filename, contentType }`
- **Mobile Note:** Because MinIO in local/Docker setups may sign URLs against an internal Docker/localhost hostname unreachable from external share recipients (or unreachable on mobile device if `MINIO_ENDPOINT` is `minio:9000`), **always prefer `GET /receipts/{id}/content` + `share_plus` file sharing** inside the app! Offer presigned URL copy only as a secondary utility when `url` is reachable.

### 6.5 `DELETE /api/v1/receipts/{id}`
- **Response (`204 No Content`):** Deletes S3/MinIO object and soft-deletes `Receipt` metadata.

---

## 7. State Management & Data Flow

```text
receiptUploadController (AutoDisposeNotifierProvider.family<ReceiptUploadState, String /*txId*/>)
  ├── idle | picking | compressing | validating | uploading(progress: double) | error(msg)
  └── upload(txId, source) -> pick -> compress (if image) -> validate magic bytes & <= 10MB -> POST multipart

receiptContentProvider (FutureProvider.autoDispose.family<Uint8List, String /*receiptId*/>)
  └── GET /api/v1/receipts/{id}/content (ResponseType.bytes, keepAlive: false so private bytes clear on pop!)
```

- **Memory & Disk Cleanup:** Because `receiptContentProvider` is `autoDispose`, binary receipt bytes in RAM are released as soon as `ReceiptViewerScreen` closes. Any temp file written for `share_plus` / PDF viewing is placed in `getTemporaryDirectory()/afab_receipts/` and purged on logout or app startup.

---

## 8. Business Logic, Validation & Edge Cases

1. **Client-Side Image Compression (`flutter_image_compress`):**
   - For camera/gallery images (`JPEG`/`PNG`/`WEBP`), if file size `> 1 MB` or dimensions `> 1600px`, compress to `maxWidth: 1600, maxHeight: 1600, quality: 82` (preserving orientation EXIF rotated upright).
   - Keep `PDF` files untouched; validate size `<= 10,485,760` bytes after compression. If a PDF or compressed image still exceeds `10 MB`, reject immediately with localized `"Receipt file exceeds the 10 MB maximum limit."` before hitting the network.
2. **Client-Side Magic-Byte Verification:**
   - Read first 12 bytes of selected file and verify against the 4 backend signatures (`%PDF-`, `PNG`, `JPEG`, `WEBP`). Prevents wasted uploads of renamed `.heic`/`.txt` files (note: on iOS, `image_picker` converts HEIC photos to JPEG automatically when `imageQuality` or default settings are applied; if `file_picker` picks `.heic`, reject or convert to JPEG before upload!).
   - Set explicit `MediaType` on `Dio` `MultipartFile.fromFile(..., contentType: MediaType.parse(detectedMime))` so backend `normalizedMime.equals(detectedMime)` check (`ReceiptService.java:116`) ALWAYS succeeds!
3. **Zero-Byte File Guard:** Reject `fileSize == 0` matching `ReceiptService.java:88`.
4. **Offline / Interrupted Upload:** If upload fails mid-stream due to network loss, display retry prompt with `"Upload failed — check connection and try again"`; no partial receipt is created on backend.
5. **Read-Only Workspace:** `BusinessAccessGuard.assertEditable` blocks upload & delete with `403 BUSINESS_READ_ONLY`. Mobile proactively hides upload/delete triggers when `activeBusiness.editable == false`.

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **No Inline Receipt Preview:** Web only triggers a blind `<a download>` blob download without viewing images or PDFs in-app. | `TransactionDetailDrawer.tsx:134-140`, `receipts.ts:51-67` | Mobile provides `ReceiptViewerScreen` with zoomable `InteractiveViewer` + PDF preview + native `share_plus`. |
| **No Camera Capture or Compression:** Web relies on `<input type="file">`, failing easily when modern phone cameras produce `> 10 MB` photos or `HEIC` images. | `TransactionDetailDrawer.tsx:317-323` | Mobile integrates `image_picker` camera/gallery + `flutter_image_compress` (JPEG conversion + resize) + `file_picker` for PDFs. |
| **No Upload Progress or Cancellation:** Web shows a generic spinner (`uploadingReceipt`) with no percentage or cancel control. | `TransactionDetailDrawer.tsx:310-316` | Mobile displays `Dio` `onSendProgress` bar and `CancelToken` abort button. |
| **Silent Delete Without Confirmation:** Web deletes receipt immediately on single trash icon click (`handleDeleteReceipt`). | `TransactionDetailDrawer.tsx:142-150,362-369` | Mobile requires explicit confirmation dialog before `DELETE /api/v1/receipts/{id}`. |
| **Unused `getDownloadUrl` API:** `receipts.ts:47-49` defines `getDownloadUrl` but never surfaces it. | `receipts.ts:47-49` | Mobile documents `GET /{id}/content` as primary private preview/share path and uses `/{id}/download-url` only as optional short-lived link utility. |

---

## 10. Design Tokens & Visual Styling

- **Upload Sheet:** `AfabBottomSheet` (`surface`, `24dp` top corners), source tiles use `surfaceInset` + `1px border` + `AfabColors.primary` leading icon container.
- **Image Viewer Backdrop:** Deep dark `#060813` canvas for high contrast receipt legibility regardless of app light/dark theme.
- **Progress Indicator:** `AfabColors.primary` bar on `surfaceInset` track.
- **File Type Pill:** `AfabStatusBadge` (`PDF` danger/rose tint, `JPEG`/`PNG`/`WEBP` info/sky tint).

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** `transactions.json` → `drawer.{receipts, attachReceipt, uploading, loadingReceipts, noReceipts, downloadReceipt, deleteReceipt, invalidReceiptType, receiptTooLarge, receiptUploaded, receiptDeleted}` + new ARB keys for `Take Photo`, `Choose from Gallery`, `Browse PDF / Document`, `Cancel Upload`, `Share Receipt`, `Delete Receipt Confirm`, `Expires in 5 minutes`, and `Permission Denied (Camera/Photos)`.
- **BiDi Rules:** Filenames, MIME types (`image/jpeg`), file sizes (`1.42 MB`), and `SHA-256` checksums forced `TextDirection.ltr`.

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` & `compact` (`< 600dp`) | `ReceiptUploadSheet` modal bottom sheet; full-screen `ReceiptViewerScreen` with pinch-to-zoom. |
| `medium` & `expanded` (`>= 600dp`) | Centered picker dialog (`maxWidth: 420dp`); full-screen or centered modal `ReceiptViewerScreen` (`maxWidth: 900dp`, `maxHeight: 90%`) with side/bottom metadata bar. |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** Screen readers announce filename, MIME type, and formatted size; `Semantics` labels on Zoom/Share/Delete buttons; `48dp` minimum hit targets.
- **Security (Critical for Private Receipts):**
  - **Never** save private receipts to the public device photo album by default.
  - **Never** cache `GET /receipts/{id}/content` in `cached_network_image` or persistent HTTP disk cache (obey `Cache-Control: private, no-store`).
  - Pass `Authorization: Bearer` + `X-Business-Id` strictly through `Dio`; purge temp share files on session end/logout.
  - Declare `NSCameraUsageDescription` & `NSPhotoLibraryUsageDescription` (`Info.plist`) and `CAMERA` / `READ_MEDIA_IMAGES` (`AndroidManifest.xml`), handling permanent permission denial gracefully with an `"Open App Settings"` CTA.
- **Performance:** Compress large photos in a background isolate (`flutter_image_compress` runs natively off the UI thread) so UI stays 60fps; `autoDispose` releases decoded image memory immediately upon leaving viewer.

---

## 14. Dependencies and Risks

- **Dependencies:** `image_picker: ^1.2.4`, `file_picker: ^13.4.1`, `flutter_image_compress`, `printing: ^5.15.0` (PDF preview), `share_plus: ^13.3.1`, `open_filex: ^5.0.0`, `path_provider: ^2.1.5`, `http_parser` (`MediaType`).
- **Risks & Mitigations:**
  1. **iOS `HEIC` Format Rejected by Backend:** Backend `ReceiptService.java` accepts only `PDF`, `JPEG`, `PNG`, `WEBP`. *Mitigation:* Always transcode picked/captured `HEIC` images to `JPEG` via `flutter_image_compress` (and verify magic bytes `FF D8 FF`) before multipart upload.
  2. **Presigned URL Hostname Unreachable on Mobile (`localhost`/`minio:9000`):** `GET /{id}/download-url` returns MinIO's internal endpoint URL. *Mitigation:* Always use authenticated `GET /receipts/{id}/content` for in-app viewing and `share_plus` file sharing.
  3. **Duplicate `image_picker` / `file_picker` OOM on Low-RAM Android Devices:** Decoding 12MP–48MP photos in Dart heap causes OOM. *Mitigation:* Pass `maxWidth: 2048, maxHeight: 2048` or compress directly from file path (`compressAndGetFile`) without loading uncompressed bitmaps into Dart memory.
