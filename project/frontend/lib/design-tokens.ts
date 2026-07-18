/**
 * AFAB Design Tokens
 * ────────────────────────────────────────────────────
 * Extracted from Stitch "AFAB Project UI" design system.
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
  primary: "#7c3aed",
  primaryContainer: "#7c3aed",
  onPrimary: "#ffffff",
  secondary: "#f3f0ff",
  secondaryContainer: "#f3f0ff",
  onSecondary: "#7c3aed",
  muted: "#f1f3f9",
  mutedForeground: "#64748b",
  accent: "#f3f0ff",
  accentForeground: "#7c3aed",
  error: "#ef4444",
  onBackground: "#1a1a2e",
  onSurface: "#1a1a2e",
  outline: "#e5e7eb",
  success: "#10b981",
  warning: "#f59e0b",
  info: "#3b82f6",
} as const;

/* ── Dark Theme Palette ── */
export const darkPalette = {
  background: "#0a0e1a",
  surface: "#131825",
  primary: "#8b5cf6",
  primaryContainer: "#0a2540",
  onPrimary: "#ffffff",
  secondary: "#1e1b4b",
  secondaryContainer: "#1e1b4b",
  onSecondary: "#c4b5fd",
  muted: "#1a1f2e",
  mutedForeground: "#94a3b8",
  accent: "#1e1b4b",
  accentForeground: "#c4b5fd",
  error: "#ef4444",
  onBackground: "#e2e8f0",
  onSurface: "#e2e8f0",
  outline: "#1e293b",
  success: "#34d399",
  warning: "#fbbf24",
  info: "#60a5fa",
} as const;

/* ── Chart Color Palettes (for recharts / chart.js) ── */
export const chartColors = {
  light: ["#7c3aed", "#10b981", "#f59e0b", "#3b82f6", "#ec4899"],
  dark: ["#8b5cf6", "#34d399", "#fbbf24", "#60a5fa", "#f472b6"],
} as const;

/* ── Elevation Shadows ── */
export const shadows = {
  level1: "none", // uses 1px border instead
  level2: "0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)",
  hover: "0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 4px 10px -5px rgba(0, 0, 0, 0.04)",
} as const;
