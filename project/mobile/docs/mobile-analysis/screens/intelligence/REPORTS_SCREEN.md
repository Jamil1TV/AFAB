# INT-03 — Financial Reports & Analytics Screen Specification

> **Verified Sources:**
> - Web Page: `Web/project/frontend/app/[locale]/(dashboard)/dashboard/reports/page.tsx`
> - Web API: `Web/project/frontend/lib/api/reports.ts`, `Web/project/frontend/lib/api/subscription.ts`
> - Backend: `ReportController.java`, `ReportService.java`, `CsvReportExporter.java`, `PdfReportExporter.java`, `ProfitAndLossReportDTO.java`, `CashFlowReportDTO.java`, `ComparisonReportDTO.java`
> - Mobile Core Docs: `03_API_CONTRACT_CATALOG.md`, `07_DESIGN_SYSTEM.md`, `08_LOCALIZATION_AND_RTL.md`, `13_RISKS_AND_TECHNICAL_DECISIONS.md`

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `INT-03` |
| **Screen Name** | `ReportsScreen` |
| **Feature Module** | `lib/features/reports/` |
| **Route Path** | `/reports` (`AppRoutes.reports`) |
| **Navigation Location** | Phone: `MoreHubScreen` → *Intelligence & FX* → *Financial Reports* (`Tab 4` stack); Tablet: Primary `NavigationRail` → *Reports* |
| **Presentation Style** | Scrollable analytics screen with 3 report tabs (`P&L`, `Cash Flow`, `Comparison`), period/date controls, quota badge, Copilot trigger, and native export actions |
| **Related Flows** | `GlobalCopilotSheet`, `PlansAndSubscriptionScreen` (`PLAN-01`), `PlanLimitSheet` |

---

## 2. Purpose and Web Parity Status

- **Purpose:** Delivers cash-basis financial statements—Profit & Loss (`P&L`), Cash Flow (`6-month trend`), and Period-over-Period Comparison—along with monthly export quota tracking, AI Copilot `"Explain Report"` analysis, and RFC 4180 CSV / branded PDF statement downloads.
- **Web Parity Status:** **Implemented but Incomplete** — Mobile delivers full parity while resolving **4 confirmed Web gaps and backend caveats**:
  1. **Fixes Hardcoded `comparisonPeriod=last_month` (`reports/page.tsx:101`):** On Web, the Comparison tab always passes `"last_month"` as `comparisonPeriod` and displays generic `"vs previous:"` copy. Mobile adds a second selector (`Compare Against`: `this_month`, `last_month`, `this_quarter`, `this_year`, `last_year`) and renders the backend's `primaryPeriodLabel` and `comparisonPeriodLabel`.
  2. **Exposes Pro Custom Date Range (`startDate` & `endDate`):** Backend `ReportService.validateReportLevel()` supports `period=custom&startDate=YYYY-MM-DD&endDate=YYYY-MM-DD` for Pro (`reports.level == "custom"`), and `this_year`/`last_year` for Plus/Pro (`reports.level != "basic"`), yet Web's `<select>` omits `"custom"` completely. Mobile adds `"Custom Range"` to P&L & Cash Flow period selectors (gated cleanly with a Pro badge/`PlanLimitSheet` for Free/Plus users).
  3. **Adds Native File Preview & Share Sheet:** Instead of silent browser blob download, Mobile saves CSV/PDF to temporary storage (`path_provider`), opens native preview (`open_filex` / `printing`), and offers OS Share Sheet (`share_plus`).
  4. **Surfaces Honest Export Scope & Arabic PDF Caveats:**
     - Backend `/reports/export/csv` and `/reports/export/pdf` always generate the **Profit & Loss** report for the selected `period`/`startDate`/`endDate` (`ReportService.java:195, 214`), even if the user is viewing Cash Flow or Comparison. Mobile labels export buttons clearly (e.g., *"Export P&L CSV"* / *"Download P&L PDF"* or shows a concise note on tabs 2 & 3).
     - Backend `PdfReportExporter.java:37-42` uses `FontFactory.HELVETICA` without an embedded Arabic TTF font, so Arabic business/category names render blank or garbled in server-generated PDFs (`13_RISKS_AND_TECHNICAL_DECISIONS.md` #13). Mobile warns Arabic users before/after server PDF export (and offers local Arabic-capable PDF rendering via `pdf` + bundled `Cairo.ttf` or UTF-8 BOM CSV export which opens cleanly in Excel).

---

## 3. Navigation, Entry Points, and Deep Links

- **Entry Points:**
  - `MoreHubScreen` → *Intelligence & FX* → *Financial Reports*.
  - Tablet `NavigationRail` → *Reports*.
  - `DataExportSettingsScreen` cross-link ("Financial Statements").
- **Outbound Navigation:**
  - **Explain Report** button → opens `GlobalCopilotSheet` with `autoSend: true`, `prompt`, and `screenContext` (`{ page: "reports", tab, period, comparisonPeriod?, startDate?, endDate? }`).
  - **Upgrade Plan Now** button (on `PLAN_LIMIT_REACHED` gated state or export quota `403`) → pushes `PlansAndSubscriptionScreen` (`PLAN-01`).
- **Deep Link:** `afab://reports` or `https://<domain>/{locale}/dashboard/reports`.

---

## 4. Layout and Visual Hierarchy

1. **Top Action & Quota Header:**
   - **Export Quota Pill:** Visible on ALL screen widths (fixing Web `hidden lg:flex` which hides quota on phones!): `Sparkles` icon + `"Monthly Exports: {used} / {limit}"` (or `"Unlimited"` when `limit == -1`).
   - **Action Row:**
     - **Explain Report** (`AfabButton.secondary` with `primary` `Sparkles` icon).
     - **Export CSV** (`AfabButton.secondary` with `Download` icon, disabled if `isExporting || isPlanGated`).
     - **Export PDF** (`AfabButton.primary` with `Download` icon, disabled if `isExporting || isPlanGated`).
   - *Arabic Locale Notice Banner (shown only when `locale == 'ar'`):* Compact info strip noting server PDF uses Latin fonts (use CSV or local Arabic PDF viewer for Arabic category names).
2. **Tabs & Period Controls (`afab-toolbar`):**
   - **3-Tab `AfabSegmentedBar`:**
     1. `Profit & Loss (P&L)` (`pnl`)
     2. `Cash Flow` (`cashflow`)
     3. `Period Comparison` (`comparison`)
   - **Period Controls:**
     - On `pnl` / `cashflow`: `Period` dropdown (`This Month`, `Last Month`, `This Quarter`, `This Year` [Plus+], `Last Year` [Plus+], `Custom Range` [Pro]). When `Custom Range` is selected, shows interactive date-range chip (`YYYY-MM-DD → YYYY-MM-DD`) opening native `showDateRangePicker`.
     - On `comparison`: **Two** dropdowns (`Primary Period` & `Compare Against`, presets `This Month`, `Last Month`, `This Quarter`, `This Year`, `Last Year` — no `Custom Range` since `GET /reports/comparison` has no `startDate`/`endDate` params).
3. **Body Content (Tab-Specific):**
   - **Gated State (`planGatedMessage != null`):** Centered `AfabCard` with `Lock` icon tile, `"Advanced Report Requires Upgrade"`, server `message`, and `"Upgrade Plan Now"` CTA (`AfabButton.premium`).
   - **Tab 1 — Profit & Loss (`pnl`):**
     - **4 KPI Cards (`AfabKpiCard`):**
       1. `Total Revenue` (value + `"Cash received"`/`0.0%` + sparkline from `revenueBreakdown` amounts or synthetic 3-point ramp if empty breakdown).
       2. `Total Expenses` (value + `"Cash spent"`/`0.0%` + sparkline).
       3. `Net Operating Income` (value + `{marginPct}%` badge, positive/negative color).
       4. `Net Profit Margin` (`{marginPct}%` + `"Positive margin"` / `"Operating deficit"`).
     - **Revenue by Category (`AfabCard`):** Header with total revenue + list of `CategoryShare` rows (`categoryName`, `MoneyText(amount)`, `percentage%`, emerald horizontal progress bar) or `AfabEmptyState`.
     - **Expenses by Category (`AfabCard`):** Header with total expenses + list of `CategoryShare` rows (`categoryName`, `MoneyText(amount)`, `percentage%`, `primary` horizontal progress bar) or `AfabEmptyState`.
   - **Tab 2 — Cash Flow (`cashflow`):**
     - **3 KPI Cards (`AfabKpiCard`):** `Total Cash Inflow`, `Total Cash Outflow`, `Net Cash Change` (sparklines mapped from `monthlyTrend`).
     - **6-Month Cash Flow Trend (`AfabCard`):** Legend (`Inflow` emerald vs `Outflow` red) + grouped `fl_chart` `BarChart` over `monthlyTrend` (`YYYY-MM` X-axis, interactive touch tooltip showing `Inflow`, `Outflow`, `Net`). Includes subtle caption clarifying trend always shows trailing 6 months.
   - **Tab 3 — Period Comparison (`comparison`):**
     - **Comparative Financial Variance (`AfabCard`):** Period header (`{primaryPeriodLabel} vs {comparisonPeriodLabel}`) + 3 `AfabInsetPanel` variance cards:
       1. `Revenue Growth`: `primaryRevenue`, delta `%` badge (`>= 0` green, `< 0` red), absolute diff & `{comparisonPeriodLabel}: {comparisonRevenue}`.
       2. `Expense Change`: `primaryExpenses`, delta `%` badge (`<= 0` green, `> 0` red — lower expenses are favorable), absolute diff & `{comparisonPeriodLabel}: {comparisonExpenses}`.
       3. `Net Income Change`: `primaryNetIncome`, delta `%` badge (`>= 0` green, `< 0` red), absolute diff & `{comparisonPeriodLabel}: {comparisonNetIncome}`.

---

## 5. UI Components and Design System Mapping

| UI Element | Shared / Feature Widget | Design Token & Styling (`07_DESIGN_SYSTEM.md`) |
|---|---|---|
| Quota Badge | `AfabInsetPanel` compact chip | `surfaceInset`, `primary` `Sparkles` icon, tabular `used / limit` |
| Report KPIs | `AfabKpiCard` | `40x40dp` icon tile, `MoneyText`, `fl_chart` sparkline, semantic delta badge |
| Category Bars | `LinearProgressIndicator` / custom rounded track | `8dp` height, `borderRadius: 999`, Revenue `#10B981`, Expenses `primary` |
| 6-Month Bar Chart | `fl_chart` `BarChart` | Grouped rods (`6dp` top radius), Inflow `#10B981`/`#34D399`, Outflow `#EF4444`, dashed horizontal gridlines only, dark tooltip `0xE60C101C` |
| Comparison Cards | `AfabInsetPanel` | `surfaceInset`, `AfabStatusBadge`, `MoneyText` |
| Export Feedback Sheet | `AfabBottomSheet` / OS Share Sheet | Preview file (`open_filex`) or Share (`share_plus`) |

---

## 6. State Management and Data Flow

- **Providers (`lib/features/reports/presentation/providers/reports_providers.dart`):**
  - `reportsFilterProvider` (`Notifier<ReportsFilterState>`): Holds `activeTab` (`pnl | cashflow | comparison`), `period` (default `this_month`), `comparisonPeriod` (default `last_month`), `customStart` (`DateTime?`), `customEnd` (`DateTime?`).
  - `reportsDataProvider` (`AsyncNotifier<ReportsViewState>`): Watches `reportsFilterProvider` and `activeBusinessProvider`. Fetches the matching endpoint (`getProfitAndLoss`, `getCashFlow`, or `getComparison`), handling `PlanLimitReachedFailure` (`403`) separately into `planGatedFailure` state.
  - `subscriptionQuotaProvider` (shared from `plans` / `core`): Supplies `entitlements["export.per_month"]`, `usage["export.per_month"]`, and `entitlements["reports.level"]` (`"basic"` | `"advanced"` | `"custom"`). Invalidated immediately after any successful CSV or PDF export.
  - `reportExportControllerProvider` (`Notifier<ExportProgressState>`): Tracks `isExportingCsv`, `isExportingPdf`, downloads binary bytes via Dio (`ResponseType.bytes`), writes file to `getTemporaryDirectory()`, opens post-download action sheet (`Open` / `Share`), and catches `403 PLAN_LIMIT_REACHED` to trigger `PlanLimitSheet`.

---

## 7. API Contracts and DTO Mapping

| Endpoint | Query Params | Response | Entitlement / Access Gate |
|---|---|---|---|
| `GET /api/v1/reports/profit-loss` | `period`, optional `startDate`, `endDate` (`YYYY-MM-DD`) | `ProfitAndLossReportDto`: `{ period, startDate, endDate, currency, totalRevenue, totalExpenses, grossProfit, netOperatingIncome, profitMarginPct, revenueBreakdown: List<CategoryShareDto>, expenseBreakdown: List<CategoryShareDto> }` | `reports.level`: `basic` blocks `this_year`/`last_year` (`403`, `upgradeTo: plus`) and `custom` (`403`, `upgradeTo: pro`) |
| `GET /api/v1/reports/cash-flow` | `period`, optional `startDate`, `endDate` | `CashFlowReportDto`: `{ period, startDate, endDate, currency, cashInflow, cashOutflow, netCashChange, monthlyTrend: List<MonthlyCashFlowDto> }` | Same `reports.level` gate as P&L |
| `GET /api/v1/reports/comparison` | `primaryPeriod`, `comparisonPeriod` | `ComparisonReportDto`: `{ currency, primaryPeriodLabel, primaryRevenue, primaryExpenses, primaryNetIncome, comparisonPeriodLabel, comparisonRevenue, comparisonExpenses, comparisonNetIncome, revenueDifference, revenueDifferencePct, expensesDifference, expensesDifferencePct, netIncomeDifference, netIncomeDifferencePct }` | Requires `reports.level != "basic"` (`403`, `upgradeTo: plus`) |
| `GET /api/v1/reports/export/csv` | `period`, optional `startDate`, `endDate` | `200 text/csv; charset=UTF-8` (UTF-8 BOM + P&L summary + categories + line items) | Consumes `1` unit of `export.per_month` (`5` Free, `15` Plus, `-1` Unlimited Pro); `403 PLAN_LIMIT_REACHED` if exhausted |
| `GET /api/v1/reports/export/pdf` | `period`, optional `startDate`, `endDate` | `200 application/pdf` (OpenPDF P&L statement) | Consumes `1` unit of `export.per_month`; `403 PLAN_LIMIT_REACHED` if exhausted |

- **`CategoryShareDto`:** `{ categoryName: String, @DecimalConverter amount: Decimal, percentage: double, transactionCount: int }`.
- **`MonthlyCashFlowDto`:** `{ month: String ("YYYY-MM"), @DecimalConverter inflow: Decimal, @DecimalConverter outflow: Decimal, @DecimalConverter net: Decimal }`.

---

## 8. Form Fields, Validation, and Business Rules

1. **Custom Date Range (`startDate`, `endDate`):**
   - Required together when `period == "custom"`.
   - `startDate <= endDate`, serialized as ISO `YYYY-MM-DD`.
   - Pre-flight check: if `reports.level != "custom"` (i.e., user is on Free or Plus), selecting `"Custom Range"` opens `PlanLimitSheet` targeting `"pro"` (backend also enforces `403` authoritatively).
2. **Yearly & Comparison Gates:**
   - `this_year`, `last_year`, and `Period Comparison` tab require `reports.level != "basic"` (Plus or Pro).
3. **Export Quota Enforcement:**
   - Backend decrements/consumes `export.per_month` inside `exportCsv` and `exportPdf` (`@Transactional`, `ReportService.java:192, 211`).
   - Disable export buttons if `planGatedMessage != null`; if `exportUsed >= exportLimit` (when `exportLimit != -1`), tapping Export triggers `PlanLimitSheet` or shows backend `403` upgrade prompt.
   - Note: `ReportController` calls `getProfitAndLoss` / `getCashFlow` via `CurrentBusinessService.getCurrentBusiness` (allows viewing reports even if active business guard behavior changes, though `X-Business-Id` should still be sent via `TenantInterceptor`).

---

## 9. User Interactions and Edge Cases

- **Explain Report Copilot Action:** Opens `GlobalCopilotSheet` pre-populated with `prompt: "Analyze my {TAB} financial report for period '{periodLabel}' and explain key changes, anomalies, and recommendations."` and `autoSend: true`.
- **CSV/PDF Download Completion:** After bytes download and save to `AFAB-report-{period}.csv` or `AFAB-statement-{period}.pdf` (honoring `Content-Disposition` filename if present), immediately refresh `subscriptionQuotaProvider` so the `Monthly Exports` counter increments in real time, then present `"Open File"` (`open_filex`) and `"Share"` (`share_plus`) actions.
- **Same Period Selected in Comparison:** If user picks `primaryPeriod == comparisonPeriod`, allow request (returns `0.0%` variance) or show subtle hint `"Comparing identical periods"`.
- **Zero Revenue Margin:** Backend returns `profitMarginPct = 0.0` when `revenue == 0` (`ReportService.java:63`); UI renders `0.0%` cleanly without `NaN`/`Infinity`.

---

## 10. Loading, Empty, Error, and Offline States

- **Loading:** `AfabLoader` (`"Compiling financial statements..."`) while fetching active tab data.
- **Plan Gated (`403 PLAN_LIMIT_REACHED`):** Full inline upgrade card (`Lock` icon, exact server message, `"Upgrade Plan Now"` CTA → `PLAN-01`).
- **Empty Breakdown / Zero Data:** Revenue & Expense breakdown panels render `AfabEmptyState` (`"No income recorded for this period"`, `"No expenses recorded for this period"`). Cash Flow chart with all-zero months still renders axes/baseline cleanly with `0` bars and `"No cash flow activity in the last 6 months"` caption.
- **Network / Server Error:** `AfabEmptyState` with error message + `"Retry"` button; export failures show `AfabToast.error`.
- **Offline State:** Shows `OfflineBanner`; Export CSV/PDF and Explain Report disabled until online (cached last-viewed report remains readable in memory if already loaded).

---

## 11. Localization (EN/AR) and RTL Behavior

- **Translation Keys:** Web `reports/page.tsx` currently uses inline `isAr ? ... : ...` ternaries for all labels. Mobile extracts 100% of labels into `app_en.arb` and `app_ar.arb` (`reportsTitle`, `reportsSubtitle`, `reportsMonthlyExports`, `reportsExplainReport`, `reportsExportCsv`, `reportsExportPdf`, `reportsTabPnl`, `reportsTabCashFlow`, `reportsTabComparison`, `reportsPeriodThisMonth`, etc.).
- **RTL & BiDi:**
  - All monetary amounts (`MoneyText`), percentages (`+12.4%`, `-5.2%`), and ISO date ranges (`2026-01-01 → 2026-01-31`) wrap in `Directionality(textDirection: TextDirection.ltr)` with `tabularFigures`.
  - Grouped Cash Flow `BarChart` X-axis (`monthlyTrend`) flows **left-to-right chronologically** in both EN and AR (`08_LOCALIZATION_AND_RTL.md` §3.5).
  - Directional icons (`ChevronRight` on Upgrade CTA) set `matchTextDirection: true`.
- **Arabic PDF Warning:** Display localized warning in `ar` locale explaining that server-generated PDFs currently render Latin characters reliably while Arabic names may require UTF-8 CSV export (Excel-compatible BOM) or future backend Arabic TTF support.

---

## 12. Responsive and Tablet Adaptation

- **Phone (`< 600dp`):**
  - Export quota badge sits cleanly at top of screen above the 3-button action wrap (`Explain`, `CSV`, `PDF`).
  - `AfabSegmentedBar` scrolls horizontally if needed (`< 360dp`); Period dropdown(s) sit full-width below tabs.
  - KPIs render as `2-column` grid (`1-column` on `< 360dp`).
  - Revenue Breakdown and Expense Breakdown stack vertically; Comparison's 3 variance cards stack vertically.
  - `BarChart` height `220dp`, X-axis labels rotated/abbreviated (`MM/YY` or short month) on `< 380dp`.
- **Tablet (`>= 600dp` / `>= 840dp`):**
  - Action buttons & quota badge align horizontally in the top `PageHeader`.
  - P&L KPIs render as `4-column` row; Category breakdowns render side-by-side (`2-column` grid).
  - Cash Flow KPIs and Comparison variance cards render as `3-column` rows; `BarChart` height `280–320dp`.

---

## 13. Acceptance Criteria and Test Scenarios

1. **All 3 Tabs & Dynamic Comparison:** Switching between `P&L`, `Cash Flow`, and `Period Comparison` fetches the corresponding API; changing `Compare Against` from `last_month` to `this_quarter` calls `GET /reports/comparison?primaryPeriod=...&comparisonPeriod=this_quarter` and displays exact `comparisonPeriodLabel`.
2. **Entitlement Gating (`Free` / `Plus` / `Pro`):** Free user sees inline upgrade card on `Period Comparison` and `this_year`/`last_year`; Pro user can pick `Custom Range` (`startDate`, `endDate`) and load custom P&L & Cash Flow data.
3. **Export Quota & Native Share:** Exporting CSV or PDF consumes 1 quota unit, updates `Monthly Exports: X / Y` badge immediately, saves file with `.csv`/`.pdf` extension, and opens preview/share sheet; hitting quota triggers `403 PLAN_LIMIT_REACHED` upgrade sheet.
4. **Copilot Integration:** Tapping `"Explain Report"` launches `GlobalCopilotSheet` with `autoSend: true` and current report tab/period context.
5. **Arabic & RTL Safety:** Arabic UI shows UTF-8 BOM CSV notice for PDFs, keeps `MoneyText` & `%` badges LTR, and maintains chronological LTR `BarChart` without horizontal overflow.

---

## 14. Dependencies and Risks

- **Dependencies:** `dio`, `fl_chart`, `decimal`, `path_provider`, `open_filex`, `share_plus`, `ReportsRepository`, `SubscriptionRepository`, `GlobalCopilotSheet`.
- **Technical Risks & Mitigations:**
  - *Backend OpenPDF Missing Arabic Font (`PdfReportExporter.java`):* Arabic business names and category names fail to render in `GET /reports/export/pdf`. **Mitigation:** Surface clear notice in Arabic UI recommending CSV export (which includes UTF-8 BOM `0xEF 0xBB 0xBF` for Excel) or client-side Arabic PDF export (`pdf` + `Cairo.ttf` in `DataExportSettingsScreen`), and track backend TTF patch (`13_RISKS_AND_TECHNICAL_DECISIONS.md` #4.3).
  - *Export Endpoints Always Export P&L:* Users on Cash Flow or Comparison tabs might expect Cash Flow PDF. **Mitigation:** Label export buttons explicitly (`"Export P&L CSV"` / `"Export P&L PDF"`) or show a tooltip clarifying statement format.
  - *Cash Flow `monthlyTrend` Ignores `period`:* `ReportService.java:108` always computes trailing 6 months regardless of `period`, while KPI cards (`cashInflow`, `cashOutflow`, `netCashChange`) respect `period`. **Mitigation:** Clearly title the chart *"6-Month Cash Flow Trend (Trailing 6 Months)"* separately from the period-filtered KPI cards.
