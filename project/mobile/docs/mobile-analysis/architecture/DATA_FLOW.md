# Data Flow & State Synchronization — AFAB Mobile

---

## 1. Standard Request & Error Pipeline

```text
Widget (ref.watch(provider))
  │
  ▼
Riverpod AsyncNotifier / FutureProvider
  │ calls
  ▼
Feature Repository (domain interface → data impl)
  │ calls
  ▼
DioClient
  ├── 1. CookieManager: attaches refreshToken / afab_csrf (on /auth/*)
  ├── 2. AuthInterceptor: injects Bearer <accessToken> + X-CSRF-Token
  ├── 3. TenantInterceptor: injects X-Business-Id: <activeBusinessId>
  │
  ▼ HTTP Response
  ├── 2xx ──► Freezed DTO.fromJson() ──► Domain Entity (Decimal/DateTime) ──► UI
  ├── 401 ──► Single-flight lock ──► POST /auth/refresh ──► Retry original request (or logout on 401)
  ├── 403 PLAN_LIMIT_REACHED ──► Global Event Bus ──► PlanLimitBottomSheet
  ├── 403 BUSINESS_READ_ONLY ──► Clear activeBusinessId + Refresh /business ──► ReadOnlySheet
  └── 400 / 404 / 409 / 429 / 503 ──► Typed AppFailure ──► Inline fieldErrors / Retryable Banner
```

---

## 2. Multi-Tenant & Mutation Cache Invalidation Rules

To guarantee zero cross-tenant data leakage and instant UI consistency (replacing Web's `window.location.reload()`):

| Event / Mutation | Providers Invalidated Immediately |
|---|---|
| **Login / Logout / Password Change / Account Delete** | `sessionProvider`, `cookieJar`, **ALL** feature providers (`ProviderContainer` reset or scoped family disposal). |
| **Switch Active Business (`PUT /business/{id}/switch`)** | `activeBusinessProvider` → cascades auto-rebuild to `dashboardProvider`, `transactionsProvider`, `expensesProvider`, `revenueProvider`, `categoriesProvider`, `customersProvider`, `invoicesProvider`, `budgetsProvider`, `recurringProvider`, `calendarProvider`, `reportsProvider`, `aiConversationsProvider`, `aiMemoryProvider`. |
| **Transaction / Split / Receipt / Category Mutation** | `transactionsProvider`, `dashboardProvider`, `expensesProvider`, `revenueProvider`, `budgetsProvider`, `calendarProvider`, `reportsProvider`. |
| **Invoice Issue / Cancel / Record Payment** | `invoicesProvider`, `invoiceDetailProvider(id)`, `customersProvider`, `customerDetailProvider(customerId)`, `dashboardProvider`, `transactionsProvider`, `revenueProvider`. |
| **AI Draft Approval (`approve-transaction/invoice/budget`)** | Same targets as the created entity + `aiConversationDetailProvider(id)` + `subscriptionProvider` (token meter). |
| **Stripe Checkout Verify / Upgrade / Cancel / Allocation** | `subscriptionProvider`, `businessListProvider`, `businessAllocationProvider`, `notificationsProvider`, `reportsProvider`. |

---

## 3. Streaming Data Flow (`POST /api/v1/ai/chat/stream`)

1. UI submits message + `stagedAttachmentIds` + `reasoningMode` (`fast`/`deep`) + `screenContext`.
2. `AiChatNotifier` opens SSE `ResponseBody.stream` via `CancelToken`.
3. `SseParser` decodes UTF-8 lines, splits on `\n\n`, and emits `AiSseEvent` frames to update immutable `StreamingTurnState`:
   - `status` → phase label (`warming_model` / `retrieving` / `generating`)
   - `thought` → appends to `thinkingBuffer`
   - `tool_start` / `tool_done` → updates active/completed tool pills
   - `delta` → appends to `contentBuffer` (throttled ~50ms frame batching for smooth 60fps Markdown reflow)
   - `replace` → replaces `contentBuffer` cleanly if language guard repaired output
   - `done` → replaces optimistic streaming message with authoritative persisted `AiChatResponseDTO` (charts, action drafts, evidence, token usage)
   - `error` / stream abort → transitions turn to recoverable error state with Retry / Stop Partial Keep.
