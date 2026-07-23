# AFAB - AI Finance Assistant for Business

Welcome to the backend repository for **AFAB**, an enterprise-grade financial management platform.

## Architecture
- **Framework:** Spring Boot 4.1 (Java 21 LTS)
- **Database:** PostgreSQL 18
- **Design Pattern:** Package-by-Feature (Modular Monolith)
- **Security:** Stateless JWTs, BCrypt(12), Bucket4j Rate Limiting, Asynchronous Audit Logging

---

## Development Progress

### Phase 1: Foundation (COMPLETED)
- Initialized Spring Boot backend and Docker Compose infrastructure (Postgres, MinIO, Mailpit, Redis).
- Created the baseline `V1__init.sql` Flyway migration incorporating the strict enterprise schema (Users, Businesses, Categories, Incomes, Expenses, Budgets, Goals, Investments).
- Configured backend to disable Hibernate auto-DDL to prevent conflicts with Flyway `citext` extensions.

### Phase 2: Secure Authentication & Business Onboarding (COMPLETED)
- Implemented maximum-security dependencies (Bucket4j, jjwt).
- Created `User`, `Business`, `RefreshToken`, and `AuditLog` entities.
- Implemented `JwtService`, `UserDetailsServiceImpl`, and `JwtAuthenticationFilter`.
- Built the `AuthService` handling Registration, Login, Refresh, and Logout with token rotation and database-persisted session revocation.
- Locked down global endpoints via `SecurityConfig` and exposed `/api/v1/auth/**`.
- Created robust Business Onboarding APIs (`GET /api/v1/business/{id}`, `PUT /api/v1/business/{id}`) for the multi-step frontend wizard.
- Added comprehensive user profile fetch (`GET /api/v1/user/me`) delivering full profile, email verification status, and onboarding completion state.
- **Contracts Exported:** `contracts/identity.openapi.yaml`

### Phase 3: Core Finance (UP NEXT)
- Implement Financial Categories CRUD.
- Implement Income & Expense tracking ledgers.
- Connect MinIO for secure Expense Receipt storage.

---

## Contract Versioning Rule
> **Rule:** After the completion of each major development phase, this README must be updated, and the OpenAPI specification for the completed module must be exported to the `contracts/` directory (e.g., `identity.openapi.yaml`, `finance.openapi.yaml`).
