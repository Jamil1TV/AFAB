"use client";

export type ThemeMode = "light" | "dark" | "system";

export type AccentPresetId =
  | "purple"
  | "blue"
  | "emerald"
  | "amber"
  | "rose"
  | "cyan"
  | "magenta"
  | "slate"
  | "custom";

export type DarkSurfaceId = "midnight" | "oled" | "slate" | "charcoal";

export type RadiusPresetId = "sm" | "md" | "lg";

export type DensityId = "comfortable" | "compact";

export type FontFamilyId = "inter" | "serif" | "mono" | "geometric" | "kufi" | "system";

export type FontSizeId = "sm" | "md" | "lg" | "xl";

export interface AccentPreset {
  id: AccentPresetId;
  nameEn: string;
  nameAr: string;
  primary: string;
  primaryHover: string;
  lightTint: string;
  darkSecondary: string;
  glowColor: string;
}

export interface DarkSurfacePreset {
  id: DarkSurfaceId;
  nameEn: string;
  nameAr: string;
  descEn: string;
  descAr: string;
  bg: string;
  card: string;
  surfaceInset: string;
  border: string;
}

export interface RadiusPreset {
  id: RadiusPresetId;
  nameEn: string;
  nameAr: string;
  valueRem: string;
  pxValue: number;
}

export interface FontFamilyPreset {
  id: FontFamilyId;
  nameEn: string;
  nameAr: string;
  categoryEn: string;
  categoryAr: string;
  descEn: string;
  descAr: string;
  sampleEn: string;
  sampleAr: string;
  cssFamilyBody: string;
  cssFamilyHeading: string;
}

export interface FontSizePreset {
  id: FontSizeId;
  nameEn: string;
  nameAr: string;
  descEn: string;
  descAr: string;
  basePx: number;
  scalePercent: string;
}

export interface AppearanceSettings {
  themeMode: ThemeMode;
  accentPreset: AccentPresetId;
  customPrimaryColor: string;
  darkSurface: DarkSurfaceId;
  radius: RadiusPresetId;
  density: DensityId;
  fontFamily: FontFamilyId;
  fontSize: FontSizeId;
  enableGlow: boolean;
  smoothTransitions: boolean;
}

export const ACCENT_PRESETS: AccentPreset[] = [
  {
    id: "purple",
    nameEn: "Electric Violet",
    nameAr: "بنفسجي إشعاعي (هوية AFAB)",
    primary: "#8b5cf6",
    primaryHover: "#7c3aed",
    lightTint: "#f5f3ff",
    darkSecondary: "#191832",
    glowColor: "rgba(139, 92, 246, 0.35)",
  },
  {
    id: "blue",
    nameEn: "Ocean Sapphire",
    nameAr: "أزرق المحيط الياقوتي",
    primary: "#3b82f6",
    primaryHover: "#2563eb",
    lightTint: "#eff6ff",
    darkSecondary: "#172554",
    glowColor: "rgba(59, 130, 246, 0.35)",
  },
  {
    id: "emerald",
    nameEn: "Emerald Wealth",
    nameAr: "زمردي مالي واعد",
    primary: "#10b981",
    primaryHover: "#059669",
    lightTint: "#ecfdf5",
    darkSecondary: "#064e3b",
    glowColor: "rgba(16, 185, 129, 0.35)",
  },
  {
    id: "amber",
    nameEn: "Sunset Amber",
    nameAr: "كهرماني غروب الشمس",
    primary: "#f59e0b",
    primaryHover: "#d97706",
    lightTint: "#fffbeb",
    darkSecondary: "#451a03",
    glowColor: "rgba(245, 158, 11, 0.35)",
  },
  {
    id: "rose",
    nameEn: "Crimson Ruby",
    nameAr: "ياقوتي قرمزي حديث",
    primary: "#f43f5e",
    primaryHover: "#e11d48",
    lightTint: "#fff1f2",
    darkSecondary: "#4c0519",
    glowColor: "rgba(244, 63, 94, 0.35)",
  },
  {
    id: "cyan",
    nameEn: "Cyber Cyan",
    nameAr: "سماوي تكنولوجي سايبر",
    primary: "#06b6d4",
    primaryHover: "#0891b2",
    lightTint: "#ecfeff",
    darkSecondary: "#083344",
    glowColor: "rgba(6, 182, 212, 0.35)",
  },
  {
    id: "magenta",
    nameEn: "Neon Magenta",
    nameAr: "فوشيا نيون ساطع",
    primary: "#d946ef",
    primaryHover: "#c026d3",
    lightTint: "#fdf4ff",
    darkSecondary: "#4a044e",
    glowColor: "rgba(217, 70, 239, 0.35)",
  },
  {
    id: "slate",
    nameEn: "Titanium Slate",
    nameAr: "رمادي تيتانيوم مصقول",
    primary: "#64748b",
    primaryHover: "#475569",
    lightTint: "#f8fafc",
    darkSecondary: "#1e293b",
    glowColor: "rgba(100, 116, 139, 0.35)",
  },
];

export const DARK_SURFACE_PRESETS: DarkSurfacePreset[] = [
  {
    id: "midnight",
    nameEn: "Midnight Navy",
    nameAr: "كحلي منتصف الليل (الافتراضي)",
    descEn: "Signature AFAB deep space navy with vibrant contrast.",
    descAr: "هوية AFAB الكحلية الفضائية العميقة بتباين فائق.",
    bg: "#060813",
    card: "#0c101c",
    surfaceInset: "#080c18",
    border: "#171f2c",
  },
  {
    id: "oled",
    nameEn: "OLED Pure Black",
    nameAr: "أسود نقي تام (OLED)",
    descEn: "Ultra-pure pitch black surface for maximum contrast and battery efficiency.",
    descAr: "أسود تام لتباين مطلق وتوفير طاقة شاشات OLED.",
    bg: "#000000",
    card: "#0a0a0a",
    surfaceInset: "#050505",
    border: "#171717",
  },
  {
    id: "slate",
    nameEn: "Deep Slate",
    nameAr: "رمادي أردوازي عميق",
    descEn: "Balanced dark titanium graphite with modern cool undertones.",
    descAr: "رمادي داكن متوازن بلمسات تيتانيوم باردة.",
    bg: "#090d16",
    card: "#0f172a",
    surfaceInset: "#0b1120",
    border: "#1e293b",
  },
  {
    id: "charcoal",
    nameEn: "Charcoal Eclipse",
    nameAr: "فحم كلاسيكي هادئ",
    descEn: "Subtle neutral matte charcoal for reduced eye fatigue during long sessions.",
    descAr: "درجات فحمية مطفية ناعمة تخفف إجهاد العين في أوقات العمل الطويلة.",
    bg: "#111318",
    card: "#181b22",
    surfaceInset: "#13161c",
    border: "#232730",
  },
];

// Removed Pill option as requested (Sharp 8px, Balanced 12px, Modern 16px)
export const RADIUS_PRESETS: RadiusPreset[] = [
  { id: "sm", nameEn: "Sharp", nameAr: "حواف حادة (8px)", valueRem: "0.5rem", pxValue: 8 },
  { id: "md", nameEn: "Balanced", nameAr: "متوازن (12px)", valueRem: "0.75rem", pxValue: 12 },
  { id: "lg", nameEn: "Modern", nameAr: "عصري مستدير (16px)", valueRem: "1rem", pxValue: 16 },
];

// Visually distinct typography styles: Clean Sans, Classical Serif, Coding Monospace, Chunky Geometric, Ancient Kufic, and Native OS
export const FONT_FAMILY_PRESETS: FontFamilyPreset[] = [
  {
    id: "inter",
    nameEn: "Modern Clean Sans (Inter & Poppins)",
    nameAr: "عصري قياسي (Inter & Poppins)",
    categoryEn: "Clean Sans",
    categoryAr: "سان سيريف نقي",
    descEn: "Clean, standard modern fintech benchmark with supreme clarity",
    descAr: "المظهر العصري القياسي المعتمد لمنصات التكنولوجيا المالية العالمية",
    sampleEn: "Fintech Portfolio $124,850",
    sampleAr: "محفظة التكنولوجيا المالية 124,850 $",
    cssFamilyBody: "var(--font-sans), 'Inter', -apple-system, sans-serif",
    cssFamilyHeading: "var(--font-heading), 'Poppins', sans-serif",
  },
  {
    id: "serif",
    nameEn: "Luxury Editorial Serif (Playfair & Amiri)",
    nameAr: "سيريف ملكي فاخر (Playfair & أميري)",
    categoryEn: "Classical Serif",
    categoryAr: "سيريف وزخرفة ملكية",
    descEn: "High-end private banking serif with classical Arabic Naskh calligraphy",
    descAr: "خط كلاسيكي فاخر ذو حواف مميزة وزخرفة عربية أصيلة للبنوك الخاصة",
    sampleEn: "Private Wealth & Assets $124,850",
    sampleAr: "الأصول والثروات الاستثمارية 124,850 $",
    cssFamilyBody: "'Playfair Display', 'Amiri', Georgia, serif",
    cssFamilyHeading: "'Playfair Display', 'Amiri', Georgia, serif",
  },
  {
    id: "mono",
    nameEn: "Cyber Terminal Monospace (JetBrains Mono)",
    nameAr: "محطة برمجية ثابتة العرض (JetBrains Mono)",
    categoryEn: "Terminal Mono",
    categoryAr: "خط برمجي ثابت العرض",
    descEn: "Fixed-width Bloomberg / code terminal aesthetic with tabular numbers",
    descAr: "خط برمجي ذو مسافات ثابتة يمنح طابع منصات التداول وأجهزة بلومبرغ",
    sampleEn: "EXECUTE_TRADE_NET: $124,850.00",
    sampleAr: "تنفيذ_المعاملات_المالية: 124,850 $",
    cssFamilyBody: "'JetBrains Mono', 'Courier New', monospace",
    cssFamilyHeading: "'JetBrains Mono', 'Courier New', monospace",
  },
  {
    id: "geometric",
    nameEn: "Bold Geometric Impact (Cairo & Montserrat)",
    nameAr: "هندسي عريض جريء (Cairo & Montserrat)",
    categoryEn: "Bold Geometric",
    categoryAr: "هندسي عريض ومكثف",
    descEn: "Chunky, high-impact geometric blocks with wide bold curves",
    descAr: "خط هندسي عريض وقوي الحضور ذو زوايا جريئة ومتباعدة",
    sampleEn: "AFAB PRIME CAPITAL $124,850",
    sampleAr: "رأس المال الاستثماري 124,850 $",
    cssFamilyBody: "'Cairo', 'Montserrat', sans-serif",
    cssFamilyHeading: "'Cairo', 'Montserrat', sans-serif",
  },
  {
    id: "kufi",
    nameEn: "Monumental Kufic & Roman (Cinzel & Reem Kufi)",
    nameAr: "كوفي كلاسيكي وروماني (Cinzel & Reem Kufi)",
    categoryEn: "Monumental Display",
    categoryAr: "كوفي وروماني أثري",
    descEn: "Monumental Roman stone capitals paired with authentic geometric Kufic",
    descAr: "نقوش رومانية حجرية مميزة مدمجة مع الخط الكوفي الهندسي التراثي",
    sampleEn: "MONUMENTAL FINANCIAL SUITE",
    sampleAr: "الصرح المالي للمؤسسات الكبرى",
    cssFamilyBody: "'Reem Kufi', 'Cinzel', serif",
    cssFamilyHeading: "'Cinzel', 'Reem Kufi', serif",
  },
  {
    id: "system",
    nameEn: "System Native OS",
    nameAr: "خط النظام الافتراضي (System OS)",
    categoryEn: "Native OS",
    categoryAr: "خط الجهاز المباشر",
    descEn: "Zero-latency raw operating system font (Segoe UI, San Francisco)",
    descAr: "الخط الخام المباشر لنظام تشغيل جهازك دون أي تحميل خارجي",
    sampleEn: "Native System Experience $124,850",
    sampleAr: "الواجهة الأصلية لجهازك 124,850 $",
    cssFamilyBody: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    cssFamilyHeading: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  },
];

export const FONT_SIZE_PRESETS: FontSizePreset[] = [
  {
    id: "sm",
    nameEn: "Compact (14px)",
    nameAr: "مكثف (14 بكسل)",
    descEn: "Data-dense ledger view for power accountants and multi-column screens",
    descAr: "عرض مكثف للبيانات ملائم للمحاسبين والشاشات متعددة الأعمدة",
    basePx: 14,
    scalePercent: "87.5%",
  },
  {
    id: "md",
    nameEn: "Standard (16px)",
    nameAr: "قياسي متوازن (16 بكسل)",
    descEn: "Default AFAB typography with optimal readability and proportion",
    descAr: "المقاس الافتراضي المتوازن لمنصة AFAB براحة قراءة مثالية",
    basePx: 16,
    scalePercent: "100%",
  },
  {
    id: "lg",
    nameEn: "Comfortable (18px)",
    nameAr: "مريح وواضح (18 بكسل)",
    descEn: "Larger relaxed typography reducing eye strain during long sessions",
    descAr: "خط أكبر وأكثر راحة للعين خلال جلسات العمل والتدقيق الطويلة",
    basePx: 18,
    scalePercent: "112.5%",
  },
  {
    id: "xl",
    nameEn: "Accessible (20px)",
    nameAr: "كبير عالي الوضوح (20 بكسل)",
    descEn: "High-visibility scale ideal for presentations and enhanced accessibility",
    descAr: "حجم كبير فائق الوضوح للعروض التقديمية ولسهولة الوصول الفائقة",
    basePx: 20,
    scalePercent: "125%",
  },
];

export const DEFAULT_APPEARANCE_SETTINGS: AppearanceSettings = {
  themeMode: "system",
  accentPreset: "purple",
  customPrimaryColor: "#8b5cf6",
  darkSurface: "midnight",
  radius: "md",
  density: "comfortable",
  fontFamily: "inter",
  fontSize: "md",
  enableGlow: true,
  smoothTransitions: true,
};

export const APPEARANCE_STORAGE_KEY = "afab_appearance_settings";

/**
 * Helper to adjust lightness of a hex color
 */
export function adjustHexLightness(hex: string, percent: number): string {
  const cleanHex = hex.replace("#", "");
  if (cleanHex.length !== 6) return hex;

  const num = parseInt(cleanHex, 16);
  let r = (num >> 16) + Math.round(255 * (percent / 100));
  let g = ((num >> 8) & 0x00ff) + Math.round(255 * (percent / 100));
  let b = (num & 0x0000ff) + Math.round(255 * (percent / 100));

  r = Math.min(255, Math.max(0, r));
  g = Math.min(255, Math.max(0, g));
  b = Math.min(255, Math.max(0, b));

  return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
}

/**
 * Converts a hex string into rgba
 */
export function hexToRgba(hex: string, alpha: number): string {
  const cleanHex = hex.replace("#", "");
  if (cleanHex.length !== 6) return `rgba(139, 92, 246, ${alpha})`;
  const num = parseInt(cleanHex, 16);
  const r = num >> 16;
  const g = (num >> 8) & 0x00ff;
  const b = num & 0x0000ff;
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

/**
 * Resolves color tokens from preset or custom hex
 */
export function resolveAccentColors(presetId: AccentPresetId, customHex: string) {
  if (presetId === "custom") {
    const validHex = /^#[0-9A-Fa-f]{6}$/.test(customHex) ? customHex : "#8b5cf6";
    return {
      primary: validHex,
      primaryHover: adjustHexLightness(validHex, -12),
      lightTint: adjustHexLightness(validHex, 90),
      darkSecondary: adjustHexLightness(validHex, -75),
      glow: hexToRgba(validHex, 0.4),
    };
  }

  const preset = ACCENT_PRESETS.find((p) => p.id === presetId) || ACCENT_PRESETS[0];
  return {
    primary: preset.primary,
    primaryHover: preset.primaryHover,
    lightTint: preset.lightTint,
    darkSecondary: preset.darkSecondary,
    glow: preset.glowColor,
  };
}

/**
 * Reads stored appearance from localStorage safely
 */
export function getStoredAppearance(): AppearanceSettings {
  if (typeof window === "undefined") return DEFAULT_APPEARANCE_SETTINGS;
  try {
    const raw = localStorage.getItem(APPEARANCE_STORAGE_KEY);
    if (!raw) return DEFAULT_APPEARANCE_SETTINGS;
    const parsed = JSON.parse(raw);
    const validRadius = RADIUS_PRESETS.some((r) => r.id === parsed.radius)
      ? parsed.radius
      : "md";
    return { ...DEFAULT_APPEARANCE_SETTINGS, ...parsed, radius: validRadius };
  } catch {
    return DEFAULT_APPEARANCE_SETTINGS;
  }
}

/**
 * Dynamically applies appearance settings by injecting CSS variables and data attributes
 */
export function applyAppearance(
  settings: AppearanceSettings,
  setThemeFn?: (theme: string) => void
): void {
  if (typeof window === "undefined") return;

  if (setThemeFn && settings.themeMode) {
    setThemeFn(settings.themeMode);
  }

  const { primary, primaryHover, glow, darkSecondary, lightTint } = resolveAccentColors(
    settings.accentPreset,
    settings.customPrimaryColor
  );

  const surface =
    DARK_SURFACE_PRESETS.find((s) => s.id === settings.darkSurface) ||
    DARK_SURFACE_PRESETS[0];

  const radiusObj =
    RADIUS_PRESETS.find((r) => r.id === settings.radius) || RADIUS_PRESETS[1];

  const fontObj =
    FONT_FAMILY_PRESETS.find((f) => f.id === settings.fontFamily) ||
    FONT_FAMILY_PRESETS[0];

  const sizeObj =
    FONT_SIZE_PRESETS.find((s) => s.id === settings.fontSize) ||
    FONT_SIZE_PRESETS[1];

  const css = `
    :root {
      --font-family-body: ${fontObj.cssFamilyBody};
      --font-family-heading: ${fontObj.cssFamilyHeading};
      --primary: ${primary};
      --primary-hover: ${primaryHover};
      --primary-foreground: #ffffff;
      --secondary: ${lightTint};
      --secondary-foreground: ${primary};
      --accent: ${lightTint};
      --accent-foreground: ${primary};
      --ring: ${primary};
      --sidebar-primary: ${primary};
      --sidebar-accent: ${hexToRgba(primary, 0.08)};
      --sidebar-accent-foreground: ${primary};
      --radius: ${radiusObj.valueRem};
      --radius-sm: calc(${radiusObj.valueRem} * 0.5);
      --radius-md: calc(${radiusObj.valueRem} * 0.75);
      --radius-lg: ${radiusObj.valueRem};
      --radius-xl: calc(${radiusObj.valueRem} * 1.33);
      --radius-2xl: calc(${radiusObj.valueRem} * 1.67);
      --radius-3xl: calc(${radiusObj.valueRem} * 2);
      --radius-4xl: calc(${radiusObj.valueRem} * 2.67);
      --glow-color: ${glow};
    }
    .dark {
      --font-family-body: ${fontObj.cssFamilyBody};
      --font-family-heading: ${fontObj.cssFamilyHeading};
      --primary: ${primary};
      --primary-hover: ${primaryHover};
      --primary-foreground: #ffffff;
      --background: ${surface.bg};
      --card: ${surface.card};
      --popover: ${surface.card};
      --surface-inset: ${surface.surfaceInset};
      --border: ${surface.border};
      --secondary: ${darkSecondary};
      --secondary-foreground: ${adjustHexLightness(primary, 30)};
      --accent: ${darkSecondary};
      --accent-foreground: ${adjustHexLightness(primary, 30)};
      --ring: ${primary};
      --sidebar-primary: ${primary};
      --sidebar-accent: ${darkSecondary};
      --sidebar-accent-foreground: ${adjustHexLightness(primary, 30)};
      --radius: ${radiusObj.valueRem};
      --radius-sm: calc(${radiusObj.valueRem} * 0.5);
      --radius-md: calc(${radiusObj.valueRem} * 0.75);
      --radius-lg: ${radiusObj.valueRem};
      --radius-xl: calc(${radiusObj.valueRem} * 1.33);
      --radius-2xl: calc(${radiusObj.valueRem} * 1.67);
      --radius-3xl: calc(${radiusObj.valueRem} * 2);
      --radius-4xl: calc(${radiusObj.valueRem} * 2.67);
      --glow-color: ${glow};
    }
    html, body, p, span, a, button, input, select, textarea, label, td, th, li {
      font-family: var(--font-family-body) !important;
    }
    h1, h2, h3, h4, h5, h6, .afab-page-title, .afab-card-title, .text-headline-lg, .text-headline-md, .text-display-lg {
      font-family: var(--font-family-heading) !important;
    }
  `;

  let styleEl = document.getElementById("afab-appearance-theme") as HTMLStyleElement | null;
  if (!styleEl) {
    styleEl = document.createElement("style");
    styleEl.id = "afab-appearance-theme";
    document.head.appendChild(styleEl);
  }
  styleEl.textContent = css;

  const root = document.documentElement;
  root.setAttribute("data-density", settings.density);
  root.setAttribute("data-glow", settings.enableGlow ? "true" : "false");
  root.setAttribute("data-transitions", settings.smoothTransitions ? "true" : "false");
  root.setAttribute("data-font", settings.fontFamily || "inter");
  root.setAttribute("data-font-size", settings.fontSize || "md");
  root.style.fontSize = sizeObj.scalePercent;

  try {
    localStorage.setItem(APPEARANCE_STORAGE_KEY, JSON.stringify(settings));
  } catch (err) {
    console.error("Failed to save appearance settings to localStorage:", err);
  }

  window.dispatchEvent(
    new CustomEvent("afab_appearance_changed", { detail: settings })
  );
}

/**
 * Resets appearance to AFAB signature defaults
 */
export function resetAppearance(
  setThemeFn?: (theme: string) => void
): AppearanceSettings {
  applyAppearance(DEFAULT_APPEARANCE_SETTINGS, setThemeFn);
  return DEFAULT_APPEARANCE_SETTINGS;
}
