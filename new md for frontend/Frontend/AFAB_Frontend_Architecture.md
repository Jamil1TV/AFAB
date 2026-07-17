# AFAB Frontend Architecture

## Tech Stack

-   Next.js 15 (App Router)
-   TypeScript
-   Tailwind CSS v4
-   shadcn/ui
-   Zustand
-   TanStack Query
-   React Hook Form + Zod
-   next-intl
-   next-themes
-   Framer Motion
-   Recharts

## Folder Structure

``` text
app/
  (marketing)/
    page.tsx
    pricing/
    about/
  (auth)/
    login/
    signup/
    forgot-password/
  (dashboard)/
    dashboard/
    transactions/
    expenses/
    revenue/
    invoices/
    customers/
    reports/
    ai-assistant/
    calendar/
    team/
    settings/
      business-profile/
      subscription/
      users/
      notifications/
      security/
      integrations/
      data-export/
      appearance/
      language/
components/
  layout/
  cards/
  charts/
  forms/
  tables/
  ui/
hooks/
lib/
services/
store/
types/
```

## Layout Hierarchy

RootLayout → ThemeProvider → IntlProvider → DashboardLayout → Sidebar →
Header → Page Content → Right Widgets
