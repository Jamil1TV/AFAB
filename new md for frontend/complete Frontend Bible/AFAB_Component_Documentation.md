# AFAB Component Documentation

Version: 1.0

## Purpose

This document defines the reusable component library for AFAB. Every
screen should be composed from these components.

------------------------------------------------------------------------

# Component Standards

Every component must include: - TypeScript interface - Light & Dark mode
support - Responsive behavior - Loading state - Empty/Error state where
applicable - Accessibility (WCAG AA) - Story/demo example - Unit tests

Folder pattern:

    components/<category>/<ComponentName>/
    ├── ComponentName.tsx
    ├── ComponentName.types.ts
    ├── ComponentName.test.tsx
    ├── ComponentName.stories.tsx
    └── index.ts

------------------------------------------------------------------------

# Layout Components

## AppShell

Purpose: Global application layout.

Props: - children - title - showRightPanel - breadcrumbs

Contains: - Sidebar - TopNavbar - Content - RightPanel (optional)

------------------------------------------------------------------------

## Sidebar

Variants: - Expanded - Collapsed - Mobile Drawer

Features: - Active item - Tooltips - Collapse - User profile - Theme
toggle

------------------------------------------------------------------------

## TopNavbar

Sections: - Breadcrumbs - Global Search - AI Shortcut - Notifications -
Theme Switch - Language Switch - User Menu

------------------------------------------------------------------------

# Navigation Components

-   Breadcrumbs
-   NavItem
-   UserDropdown
-   CommandPalette
-   SearchBar

------------------------------------------------------------------------

# Button Components

Variants: - Primary - Secondary - Ghost - Outline - Success - Danger -
Icon - FAB

Sizes: - sm - md - lg

States: - Default - Hover - Focus - Active - Disabled - Loading

------------------------------------------------------------------------

# Form Components

-   Input
-   PasswordInput
-   SearchInput
-   CurrencyInput
-   NumberInput
-   TextArea
-   Select
-   MultiSelect
-   Combobox
-   Checkbox
-   RadioGroup
-   Switch
-   DatePicker
-   FileUploader

Validation: React Hook Form + Zod

------------------------------------------------------------------------

# Card Components

-   StatCard
-   ChartCard
-   InsightCard
-   InvoiceCard
-   CustomerCard
-   TeamCard
-   IntegrationCard
-   PricingCard
-   EmptyStateCard

Shared props: - title - icon - children - actions

------------------------------------------------------------------------

# Table Components

## DataTable

Features: - Sorting - Filtering - Pagination - Bulk Actions - Row
Selection - Sticky Header - Column Visibility

Reusable in: - Transactions - Customers - Invoices - Team - Reports

------------------------------------------------------------------------

# Chart Components

Library: Recharts

Components: - RevenueChart - ExpenseChart - CashFlowChart -
ProfitChart - ForecastChart - DonutChart

Shared Props: - data - loading - height - dateRange

------------------------------------------------------------------------

# Feedback Components

-   Toast
-   Alert
-   Modal
-   Drawer
-   ConfirmationDialog
-   EmptyState
-   Skeleton
-   Spinner
-   ProgressBar

------------------------------------------------------------------------

# AI Components

-   ChatWindow
-   ChatMessage
-   SuggestionCard
-   PromptInput
-   VoiceButton
-   TypingIndicator
-   AIInsightCard

------------------------------------------------------------------------

# Settings Components

-   ThemeSelector
-   LanguageSelector
-   IntegrationCard
-   PermissionMatrix
-   NotificationPreference
-   SecurityCard

------------------------------------------------------------------------

# Dashboard Widgets

-   KPIGrid
-   RecentTransactions
-   UpcomingInvoices
-   ExpenseBreakdown
-   RevenueSummary
-   TeamActivity
-   BusinessHealthCard

------------------------------------------------------------------------

# Accessibility Checklist

Every component: - Keyboard accessible - Visible focus - Screen-reader
labels - Proper ARIA attributes - Color contrast compliant

------------------------------------------------------------------------

# Naming Convention

Components: PascalCase

Hooks: useSomething

Stores: useSomethingStore

Types: SomethingProps SomethingResponse

------------------------------------------------------------------------

# Composition Rules

Prefer composition over inheritance.

Keep components: - Small - Reusable - Stateless when possible

Business logic belongs in hooks/services, not UI components.

------------------------------------------------------------------------

# Definition of Done

A reusable component is complete when: - Fully typed - Tested -
Accessible - Responsive - Theme-aware - Documented - Used in at least
one page
