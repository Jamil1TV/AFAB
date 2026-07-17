# AFAB Complete Frontend Bible --- Part 2

## Reusable Components Specification

## Philosophy

Every page in AFAB should be assembled from reusable components. Avoid
page-specific UI whenever possible.

------------------------------------------------------------------------

# Layout Components

## AppShell

Responsible for: - Sidebar - Top Navbar - Content Container - Optional
Right Widget Panel

Props: - children - showRightPanel - pageTitle

------------------------------------------------------------------------

## Sidebar

Features: - 11 navigation items - Active state - Collapse/Expand - User
profile - Theme switch - Notifications shortcut

States: - Expanded - Collapsed - Mobile Drawer

------------------------------------------------------------------------

## Settings Sidebar

Contains: - General - Business Profile - Subscription & Billing - Users
& Permissions - Notifications - Security - Integrations - Data &
Export - Appearance - Language

------------------------------------------------------------------------

## Top Navbar

Contains: - Breadcrumbs - Search - AI Quick Action - Notification Bell -
Theme Toggle - Language Switch - User Avatar

------------------------------------------------------------------------

# Card Components

## StatCard

Displays: - Icon - Title - Main Value - Trend (+/-) - Comparison text

Variants: - Revenue - Expense - Profit - Invoice - Customer - AI Insight

------------------------------------------------------------------------

## InsightCard

Contains: - AI recommendation - Confidence badge - Action button

------------------------------------------------------------------------

## ChartCard

Supports: - Line - Area - Bar - Donut

Shared actions: - Filter - Export - Fullscreen

------------------------------------------------------------------------

# Form Components

-   Input
-   PasswordInput
-   SearchInput
-   NumberInput
-   CurrencyInput
-   TextArea
-   Select
-   MultiSelect
-   DatePicker
-   FileUploader
-   Switch
-   Checkbox
-   RadioGroup

Validation: - React Hook Form - Zod

------------------------------------------------------------------------

# Table Components

## DataTable

Features: - Sorting - Filtering - Pagination - Bulk Actions - Export -
Responsive

Used in: - Transactions - Customers - Invoices - Team

------------------------------------------------------------------------

# Feedback Components

-   Toast
-   Alert
-   Modal
-   Drawer
-   Confirmation Dialog
-   Empty State
-   Loading Skeleton

------------------------------------------------------------------------

# AI Components

## Chat Window

-   Messages
-   Suggestions
-   Voice Button
-   File Upload
-   Typing Indicator

## AI Insight Card

Displays: - Recommendation - Estimated impact - Confidence score

------------------------------------------------------------------------

# Navigation Patterns

Every page should contain: 1. Page Title 2. Optional Breadcrumb 3.
Primary Action 4. Filters 5. Main Content

------------------------------------------------------------------------

# Theme Rules

Light and Dark mode must: - Use identical spacing - Use identical
typography - Preserve hierarchy - Only colors change

------------------------------------------------------------------------

# Motion

Use Framer Motion.

Standard durations: - Hover: 150ms - Page transition: 250ms - Modal:
200ms - Drawer: 250ms

Animations: - Fade - Slide - Scale Never use excessive motion.

------------------------------------------------------------------------

# Accessibility

Every reusable component must support: - Keyboard navigation - Focus
ring - Screen readers - Proper labels - WCAG AA contrast

------------------------------------------------------------------------

# Component Naming

Use PascalCase.

Examples: - DashboardHeader - RevenueChart - CustomerTable -
NotificationDrawer - ThemeSwitcher - LanguageSelector - InvoiceCard -
StatCard
