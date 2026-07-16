# AFAB Backend

**AI Finance Assistant for Business** — Spring Boot REST API

---

## 🛠 Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Runtime** | Java | 21 (LTS) |
| **Framework** | Spring Boot | 4.1.0 |
| **Security** | Spring Security + JWT (JJWT) | 0.13.0 |
| **Database** | PostgreSQL | 18 |
| **ORM** | Spring Data JPA (Hibernate) | — |
| **Migrations** | Flyway | — |
| **API Docs** | springdoc-openapi (Swagger UI) | 3.0.2 |
| **File Storage** | MinIO (S3-compatible) | 9.0.3 SDK |
| **Email** | Mailpit (local dev) | latest |
| **Cache** | Redis | 7-alpine |
| **CSV Export** | Apache Commons CSV | 1.14.0 |
| **PDF Export** | OpenPDF | 2.0.3 |
| **Testing** | JUnit 5 + Testcontainers | 1.21.1 |
| **Containerization** | Docker + Docker Compose | — |

---

## 📁 Project Structure

```
src/main/java/com/afab/
├── AfabApplication.java          # Main entry point
├── config/                       # Spring configuration
│   ├── SecurityConfig.java       # JWT auth, BCrypt, filter chain
│   ├── CorsConfig.java           # CORS (locked to BFF)
│   ├── OpenApiConfig.java        # Swagger/OpenAPI setup
│   ├── JacksonConfig.java        # JSON serialization
│   └── WebConfig.java            # Custom argument resolvers
├── common/
│   ├── exception/                # Global exception handling
│   │   ├── GlobalExceptionHandler.java
│   │   ├── ApiError.java
│   │   ├── ResourceNotFoundException.java
│   │   └── BusinessRuleException.java
│   ├── response/                 # Standardized responses
│   │   ├── ApiResponse.java      # ApiResponse<T> wrapper
│   │   └── PageResponse.java     # Paginated response
│   └── security/                 # JWT infrastructure
│       ├── JwtService.java       # Token generation & validation
│       ├── JwtAuthFilter.java    # Request filter
│       ├── CurrentUser.java      # @CurrentUser annotation
│       └── CurrentUserArgumentResolver.java
├── auth/                         # Authentication module
│   ├── AuthController.java
│   ├── AuthService.java
│   ├── CustomUserDetailsService.java
│   └── dto/
│       ├── RegisterRequest.java
│       ├── LoginRequest.java
│       └── AuthResponse.java
├── user/                         # User entity & repository
├── business/                     # Business entity & repository
├── category/                     # 🔜 Phase 3
├── income/                       # 🔜 Phase 3
├── expense/                      # 🔜 Phase 3
├── budget/                       # 🔜 Phase 4
├── goal/                         # 🔜 Phase 4
├── investment/                   # 🔜 Phase 5
├── report/                       # 🔜 Phase 5
├── notification/                 # 🔜 Phase 4
├── settings/                     # 🔜 Phase 3
└── assistant/                    # AI placeholder (disabled V1)

src/main/resources/
├── application.yml               # Main configuration
├── application-local.yml         # Local dev overrides
└── db/migration/
    └── V1__baseline.sql          # Full database schema (16 tables)
```

---

## 🚀 Getting Started

### Prerequisites

- **Java 21** (LTS) — [Download](https://adoptium.net/)
- **Docker Desktop** — [Download](https://www.docker.com/products/docker-desktop/)
- **IntelliJ IDEA** (recommended)

### 1. Clone & Open

Open the project in IntelliJ IDEA:
```
File → Open → select project/backend folder
```

IntelliJ will auto-detect the Maven `pom.xml` and import dependencies.

### 2. Start Infrastructure (Docker)

Start PostgreSQL, MinIO, Mailpit, and Redis:

```bash
cd project/backend
docker compose up -d postgres minio mailpit redis
```

> **Note**: Only infrastructure services are started. The Spring Boot app runs from IntelliJ.

### 3. Verify Services Are Running

| Service | URL | Purpose |
|---------|-----|---------|
| PostgreSQL | `localhost:5432` | Database |
| MinIO Console | [http://localhost:9001](http://localhost:9001) | File storage UI |
| Mailpit | [http://localhost:8025](http://localhost:8025) | Email testing UI |
| Redis | `localhost:6379` | Cache |

### 4. Configure Environment

Copy the example env file:
```bash
cp .env.example .env
```

The `.env` file is pre-configured for local development. Edit if needed.

### 5. Run the Application

**From IntelliJ:**
1. Open `AfabApplication.java`
2. Click the green ▶ Run button
3. Set active profile to `local` in Run Configuration → VM Options:
   ```
   -Dspring.profiles.active=local
   ```

**Or via environment variables in IntelliJ Run Configuration:**
- Add all variables from `.env` to the Run Configuration's Environment Variables.

### 6. Access the API

| Endpoint | URL |
|----------|-----|
| **Swagger UI** | [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html) |
| **OpenAPI JSON** | [http://localhost:8080/api-docs](http://localhost:8080/api-docs) |
| **Register** | `POST http://localhost:8080/api/v1/auth/register` |
| **Login** | `POST http://localhost:8080/api/v1/auth/login` |

---

## 🐳 Docker

### Infrastructure Only (Recommended for Development)

```bash
docker compose up -d postgres minio mailpit redis
```

### Full Stack (Including Backend)

```bash
docker compose up -d
```

### Stop Everything

```bash
docker compose down
```

### Reset Database

```bash
docker compose down -v   # removes volumes
docker compose up -d postgres minio mailpit redis
```

---

## 🗄 Database

- **Engine**: PostgreSQL 18
- **Migrations**: Flyway (auto-runs on app startup)
- **Schema**: 16 tables defined in `V1__baseline.sql`
- **Conventions**: `numeric(14,2)` for money, `timestamptz` for timestamps, `citext` for email

### Tables

| Table | Description |
|-------|-------------|
| `users` | Registered users |
| `businesses` | One per user (V1 constraint) |
| `user_settings` | Theme, locale, notification prefs |
| `refresh_tokens` | JWT refresh token persistence |
| `categories` | Income/expense categories |
| `incomes` | Income records |
| `income_recurring_rules` | Recurring income schedule |
| `expenses` | Expense records |
| `expense_recurring_rules` | Recurring expense schedule |
| `expense_receipts` | Receipt file metadata (MinIO) |
| `budgets` | Monthly/yearly/custom budgets |
| `savings_goals` | Savings goals with targets |
| `investments` | Manual investment tracking |
| `notifications` | System notifications |
| `assistant_conversations` | AI placeholder (disabled) |
| `assistant_messages` | AI placeholder (disabled) |
| `financial_insights` | AI placeholder (disabled) |

---

## 🔐 Security

- **Authentication**: JWT (access + refresh tokens)
- **Password Hashing**: BCrypt
- **Session**: Stateless (no server-side sessions)
- **CORS**: Locked to BFF proxy origins only
- **Architecture**: API-first, designed for Next.js BFF proxy pattern

---

## 📋 API Versioning

All endpoints are versioned under `/api/v1/`.

---

## 🧩 Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| **Modular Monolith** | Package-by-feature, not microservices. Easy to split later if needed. |
| **PR-001**: One User = One Business | V1 constraint. `businesses.user_id` is UNIQUE. |
| **PR-004**: Records → Business | All financial data belongs to `businesses`, not `users`. |
| **PR-002**: No AI in MVP | AI tables exist but are flagged off. No third-party AI APIs ever. |
| **Flyway over ddl-auto** | Flyway owns the schema. Hibernate validates only. |
| **BFF Pattern** | Browser → Next.js → Spring Boot. No direct browser-to-API calls. |

---

## 📝 Changelog

### Phase 1 — Foundation (Current)
- ✅ Spring Boot 4.1.0 project scaffold
- ✅ Docker Compose (PostgreSQL 18, MinIO, Mailpit, Redis)
- ✅ Flyway V1 baseline migration (16 tables, all indexes/FKs)
- ✅ Spring Security + JWT authentication
- ✅ Global exception handling
- ✅ Standardized API response wrappers
- ✅ OpenAPI/Swagger configuration
- ✅ Auth module skeleton (register, login, logout)
- ✅ User & Business JPA entities
- ✅ Package-by-feature structure for all 11 modules
