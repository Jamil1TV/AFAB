# AFAB TypeScript Interfaces

Version: 1.0

## Purpose

This document defines the TypeScript models for the AFAB frontend. These
interfaces should live under `src/types/` and be shared across features.

------------------------------------------------------------------------

# Shared Types

``` ts
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  hasNext: boolean;
}
```

------------------------------------------------------------------------

# User

``` ts
export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  avatar?: string;
  role: UserRole;
  businessId: string;
  createdAt: string;
}
```

``` ts
export type UserRole =
  | "owner"
  | "admin"
  | "manager"
  | "accountant"
  | "viewer";
```

------------------------------------------------------------------------

# Business

``` ts
export interface Business {
  id: string;
  name: string;
  logo?: string;
  industry: string;
  currency: string;
  timezone: string;
  country: string;
  city: string;
}
```

------------------------------------------------------------------------

# Transaction

``` ts
export interface Transaction {
  id: string;
  type: "income" | "expense" | "transfer" | "refund";
  category: string;
  description: string;
  amount: number;
  currency: string;
  status: "pending" | "completed" | "failed";
  date: string;
}
```

------------------------------------------------------------------------

# Expense

``` ts
export interface Expense {
  id: string;
  vendor: string;
  category: string;
  amount: number;
  receiptUrl?: string;
  recurring: boolean;
}
```

------------------------------------------------------------------------

# Revenue

``` ts
export interface RevenueSummary {
  totalRevenue: number;
  monthlyRevenue: number;
  mrr: number;
  arr: number;
}
```

------------------------------------------------------------------------

# Invoice

``` ts
export interface Invoice {
  id: string;
  invoiceNumber: string;
  customerId: string;
  issueDate: string;
  dueDate: string;
  total: number;
  status: "draft" | "sent" | "paid" | "overdue";
}
```

------------------------------------------------------------------------

# Customer

``` ts
export interface Customer {
  id: string;
  name: string;
  email: string;
  phone?: string;
  totalRevenue: number;
}
```

------------------------------------------------------------------------

# Report

``` ts
export interface Report {
  id: string;
  type: string;
  generatedAt: string;
  downloadUrl: string;
}
```

------------------------------------------------------------------------

# AI

``` ts
export interface AIMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  createdAt: string;
}

export interface AIConversation {
  id: string;
  messages: AIMessage[];
}
```

------------------------------------------------------------------------

# Calendar

``` ts
export interface CalendarEvent {
  id: string;
  title: string;
  start: string;
  end: string;
  type: "meeting" | "invoice" | "payroll" | "tax";
}
```

------------------------------------------------------------------------

# Team

``` ts
export interface TeamMember {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  status: "active" | "invited";
}
```

------------------------------------------------------------------------

# Notifications

``` ts
export interface NotificationSettings {
  email: boolean;
  push: boolean;
  inApp: boolean;
  quietHours: boolean;
}
```

------------------------------------------------------------------------

# Subscription

``` ts
export interface Subscription {
  plan: "free" | "pro";
  status: "active" | "cancelled" | "trial";
  renewalDate: string;
}
```

------------------------------------------------------------------------

# Integration

``` ts
export interface Integration {
  id: string;
  name: string;
  connected: boolean;
  lastSync?: string;
}
```

------------------------------------------------------------------------

# Settings

``` ts
export interface AppearanceSettings {
  theme: "light" | "dark" | "system";
  primaryColor: string;
  font: string;
}

export interface LanguageSettings {
  language: "en" | "ar";
  rtl: boolean;
}
```

------------------------------------------------------------------------

# Filter Types

``` ts
export interface DateRange {
  startDate: string;
  endDate: string;
}

export interface TableFilters {
  search?: string;
  status?: string;
  category?: string;
}
```

------------------------------------------------------------------------

# Folder Layout

``` text
src/types/
├── api.ts
├── auth.ts
├── business.ts
├── customer.ts
├── invoice.ts
├── report.ts
├── transaction.ts
├── team.ts
├── ai.ts
├── settings.ts
├── calendar.ts
└── index.ts
```
