# AFAB Project Summary

## Overview

**AFAB (AI Finance Assistant)** is a modern AI-ready personal finance
platform. The MVP focuses on finance management only. AI capabilities
will be added in a future phase.

------------------------------------------------------------------------

# Brand Identity

A complete branding package has been created using Leonardo AI.

## Assets

-   Primary Logo
-   Secondary Logo
-   App Icon
-   Logo Mark
-   Color Palette
-   Typography
-   UI Style
-   Brand Elements

## Design Style

-   Modern FinTech
-   Premium SaaS
-   Apple-inspired minimalism
-   Stripe / Linear / Notion aesthetics
-   Rounded UI
-   Clean dashboards
-   Data-first interface

## Brand Colors

  Role         Color
  ------------ -----------
  Primary      `#0A2540`
  Secondary    `#2563EB`
  Accent       `#10B981`
  White        `#FFFFFF`
  Dark Gray    `#1F2937`
  Light Gray   `#F5F7FA`

**Typography:** Inter

------------------------------------------------------------------------

# Technology Stack

## Backend

-   Spring Boot 4.1
-   Java 21 (LTS)
-   PostgreSQL 18
-   Spring Security (JWT)
-   REST API
-   Spring Data JPA (Hibernate), native SQL for reporting queries
-   Flyway migrations

## Frontend

-   Next.js 16 (App Router)
-   shadcn/ui
-   Tailwind CSS
-   TanStack Query (client-side server-state) + React Server Components
-   React Hook Form
-   Zod
-   lucide-react
-   Recharts (via shadcn charts)

No global client-side store (Redux) is used. Server state lives in TanStack Query; UI-only state uses React state/context, with a small Zustand store only if a specific cross-cutting concern needs one.

## Deployment

-   Docker-ready (Docker Compose: PostgreSQL, MinIO, Mailpit)
-   Two repos: `afab-backend`, `afab-frontend`, connected by an OpenAPI contract
-   Environment configuration
-   Git-friendly project structure

------------------------------------------------------------------------

# AI Roadmap

The AI Assistant is **not included in the MVP**, and AFAB will **never call a third-party AI API**, in the MVP or any future version.

Permanently excluded: - Chatbot via third-party API - OpenAI API - Claude
API - Gemini API - Any external AI/LLM vendor

Future AI features (spending insights, smart categorization, forecasting,
receipt OCR) will be served by AFAB's own self-hosted/self-trained models,
run via an internal-only service — see `AFAB-architecture-plan.md`,
Section 14.

Only placeholders should be prepared for now, ready for that self-hosted
service later.

------------------------------------------------------------------------

# Core Features (MVP)

## Authentication

-   Register
-   Login
-   Forgot Password
-   Reset Password
-   Email Verification
-   Remember Me
-   Profile Management
-   Change Password
-   Delete Account

## Dashboard

-   Current Balance
-   Monthly Income
-   Monthly Expenses
-   Savings
-   Budget Progress
-   Recent Transactions
-   Expense Breakdown
-   Income vs Expense Charts
-   Monthly Spending Charts
-   Quick Actions

## Income Module

-   CRUD
-   Categories
-   Recurring Income
-   Search
-   Pagination
-   Filtering

## Expense Module

-   CRUD
-   Categories
-   Receipt Upload
-   Recurring Expenses
-   Search
-   Pagination
-   Filtering

## Budget Module

-   Monthly Budgets
-   Category Budgets
-   Progress Tracking
-   Budget Alerts

## Savings Goals

-   Create Goals
-   Progress Tracking
-   Target Amount
-   Deadline

## Investments

Manual tracking only: - Stocks - Crypto - Mutual Funds - Real Estate

(No live market integration.)

## Reports

-   Monthly Reports
-   Yearly Reports
-   Category Analysis
-   Export PDF
-   Export CSV

## Notifications

-   Budget Warnings
-   Goal Completion
-   Large Expense Alerts
-   Upcoming Recurring Payments

------------------------------------------------------------------------

# Pages

-   Landing
-   Features
-   Pricing (Coming Soon)
-   About
-   Contact
-   Login
-   Register
-   Dashboard
-   Income
-   Expenses
-   Budgets
-   Goals
-   Investments
-   Reports
-   Notifications
-   Settings

------------------------------------------------------------------------

# Architecture

## Backend

-   Controllers
-   Services
-   Repositories (Spring Data JPA)
-   DTOs / Validation (Jakarta Bean Validation)
-   Security Filters (Spring Security)
-   Scheduled Jobs (recurring transactions)
-   Global Exception Handling

## Frontend

``` text
app/
components/
hooks/
lib/
styles/
```

Feature-based organization is recommended (package-by-feature on the
backend, route-group-by-feature under `app/` on the frontend).

------------------------------------------------------------------------

# Database

Entities: - Users - Businesses - Income - Expenses - Categories - Budgets
- Savings Goals - Investments - Notifications - User Settings

Every financial entity (Income, Expenses, Categories, Budgets, Savings
Goals, Investments, Notifications) belongs to a Business, not directly to
a User — see `Product Rule PR-001` and PR-004.

Include: - Relationships - Foreign Keys - Indexes - Migrations (Flyway)

------------------------------------------------------------------------

# API

Base URL:

``` text
/api/v1
```

Requirements: - RESTful - Validation - Authentication - Proper HTTP
Status Codes - Error Handling

------------------------------------------------------------------------

# Security

-   Spring Security + JWT (access + refresh tokens)
-   Next.js BFF proxy (browser never talks to the API directly; no public
    CORS surface on the backend)
-   Rate Limiting
-   Password Hashing (BCrypt)
-   XSS Protection
-   SQL Injection Prevention (parameterized queries via JPA/native SQL)

------------------------------------------------------------------------

# Performance

-   Pagination
-   Lazy Loading
-   Query Optimization
-   Caching
-   Reusable Components

------------------------------------------------------------------------

# Coding Standards

-   SOLID Principles
-   Clean Architecture
-   DRY
-   Production-ready code
-   Scalable Design

------------------------------------------------------------------------

# Development Workflow

Before implementation:

1.  Software Architecture
2.  Folder Structure
3.  Database ER Diagram
4.  Database Schema
5.  User Flow
6.  API Endpoints
7.  UI Pages
8.  Component List
9.  Development Roadmap
10. Milestones
11. Backend (Java/Spring) Packages
12. Frontend (Next.js) Packages
13. Future AI Integration Plan

Claude should wait for approval after each milestone before continuing.

------------------------------------------------------------------------

# Future AI Features (Phase 2)

-   AI Spending Insights
-   Budget Predictions
-   Smart Expense Categorization
-   Personalized Financial Advice
-   Financial Health Score
-   Investment Portfolio Analysis
-   Receipt OCR
-   Natural Language Financial Queries
-   Conversational AI Assistant

------------------------------------------------------------------------

# Vision

Build **AFAB** as a polished, scalable, production-ready FinTech SaaS
platform with a premium user experience. The MVP focuses on personal
finance management while keeping the architecture ready for advanced AI
integration.
