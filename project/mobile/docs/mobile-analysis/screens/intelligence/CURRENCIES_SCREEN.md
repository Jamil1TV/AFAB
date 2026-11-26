# INT-01 — Currencies & FX Markets Screen Specification

> **Verified Sources:**
> - Web Page: `Web/project/frontend/app/[locale]/(dashboard)/dashboard/currencies/page.tsx`
> - Web Components: `LiveMarketTicker.tsx`, `FeaturedPairCard.tsx`, `FxTrajectoryChart.tsx`, `BinanceLiveChart.tsx`, `FxConverterWidget.tsx`, `BusinessPortfolioImpactCard.tsx`, `FxInvoiceRiskSimulator.tsx`, `FxRateAlerts.tsx`
> - Web API & Translations: `Web/project/frontend/lib/api/currencies.ts`, `messages/en/currencies.json`, `messages/ar/currencies.json`
> - Backend: `CurrencyController.java`, `ExchangeRateService.java`
> - Mobile Core Docs: `03_API_CONTRACT_CATALOG.md`, `07_DESIGN_SYSTEM.md`, `08_LOCALIZATION_AND_RTL.md`, `13_RISKS_AND_TECHNICAL_DECISIONS.md`

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `INT-01` |
| **Screen Name** | `CurrenciesScreen` |
| **Feature Module** | `lib/features/currencies/` |
| **Route Path** | `/currencies` (`AppRoutes.currencies`) |
| **Navigation Location** | Phone: `MoreHubScreen` → *Intelligence & FX* → *Currencies & FX Markets* (`Tab 4` stack); Tablet: Primary `NavigationRail` → *Currencies* |
| **Presentation Style** | Full-screen scrollable page with persistent top header controls, live ticker strip, and 5-tab segmented workspace |
| **Related Sheets** | `INT-02` (`CurrencyMigrationSheet`), `GlobalCopilotSheet` |

---

## 2. Purpose and Web Parity Status

- **Purpose:** Provides live mid-market FX monitoring, two-way currency conversion, multi-currency business portfolio valuation, historical rate trajectory inspection, simulated 1-second tick visualization, invoice FX sensitivity simulation, local target-rate alerts, and a 16-currency rate directory—plus an entry point to migrate the active business's base accounting currency (`INT-02`).
- **Web Parity Status:** **Implemented but Incomplete** — Mobile achieves 100% functional coverage while fixing **4 confirmed Web defects** and applying **ADR-06 (Honest Labeling)**:
  1. **Fixes `viewBaseCurrency` Reset Bug (`currencies/page.tsx:132-185`):** On Web, the `useEffect` depending on `[viewBaseCurrency]` re-fetches `DashboardService.getSummary()` and unconditionally calls `setViewBaseCurrency(summary.currency)`, snapping the "View:" currency back to the business base currency immediately after the user changes it. Mobile separates `businessContext` loading from `viewBaseCurrency` selection.
  2. **Honest Labeling of Synthetic Data (ADR-06):**
     - Web's `BinanceLiveChart.tsx` claims `"Live Binance WebStream"` / `"Binance Live (1s Ticks)"` and `"Orderbook Synced"`, while 100% of ticks, candles, volumes, and spread (`0.04%`) are deterministic client-side `Math.sin` oscillations anchored to `baseRate`. Mobile renames this tab and chart badge to **"Simulated Live Tick"** (`"محاكاة اللحظات (1ث)"`) with a clear info tooltip explaining it is a client-side micro-tick simulation anchored to the live mid-market spot rate.
     - `ExchangeRateService.getMarketPairs()` computes synthetic `change24h` (`-0.85%` to `+0.95%`), `high24h`, `low24h`, and 7-point `sparkline`. `ExchangeRateService.getHistoricalRates()` generates a synthetic cyclical curve—and has a backend bug where `1Y` (`pointsCount = 52`) loops `today.minusDays(i)` (52 **days** instead of 52 weeks). Mobile renders the backend points accurately while displaying a subtle `"Simulated Trend"` caption and avoiding misleading `"Real-time Interbank"` claims where synthetic data is shown.
     - `FxRateAlerts` persists only in browser `localStorage` (`afab_fx_rate_alerts`). Mobile stores alerts in `SharedPreferences` and explicitly labels them **"Device-Local Alerts (Evaluated on Refresh)"**.
  3. **Fixes 16-Currency Coverage Gaps:** Web's `ALL_CURRENCIES` has 16 currencies (`USD, EUR, TND, QAR, GBP, AED, SAR, CAD, JPY, CHF, KWD, MAD, TRY, EGP, AUD, CNY`), but `FxConverterWidget` only lists 13, `FxInvoiceRiskSimulator` only lists 7, `ExchangeRateService.POPULAR_CURRENCIES` only returns 11 targets, and the Directory table falls back to hardcoded constants (`0.92`, `2.99`, `0.79`, `1.15`) for missing pairs. Mobile exposes all **16** currencies consistently across Converter, Risk Simulator, and Directory, computing missing cross-rates via `GET /api/v1/currencies/convert` or USD cross-derivation instead of hardcoded placeholders.
  4. **Fixes `CurrencyMigrationModal` Target Selection (`INT-02`):** Web hardcodes `baseCurrency === "USD" ? "EUR" : "USD"` with no picker; Mobile lets the user pick any target currency inside `CurrencyMigrationSheet`.

---

## 3. Navigation, Entry Points, and Deep Links

- **Entry Points:**
  - `MoreHubScreen` → *Intelligence & FX* → *Currencies & FX Markets*.
  - Tablet `NavigationRail` → *Currencies*.
  - `DashboardScreen` or `AddEditTransactionScreen` optional deep-link action ("View FX Markets").
- **Outbound Navigation:**
  - Tapping **Base: `{baseCurrency}`** button in header → opens `CurrencyMigrationSheet` (`INT-02`).
  - Tapping **Convert** on any row in the *Directory* tab → sets converter `(from: viewBaseCurrency, to: row.code)`, selects/creates `selectedPair`, and switches back to *Markets* tab scrolled to the converter.
  - AppBar **Ask Copilot (`Sparkles`)** → opens `GlobalCopilotSheet` with `screenContext: { page: "currencies", tab: activeTab, baseCurrency, viewBaseCurrency, selectedPair: selectedPair?.symbol }`.
- **Deep Link:** `afab://currencies` or `https://<domain>/{locale}/dashboard/currencies` (supports optional `?tab=markets|simulated_tick|risk|alerts|directory`).

---

## 4. Layout and Visual Hierarchy

1. **Shell AppBar:** Standard `ShellAppBar` (Business Switcher pill, Ask Copilot icon, Notifications bell) + page title *"Currencies & FX Markets"* (`PageHeader` equivalent).
2. **Status & Controls Strip (Wrap/Row below title):**
   - **Feed Status Pill:** Green dot + `"Live Rates Active"` + `• HH:mm:ss` timestamp (or amber `"Feed Unavailable"` when `ratesError != null`, noting source `open.er-api.com`).
   - **View Base Selector (`AfabSelectField` compact chip):** Globe icon + `"View:"` + dropdown of all 16 currencies (`viewBaseCurrency`).
   - **Base Currency Migration CTA (`AfabButton.soft`):** Wallet icon + `"Base: {baseCurrency}"` → opens `INT-02`.
   - **Refresh Icon Button:** Triggers manual reload (`isRefreshing` spin state).
3. **Global Ticker Strip (`LiveMarketTicker`):**
   - Filter chips: `All Pairs`, `Majors`, `MENA / Gulf`, `Asia-Pac`.
   - Horizontally scrollable pill strip (`Pair Symbol`, `Rate`, `24h %`). Tapping any pill selects `selectedPair`.
4. **5-Tab `AfabSegmentedBar` (horizontally scrollable on phones):**
   1. `Markets` (`markets`)
   2. `Simulated Tick` (`simulated_tick`)
   3. `Risk Simulator` (`risk`)
   4. `Local Alerts` (`alerts`)
   5. `Directory` (`directory`)
5. **Tab Body:**
   - **Tab 1 (`Markets`):**
     1. *Featured Pairs* (`4` spotlight cards: 2x2 grid or horizontal snap carousel on phones, 4-col grid on tablet) with mini `fl_chart` sparkline & 24h Low/High range bar.
     2. *Chart Card* with toggle: `Simulated Tick (1s)` vs `Historical Trajectory (1W/1M/3M/1Y)` + `MA-5` toggle + `Line / Bar` toggle.
     3. *Two-Way Live Converter* card (`From` input + 16-currency picker, animated 180° Swap FAB, `To` editable input + Copy button, `+100/+500/+1k/+5k` quick chips, `25%/50%/75%/Max` portfolio balance chips when `netBalance > 0`, mid-market rate footer).
     4. *Business Portfolio Impact Card* (`netBalance` translated into 4 major settlement currencies from `["USD", "EUR", "TND", "GBP", "AED"]` excluding `baseCurrency`).
   - **Tab 2 (`Simulated Live Tick`):**
     - Quick pair selector pills (first 10 `marketPairs`) + honest `"Simulated 1s Tick (Anchored to Spot)"` badge.
     - Full-width `Candles` / `Wave` chart (`1s / 5s / 1m / 15m` interval, Play/Pause toggle, pulsing spot price marker) + 8-row live simulated trade feed + `Spread: 0.04%` footer.
   - **Tab 3 (`Risk Simulator`):**
     - Inputs: `Foreign Invoice Amount`, `Billing Currency` (all 16 currencies), `Payment Terms` (`Net 15 / 30 / 60 / 90 Days`).
     - Today's Spot Valuation card (`1 {foreign} = {rate} {base}`).
     - 5 FX Sensitivity Scenario cards (`+3.0%`, `+1.5%`, `0.0% Spot`, `-1.5%`, `-3.0%`) showing projected settlement value and gain/loss delta in `baseCurrency`.
   - **Tab 4 (`Local Rate Alerts`):**
     - Honest info banner: *"Alerts are saved locally on this device and checked when market rates refresh."*
     - `New Alert` expandable inline card/sheet (`Pair`, `Condition: Rises above / Drops below`, `Target Rate`, `Save Alert`).
     - Alert list with Active toggle switch, target vs current `% away` badge, triggered highlight if current rate crosses threshold, and Delete button.
   - **Tab 5 (`Directory`):**
     - Search input (`Search currency or symbol...`) + 16-currency list (touch cards on phone `< 600dp`, full 5-column table on tablet `>= 840dp`) with `"Convert"` action button per row.

---

## 5. UI Components and Design System Mapping

| UI Element | Shared / Feature Widget | Design Token & Styling (`07_DESIGN_SYSTEM.md`) |
|---|---|---|
| Page Container | `Scaffold` + `RefreshIndicator` | `AfabColors.background` (`#F8F9FB` light / `#060813` midnight) |
| Ticker Strip & Cards | `AfabCard` | `surface` bg, `1px border`, `baseRadius * 1.33`, `14–16dp` padding |
| Sparklines & Trajectory | `fl_chart` `LineChart` / `BarChart` | Series colors: positive `#10B981`/`#34D399`, negative `#EF4444`, MA-5 `#F59E0B`; dark tooltip `0xE60C101C` |
| Simulated Candlesticks | `CustomPainter` (`SimulatedCandleChart`) | Bullish `#0ECB81`, Bearish `#F6465D`, dashed horizontal guide + right-axis price pill |
| Converter Inputs | `AfabInsetPanel` + `TextFormField` | `surfaceInset`, `tabularFigures`, `Directionality.ltr` on numeric & currency codes |
| Swap Button | `IconButton` + `AnimatedRotation` | `40x40dp` circle, `primary` fill, `0.5` turns (`180°`) on tap |
| Status & Trend Badges | `AfabStatusBadge` | `6dp` radius pill, `10%` semantic tint (`success`/`danger`/`warning`/`primary`) |
| Tab Switcher | `AfabSegmentedBar` | `surfaceInset` container, `primary` active pill |

---

## 6. State Management and Data Flow

- **Providers (`lib/features/currencies/presentation/providers/currencies_providers.dart`):**
  - `viewBaseCurrencyProvider` (`Notifier<String>`): Initialized once from `activeBusinessProvider.currency` (default `"USD"`), **never overwritten** when `viewBaseCurrency` changes unless the user switches active business or completes a currency migration (`INT-02`).
  - `marketRatesProvider` (`FutureProvider<List<CurrencyPair>>`): Watches `viewBaseCurrencyProvider`; calls `CurrencyRepository.getMarketRates(base: viewBaseCurrency)`.
  - `businessPortfolioSummaryProvider` (`FutureProvider<PortfolioFxSummary>`): Watches `activeBusinessProvider`; fetches `DashboardService.getSummary()` to extract `businessName`, `baseCurrency`, and `netBalance` (`kpiData.profit.rawValue ?? kpiData.cashFlow.rawValue ?? 0`).
  - `selectedPairProvider` (`Notifier<CurrencyPair?>`): Defaults to first pair matching `viewBaseCurrency` on initial load; updated on ticker/card/converter/directory selection.
  - `historicalRatesProvider` (`FutureProvider.family`): Keyed by `(from, to, timeframe)` (`1W`, `1M`, `3M`, `1Y`); calls `GET /api/v1/currencies/history`.
  - `converterControllerProvider` (`Notifier<ConverterState>`): Manages `from`, `to`, `sendAmount`, `receiveAmount`, `rate`, `lastEdited` with debounced (`250ms`) `GET /api/v1/currencies/convert` sync and instant `Decimal` optimistic calculation between debounces.
  - `localFxAlertsProvider` (`AsyncNotifier<List<FxRateAlert>>`): Persists JSON list under `SharedPreferences` key `afab_fx_rate_alerts`; evaluates active alerts against newly loaded `marketPairs` and surfaces an in-screen banner/toast if any active alert threshold is met.
  - `simulatedTickControllerProvider` (`Notifier<SimulatedTickState>`): Auto-disposes `Timer.periodic(1s)` when tab leaves `Markets(simulated)` / `Simulated Tick` or app moves to background (`WidgetsBindingObserver` pause).

---

## 7. API Contracts and DTO Mapping

| Endpoint | Auth / Headers | Request Params / Body | Response DTO (`Freezed`) |
|---|---|---|---|
| `GET /api/v1/currencies/rates` | Public (opt `Authorization`, `X-Business-Id`) | `?base={viewBaseCurrency}` | `List<CurrencyPairDto>`: `{ symbol, base, target, @DecimalConverter rate, change24h, @DecimalConverter high24h, @DecimalConverter low24h, sparkline: List<double> }` |
| `GET /api/v1/currencies/history` | Public | `?from={from}&to={to}&timeframe={1W\|1M\|3M\|1Y}` | `List<HistoricalRatePointDto>`: `{ date: String (YYYY-MM-DD), rate: double }` |
| `GET /api/v1/currencies/convert` | Public | `?from={from}&to={to}&amount={Decimal}` | `CurrencyConversionResultDto`: `{ from, to, @DecimalConverter amount, @DecimalConverter exchangeRate, @DecimalConverter convertedAmount }` |
| `GET /api/v1/dashboard/summary` | JWT + `X-Business-Id` (`EDITABLE`) | `?period=month` | Extracts `businessName`, `currency`, `kpiData.profit.rawValue` / `cashFlow.rawValue` |

- **Numeric & Precision Rules:**
  - Exchange rates use `Decimal` (`scale 6` `HALF_UP` matching `ExchangeRateService.java:70`). Display rates at `4` decimals (e.g., `1.0825`), and `MoneyFormatter` minor-unit precision for converted monetary amounts (`3` decimals for `TND`/`KWD`/`BHD`/`OMR`/`JOD`, `0` for `JPY`/`KRW`, `2` default).
  - **Missing Pair Cross-Rate Resolution:** Since `ExchangeRateService.getMarketPairs()` only returns the `10` pairs in `POPULAR_CURRENCIES` (`USD, EUR, TND, GBP, AED, SAR, CAD, JPY, CHF, QAR, KWD`), `MAD`, `TRY`, `EGP`, `AUD`, `CNY` are absent from `/currencies/rates`. Mobile fetches `GET /currencies/convert?from={viewBaseCurrency}&to={code}&amount=1` (batched or lazy per visible item, cached in memory per `viewBaseCurrency`) so Directory and Risk Simulator never show fake hardcoded numbers.

---

## 8. Form Fields, Validation, and Business Rules

1. **Two-Way Converter:**
   - `sendAmount` / `receiveAmount`: `Decimal` >= `0`, regex `^\d*\.?\d{0,6}$`. Empty or `0` yields `"0"` without calling `/convert` unnecessarily.
   - `from` and `to`: Any of the 16 supported currencies; if `from == to`, `rate = 1.0000` short-circuits locally.
2. **Risk Simulator:**
   - `invoiceAmount`: `Decimal` >= `0` (default `10000`).
   - `foreignCurrency`: Any of the 16 supported currencies (default `"USD"`, or `"EUR"` if `baseCurrency == "USD"`).
   - `paymentTermsDays`: Enum `[15, 30, 60, 90]` (default `30`).
3. **Local Rate Alerts (`SharedPreferences`):**
   - `pair`: Selected from available pairs (`BASE/TARGET`) or any custom 16-currency pair.
   - `condition`: `"above"` (`≥`) or `"below"` (`≤`).
   - `targetRate`: Required positive `Decimal` (`> 0`). Inline validation error if `<= 0` or invalid number.
   - `id`: UUID v4; `createdAt`: ISO8601 UTC timestamp.
4. **Simulated Live Tick Guardrails:**
   - Must pause `Timer.periodic` when app lifecycle state is `paused`/`inactive` or when user switches to another tab/screen to prevent battery drain.
   - Must never label simulated ticks as real Binance or interbank orderbook executions.

---

## 9. User Interactions and Edge Cases

- **Pull-to-Refresh:** Refreshes `marketRatesProvider` and `businessPortfolioSummaryProvider`, updating `lastUpdated` timestamp and re-evaluating local FX alerts.
- **Pair Selection Sync:** Tapping a pair in `LiveMarketTicker` or `FeaturedPairCard` updates `selectedPair`, refreshes `historicalRatesProvider` (if Trajectory mode active), resets `SimulatedTick` anchor to `pair.rate`, and updates `FxConverterWidget` `from`/`to`.
- **Two-Way Editing Race Condition:** Typing rapidly in `You Receive` sets `lastEdited = receive` and computes `sendAmount = receive / rate` locally, only syncing `/convert` after `250ms` debounce so cursor position and user input are never overwritten mid-typing.
- **Clipboard Copy:** Tapping Copy in `You Receive` copies `"{receiveAmount} {to}"`, triggers `HapticFeedback.lightImpact()`, and shows check icon for `2s` + `AfabToast`.
- **READ_ONLY Business Edge Case:** If active business is `READ_ONLY` (so `GET /dashboard/summary` returns `403 BUSINESS_READ_ONLY`), catch gracefully: keep `marketPairs` working using `GET /currencies/rates?base=<fallback>`, hide or zero out `BusinessPortfolioImpactCard` with an informational note, and disable the `"Base: {baseCurrency}"` migration trigger.

---

## 10. Loading, Empty, Error, and Offline States

- **Initial Loading:** `AfabLoader` / shimmer placeholders for Ticker Strip, 4 Featured Cards, and Chart container (`240dp`).
- **Chart Loading:** Translucent overlay spinner inside `FxTrajectoryChart` without collapsing container height.
- **API Unavailable (`ratesError != null`):** Amber warning banner (`"Live exchange rates cannot currently be retrieved"`) with Retry CTA. Note: backend `ExchangeRateService` falls back to static `loadFallbackRates()` when `open.er-api.com` is unreachable, so backend usually still returns HTTP `200`; if backend itself is unreachable or offline, display last cached `marketPairs` (if available) with an `"Offline — Cached Rates"` badge, or `AfabEmptyState` with Retry.
- **Directory Empty Search:** `AfabEmptyState` ("No currencies match '{query}'") with Clear Search button.
- **Alerts Empty State:** `AfabEmptyState` (`Bell` icon, `"No target rate alerts created yet"`) with `"New Alert"` CTA.

---

## 11. Localization (EN/AR) and RTL Behavior

- **Translation Keys:** Migrate all `55` keys from `currencies.json` plus localize the hardcoded EN/AR ternaries from `currencies/page.tsx` and subcomponents (`Markets & Converter`, `Simulated Live Tick`, `Invoice Risk Simulator`, `Local Rate Alerts`, `Rates Directory`, `Live Exchange Rates`, disclaimer banners) into `app_en.arb` / `app_ar.arb`.
- **RTL & BiDi Rules (`08_LOCALIZATION_AND_RTL.md`):**
  - Wrap all FX pair symbols (`EUR/USD`), ISO codes (`TND`), exchange rates (`1 EUR = 3.3500 TND`), and `+0.25%` / `-0.18%` badges in `Directionality(textDirection: TextDirection.ltr)` so slashes and signs never flip in Arabic.
  - Keep Western Arabic digits (`0-9`) with `FontFeature.tabularFigures()`.
  - Time-series X-axis on `FxTrajectoryChart` and `SimulatedCandleChart` flows **left-to-right chronologically** in both EN and AR.
  - Directional arrows in `"Analyze Chart →"` / `"← تحليل الرسم البياني"` use `matchTextDirection: true` or localized ARB strings.

---

## 12. Responsive and Tablet Adaptation

- **Compact Phones (`< 600dp`):**
  - Header controls wrap cleanly into 2 compact rows; `AfabSegmentedBar` tabs scroll horizontally with edge fade.
  - Featured Pairs render as a `2x2` compact grid (or horizontal `PageView` on `< 360dp`).
  - Trajectory Chart + Converter stack vertically (`Chart` on top, `Converter` below); Simulated Live Tick stacks `Chart` (`240dp`) above the 8-row `Simulated Trades` panel.
  - Risk Simulator 5 scenario cards render as a `2-col` wrap or horizontal swipe strip.
  - Directory renders as touch cards (`Symbol tile + Name/Code | Rate + Trend badge + Convert button`) — no horizontal-scrolling HTML table on phones.
- **Tablets (`>= 600dp` / `>= 840dp`):**
  - Featured Pairs render in a `4-column` row (`>= 840dp`) or `2x2` (`600–839dp`).
  - `Markets` tab uses a `7:5` two-column split (`Chart` left, `Converter` right).
  - `Simulated Live Tick` tab uses an `8:4` split (`Candles` left, `Trades` panel right).
  - `Risk Simulator` renders inputs in a `3-column` row and 5 scenario cards in a `5-column` row.
  - `Directory` renders a clean 5-column `DataTable` inside `AfabCard`.

---

## 13. Acceptance Criteria and Test Scenarios

1. **View Base Persistence Fix:** Switching `View:` from `USD` to `EUR` calls `GET /currencies/rates?base=EUR`, updates all market pairs, featured cards, and directory rates to `EUR`, and **does NOT reset back to `USD`**.
2. **Honest Labeling:** Simulated Live Tick tab and chart explicitly state `"Simulated 1s Tick"` (never `"Binance WebStream"`); Alerts tab explicitly states `"Device-Local Alerts"`.
3. **Two-Way Converter Accuracy:** Entering `1000` in `From` updates `To` via `/currencies/convert`; editing `To` updates `From` inversely; Swap button rotates `180°` and swaps currencies/amounts without NaN.
4. **16-Currency Coverage:** All 16 currencies appear in Converter, Risk Simulator, and Directory; selecting `MAD` or `TRY` in Directory/Simulator resolves real rates without hardcoded fallback constants.
5. **Local Alerts Persistence:** Creating, pausing, and deleting an alert persists across app restarts via `SharedPreferences`.
6. **Lifecycle & RTL:** Switching app to background pauses the 1s simulation timer; Arabic RTL layout keeps `EUR/USD` and `1.0825` strictly LTR with zero text overflow at `1.25x` text scale.

---

## 14. Dependencies and Risks

- **Dependencies:** `flutter_riverpod`, `fl_chart`, `decimal`, `shared_preferences`, `CurrenciesRepository`, `DashboardRepository`, `CurrencyMigrationSheet` (`INT-02`), `GlobalCopilotSheet`.
- **Technical Risks & Mitigations:**
  - *Backend `1Y` History Bug (`ExchangeRateService.java:158`):* `1Y` returns 52 consecutive days rather than 52 weeks. **Mitigation:** Display the exact `date` strings returned by the backend in tooltips/X-axis so the chart never misrepresents dates.
  - *Backend `POPULAR_CURRENCIES` Subset (`11` vs `16`):* Calling `/currencies/convert` individually for 5 missing directory rows on every base change adds 5 small GET requests. **Mitigation:** Compute missing directory rates lazily when the *Directory* tab is opened, or derive cross-rates from a single cached `USD` base fetch + target conversions, caching per `viewBaseCurrency` for 15 minutes.
  - *Open Exchange Rates Upstream Outage:* `ExchangeRateService` silently falls back to static rates (`loadFallbackRates`) without an HTTP error flag. **Mitigation:** Surface `lastUpdated` timestamp and provide manual Refresh.
