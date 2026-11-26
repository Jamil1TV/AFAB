# PLAN-01 — Plans & Subscription Screen Specification

> **Verified Sources:**
> - Web Pages: `Web/project/frontend/app/[locale]/(dashboard)/dashboard/plans/page.tsx`, `upgrade/page.tsx`, `settings/subscription/page.tsx`
> - Web Component & API: `Web/project/frontend/components/plans/PlansScreen.tsx`, `Web/project/frontend/lib/api/subscription.ts`, `Web/project/frontend/lib/api/business.ts`
> - Backend: `SubscriptionController.java`, `StripeBillingController.java`, `StripeBillingService.java`, `EntitlementService.java`, `SubscriptionSnapshotDTO.java`
> - Mobile Core Docs: `03_API_CONTRACT_CATALOG.md`, `05_MOBILE_INFORMATION_ARCHITECTURE.md`, `07_DESIGN_SYSTEM.md`, `08_LOCALIZATION_AND_RTL.md`, `10_USER_FLOWS_AND_NAVIGATION.md`, `13_RISKS_AND_TECHNICAL_DECISIONS.md`

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `PLAN-01` |
| **Screen Name** | `PlansAndSubscriptionScreen` |
| **Feature Module** | `lib/features/plans/` |
| **Route Paths** | `/plans` (`AppRoutes.plans`), `/settings/subscription` (alias), plus deep-link intercepts for `/dashboard/plans`, `/dashboard/upgrade`, and `/dashboard/settings/subscription` |
| **Navigation Location** | Phone: `MoreHubScreen` → *Workspace & Billing* → *Plans & Subscription*, and `SettingsHomeScreen` → *Subscription & Plans*; Tablet: `NavigationRail` footer CTA & `Settings` split pane |
| **Related Sheets** | `PLAN-02` (`BusinessAllocationSheet`, `CancelSubscriptionSheet`) |

---

## 2. Purpose and Web Parity Status

- **Purpose:** Serves as the single unified billing, entitlement, and subscription lifecycle hub—absorbing Web's `/plans` (redirect), `/upgrade` (redirect), and `/settings/subscription` (`PlansScreen.tsx`). Displays current subscription status, AI token/query usage meter, editable vs locked business allocation summary, monthly/yearly pricing cards, full feature comparison table, billing/payment history, and Stripe Checkout / Customer Portal handoffs.
- **Web Parity Status:** **Implemented and Connected** (Stripe sandbox), with **4 Mobile fixes and 1 critical App Store compliance risk**:
  1. **Fixes Missing `plan.features` List on Plan Cards (`PlansScreen.tsx:239-423, 1282-1450`):** Web defines a detailed `features` checklist + `featuresHeader` + tooltips on `Free`, `Plus`, and `Pro` in `plans[]`, **but never renders them** inside the pricing card JSX! Mobile renders the full `featuresHeader` + included/excluded feature checklist (and tappable info tooltips) on each card.
  2. **Fixes Hardcoded `$` Currency Bug (`PlansScreen.tsx:1353, 1639`):** Web hardcodes `$` in front of plan prices (`$${price}`) and payment history rows (`$${(pay.amountCents / 100).toFixed(2)} ${pay.currency}`). Mobile formats plan card prices using `subscription.currency` (default `"USD"`) and formats **every payment history row using its own `pay.currency`** via `MoneyFormatter` (handling 0-decimal currencies such as `JPY` where `amountCents` is minor units, and 3-decimal currencies cleanly).
  3. **Fixes Embedded/Duplicate Routes:** Consolidates `/plans`, `/upgrade`, and `/settings/subscription` cleanly via GoRouter redirects so there is zero flicker from client-side `router.replace()` redirects (`plans/page.tsx`, `upgrade/page.tsx`).
  4. **App Link / Universal Link Return Handling:** Because `StripeBillingService.sanitizeReturnPath()` rejects custom schemes like `afab://` (`StripeBillingService.java:1529`), Mobile passes `returnPath: "/dashboard/settings/subscription"` and uses verified Universal Links (iOS) / App Links (Android) to capture `?checkout=success&session_id=...` or `?checkout=canceled` back into `PlansAndSubscriptionScreen`.
  5. **Store Policy Risk (Apple Guideline 3.1.1 & Google Play Billing):** Opening Stripe Checkout inside a mobile app for digital SaaS tiers (`Plus`/`Pro`) carries **App Store / Play Store rejection risk** unless governed by an approved billing strategy (see Section 14).

---

## 3. Navigation, Entry Points, and Deep Links

- **Entry Points:**
  - `MoreHubScreen` → *Plans & Subscription*.
  - `SettingsHomeScreen` → *Subscription & Plans*.
  - `PastDueGraceBanner` ("Update Payment") or `AllocationAttentionBanner` ("Manage Workspaces").
  - `PlanLimitSheet` ("Upgrade Plan") triggered globally by any `403 PLAN_LIMIT_REACHED` response (e.g., AI Copilot quota, invoice limit, export limit, report level, business max).
  - Tablet `NavigationRail` footer Upgrade CTA (when on `free`).
- **Deep Links:**
  - `https://<web-domain>/{en|ar}/dashboard/settings/subscription?checkout=success&session_id={SESSION_ID}` → triggers `POST /api/v1/billing/checkout/verify`.
  - `https://<web-domain>/{en|ar}/dashboard/settings/subscription?checkout=canceled` → shows info toast (`"Checkout was canceled. No charges were made."`).
  - `https://<web-domain>/{en|ar}/dashboard/settings/subscription?changePlan=true` → auto-expands plan cards section (`showPlanCardsOverride = true`).
  - `Notification.actionUrl == "/dashboard/settings/subscription"` → routes here directly.

---

## 4. Layout and Visual Hierarchy

1. **Page Header + Active Businesses Summary Pill:**
   - Title: *"Manage Subscription & Plans"*.
   - Compact `AfabCard` pill: `Building2` icon + `"Active Businesses: {editableCount} / {editableLimit}"` + subtitle *"Additional businesses stay safely locked until you upgrade or swap."*
2. **Current Subscription Overview Card (`AfabCard` with `primary` 25% border):**
   - **Header Row:** `CreditCard` icon tile, `"Current Plan: {planName}"`, Status badge (`ACTIVE` green, `TRIALING` primary, `PAST_DUE` red, `CANCELED`/`EXPIRED` neutral), Billing Interval badge (`Monthly Billing` / `Yearly Billing`), Scheduled Cancel / Pending Downgrade warning badge.
   - **Dates & Trial Countdown:**
     - If `isTrialActive`: `"7-Day Plus Trial: {trialDaysRemaining} day(s) remaining (expires {trialEnd})"`.
     - Renewal / Cancel / Pending Transition date (`effectiveCancelAt` / `pendingChangeEffectiveAt` / `periodEnd`).
   - **Action Buttons Wrap:**
     - If `Plus` (`hasActivePaidSubscription`): `"Upgrade to Pro"` / `"Hide Plan Options"` (`AfabButton.premium`).
     - If `Pro` (`hasActivePaidSubscription`): `"Change / Downgrade Plan"` / `"Hide Plan Options"` (`AfabButton.secondary`).
     - If `hasPendingChange` (`cancelAtPeriodEnd || pendingPlanSlug`): `"Keep / Resume Subscription"` or `"Cancel Scheduled Downgrade"` (`AfabButton.primary` → `POST /billing/resume`).
     - If `hasStripeCustomer`: `"Manage Billing & Payment Methods"` (`AfabButton.secondary` → `POST /billing/portal`).
     - If `hasStripeSubscription && !cancelAtPeriodEnd`: `"Cancel Free Trial"` / `"Cancel Subscription"` (`AfabButton.danger` → opens `CancelSubscriptionSheet` `PLAN-02`).
   - **Monthly AFAB Copilot Token & Query Usage Meter (`AfabInsetPanel`):**
     - Displays `{tokenUsed} / {tokenLimit} tokens ({queryUsed}/{queryLimit} queries)` (or `∞` if `< 0`).
     - Progress bar colored `primary` (`< 75%`), amber (`>= 75%`), red (`>= 90%`).
   - **Pending Downgrade / Cancel Alert Box (amber, conditional on `hasPendingChange`):**
     - Explains retention of current entitlements until `effectiveEndDateFormatted` + `"Configure Future Businesses"` button (shown when `ownedBusinesses.length > (allocation.pendingEditableLimit ?? 1)`, opens `BusinessAllocationSheet` in `PENDING_EDIT` mode).
   - **3-Day Grace Period Banner (red, conditional on `isPastDue`):**
     - `"Payment Failed — 3-Day Grace Period ({gracePeriodHoursRemaining ?? 72} hours remaining)"` + `"Update Payment Method"` button → `POST /billing/portal`.
3. **Business Allocation Summary Section (`AfabCard`, shown when `ownedBusinesses.length > 0`):**
   - Header + `"Change Editable Businesses"` button (when `ownedBusinesses.length > 1`, opens `BusinessAllocationSheet` in `MANAGE` mode).
   - List/Grid of owned businesses with `logoUrl`/icon, `name`, `Primary` badge, `currency • industry`, and status pill (`Active` green vs `Locked` amber).
4. **Billing Interval Toggle, Trial Banner & Plan Cards (`shouldShowPlanCards = !hasActivePaidSubscription || showPlanCardsOverride`):**
   - **Monthly / Yearly `AfabSegmentedBar`** with `"Save 20%"` green badge on Yearly.
   - **7-Day Plus Trial Banner** (shown when `isTrialActive` or `isPlusTrialEligible`).
   - **3 Plan Cards (`Free`, `Plus` [highlighted `primary` border + `"Most Popular • 7-Day Trial"` pill], `Pro` [amber VIP accent]):**
     - Icon tile, Active badge, Name (+ `VIP` for Pro), Subtitle, Price (`MoneyText(price, currency)` + `/ month` + `(billed annually)`), Description, CTA Button (`Current Plan`, `Start 7-Day Free Trial`, `Upgrade to {Plan}`, `Downgrade to Plus`, `Downgrade to Free`), **Features Header & Checklist** (`features[]` with `Check`/`X` icons and tap-to-view tooltip).
5. **Compare Plans Matrix (`AfabCard`):**
   - 11 comparison rows (`AI Copilot Tokens & Queries`, `AI Recommendations`, `Cash Flow Forecasting`, `Financial Reports`, `Invoices`, `Active (Unlocked) Businesses` [with info tooltip], `Locked Vaulted Businesses`, `Export Data`, `Email Support`, `Priority Support`, `7-Day Free Trial (Plus Exclusive)`).
6. **Subscription & Payment History (`subscriptionHistory` & `paymentHistory`, shown if either non-empty):**
   - **Subscription Change History:** Event type (`CANCEL_SCHEDULED`, `UPGRADED`, etc.), date, details.
   - **Payment & Invoice History:** Per-row formatted amount (`pay.amountCents / 100` in `pay.currency`), status pill (`PAID` green / `FAILED` red / `OPEN`), date, optional `failureReason`, and `"Invoice"` button opening `hostedInvoiceUrl` (plus optional `invoicePdfUrl` download/open).

---

## 5. UI Components and Design System Mapping

| UI Element | Shared / Feature Widget | Design Token & Styling (`07_DESIGN_SYSTEM.md`) |
|---|---|---|
| Plan Cards | `AfabCard` / `PlanTierCard` | `Plus`: `2px primary` border + `glowColor` shadow; `Pro`: amber `40%` border + subtle gradient; `Free`: standard `AfabCard` |
| Upgrade / Trial CTAs | `AfabButton.premium` | Gradient `primary → primaryHover`, min height `48dp` |
| Token Usage Meter | `LinearProgressIndicator` | `8dp` height, rounded track, `<75% primary`, `75–89% #F59E0B`, `>=90% #EF4444` |
| Grace / Pending Banners | `AfabInsetPanel` semantic | Red `10%` bg + `30%` border (`PAST_DUE`); Amber `10%` bg + `25%` border (Pending change) |
| Comparison Matrix | Pinned-column comparison or Tier Filter Tabs on `< 600dp`; full `DataTable` on `>= 840dp` | `Plus` column highlighted with `primary` `4–6%` tint |
| External Stripe Sheet | `flutter_custom_tabs` (`CustomTabs` / `SFSafariViewController`) | Matches app `primary` toolbar color |

---

## 6. State Management and Data Flow

- **Providers (`lib/features/plans/presentation/providers/plans_providers.dart`):**
  - `subscriptionSnapshotProvider` (`AsyncNotifier<SubscriptionSnapshot>`): Calls `GET /api/v1/subscription/me`. Shared across app shell (`PastDueGraceBanner`, `AiCopilotScreen`, `ReportsScreen`).
  - `businessAllocationProvider` (`FutureProvider<BusinessAllocationSummary?>`): Calls `GET /api/v1/business/allocations`.
  - `billingHistoryProvider` (`FutureProvider<BillingHistoryResponse?>`): Calls `GET /api/v1/billing/history`.
  - `plansUiStateProvider` (`Notifier<PlansUiState>`): Tracks `billingPeriod` (`monthly` | `yearly`, synced initially from `subscription.billingInterval`), `showPlanCardsOverride`, and `submittingAction` (`null | 'plus' | 'pro' | 'portal' | 'cancel' | 'resume' | 'allocation'`).
- **Checkout Verification & Refresh Lifecycle:**
  1. When deep-link arrives with `?checkout=success&session_id=...`, `verifyCheckoutSession(sessionId)` runs `POST /api/v1/billing/checkout/verify`.
  2. Immediately invalidates/refreshes `subscriptionSnapshotProvider`, `businessAllocationProvider`, `billingHistoryProvider`, `businessListProvider`, `activeBusinessProvider`, and updates `sessionUser.planTier`.
  3. Also attaches `WidgetsBindingObserver` (`didChangeAppLifecycleState(resumed)`): if user opened Stripe Checkout or Portal via `flutter_custom_tabs` and manually closed the browser tab after paying without triggering the App Link redirect, automatically call `refreshAllBillingData(force: true)` on resume so subscription state never looks stale!

---

## 7. API Contracts and DTO Mapping

| Endpoint | Request Body / Params | Response DTO | Notes |
|---|---|---|---|
| `GET /api/v1/subscription/me` | — | `SubscriptionSnapshotDto` (38 fields incl. `planSlug`, `status`, `trial`, `trialDaysRemaining`, `trialEligible`, `billingInterval`, `cancelAtPeriodEnd`, `pendingPlanSlug`, `gracePeriodHoursRemaining`, `allocationAttentionRequired`, `editableBusinessLimit`, `hasStripeCustomer`, `hasActiveStripeSubscription`, `stripeConfigured`, `entitlements`, `usage`) | Note: `EntitlementService` sets `isTrial` which Jackson serializes as `"trial"` (`boolean isTrial()`). Map `@JsonKey(name: 'trial')` with fallback to `'isTrial'`. |
| `GET /api/v1/business/allocations` | — | `BusinessAllocationDto` | Owned businesses + `pendingBusinessIds` |
| `GET /api/v1/billing/history` | — | `BillingHistoryResponseDto`: `{ subscriptionHistory[<=50], paymentHistory[<=50] }` | `PaymentHistoryItemDto.amountCents` (long) + `currency` |
| `POST /api/v1/billing/checkout` | `{ planSlug: "plus"\|"pro", billingInterval: "monthly"\|"yearly", locale: "en"\|"ar", returnPath: "/dashboard/settings/subscription" }` | `CheckoutSessionResponseDto`: `{ sessionId, url, mode: "CHECKOUT"\|"PORTAL" }` | Creates 7-day trial automatically for eligible `plus` checkouts |
| `POST /api/v1/billing/upgrade` | `{ planSlug, billingInterval, locale, returnPath }` | `UpgradeSubscriptionResponseDto`: `{ mode: "DIRECT_UPGRADE"\|"CHECKOUT"\|"PORTAL", sessionId?, url?, snapshot? }` | Prorated direct update if active Stripe sub; Checkout if Free |
| `POST /api/v1/billing/portal` | `{ locale, returnPath }` | `PortalSessionResponseDto`: `{ url }` | Requires `hasStripeCustomer == true` |
| `POST /api/v1/billing/checkout/verify` | `{ sessionId }` | `SubscriptionSnapshotDto` | Verifies `clientReferenceId` or `stripeCustomerId` ownership |
| `POST /api/v1/billing/resume` | — | `SubscriptionSnapshotDto` | Reverses scheduled cancel or downgrade |
| `POST /api/v1/subscription/{trial,switch}` | `{ planSlug }` | `SubscriptionSnapshotDto` | Dev-only fallback; returns `403` when Stripe configured or outside `local`/`dev` |

- **Redacted Configuration References:** Backend resolves Stripe product/price/portal config IDs server-side (`<stripe-product-id>`, `<stripe-price-id>`, `<stripe-portal-config-id>`); mobile **never** embeds or receives Stripe secret keys or price IDs.

---

## 8. Form Fields, Validation, and Business Rules

1. **Billing Interval:** `"monthly"` or `"yearly"` (normalized server-side). Switching interval updates displayed prices (`$9.99` vs `$7.99` for Plus; `$19.99` vs `$15.99` for Pro).
2. **7-Day Free Trial Policy:** Exclusively on `Plus`, once per account (`trialEligible == !trialUsed && !hasActiveStripeSubscription`). `Pro` never offers a free trial (`StripeBillingService.java:146`).
3. **Return Path Allowlist (`StripeBillingService.java:1524-1537`):** Must start with `/dashboard`, no `//`, no `://`. Mobile always sends `"/dashboard/settings/subscription"`.
4. **Action Locking:** While `submittingAction != null`, all upgrade/downgrade/portal/cancel/resume buttons disable to prevent double-taps or duplicate Stripe Checkout sessions.
5. **Unused Seeded Entitlements Note:** `invoices.per_month`, `team.users`, `forecast.cashflow`, `ai.recommendations` are seeded in `PlanEntitlement` and shown in the marketing Comparison Table (matching Web `PlansScreen.tsx:435-461`), though backend enforcement currently focuses on `ai.chat.*`, `business.max`, `reports.level`, and `export.per_month`.

---

## 9. User Interactions and Edge Cases

- **Upgrading from Free (`hasActiveStripeSubscription == false`):** Calls `POST /billing/checkout` (or `/billing/upgrade` which delegates to checkout) → opens `res.url` in `flutter_custom_tabs`.
- **Upgrading from Plus to Pro (`hasActiveStripeSubscription == true`):** Calls `POST /billing/upgrade` → returns `mode: "DIRECT_UPGRADE"` with updated `snapshot` directly in JSON (no browser handoff!), automatically restores previously `READ_ONLY` businesses up to `5`, and shows success toast.
- **Stripe Returns `mode == "PORTAL"`:** If user already has an active Stripe sub when calling `/checkout`, backend returns Portal URL instead of creating a duplicate subscription (`StripeBillingService.java:124-127`). Mobile opens `res.url` in Custom Tabs.
- **Opening Invoice URL (`hostedInvoiceUrl`):** Tapping `"Invoice"` in Payment History launches URL via Custom Tabs / external browser.
- **Stripe Not Configured (`503 BillingNotConfiguredException`):** Show clear error toast/banner (*"Billing service is not configured in this environment"*); do **not** silently call `/subscription/switch` in production builds.

---

## 10. Loading, Empty, Error, and Offline States

- **Initial Loading:** `AfabLoader` (`"Loading subscription details..."`) while fetching `/subscription/me`, `/business/allocations`, and `/billing/history`.
- **Checkout Verification Loading:** Full-card loading overlay (`"Verifying your Stripe subscription..."`) on deep-link return until `POST /billing/checkout/verify` completes.
- **Empty Payment History:** `"No invoice payments recorded yet."` inside Payment & Invoice History card.
- **Error States:** `400`/`403`/`503`/Stripe errors surface via `AfabToast.error` with server `message`; initial load failure shows `AfabEmptyState` with Retry button.
- **Offline State:** Disable Upgrade, Downgrade, Cancel, Resume, and Portal buttons while offline; keep cached `SubscriptionSnapshot` summary visible read-only with `OfflineBanner`.

---

## 11. Localization (EN/AR) and RTL Behavior

- **Translation Keys:** Extract all ~120 inline `isAr ? ... : ...` strings in `PlansScreen.tsx` into `app_en.arb` and `app_ar.arb` (`plansHeaderManage`, `plansCurrentPlan`, `plansAiMeterTitle`, `plansGracePeriodTitle`, `plansCompareTitle`, `plansFeature...`).
- **Locale Forwarding:** Pass active app locale (`"en"` or `"ar"`) to `POST /billing/checkout`, `POST /billing/upgrade`, and `POST /billing/portal` so Stripe Checkout & Customer Portal render in the user's chosen language.
- **RTL & BiDi:**
  - Prices (`$9.99`, `$19.99`), token counts (`15,000 / 150,000`), and payment amounts (`$19.99 USD`) wrap in `Directionality(textDirection: TextDirection.ltr)` with `tabularFigures`.
  - `ArrowRight` icons on Upgrade CTAs use `matchTextDirection: true`.
  - Dates use localized Gregorian formatting (`intl` `DateFormat.yMMMd(locale)`).

---

## 12. Responsive and Tablet Adaptation

- **Phone (`< 600dp`):**
  - Subscription Overview header stacks plan info above wrapped action buttons.
  - Business Allocation list renders full-width 1-column cards.
  - Plan Cards (`Free`, `Plus`, `Pro`) stack vertically (`Plus` ordered first or visually highlighted with `"Most Popular"` badge; preserve `Free` / `Plus` / `Pro` order with clear `"Active"` pill on current card).
  - **Compare Plans Matrix on Phone:** Rather than an awkwardly wide 4-column horizontal-scroll table, render an adaptive **2-tier comparison list** (Feature label on top/left + compact 3-column mini-grid `Free | Plus | Pro` below each row) or horizontally scrollable table with pinned feature column.
  - History sections (`Subscription Change History` & `Payment & Invoice History`) stack vertically or use a 2-tab toggle.
- **Tablet (`>= 600dp` / `>= 840dp`):**
  - Plan Cards render in a `3-column` equal-height row (`Plus` elevated slightly on `>= 1024dp`).
  - Business Allocation cards render in `2-col` (`600–839dp`) / `3-col` (`>= 840dp`).
  - Compare Plans renders full 4-column `DataTable`; History renders side-by-side (`2-column` grid).

---

## 13. Acceptance Criteria and Test Scenarios

1. **Plan Card Completeness:** All 3 plan cards display their `featuresHeader` and full `features` checklist (`Check`/`X` + tappable tooltip) and format prices using `subscription.currency`.
2. **Checkout & Deep-Link Verification:** Tapping `"Start 7-Day Free Trial"` on Free launches Custom Tabs; returning via `?checkout=success&session_id=...` calls `POST /billing/checkout/verify`, updates status to `TRIALING`, hides plan cards by default, and refreshes business allocations.
3. **Resume Fallback on Manual Tab Close:** Closing Custom Tabs manually after completing payment still refreshes `SubscriptionSnapshot` when app resumes.
4. **Per-Row Payment Currency:** Payment history rows format `amountCents` using each row's `pay.currency` (not hardcoded `$`).
5. **Grace Period & Pending Change:** `PAST_DUE` shows red 3-day grace banner + `"Update Payment Method"` portal CTA; `cancelAtPeriodEnd` or `pendingPlanSlug` shows amber banner + `"Keep / Resume Subscription"` (`POST /billing/resume`) and `"Configure Future Businesses"`.

---

## 14. Dependencies and Risks

- **Dependencies:** `flutter_custom_tabs`, `url_launcher`, `flutter_riverpod`, `decimal`, `intl`, `PlansRepository`, `BusinessAllocationRepository`, `BusinessAllocationSheet` & `CancelSubscriptionSheet` (`PLAN-02`).
- **Technical Risks & Mitigations:**
  - **Apple App Store (Guideline 3.1.1) & Google Play Billing Policy (`13_RISKS_AND_TECHNICAL_DECISIONS.md` §3):** Directing users from inside an iOS/Android app to external Stripe Checkout for digital SaaS subscriptions risks App Review rejection. **Mitigation (Decision Gate Required before P6-01):** Confirm with stakeholders whether to (a) make mobile a "companion" view for managing existing plans while directing new subscriptions to web ("Manage subscription on web") without external purchase links, (b) integrate native StoreKit / Google Play Billing (e.g., RevenueCat) synced to backend `subscriptions`, or (c) apply for region-specific external purchase link entitlements.
  - **Universal Links / App Links Domain Setup:** If `assetlinks.json` (Android) or `apple-app-site-association` (iOS) is not hosted on `<web-domain>`, Stripe's redirect URL stays in Custom Tabs instead of returning automatically to the app. **Mitigation:** Pair Universal Link verification with the `AppLifecycleState.resumed` auto-refresh fallback.
  - **`Stripe` Webhook Delay vs `/verify`:** Webhook may arrive after user returns. **Mitigation:** Always call `POST /billing/checkout/verify` on checkout return, which synchronously retrieves the Stripe session & subscription (`StripeBillingService.java:196-208`).
