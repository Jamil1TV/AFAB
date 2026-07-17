# AFAB Complete Frontend Bible --- Part 3

# Dashboard Module Specification

## Overview

This document specifies every primary dashboard page in AFAB. Each page
follows the same structure:

1.  Page Header
2.  KPI Cards
3.  Filters/Search
4.  Main Content
5.  Secondary Widgets
6.  Quick Actions

------------------------------------------------------------------------

# 1. Dashboard

## Purpose

Provide an executive overview of the business.

## KPI Cards

-   Total Revenue
-   Total Expenses
-   Net Profit
-   Cash Flow
-   Outstanding Invoices
-   AI Business Health Score

## Charts

-   Revenue vs Expenses (Line)
-   Cash Flow (Area)
-   Revenue by Month (Bar)
-   Expense Categories (Donut)

## Widgets

-   Recent Transactions
-   Upcoming Invoice Deadlines
-   AI Recommendations
-   Team Activity

## Quick Actions

-   Create Invoice
-   Add Transaction
-   Upload Receipt
-   Open AI Assistant

States: - Loading Skeleton - Empty Business - Error - Success

------------------------------------------------------------------------

# 2. Transactions

Purpose: Manage every financial transaction.

Columns - Date - Description - Category - Account - Amount - Status

Actions - Search - Filter - Sort - Export CSV - Export Excel - Add
Transaction - Edit - Delete

Filters - Date Range - Category - Payment Method - Amount - Status

------------------------------------------------------------------------

# 3. Expenses

Purpose Track business spending.

Dashboard Widgets - Total Expenses - Monthly Budget - Budget Remaining -
Largest Expense

Charts - Spending by Category - Monthly Trend

Features - Receipt Upload - Tax Flag - Recurring Expense - Vendor

------------------------------------------------------------------------

# 4. Revenue

KPIs - MRR - ARR - Gross Revenue - Average Order Value

Charts - Monthly Revenue - Revenue Sources - Forecast

Widgets - Top Customers - Best Products

------------------------------------------------------------------------

# 5. Invoices

Functions - Create Invoice - Duplicate - Download PDF - Send Email -
Mark Paid

Statuses - Draft - Sent - Paid - Overdue - Cancelled

Table - Client - Number - Issue Date - Due Date - Total - Status

------------------------------------------------------------------------

# 6. Customers

Purpose Mini CRM.

Customer Card - Avatar - Name - Email - Revenue - Active Invoices

Profile - Timeline - Notes - Contact Info - Invoice History

------------------------------------------------------------------------

# 7. Reports

Available Reports - Profit & Loss - Cash Flow - Balance Sheet - Expense
Report - Revenue Report - Tax Summary

Features - Date Filters - Export PDF - Export Excel - AI Summary

------------------------------------------------------------------------

# 8. AI Assistant

Modes - Chat - Voice - Document Analysis

Capabilities - Financial Q&A - Forecasting - Expense Classification -
Report Generation - Invoice Drafting

Free Plan - Daily limit - Upgrade Banner

Pro - Unlimited AI - Advanced Insights

------------------------------------------------------------------------

# 9. Calendar

Views - Month - Week - Day

Events - Invoice Due - Payroll - Meetings - Taxes - Custom Reminder

------------------------------------------------------------------------

# 10. Team

Roles - Owner - Admin - Manager - Accountant - Viewer

Features - Invite Member - Edit Role - Remove Member - Activity Log

------------------------------------------------------------------------

# Shared Responsive Rules

Desktop - Three-column dashboard where applicable.

Tablet - Two-column layout. - Sidebar collapses.

Mobile - Single-column cards. - Drawer navigation. - Sticky action
button.

------------------------------------------------------------------------

# API Requirements

Every page should support: - Pagination - Search - Sorting - Filtering -
Optimistic updates - Loading state - Error state - Empty state

------------------------------------------------------------------------

# Performance

-   Lazy-load charts
-   Virtualize long tables
-   Server Components where possible
-   Client Components only for interactive UI
-   Cache server data with TanStack Query
