# AFAB Frontend Technical Specification

Version: 1.0

## 1. Technology Stack

-   Next.js 15 (App Router)
-   TypeScript
-   Tailwind CSS v4
-   shadcn/ui
-   Zustand
-   TanStack Query
-   React Hook Form
-   Zod
-   next-intl
-   next-themes
-   Framer Motion
-   Recharts
-   Lucide React

------------------------------------------------------------------------

# 2. Project Structure

``` text
src/
├── app/
│   ├── (marketing)/
│   ├── (auth)/
│   ├── (dashboard)/
│   ├── api/
│   ├── layout.tsx
│   └── globals.css
├── components/
│   ├── ui/
│   ├── layout/
│   ├── cards/
│   ├── charts/
│   ├── tables/
│   └── forms/
├── features/
│   ├── dashboard/
│   ├── invoices/
│   ├── reports/
│   ├── settings/
│   └── ai/
├── hooks/
├── lib/
├── services/
├── store/
├── types/
├── utils/
└── i18n/
```

## 3. Route Groups

-   (marketing)
-   (auth)
-   (dashboard)

Dashboard routes: - /dashboard - /transactions - /expenses - /revenue -
/invoices - /customers - /reports - /ai-assistant - /calendar - /team -
/settings/\*

------------------------------------------------------------------------

## 4. Layout Hierarchy

RootLayout → ThemeProvider → IntlProvider → QueryProvider → AuthProvider
→ DashboardLayout → Sidebar → Header → Page

------------------------------------------------------------------------

## 5. State Management

### Zustand

Use for: - User session - Sidebar state - Theme UI state -
Notifications - Filters

### TanStack Query

Use for: - Server data - Caching - Pagination - Mutations - Background
refresh

------------------------------------------------------------------------

## 6. API Layer

services/ - auth.ts - dashboard.ts - invoices.ts - reports.ts -
settings.ts - ai.ts

Each service exposes: - getAll() - getById() - create() - update() -
delete()

------------------------------------------------------------------------

## 7. Authentication

Flow: Login → JWT/Session → Protected Routes → Dashboard

Protected pages redirect to Login.

------------------------------------------------------------------------

## 8. Internationalization

Languages: - English (default) - Arabic

Structure: i18n/ - en.json - ar.json

Use translation keys only.

------------------------------------------------------------------------

## 9. Theme Architecture

Themes: - Light - Dark - System

Persist user preference.

------------------------------------------------------------------------

## 10. Forms

Library: React Hook Form

Validation: Zod

Rules: - Client validation - Server validation - Inline errors

------------------------------------------------------------------------

## 11. Error Handling

States: - Loading - Empty - Success - Error

Display: - Skeletons - Toasts - Error cards

------------------------------------------------------------------------

## 12. Performance

-   Server Components by default
-   Client Components only when interactive
-   Dynamic imports
-   Lazy charts
-   Image optimization
-   Route prefetching

------------------------------------------------------------------------

## 13. Security

-   Never expose secrets
-   Validate all input
-   Escape HTML
-   CSRF protection (backend)
-   Secure cookies
-   Role-based UI

------------------------------------------------------------------------

## 14. Coding Standards

-   Strict TypeScript
-   ESLint
-   Prettier
-   PascalCase components
-   camelCase variables
-   Feature-first organization

------------------------------------------------------------------------

## 15. Testing

Unit: - Vitest

Component: - React Testing Library

E2E: - Playwright

------------------------------------------------------------------------

## 16. Deployment Checklist

-   Production build passes
-   No TypeScript errors
-   No ESLint errors
-   Lighthouse \>90
-   Responsive verified
-   RTL verified
-   Accessibility checked
-   Theme switching verified
-   API endpoints connected
