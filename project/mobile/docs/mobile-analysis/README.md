# AFAB Mobile — Complete Web-to-Flutter Architecture & Reverse-Engineering Blueprint

> **Product:** AFAB — AI Finance Assistant for Business (Native Mobile & Tablet Flutter Edition)
> **Status:** Blueprint & Reverse-Engineering Complete (**70 Markdown Documents**, 0 Application Code Written)
> **Source Baseline:** `Web/project/` (`master` @ `78faa7b`) · **Target Platform:** Flutter `3.44.8` / Dart `3.12.2` (`Mobile/`)

---

## 1. Executive Summary

This directory contains the complete, source-code-verified reverse-engineering analysis and Flutter architecture blueprint for **AFAB Mobile**. Every endpoint, DTO, validation rule, design token, localization key, incomplete web feature, and architectural risk has been traced directly against the actual Next.js 16 frontend (`Web/project/frontend/`) and Spring Boot 4.1 backend (`Web/project/backend/`).

### Verified Quantitative Summary
- **Web Routes Audited:** 41 files under `app/` (`31 page.tsx` routes, `4 layout.tsx`, `4 error/loading/not-found` boundaries + `4 Coming Soon` `[...slug]` tabs)
- **Backend API Mapped:** **132 REST & SSE endpoints across 20 controllers** (vs. only 44 documented in `contracts/*.openapi.yaml`)
- **Database Schema Inspected:** Flyway **V1–V28** (PostgreSQL 16 + `pgvector`, Redis 7, MinIO, Ollama, Stripe SDK)
- **Localization Audited:** **15 namespaces**, **1,419 leaf keys** in English & **1,419** in Arabic (100% key/placeholder parity + documented hardcoded strings)
- **Mobile Specifications Produced:** **70 `.md` files** (**19 core/architecture docs** + **51 exhaustive 14-section screen/flow specs**)

---

## 2. Recommended Reading Order

1. Start with [00_WORKSPACE_AND_DISCOVERY.md](./00_WORKSPACE_AND_DISCOVERY.md) for repo layout, SDK constraints, and Context/Roadmap contradictions.
2. Review [01_COMPLETE_WEB_SCREEN_INVENTORY.md](./01_COMPLETE_WEB_SCREEN_INVENTORY.md) and [02_FEATURE_PARITY_MATRIX.md](./02_FEATURE_PARITY_MATRIX.md) for the exact scope and status classification.
3. Study [03_API_CONTRACT_CATALOG.md](./03_API_CONTRACT_CATALOG.md) and [04_AUTHENTICATION_AND_SECURITY.md](./04_AUTHENTICATION_AND_SECURITY.md) before touching networking or session storage.
4. Review [05_MOBILE_INFORMATION_ARCHITECTURE.md](./05_MOBILE_INFORMATION_ARCHITECTURE.md) through [11_TESTING_STRATEGY.md](./11_TESTING_STRATEGY.md) and `architecture/*` for UI shell, tokens, RTL, responsiveness, and Clean Architecture rules.
5. Follow [12_IMPLEMENTATION_ROADMAP.md](./12_IMPLEMENTATION_ROADMAP.md) (Phases 0–7) and [13_RISKS_AND_TECHNICAL_DECISIONS.md](./13_RISKS_AND_TECHNICAL_DECISIONS.md), consulting the 51 individual specs under `screens/` as each task is built.

---

## 3. Complete Document Index (70 Files)

### A. Core Blueprint Documents (15)
| # | Document | Focus |
|---|---|---|
| 0 | [README.md](./README.md) | Master index and blueprint overview |
| 1 | [00_WORKSPACE_AND_DISCOVERY.md](./00_WORKSPACE_AND_DISCOVERY.md) | Flutter scaffold, Web git repo, stack versions, doc drift |
| 2 | [01_COMPLETE_WEB_SCREEN_INVENTORY.md](./01_COMPLETE_WEB_SCREEN_INVENTORY.md) | All 41 `app/` files, 27 overlays, and 51 mobile mappings |
| 3 | [02_FEATURE_PARITY_MATRIX.md](./02_FEATURE_PARITY_MATRIX.md) | Exhaustive Web vs Mobile status matrix |
| 4 | [03_API_CONTRACT_CATALOG.md](./03_API_CONTRACT_CATALOG.md) | All 132 endpoints across 20 backend controllers |
| 5 | [04_AUTHENTICATION_AND_SECURITY.md](./04_AUTHENTICATION_AND_SECURITY.md) | Cookie jar, CSRF, single-flight refresh, 2FA, tenant isolation, 5 backend proposals |
| 6 | [05_MOBILE_INFORMATION_ARCHITECTURE.md](./05_MOBILE_INFORMATION_ARCHITECTURE.md) | 5-tab Phone Nav, More Hub, Tablet Rail, Deep Links |
| 7 | [06_FLUTTER_ARCHITECTURE.md](./06_FLUTTER_ARCHITECTURE.md) | Feature-First Clean Architecture & Riverpod/GoRouter/Dio stack |
| 8 | [07_DESIGN_SYSTEM.md](./07_DESIGN_SYSTEM.md) | Light/Dark tokens, 8+custom accents, 4 dark surfaces, 6 fonts, shared widgets |
| 9 | [08_LOCALIZATION_AND_RTL.md](./08_LOCALIZATION_AND_RTL.md) | EN/AR ARB migration, 3-decimal currencies, Western digits, RTL rules |
| 10 | [09_RESPONSIVE_AND_ADAPTIVE_DESIGN.md](./09_RESPONSIVE_AND_ADAPTIVE_DESIGN.md) | Phone/Tablet breakpoints, cards vs tables, safe areas, keyboard ergonomics |
| 11 | [10_USER_FLOWS_AND_NAVIGATION.md](./10_USER_FLOWS_AND_NAVIGATION.md) | Mermaid auth, refresh, invoice, AI SSE, and Stripe billing flows |
| 12 | [11_TESTING_STRATEGY.md](./11_TESTING_STRATEGY.md) | Unit, Widget, Integration, Responsive, RTL & Security QA |
| 13 | [12_IMPLEMENTATION_ROADMAP.md](./12_IMPLEMENTATION_ROADMAP.md) | Phases 0–7 tasks, dependencies, acceptance criteria & traceability |
| 14 | [13_RISKS_AND_TECHNICAL_DECISIONS.md](./13_RISKS_AND_TECHNICAL_DECISIONS.md) | ADRs, confirmed web/backend bugs register, IAP/Store risks, open questions |

### B. Architecture Deep-Dives (`architecture/` — 4 Files)
- [SYSTEM_ARCHITECTURE.md](./architecture/SYSTEM_ARCHITECTURE.md)
- [FOLDER_STRUCTURE.md](./architecture/FOLDER_STRUCTURE.md)
- [DEPENDENCY_MAP.md](./architecture/DEPENDENCY_MAP.md)
- [DATA_FLOW.md](./architecture/DATA_FLOW.md)

### C. Individual Screen & Flow Specifications (`screens/` — 51 Files)

#### Authentication & Onboarding (`screens/authentication/` — 8)
- [SPLASH_SCREEN.md](./screens/authentication/SPLASH_SCREEN.md) (`AUTH-01`)
- [LOGIN_SCREEN.md](./screens/authentication/LOGIN_SCREEN.md) (`AUTH-02`)
- [TWO_FACTOR_CHALLENGE_SCREEN.md](./screens/authentication/TWO_FACTOR_CHALLENGE_SCREEN.md) (`AUTH-03`)
- [SIGNUP_SCREEN.md](./screens/authentication/SIGNUP_SCREEN.md) (`AUTH-04`)
- [EMAIL_VERIFICATION_SCREEN.md](./screens/authentication/EMAIL_VERIFICATION_SCREEN.md) (`AUTH-05`)
- [FORGOT_PASSWORD_SCREEN.md](./screens/authentication/FORGOT_PASSWORD_SCREEN.md) (`AUTH-06`)
- [RESET_PASSWORD_SCREEN.md](./screens/authentication/RESET_PASSWORD_SCREEN.md) (`AUTH-07`)
- [ONBOARDING_SCREEN.md](./screens/authentication/ONBOARDING_SCREEN.md) (`AUTH-08`)

#### Dashboard, Shell & Workspace (`screens/dashboard/` — 4)
- [DASHBOARD_SCREEN.md](./screens/dashboard/DASHBOARD_SCREEN.md) (`DASH-01`)
- [APP_SHELL_AND_MORE_HUB_SCREEN.md](./screens/dashboard/APP_SHELL_AND_MORE_HUB_SCREEN.md) (`DASH-02`)
- [BUSINESS_SWITCHER_SHEET.md](./screens/dashboard/BUSINESS_SWITCHER_SHEET.md) (`DASH-03`)
- [NOTIFICATIONS_SCREEN.md](./screens/dashboard/NOTIFICATIONS_SCREEN.md) (`DASH-04`)

#### Financial Core (`screens/financial/` — 8)
- [TRANSACTIONS_SCREEN.md](./screens/financial/TRANSACTIONS_SCREEN.md) (`FIN-01`)
- [TRANSACTION_DETAILS_SCREEN.md](./screens/financial/TRANSACTION_DETAILS_SCREEN.md) (`FIN-02`)
- [ADD_EDIT_TRANSACTION_SCREEN.md](./screens/financial/ADD_EDIT_TRANSACTION_SCREEN.md) (`FIN-03`)
- [SPLIT_TRANSACTION_SCREEN.md](./screens/financial/SPLIT_TRANSACTION_SCREEN.md) (`FIN-04`)
- [MANAGE_CATEGORIES_SCREEN.md](./screens/financial/MANAGE_CATEGORIES_SCREEN.md) (`FIN-05`)
- [EXPENSES_SCREEN.md](./screens/financial/EXPENSES_SCREEN.md) (`FIN-06`)
- [REVENUE_SCREEN.md](./screens/financial/REVENUE_SCREEN.md) (`FIN-07`)
- [RECEIPT_VIEWER_AND_UPLOAD_FLOW.md](./screens/financial/RECEIPT_VIEWER_AND_UPLOAD_FLOW.md) (`FIN-08`)

#### Business Operations (`screens/business/` — 9)
- [CUSTOMERS_SCREEN.md](./screens/business/CUSTOMERS_SCREEN.md) (`BIZ-01`)
- [CUSTOMER_DETAILS_SCREEN.md](./screens/business/CUSTOMER_DETAILS_SCREEN.md) (`BIZ-02`)
- [INVOICES_SCREEN.md](./screens/business/INVOICES_SCREEN.md) (`BIZ-03`)
- [INVOICE_DETAILS_SCREEN.md](./screens/business/INVOICE_DETAILS_SCREEN.md) (`BIZ-04`)
- [CREATE_EDIT_INVOICE_SCREEN.md](./screens/business/CREATE_EDIT_INVOICE_SCREEN.md) (`BIZ-05`)
- [RECORD_PAYMENT_SHEET.md](./screens/business/RECORD_PAYMENT_SHEET.md) (`BIZ-06`)
- [BUDGETS_SCREEN.md](./screens/business/BUDGETS_SCREEN.md) (`BIZ-07`)
- [RECURRING_TRANSACTIONS_SCREEN.md](./screens/business/RECURRING_TRANSACTIONS_SCREEN.md) (`BIZ-08`)
- [FINANCIAL_CALENDAR_SCREEN.md](./screens/business/FINANCIAL_CALENDAR_SCREEN.md) (`BIZ-09`)

#### Financial Intelligence (`screens/intelligence/` — 3)
- [CURRENCIES_SCREEN.md](./screens/intelligence/CURRENCIES_SCREEN.md) (`INT-01`)
- [CURRENCY_MIGRATION_SHEET.md](./screens/intelligence/CURRENCY_MIGRATION_SHEET.md) (`INT-02`)
- [REPORTS_SCREEN.md](./screens/intelligence/REPORTS_SCREEN.md) (`INT-03`)

#### AI Copilot v2 (`screens/ai/` — 3)
- [AI_COPILOT_SCREEN.md](./screens/ai/AI_COPILOT_SCREEN.md) (`AI-01`)
- [GLOBAL_COPILOT_SHEET.md](./screens/ai/GLOBAL_COPILOT_SHEET.md) (`AI-02`)
- [BUSINESS_MEMORY_SCREEN.md](./screens/ai/BUSINESS_MEMORY_SCREEN.md) (`AI-03`)

#### Plans & Subscriptions (`screens/plans/` — 2)
- [PLANS_AND_SUBSCRIPTION_SCREEN.md](./screens/plans/PLANS_AND_SUBSCRIPTION_SCREEN.md) (`PLAN-01`)
- [BUSINESS_ALLOCATION_AND_CANCEL_FLOWS.md](./screens/plans/BUSINESS_ALLOCATION_AND_CANCEL_FLOWS.md) (`PLAN-02`)

#### Settings & Account (`screens/settings/` — 10)
- [SETTINGS_HOME_SCREEN.md](./screens/settings/SETTINGS_HOME_SCREEN.md) (`SET-01`)
- [GENERAL_SETTINGS_SCREEN.md](./screens/settings/GENERAL_SETTINGS_SCREEN.md) (`SET-02`)
- [BUSINESS_PROFILE_SCREEN.md](./screens/settings/BUSINESS_PROFILE_SCREEN.md) (`SET-03`)
- [SECURITY_SETTINGS_SCREEN.md](./screens/settings/SECURITY_SETTINGS_SCREEN.md) (`SET-04`)
- [APPEARANCE_SETTINGS_SCREEN.md](./screens/settings/APPEARANCE_SETTINGS_SCREEN.md) (`SET-05`)
- [SIGNATURE_SETTINGS_SCREEN.md](./screens/settings/SIGNATURE_SETTINGS_SCREEN.md) (`SET-06`)
- [DATA_EXPORT_SETTINGS_SCREEN.md](./screens/settings/DATA_EXPORT_SETTINGS_SCREEN.md) (`SET-07`)
- [LANGUAGE_SETTINGS_SCREEN.md](./screens/settings/LANGUAGE_SETTINGS_SCREEN.md) (`SET-08`)
- [SETTINGS_COMING_SOON_SCREEN.md](./screens/settings/SETTINGS_COMING_SOON_SCREEN.md) (`SET-09`)
- [ACCOUNT_DELETION_FLOW.md](./screens/settings/ACCOUNT_DELETION_FLOW.md) (`SET-10`)

#### Global Application States (`screens/application/` — 4)
- [LOADING_AND_SKELETON_STATES.md](./screens/application/LOADING_AND_SKELETON_STATES.md) (`APP-01`)
- [MAINTENANCE_SCREEN.md](./screens/application/MAINTENANCE_SCREEN.md) (`APP-02`)
- [ERROR_AND_NOT_FOUND_STATES.md](./screens/application/ERROR_AND_NOT_FOUND_STATES.md) (`APP-03`)
- [SESSION_NETWORK_PLAN_LIMIT_STATES.md](./screens/application/SESSION_NETWORK_PLAN_LIMIT_STATES.md) (`APP-04`)
