# AFAB Next.js Project Blueprint

Version: 1.0

## Objective

This blueprint defines the complete frontend project structure for AFAB.
It serves as the implementation roadmap for a scalable, production-ready
Next.js application.

------------------------------------------------------------------------

# Recommended Folder Structure

``` text
src/
├── app/
│   ├── (marketing)/
│   │   ├── page.tsx
│   │   ├── pricing/
│   │   ├── about/
│   │   └── contact/
│   ├── (auth)/
│   │   ├── login/
│   │   ├── signup/
│   │   ├── forgot-password/
│   │   └── reset-password/
│   ├── (dashboard)/
│   │   ├── dashboard/
│   │   ├── transactions/
│   │   ├── expenses/
│   │   ├── revenue/
│   │   ├── invoices/
│   │   ├── customers/
│   │   ├── reports/
│   │   ├── ai-assistant/
│   │   ├── calendar/
│   │   ├── team/
│   │   └── settings/
│   ├── layout.tsx
│   ├── loading.tsx
│   ├── error.tsx
│   └── globals.css
│
├── components/
│   ├── layout/
│   ├── ui/
│   ├── forms/
│   ├── cards/
│   ├── charts/
│   ├── tables/
│   ├── dashboard/
│   ├── settings/
│   ├── ai/
│   └── shared/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── invoices/
│   ├── reports/
│   ├── settings/
│   └── ai/
│
├── hooks/
├── lib/
├── providers/
├── services/
├── store/
├── types/
├── utils/
├── constants/
├── config/
├── i18n/
└── styles/
```

------------------------------------------------------------------------

# Core Providers

-   ThemeProvider
-   QueryProvider
-   AuthProvider
-   IntlProvider
-   ToastProvider

------------------------------------------------------------------------

# Global Layout

RootLayout

↓

ThemeProvider

↓

IntlProvider

↓

QueryProvider

↓

DashboardLayout

↓

Sidebar

↓

TopNavbar

↓

Page Content

------------------------------------------------------------------------

# Services

Each module has its own service.

Examples

-   auth.service.ts
-   dashboard.service.ts
-   invoice.service.ts
-   report.service.ts
-   ai.service.ts
-   settings.service.ts

------------------------------------------------------------------------

# Hooks

Global hooks

-   useAuth()
-   useTheme()
-   useLanguage()
-   usePagination()
-   useDebounce()
-   useModal()
-   useToast()

Feature hooks

-   useDashboard()
-   useTransactions()
-   useInvoices()
-   useReports()
-   useAI()

------------------------------------------------------------------------

# Zustand Stores

-   auth.store.ts
-   sidebar.store.ts
-   notification.store.ts
-   theme.store.ts
-   settings.store.ts

------------------------------------------------------------------------

# Constants

-   routes.ts
-   roles.ts
-   permissions.ts
-   currencies.ts
-   dateFormats.ts

------------------------------------------------------------------------

# Configuration

-   env.ts
-   navigation.ts
-   theme.ts
-   query.ts

------------------------------------------------------------------------

# Translation Files

i18n/ - en.json - ar.json

Namespaces

-   common
-   auth
-   dashboard
-   settings
-   ai
-   invoices

------------------------------------------------------------------------

# Build Order

Phase 1 - Project setup - Tailwind - shadcn/ui - Theme - i18n

Phase 2 - Authentication - Dashboard layout - Sidebar - Navbar

Phase 3 - Shared UI components - Forms - Tables - Charts

Phase 4 - Dashboard pages

Phase 5 - Settings pages

Phase 6 - AI Assistant

Phase 7 - Responsive optimization

Phase 8 - Accessibility

Phase 9 - Performance optimization

Phase 10 - Testing - Deployment

------------------------------------------------------------------------

# Coding Rules

-   Strict TypeScript
-   Feature-first organization
-   Server Components by default
-   Client Components only when needed
-   Shared UI in components/
-   Business logic in hooks/services
-   No duplicated code

------------------------------------------------------------------------

# Definition of Done

Before a feature is complete:

-   Type-safe
-   Responsive
-   Accessible
-   Theme-aware
-   Translated
-   Tested
-   Connected to API
-   Performance optimized
-   Lint passes
-   Build passes
