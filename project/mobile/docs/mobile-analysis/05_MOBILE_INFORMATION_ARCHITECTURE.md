# 05 — Mobile Information Architecture (Phone & Tablet)

> **Goal:** Translate AFAB Web's 13-item desktop sidebar + 11-tab settings sidebar + global drawer into a crisp, thumb-friendly native mobile & adaptive tablet experience without losing any feature.

---

## 1. Entry & Unauthenticated Navigation Tree

No public marketing landing page (`/[locale]/page.tsx`) exists in AFAB Mobile.

```text
/splash (SplashScreen — initial route)
  ├── [No session / expired] ──► /login (LoginScreen)
  │                                ├── /two-factor (TwoFactorChallengeScreen)
  │                                ├── /signup (SignUpScreen)
  │                                └── /forgot-password (ForgotPasswordScreen)
  │                                      └── /reset-password?token=... (ResetPasswordScreen)
  ├── [!emailVerified] ────────► /verify-email (EmailVerificationScreen)
  ├── [!onboardingComplete] ───► /onboarding (OnboardingScreen — 3 steps)
  └── [Verified + Onboarded] ──► /dashboard (Authenticated Shell)

Global Out-of-Shell Routes:
  ├── /maintenance (MaintenanceScreen — triggered by 503 / health outage)
  └── /not-found (ErrorAndNotFoundScreen)
```

---

## 2. Phone Navigation Architecture (`width < 600dp`)

Replaces Web's 13-item collapsible sidebar with a **5-Tab Bottom Navigation Bar** (`NavigationBar` inside `GoRouter` `StatefulShellRoute.indexedStack`, preserving independent scroll & stack state per tab) + a categorized **More Hub**.

| Tab Index | Label (EN / AR) | Icon (Lucide) | Root Destination | Nested Stack Routes |
|---|---|---|---|---|
| **0** | **Home** / الرئيسية | `LayoutDashboard` | `DashboardScreen` | `NotificationsScreen`, `BudgetDetail` (via Budgets), `TransactionDetailsScreen` |
| **1** | **Finance** / المالية | `ArrowRightLeft` | `TransactionsScreen` | `TransactionDetailsScreen`, `AddEditTransactionScreen`, `SplitTransactionScreen`, `ManageCategoriesScreen`, `ReceiptViewerFlow`, `ExpensesScreen`, `RevenueScreen` |
| **2** | **Copilot** / المساعد الذكي | `Sparkles` *(elevated accent)* | `AiCopilotScreen` | `BusinessMemoryScreen` (+ `GlobalCopilotSheet` modal accessible from any non-Copilot route) |
| **3** | **Invoices** / الفواتير | `FileText` | `InvoicesScreen` | `InvoiceDetailsScreen`, `CreateEditInvoiceScreen`, `RecordPaymentSheet`, `CustomersScreen`, `CustomerDetailsScreen` |
| **4** | **More** / المزيد | `LayoutGrid` | `MoreHubScreen` | Categorized grid/list to all remaining modules (below) |

### 2.1 `MoreHubScreen` Directory Structure (Phone Tab 4)
Grouped into 4 clear sections matching AFAB's domain taxonomy:
1. **Money & Operations**
   - Expenses (`/expenses`), Revenue (`/revenue`), Categories (`/categories`), Customers (`/customers`), Budgets (`/budgets`), Recurring (`/recurring`), Financial Calendar (`/calendar`)
2. **Intelligence & FX**
   - Currencies & FX Markets (`/currencies`), Financial Reports (`/reports`)
3. **Workspace & Billing**
   - Plans & Subscription (`/plans`), Business Switcher (`BusinessSwitcherSheet`)
4. **Preferences & Account**
   - Settings Home (`/settings`) → General, Business Profile, Security & 2FA, Appearance, Wet Signature, Data & Export, Language (EN/AR), Coming Soon modules (`Users & Permissions`, `Notifications`, `Integrations`)

### 2.2 Persistent Shell AppBar Controls (All Top-Level Tabs)
- **Leading:** **Business Switcher Pill** displaying active business name, currency badge, plan pill (`Plus`/`Pro`), or `Locked` warning icon → opens `BusinessSwitcherSheet`.
- **Trailing:**
  1. **Ask Copilot Icon (`Sparkles`)** (hidden on Tab 2 `AiCopilotScreen`) → opens `GlobalCopilotSheet` preloaded with current route's `screenContext` (`{ page, period, ... }`).
  2. **Notifications Bell** with live unread badge (`1..9`, `9+`) → pushes `NotificationsScreen`.
- **Global Persistent Banners (below AppBar, above body):**
  - `PastDueGraceBanner` (`subscription.status == "PAST_DUE"` → remaining hours + "Update Payment" CTA).
  - `AllocationAttentionBanner` (`allocationAttentionRequired == true` → "Manage Workspaces" CTA).
  - `OfflineBanner` (when `connectivity_plus` reports offline).

---

## 3. Tablet & Large-Screen Adaptive Architecture (`width >= 600dp`)

On tablets (`>= 600dp`), bottom navigation transitions automatically to a **Material 3 `NavigationRail`** (`72dp` collapsed on `600–1023dp`, `248dp` extended drawer-rail on `>= 1024dp` landscape), restoring direct 1-tap access to AFAB Web's full navigation hierarchy:

- **Rail Header:** `BusinessSwitcher` tile + Quick-Add (`+`) button.
- **Rail Primary Section:** Overview, Transactions, Expenses, Revenue, Invoices, Customers, Budgets, Recurring, Reports, Currencies.
- **Rail Workspace Section:** AI Copilot (`NEW` badge), Calendar, Settings.
- **Rail Footer:** Active Plan / Upgrade CTA (when Free) + User Profile tile.
- **Two-Pane Master-Detail Layouts (`>= 840dp`):**
  - **Transactions:** Ledger list (left 58%) + `TransactionDetails` inline pane (right 42%).
  - **Customers:** Directory + KPIs (left 55%) + `CustomerDetails` inline pane (right 45%).
  - **Invoices:** Receivables list (left 58%) + `InvoiceDetails` inline pane (right 42%).
  - **AI Copilot:** Conversation history drawer (fixed 280dp) + Chat Studio + inline `BusinessMemory` side pane.
  - **Settings:** 11-item Settings category rail (260dp) + active Settings detail pane.

---

## 4. Deep Linking, Back Navigation & Context Preservation

- **Deep Link Schemes (`GoRouter`):**
  - Universal / App Links (`https://<afab-web-domain>/{en|ar}/...`) & Custom Scheme (`afab://...`):
    - `/reset-password?token=<rawToken>` → `ResetPasswordScreen` (preserving `_` in Base64URL tokens!)
    - `/verify-email` → `EmailVerificationScreen`
    - `/dashboard/settings/subscription?checkout=success&session_id=...` → `PlansAndSubscriptionScreen` (runs `POST /billing/checkout/verify`)
    - `/dashboard/settings/subscription?checkout=canceled` → `PlansAndSubscriptionScreen` (canceled toast)
    - `Notification.actionUrl` (e.g., `/dashboard/settings/subscription`) → navigates directly into matching authenticated route after restoring session.
- **Back Navigation Rules:**
  - Android system back / iOS edge swipe pops within active `StatefulShellBranch` first; pressing back on non-Home root tab switches to Home tab (`0`) before prompting/exiting app.
  - Full-screen modal workflows (`AddEditTransaction`, `SplitTransaction`, `CreateEditInvoice`, `AccountDeletionFlow`) prompt discard confirmation when `isDirty == true`.
- **Business Context Switch Behavior:**
  - Unlike Web's `window.location.reload()`, Flutter updates `activeBusinessProvider`, invalidates all Riverpod feature providers, closes open detail sheets, and stays on the current top-level tab (or falls back to Dashboard if current detail ID belongs to the previous business).
