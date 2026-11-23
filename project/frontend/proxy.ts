import createMiddleware from 'next-intl/middleware';
import { routing } from './i18n/routing';
import { NextRequest, NextResponse } from 'next/server';

const intlMiddleware = createMiddleware(routing);

export function proxy(req: NextRequest) {
  // Check non-sensitive session-presence cookie (afab_csrf).
  // Refresh tokens are HttpOnly on /api/v1 and access tokens live in JS memory only.
  // Backend Spring Security strictly enforces JWT authorization on every API call.
  const hasSessionCookie = Boolean(req.cookies.get('afab_csrf')?.value);
  const { pathname } = req.nextUrl;

  // Extract locale from the path if present, otherwise use default
  const segments = pathname.split('/');
  const localeSegment = segments[1];
  const hasLocale = (routing.locales as readonly string[]).includes(localeSegment);
  const locale = hasLocale ? localeSegment : routing.defaultLocale;

  // Define route types
  const isDashboardRoute = pathname.includes('/dashboard');
  const isOnboardingRoute = pathname.includes('/onboarding');
  const isSettingsRoute = pathname.includes('/settings');
  const isHomeRoute = pathname === '/' || (hasLocale && pathname === `/${locale}`);

  // Protected routes require authentication
  const isProtectedRoute = isDashboardRoute || isOnboardingRoute || isSettingsRoute;

  // 1. Logged out user attempting to access a protected route -> redirect to login
  if (isProtectedRoute && !hasSessionCookie) {
    const loginUrl = new URL(`/${locale}/login`, req.url);
    return NextResponse.redirect(loginUrl);
  }

  // 2. Logged in user attempting to access root landing page -> redirect to dashboard
  if (isHomeRoute && hasSessionCookie) {
    const dashboardUrl = new URL(`/${locale}/dashboard`, req.url);
    return NextResponse.redirect(dashboardUrl);
  }

  // Continue with next-intl routing
  return intlMiddleware(req);
}

export default proxy;

export const config = {
  // Match all pathnames except internal Next.js paths and static files
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)'],
};
