import { getRequestConfig } from 'next-intl/server';
import { routing } from './routing';

export default getRequestConfig(async ({ requestLocale }) => {
  let locale = await requestLocale;

  if (!locale || !routing.locales.includes(locale as any)) {
    locale = routing.defaultLocale;
  }

  // Merge all per-screen translation files into one messages object
  const common = (await import(`../messages/${locale}/common.json`)).default;
  const home = (await import(`../messages/${locale}/home.json`)).default;
  const auth = (await import(`../messages/${locale}/auth.json`)).default;
  const dashboard = (await import(`../messages/${locale}/dashboard.json`)).default;
  const notFound = (await import(`../messages/${locale}/not-found.json`)).default;

  return {
    locale,
    messages: {
      Common: common,
      Home: home,
      Auth: auth,
      Dashboard: dashboard,
      NotFound: notFound,
    }
  };
});
