import createMiddleware from 'next-intl/middleware';
import { routing } from './i18n/routing';
import { NextRequest, NextResponse } from 'next/server';

const intlMiddleware = createMiddleware(routing);

export default function middleware(req: NextRequest) {
  const token = req.cookies.get('accessToken')?.value;
  const { pathname } = req.nextUrl;

  // Extract locale from the path if present, otherwise use default
  const segments = pathname.split('/');
  const localeSegment = segments[1];
  const hasLocale = routing.locales.includes(localeSegment as any);
  const locale = hasLocale ? localeSegment : routing.defaultLocale;

  // Define route types
  const isDashboardRoute = pathname.includes('/dashboard');
  const isOnboardingRoute = pathname.includes('/onboarding');
  const isSettingsRoute = pathname.includes('/settings');
  const isAuthRoute = pathname.includes('/login') || pathname.includes('/signup');
  const isHomeRoute = pathname === '/' || (hasLocale && pathname === `/${locale}`);
  
  // Protected routes require authentication
  const isProtectedRoute = isDashboardRoute || isOnboardingRoute || isSettingsRoute;

  // 1. Logged out user attempting to access a protected route
  if (isProtectedRoute && !token) {
    const loginUrl = new URL(`/${locale}/login`, req.url);
    return NextResponse.redirect(loginUrl);
  }

  // 2. Logged in user attempting to access auth or home page
  if ((isAuthRoute || isHomeRoute) && token) {
    const dashboardUrl = new URL(`/${locale}/dashboard`, req.url);
    return NextResponse.redirect(dashboardUrl);
  }

  // Continue with next-intl routing
  return intlMiddleware(req);
}

export const config = {
  // Match all pathnames except internal Next.js paths and static files
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)']
};
