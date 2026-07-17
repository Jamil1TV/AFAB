# AFAB Complete Frontend Bible (Part 1)

> Version: 1.0\
> Project: AFAB --- AI Finance Assistant for Business

------------------------------------------------------------------------

# Purpose

This document is the master reference for building the AFAB frontend
with Next.js.

Goals:

-   Maintain a consistent UI across all pages.
-   Define reusable patterns before implementation.
-   Ensure every screen follows the same design language.
-   Minimize duplicated code.

------------------------------------------------------------------------

# Core Principles

1.  Premium FinTech look and feel.
2.  Minimal interfaces with generous whitespace.
3.  Accessibility first (WCAG AA).
4.  Mobile-ready, desktop-first.
5.  Every UI element is reusable.
6.  Light and Dark modes must have identical layouts.
7.  Arabic (RTL) and English (LTR) are first-class citizens.

------------------------------------------------------------------------

# Global Layout

## Marketing

-   Landing Page
-   Pricing
-   About
-   Contact

## Authentication

-   Login
-   Sign Up
-   Forgot Password
-   Reset Password

## Dashboard

-   Dashboard
-   Transactions
-   Expenses
-   Revenue
-   Invoices
-   Customers
-   Reports
-   AI Assistant
-   Calendar
-   Team
-   Settings

------------------------------------------------------------------------

# Global Grid

Desktop: - Sidebar: 240px - Content: Flexible - Right Panel: 320px
(optional)

Tablet: - Collapsible sidebar

Mobile: - Drawer navigation

------------------------------------------------------------------------

# Global Navigation

Primary Sidebar (11 pages)

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

Settings Navigation

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

------------------------------------------------------------------------

# Page Blueprint

Every page follows:

1.  Page Header
2.  Breadcrumb (optional)
3.  KPI cards (if applicable)
4.  Filters / Search
5.  Main content
6.  Secondary widgets
7.  Footer actions

------------------------------------------------------------------------

# Global States

Every page must define:

-   Default
-   Loading
-   Empty
-   Error
-   Success
-   Offline (future)

------------------------------------------------------------------------

# Authentication Rules

Login: - Email - Password - Remember me - Forgot password

Sign Up: - First Name - Last Name - Email - Password (minimum 8
characters) - Business Name

------------------------------------------------------------------------

# Theme Rules

-   next-themes
-   Default: Light
-   Persist user preference
-   System mode optional

------------------------------------------------------------------------

# Internationalization

Supported Languages:

-   English (default)
-   Arabic (RTL)

Use next-intl for all text.

------------------------------------------------------------------------

# Next Sections

The following parts will cover:

-   Component specifications
-   Every dashboard page
-   Every settings page
-   Responsive behavior
-   Accessibility
-   Animation system
-   API integration strategy
-   Coding standards
