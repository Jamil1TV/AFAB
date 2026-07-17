# AFAB API Contract Specification

Version: 1.0

## Overview

This document defines the frontend contracts expected from the backend.
All endpoints return JSON and use REST conventions.

## Standards

-   Authentication: Bearer JWT
-   Content-Type: application/json
-   Dates: ISO 8601
-   Currency: Decimal
-   Pagination:
    -   page
    -   limit
    -   total
    -   hasNext

------------------------------------------------------------------------

# Authentication

## POST /auth/login

Request

``` json
{
  "email": "user@example.com",
  "password": "********"
}
```

Response

``` json
{
  "accessToken": "...",
  "refreshToken": "...",
  "user": {}
}
```

Errors - 400 Validation - 401 Invalid credentials

## POST /auth/register

Fields - firstName - lastName - email - password - businessName

## POST /auth/logout

## POST /auth/refresh

------------------------------------------------------------------------

# Dashboard

GET /dashboard

Returns: - KPIs - Recent Transactions - Upcoming Invoices - AI
Insights - Revenue Summary

------------------------------------------------------------------------

# Transactions

GET /transactions POST /transactions GET /transactions/{id} PATCH
/transactions/{id} DELETE /transactions/{id}

Query Parameters - page - limit - search - category - status -
startDate - endDate

------------------------------------------------------------------------

# Expenses

GET /expenses POST /expenses PATCH /expenses/{id} DELETE /expenses/{id}

Supports receipt upload.

------------------------------------------------------------------------

# Revenue

GET /revenue GET /revenue/forecast

------------------------------------------------------------------------

# Invoices

GET /invoices POST /invoices PATCH /invoices/{id} DELETE /invoices/{id}

Extra Actions - POST /invoices/{id}/send - POST
/invoices/{id}/mark-paid - GET /invoices/{id}/pdf

------------------------------------------------------------------------

# Customers

CRUD endpoints plus: GET /customers/{id}/invoices

------------------------------------------------------------------------

# Reports

GET /reports/profit-loss GET /reports/cash-flow GET /reports/tax GET
/reports/export

------------------------------------------------------------------------

# AI Assistant

POST /ai/chat POST /ai/analyze POST /ai/generate-report

Response - message - citations - confidence - suggestions

------------------------------------------------------------------------

# Calendar

CRUD endpoints for events.

------------------------------------------------------------------------

# Team

CRUD members. Role management endpoint.

------------------------------------------------------------------------

# Settings

GET /settings PATCH /settings

Nested resources: - business-profile - notifications - security -
appearance - language - integrations - subscription

------------------------------------------------------------------------

# Standard Error Response

``` json
{
  "success": false,
  "message": "Validation failed",
  "errors": {}
}
```

------------------------------------------------------------------------

# Success Response

``` json
{
  "success": true,
  "data": {},
  "message": "Operation completed"
}
```

------------------------------------------------------------------------

# Frontend Requirements

-   Optimistic updates where appropriate
-   Retry transient failures
-   Handle 401 by refreshing token
-   Show loading, empty, error, and success states
-   Validate forms before submission
-   Strongly type every request and response using TypeScript interfaces
