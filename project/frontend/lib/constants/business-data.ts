/**
 * Centralized Business Constants & Localization Registry
 * 
 * Provides stable internal identifiers / enum keys for API and backend compatibility,
 * while offering localized display labels for English and Arabic.
 */

export interface CountryItem {
  code: string;
  nameEn: string;
  nameAr: string;
}

export interface IndustryItem {
  id: string;
  nameEn: string;
  nameAr: string;
}

export interface BusinessTypeItem {
  id: string;
  nameEn: string;
  nameAr: string;
}

export interface CurrencyItem {
  code: string;
  symbol: string;
  nameEn: string;
  nameAr: string;
}

export interface TimezoneItem {
  value: string;
  labelEn: string;
  labelAr: string;
}

export interface MonthItem {
  value: number;
  nameEn: string;
  nameAr: string;
}

export interface DateFormatItem {
  value: string;
  labelEn: string;
  labelAr: string;
}

export interface NumberFormatItem {
  value: string;
  labelEn: string;
  labelAr: string;
}

// ── COUNTRIES ─────────────────────────────────────────────────────────────
export const COUNTRIES: CountryItem[] = [
  { code: "US", nameEn: "United States", nameAr: "الولايات المتحدة" },
  { code: "AE", nameEn: "United Arab Emirates", nameAr: "الإمارات العربية المتحدة" },
  { code: "SA", nameEn: "Saudi Arabia", nameAr: "المملكة العربية السعودية" },
  { code: "QA", nameEn: "Qatar", nameAr: "قطر" },
  { code: "KW", nameEn: "Kuwait", nameAr: "الكويت" },
  { code: "BH", nameEn: "Bahrain", nameAr: "البحرين" },
  { code: "OM", nameEn: "Oman", nameAr: "عُمان" },
  { code: "EG", nameEn: "Egypt", nameAr: "مصر" },
  { code: "DZ", nameEn: "Algeria", nameAr: "الجزائر" },
  { code: "MA", nameEn: "Morocco", nameAr: "المغرب" },
  { code: "JO", nameEn: "Jordan", nameAr: "الأردن" },
  { code: "LB", nameEn: "Lebanon", nameAr: "لبنان" },
  { code: "GB", nameEn: "United Kingdom", nameAr: "المملكة المتحدة" },
  { code: "CA", nameEn: "Canada", nameAr: "كندا" },
  { code: "DE", nameEn: "Germany", nameAr: "ألمانيا" },
  { code: "FR", nameEn: "France", nameAr: "فرنسا" },
];

// ── INDUSTRIES ────────────────────────────────────────────────────────────
export const INDUSTRIES: IndustryItem[] = [
  { id: "technology", nameEn: "Technology & Software", nameAr: "التكنولوجيا والبرمجيات" },
  { id: "ecommerce", nameEn: "E-commerce & Retail", nameAr: "التجارة الإلكترونية والتجزئة" },
  { id: "services", nameEn: "Professional Services & Consulting", nameAr: "الخدمات المهنية والاستشارات" },
  { id: "finance", nameEn: "Financial Services & Fintech", nameAr: "الخدمات المالية والتقنية المالية" },
  { id: "healthcare", nameEn: "Healthcare & Life Sciences", nameAr: "الرعاية الصحية وعلوم الحياة" },
  { id: "realestate", nameEn: "Real Estate & Construction", nameAr: "العقارات والإنشاءات" },
  { id: "media", nameEn: "Media & Entertainment", nameAr: "الإعلام والترفيه" },
  { id: "food", nameEn: "Food & Beverage", nameAr: "الأغذية والمشروبات" },
  { id: "manufacturing", nameEn: "Manufacturing & Logistics", nameAr: "التصنيع والخدمات اللوجستية" },
  { id: "education", nameEn: "Education & Non-profit", nameAr: "التعليم والمنظمات غير الربحية" },
  { id: "other", nameEn: "Other", nameAr: "أخرى" },
];

// ── BUSINESS / ENTITY TYPES ───────────────────────────────────────────────
export const BUSINESS_TYPES: BusinessTypeItem[] = [
  { id: "sole_proprietorship", nameEn: "Sole Proprietorship", nameAr: "ملكية فردية" },
  { id: "llc", nameEn: "Limited Liability Company (LLC)", nameAr: "شركة ذات مسؤولية محدودة" },
  { id: "corporation", nameEn: "Corporation", nameAr: "شركة مساهمة" },
  { id: "partnership", nameEn: "Partnership", nameAr: "شراكة" },
  { id: "freelancer", nameEn: "Freelancer / Individual", nameAr: "مستقل / فرد" },
  { id: "non_profit", nameEn: "Non-Profit", nameAr: "منظمة غير ربحية" },
];

// ── CURRENCIES ────────────────────────────────────────────────────────────
export const CURRENCIES: CurrencyItem[] = [
  { code: "USD", symbol: "$", nameEn: "US Dollar", nameAr: "دولار أمريكي" },
  { code: "EUR", symbol: "€", nameEn: "Euro", nameAr: "يورو" },
  { code: "AED", symbol: "د.إ", nameEn: "UAE Dirham", nameAr: "درهم إماراتي" },
  { code: "SAR", symbol: "﷼", nameEn: "Saudi Riyal", nameAr: "ريال سعودي" },
  { code: "QAR", symbol: "﷼", nameEn: "Qatari Riyal", nameAr: "ريال قطري" },
  { code: "KWD", symbol: "د.ك", nameEn: "Kuwaiti Dinar", nameAr: "دينار كويتي" },
  { code: "BHD", symbol: "د.ب", nameEn: "Bahraini Dinar", nameAr: "دينار بحريني" },
  { code: "OMR", symbol: "ر.ع.", nameEn: "Omani Rial", nameAr: "ريال عماني" },
  { code: "EGP", symbol: "ج.م", nameEn: "Egyptian Pound", nameAr: "جنيه مصري" },
  { code: "DZD", symbol: "د.ج", nameEn: "Algerian Dinar", nameAr: "دينار جزائري" },
  { code: "MAD", symbol: "د.م", nameEn: "Moroccan Dirham", nameAr: "درهم مغربي" },
  { code: "GBP", symbol: "£", nameEn: "British Pound", nameAr: "جنيه إسترليني" },
  { code: "CAD", symbol: "$", nameEn: "Canadian Dollar", nameAr: "دولار كندي" },
  { code: "AUD", symbol: "$", nameEn: "Australian Dollar", nameAr: "دولار أسترالي" },
  { code: "JPY", symbol: "¥", nameEn: "Japanese Yen", nameAr: "ين ياباني" },
];

// ── TIMEZONES ─────────────────────────────────────────────────────────────
export const TIMEZONES: TimezoneItem[] = [
  { value: "Asia/Dubai", labelEn: "Asia/Dubai (GMT+4 - UAE Time)", labelAr: "آسيا/دبي (GMT+4 - توقيت الإمارات)" },
  { value: "Asia/Riyadh", labelEn: "Asia/Riyadh (GMT+3 - Saudi Time)", labelAr: "آسيا/الرياض (GMT+3 - توقيت السعودية)" },
  { value: "Asia/Qatar", labelEn: "Asia/Qatar (GMT+3 - Qatar Time)", labelAr: "آسيا/قطر (GMT+3 - توقيت قطر)" },
  { value: "Africa/Cairo", labelEn: "Africa/Cairo (GMT+3 - Cairo Time)", labelAr: "إفريقيا/القاهرة (GMT+3 - توقيت القاهرة)" },
  { value: "Africa/Algiers", labelEn: "Africa/Algiers (GMT+1 - Algiers Time)", labelAr: "إفريقيا/الجزائر (GMT+1 - توقيت الجزائر)" },
  { value: "UTC", labelEn: "UTC (Universal Time Coordinated)", labelAr: "التوقيت العالمي المنسق (UTC)" },
  { value: "Europe/London", labelEn: "Europe/London (GMT / BST)", labelAr: "أوروبا/لندن (GMT / BST)" },
  { value: "Europe/Paris", labelEn: "Europe/Paris (GMT+1 - CET)", labelAr: "أوروبا/باريس (GMT+1 - توقيت وسط أوروبا)" },
  { value: "America/New_York", labelEn: "America/New_York (EST / EDT)", labelAr: "أمريكا/نيويورك (EST / EDT)" },
  { value: "America/Los_Angeles", labelEn: "America/Los_Angeles (PST / PDT)", labelAr: "أمريكا/لوس أنجلوس (PST / PDT)" },
  { value: "Asia/Tokyo", labelEn: "Asia/Tokyo (JST)", labelAr: "آسيا/طوكيو (JST)" },
  { value: "Australia/Sydney", labelEn: "Australia/Sydney (AEST)", labelAr: "أستراليا/سيدني (AEST)" },
];

// ── MONTHS ────────────────────────────────────────────────────────────────
export const MONTHS: MonthItem[] = [
  { value: 1, nameEn: "January", nameAr: "يناير" },
  { value: 2, nameEn: "February", nameAr: "فبراير" },
  { value: 3, nameEn: "March", nameAr: "مارس" },
  { value: 4, nameEn: "April", nameAr: "أبريل" },
  { value: 5, nameEn: "May", nameAr: "مايو" },
  { value: 6, nameEn: "June", nameAr: "يونيو" },
  { value: 7, nameEn: "July", nameAr: "يوليو" },
  { value: 8, nameEn: "August", nameAr: "أغسطس" },
  { value: 9, nameEn: "September", nameAr: "سبتمبر" },
  { value: 10, nameEn: "October", nameAr: "أكتوبر" },
  { value: 11, nameEn: "November", nameAr: "نوفمبر" },
  { value: 12, nameEn: "December", nameAr: "ديسمبر" },
];

// ── DATE FORMATS ──────────────────────────────────────────────────────────
export const DATE_FORMATS: DateFormatItem[] = [
  { value: "MM/DD/YYYY", labelEn: "MM/DD/YYYY (12/31/2026 - US)", labelAr: "MM/DD/YYYY (12/31/2026 - نمط أمريكي)" },
  { value: "DD/MM/YYYY", labelEn: "DD/MM/YYYY (31/12/2026 - International)", labelAr: "DD/MM/YYYY (31/12/2026 - نمط دولي)" },
  { value: "YYYY-MM-DD", labelEn: "YYYY-MM-DD (2026-12-31 - ISO)", labelAr: "YYYY-MM-DD (2026-12-31 - نمط قياسي ISO)" },
  { value: "DD-MM-YYYY", labelEn: "DD-MM-YYYY (31-12-2026)", labelAr: "DD-MM-YYYY (31-12-2026)" },
  { value: "MMM DD, YYYY", labelEn: "MMM DD, YYYY (Dec 31, 2026)", labelAr: "MMM DD, YYYY (31 ديسمبر 2026)" },
  { value: "DD MMM YYYY", labelEn: "DD MMM YYYY (31 Dec 2026)", labelAr: "DD MMM YYYY (31 ديسمبر 2026)" },
  { value: "YYYY/MM/DD", labelEn: "YYYY/MM/DD (2026/12/31)", labelAr: "YYYY/MM/DD (2026/12/31)" },
];

// ── NUMBER FORMATS ────────────────────────────────────────────────────────
export const NUMBER_FORMATS: NumberFormatItem[] = [
  { value: "US", labelEn: "1,234,567.89 (US Standard)", labelAr: "1,234,567.89 (النمط الأمريكي)" },
  { value: "EU", labelEn: "1.234.567,89 (EU Standard)", labelAr: "1.234.567,89 (النمط الأوروبي)" },
  { value: "SI", labelEn: "1 234 567,89 (Space separator)", labelAr: "1 234 567,89 (فاصل المسافة)" },
  { value: "DOT", labelEn: "1,234,567·89 (Middle dot)", labelAr: "1,234,567·89 (نقطة وسطية)" },
  { value: "RAW", labelEn: "1234567.89 (Plain)", labelAr: "1234567.89 (بدون فواصل)" },
];

// ── PERIODS ───────────────────────────────────────────────────────────────
export const PERIODS = {
  WEEKLY: { en: "WEEKLY", ar: "أسبوعي" },
  MONTHLY: { en: "MONTHLY", ar: "شهري" },
  YEARLY: { en: "YEARLY", ar: "سنوي" },
} as const;

export type PeriodKey = "WEEKLY" | "MONTHLY" | "YEARLY";

// ──────────────────────────────────────────────────────────────────────────
// LOCALIZATION LOOKUP HELPERS
// ──────────────────────────────────────────────────────────────────────────

/**
 * Returns localized country name. Matches by code ("US", "QA") or English/Arabic name.
 */
export function getLocalizedCountry(codeOrName: string | undefined | null, locale: string = "en"): string {
  if (!codeOrName) return "";
  const isAr = locale === "ar";
  const trimmed = codeOrName.trim();
  
  const found = COUNTRIES.find(
    (c) =>
      c.code.toUpperCase() === trimmed.toUpperCase() ||
      c.nameEn.toLowerCase() === trimmed.toLowerCase() ||
      c.nameAr === trimmed
  );

  if (found) return isAr ? found.nameAr : found.nameEn;
  return trimmed;
}

/**
 * Returns localized industry name. Matches by ID or English/Arabic name.
 */
export function getLocalizedIndustry(idOrName: string | undefined | null, locale: string = "en"): string {
  if (!idOrName) return "";
  const isAr = locale === "ar";
  const trimmed = idOrName.trim();

  // Handle aliases like "Software" -> "Technology & Software", "Retail" -> "E-commerce & Retail"
  const aliasMap: Record<string, string> = {
    Software: "technology",
    "Software & IT": "technology",
    Retail: "ecommerce",
    "Retail & E-commerce": "ecommerce",
    Consulting: "services",
    "Consulting & Professional Services": "services",
    Finance: "finance",
    "Finance & Investment": "finance",
    Healthcare: "healthcare",
    "Healthcare & Wellness": "healthcare",
    "Real Estate": "realestate",
    Education: "education",
    "Education & Training": "education",
    Manufacturing: "manufacturing",
    "Manufacturing & Supply Chain": "manufacturing",
  };

  const normalizedId = aliasMap[trimmed] || trimmed.toLowerCase();

  const found = INDUSTRIES.find(
    (ind) =>
      ind.id === normalizedId ||
      ind.nameEn.toLowerCase() === trimmed.toLowerCase() ||
      ind.nameAr === trimmed
  );

  if (found) return isAr ? found.nameAr : found.nameEn;
  return trimmed;
}

/**
 * Returns localized entity / business type name. Matches by ID or English/Arabic name.
 */
export function getLocalizedBusinessType(idOrName: string | undefined | null, locale: string = "en"): string {
  if (!idOrName) return "";
  const isAr = locale === "ar";
  const trimmed = idOrName.trim();

  const found = BUSINESS_TYPES.find(
    (bt) =>
      bt.id === trimmed.toLowerCase() ||
      bt.nameEn.toLowerCase() === trimmed.toLowerCase() ||
      bt.nameAr === trimmed
  );

  if (found) return isAr ? found.nameAr : found.nameEn;
  return trimmed;
}

/**
 * Returns localized currency name (e.g. "Qatari Riyal" vs "ريال قطري").
 */
export function getLocalizedCurrencyName(code: string | undefined | null, locale: string = "en"): string {
  if (!code) return "";
  const isAr = locale === "ar";
  const upper = code.toUpperCase().trim();
  const found = CURRENCIES.find((c) => c.code === upper);
  if (found) return isAr ? found.nameAr : found.nameEn;
  return upper;
}

/**
 * Returns localized currency display with code, symbol, and name.
 * e.g., "QAR (﷼) — ريال قطري" (ar) / "QAR (﷼) — Qatari Riyal" (en)
 */
export function getLocalizedCurrencyOption(currency: CurrencyItem, locale: string = "en"): string {
  const isAr = locale === "ar";
  return `${currency.code} (${currency.symbol}) — ${isAr ? currency.nameAr : currency.nameEn}`;
}

/**
 * Returns localized timezone label. Matches by value ("Asia/Riyadh", "UTC", etc.).
 */
export function getLocalizedTimezone(tzValue: string | undefined | null, locale: string = "en"): string {
  if (!tzValue) return "";
  const isAr = locale === "ar";
  const trimmed = tzValue.trim();

  const found = TIMEZONES.find(
    (tz) =>
      tz.value === trimmed ||
      tz.labelEn.toLowerCase().startsWith(trimmed.toLowerCase()) ||
      tz.labelAr.startsWith(trimmed)
  );

  if (found) return isAr ? found.labelAr : found.labelEn;
  return trimmed;
}

/**
 * Returns localized month name (1 -> "January" / "يناير").
 */
export function getLocalizedMonth(monthNum: number | string | undefined | null, locale: string = "en"): string {
  const num = typeof monthNum === "string" ? parseInt(monthNum, 10) : monthNum;
  if (!num || isNaN(num) || num < 1 || num > 12) return "";
  const isAr = locale === "ar";
  const found = MONTHS.find((m) => m.value === num);
  if (found) return isAr ? found.nameAr : found.nameEn;
  return "";
}

/**
 * Returns localized period label ("WEEKLY" -> "WEEKLY" in EN, "أسبوعي" in AR).
 */
export function getLocalizedPeriod(period: PeriodKey, locale: string = "en"): string {
  const isAr = locale === "ar";
  return isAr ? PERIODS[period]?.ar || period : PERIODS[period]?.en || period;
}
