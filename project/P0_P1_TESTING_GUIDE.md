# AFAB — P0 & P1 Team Testing Guide

> **Branch:** `feat/p0-p1-security-finance-foundation`
> **Purpose:** Step-by-step manual browser walkthrough and automated test verification guide so every team member can test every P0 (Security & Reliability) and P1 (Core Business Finance) deliverable consistently.

---

## 1. Prerequisites & Local Environment Setup

### 1.1 Configure `project/.env`
Copy `project/.env.example` to `project/.env` (never commit `.env`) and ensure the following local settings are configured:

- `JWT_SECRET` — valid standard Base64 string decoding to **>= 32 bytes** (e.g., generate with `openssl rand -base64 64`). Startup fails fast if missing, weak, or still set to `CHANGE_ME`.
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET=afab-receipts`, `MINIO_PUBLIC_ENDPOINT=http://localhost:9000`
- `AFAB_COOKIE_SECURE=false` and `AFAB_COOKIE_SAME_SITE=Lax` *(for local `http://localhost:3000`; `prod` enforces `Secure=true`)*
- `AFAB_RATE_LIMIT_ENABLED=true` and `AFAB_RATE_LIMIT_FAIL_MODE=fail_open` *(or `fail_closed` while Redis is running)*
- `AFAB_ALLOW_DEV_OTP=true` *(optional, only active under the `local` profile to allow local signup without SMTP)*

### 1.2 Start Backend Infrastructure & API
From the repository root:

```powershell
cd project
docker compose up -d
docker logs -f afab-backend
```

**Verify startup:**
- Logs show `SecurityConfigurationValidator : JWT signing key validated`.
- Flyway applies migrations **`V1` through `V23`** cleanly (existing data is preserved: `V17` hashes legacy refresh tokens; `V19` marks legacy transactions as `LEGACY_UNKNOWN` without altering amounts).
- `Started AfabApplication` appears on port `8080`.
- Health check responds `UP`:
  ```powershell
  Invoke-RestMethod http://localhost:8080/api/v1/health
  ```

### 1.3 Start the Frontend
In a second terminal:

```powershell
cd project\frontend
npm install
npm run dev
```

Open **`http://localhost:3000/en/login`** (English) or **`http://localhost:3000/ar/login`** (Arabic RTL).

---

## 2. Manual Browser Walkthrough — P0 (Security & Reliability)

### P0.1 — Secrets & Sanitized Logging
1. Perform login, signup, and forgot-password actions.
2. Inspect backend logs:
   ```powershell
   docker logs afab-backend --tail 60
   ```
3. **Pass Criteria:**
   - Emails in logs are masked (e.g., `u***@domain.com`).
   - **Zero** OTP codes, password reset links/tokens, JWT access tokens, refresh tokens, or SMTP passwords appear in logs.
   - `project/.env.example` contains only `CHANGE_ME_...` placeholders.

### P0.2 — HttpOnly Cookies, Memory-Only Access Tokens & CSRF Protection
1. Log in at `/en/login`.
2. Open Browser DevTools (**`F12`**):
   - **Application → Local Storage (`http://localhost:3000`):** confirm **no** `accessToken` or `refreshToken` keys are stored.
   - **Application → Cookies (`http://localhost:3000`):** confirm:
     - `refreshToken` exists with **`HttpOnly = ✓`** and `Path = /api/v1`.
     - `afab_csrf` exists (`Path = /`).
3. **Hard-refresh (`Ctrl + Shift + R`):**
   - Confirm you stay logged in seamlessly.
   - In **Network tab**, inspect `POST /api/v1/auth/refresh`:
     - Request includes `X-CSRF-Token` header and `Cookie: refreshToken=...`.
     - Response JSON contains `accessToken` and `csrfToken`, and does **NOT** contain `refreshToken`.
4. **Logout:**
   - Open the bottom-left profile menu → click **Logout**.
   - Confirm both cookies expire (`Max-Age=0`) and navigating back to `/en/dashboard` redirects to `/en/login`.

### P0.3 — Distributed Redis Rate Limiting
1. Run this PowerShell snippet to send 12 invalid login attempts:
   ```powershell
   1..12 | ForEach-Object {
     try {
       Invoke-RestMethod -Method Post -Uri "http://localhost:8080/api/v1/auth/login" `
         -ContentType "application/json" `
         -Body '{"email":"unknown-user@test.local","password":"wrong"}' | Out-Null
     } catch {
       "Attempt $_ -> HTTP $($_.Exception.Response.StatusCode.value__)"
     }
   }
   ```
2. **Pass Criteria:**
   - Attempts 1–10 return HTTP **`401`** with a generic invalid-credentials message (does not reveal whether the email exists).
   - Attempts 11–12 return HTTP **`429 Too Many Requests`** with a `Retry-After` header backed by Redis.

### P0.4 — Safe Account Deletion & Ownership Transfer
1. Log in and go to **Settings → General → Delete Account**.
2. Click to open the deletion modal while owning at least one active business.
3. **Pass Criteria:**
   - Preflight check **blocks deletion** (HTTP `409` if attempted directly) and lists the active business(es) preventing deletion.
   - Modal offers an inline **Archive Business** action (or ownership transfer via `POST /api/v1/business/{id}/transfer-ownership`) instead of silently cascade-deleting business financial records.
   - *(Cancel out unless testing with a throwaway user.)*

### P0.5 — Multi-Tenant Business Isolation
1. Click the top-left **Business Switcher** → create a second business (e.g., `Business B`).
2. Add a transaction, customer, invoice, recurring rule, and budget in `Business A`.
3. Switch to `Business B`.
4. **Pass Criteria:**
   - None of `Business A`'s transactions, customers, invoices, recurring schedules, receipts, or budgets appear in `Business B`.
   - Any API call sending a foreign `X-Business-Id` or foreign entity UUID returns HTTP **`403 Forbidden`**.

---

## 3. Manual Browser Walkthrough — P1 (Core Business Finance)

### P1.1 — Transaction Currency & Immutable FX Snapshots
1. Open **`/en/dashboard/transactions`** → click **Add Transaction**.
2. Create an **Expense** in a foreign currency (e.g., `100 EUR` on a `USD` or `TND` business).
   - **Verify:** Live FX rate and converted base-currency preview appear before saving.
3. Click the saved transaction to open the **Detail Drawer**:
   - **Verify:** Shows converted base amount, original foreign amount + applied rate, and `FX Snapshot` provenance.
4. Click **Edit** on that transaction:
   - **Verify:** Original currency is **locked** and cannot be changed retroactively.
5. Open **`/en/dashboard/settings/general`** → change the business base currency:
   - **Verify:** Modal confirms historical transactions will **not** be rewritten using today's rate.
   - Re-open the previous transaction and confirm its converted amount, base currency, and exchange rate are **unchanged**.

### P1.2 — Real Customer Backend (Zero `localStorage` Fallback)
1. Open **`/en/dashboard/customers`** → click **Add Customer** → create a customer (e.g., `Atlas Retail`, `billing@atlas.test`).
2. Hard-refresh (`F5`) → confirm customer persists from PostgreSQL.
3. Test **Edit**, **Search**, **Group/Status Filter**, and **CSV Export**.
4. *(Failure-state check)* Temporarily stop the backend (`docker stop afab-backend`), reload `/customers`, and verify an explicit **error banner with Retry** appears (no silent `localStorage` or mock fallback). Restart backend (`docker start afab-backend`).

### P1.3 — Real Invoice Lifecycle & Cash-Basis Payments
1. Open **`/en/dashboard/invoices`** → click **New Invoice**:
   - Select your customer, add 2 line items totaling e.g. `1,000`, and save as **Draft**.
   - **Verify:** Status is `DRAFT`. Check `/dashboard/transactions` — **zero** Income Transaction created.
2. Open the draft invoice → edit a line item → click **Issue Invoice**:
   - **Verify:** Status changes to `UNPAID`, invoice number is assigned (`INV-YYYY-XXXX`), and still **zero** Income Transaction exists.
3. Click **Record Payment** and record a partial payment of `400`:
   - **Verify:** Status becomes `PARTIALLY_PAID`, Paid = `400`, Outstanding = `600`.
   - Check `/dashboard/transactions` → **exactly 1 Income Transaction (`+400`)** exists.
4. Record the remaining `600`:
   - **Verify:** Status becomes `PAID`, Outstanding = `0`, total Income Transactions = `2` (`400` + `600`).
   - Check `/dashboard/customers` → customer's real paid revenue reflects `1,000`.
5. Test **Cancel** on an unpaid invoice (verify cancelled invoices cannot receive payments).

### P1.4 — Recurring Transactions & Private Receipt Storage (MinIO)
#### Recurring Transactions (`/en/dashboard/recurring`)
1. Click **New Schedule** → create a **Monthly Expense** of `850` starting **today**.
2. Click **Run due now (`↻`)**:
   - **1st click:** Generates **1** completed transaction (`850`) and advances `Next Run` by 1 month.
   - **2nd click immediately:** Reports **0 due occurrences** (idempotent — zero duplicates).
3. Test **Pause / Resume**, **Edit**, and **Delete/Deactivate**.

#### Private Receipts (`/en/dashboard/transactions` → Detail Drawer)
1. Click any transaction to open the **Detail Drawer** → scroll to **Receipts**.
2. Click **Attach Receipt** and upload a valid `.pdf`, `.png`, `.jpg`, or `.webp` (<10 MB):
   - **Verify:** Appears in the list with filename, MIME type, and file size.
   - Click **Download** → verifies authenticated download works.
   - Click **Delete** → removes from MinIO and disappears from the list.
3. **Security validation test:** Rename a plain `.txt` or `.html` file to `fake.png` and try uploading:
   - **Verify:** Rejected with an explicit error (magic-byte inspection catches disguised payloads).
4. *(Optional)* Inspect MinIO Console at `http://localhost:9001` → bucket `afab-receipts` → confirm objects are stored privately under `businesses/{businessId}/transactions/{transactionId}/{uuid}.{ext}`.

### P1.5 — Business Budgets & Dashboard Integration
1. Open **`/en/dashboard/budgets`** → click **New Budget**:
   - Name: `Monthly OpEx`, Limit: `1000`, Category: `All Business Expenses`, Period: `Monthly`, Alert Threshold: `80%`.
   - **Verify:** With `850` in completed expenses this month (from P1.4), the budget card shows **`85%` — Approaching** (amber progress bar, `150` remaining).
2. Add another completed expense of `350` (`1,200` total) and reopen **`/en/dashboard/budgets`**:
   - **Verify:** Card shows **`120%` — Over Budget** (red progress bar, `Over by 200`, `0` remaining).
3. Create a **category-scoped** budget (e.g., Marketing) and confirm it counts only expenses in that category (including split transaction lines without double-counting).
4. Open **`/en/dashboard`** (Overview):
   - **Verify:** **Budget Progress** card shows active budgets, **Reminders** lists real over-budget/approaching alerts and overdue invoices, and **Top Customers** displays real paid customer revenue.

---

## 4. UI Quality Matrix (Responsive, Themes & Languages)

Verify across **Overview**, **Transactions (Detail Drawer)**, **Customers**, **Invoices**, **Budgets**, and **Recurring**:
- [ ] **Light Theme & Dark Theme:** Toggle the sun/moon switch in the top header; verify readable text, cards, tables, modals, badges, and chart tooltips in both modes.
- [ ] **English (`en`, LTR) & Arabic (`ar`, RTL):** Toggle the language button in the top header; verify translated labels, mirrored RTL layout, drawers sliding cleanly, and Arabic/English currency formatting.
- [ ] **Responsive Breakpoints:** Check desktop (`1440px`), narrow desktop / DevTools split (`1024px`), tablet (`768px`), and mobile (`390px`) — zero overlapping KPI text, zero horizontal page overflow, zero Recharts `width(-1) height(-1)` browser console warnings.

---

## 5. Automated Verification Commands

Run from the repository root (`AFAB/`):

### Backend Unit Tests (98 tests, ~25s)
```powershell
docker run --rm `
  -v "${PWD}\project\backend:/workspace/backend" `
  -v project_maven_cache:/root/.m2 `
  -w /workspace/backend `
  maven:3.9.9-eclipse-temurin-21 mvn -B test
```

### Full Backend Unit + Real-Infrastructure Integration Suite (104 tests: PostgreSQL 16 + Flyway V1–V23 + Redis 7 + MinIO)
```powershell
$net = "afab-it-net-$(Get-Random)"
try {
  docker network create $net | Out-Null
  docker run -d --name afab-it-pg --network $net -e POSTGRES_DB=afab_test -e POSTGRES_USER=afab_test -e POSTGRES_PASSWORD=afab_test_pass postgres:16-alpine | Out-Null
  docker run -d --name afab-it-redis --network $net redis:7-alpine | Out-Null
  docker run -d --name afab-it-minio --network $net -e MINIO_ROOT_USER=afabtestminio -e MINIO_ROOT_PASSWORD=afabtestminiosecret elestio/minio:latest server /data | Out-Null

  for ($i = 0; $i -lt 30; $i++) {
    docker exec afab-it-pg pg_isready -U afab_test -d afab_test 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 1
  }
  Start-Sleep -Seconds 2

  docker run --rm --network $net `
    -v "${PWD}\project\backend:/workspace/backend" `
    -v project_maven_cache:/root/.m2 `
    -w /workspace/backend `
    -e RUN_INTEGRATION_TESTS=true `
    -e POSTGRES_HOST=afab-it-pg `
    -e POSTGRES_PORT=5432 `
    -e POSTGRES_DB=afab_test `
    -e POSTGRES_USER=afab_test `
    -e POSTGRES_PASSWORD=afab_test_pass `
    -e REDIS_HOST=afab-it-redis `
    -e REDIS_PORT=6379 `
    -e MINIO_ENDPOINT=http://afab-it-minio:9000 `
    -e MINIO_ACCESS_KEY=afabtestminio `
    -e MINIO_SECRET_KEY=afabtestminiosecret `
    -e MINIO_BUCKET=afab-receipts-test `
    maven:3.9.9-eclipse-temurin-21 mvn -B test
} finally {
  docker rm -f afab-it-pg afab-it-redis afab-it-minio 2>&1 | Out-Null
  docker network rm $net 2>&1 | Out-Null
}
```

### Frontend TypeScript & Production Build
```powershell
cd project\frontend
npx tsc --noEmit
npm run build
```

---

## 6. Team QA Sign-Off Table

| Area | Tester | EN / AR (RTL) | Light / Dark | Mobile / Desktop | Status | Notes |
|---|---|---|---|---|---|---|
| P0.1–P0.3 Auth, Cookies, CSRF, Rate Limit, Logs | | [ ] | [ ] | [ ] | | |
| P0.4–P0.5 Safe Account Deletion & Multi-Business Isolation | | [ ] | [ ] | [ ] | | |
| P1.1 Immutable Currency / FX Snapshots | | [ ] | [ ] | [ ] | | |
| P1.2 Customers (PostgreSQL + Error State) | | [ ] | [ ] | [ ] | | |
| P1.3 Invoices & Partial Payments (Cash Basis) | | [ ] | [ ] | [ ] | | |
| P1.4 Recurring Transactions & Private MinIO Receipts | | [ ] | [ ] | [ ] | | |
| P1.5 Budgets & Dashboard Progress / Alerts | | [ ] | [ ] | [ ] | | |
