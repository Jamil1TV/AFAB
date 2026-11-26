# SET-07 — Data & Export Settings Screen (`DataExportSettingsScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-07` |
| **Screen Name** | Data & Export Center (`DataExportSettingsScreen` + `ExportPeriodModalSheet`) |
| **Route Path** | `/settings/data-export` |
| **Feature Module** | `lib/features/settings/presentation/data_export_settings_screen.dart` & `export_period_sheet.dart` |
| **Web Equivalent** | `settings/data-export/page.tsx` + `DataExportSettings.tsx` + `ExportPeriodModal.tsx` + `lib/export-utils.ts` |
| **Priority** | P2 (Enterprise Reporting, Excel & PDF Archives) |

---

## 2. Purpose and User Goal

Enable business users to filter and export complete financial archives (Executive KPIs, Transactions, Customer Directory, Invoices) or individual datasets into multi-sheet `.xlsx` workbooks, Arabic-capable branded `.pdf` reports, or backend-certified P&L CSV/PDF statements, and immediately preview or share them via native mobile share sheets.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `DataExportSettings.tsx` | Period filter (`9` presets + custom range), currency selector, 4 live counter cards, Master Archive (`.xlsx`, `.pdf`, Print), 4 Modular dataset cards (Transactions, Customers, Invoices, P&L Backend Reports). Fetches `size: 1000` on mount. | **Implemented but Incomplete → Enhanced on Mobile:** Replaces `xlsx`/`jsPDF` browser blobs & `window.print()` with native `excel_community ^2.6.2` (`.xlsx`), `pdf ^3.11.0` + `printing ^5.15.0` (bundled **Cairo TTF** fixing Web's missing Arabic glyphs in `jsPDF`!), and `share_plus` / `open_filex`. |
| `ExportPeriodModal.tsx` | Pre-download modal confirming period preset, custom dates, Fiscal Matricule (`MF`), Business Purpose, Official Address, currency, `includeLogo`, `includeSignature`, and active range badge. | **Implemented and Connected:** Presented as `ExportPeriodSheet` (`AfabBottomSheet`), persisting optional branding overrides scoped per `businessId`. |
| **1000-Row Fetch Cap & Backend `size` Limit** | Web requests `page=0, size=1000` from `/transactions`, `/customers`, `/invoices`; backend `/transactions` enforces `size <= 100` (`03_API_CONTRACT_CATALOG.md` §2.5), silently truncating large ledgers! | **Mitigated Explicitly:** Mobile paginates up to 1,000 rows (`page=0..9, size=100` or server page limit) and renders a **clear truncation warning banner** whenever `totalElements > loadedCount` (recommending narrower period filters or backend CSV/JSON export). |
| **Currency Selector Bug** | Web lets user switch `selectedCurrency` without converting individual rows or summary amounts via FX. | **Mitigated Honestly:** Preserves each transaction/invoice's original `currency` in row tables and labels summary currency clearly as display-only (`business.currency` default) when mixed currencies exist. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `SettingsHomeScreen` (`SET-01`) → **Data & Export**.
  - Tablet Settings rail → **Data & Export**.
  - Deep link `/dashboard/settings/data-export`.
- **Child Overlays:**
  - `ExportPeriodSheet` (pre-download configuration sheet).
  - Native PDF Preview / Print (`printing` `PdfPreview` screen) or OS Share Sheet (`share_plus`).
  - `PlanLimitBottomSheet` (if backend `/reports/export/{csv,pdf}` returns `403 PLAN_LIMIT_REACHED`).

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone Layout (`< 600dp`, Single-Column Scrollable)
1. **Top AppBar:** Title `"Data & Export"` + trailing `"Refresh"` icon button (`fetchAllData`).
2. **Dataset Truncation Warning Banner (Conditional):** Amber `AfabInsetPanel` shown if `transactions.totalElements > loadedTransactions.length` (or `>= 1000` cap reached), advising user to narrow the period filter or use `GET /user/me/export` JSON archive for full raw history.
3. **Period Filter & Controls Card (`AfabCard`):**
   - `Period` dropdown/sheet (`9` `PERIOD_PRESETS`: `all`, `this_month`, `last_month`, `this_quarter`, `this_year`, `last_year`, `last_30_days`, `last_90_days`, `custom`) + active date range pill.
   - `Reporting Currency` selector (`USD`, `EUR`, `SAR`, `AED`, `TND`, `GBP`, `CAD`, `KWD` + `business.currency`).
   - Conditional `Start Date` / `End Date` native date pickers when `period == 'custom'`.
4. **Live Period Counters (2x2 Grid of `AfabStatCard`s):**
   - `Period Transactions` (`filteredTransactions.length`)
   - `Clients Directory` (`filteredCustomers.length`)
   - `Period Invoices` (`filteredInvoices.length`)
   - `Net Flow (Period)` (`MoneyText` formatted in selected currency)
5. **Master Complete Archive Hero Card (`AfabCard` with subtle primary border/tint):**
   - Badge `"Complete Business Archive"`, title, description.
   - 3 stacked/row action buttons:
     - `Download All Excel (.xlsx)` (emerald button)
     - `Download All PDF (.pdf)` (primary button)
     - `Print / Preview PDF` (outlined button → opens native `PdfPreview`)
6. **Modular Dataset Exports (Vertical List on Phone, 2x2 Grid on Tablet):**
   1. **Transactions & Cash Flow** (`filteredTransactions.length` records) → `Excel (.xlsx)` | `PDF (.pdf)`
   2. **Customer CRM & Order Registry** (`filteredCustomers.length` clients) → `Excel (.xlsx)` | `PDF (.pdf)`
   3. **Invoices & Billing Register** (`filteredInvoices.length` invoices) → `Excel (.xlsx)` | `PDF (.pdf)`
   4. **Financial Performance (P&L)** (Active period) → `Backend CSV` | `Official Backend PDF`
7. **Compliance & UTF-8 Security Footer Card (`AfabInsetPanel`):** Shield icon + Arabic/UTF-8 compatibility note.

### Tablet Layout (`>= 600dp` / `>= 840dp`)
- 4-column KPI counter row, full-width Master Archive card with horizontal CTA bar, and 2x2 grid for Modular Dataset cards.

---

## 6. UI Components and Interactive Elements

| Component | Package / Implementation | Details |
|---|---|---|
| `ExportPeriodSheet` | `AfabBottomSheet` | Triggered on any export button tap. Lets user confirm/override `period` (3x3 preset grid), `customStart`/`customEnd`, `Fiscal Matricule (MF)`, `Purpose & Activity`, `Official Business Address`, `Currency`, `Include Business Logo` switch, `Include Wet Signature` switch (`SET-06` active signature), active scope badge, and `"Generate & Share"` CTA. *(Note: Omits Web's raw base64 logo file picker or keeps local-only compressed file path for PDF header without calling `PUT /business/{id}`.)* |
| `MasterExcelGenerator` | `excel_community: ^2.6.2` | Builds 4 sheets (`Overview & KPIs`, `Transactions`, `Customers`, `Invoices`) with UTF-8 strings, MF/address/purpose metadata, and wet signature certification metadata when enabled. Runs in `compute()` isolate for large datasets. |
| `ArabicPdfGenerator` | `pdf: ^3.11.0` + `printing: ^5.15.0` | Bundles `assets/fonts/Cairo-Regular.ttf` & `Cairo-Bold.ttf` so Arabic business names, descriptions, and customer names render with proper shaping & RTL alignment (fixing Web `jsPDF` garbled Arabic!). Embeds business logo & active Wet Signature PNG when toggled on. |
| `NativeShareAndPreview` | `share_plus: ^13.3.1`, `open_filex: ^5.0.0`, `path_provider: ^2.1.5` | Writes `.xlsx`/`.pdf`/`.csv` to temp/cache directory and triggers native share sheet (WhatsApp, Email, Files, Drive) or `PdfPreview` print dialog. |

---

## 7. Data Requirements and API Contracts

### Client-Aggregated Export Endpoints (Mounted on Load & Refresh)
1. **`GET /api/v1/transactions?page={p}&size=100`** (paginated up to `1000` records max; note `DataExportSettings.tsx:93` sent `size=1000`, which backend caps at `100` per page).
2. **`GET /api/v1/customers?page=0&size=100`** (or paginated up to `1000`).
3. **`GET /api/v1/invoices?page=0&size=100`** (or paginated up to `1000`).

### Backend P&L Export Endpoints (Modular Card #4)
4. **`GET /api/v1/reports/export/csv?period={p}&startDate=&endDate=`**
   - Response: `200 text/csv` (UTF-8 BOM); consumes `1` of `export.per_month` plan quota (`403 PLAN_LIMIT_REACHED`).
5. **`GET /api/v1/reports/export/pdf?period={p}&startDate=&endDate=`**
   - Response: `200 application/pdf` (OpenPDF; consumes `1` of `export.per_month`; note backend OpenPDF uses non-Arabic font so Arabic text in backend PDF may render imperfectly compared to client-generated Cairo PDF).
   - Period mapping: When `config.period == "all"`, maps to `"this_year"` (matching `DataExportSettings.tsx:520, 524`).

---

## 8. State Management and Caching

- **`dataExportProvider(businessId)` (`AutoDisposeAsyncNotifier`):**
  - Fetches paginated Transactions, Customers, and Invoices on init (`Future.wait`), tracking `isTruncated` and `totalAvailable` per dataset.
  - Holds filter state (`selectedPeriod`, `customStartDate`, `customEndDate`, `selectedCurrency`).
  - Recomputes `filteredTransactions`, `filteredInvoices`, `filteredCustomers`, and `filteredSummary` using `Decimal` arithmetic (`decimal ^3.2.6` — fixing JS `Number` rounding!).
- **Branding Overrides Cache:** Optional MF / Address / Purpose overrides typed in `ExportPeriodSheet` cache in `SharedPreferences` keyed by `businessId`.

---

## 9. User Actions, Validation, and Error Handling

- **Custom Range Validation:** Ensure `customEndDate >= customStartDate` when `period == 'custom'`.
- **Quota Exceeded (`403 PLAN_LIMIT_REACHED`):** Caught on `/reports/export/{csv,pdf}` and routed to global `PlanLimitBottomSheet` showing used vs monthly limit and upgrade option.
- **Large Dataset Generation:** Excel/PDF generation runs asynchronously with loading state on the active button so UI remains responsive; errors show localized snackbar (`"Failed to generate export file"`).
- **Empty Dataset Export:** If filtered list has 0 records, still generates valid workbook/PDF with `0` rows or warns user clearly before export.

---

## 10. Permissions, Security, and Tenant Isolation

- **Tenant Scoping:** All fetches include `X-Business-Id`; if workspace is `READ_ONLY`, read exports still work for `/transactions`, `/customers`, `/invoices`? *(Wait: check `03_API_CONTRACT_CATALOG.md` — `BusinessAccessGuard` blocks `READ_ONLY` writes, while `GET /transactions` etc. check membership/read access; if `403 BUSINESS_READ_ONLY` occurs on any endpoint, handle gracefully with `BusinessReadOnlySheet`.)*
- **Branding Cache Keying:** Cache MF/address/purpose per `businessId` so Workspace A metadata never leaks into Workspace B exports.
- **Temp Export Files:** Store generated `.xlsx`/`.pdf`/`.csv` inside app temporary cache directory (`getTemporaryDirectory()`) for `share_plus` handoff and purge stale temp exports periodically.

---

## 11. Localization (EN/AR) and RTL Behavior

- Uses `settings.dataExport.*` ARB keys plus localized `PERIOD_PRESETS` (`all`..`custom`) and `ExportPeriodSheet` strings.
- **Arabic PDF Support (Major Mobile Upgrade):** Client-side PDFs (`Master PDF`, `Transactions PDF`, `Customers PDF`, `Invoices PDF`, `Print Preview`) embed **Cairo TTF** (`Cairo-Regular`, `Cairo-Bold`) and set `pw.TextDirection.rtl` for Arabic UI/content while keeping amounts/codes LTR (`tabularFigures`).
- **Excel UTF-8:** `excel_community` writes UTF-8 shared strings natively so Arabic labels render cleanly in Microsoft Excel and Apple Numbers.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Responsive:** Period/Currency dropdowns wrap cleanly on `< 360dp`; KPI counters render 2x2 on phones and 4-across on tablets; `MoneyText` scales down cleanly with `FittedBox` so large period net flows never clip.
- **Loading / Error:** `CircularProgressIndicator` inside KPI counters while initial fetch runs; retry button if initial fetch fails.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **1000-Row Cap & Pagination Warning:** When backend `totalElements > fetchedRows` (or `>= 1000`), screen fetches cleanly in `size=100` pages and displays the truncation warning banner.
2. **Master `.xlsx` Generation & Share:** Tapping `Download All Excel` -> Confirm generates a 4-sheet `.xlsx` file with UTF-8 Arabic support and opens `share_plus`.
3. **Arabic-Safe `.pdf` Generation:** Generating Master PDF in Arabic mode renders Arabic headers/company name cleanly using bundled Cairo TTF without missing-glyph boxes (`□`).
4. **Wet Signature Stamping:** With `SET-06` active signature enabled and `includeSignature = true`, Master PDF embeds the transparent signature PNG + signatory name/title.
5. **Backend Report Quota (`403`):** Tapping Official Backend PDF when monthly export quota is exhausted opens `PlanLimitBottomSheet`.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Packages** | `excel_community: ^2.6.2`, `pdf: ^3.11.0`, `printing: ^5.15.0`, `share_plus: ^13.3.1`, `open_filex: ^5.0.0`, `path_provider: ^2.1.5`, `decimal: ^3.2.6` | All verified in `06_FLUTTER_ARCHITECTURE.md`. |
| **Asset Dependency** | Bundled `assets/fonts/Cairo-Regular.ttf` and `Cairo-Bold.ttf` required for Arabic PDF rendering. | Track under `P0-01` / `P0-04` asset setup. |
| **Risk: Backend OpenPDF Arabic Glyphs** | Modular Card #4 `GET /reports/export/pdf` uses backend OpenPDF (`Helvetica`), which strips/garbles Arabic characters. | Warn Arabic users subtly on backend PDF option and recommend client-generated Master/Modular PDFs for Arabic documents (`13_RISKS_AND_TECHNICAL_DECISIONS.md` §2.13). |
| **Risk: Multi-Currency Unconverted Totals** | Period net flow sums raw `tx.amount` across mixed currencies if business currency changed historically. | Note limitation clearly next to currency selector (`DataExportSettings.tsx` parity). |
