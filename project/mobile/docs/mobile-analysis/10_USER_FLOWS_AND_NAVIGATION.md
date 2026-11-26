# 10 — User Flows & Navigation Diagrams

> End-to-end behavioral flows connecting AFAB Mobile screens, GoRouter guards, and Spring Boot APIs.

---

## 1. App Startup, Session Restoration & Auth Routing

```mermaid
flowchart TD
    A["App Launch -> SplashScreen"] --> B{"Encrypted CookieJar has refreshToken?"}
    B -- No --> L["LoginScreen / SignUpScreen"]
    B -- Yes --> C["POST /api/v1/auth/refresh + X-CSRF-Token"]
    C -- 200 OK --> D["Store accessToken in RAM + GET /api/v1/user/me"]
    C -- 401/403 --> CLR["Clear CookieJar & RAM"] --> L
    C -- Network Error --> OFF["Offline / Retry Banner on Splash"]
    D --> E{"emailVerified?"}
    E -- No --> V["EmailVerificationScreen"]
    E -- Yes --> F{"onboardingComplete?"}
    F -- No --> O["OnboardingScreen (3 Steps)"]
    F -- Yes --> H["Dashboard Shell (Tab 0 Home)"]
```

---

## 2. Login + 2FA + Registration + Password Recovery

```mermaid
sequenceDiagram
    actor U as User
    participant App as Flutter App
    participant API as Spring Boot /api/v1/auth
    U->>App: Enter email, password, rememberMe
    App->>API: POST /login
    alt 2FA Disabled
        API-->>App: 200 AuthResponse + Set-Cookie(refreshToken, afab_csrf)
        App->>App: Store JWT in RAM, cookies in Secure CookieJar
    else 2FA Enabled
        API-->>App: 200 { requiresTwoFactor: true, twoFactorToken }
        App->>U: Navigate to TwoFactorChallengeScreen
        U->>App: Enter 6-digit TOTP or 8-char backup code
        App->>API: POST /2fa/verify-login { twoFactorToken, code, rememberMe }
        API-->>App: 200 AuthResponse + Set-Cookie(refreshToken, afab_csrf)
    end
```

---

## 3. Single-Flight Token Refresh & Multi-Tenant Business Switch

```mermaid
sequenceDiagram
    participant UI as Multiple Widgets
    participant Dio as AuthInterceptor
    participant Lock as Single-Flight Completer
    participant API as Backend API
    UI->>Dio: Request A & Request B (expired JWT)
    Dio->>API: Requests A & B -> 401 UNAUTHORIZED
    Dio->>Lock: Acquire inFlightRefresh (Request A starts, B awaits)
    Lock->>API: POST /auth/refresh (Cookie: refreshToken + afab_csrf; Header: X-CSRF-Token)
    API-->>Lock: 200 New accessToken + Rotated refreshToken cookie
    Lock-->>Dio: Complete(true)
    Dio->>API: Retry Request A & B with new Bearer token + X-Business-Id
```

**Business Switch Flow:**
1. User taps Business Switcher pill in AppBar → `BusinessSwitcherSheet` displays `GET /api/v1/business` with `editable` / `READ_ONLY` badges.
2. If user taps an `EDITABLE` business → `PUT /api/v1/business/{id}/switch` → update `activeBusinessIdProvider` → invalidate all Riverpod business-scoped providers → refetch Dashboard/current tab.
3. If user taps a `READ_ONLY` business → show `LockedBusinessDialog` explaining vault protection and offering navigation to `PlansAndSubscriptionScreen` / `BusinessAllocationSheet`.

---

## 4. Core Financial Flows

### 4.1 Transaction Lifecycle (Create / Edit / Duplicate / Split / Receipt)
- **Create / Duplicate:** `AddEditTransactionScreen` (`isEditing = false`) → optional live `GET /currencies/convert` FX quote preview → `POST /transactions` → refresh ledger & Dashboard. *(Fixes Web bug where Duplicate called `PUT` with empty ID.)*
- **Split:** `SplitTransactionScreen` → validates `sum(lines) == totalAmount` using `Decimal` → `POST /transactions` with `splitItems[]` (last child absorbs FX rounding residual on backend).
- **Receipt:** `TransactionDetailsScreen` → Camera/Gallery/PDF picker → compress image (`<= 1024px`) → `POST /receipts/transactions/{id}` → preview/download via `GET /receipts/{id}/content` (authenticated stream) or `share_plus`.

### 4.2 Invoice Lifecycle & Idempotent Payment Recording
```mermaid
stateDiagram-v2
    [*] --> DRAFT: POST /invoices
    DRAFT --> DRAFT: PUT /invoices/{id}
    DRAFT --> SENT: POST /issue?sent=true
    DRAFT --> UNPAID: POST /issue?sent=false
    SENT --> PARTIALLY_PAID: POST /payments (partial)
    UNPAID --> PARTIALLY_PAID: POST /payments (partial)
    PARTIALLY_PAID --> PAID: POST /payments (full balance)
    SENT --> PAID: POST /payments (full balance)
    UNPAID --> PAID: POST /payments (full balance)
    DRAFT --> CANCELLED: POST /cancel (paid==0)
    SENT --> CANCELLED: POST /cancel (paid==0)
    UNPAID --> CANCELLED: POST /cancel (paid==0)
```
- `RecordPaymentSheet` generates one `Uuid().v4()` `Idempotency-Key` per sheet session (reused on network retry), creating a 1:1 cash-basis `INCOME` transaction with immutable FX snapshot on the backend.

### 4.3 AI Copilot Streaming & Action Approval Flow
1. Optional attachment staging: pick/capture file → `POST /ai/attachments/stage` (max 3, `<= 10 MB`) → chip preview via `GET /ai/attachments/{id}/preview`.
2. Send turn: `POST /ai/chat/stream` → SSE frames `status` → `thought` (deep mode) → `tool_start`/`tool_done` → `delta` (streaming Markdown) → optional `replace` → `done` (with `charts[]`, `actionDrafts[]`, `evidence[]`, `suggestedFollowUps[]`).
3. Human-in-the-Loop Drafts: User edits/reviews inline draft card → taps Approve → calls `POST /ai/actions/approve-{transaction|invoice|budget|memory}` (promotes staged receipt if present) or `PATCH /ai/messages/{msgId}/drafts/{draftId}/dismiss`.

### 4.4 Stripe Billing & Return Flow
1. Upgrade without active Stripe sub → `POST /billing/checkout` → open returned `url` via `flutter_custom_tabs` (`CustomTabs` / `SFSafariViewController`).
2. User completes Stripe Checkout → Stripe redirects to `{frontendUrl}/{locale}/dashboard/settings/subscription?checkout=success&session_id=...` → App Links / Universal Links deep-links back into app (or Custom Tab closes on redirect) → app calls `POST /billing/checkout/verify` → refreshes `SubscriptionSnapshot` & `BusinessAllocations`.
3. Direct Upgrade (existing Stripe sub) / Downgrade / Cancel / Resume → pure JSON APIs (`POST /billing/upgrade`, `/downgrade`, `/cancel`, `/resume`) with zero browser handoff.
