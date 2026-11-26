# 03 — Complete Backend API Contract Catalog (132 Endpoints / 20 Controllers)

> **Base URL:** `/api/v1` (Local dev: `http://127.0.0.1:8080/api/v1`; Next.js web proxies `/api/v1/:path*`)
> **Verified Source:** All 20 Java controllers under `Web/project/backend/src/main/java/com/afab/**/controller/` (and package-root controllers), `SecurityConfig.java`, and `GlobalExceptionHandler.java`.
> **OpenAPI Drift Warning:** `Web/project/contracts/*.openapi.yaml` covers only **44 / 132 endpoints (33.3%)**. Always use this catalog and live Springdoc `/api-docs` as authoritative.

---

## 1. Global Headers, Auth, Isolation & Error Contracts

### 1.1 Standard Headers
| Header | Required On | Purpose |
|---|---|---|
| `Authorization` | All authenticated endpoints | `Bearer <jwt_access_token>` (15-min TTL) |
| `X-Business-Id` | All business-scoped endpoints | Optional UUID selecting active workspace; validated server-side against `business_members` (`ACTIVE`, `archivedAt IS NULL`, and `EDITABLE` via `CurrentBusinessService` / `BusinessAccessGuard`) |
| `X-CSRF-Token` | `POST /auth/refresh`, `POST /auth/logout` (if `refreshToken` cookie present) | Must match `afab_csrf` cookie in constant time |
| `Cookie` | `/auth/refresh`, `/auth/logout` | `refreshToken=<opaque>; afab_csrf=<nonce>` |
| `Idempotency-Key` | `POST /invoices/{id}/payments` | Client-generated unique key (max 128 chars) preventing duplicate payment/transaction creation |
| `Accept` / `Content-Type` | JSON (`application/json`), Multipart (`multipart/form-data`), SSE (`text/event-stream`) | Standard MIME negotiation |

### 1.2 Global Error Payloads (`GlobalExceptionHandler.java` & `SecurityConfig.java`)
- **Standard `ApiError` JSON** (`400`, `403 ForbiddenException`, `404`, `409`, `413`, `502`, `503 BillingNotConfiguredException`, `500`):
  `{ "status": int, "error": string, "message": string, "path": string, "fieldErrors"?: { [field]: string }, "timestamp": ISO8601 }`
- **Plan Quota Error (`403` `PlanLimitReachedException`):**
  `{ "status": 403, "code": "PLAN_LIMIT_REACHED", "message": string, "feature": string, "limit": int, "used": int, "upgradeTo": string, "path": string }`
- **Read-Only Business Error (`403` `BusinessReadOnlyException`):**
  `{ "status": 403, "error": "Forbidden", "code": "BUSINESS_READ_ONLY", "businessId": UUID, "businessName": string, "message": string, "path": string }`
- **AI Unavailable Error (`503` `AiServiceUnavailableException`):**
  `{ "status": 503, "error": "Service Unavailable", "code": "AI_SERVICE_UNAVAILABLE", "message": string, "path": string }`
- **Spring Security Filter Errors (`SecurityConfig.java`):**
  `401`: `{"success":false,"code":"UNAUTHORIZED","message":"Authentication required."}`
  `403`: `{"success":false,"code":"FORBIDDEN","message":"Access denied."}`
- **Auth Rate Limit (`DistributedRateLimiter`):** `429` (`code: "RATE_LIMITED"`, headers `Retry-After`, `X-RateLimit-Remaining: 0`) or `503` (`code: "RATE_LIMIT_UNAVAILABLE"`).

---

## 2. Controller-by-Controller Endpoint Catalog

### 2.1 `AuthController` (`/api/v1/auth` — 13 Endpoints)

| Method & Path | Auth / Rate Limit | Request DTO / Headers | Response DTO / Status | Errors | Web / Flutter Usage |
|---|---|---|---|---|---|
| `POST /api/v1/auth/register` | Public / `REGISTER` (5/m) | `RegisterRequest { firstName, lastName, email, password(>=8), businessName }` | `200 AuthResponse` + `Set-Cookie: refreshToken, afab_csrf` | `400 REGISTRATION_FAILED`, `429`, `503` | Web: `/signup`. Flutter: `SignUpRepository` |
| `POST /api/v1/auth/login` | Public / `LOGIN` (10/m) | `LoginRequest { email, password, rememberMe? }` | `200 AuthResponse` (if 2FA: `{ requiresTwoFactor: true, twoFactorToken }` w/o cookies; else full + cookies) | `401 INVALID_CREDENTIALS`, `403 ACCOUNT_DISABLED/LOCKED`, `429` | Web: `/login`. Flutter: `AuthRepository` |
| `POST /api/v1/auth/2fa/verify-login` | Public / `OTP_VERIFY` (10/m) | `TwoFactorVerifyRequest { twoFactorToken, code, rememberMe? }` | `200 AuthResponse` + cookies (7d or 30d) | `400 INVALID_2FA_REQUEST`, `401 INVALID_2FA_CODE`, `403 ACCOUNT_DISABLED` | Web: `/login` step 2. Flutter: `TwoFactorChallengeScreen` |
| `POST /api/v1/auth/refresh` | Cookie + CSRF + Origin / `REFRESH` (30/m) | Cookie `refreshToken`, `afab_csrf`, Header `X-CSRF-Token` | `200 AuthResponse` + rotated cookies | `401 INVALID_REFRESH_TOKEN`, `401 REFRESH_TOKEN_REUSE`, `403 CSRF_VALIDATION_FAILED` | Web: `client.ts`. Flutter: `AuthInterceptor` + `CookieJar` |
| `POST /api/v1/auth/logout` | CSRF+Origin if cookie present | Cookie `refreshToken`, `afab_csrf`, Header `X-CSRF-Token` | `200 ErrorResponse` + clears cookies | `403 CSRF_VALIDATION_FAILED` | Web: Sidebar. Flutter: `AuthRepository.logout()` |
| `POST /api/v1/auth/verify-email` | Public / `VERIFY_EMAIL` (10/m) | `VerifyEmailRequest { email, code(6) }` | `200 ErrorResponse` | `400 VERIFICATION_FAILED` | Web: `/verify-email`. Flutter: `EmailVerificationScreen` |
| `POST /api/v1/auth/resend-verification` | Public / `VERIFY_EMAIL` (10/m) | `ResendVerificationRequest { email }` | `200 { success, message, devOtp? }` | `503 EMAIL_DELIVERY_FAILED`, `429` | Web: `/verify-email`. Flutter: `EmailVerificationScreen` |
| `POST /api/v1/auth/forgot-password` | Public / `FORGOT_PASSWORD` (5/m) | `ForgotPasswordRequest { email }` | `200 ErrorResponse` (OTP flow) | `400`, `429` | Web: unused. Flutter: optional OTP recovery fallback |
| `POST /api/v1/auth/reset-password` | Public / `RESET_PASSWORD` (5/m) | `ResetPasswordRequest { email, code(6), newPassword(>=8) }` | `200 ErrorResponse` (revokes all refresh tokens) | `400 RESET_FAILED`, `429` | Web: unused. Flutter: optional OTP recovery fallback |
| `POST /api/v1/auth/forgot-password-link` | Public / `FORGOT_PASSWORD` (5/m) | `ForgotPasswordRequest { email }` | `200 ErrorResponse` (15m link) | `400`, `429` | Web: `/forgot-password`. Flutter: `ForgotPasswordScreen` |
| `POST /api/v1/auth/validate-reset-token` | Public / `RESET_PASSWORD` (5/m) | `ValidateTokenRequest { token }` | `200 ErrorResponse` | `400 TOKEN_EXPIRED`, `400 INVALID_TOKEN` | Web: `/reset-password`. Flutter: `ResetPasswordScreen` |
| `POST /api/v1/auth/reset-password-token` | Public / `RESET_PASSWORD` (5/m) | `ResetPasswordByTokenRequest { token, password(>=8) }` | `200 ErrorResponse` (revokes all tokens) | `400 TOKEN_EXPIRED`, `400 INVALID_TOKEN`, `400 RESET_FAILED` | Web: `/reset-password`. Flutter: `ResetPasswordScreen` |
| `POST /api/v1/auth/change-password` | JWT Auth | `ChangePasswordRequest { currentPassword, newPassword(>=8) }` | `200 ErrorResponse` + revokes all sessions & clears cookies | `401`, `400 CHANGE_PASSWORD_FAILED` | Web: `SecuritySettings`. Flutter: `SecuritySettingsScreen` (+ force re-login) |

### 2.2 `UserController` (`/api/v1/user` — 12 Endpoints, All JWT Authenticated)

| Method & Path | Request / Params | Response DTO | Errors | Notes & Flutter Usage |
|---|---|---|---|---|
| `GET /api/v1/user/me` | Optional `X-Business-Id` | `200 UserProfileDTO` (21 fields incl. `planTier`, preferences, `twoFactorEnabled`, `lastLoginAt`) | `401` | Core profile hydration across app |
| `PUT /api/v1/user/me` | `UpdateUserRequest { firstName, lastName, phoneNumber, avatarUrl(<=500k), enableAiInsights, compactMode, autoCategorizeTransactions, showTips }` | `200 UserProfileDTO` | `400 INVALID_FIRST_NAME/LAST_NAME/PHONE_TAKEN`, `401` | Edit Profile & General/Appearance (`compactMode`) |
| `GET /api/v1/user/me/export` | — | `200` attachment `afab-account-export-YYYY-MM-DD.json` | `401` | JSON GDPR-style account export |
| `GET /api/v1/user/me/deletion-preflight` | — | `200 AccountDeletionPreflightDTO { canDelete, blockingBusinesses[], guidance }` | `401` | Step 1 of `AccountDeletionFlow` |
| `DELETE /api/v1/user/me` | `DeleteAccountRequest { confirmation: "delete <email>" }` | `200 ErrorResponse` + clears `refreshToken`, `afab_csrf` | `400 DELETE_CONFIRMATION_INVALID`, `409` (blocking biz) | Tombstone anonymization; preserves financial ledgers |
| `GET /api/v1/user/2fa/setup` | — | `200 TwoFactorSetupResponse { secret, qrCodeUri, backupCodes[8] }` | `401` | Step 1 of 2FA enable sheet |
| `POST /api/v1/user/2fa/enable` | `TwoFactorEnableRequest { secret, code, backupCodes[] }` | `200` empty | `400 INVALID_CODE`, `401` | Verifies TOTP & enables 2FA |
| `POST /api/v1/user/2fa/disable` | `TwoFactorDisableRequest { password, code? (ignored) }` | `200` empty | `401 INVALID_PASSWORD`, `400 DISABLE_FAILED` | Disables 2FA via password |
| `POST /api/v1/user/2fa/backup-codes` | — | `200 List<String>` (8 codes) | `400 FAILED`, `401` | Regenerates backup codes |
| `GET /api/v1/user/me/sessions` | Cookie `refreshToken` (not sent by browser due to path!) | `200 List<SessionDTO>` | `401` | `SecuritySettingsScreen` |
| `DELETE /api/v1/user/me/sessions/{tokenId}` | Path `tokenId: UUID` | `200` empty | `400`, `403`, `401` | Single session revoke |
| `DELETE /api/v1/user/me/sessions` | Cookie `refreshToken` (null due to path → revokes ALL) | `200` empty | `401` | Force logout if current session revoked |

### 2.3 `BusinessController` (`/api/v1/business` — 12 Endpoints, All JWT Authenticated)

| Method & Path | Role / Access Guard | Request / Params | Response DTO | Errors |
|---|---|---|---|---|
| `GET /api/v1/business` | Active user (allows locked `X-Business-Id`) | Optional `X-Business-Id` | `200 List<BusinessDTO>` (28 fields) | `401`, `403` |
| `POST /api/v1/business` | Authenticated; enforces `business.max` (`1`/`3`/`5`) | `CreateBusinessRequest { name, currency(3), country?, timezone?, industry?, businessType? }` | `201 BusinessDTO` | `400`, `403 PLAN_LIMIT_REACHED` |
| `GET /api/v1/business/mine` | Member + `EDITABLE` | Optional `X-Business-Id` | `200 BusinessDTO` | `403`, `403 BUSINESS_READ_ONLY`, `404` |
| `GET /api/v1/business/{id}` | Member + `EDITABLE` | Path `id: UUID` | `200 BusinessDTO` | `403`, `403 BUSINESS_READ_ONLY` |
| `PUT /api/v1/business/{id}` | `OWNER`/`ADMIN` + `EDITABLE` | `UpdateBusinessRequest` (19 opt fields; `logoUrl<=500`) | `200 BusinessDTO` | `400`, `403`, `403 BUSINESS_READ_ONLY` |
| `DELETE /api/v1/business/{id}` | `OWNER` + `EDITABLE` | Path `id: UUID` | `204` (soft-archive) | `403`, `403 BUSINESS_READ_ONLY` |
| `PUT /api/v1/business/{id}/switch` | Member + `EDITABLE` | Path `id: UUID` | `200 BusinessDTO` | `403`, `403 BUSINESS_READ_ONLY` |
| `GET /api/v1/business/{id}/members` | Member + `EDITABLE` | Path `id: UUID` | `200 List<BusinessMemberDTO>` | `403`, `403 BUSINESS_READ_ONLY` |
| `POST /api/v1/business/{id}/transfer-ownership` | `OWNER` (no `assertEditable`) | `TransferOwnershipRequest { targetUserId }` | `200 BusinessDTO` | `403`, `404`, `409` |
| `GET /api/v1/business/allocations` | Authenticated | — | `200 BusinessAllocationDTO` | `401`, `404` |
| `PUT /api/v1/business/allocations` | `OWNER` of selected IDs | `{ selectedBusinessIds[], primaryBusinessId? }` | `200 BusinessAllocationDTO` | `400`, `403`, `403 PLAN_LIMIT_REACHED` |
| `PUT /api/v1/business/allocations/pending` | `OWNER` of selected IDs | `{ targetPlanSlug, selectedBusinessIds[] }` | `200 BusinessAllocationDTO` | `400`, `403`, `403 PLAN_LIMIT_REACHED` |

### 2.4 `DashboardController` (`/api/v1/dashboard` — 1 Endpoint)
- `GET /api/v1/dashboard/summary?period=month` (`weekly|week`, `30d`, `month|monthly`, `year|yearly`): JWT + `X-Business-Id` (`EDITABLE`). Returns `200 DashboardSummaryDTO` (`kpiData`, `revenueData[6]`, `transactions[5]`, `expenseCategories`, `reminders[<=8]`, `customers[<=5]`, `currency`, `businessName`, `budgets`).

### 2.5 `TransactionController` (`/api/v1/transactions` — 6 Endpoints)
- `GET /api/v1/transactions`: Query `type`, `categoryId`, `status`, `paymentMethod`, `taxDeductible`, `startDate`, `endDate`, `search`, `page=0`, `size=20 (1..100)`. Returns `200 TransactionResponseDTO` (`content`, paging, `totalInflow`, `totalOutflow`, `netBalance`, `currency`).
- `GET /api/v1/transactions/{id}`: Returns `200 TransactionDTO` (with `splitItems`, FX snapshot, anomaly flags `potentialDuplicate` & `priceHikePercentage`).
- `POST /api/v1/transactions`: `CreateTransactionRequest { type(INCOME|EXPENSE), amount(>=0.0001), originalCurrency?(3), exchangeRate?(>=0.000001), description(<=255), transactionDate, categoryId?, paymentMethod?, status?, notes?(<=1000), taxDeductible?, taxRate?, splitItems?[] }` → `201 TransactionDTO`.
- `PUT /api/v1/transactions/{id}`: `UpdateTransactionRequest` (cannot change `originalCurrency`; `splitItems` accepted in DTO but ignored by service) → `200 TransactionDTO`.
- `DELETE /api/v1/transactions/{id}`: Soft-deletes parent + split children → `204`.
- `GET /api/v1/transactions/categories`: Legacy alias → `200 List<CategoryDTO>`.

### 2.6 `CategoryController` (`/api/v1/categories` — 4 Endpoints)
- `GET /api/v1/categories` → `200 List<CategoryDTO>` (note: `isSystemDefault()` serializes to JSON `"systemDefault"`).
- `POST /api/v1/categories` (`{ name, type, icon?, color? }`) → `201 CategoryDTO` (`409` duplicate).
- `PUT /api/v1/categories/{id}` (`{ name?, icon?, color? }`) → `200 CategoryDTO` (`403` on system defaults).
- `DELETE /api/v1/categories/{id}` → `204` (`403` system default, `409` if referenced by active transactions).

### 2.7 `ExpenseController` (`/api/v1/expenses` — 2) & `RevenueController` (`/api/v1/revenue` — 2)
- `GET /api/v1/expenses/summary?period=month` → `200 ExpenseSummaryDTO` (`recurringTotal=0`, `recurringList=[]` stubbed).
- `GET /api/v1/expenses?categoryId=&search=&page=0&size=15` → `200 TransactionResponseDTO`.
- `GET /api/v1/revenue/summary?period=month` → `200 RevenueSummaryDTO` (`discounts=0`, `refunds=0`, `topProducts=[]` stubbed).
- `GET /api/v1/revenue?categoryId=&search=&page=0&size=15` → `200 TransactionResponseDTO`.

### 2.8 `CurrencyController` (`/api/v1/currencies` — 5 Endpoints)
- `GET /api/v1/currencies/rates?base=` (**Public**, opt JWT) → `200 List<CurrencyPairDTO>` (live spot rate + synthetic 24h/sparkline).
- `GET /api/v1/currencies/history?from=EUR&to=USD&timeframe=1M` (**Public**) → `200 List<HistoricalRatePointDTO>` (synthetic curve).
- `GET /api/v1/currencies/convert?from=&to=&amount=` (**Public**) → `200 { from, to, amount, exchangeRate, convertedAmount }`.
- `GET /api/v1/currencies/business/preview?newCurrency=` (JWT) → `200 CurrencyChangePreviewDTO`.
- `POST /api/v1/currencies/business/change` (JWT `OWNER`/`ADMIN` + `EDITABLE`, `{ newCurrency, convertExistingTransactions }`) → `200 CurrencyChangeResultDTO` (never mutates historical txs).

### 2.9 `CustomerController` (`/api/v1/customers` — 6 Endpoints)
- `GET /api/v1/customers?search=&status=&group=&page=0&size=10&sortBy=createdAt&sortOrder=desc` → `200 CustomerPageDTO` (`orders: []` in list).
- `GET /api/v1/customers/summary?period=month` → `200 CustomerSummaryDTO`.
- `GET /api/v1/customers/{id}` → `200 CustomerDTO` (populates `orders: CustomerInvoiceLinkDTO[]`).
- `POST /api/v1/customers` (`CreateCustomerRequest`) → `201 CustomerDTO` (`409` duplicate email/code).
- `PUT /api/v1/customers/{id}` (`UpdateCustomerRequest`) → `200 CustomerDTO`.
- `DELETE /api/v1/customers/{id}` → `204` (soft-archive).

### 2.10 `InvoiceController` (`/api/v1/invoices` — 9 Endpoints)
- `GET /api/v1/invoices/summary?period=month` (`period` ignored) → `200 InvoiceSummaryDTO`.
- `GET /api/v1/invoices?customerId=&status=&search=&page=0&size=15` → `200 InvoicePageDTO`.
- `GET /api/v1/invoices/{id}` → `200 InvoiceDTO` (populates `items[]` and `payments[]`).
- `POST /api/v1/invoices` (`CreateInvoiceRequest`) → `201 InvoiceDTO` (`DRAFT`).
- `PUT /api/v1/invoices/{id}` (`CreateInvoiceRequest`, `DRAFT` only else `409`) → `200 InvoiceDTO`.
- `POST /api/v1/invoices/{id}/issue?sent=false` (`DRAFT` only else `409`) → `200 InvoiceDTO` (`SENT`/`UNPAID`).
- `POST /api/v1/invoices/{id}/cancel` (`paidAmount==0` & not `PAID`/`CANCELLED` else `409`) → `200 InvoiceDTO`.
- `POST /api/v1/invoices/{id}/payments` (Header/Body `Idempotency-Key`, `RecordPaymentRequest`) → `201 PaymentDTO` (pessimistic lock + 1:1 `INCOME` transaction + FX snapshot).
- `GET /api/v1/invoices/{id}/payments` → `200 List<PaymentDTO>`.

### 2.11 `BudgetController` (`/api/v1/budgets` — 6 Endpoints)
- `GET /api/v1/budgets?includeArchived=false` → `200 List<BudgetDTO>`.
- `GET /api/v1/budgets/summary` → `200 BudgetSummaryDTO`.
- `GET /api/v1/budgets/{id}` → `200 BudgetDTO`.
- `POST /api/v1/budgets` (`BudgetRequest`) → `201 BudgetDTO`.
- `PUT /api/v1/budgets/{id}` (`BudgetRequest`) → `200 BudgetDTO`.
- `DELETE /api/v1/budgets/{id}` → `204` (soft-archive).

### 2.12 `RecurringTransactionController` (`/api/v1/recurring-transactions` — 7 Endpoints)
- `GET /api/v1/recurring-transactions` → `200 List<RecurringTransactionDTO>`.
- `GET /api/v1/recurring-transactions/{id}` → `200 RecurringTransactionDTO`.
- `POST /api/v1/recurring-transactions` (`RecurringTransactionRequest`) → `201 RecurringTransactionDTO`.
- `PUT /api/v1/recurring-transactions/{id}` (`RecurringTransactionRequest`) → `200 RecurringTransactionDTO`.
- `PATCH /api/v1/recurring-transactions/{id}/status` (`{ active: boolean }`) → `200 RecurringTransactionDTO`.
- `POST /api/v1/recurring-transactions/{id}/run-due` → `200 RunResult { rule, generatedCount, transactionIds }`.
- `DELETE /api/v1/recurring-transactions/{id}` → `204` (deactivates if executions exist, else hard-deletes).

### 2.13 `ReceiptController` (`/api/v1/receipts` — 5 Endpoints)
- `POST /api/v1/receipts/transactions/{transactionId}` (`multipart/form-data` part `file` ≤10MB; PDF/PNG/JPEG/WEBP magic-byte checked) → `201 ReceiptDTO`.
- `GET /api/v1/receipts/transactions/{transactionId}` → `200 List<ReceiptDTO>`.
- `GET /api/v1/receipts/{id}/download-url` → `200 PresignedDownloadDTO` (300s default expiry).
- `GET /api/v1/receipts/{id}/content` → `200 byte[]` stream (`Cache-Control: private, no-store`, `X-Content-Type-Options: nosniff`).
- `DELETE /api/v1/receipts/{id}` → `204`.

### 2.14 `ReportController` (`/api/v1/reports` — 5 Endpoints)
- `GET /api/v1/reports/profit-loss?period=this_month&startDate=&endDate=` → `200 ProfitAndLossReportDTO` (`reports.level` gated).
- `GET /api/v1/reports/cash-flow?period=this_month&startDate=&endDate=` → `200 CashFlowReportDTO`.
- `GET /api/v1/reports/comparison?primaryPeriod=this_month&comparisonPeriod=last_month` → `200 ComparisonReportDTO` (requires `reports.level != basic`).
- `GET /api/v1/reports/export/csv?period=this_month&startDate=&endDate=` → `200 text/csv` (UTF-8 BOM; consumes `1` of `export.per_month`).
- `GET /api/v1/reports/export/pdf?period=this_month&startDate=&endDate=` → `200 application/pdf` (OpenPDF; consumes `1` of `export.per_month`).

### 2.15 `NotificationController` (`/api/v1/notifications` — 3 Endpoints, User-Scoped)
- `GET /api/v1/notifications` → `200 NotificationsResponse { unreadCount, notifications[<=30] }`.
- `PUT /api/v1/notifications/{id}/read` → `200 NotificationsResponse`.
- `PUT /api/v1/notifications/read-all` → `200 NotificationsResponse`.

### 2.16 `SubscriptionController` (`/api/v1/subscription` — 3) & `StripeBillingController` (`/api/v1/billing` — 9)
- `GET /api/v1/subscription/me` → `200 SubscriptionSnapshotDTO` (plan, status, dates, entitlements, monthly usage, trial flags, allocation attention).
- `POST /api/v1/subscription/trial` (`{ planSlug }`) → `200 SubscriptionSnapshotDTO` (**`403` outside local/dev or when Stripe configured**).
- `POST /api/v1/subscription/switch` (`{ planSlug }`) → `200 SubscriptionSnapshotDTO` (**`403` outside local/dev or when Stripe configured**).
- `POST /api/v1/billing/checkout` (`{ planSlug, billingInterval, locale, returnPath }`) → `200 CheckoutSessionResponse { sessionId, url, mode }`.
- `POST /api/v1/billing/portal` (`{ locale, returnPath }`) → `200 PortalSessionResponse { url }`.
- `POST /api/v1/billing/checkout/verify` (`{ sessionId }`) → `200 SubscriptionSnapshotDTO`.
- `POST /api/v1/billing/cancel` (`{ selectedBusinessIds? }`) → `200 SubscriptionSnapshotDTO`.
- `POST /api/v1/billing/resume` → `200 SubscriptionSnapshotDTO`.
- `POST /api/v1/billing/downgrade` (`{ targetPlanSlug, billingInterval?, selectedBusinessIds?, deferAllocation }`) → `200 SubscriptionSnapshotDTO`.
- `POST /api/v1/billing/upgrade` (`{ planSlug, billingInterval, locale, returnPath }`) → `200 UpgradeSubscriptionResponse { mode, sessionId?, url?, snapshot? }`.
- `GET /api/v1/billing/history` → `200 BillingHistoryResponse { subscriptionHistory[<=50], paymentHistory[<=50] }`.
- `POST /api/v1/billing/webhook` (**Public**, `Stripe-Signature` header) → `200 { received: true }`.

### 2.17 `AiController` (`/api/v1/ai` — 21 Endpoints)
- `GET /api/v1/ai/status?fresh=false` (JWT) → `200 AiStatusDTO`.
- `GET /api/v1/ai/health?fresh=true` (**Public**) → `200 AiHealthDTO`.
- `GET /api/v1/ai/health/stream` (**Public**) → `200 text/event-stream` (`health` event every 4s).
- `GET /api/v1/ai/pulse` (JWT) → `200 AiPulseDTO`.
- `POST /api/v1/ai/chat` (JWT + `EDITABLE`, `AiChatRequest`) → `200 AiChatResponseDTO`.
- `POST /api/v1/ai/chat/stream` (JWT + `EDITABLE`, `AiChatRequest`) → `200 text/event-stream` (events: `status`, `ping`, `thought`, `tool_start`, `tool_done`, `delta`, `replace`, `done`, `error`).
- `POST /api/v1/ai/attachments/stage` (JWT + `EDITABLE`, multipart `file` ≤10MB) → `201 AiAttachmentDTO`.
- `GET /api/v1/ai/attachments/{id}/preview` (JWT, biz-scoped) → `200 binary`.
- `POST /api/v1/ai/actions/approve-transaction` (JWT + `EDITABLE`) → `200 AiActionDraftDTO`.
- `POST /api/v1/ai/actions/approve-invoice` (JWT + `EDITABLE`) → `200 AiActionDraftDTO`.
- `POST /api/v1/ai/actions/approve-budget` (JWT + `EDITABLE`) → `200 AiActionDraftDTO`.
- `POST /api/v1/ai/actions/approve-memory` (JWT + `EDITABLE`) → `200 AiActionDraftDTO`.
- `PATCH /api/v1/ai/messages/{messageId}/drafts/{draftId}/dismiss` (JWT + `EDITABLE`) → `200 AiActionDraftDTO`.
- `POST /api/v1/ai/index/sync` (JWT + `EDITABLE`) → `200 AiIndexSyncResponseDTO`.
- `GET /api/v1/ai/conversations` (JWT) → `200 List<AiConversationSummaryDTO>`.
- `GET /api/v1/ai/conversations/{id}` (JWT) → `200 AiConversationDetailDTO`.
- `DELETE /api/v1/ai/conversations/{id}` (JWT + `EDITABLE`) → `204`.
- `GET /api/v1/ai/memory?status=ALL` (JWT) → `200 List<BusinessMemoryDTO>`.
- `POST /api/v1/ai/memory` (JWT + `EDITABLE`, `BusinessMemoryRequest`) → `201 BusinessMemoryDTO`.
- `PATCH /api/v1/ai/memory/{id}` (JWT + `EDITABLE`, `BusinessMemoryUpdateRequest`) → `200 BusinessMemoryDTO`.
- `DELETE /api/v1/ai/memory/{id}` (JWT + `EDITABLE`) → `204`.

### 2.18 `HealthController` (`/api/v1/health` — 1 Endpoint)
- `GET /api/v1/health` (**Public**) → `200 { status: "UP", timestamp, service: "afab-backend", mail: { status: "UP" | "DOWN" } }`.
