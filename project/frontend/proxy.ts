import createMiddleware from 'next-intl/middleware';
import { routing } from './i18n/routing';
import { NextRequest, NextResponse } from 'next/server';

const intlMiddleware = createMiddleware(routing);

export default function proxy(req: NextRequest) {
  const token = req.cookies.get('accessToken')?.value;
  const { pathname } = req.nextUrl;

  // Protect the dashboard routes
  const isDashboardRoute = pathname.includes('/dashboard');

  if (isDashboardRoute && !token) {
    // Extract locale or fallback to default
    const segments = pathname.split('/');
    const locale = (segments[1] === 'ar' || segments[1] === 'en') ? segments[1] : routing.defaultLocale;
    
    const loginUrl = new URL(`/${locale}/login`, req.url);
    return NextResponse.redirect(loginUrl);
  }

  // Continue with next-intl routing
  return intlMiddleware(req);
}

export const config = {
  // Match all pathnames to allow next-intl and auth proxy to catch bare routes like /dashboard and /login
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)']
};
