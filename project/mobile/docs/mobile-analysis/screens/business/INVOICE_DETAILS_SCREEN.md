# INVOICE_DETAILS_SCREEN (`BIZ-04`)

> **Domain:** Business Operations (`invoices`)
> **Task Reference:** `P3-06`
> **Web Source:** `Web/project/frontend/app/[locale]/(dashboard)/dashboard/invoices/page.tsx` (Detail Drawer), `Web/project/frontend/lib/export-utils.ts` (`openPrintableInvoiceWindow`), `Web/project/frontend/lib/signature-utils.ts`
> **Backend Source:** `InvoiceController.java`, `InvoiceService.java`, `InvoiceDTO.java`, `Invoice.java`, `InvoiceStatus.java`, `BusinessDTO.java`

---

## 1. Screen Identity

- **Screen ID:** `BIZ-04`
- **Screen Name:** `InvoiceDetailsScreen`
- **Flutter File Path:** `lib/features/invoices/presentation/invoice_details_screen.dart`
- **PDF Builder Service:** `lib/features/invoices/data/invoice_pdf_generator.dart`
- **Route Path (`GoRouter`):** `/invoices/:invoiceId` (pushed full screen on `< 840dp`; rendered as right-hand inline pane on `>= 840dp` tablet landscape)

---

## 2. Purpose and Functional Scope

Displays the complete legal and financial breakdown of a single invoice (`GET /api/v1/invoices/{id}`): issuer identity (business name, logo, `taxId` / Matricule Fiscale), client details, lifecycle actions (Edit Draft, Issue as Sent or Unpaid, Record Payment, Cancel), financial summary totals, line items, FX-aware payment history, local wet signature certification preview, and native Arabic/English A4 PDF generation + OS sharing.

### Confirmed Web Bugs Fixed on Mobile
1. **Fix `subtotal` Field Bug in Printable PDF (`export-utils.ts:1179`):** Web's `openPrintableInvoiceWindow` reads `invoice.subtotalAmount ?? invoice.totalAmount` — because `InvoiceDTO.java` serializes `subtotal` (NOT `subtotalAmount`), Web prints `totalAmount` on the Subtotal line and omits `discountAmount`! Mobile PDF & UI read `invoice.subtotal` and `invoice.discountAmount` directly from `InvoiceDTO`.
2. **Expose Both `sent=true` and `sent=false` on Issue (`InvoiceController.java:75-80`):** Web only calls `issueInvoice(id, true)` (no option to issue without marking sent). Mobile presents an Issue action sheet / split choice: **"Mark as Sent"** (`POST /issue?sent=true` → `SENT`) and **"Issue as Unpaid"** (`POST /issue?sent=false` → `UNPAID`), while clearly noting that issuing does **not** automatically send an email (no SMTP invoice-email endpoint exists on backend).
3. **Arabic Font & Offline Native PDF (`pdf` + `printing` + `share_plus`):** Web relies on `window.open()` + browser print dialog with Google Fonts CDN. Mobile generates a self-contained A4 PDF with bundled `Cairo` TTF (Arabic) and `Inter` (Latin) fonts, supporting 3-decimal ISO-4217 currencies and instant sharing via WhatsApp/Email/Files.
4. **Honest Wet Signature Labeling:** Mirrors Web's local signature vault (`SharedPreferences` / local app docs) with explicit indication that the wet signature is stored **on this device only** (no backend sync).

---

## 3. Navigation and Entry / Exit Flows

- **Entry Points:**
  - `InvoicesScreen` (`BIZ-03`): tap invoice card/row or Upcoming Due item.
  - `CustomerDetailsScreen` (`BIZ-02`): tap an order/invoice card.
  - `AiCopilotScreen` / `GlobalCopilotSheet`: tap approved `CREATE_INVOICE` action draft (`"View Invoice"`).
- **Exit / Forward Flows:**
  - Tap `Edit Draft` → pushes `CreateEditInvoiceScreen` (`BIZ-05`, Edit mode).
  - Tap `Record Payment` → opens `RecordPaymentSheet` (`BIZ-06`).
  - Tap `Generate / Share PDF` → builds A4 PDF → opens preview/print sheet (`printing`) or OS share sheet (`share_plus`).
  - Tap `Set +` on missing `taxId` (MF) → pushes `BusinessProfileScreen` (`/settings/business-profile`).
  - Tap `Configure wet signature` → pushes `SignatureSettingsScreen` (`/settings/signature`).
  - Tap a payment's `incomeTransactionId` chip (`TX ...`) → pushes `TransactionDetailsScreen` (`/transactions/:txId`).
  - Tap client name (when `customerId != null`) → pushes `CustomerDetailsScreen` (`/customers/:customerId`).
  - Tap AI Reminder (`Sparkles` for `SENT`/`UNPAID`/`PARTIALLY_PAID`/`OVERDUE`) → opens `GlobalCopilotSheet`.

---

## 4. Layout and Responsive Behavior

- **Phone (`< 600dp`):** Full-screen `Scaffold` with AppBar (`invoiceNumber`, PDF/Share icon button, overflow menu), scrollable `ListView` body (`SafeArea`), and sticky bottom action bar adapting to current `InvoiceStatus`.
- **Tablet Portrait (`600–839dp`):** Full-screen `maxWidth: 720dp` centered layout with 3-col Totals card and side-by-side Issuer/Client header.
- **Tablet Landscape (`>= 840dp`):** Embedded `42%` right-hand detail pane inside `InvoicesScreen` Master-Detail split.

---

## 5. UI Components and Visual Hierarchy

1. **Issuer & Client Header Card (`AfabCard`):**
   - **Issuer Block:**
     - Business Logo (`48x48dp` rounded container): loads `activeBusiness.logoUrl` via `CachedNetworkImage` if valid HTTPS URL, falling back gracefully to bundled `assets/images/afab-logo-light.png` (no broken `localStorage` data URI).
     - Label `"Issuer"` + `activeBusiness.name`.
     - **Fiscal ID (`taxId` / Matricule Fiscale):** Displays monospace MF pill if `activeBusiness.taxId` is set; otherwise shows `"Set +"` link to `BusinessProfileScreen`.
     - Optional business address formatted via `addressLine, city, state, postalCode, country`.
   - **Client & Invoice Metadata Block:**
     - Label `"Billed To"` + tappable `customerName` (or `"General Client"`) + `customerEmail`.
     - Monospace `invoiceNumber` (LTR) + `AfabStatusBadge` (`status`).
     - `Issue Date` and `Due Date` (with overdue indicator when `invoice.overdue == true`).
2. **Lifecycle Action Bar (Contextual by `status` & `paidAmount`):**
   - Always available: **`Print / Share PDF`** (`Printer` / `Share2`).
   - When `status == "DRAFT"`:
     - **`Edit Draft`** (`Pencil`) → `BIZ-05`.
     - **`Issue Invoice`** (`Send`) → opens quick choice dialog/sheet:
       - *Issue & Mark Sent* (`sent=true` → `SENT`)
       - *Issue as Unpaid* (`sent=false` → `UNPAID`)
   - When `status` is `UNPAID`, `SENT`, `PARTIALLY_PAID`, or `OVERDUE`:
     - **`Record Payment`** (`DollarSign`, Emerald CTA) → `BIZ-06`.
     - **`AI Reminder`** (`Sparkles`, Soft Violet) → `GlobalCopilotSheet`.
   - When `status != "PAID" && status != "CANCELLED" && paidAmount == 0`:
     - **`Cancel Invoice`** (`Ban`, Danger outlined) → confirmation dialog → `POST /cancel`.
3. **Financial Totals Summary (`AfabCard` + 3 `AfabInsetPanel` tiles):**
   - **Total:** `MoneyText(invoice.totalAmount, invoice.currency)`
   - **Paid:** `MoneyText(invoice.paidAmount, invoice.currency)` (Emerald tint)
   - **Outstanding:** `MoneyText(invoice.outstandingBalance, invoice.currency)` (Amber tint when `> 0`, Emerald when `0`)
   - Breakdown sub-rows: `Subtotal` (`invoice.subtotal`), `Discount` (`-invoice.discountAmount`, shown when `> 0`), `Tax Total` (`invoice.taxAmount`).
4. **Line Items Section (`AfabCard`):**
   - Each `InvoiceItemDTO` row:
     - `description` (bold)
     - Formula line (LTR): `${quantity} × ${MoneyText(unitPrice, currency)}` + optional `(+${taxRate}% tax)`
     - Right-aligned `MoneyText(lineTotal ?? (quantity * unitPrice), currency)`
5. **Payment History Section (`AfabCard`):**
   - Header: `Payment History (${payments.length})`.
   - Empty state (dashed inset): *"No payments recorded yet. Unpaid invoices do not record income until paid."*
   - Populated `PaymentDTO` cards (tappable to view linked `INCOME` transaction):
     - `+${MoneyText(p.amount, p.currency)}` (Emerald)
     - **FX Conversion Line** (shown when `p.currency != p.baseCurrency`): `(${MoneyText(p.convertedBaseAmount, p.baseCurrency)} @ ${p.exchangeRate})`
     - Metadata: `${localized p.paymentDate} · ${localized p.paymentMethod}` + optional `· Ref: ${p.reference}`
     - Linked transaction chip: `TX ${p.incomeTransactionId.substring(0, 8)}` → navigates to `TransactionDetailsScreen`.
6. **Authorized Wet Signature & Seal Card (`AfabCard`):**
   - Reads local signature registry (`SignatureLocalStore` keyed by `businessId`).
   - If active & `autoApply` enabled: displays `signatoryName`, `signatoryTitle`, `taxId` (MF), `"Digitally Certified (Device Local)"` pill, and rendered signature PNG image; plus an inline toggle `"Include signature in PDF"` for this export.
   - If none configured: dashed prompt with `"Configure wet signature in Settings →"` link.
7. **Notes Section:** Rendered if `invoice.notes` is non-blank.

---

## 6. Interactive States and User Flows

- **Loading:** Full-screen `AfabLoader` while `GET /api/v1/invoices/{id}` fetches `items[]` and `payments[]`.
- **Error / 404:** Error banner with `Retry`; on `404` or `403`, show `"Invoice unavailable"` and pop safely.
- **Issue Flow:**
  1. Tapping `Issue Invoice` shows a compact `AfabBottomSheet` / `AlertDialog` with two options (`Mark as Sent` [`sent=true`] vs `Issue as Unpaid` [`sent=false`]) and a note: *"Issuing finalizes draft totals. No income transaction is recorded until a payment is received."*
  2. Disable action buttons while `actionBusy == true` → `POST /api/v1/invoices/{id}/issue?sent=...` → update state with returned `InvoiceDTO` → invalidate `invoicesProvider` & `customersProvider` → toast.
- **Cancel Flow:**
  1. Tapping `Cancel Invoice` opens destructive confirmation `AlertDialog` (`"Cancel Invoice ${invoiceNumber}? Cancelled invoices cannot be edited or paid."`).
  2. Confirm → `POST /api/v1/invoices/{id}/cancel` → update `InvoiceDTO` → invalidate list/summary providers → toast.
- **Native PDF Generation & Share Flow (`InvoicePdfGenerator`):**
  1. Builds A4 PDF (`pdf` package) using bundled `Cairo` (for `ar` or Arabic content) + `Inter` (for `en`) TTF fonts so Arabic RTL text shapes cleanly without tofu boxes (`□□□`).
  2. Header: Business Logo (downloaded/cached bytes or bundled AFAB logo) + `business.name` + `MF: ${taxId}` + `address` + `businessEmail`/`phoneNumber`; Client block (`customerName`, `customerEmail`, `invoiceNumber`, `issueDate`, `dueDate`, `status` badge).
  3. KPI bar: Total, Paid, Balance Due.
  4. Line items table: Description, Qty, Unit Price, Tax %, Line Total (formatted with ISO-4217 minor units in `invoice.currency`).
  5. Totals summary box: **`Subtotal` (`invoice.subtotal`)**, **`Discount` (`-invoice.discountAmount`, if `> 0`)**, **`Tax Total` (`invoice.taxAmount`)**, **`Total Amount` (`invoice.totalAmount`)**, **`Paid` (`invoice.paidAmount`)**, **`Balance Due` (`invoice.outstandingBalance`)**.
  6. Recorded Payments History table (if `payments.isNotEmpty`), including FX base equivalent if `p.currency != p.baseCurrency`.
  7. Optional Wet Signature Certification Block (when enabled and image bytes exist).
  8. Opens native print/preview (`Printing.layoutPdf`) or immediately shares file `AFAB-Invoice-${invoiceNumber}.pdf` via `Share.shareXFiles` (`share_plus`).

---

## 7. API Endpoints and Data Contracts

| Operation | Method & Path | Query / Body | Response DTO | Notes |
|---|---|---|---|---|
| Get Full Invoice | `GET /api/v1/invoices/{id}` | — | `200 InvoiceDTO` | Populates `items[]` and `payments[]` (with `incomeTransactionId`, `convertedBaseAmount`, `baseCurrency`, `exchangeRate`). |
| Issue Draft | `POST /api/v1/invoices/{id}/issue` | `?sent=true\|false` | `200 InvoiceDTO` | `DRAFT` only (`409` otherwise); rejects `totalAmount <= 0` (`400`). |
| Cancel Invoice | `POST /api/v1/invoices/{id}/cancel` | — | `200 InvoiceDTO` | Requires `paidAmount == 0` and not `PAID`/`CANCELLED` (`409` otherwise). |
| Record Payment | `POST /api/v1/invoices/{id}/payments` | `Idempotency-Key` + `RecordPaymentRequest` | `201 PaymentDTO` | Handled via `BIZ-06`; triggers refresh of `BIZ-04`. |

---

## 8. State Management and Caching

- **`invoiceDetailProvider(String invoiceId)` (`FutureProvider.autoDispose.family`):** Watches `activeBusinessIdProvider` and fetches `GET /api/v1/invoices/{id}`.
- **`invoiceActionControllerProvider` (`AsyncNotifier`):** Guards `issueInvoice`, `cancelInvoice`, and `generatePdf` with `isBusy` lock to prevent double taps.
- **Invalidation:** Any lifecycle mutation (`issue`, `cancel`, `edit`, `payment`) updates/invalidates `invoiceDetailProvider(id)`, `invoiceListProvider`, `invoiceSummaryProvider`, `customerListProvider`, `customerSummaryProvider`, `customerDetailProvider(customerId)`, and `dashboardSummaryProvider` (plus `transactionsProvider` on payment).

---

## 9. Validation, Error Handling, and Edge Cases

- **`409 Conflict` Transitions:** If invoice state changed concurrently on another device (e.g., already paid or issued), catch `409`, display server message via `AfabToast.error`, and immediately refresh `invoiceDetailProvider(id)` so UI reflects true server state.
- **Zero-Total Draft Issue Guard:** Backend rejects issuing a `DRAFT` with `totalAmount <= 0` (`400`). Disable `Issue Invoice` or show inline explanation when `totalAmount <= 0`.
- **Logo Fetch Failure in PDF:** If `business.logoUrl` is unreachable offline or times out (`3s` timeout), fall back seamlessly to bundled `assets/images/afab-logo-light.png` so PDF export never fails offline.

---

## 10. Localization and RTL Support

- Full EN/AR localization for all status badges (`DRAFT`, `SENT`, `UNPAID`, `PARTIALLY_PAID`, `PAID`, `OVERDUE`, `CANCELLED`), action buttons, PDF section headers, and payment methods.
- PDF generator sets `pw.Directionality(textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr)` when `Locale == 'ar'`, while wrapping `invoiceNumber`, `taxId`, currency figures, and dates in LTR spans with Western digits (`0–9`).

---

## 11. Accessibility and Touch Ergonomics

- Minimum `48x48dp` targets on all lifecycle action buttons, PDF/Share actions, `TX` link pills, and customer link.
- Sticky bottom bar uses `Wrap` / scrollable action row on `< 360dp` screens so `Edit Draft`, `Issue`, `Cancel`, and `PDF` never overflow horizontally.
- High-contrast semantic colors across all 4 dark themes (`midnight`, `oled`, `slate`, `charcoal`) and light mode.

---

## 12. Security, Multi-Tenancy, and Plan Entitlements

- Tenant-scoped by `X-Business-Id` (`invoice.business.id == business.id`).
- `READ_ONLY` workspaces hide/disable `Edit Draft`, `Issue Invoice`, `Record Payment`, and `Cancel Invoice` while still allowing read inspection and PDF generation/export.
- Generated PDF files are written to temporary cache (`getTemporaryDirectory()`) and shared via `FileProvider`/`UIActivityViewController` without leaving unencrypted copies in public shared storage unless explicitly saved by user.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Unit Tests:**
   - Verify `InvoiceDTO` parsing for `subtotal`, `discountAmount`, `taxAmount`, `totalAmount`, `paidAmount`, `outstandingBalance`, and `payments[]` FX fields.
   - Verify `InvoicePdfGenerator` outputs non-empty valid `%PDF-` bytes in both `en` and `ar` (with `Cairo` font), renders `invoice.subtotal` (NOT `totalAmount`) on the Subtotal line, and includes `discountAmount` when `> 0`.
2. **Widget Tests:**
   - Verify lifecycle action matrix for every status: `DRAFT` (`Edit`, `Issue`, `Cancel`), `SENT`/`UNPAID` (`Record Payment`, `AI Reminder`, `Cancel` if `paidAmount == 0`), `PARTIALLY_PAID` (`Record Payment`, `AI Reminder`, NO `Cancel`), `PAID` (`PDF` only), `CANCELLED` (`PDF` only).
   - Verify FX line renders only when `p.currency != p.baseCurrency`.
3. **Integration Test:** Load `DRAFT` invoice → `Edit Draft` → `Issue` (`sent=true`) → verify status becomes `SENT` → `Record Payment` (partial) → verify `PARTIALLY_PAID`, `Cancel` disappears, and `payments[]` shows linked `TX`.

---

## 14. Dependencies and Risks

- **Dependencies:** `pdf: ^3.11.0`, `printing: ^5.15.0`, `share_plus: ^13.3.1`, `path_provider: ^2.1.5`, `cached_network_image: ^4.0.7`, `decimal: ^3.2.6`.
- **Risks:**
  - **Arabic PDF BiDi Shaping:** `pdf` package requires a bundled TTF (`Cairo-Regular.ttf`, `Cairo-Bold.ttf`) and explicit `TextDirection.rtl` + `intl` Western digits; must be golden/byte-tested with mixed Arabic descriptions and English `INV-2026-0001` codes.
  - **Wet Signature Local-Only Persistence:** Signature exists only on the local device; document clearly in UI so multi-device users aren't surprised if signature configured on Web doesn't appear on Mobile.
