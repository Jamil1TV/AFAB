# 09 — Responsive & Adaptive Design Specification

> **Device Scope:** Small Android phones (`320–359dp`), standard Android/iOS phones (`360–429dp`), large phones (`430–599dp`), tablets portrait (`600–839dp`), tablets landscape & foldables (`>= 840dp` / `>= 1024dp`).

---

## 1. Breakpoint System (`AfabBreakpoints`)

| Class | Width (`dp`) | Shell Navigation | Grid Columns | Master-Detail | Dialog Presentation |
|---|---|---|---|---|---|
| `compactSmall` | `< 360` | 5-tab `NavigationBar` (compact labels) | 1 col (KPIs 1–2 col wrap) | Push route | Full-screen modal / 95% bottom sheet |
| `compact` | `360 – 599` | 5-tab `NavigationBar` | 2-col KPI grid, 1-col lists/charts | Push route | Full-screen route or draggable bottom sheet |
| `medium` (Tablet Portrait) | `600 – 839` | Collapsed `NavigationRail` (`72dp`) | 2–3 col KPIs, 2-col analytics | Optional split on Settings/AI | Centered dialog (`maxWidth: 560dp`) or side sheet |
| `expanded` (Tablet Landscape) | `>= 840` (`>= 1024` extended rail) | Extended `NavigationRail` (`248dp`) | 4–5 col KPIs, 2:1 analytics (`8+4` / `9+3`) | Two-pane split (`List + Detail`) | Centered dialog (`maxWidth: 640dp`) / side drawer (`440dp`) |

---

## 2. Core Responsiveness Rules (Zero Overflow / Clipping Guarantee)

1. **No Desktop Tables on Phones:**
   - Transactions, Expenses, Revenue, Customers, Invoices, Recurring Schedules, Sessions, and Currencies Directory convert multi-column tables (`afab-table`) into **structured touch cards** on `< 600dp`, preserving 100% of data fields and row actions via tap + swipe/kebab menu.
   - On `>= 840dp` tablets, structured data tables or split master-detail panes are rendered inside horizontal-safe constrained layouts.
2. **Financial Number Safety (`MoneyText`):**
   - Never use `TextOverflow.ellipsis` on KPI amounts or balances (matching AFAB Web finding F16). Use `FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart)` paired with `tabularFigures` so 10-digit balances (`$1,234,567.890`) scale cleanly down instead of truncating.
3. **Charts (`fl_chart`):**
   - Wrap charts in `AspectRatio` or responsive `LayoutBuilder` height (`200–240dp` phone, `280–320dp` tablet).
   - Provide `touchTooltipData` (tap/long-press scrubber on touchscreens instead of mouse hover).
   - Rotate or thin X-axis labels dynamically (`interval`) when width `< 380dp`.
4. **Keyboard & Form Ergonomics:**
   - All forms wrap scrollable bodies inside `SafeArea` + `SingleChildScrollView` + `AnimatedPadding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom))`.
   - Complex multi-field forms (Add/Edit Transaction, Split Transaction, Create/Edit Invoice, Business Profile) open as **full-screen modal pages** on phones with sticky bottom action bars (`Cancel` / `Save`), rather than cramped dialogs.
   - Numeric inputs specify `TextInputType.numberWithOptions(decimal: true)` and `TextInputAction.next` / `done`.
5. **Safe Areas, Notches & System Bars:**
   - Enable edge-to-edge on Android (`SystemUiMode.edgeToEdge`) and respect iOS Dynamic Island / home indicator via `SafeArea` and `MediaQuery.paddingOf(context)`.
   - Bottom sheets and FABs include `viewPadding.bottom` clearance so iOS home bar or Android 3-button nav never overlaps CTAs.
6. **Orientation & Text Scaling:**
   - Support portrait & landscape seamlessly (`LayoutBuilder` reacts to `constraints.maxWidth`, never hardcoding `MediaQuery.size` checks globally where split-screen/multi-window applies).
   - Clamp combined OS + in-app text scale safely and test all screens at `1.25x` and `1.4x` text scale in both EN and AR.
