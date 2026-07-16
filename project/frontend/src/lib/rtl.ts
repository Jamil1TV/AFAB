export const RTL_LOCALES = ['ar'] as const;

export type SupportedLocale = 'en' | 'ar';
export type Direction = 'ltr' | 'rtl';

export function isSupportedLocale(value: string | undefined): value is SupportedLocale {
  return value === 'en' || value === 'ar';
}

export function isRtlLocale(locale: string): boolean {
  return (RTL_LOCALES as readonly string[]).includes(locale);
}

export function getDirection(locale: string): Direction {
  return isRtlLocale(locale) ? 'rtl' : 'ltr';
}
