# AFAB — Master Roadmap

> **One file to use.** It merges my two earlier files (`AFAB_Next_Steps_Roadmap.md`, `AFAB_Roadmap_Part2_Advanced.md`) and the ChatGPT audit (`AFAB_Project_Audit_and_Development_Roadmap.md`). Where they disagreed, I re-checked the code and chose one answer (§9).
> **Basis:** static review of `AFAB-master.zip`. I did **not** build, run, or test anything, so "exists" means "the code is there", not "it works". Phase 0 turns that into facts.
> **Rule for the whole project:** a screen is not a feature. A feature is done only when UI + API + DB are connected, the numbers are right, ownership is tested, and loading/empty/error states exist.

---

## 1. Where you are (checked against the source)

| Area | Backend | Frontend | Verdict |
|---|---|---|---|
| Auth (register, login, refresh, logout, verify email, forgot/reset/change password) | ✅ | ✅ | Built — needs end-to-end verification |
| Onboarding, Business profile, User profile, Sessions | ✅ | ✅ | Built |
| Settings: General, Business Profile, Security | ✅ | ✅ | Built |
| Transactions (list, create, delete, categories list) | 🟡 | ✅ | **No edit, weak validation, category ownership gap** |
| Expenses / Revenue pages | 🟡 | ✅ | **Summaries contain hardcoded demo data** |
| Invoices page | 🟡 | ✅ | Reads income transactions + **demo upcoming invoices**; no real invoice model |
| Dashboard | 🔴 stub returns zeros | ✅ | Screen only |
| Customers, Reports, Calendar | ❌ | ❌ | Sidebar links open a missing page (404) |
| AI Assistant route | ❌ | placeholder | `/dashboard/ai` renders the plans screen |
| Plans / Subscription | ❌ | UI + local state | No entitlements, no payment |
| Settings: Users & Permissions, Notifications, Integrations, Data & Export, Appearance, Language | ❌ | "Coming soon" catch-all | Placeholders |
| Budgets, Savings Goals, Investments, Recurring, Receipts, Notifications | ❌ | ❌ | In the PRD, not built |
| Automated tests | ❌ none | ❌ none | **Zero tests in the archive** |

> **Correction to my earlier files:** I marked the Expenses/Revenue summaries as working. They are not — they contain hardcoded demo values (details in F7). The ChatGPT audit was right about that.

---

## 2. Findings register (verified by reading the code)

Priority: **P0** fix before more features · **P1** fix in the phase shown · **P2** plan for it.

| ID | Pri | Finding | Evidence | Fixed in |
|---|---|---|---|---|
| F1 | P0 | **Both `project/.env` and `project/.env.example` contain a mail password-like value** (they look like two different credentials) plus JWT/DB/MinIO secrets. Treat all as exposed. Values are deliberately not reproduced here. | `.env`, `.env.example` | Phase 0 |
| F2 | P0 | **No `.gitignore` at the project root** (only `frontend/.gitignore`). `.env`, `backend/target/` and `.idea/` are inside the archive. | file tree | Phase 0 |
| F3 | P0 | **No tests** (no `src/test`, no frontend tests). | file tree | Phase 0 → every phase |
| F4 | P0 | **Error handling:** the only global handler is a catch-all that returns **HTTP 500** with `ex.getMessage()` in the body. Validation errors, "not found" and "unauthorized" (thrown as `IllegalArgumentException`) all surface as 500 and leak internal messages. (`AuthController` has its own `ErrorResponse` — not checked in detail.) | `GlobalExceptionHandler.java` | Phase 0 |
| F5 | P0 | **Category ownership/type not checked:** `createTransaction` does `categoryRepository.findById(id).orElse(null)` — any category UUID is accepted (another business's, or an INCOME category on an EXPENSE), and an unknown id is **silently dropped**. | `TransactionService` ~L96 | Phase 1 |
| F6 | P1 | **Validation gaps:** `type`, `status`, `paymentMethod` are free strings (only `@NotBlank`); `description` has no max length (column is 255 → a 500); page `size` has no upper cap; no date-range/status filters; no update endpoint. | `CreateTransactionRequest`, `TransactionController` | Phase 1 |
| F7 | P0 | **Hardcoded demo data shown as real:** recurring expenses "Adobe Creative Cloud / Google Workspace / Shopify Plan" with a fixed total of 251.00; revenue "top products" (AFAB Pro Plan 8,450.00 …); "upcoming invoices" INV-1242…1244 dated May 2024. Average/day divides by a **fixed 30** instead of the real number of days. | `TransactionService` ~L145, 194–198, 237, 282–284, 359–361 | Phases 2–3 |
| F8 | P1 | **Dashboard returns zeros** and empty lists; `Locale.ENGLISH` month names and pre-formatted money **strings** (`"$0.00"`) break Arabic. | `DashboardService` | Phase 2 |
| F9 | P1 | **Money precision:** `transactions.amount` is `NUMERIC(15,2)`. TND, KWD, BHD, OMR use **3 decimals**; `DashboardService` already lists KWD/BHD/OMR. | `V7__transactions.sql` | Phase 0 |
| F10 | P1 | **Single-business assumption in 12 places** (`findByUserId`: `TransactionService` ×7, `AuthService` ×2, `UserController`, `BusinessController`, `DashboardService`) and `Business` is `@OneToOne` + `unique user_id`. | grep | Phases 0, 4 |
| F11 | P1 | **Sidebar links to pages that don't exist** (`/customers`, `/reports`, `/calendar`). | `Sidebar.tsx` | Phases 6, 8, 14 |
| F12 | P1 | **Invoices aren't invoices:** the controller returns INCOME transactions. No invoice table, items, numbering, due date, or lifecycle. | `InvoiceController` | Phase 9 |
| F13 | P1 | **Docs/config drift:** README says PostgreSQL 18, `docker-compose.yml` runs `postgres:16-alpine`; README says Phase 3 is "up next" though V7 and finance code exist; only `identity.openapi.yaml` exists in `contracts/`; **no Maven wrapper** although the context docs suggest `./mvnw`; PRD §4.2 still forbids AI, multi-business, team. | files | Phase 0 |
| F14 | P1 | **Auth hardening (from your own `PRODUCTION_CHECKLIST.md` + config, not re-verified line by line):** tokens in `localStorage` + a JS-readable cookie; one-time tokens stored in plain form; in-memory rate limiter (per instance); CORS localhost defaults; default JWT secret fallback; no 2FA endpoints (columns exist); no delete-account endpoint (PRD says in scope). | checklist, `application.yml` | Phase 22 (+ Phase 7) |

---

## 3. Decisions to lock (they change the design)

| # | Decision | My recommendation | Needed by |
|---|---|---|---|
| D1 | Is AI in scope? | **Yes (you decided).** Update PRD §4.2 and `Context/*.md` so tools/agents stop "correcting" it. | Phase 0 |
| D2 | Multi-business with plan limits? | **Yes (you decided): 1 / 3 / 5.** | Phase 4 |
| D3 | One `transactions` table for income+expense | **Keep it.** Don't create `incomes`/`expenses` tables. | now |
| D4 | Accounting semantics | **Cash basis for V1:** only `COMPLETED` transactions count; `PENDING` appears in invoices/calendar only; an invoice is **not** income until it is paid. | Phase 2 |
| D5 | Category deletion when used | **Block with 409 + usage count** (don't null out history). | Phase 1 |
| D6 | Delete transactions | **Soft delete + audit entry**; never hard-delete financial data silently. | Phase 1 |
| D7 | Quota scope | **Pooled per account** (AI queries, exports, invoices). "Users" = distinct invited users across your businesses. | Phase 5 |
| D8 | Invoice tax | PRD excludes tax *calculation*: store an optional per-invoice tax amount/rate, no tax engine. | Phase 9 |
| D9 | Token storage | Decide before any public release: BFF + HttpOnly cookies vs current `localStorage`. | Phase 22 |
| D10 | Payment provider | Verify availability for Tunisia (local gateways vs merchant of record). **Start early** — onboarding can take time. | Phase 18 |
| D11 | Source of truth for scope | **Mockups + the plan matrix in `PlansScreen.tsx`**; update the PRD to match. | Phase 0 |
| D12 | AI provider/hosting | Provider-swappable backend gateway; first provider Gemini; revisit self-hosting later. | Phase 15 |

---

## 4. The roadmap at a glance

**Size:** S ≈ days · M ≈ 1–2 weeks · L ≈ 3+ weeks (rough, solo developer).
**Rule:** don't start a phase before the previous one meets its Definition of Done.

| Phase | Name | Size | Depends on | Milestone |
|---|---|---|---|---|
| **0** | Baseline, hygiene & foundations | M | — | **M1 — Honest finance tracker** |
| **1** | Finance core: Categories + Transactions | M | 0 | M1 |
| **2** | Stats layer + Dashboard | M | 1 | M1 |
| **3** | Expenses & Revenue on real data | S–M | 2 | M1 |
| **4** | Multi-business foundation | M–L | 1–3 | **M2 — Platform (free beta can open)** |
| **5** | Plans & entitlements engine | M | 4 | M2 |
| **6** | Reports & Export | M | 2, 5 | M2 |
| **7** | Settings quick wins | S | 6 | M2 |
| **8** | Customers | M | 4 | **M3 — SME toolkit** |
| **9** | Invoices (real) | M–L | 5, 8 | M3 |
| **10** | Budgets | M | 2 | M3 |
| **11** | Savings goals | S–M | 2 | M3 |
| **12** | Investments (manual) | S–M | 4 | M3 |
| **13** | Recurring transactions + Receipts | M–L | 1 | M3 |
| **14** | Notifications + Calendar | M–L | 9, 10, 13 | M3 |
| **15** | AI-A: insights, recommendations, forecast | M–L | 2, 5, 13 | **M4 — Intelligence** |
| **16** | AI-B: assistant (LLM + tools) | L | 15 | M4 |
| **17** | Team & roles | L | 4, 5 | **M5 — Paid launch** |
| **18** | Billing | L | 5 | M5 |
| **19** | AI-C: learned models | L | 15–16 + consented data | **M6 — Scale** |
| **20** | Advanced pack | L | various | M6 |
| **21** | Integrations | L | — | M6 |
| **22** | Production hardening & release | M | continuous | before any public release |

**Why this order**
- **Transactions before Dashboard:** every number on every screen is an aggregate of transactions, and F5/F6 are data-integrity holes. Fix the source before summing it.
- **One stats layer, many screens:** build the aggregation once (Phase 2), then Dashboard, Expenses, Revenue, Reports, Budgets and AI all read from it — never re-implement the same sum five times.
- **Multi-business right after the core, before Customers/Invoices/Budgets:** each later module adds more business-scoped tables and queries. Refactoring 12 call sites is cheap; refactoring 40 is not.
- **Entitlements before Reports/Invoices/AI:** exports, invoices and AI queries are plan-limited, so the gate should exist when they ship (billing itself comes much later).
- **Billing last:** there must be something worth paying for, and plan changes should be enforceable first.

---

## 5. Phase details

> **Cycle for every phase** (same order every time): Inspect existing code → Contract (request/response, status codes, ownership rules) → Migration (forward-only) → Backend (entity → repository → service → controller/DTO) → Tests → `lib/api/*.ts` types → UI (loading / empty / error / success, EN + AR + RTL, design tokens) → Verify manually + lint/build/tests → Update OpenAPI + this roadmap → only then start the next phase.
> Migration numbers below (`V10`, `V11`…) are illustrative — always use the next free version; never edit an applied migration.

---

### Phase 0 — Baseline, hygiene & foundations · M

**Goal:** know what really runs, remove hazards, and lay the foundations every later phase assumes.

**Steps (in this order)**
1. **Secrets (do first, ~30 min):** rotate the mail credential(s) in both `.env` and `.env.example`; assume all secrets in the archive are exposed (JWT, DB, MinIO too). Make `.env.example` contain obvious placeholders only.
2. **Root `.gitignore`:** `.env*` (keep `.env.example`), `backend/target/`, `node_modules/`, `.next/`, `.idea/`. Remove `target/` and `.idea/` from the repo. If secrets were ever committed, purge history or at least rotate (done in step 1).
3. **Run the baseline and record real results:**
   - Infra: `docker compose up -d` (Postgres, Redis, MinIO, Mailpit).
   - Backend: add the Maven wrapper (`mvn wrapper:wrapper`; none exists), then `./mvnw test` and `./mvnw verify`.
   - Frontend (`project/frontend`): `npm ci`, `npm run lint`, `npx tsc --noEmit`, `npm run build`.
   - Write the exact outcome in the README — a failing build is information, not a failure of the step.
4. **Manual end-to-end from zero**, in `/en` and `/ar`: signup → verify email → login → onboarding → refresh token → logout → login → forgot/reset password. Note every broken state.
5. **Global error handling (F4):** keep the `ApiError` shape and map: `MethodArgumentNotValidException`/`ConstraintViolationException` → 400 with per-field errors; new `NotFoundException` → 404; `ForbiddenException` → 403; `IllegalArgumentException` → 400; everything else → 500 with a **generic** message (log the details server-side, never return `ex.getMessage()`). Replace the `IllegalArgumentException("…not found/Unauthorized…")` calls in services with the typed exceptions.
6. **Money foundation (F9):** migration `ALTER TABLE transactions ALTER COLUMN amount TYPE NUMERIC(19,4);` + one `Money`/`CurrencyUtil` helper that rounds with `Currency.getInstance(code).getDefaultFractionDigits()` and one chosen rounding mode (with tests for TND/KWD/USD/JPY).
7. **`CurrentBusinessService` (F10):** one method returning the current user's business; route all 12 `findByUserId` call sites through it. Phase 4 then changes one place.
8. **Test + CI foundation:** Testcontainers (Postgres) so Flyway V1→latest runs in tests; one auth-flow integration test; one tenant-isolation test as a template; GitHub Actions running backend tests + frontend lint/tsc/build.
9. **Docs/config drift (F13):** pick one PostgreSQL version (use the one you'll deploy) and align README + compose; update README phases; record D1/D2/D11 in the PRD and `Context/*.md`.
10. **Honest navigation (F11):** until a page exists, mark Customers / Reports / Calendar as "Coming soon" instead of linking to a 404, and stop `/dashboard/ai` from rendering the plans screen.

**Done when**
- [ ] Real results of `mvn test/verify`, `npm run lint/build`, `tsc` are recorded.
- [ ] New user → onboarding works end-to-end in EN and AR.
- [ ] No secret in the repo; root `.gitignore` in place; mail credentials rotated.
- [ ] Validation/ownership/not-found errors return 400/403/404 (not 500) and never leak internal messages.
- [ ] Amount column is `NUMERIC(19,4)`; `Money` helper tested; one place resolves the current business.
- [ ] CI runs on every push.

---

### Phase 1 — Finance core: Categories + Transactions · M

**Goal:** make the source of every number trustworthy.

**Where:** `finance/controller/TransactionController`, `finance/service/TransactionService`, `finance/repository/*`, `finance/domain/{Transaction,Category}`, `finance/dto/*`; frontend `dashboard/transactions/page.tsx`, `components/dashboard/AddTransactionModal.tsx`, `lib/api/transactions.ts`; new `contracts/finance.openapi.yaml`.

**Steps**
1. **Contract first:** document the current behavior and the target in `finance.openapi.yaml`.
2. **Categories (CRUD, per business):** `GET/POST/PUT/DELETE /api/v1/categories` (keep `GET /transactions/categories` working or migrate the frontend). Global defaults (`business_id IS NULL`) are usable but read-only. Rules: required name with max length, type ∈ {INCOME, EXPENSE}, unique name per (business, type), cannot touch another business's category, **delete blocked with 409 + usage count when used (D5)**. One "Manage categories" UI (Settings or a shared dialog) — not three copies.
3. **Fix F5:** on create/update, the category must be global **or** belong to the current business **and** match the transaction type; unknown id → 400/404, never silently ignored.
4. **Transaction CRUD:** add `PUT /api/v1/transactions/{id}` with ownership check. Convert `type`, `status`, `paymentMethod` to enums with validation; `description` `@Size(max=255)`, `notes` max length; amount > 0 with an upper bound and per-currency scale; sane date range.
5. **Listing:** cap `size` (e.g. ≤ 100), `page ≥ 0`; filters for date range, status, payment method, category, type, search; stable sort.
6. **Soft delete (D6):** `deleted_at` + audit entry via `AuditService`; all queries exclude deleted rows.
7. **Frontend:** edit modal, delete confirmation, field-level errors from the 400 response, loading/empty/error states, list refresh after any mutation, filters/pagination that really hit the API, EN/AR/RTL, mobile widths.
8. **Tests:** user A can't read/edit/delete user B's transactions or categories; category from another business or wrong type is rejected; zero/negative/unknown-type amounts rejected; pagination/search/filters correct; create/update/delete reflected in the next GET; error codes are 400/403/404 as designed.

**Done when**
- [ ] Add / list / edit / delete transactions work in the UI; categories manageable.
- [ ] Ownership and type rules enforced in the backend and covered by tests.
- [ ] `finance.openapi.yaml` matches the DTOs.

---

### Phase 2 — Stats layer + Dashboard · M

**Goal:** one aggregation layer; the first screen after login shows real numbers.

**Where:** new `finance/stats/FinanceStatsService` (+ repository aggregate queries); `dashboard/DashboardService`, `DashboardSummaryDTO`; frontend `dashboard/page.tsx`, `components/dashboard/*`, `lib/api/dashboard.ts`, `lib/currency.ts`.

**Steps**
1. **Lock the semantics (D4):** cash basis, `COMPLETED` only, amounts in the business currency, periods in the business timezone. Write these definitions at the top of the service.
2. **Stats queries** (all scoped by business, `BigDecimal`): totals by type and period; totals per month (last 6); breakdown by category (with %); last N transactions; comparison with the previous period.
3. **Dashboard summary:** KPIs (revenue, expenses, profit, cash flow) with real % change; `GET /dashboard/summary?period=month|30d|year` (the `PeriodSelector` already exists).
4. **DTO change (F8):** return **numbers** (`BigDecimal` + `currency`) and months as `yyyy-MM`; remove `Locale.ENGLISH` and symbol-formatting from the backend. Format in the frontend with `Intl.NumberFormat(locale, …)` and locale-aware month labels.
5. **No fake data:** `reminders`, `customers`, AI insights stay empty → hide the card or show an honest empty state until their phases.
6. After `AddTransactionModal` succeeds, refetch the dashboard.
7. **Tests:** fixed datasets (two months, month/year boundaries, empty period, rounding for TND/KWD/USD, user A vs user B).

**Done when:** adding/editing/deleting a transaction changes the KPIs, chart and recent list correctly, in EN and AR; no hardcoded numbers reach the user.

---

### Phase 3 — Expenses & Revenue on real data · S–M

**Goal:** remove every fake number from these screens (F7).

**Steps**
1. Rebuild `getExpenseSummary` / `getRevenueSummary` on the Phase 2 stats layer with an explicit `period` / date range.
2. Compute total, **average per day using the real number of days in the period** (not a fixed 30), largest item, category breakdown.
3. **Delete the hardcoded recurring list and total** (Adobe / Google Workspace / Shopify) and the **top-products list** (AFAB Pro Plan …). Show an empty state or hide the section until recurring (Phase 13) and a products/services model exist. Don't show discounts/refunds/gross-vs-net until the data model defines them.
4. Make the Invoices page stop showing the demo "upcoming invoices" now (empty state) — it gets real data in Phase 9.
5. Frontend: filters/pagination, loading/empty/error, currency formatting per business, list refresh after add/edit/delete.
6. **Tests:** revenue total = sum of income transactions for the period; same for expenses; empty period; boundaries.

**Done when:** every value on Expenses and Revenue comes from the database; add/edit/delete reflect in lists and summaries.

> 🏁 **Milestone M1 reached:** a small business can record money and trust every number it sees.

---

### Phase 4 — Multi-business foundation · M–L

**Goal:** switch between businesses safely; per-plan limits come in Phase 5.

**Data model (forward-only migrations)**
1. New `business_members(business_id, user_id, role, status)`; backfill one `OWNER` row per existing business.
2. Drop the unique constraint on the owner column (rename `user_id` → `owner_user_id`); add `archived_at` to `businesses`; optional `users.last_active_business_id` (convenience only).
3. Every business-owned table keeps `business_id`; every new module must too.

**Request context (the security-critical part)**
- The client sends `X-Business-Id` on every business-scoped request (set automatically by `fetchClient`).
- A `BusinessContextResolver` loads the membership for *(authenticated user, header)* → **403 if none**; if the header is missing, use the default business. **The header is a hint; the membership check is the control.**
- Services take a `BusinessContext`; the `CurrentBusinessService` from Phase 0 becomes this resolver.

**APIs:** `GET /businesses`, `POST /businesses`, `PUT /businesses/{id}`, `DELETE /businesses/{id}` (archive, owner only), `PUT /user/me/active-business`.

**Frontend:** business switcher in the sidebar/header ("Add business" opens the onboarding wizard; disabled with an upgrade prompt at the cap in Phase 5). `activeBusinessId` in `lib/auth-store.ts`; **include it in every data key and clear/refetch everything on switch**; currency, timezone and fiscal year come from the *active* business.

**Decide explicitly:** downgrade (5 → 1) never deletes data — extra businesses become read-only/archived and the user chooses which stays active; deleting a business = archive first, purge later with a backup policy.

**Tests:** cross-business access with a foreign id in the header, missing/invalid header, revoked membership, audit entries carry `business_id`.

**Done when:** a user can own several businesses, switch between them, and never see another business's data.

---

### Phase 5 — Plans & entitlements engine · M

**Goal:** every plan row in your UI becomes enforceable on the server. No payments yet.

**The matrix (from `PlansScreen.tsx` — confirm it)**

| Feature | Key | Free | Plus | Pro |
|---|---|---|---|---|
| Price / month (UI) | — | $0 | $9.99 (yearly shown $7.99) | $19.99 (yearly shown $15.99) |
| AI Chat & Insights | `ai.chat.queries_per_month` | 10 | 100 | 300 |
| AI Recommendations | `ai.recommendations` | ✗ | ✓ | ✓ (advanced) |
| Cash-flow forecasting | `forecast.cashflow` | ✗ | ✓ | ✓ |
| Financial reports | `reports.level` | basic | advanced | advanced + custom |
| Invoices | `invoices.per_month` | 5 | 50 | unlimited |
| Users | `team.users` | 1 | up to 3 | up to 5 |
| Businesses | `business.max` | 1 | up to 3 | up to 5 |
| Data export | `export.per_month` | 5 | 15 | unlimited |
| Email / priority support | `support.email` / `support.priority` | ✗ / ✗ | ✓ / ✗ | ✓ / ✓ |
| Free trial | `trial.days` | — | 7 | 7 |

**Tables:** `plans`, `plan_entitlements(plan_id, feature_key, type[BOOLEAN|LIMIT|QUOTA|LEVEL], value)`, `subscriptions(owner_user_id, plan_id, status[TRIALING|ACTIVE|PAST_DUE|CANCELED|EXPIRED], period_start, period_end, trial_end, cancel_at_period_end, provider, provider_subscription_id)`, `usage_counters(owner_user_id, feature_key, period_start, used)`, `subscription_events`. Every account gets a `FREE` subscription (backfill existing users).

**Engine:** `EntitlementService.check / consume / snapshot`. `consume` is **atomic** (`UPDATE … SET used = used + :n WHERE used + :n <= :limit`; 0 rows = limit reached). Enforce with `@RequiresEntitlement(...)` plus explicit service checks. Error contract: `403 {code:"PLAN_LIMIT_REACHED", feature, limit, used, upgradeTo}`; one global frontend handler opens the upgrade modal. `useEntitlements()` (from `GET /subscription/me`) is **UX only**.

**Race-safe business cap:** in one transaction, lock the subscription row (`SELECT … FOR UPDATE`), count owned non-archived businesses, compare with `business.max`, insert.

**Trial:** 7 days on Plus/Pro, once per account; at `trial_end` fall back to Free using the Phase 4 downgrade rules. Until billing exists, assign plans by seed/admin endpoint so every gate is testable.

**Where gates apply:** `business.max` (Phase 4 create), `export.per_month` (Phases 6–7), `reports.level` (Phase 6), `invoices.per_month` (Phase 9), `team.users` (Phase 17), `forecast.cashflow` / `ai.recommendations` (Phase 15), `ai.chat.queries_per_month` (Phase 16).

**Tests:** concurrent consume cannot exceed the limit, concurrent business creation cannot exceed the cap, downgrade behavior, direct API calls with a Free account are rejected.

**Done when:** each limit in the table is enforced by the backend and tested; the UI shows the upgrade modal on `PLAN_LIMIT_REACHED`.

---

### Phase 6 — Reports & Export · M

**Goal:** reports built on the same definitions as the Dashboard.

**Where:** new `reports/` package; frontend `dashboard/reports/page.tsx`, `lib/api/reports.ts`.

**Steps**
1. Endpoints on the stats layer: Profit & Loss, cash flow, expense by category, monthly and yearly summaries, comparison between two periods. **Cash basis (D4)**; never mix invoice issue date with cash received.
2. **Export CSV first, PDF second.** Each export consumes `export.per_month`; PDF/branded layout can use the stored business logo.
3. `reports.level`: basic = monthly + category; advanced = yearly, comparison, trends; custom (Pro) = saved report definitions.
4. Frontend: filters (period, type, currency), Recharts charts, export buttons with quota feedback, loading/empty/error, RTL charts and tables.
5. **Tests:** rounding, empty months, year boundaries, timezone, never summing different currencies into one total, quota consumption.

**Done when:** report totals equal the underlying transactions; CSV/PDF open correctly and state period + currency; no hardcoded figures.

---

### Phase 7 — Settings quick wins · S

**Goal:** replace the "Coming soon" catch-all for the tabs that are cheap and PRD-relevant.

**Steps**
1. **Appearance:** reuse `theme-provider`/`theme-toggle`; persist the choice in user preferences (V6 exists).
2. **Language:** reuse `language-switcher`; persist `locale`; apply it at login. **Add French (`fr`)** next to `en`/`ar` — `next-intl` is already set up.
3. **Data & Export:** export all transactions as CSV (reuses Phase 6, consumes quota) and **Delete account** (PRD in scope; not found in the backend) with re-authentication, confirmation, and a clear data-retention rule.
4. Give each tab its own `page.tsx` (like `general/` and `security/`) and remove it from the catch-all. Notifications / Integrations / Users & Permissions stay "Coming soon" honestly until Phases 14 / 21 / 17.

**Done when:** these tabs persist across sessions/devices and no longer show the placeholder.

> 🏁 **Milestone M2 reached:** multi-business, enforced plans, reports and core settings — a free beta can open.

---

### Phase 8 — Customers · M

**Goal:** customer records that Invoices (and the Dashboard) depend on.

**Where:** new `customers/` package + migration `customers` (+ nullable `customer_id` on `transactions`); frontend `dashboard/customers/page.tsx` (new), `components/dashboard/TopCustomers.tsx`.

**Steps**
1. Table `customers`: `business_id` NOT NULL, name, optional email/phone/notes, status, timestamps; index on `business_id`; duplicate rule (e.g. unique email per business when present).
2. CRUD (+ archive) with search and pagination; every query scoped by the active business; ownership checks.
3. Link transactions to a customer (select in `AddTransactionModal`; deleting/archiving a customer never deletes transactions).
4. UI: list + search + create/edit form + detail (total received, recent transactions).
5. Dashboard `TopCustomers` from real income per customer; remove the "Coming soon" label from the sidebar link.
6. **Tests:** isolation by business, duplicate handling, archive keeps history.

**Done when:** customer CRUD works end-to-end, is isolated per business, and the sidebar link opens a real page.

---

### Phase 9 — Invoices (real) · M–L

**Goal:** an invoice is its own record — money received is a separate fact.

**Data model:** `invoices(business_id, customer_id, number, issue_date, due_date, status, subtotal, tax_amount, total, notes, paid_transaction_id, …)` and `invoice_items(invoice_id, description, quantity, unit_price, line_total)`. Statuses `DRAFT → SENT → PAID`, plus `CANCELLED`; `OVERDUE` is derived from `due_date` (not stored). Unique `(business_id, number)`; numbers generated **atomically** per business. Tax: optional amount/rate only (D8).

**Steps**
1. Decide numbering format, allowed status transitions, and tax handling before coding.
2. Migrations, entity/repository/service/controller/DTOs; CRUD with business + customer ownership validation; totals computed server-side with `Money`.
3. **Mark paid** is atomic and **idempotent**: sets status, creates exactly one income transaction (linked via `paid_transaction_id`), so income is never counted twice.
4. Enforce `invoices.per_month` through the entitlement engine.
5. Replace the generic `AddTransactionModal` on this page with an invoice form (customer, items, dates); delete the invoice summary code in `TransactionService`.
6. Sub-phase 9b (after CRUD and totals are stable): PDF generation, send by email, payment link. Never claim "sent" or "paid" before the real integration exists.
7. **Tests:** numbering under concurrency, totals/rounding, transition rules, mark-paid twice = one transaction, plan quota, tenant isolation.

**Done when:** invoices are independent of income transactions, totals/status are correct, and no sample invoices remain.

---

### Phase 10 — Budgets · M

**Where:** new `budgets/` package + migration; frontend `dashboard/budgets/page.tsx`. *(No mockup exists — design it with the current design system first.)*

**Steps**
1. Table `budgets(business_id, category_id NULL = overall, amount, period, start/end, alert_threshold)`.
2. CRUD with validation and isolation; progress computed **server-side** from expense transactions in the period (never a number sent by the frontend).
3. UI: list, create/edit/delete, progress bars with warning/over-budget states.
4. Threshold crossing is detected by the backend now; real alerts arrive with Notifications (Phase 14).
5. **Tests:** overall vs category budgets, period boundaries, over-budget amounts.

**Done when:** budget, spent and remaining always match the transactions.

---

### Phase 11 — Savings goals · S–M

1. Decide what `current_amount` means: manually entered **or** sum of contributions — not both without rules.
2. Table `savings_goals` + CRUD; progress (percentage, remaining, deadline, status) computed server-side.
3. UI `dashboard/goals`: create/edit/pause/complete.
4. **Tests:** zero amount, target below current, past deadline, status transitions.

**Done when:** a user can create and track goals; progress is computed by the server.

---

### Phase 12 — Investments (manual tracking only) · S–M

1. Model: type (stock, crypto, fund, real estate, other), name, quantity (optional), invested amount, current value, purchase date, note.
2. CRUD with isolation; UI `dashboard/investments`.
3. Gain/loss and return with divide-by-zero protection; label them clearly as manual estimates. **No live prices** in V1.
4. **Tests:** return calculations, zero invested amount, isolation.

**Done when:** CRUD works and calculations are tested.

---

### Phase 13 — Recurring transactions + Receipts · M–L

**A. Recurring**
- Table `recurring_rules(business_id, template fields, frequency, interval, start/end, next_run, active)`.
- A `@Scheduled` job generates transactions **idempotently**: `UNIQUE(rule_id, run_date)`, business-timezone aware, pause/cancel, safe to re-run after a restart (test it).
- Then — and only then — re-enable the recurring section in Expenses/Revenue with real data.

**B. Receipts**
- MinIO with **private** buckets; file type/size limits; store the object key + metadata (not a public URL); authorized upload/download via short-lived presigned URLs; deny cross-business access.
- UI: attach/preview receipts on an expense.

**Tests:** scheduler idempotency and retries, receipt access across businesses, upload limits.

**Done when:** a recurring rule creates each transaction exactly once; receipts are private and business-scoped.

---

### Phase 14 — Notifications + Calendar · M–L

**Steps**
1. `notifications` table/API with read/unread and pagination; bell UI; events only from things that really happen: budget threshold (Phase 10), upcoming recurring (13), invoice due/overdue (9), goal completed (11).
2. Notification preferences tab in Settings (remove it from the catch-all); email delivery through `EmailService` once in-app works (and swap SMTP for a transactional provider — see Phase 22).
3. **Calendar** (`dashboard/calendar`, new): monthly view of invoice due dates, recurring payments, and custom reminders; feed `ReminderCard` on the Dashboard with real data.
4. **Tests:** notification created once per event, preferences respected, calendar entries match source records.

**Done when:** reminders on the Dashboard and Calendar come from real data; no notification fires for an event that didn't happen.

> 🏁 **Milestone M3 reached:** a complete small-business toolkit.

---

### Phase 15 — AI-A: insights, recommendations, forecast (no LLM) · M–L

**Goal:** deterministic, testable intelligence — the trustworthy facts the assistant will later talk about. This is what the plan rows *Cash-flow forecasting* and *AI Recommendations* sell.

**Guardrails (set before any AI code)**
- Backend-only: the provider key never reaches the browser. Facts come from code; a model may only explain them.
- Tenant isolation: AI features read data only through `BusinessContext`-scoped queries.
- Label all of it "AI-generated — not financial advice"; don't call a plain calculation "AI" unless a model is behind it.

**Output** is a structured insight: `{type, severity, titleKey, params, evidence:{txIds, metrics}, createdAt, dismissedAt}` — i18n **keys + params**, translated in the frontend (EN/AR/FR), never baked-in sentences. Table `insights`; a nightly `@Scheduled` job per business plus on-demand refresh; feeds `AIInsightsCard`.

| Insight | Method |
|---|---|
| Spending spike | Category spend vs 3-month median / robust z-score |
| Recurring subscriptions detected | Same vendor/description + similar amount, monthly cadence |
| Duplicate suspects | Same amount + date window + description |
| Revenue concentration | Top customer's share of revenue |
| Late receivables | Overdue invoices total (Phase 9) |
| Runway | Cash balance ÷ average monthly burn |
| Budget overrun projection | Spend to date ÷ days elapsed × days in month (Phase 10) |
| **Cash-flow forecast** | Baselines first (moving average, seasonal naive, ETS), **backtested per business**; with too little history show "not enough data" instead of guessing |

Recommendation = insight + templated action ("review subscription X", "send reminders for overdue invoices"). Gating: `forecast.cashflow` and `ai.recommendations` (Plus+); Pro = "advanced" (more insight types, longer horizon, anomaly alerts, what-if scenarios).

**Tests:** each insight against a fixed dataset, forecast backtest metrics, "not enough data" path, tenant isolation, entitlement gating.

**Done when:** the Dashboard insight card shows real, explainable insights and a forecast with honest uncertainty.

---

### Phase 16 — AI-B: assistant (LLM + tools, metered) · L

**Where:** new `ai/` package; frontend `/dashboard/ai` (replace the plans placeholder; plans stay at `/plans` and `/upgrade`).

**Architecture**
- `AiController` (SSE streaming) → `AiOrchestrator` → `LlmClient` interface (first implementation: Gemini; provider-swappable) → `ToolRegistry` → `AiUsageService`; tables `conversations`, `messages`.
- **Read-only tools**, scoped server-side (the model passes filters, never a business id): `get_kpis(period)`, `get_category_breakdown(period, type)`, `search_transactions(filters, limit ≤ 50)`, `get_forecast(horizon)`, `get_insights()`, `get_overdue_invoices()`. Write tools only much later, and only as drafts that need user confirmation.
- System prompt carries business currency, locale and today's date: "answer only from tool results; say so when data is missing."
- **Grounding check:** key figures in an answer must appear in tool outputs, otherwise retry or fall back to a safe message.

**Safety and cost**
- **Untrusted text:** transaction descriptions, notes, customer names and imported files are user-controlled → treat as data, never as instructions (prompt injection).
- Minimize what leaves your servers (aggregates over rows; no emails/phones/ids); check the provider's retention/training terms.
- Meter with `consume("ai.chat.queries_per_month")` **before** the call, refund on provider failure; per-day cost cap; Redis rate limit; max tool calls per turn, max tokens, timeouts, circuit breaker.
- Conversation retention policy + user-side delete; log metadata only (no secrets or full financial payloads).

**Frontend:** chat UI with suggested questions, quota meter ("7/10 used"), upgrade CTA at the limit, thumbs up/down (this feedback becomes Phase 19 data), correct RTL for streamed Arabic.

**Evals:** a golden set of ~50–100 questions over a synthetic business, run in CI against recorded tool outputs so prompt/model changes can't silently regress.

**Tests:** tenant isolation for **every tool**, prompt-injection cases, quota atomicity, provider-down fallback.

**Done when:** a user can ask questions about their own business in EN/AR/FR, answers are grounded in tool results, and the quota is enforced.

---

### Phase 17 — Team & roles · L

Your plan table promises **Users 1/3/5**, so this must be built — or that row removed from the UI.

1. Roles (Owner / Admin / Member / Accountant read-only) and the exact permission matrix per role, written down first.
2. Built on `business_members` from Phase 4: invitations (hashed, expiring tokens), accept/revoke, role changes, per-endpoint permission checks in the **backend** (hiding a button in React is not authorization).
3. Enforce `team.users` through the entitlement engine; define what happens to extra members on downgrade (read-only/suspended, never deleted).
4. Settings → Users & Permissions UI; audit-log entries for member changes.
5. **Tests:** each role × each sensitive endpoint, invitation reuse/expiry, seat limit under concurrency.

**Done when:** invited users only do what their role allows, and seats follow the plan.

---

### Phase 18 — Billing · L

1. **Provider (D10):** verify current availability for Tunisia — local gateways (e.g. Konnect, Paymee) vs a merchant of record (e.g. Paddle, Lemon Squeezy). To my knowledge Stripe does not onboard Tunisian merchants directly — check its current docs. Start provider onboarding long before this phase.
2. **Flow:** the backend creates the checkout session from the **server-side plan catalog** (never a client-sent price) → redirect → **webhook** confirms → subscription updated.
3. **Webhooks:** verify signatures; idempotency table (`processed_events`); handle payment succeeded / failed / canceled / refunded.
4. **Policies to decide:** grace period (`PAST_DUE` for N days, then downgrade), proration on upgrade/downgrade, cancel at period end, VAT/tax (depends on the provider), how yearly pricing is presented.
5. **UI:** replace the local `activePlan`/trial state in `PlansScreen` with server state; billing history under Settings → Subscription. **Never show "subscribed" until the webhook confirms.**
6. **Tests:** provider sandbox, duplicate/replayed webhook, failed payment → grace → downgrade, trial expiry.

**Done when:** a paid upgrade, downgrade and cancellation all work end-to-end with correct entitlements.

> 🏁 **Milestone M5 reached:** a paid launch is possible (after Phase 22's final pass).

---

### Phase 19 — AI-C: learned models · L

**Don't fine-tune an LLM first.** Recommendations need correct numbers about *this* business; fine-tuning teaches style and patterns, not per-user facts, and needs many clean examples, consent to train on financial data, and ongoing maintenance. Where training genuinely pays off:

| Goal | Best approach | Fine-tune an LLM? |
|---|---|---|
| Recommendation text | Phase 15 computes, the LLM narrates | No |
| Q&A over a user's data | Tool-calling (Phase 16) | No |
| **Auto-categorize transactions** | Rules → embeddings/LLM few-shot → a **small classifier trained on user-confirmed corrections** | Small model, not an LLM |
| Anomaly detection | Robust stats → Isolation Forest | No |
| Forecast | Statistical models chosen by backtest | No |
| Receipt extraction | OCR / vision model with a fixed output schema | Not initially |
| Tone/format (e.g. Tunisian-Arabic phrasing, strict JSON) | Prompt + few-shot + structured output first | Maybe — **only if evals show a persistent gap** |

**Prerequisites (start collecting from Phase 10 onward, legitimately):** opt-in consent in Terms/Settings; `category_feedback` and `ai_feedback` tables; anonymization (strip names, emails, ids); a decision on global vs per-tenant models; model registry/versioning, offline evaluation before deploy, rollback; hosting choice (Python microservice such as FastAPI vs provider-hosted).

---

### Phase 20 — Advanced pack · L (pick by value)

| Priority | Feature | Why | Suggested tier |
|---|---|---|---|
| P1 | **Multi-currency + FX rates** (per-transaction currency, base-currency reports, consolidated multi-business view) | Cross-border sales; "all my businesses" view | Plus+ |
| P1 | **CSV/Excel import** with column mapping + duplicate detection | Fastest way to bring history in | All (rows capped) |
| P1 | **Bank-statement import** (CSV/OFX) + auto-categorization | Bank data *without* bank APIs | Plus+ |
| P1 | Global search + command palette (`components/ui/command.tsx` exists) | Daily-use speed | All |
| P1 | Tags, bulk actions, saved filters, undo delete | Power-user basics | All |
| P1 | **Audit-trail viewer** (`AuditLog` table exists) | Trust, supports Team | Pro |
| P2 | **Receipt OCR** (prefill amount/date/vendor) | Removes manual entry | Plus+ |
| P2 | Scheduled report emails | Retention | Plus+ |
| P2 | Branded PDF reports (logo already stored) | Looks professional | Pro |
| P2 | **API keys + webhooks** | Integrations without building each | Pro |
| P2 | VAT tagging / tax summary (PRD excludes tax *calculation*; verify local rules before promising anything) | Common SME need | Pro |
| P2 | What-if scenarios on the forecast | Pro value for Phase 15 | Pro |
| P3 | **Accountant access** (read-only role) | Very common workflow | Pro |
| P3 | Accounting export formats (QuickBooks/Xero-style CSV) | Cheap alternative to integrations | Pro |
| P3 | **Admin back-office** (users, plans, maintenance mode — a "system under maintenance" mockup already exists) | Operate without SQL | internal |
| P3 | PWA/offline or a **Flutter companion app** (PRD defers mobile) | Natural v2 | All |
| P3 | Onboarding checklist/tour, feature flags, privacy-first analytics | Activation, safe rollouts | internal |

---

### Phase 21 — Integrations · L

The PRD excludes bank APIs, open banking and payment gateways from V1 — revisit after launch with real demand. Keep the Integrations tab honestly "Coming soon" until then; the API-keys/webhooks feature (Phase 20) covers early requests.

---

### Phase 22 — Production hardening & release · M (runs continuously; final pass before any public release)

**Security**
- [ ] Token storage decision (D9): BFF + HttpOnly/Secure/SameSite cookies, or consciously accept `localStorage`; `proxy.ts` is UX routing, **not** authorization.
- [ ] Hash verification/reset one-time tokens (verify the implementation, then test it).
- [ ] `JWT_SECRET` strong and from environment only; production **fails fast** when any secret is missing; no default secret.
- [ ] Rate limiting through Redis (the controller-local Bucket4j bucket is per instance); stricter limits on login/forgot-password.
- [ ] CORS = exact production origins; review `allowCredentials`.
- [ ] 2FA (columns exist; add setup/verify endpoints) and Delete account if not done in Phase 7.
- [ ] Swap SMTP for a transactional provider (SES / Resend / SendGrid).
- [ ] Dependency and container image scanning; secrets scanning in CI.

**Quality**
- [ ] Tenant-isolation test for **every** business-scoped endpoint; entitlement-bypass tests (direct API calls on a Free account).
- [ ] Migrations run on a clean DB **and** on a copy of production-like data.
- [ ] Playwright smoke: signup → onboarding → add transaction → dashboard → switch business → export.
- [ ] English / Arabic / French, RTL, mobile widths, keyboard navigation, focus states, empty/error states.
- [ ] Performance: indexes for the stats queries, bundle size, pagination everywhere.

**Operations**
- [ ] Production Docker build + CI/CD; environment separation (dev/staging/prod).
- [ ] Observability: error tracking, metrics, alerts, health checks; Postgres backups **and a tested restore**.
- [ ] Data-protection/compliance review for your markets (e.g. Tunisian data-protection law, GDPR if you serve EU users) — verify, don't assume.
- [ ] Landing pages from the PRD: Features, About, Contact, FAQ, Privacy, Terms.
- [ ] OpenAPI exported per module (`identity`, `finance`, `business`, `subscription`, `ai`, …); README and roadmap current.

---

## 6. Cross-cutting tracks (alongside every phase)

- **Security:** every new endpoint gets an ownership test; every new gate gets a bypass test; no secrets in code, logs, docs or prompts.
- **Tests:** a phase isn't done without tests for validation, ownership, and the business rules of that phase.
- **i18n/RTL:** EN + AR + FR keys for every label, error code and insight key; numbers, dates and currencies formatted by locale.
- **Docs:** update the OpenAPI file, `Context/*.md` and this roadmap at the end of each phase (your own "contract versioning rule").
- **Honesty in the UI:** no demo data, no fake "AI", no fake "paid/sent" states — empty states instead.

---

## 7. Definition of Done (copy into every phase)

- [ ] Backend, DB and UI are connected; no mock/demo data reaches the user.
- [ ] Ownership/tenant isolation enforced in the **backend** and covered by tests.
- [ ] Validation and error codes are correct (400/401/403/404/409, not 500).
- [ ] Loading, empty, error and success states exist.
- [ ] EN / AR / FR and RTL checked; mobile width checked.
- [ ] Migration is forward-only and tested on a clean DB.
- [ ] OpenAPI + README/roadmap updated.
- [ ] Real results of `lint`, `tsc`, `build`, `test`, `verify` recorded — never claim a check passed if it wasn't run.

---

## 8. Ready-to-paste prompt for your coding agent (Phases 0–1)

> Work only on **Phase 0** and then **Phase 1** of `AFAB_Master_Roadmap.md`. Before changing anything, read `project/Context/AFAB_AI_PROJECT_CONTEXT.md`, `AFAB_BACKEND_CONTEXT.md`, `AFAB_FRONTEND_CONTEXT.md` and inspect the current implementation. Keep Next.js 16 and Spring Boot as they are; no unrelated refactors; no mock finance data; no payment integrations; do not add AI yet. Phase 0: global exception handling (400/403/404/409, generic 500), `NUMERIC(19,4)` migration + `Money` helper, `CurrentBusinessService` replacing all `findByUserId` business lookups, Testcontainers + CI. Phase 1: category CRUD with ownership/type rules, transaction update, enum validation, size caps, filters, soft delete with audit, tests for tenant isolation and validation, update `finance.openapi.yaml`, frontend types/services and UI states in English/Arabic/RTL. Use forward-only Flyway migrations. At the end run every possible check and report exactly what passed and what could not be run. Do not claim success for anything you did not execute.

---

## 9. Where the sources disagreed — and what I chose

| Topic | Earlier files / ChatGPT | Chosen here | Why |
|---|---|---|---|
| First feature phase | Mine: Dashboard first. ChatGPT: Categories + Transactions first. | **Transactions first**, then stats + Dashboard | F5/F6 are integrity holes; every aggregate depends on them. ChatGPT was right on this. |
| Hardcoded summaries | I marked Expenses/Revenue as working; ChatGPT flagged demo data. | **Demo data removed in Phases 2–3 (F7)** | Verified in `TransactionService`. |
| Baseline verification | Missing from my files; ChatGPT had Phase 0. | **Phase 0 added** | You can't plan on code you haven't run. |
| Secrets | I said `.env`; ChatGPT said `.env.example`. | **Both** contain password-like values | Verified; rotate both. |
| Multi-business timing | Mine: early. ChatGPT: late (Phase 12). | **Right after the core (Phase 4)** | Cheap before Customers/Invoices/Budgets exist, expensive after. |
| Entitlements | Mine: early. ChatGPT: late. | **Phase 5, before Reports/Invoices/AI** | Those features are plan-limited. |
| Invoices | Mine: tracker or full. ChatGPT: real model with items and mark-paid. | **Real model (ChatGPT's design) + quota** | The plan counts invoices per month. |
| Budgets / Goals / Investments | ChatGPT had full phases; mine only Budgets/Goals. | **All three, manual investments** | They're PRD in-scope. |
| AI | ChatGPT: out of MVP, third-party APIs forbidden. Mine: post-MVP decision. | **In scope (your decision), phased 15 → 16 → 19** | Docs must be updated (D1). |
| Dashboard money format | Only I noticed strings + `Locale.ENGLISH`. | **Numbers from backend, formatting in frontend** | Breaks Arabic otherwise. |
| Money precision, 3-decimal currencies | Only I noticed. | **Phase 0 migration** | Your home currency (TND) needs 3 decimals. |
| Error handling (500 for everything) | Neither file had it. | **Phase 0** | Found while verifying. |

---

## 10. Your first 10 actions

1. Rotate the mail credential(s) and any other secret from `.env` / `.env.example`.
2. Add the root `.gitignore`; remove `target/` and `.idea/` from the repo.
3. Record D1/D2/D11 (AI, multi-business, scope source) in the PRD and `Context/*.md`.
4. Run the baseline (Maven wrapper, `mvn test/verify`, `npm ci`, lint, `tsc`, build) and write down the real results.
5. Walk the full auth + onboarding flow in `/en` and `/ar`; note what breaks.
6. Implement global exception handling.
7. Migration `NUMERIC(19,4)` + `Money` helper; introduce `CurrentBusinessService`.
8. Add Testcontainers + CI with one tenant-isolation test.
9. Start **Phase 1** (categories → transaction update → validation → tests).
10. Begin payment-provider research in the background.

When Phase 0 and 1 are done, send me the diff and the test results and we review them before Phase 2.
