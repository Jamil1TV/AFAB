/**
 * AFAB Design Tokens
 * ────────────────────────────────────────────────────
 * Source of truth: the approved reference pages (Dashboard, Transactions,
 * Expenses, Revenue, Invoices). Mirrors the CSS variables in globals.css.
 * Use these constants in TypeScript code (charts, animations, etc.)
 * For CSS-level theming, see globals.css CSS custom properties.
 * ────────────────────────────────────────────────────
 */

/* ── Typography Scale ── */
export const typography = {
  "display-lg": {
    fontFamily: "Poppins",
    fontSize: "48px",
    fontWeight: "700",
    lineHeight: "56px",
    letterSpacing: "-0.02em",
  },
  "headline-lg": {
    fontFamily: "Poppins",
    fontSize: "32px",
    fontWeight: "600",
    lineHeight: "40px",
    letterSpacing: "-0.01em",
  },
  "headline-lg-mobile": {
    fontFamily: "Poppins",
    fontSize: "28px",
    fontWeight: "600",
    lineHeight: "36px",
  },
  "headline-md": {
    fontFamily: "Poppins",
    fontSize: "24px",
    fontWeight: "600",
    lineHeight: "32px",
    letterSpacing: "-0.01em",
  },
  "body-lg": {
    fontFamily: "Inter",
    fontSize: "18px",
    fontWeight: "400",
    lineHeight: "28px",
  },
  "body-md": {
    fontFamily: "Inter",
    fontSize: "16px",
    fontWeight: "400",
    lineHeight: "24px",
  },
  "label-md": {
    fontFamily: "Inter",
    fontSize: "14px",
    fontWeight: "500",
    lineHeight: "20px",
    letterSpacing: "0.01em",
  },
  "label-sm": {
    fontFamily: "Inter",
    fontSize: "12px",
    fontWeight: "600",
    lineHeight: "16px",
    letterSpacing: "0.03em",
  },
} as const;

/* ── Spacing Scale (4px baseline grid) ── */
export const spacing = {
  base: "4px",
  xs: "4px",
  sm: "8px",
  md: "16px",
  lg: "24px",
  xl: "32px",
  "2xl": "48px",
  "3xl": "64px",
  containerMax: "1440px",
  gutter: "24px",
  marginMobile: "16px",
  marginDesktop: "40px",
} as const;

/* ── Border Radius (ROUND_TWELVE / 0.75rem base) ── */
export const radii = {
  sm: "0.375rem",   // 6px
  DEFAULT: "0.75rem", // 12px
  md: "0.75rem",   // 12px
  lg: "1rem",      // 16px — standard cards
  xl: "1.5rem",    // 24px
  full: "9999px",  // pill
} as const;

/* ── Breakpoints ── */
export const breakpoints = {
  mobile: "768px",     // < 768px: 4 columns, 16px margins
  tablet: "1024px",    // 768-1024px: 8 columns, 24px margins
  desktop: "1440px",   // > 1024px: 12 columns, 40px margins
} as const;

/* ── Light Theme Palette ── */
export const lightPalette = {
  background: "#f8f9fb",
  surface: "#ffffff",
  surfaceInset: "#f9fafb",
  primary: "#8b5cf6",
  primaryHover: "#7c3aed",
  onPrimary: "#ffffff",
  secondary: "#f5f3ff",
  onSecondary: "#7c3aed",
  muted: "#f3f4f6",
  mutedForeground: "#6b7280",
  accent: "#f5f3ff",
  accentForeground: "#7c3aed",
  error: "#ef4444",
  onBackground: "#111827",
  onSurface: "#111827",
  outline: "#e5e7eb",
  success: "#10b981",
  warning: "#f59e0b",
  info: "#0ea5e9",
} as const;

/* ── Dark Theme Palette ── */
export const darkPalette = {
  background: "#060813",
  surface: "#0c101c",
  surfaceInset: "#080c18",
  primary: "#8b5cf6",
  primaryHover: "#7c3aed",
  onPrimary: "#ffffff",
  secondary: "#191832",
  onSecondary: "#c4b5fd",
  muted: "#141826",
  mutedForeground: "#9ca3af",
  accent: "#191832",
  accentForeground: "#c4b5fd",
  error: "#ef4444",
  onBackground: "#f9fafb",
  onSurface: "#f9fafb",
  outline: "#171f2c",
  success: "#34d399",
  warning: "#fbbf24",
  info: "#38bdf8",
} as const;

/* ── Chart Color Palettes (recharts) ──
   Series order follows the reference charts: revenue purple, expenses sky,
   then emerald / amber / pink / indigo for categorical breakdowns. */
export const chartColors = {
  light: ["#8b5cf6", "#0ea5e9", "#10b981", "#f59e0b", "#ec4899", "#6366f1"],
  dark: ["#8b5cf6", "#38bdf8", "#34d399", "#fbbf24", "#f472b6", "#818cf8"],
} as const;

/** Single categorical palette that reads well on both themes. */
export const CHART_PALETTE = ["#8b5cf6", "#0ea5e9", "#10b981", "#f59e0b", "#ec4899", "#6366f1"] as const;

export const chartSemantic = {
  revenue: "#8b5cf6",
  expenses: "#0ea5e9",
  positive: "#10b981",
  negative: "#ef4444",
  neutral: "#64748b",
} as const;

/** Tooltip style shared by every recharts chart (same as Dashboard RevenueChart). */
export const chartTooltipStyle = {
  contentStyle: {
    backgroundColor: "rgba(12, 16, 28, 0.9)",
    borderColor: "rgba(139, 92, 246, 0.2)",
    borderRadius: "12px",
    color: "#fff",
    fontSize: "12px",
    boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)",
  },
  itemStyle: { color: "#e5e7eb" },
  labelStyle: { color: "#9ca3af" },
} as const;

/* ── Elevation Shadows ── */
export const shadows = {
  level1: "0 1px 2px 0 rgba(0, 0, 0, 0.05)", // shadow-sm on cards
  level2: "0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)",
  hover: "0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 4px 10px -5px rgba(0, 0, 0, 0.04)",
} as const;