This section documents all fixed decisions for AFAB, so there is no ambiguity during development.

## Fixed Decisions

* One User = One Business (Version 1) — see `Product Rule PR-001`.
* Every financial record belongs to a `business`, not directly to a `user` — see PR-004. The database schema enforces this via a dedicated `businesses` table (see `AFAB-architecture-plan.md`, Section 4).
* AI is excluded from the MVP entirely (PR-002).
* AI is, and will remain, self-hosted only. AFAB will never call a third-party AI API (OpenAI, Claude, Gemini, or otherwise) — even in future versions. Any future AI feature is served by AFAB's own trained models via an internal-only service.
* Web-first application; no native mobile app in V1.
* Backend: Spring Boot 4.1, Java 21 (LTS).
* Frontend: Next.js 16 (App Router), shadcn/ui, TailwindCSS.
* Database: PostgreSQL 18, accessed via Spring Data JPA (Hibernate) with native SQL for reporting/aggregation queries.
* Migrations: Flyway.
* API: RESTful, versioned under `/api/v1`, contract published via OpenAPI (springdoc-openapi) and consumed by the frontend as a generated typed client.
* Auth: Spring Security + JWT (access + refresh tokens), proxied through Next.js as a backend-for-frontend layer so the browser never talks to the API directly.
* Repositories: two separate repos, `afab-backend` and `afab-frontend`, connected only by the OpenAPI contract.
* Team: Farouk owns the backend, Jamil owns the frontend.

## Assumptions

* No production data exists yet, so switching the original draft's stack (Laravel/MySQL/React) to Spring Boot/PostgreSQL/Next.js is a zero-cost decision made before implementation began.
* The brand identity (colors, typography, UI feel) defined in `AFAB_Project_Summary.md` is unaffected by the stack change and remains the source of truth.
