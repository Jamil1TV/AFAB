# AFAB Design System

> Source of truth: the approved reference pages — **Dashboard, Transactions, Expenses, Revenue, Invoices**.
> Every other screen must look like it was built from the same parts.
> Tokens live in `app/globals.css` (CSS variables + `afab-*` component classes) and `lib/design-tokens.ts` (TS constants for charts).

## 1. Theme tokens

| Role | Light | Dark | Tailwind (token) | Tailwind (literal used by reference pages) |
|---|---|---|---|---|
| Page background | `#f8f9fb` | `#060813` | `bg-background` | layout shell only |
| Card / popover / modal | `#ffffff` | `#0c101c` | `bg-card` | `bg-white dark:bg-[#0c101c]` |
| Inset (inputs, table head, nested panels) | `#f9fafb` | `#080c18` | `bg-surface-inset` | `bg-gray-50/50 dark:bg-[#080c18]` |
| Card border | `#e5e7eb` | `#171f2c` | `border-border` | `border-gray-200 dark:border-gray-800/60` |
| Input border | `#e5e7eb` | `#1f2937` | `border-input` | `border-gray-200 dark:border-gray-800` |
| Primary | `#8b5cf6` | `#8b5cf6` | `bg-primary` | `bg-[#8b5cf6] hover:bg-[#7c3aed]` |
| Heading text | `#111827` | `#ffffff` | `text-foreground` | `text-gray-900 dark:text-white` |
| Body / muted text | `#6b7280` | `#9ca3af` | `text-muted-foreground` | `text-gray-500 dark:text-gray-400` |
| Success / Danger / Warning / Info | emerald-500 / red-500 / amber-500 / sky-500 | 400 shades | `text-success` … | `text-emerald-600 dark:text-emerald-400` … |

Neutral palette is **gray** (not slate/zinc). Accent family is **purple/violet** (`#8b5cf6`, `#7c3aed`, `#a78bfa` for dark-mode text).

## 2. Typography
- Font: Inter everywhere in the app (Poppins `font-heading` is reserved for marketing/auth hero copy).
- Page title: `afab-page-title` → `text-2xl sm:text-3xl font-bold tracking-tight`.
- Page subtitle: `afab-page-subtitle` → `mt-1.5 text-sm text-gray-500 dark:text-gray-400`.
- Card title: `afab-card-title` → `text-lg font-bold`; card subtitle `text-sm text-gray-500`.
- KPI value: `text-xl sm:text-2xl font-bold tracking-tight`.
- Table: `text-xs`, header uppercase `tracking-wider font-semibold text-gray-400`.
- Weights: 500/600/700 only. No `font-black` / `font-extrabold` in the app shell.

## 3. Layout
- Page container: `afab-page` → `mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8`.
- Page header: `<PageHeader title subtitle actions />` (`components/dashboard/PageHeader.tsx`).
- Grids: `gap-4`; KPI row `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4`; analytics `lg:grid-cols-3` (2+1).

## 4. Radius, shadow, spacing
- Cards / panels / toolbars: `rounded-2xl`, `shadow-sm`, padding `p-5` (KPI) or `p-6` (content).
- Controls (buttons, inputs, selects): `rounded-xl`. Icon buttons / pagination: `rounded-lg`. Modals: `rounded-3xl`.
- Hover on KPI cards: `afab-card-hover` (lift 4px + `shadow-lg`).

## 5. Components (classes in `globals.css`, React in `components/dashboard`)
| Need | Use |
|---|---|
| Card | `afab-card` (+ `p-6`) |
| KPI with sparkline | `KpiCard` |
| KPI without series | `StatCard` |
| Filter bar | `afab-toolbar` |
| Inputs / selects / labels | `afab-input`, `afab-select`, `afab-label` |
| Buttons | `afab-btn-primary`, `afab-btn-secondary`, `afab-btn-soft`, `afab-btn-danger`, `afab-icon-btn` |
| Upgrade / premium CTA (only gradient allowed) | `afab-btn-premium` (purple-600 → indigo-600) |
| Tabs / period toggles | `PeriodSelector` or `afab-segmented` + `afab-segment` / `afab-segment-active` |
| Table | `afab-table`, `afab-thead`, `afab-th`, `afab-tbody`, `afab-tr`, `afab-td` |
| Pagination | `afab-pagination`, `afab-page-btn` |
| Badges | `afab-badge` + `afab-badge-{neutral,success,warning,danger,info,primary}` |
| Modal | `afab-overlay` + `afab-modal` (`max-w-lg`) |
| Dropdown / popover surface | `afab-popover` |
| Empty / error state | `EmptyState` |
| Loading | `AfabLoader` |

## 6. Charts (recharts)
- Import `CHART_PALETTE`, `chartSemantic`, `chartTooltipStyle` from `lib/design-tokens.ts`.
- Grid: `strokeDasharray="3 3" vertical={false}` with `className="text-gray-200 dark:text-gray-800/50" stroke="currentColor"`.
- Axes: no axis/tick lines, `fontSize: 12`, `className="text-gray-400 dark:text-gray-500" stroke="currentColor"`.
- Legends: `h-2.5 w-2.5 rounded-full` dot + `text-xs font-medium text-gray-600 dark:text-gray-300`.

## 7. Rules
- No decorative background gradients/glows on standard pages. Gradients are limited to the premium CTA and the AI/plans hero.
- Every hard-coded light color needs its `dark:` counterpart (and vice-versa).
- Native `<option>` elements inherit `afab-select option` colors so dropdowns stay readable in dark mode.
- Use logical properties (`ms-`, `me-`, `start-`, `end-`, `text-start`) — the app ships in Arabic (RTL).
