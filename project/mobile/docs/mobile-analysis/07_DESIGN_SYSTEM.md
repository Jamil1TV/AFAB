# 07 — Global Design System (Flutter Translation of AFAB Project UI)

> **Verified Sources:** `Web/project/frontend/DESIGN_SYSTEM.md`, `Web/project/frontend/app/globals.css`, `Web/project/frontend/lib/design-tokens.ts`, `Web/project/frontend/lib/appearance.ts`, `Web/project/frontend/components/ui/afab-loader.tsx`.

---

## 1. Color System

### 1.1 Light & Dark Core Tokens (`AfabColors` `ThemeExtension`)

| Semantic Token | Light Mode Hex | Dark Mode Default (`midnight`) | Dark (`oled`) | Dark (`slate`) | Dark (`charcoal`) |
|---|---|---|---|---|---|
| `background` | `#F8F9FB` | `#060813` | `#000000` | `#090D16` | `#111318` |
| `surface` (card/sheet) | `#FFFFFF` | `#0C101C` | `#0A0A0A` | `#0F172A` | `#181B22` |
| `surfaceInset` (inputs/nested) | `#F9FAFB` | `#080C18` | `#050505` | `#0B1120` | `#13161C` |
| `border` | `#E5E7EB` | `#171F2C` | `#171717` | `#1E293B` | `#232730` |
| `inputBorder` | `#E5E7EB` | `#1F2937` | `#1F2937` | `#334155` | `#2D333F` |
| `textPrimary` | `#111827` | `#F9FAFB` (`#FFFFFF` titles) | `#F9FAFB` | `#F9FAFB` | `#F9FAFB` |
| `textMuted` | `#6B7280` | `#9CA3AF` | `#9CA3AF` | `#9CA3AF` | `#9CA3AF` |
| `primary` (default Violet) | `#8B5CF6` | `#8B5CF6` | `#8B5CF6` | `#8B5CF6` | `#8B5CF6` |
| `primaryHover` / pressed | `#7C3AED` | `#7C3AED` | `#7C3AED` | `#7C3AED` | `#7C3AED` |
| `secondaryBg` | `#F5F3FF` | `#191832` | derived (`-75%`) | derived | derived |
| `secondaryFg` | `#7C3AED` | `#C4B5FD` | derived (`+30%`) | derived | derived |
| `success` (Income / Paid) | `#10B981` | `#34D399` | `#34D399` | `#34D399` | `#34D399` |
| `warning` (Pending / Approaching) | `#F59E0B` | `#FBBF24` | `#FBBF24` | `#FBBF24` | `#FBBF24` |
| `danger` (Expense / Overdue) | `#EF4444` | `#EF4444` (text `#F87171`) | `#EF4444` | `#EF4444` | `#EF4444` |
| `info` (Cashflow / Info) | `#0EA5E9` | `#38BDF8` | `#38BDF8` | `#38BDF8` | `#38BDF8` |

> **Rule:** Never use `slate`/`zinc` greys in light mode; AFAB uses crisp neutral `gray` (`#111827` → `#F9FAFB`) and deep navy dark surfaces. Only **Upgrade/Pro CTAs** (`primary → primaryHover`) and **AI Copilot hero accents** (`#8B5CF6 → #10B981` / AI accent gradient) may use gradients.

---

## 2. Accent Presets & Appearance Customization (`AppearanceSettings`)

All runtime appearance options from `lib/appearance.ts` map cleanly to a Flutter `AppearanceThemeBuilder`:

1. **Theme Mode:** `ThemeMode.system` (default), `ThemeMode.light`, `ThemeMode.dark`.
2. **8 Accent Presets + Custom Hex:**
   - `purple` (`#8B5CF6` / `#7C3AED`, Electric Violet — default)
   - `blue` (`#3B82F6` / `#2563EB`, Ocean Sapphire)
   - `emerald` (`#10B981` / `#059669`, Emerald Wealth)
   - `amber` (`#F59E0B` / `#D97706`, Sunset Amber)
   - `rose` (`#F43F5E` / `#E11D48`, Crimson Ruby)
   - `cyan` (`#06B6D4` / `#0891B2`, Cyber Cyan)
   - `magenta` (`#D946EF` / `#C026D3`, Neon Magenta)
   - `slate` (`#64748B` / `#475569`, Titanium Slate)
   - `custom` (`#RRGGBB` input/wheel): derives `primaryHover (-12%)`, `lightTint (+90%)`, `darkSecondary (-75%)`, `darkSecondaryFg (+30%)`, `glowColor (alpha 0.40)`.
3. **4 Dark Surface Presets:** `midnight` (default), `oled`, `slate`, `charcoal` — exposed natively on mobile (fixing Web's missing UI picker).
4. **3 Corner Rounding Presets (`baseRadius`):**
   - `sm` (Sharp): `8.0 dp` base (`card = 13.3 dp`, `control = 8.0 dp`, `modal = 16.0 dp`)
   - `md` (Balanced, default): `12.0 dp` base (`card = 16.0 dp`, `control = 12.0 dp`, `modal = 24.0 dp`)
   - `lg` (Modern): `16.0 dp` base (`card = 21.3 dp`, `control = 16.0 dp`, `modal = 28.0 dp`)
5. **6 Typography Family Archetypes (`google_fonts`):**
   - `inter`: Body `Inter`, Headings `Poppins` (default)
   - `serif`: `Playfair Display` (EN) + `Amiri` (AR)
   - `mono`: `JetBrains Mono`
   - `geometric`: `Cairo` (AR) + `Montserrat` (EN)
   - `kufi`: `Cinzel` (headings) + `Reem Kufi` (AR)
   - `system`: Platform default (`Roboto` / `SF Pro` / system Arabic)
   - **Mandatory:** Always set `fontFeatures: [FontFeature.tabularFigures()]` on monetary figures, KPIs, and table numbers.
6. **4 Font Scale Multipliers:** `sm` (`0.875x`), `md` (`1.0x`, default), `lg` (`1.125x`), `xl` (`1.25x`) — combined carefully with OS `MediaQuery.textScalerOf(context)` clamped safely (`0.85x..1.45x`) to prevent layout overflow.
7. **Density (`comfortable` vs `compact`):** Compact reduces card padding (`20dp` → `14dp`), list tile vertical spacing, and base scale (`0.9x`); synced to backend `PUT /user/me` (`compactMode`).
8. **Visual Effects:** `enableGlow` (adds subtle `BoxShadow` with `glowColor` on active CTA & Copilot tab) and `smoothTransitions` (respects OS `MediaQuery.disableAnimationsOf(context)`).

---

## 3. Chart Palette & Tokens (`lib/design-tokens.ts`)

- **Series Palette:** `[primary, #0EA5E9 (#38BDF8 dark), #10B981 (#34D399 dark), #F59E0B (#FBBF24 dark), #EC4899 (#F472B6 dark), #6366F1 (#818CF8 dark)]`.
- **Semantic:** Revenue `primary`, Expenses `#0EA5E9`, Positive `#10B981`, Negative `#EF4444`, Neutral `#64748B`.
- **Chart Tooltip Card:** Dark translucent `Color(0xE60C101C)`, `1px` `primary` border, `12dp` radius, white text (`12sp`).
- **Gridlines:** Dashed horizontal lines only (`1dp`, `#E5E7EB` light / `#171F2C` dark), zero vertical axis lines.

---

## 4. Shared AFAB Flutter Component Library (`lib/shared/widgets/`)

| Component | Replaces Web Equivalent | Key Specs |
|---|---|---|
| `AfabCard` | `.afab-card` | `surface` bg, `1px border`, `baseRadius * 1.33` radius, subtle light shadow, `16–20dp` padding (`12–14dp` compact). |
| `AfabInsetPanel` | `.afab-inset` | `surfaceInset` bg, `1px border`, `baseRadius` radius (used for nested breakdown rows & summaries). |
| `AfabKpiCard` | `KpiCard.tsx` | Icon tile (`40x40dp`), title, sparkline (`fl_chart` `LineChart` non-interactive), tabular `MoneyText`, delta badge (`+X.X%` + explicit period label — **never hardcodes "vs last month"**), optional `Ask Copilot` icon button. |
| `AfabStatCard` | `StatCard.tsx` | Compact KPI card without sparkline, optional top `3dp` semantic accent border. |
| `MoneyText` | `formatCurrency()` | Renders formatted `Decimal` with explicit currency code/symbol, tabular figures, semantic color option, auto `FittedBox(scaleDown)` safety for large balances. |
| `AfabButton` | `.afab-btn-{primary,secondary,soft,danger,premium}` | Min height `48dp` (touch accessibility), `baseRadius` corner, inline loading spinner, haptic feedback option. |
| `AfabTextField` / `AfabSelectField` | `.afab-input`, `.afab-select` | `surfaceInset` fill, `1px inputBorder`, `primary` focus ring, inline error text, clear button. |
| `AfabStatusBadge` | `.afab-badge-*` | `6dp` radius pill, `10%` semantic tint fill + crisp semantic foreground text (`11sp` SemiBold). |
| `AfabSegmentedBar` | `.afab-segmented` | Horizontal scrollable or full-width pill tabs (`surfaceInset` container, `primary` active pill). |
| `AfabBottomSheet` | `.afab-modal` / Drawer | Drag handle, sticky header + close button, `isScrollControlled: true`, `SafeArea` + `viewInsets.bottom` keyboard padding. |
| `AfabEmptyState` | `EmptyState.tsx` | Circular icon tile, title, concise description, optional primary CTA button. |
| `AfabLoader` | `afab-loader.tsx` | Custom animated geometric `"A"` monogram with rising fill & orbital ring (auto-simplifies under reduced motion). |
| `AfabToast` | `sonner` | Floating non-blocking Material `SnackBar` / overlay banner with semantic icon & optional Undo/Action button. |
