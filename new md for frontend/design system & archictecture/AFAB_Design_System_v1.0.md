# AFAB Design System v1.0

## Product

**AFAB --- AI Finance Assistant for Business**

## Product Style

-   Industry: FinTech + AI SaaS
-   Inspiration: Stripe, Linear, Notion, Vercel, Ramp, Brex, Mercury,
    Raycast
-   Keywords: Premium, Modern, Clean, Minimal, Intelligent

## Design Philosophy

-   Large white space
-   Rounded cards
-   Soft shadows
-   Purple primary accent
-   High readability
-   Apple × Stripe aesthetic

## Layout

-   Left Sidebar: **240px**
-   Main Content: **Flexible**
-   Right Widget Panel: **320px (optional)**

Typical page: 1. Header 2. KPI Cards 3. Main Content 4. Right Widgets

## Border Radius

  Element          Radius
  -------------- --------
  Cards              20px
  Buttons            14px
  Inputs             12px
  Tables             16px
  Charts             20px
  Pills/Badges     9999px

## Shadows

### Light

``` css
box-shadow: 0 8px 30px rgba(15,23,42,.06);
```

### Hover

``` css
box-shadow: 0 12px 40px rgba(99,102,241,.15);
```

### Dark

Use subtle borders instead of shadows.

## Borders

Light: `#ECEEF5`

Dark: `#232533`

------------------------------------------------------------------------

# Color Palette

## Primary

  Purpose     Color
  ----------- ---------
  Primary     #6C4CF5
  Hover       #5B3FF0
  Active      #4A31D9
  Secondary   #8B5CF6
  Accent      #A78BFA

## Semantic

| Success \| #22C55E \|
| Warning \| #F59E0B \|
| Error \| #EF4444 \|
| Info \| #3B82F6 \|

## Light Theme

  Item             Color
  ---------------- ---------
  Background       #FFFFFF
  Secondary BG     #F7F8FC
  Sidebar          #FCFCFE
  Cards            #FFFFFF
  Primary Text     #111827
  Secondary Text   #6B7280
  Muted Text       #9CA3AF

## Dark Theme

  Item             Color
  ---------------- ---------
  Background       #0B1020
  Sidebar          #0E1525
  Cards            #111827
  Secondary BG     #1A2235
  Primary Text     #F8FAFC
  Secondary Text   #CBD5E1
  Muted Text       #94A3B8

# Typography

## Fonts

Primary: **Inter**

Landing/Hero: **Plus Jakarta Sans**

Monospace: **JetBrains Mono**

## Sizes

  Usage             Size
  --------------- ------
  Hero              48px
  Page Title        36px
  KPI Numbers       30px
  Section Title     24px
  Card Title        20px
  Table Header      18px
  Body              16px
  Label             14px
  Helper            12px

# Icons

Use **Lucide React**

Dashboard, Wallet, Receipt, ChartColumn, Users, Settings, Sparkles,
Calendar, Shield, Bell, Download, Upload, Languages, Moon, Sun.

# Charts

-   Line
-   Area
-   Bar
-   Donut/Pie

No 3D charts.

# Buttons

-   Primary
-   Secondary (outline)
-   Ghost
-   Danger
-   Success
-   Icon Button
-   FAB

# Sidebar

1.  Dashboard
2.  Transactions
3.  Expenses
4.  Revenue
5.  Invoices
6.  Customers
7.  Reports
8.  AI Assistant
9.  Calendar
10. Team
11. Settings

# Settings Pages

1.  General
2.  Business Profile
3.  Subscription & Billing
4.  Users & Permissions
5.  Notifications
6.  Security
7.  Integrations
8.  Data & Export
9.  Appearance
10. Language

# FinTech Logic

## Dashboard

Revenue, Expenses, Profit, Cash Flow, Invoices, Savings, AI Insights.

## Transactions

Income, Expense, Transfer, Refund, Search, Filter, Export.

## Expenses

Categories, Receipts, Taxes, Recurring, Budgets.

## Revenue

Revenue Trends, MRR, ARR, Top Customers, Forecasts.

## Invoices

Create, Send, Status, Download PDF.

## Customers

CRM, Revenue, Timeline, Notes.

## Reports

P&L, Cash Flow, Balance Sheet, Tax Reports, AI Summary.

## AI Assistant

-   Chat
-   Voice
-   Predictions
-   Recommendations
-   Financial Q&A
-   Report Generation
-   Invoice Creation
-   Expense Classification

Free Plan: - Limited AI requests - Upgrade prompts

Pro Plan (\$9.99/month): - Unlimited AI - Forecasting - Advanced
Reports - Business Health Analysis - Smart Automations

## Calendar

Meetings, Due Invoices, Payroll, Taxes, Reminders.

## Team

Roles, Permissions, Invitations, Activity Log.

## Business Profile

Business Name, Industry, Currency, Tax Number, Logo, Timezone.

## Subscription

Plan, Usage, Payment Method, Billing History.

## Users

Owner, Admin, Manager, Accountant, Viewer.

## Notifications

Email, Push, In-App, Quiet Hours.

## Security

2FA, Password, Devices, Sessions, Login Alerts.

## Integrations

QuickBooks, Stripe, Slack, Zapier, PayPal, Xero, Google Drive, HubSpot,
Mailchimp.

## Data & Export

CSV, Excel, PDF, JSON, Audit Logs, Retention, Delete Data.

## Appearance

Theme, Primary Color, Font, Sidebar Style, Logo, Motion.

## Language

English (Default), Arabic (RTL), Regional Preferences.

# Reusable Components

## Layout

-   Sidebar
-   SettingsSidebar
-   TopNavbar
-   PageHeader
-   Breadcrumbs

## UI

-   Button
-   Input
-   PasswordInput
-   Select
-   Switch
-   Checkbox
-   Radio
-   DatePicker
-   Modal
-   Drawer
-   Toast

## Cards

-   StatCard
-   InsightCard
-   ChartCard
-   QuickActionCard
-   EmptyStateCard

## Data

-   DataTable
-   StatusBadge
-   Avatar
-   UserCard
-   ActivityTimeline
-   ProgressBar

## Charts

-   RevenueChart
-   ExpenseChart
-   CashFlowChart
-   DonutChart

# Recommended Next.js Stack

-   Next.js 15 (App Router)
-   TypeScript
-   Tailwind CSS v4
-   shadcn/ui
-   Lucide React
-   Recharts
-   TanStack Table
-   React Hook Form
-   Zod
-   Zustand
-   TanStack Query
-   next-themes
-   next-intl
-   Framer Motion
-   date-fns

# Final Goal

Build AFAB as a premium FinTech AI platform with a consistent design
language across authentication, landing page, dashboard, and all
management pages in both Light and Dark modes.
