# DASH-02 — Adaptive App Shell & More Hub Screen (`AdaptiveShell` & `MoreHubScreen`)

> **Spec ID:** `DASH-02`
> **Phase / Task:** Phase 2 (`P2-01`)
> **Verified Web Sources:** `Web/project/frontend/app/[locale]/(dashboard)/layout.tsx`, `components/dashboard/{Sidebar,DashboardHeader,LifecycleBanners}.tsx`, `components/ai/{CopilotContextProvider,GlobalCopilotDrawer}.tsx`, `messages/{en,ar}/dashboard.json`
> **Verified Mobile Architecture Refs:** `05_MOBILE_INFORMATION_ARCHITECTURE.md`, `09_RESPONSIVE_AND_ADAPTIVE_DESIGN.md`, `FOLDER_STRUCTURE.md`

---

## 1. Screen Identity

- **Screen Names:** `AdaptiveShell` (authenticated root wrapper), `ShellAppBar`, `LifecycleBanners`, `MoreHubScreen`
- **Route Names & Paths:**
  - Shell Wrapper: `StatefulShellRoute.indexedStack` hosting branches `/dashboard` (`0`), `/transactions` (`1`), `/ai` (`2`), `/invoices` (`3`), `/more` (`4` — Phone `MoreHubScreen`)
  - Tablet Rail Direct Routes (`width >= 600dp`): exposes all 13 Web sidebar destinations directly (`/dashboard`, `/transactions`, `/expenses`, `/revenue`, `/invoices`, `/customers`, `/budgets`, `/recurring`, `/reports`, `/currencies`, `/ai`, `/calendar`, `/settings`)
- **Feature Modules:**
  - `lib/app/shell/{adaptive_shell.dart,shell_app_bar.dart,lifecycle_banners.dart}`
  - `lib/features/dashboard/presentation/screens/more_hub_screen.dart`

---

## 2. Purpose and Functional Parity

Translates AFAB Web's desktop collapsible 13-item `Sidebar`, sticky `DashboardHeader`, `LifecycleBanners`, and `GlobalCopilotDrawer` trigger into a native adaptive layout:
- On **Phones (`< 600dp`)**, replaces the hamburger drawer with a thumb-friendly **5-Tab Bottom `NavigationBar`** plus a structured **More Hub** directory so no feature is buried or omitted.
- On **Tablets (`>= 600dp`)**, transitions automatically to a **Material 3 `NavigationRail`** (`72dp` collapsed on `600–839dp`, `248dp` extended drawer-rail on `>= 840dp` / `>= 1024dp`), preserving 1-tap parity with all 13 Web sidebar items, the Free-plan `"Unlock more with Pro"` card, and the User Profile popup menu (Account Settings, Business Profile, Logout).

---

## 3. Navigation and Entry/Exit Paths

- **Entry Paths:**
  - Authenticated, email-verified, onboarding-complete session enters Branch `0` (`/dashboard`) via `GoRouter` redirect guard.
  - Deep links (`Notification.actionUrl`, Stripe billing return) resolve into matching branch or pushed child route inside the shell.
- **Phone 5-Tab Bottom Navigation (`< 600dp`):**
  - **Tab 0 — Home (`LayoutDashboard`):** `DashboardScreen` (`/dashboard`)
  - **Tab 1 — Finance (`ArrowRightLeft`):** `TransactionsScreen` (`/transactions`), nested stack for Expenses, Revenue, Details, Add/Edit, Split, Categories, Receipts
  - **Tab 2 — Copilot (`Sparkles`, elevated accent):** `AiCopilotScreen` (`/ai`), nested `BusinessMemoryScreen`
  - **Tab 3 — Invoices (`FileText`):** `InvoicesScreen` (`/invoices`), nested Invoice Details, Create/Edit, Record Payment, Customers, Customer Details
  - **Tab 4 — More (`LayoutGrid`):** `MoreHubScreen` (`/more`)
- **`MoreHubScreen` Directory (4 Categorized Sections):**
  1. **Money & Operations:** Expenses (`/expenses`), Revenue (`/revenue`), Categories (`/categories`), Customers (`/customers`), Budgets (`/budgets`), Recurring (`/recurring`), Financial Calendar (`/calendar`)
  2. **Intelligence & FX:** Currencies & FX Markets (`/currencies` with `FX` badge), Financial Reports (`/reports`)
  3. **Workspace & Billing:** Plans & Subscription (`/plans`), Switch or Create Business (`BusinessSwitcherSheet`)
  4. **Preferences & Account:** Settings Home (`/settings`), User Profile Header + Quick Logout button
- **Back Navigation Rules (`PopScope`):**
  - If current branch navigator can pop → pops nested route first.
  - If at root of non-Home tab (`index != 0`) → switches to Home tab (`index = 0`) on Android system back before allowing app exit.

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

- **Phone (`< 600dp`):**
  - `Scaffold`:
    - `appBar`: `ShellAppBar` (`56dp` + `SafeArea` top)
    - `body`: `Column([OfflineBanner, LifecycleBanners, Expanded(navigationShell)])`
    - `bottomNavigationBar`: Material 3 `NavigationBar` (`68dp` + `viewPadding.bottom`) with 5 destinations. Tab 2 (`Copilot`) uses subtle `primary` circular highlight pill + optional `glowColor` when `AppearanceSettings.enableGlow` is enabled.
  - `MoreHubScreen`: Scrollable list of user summary card (`avatar`, `fullName`, `email`, `planBadge`) → 4 grouped `AfabCard` sections with `ListTile` rows (48dp+ height, trailing chevron) → Free-plan Pro teaser card (only when `planSlug == 'free'`) → `"Logout"` danger action tile.
- **Tablet Portrait (`600–839dp`) & Landscape (`>= 840dp`):**
  - `Scaffold` body is a `Row`:
    - Leading `NavigationRail` (`72dp` icon-only on `600–1023dp` with tooltips; `248dp` extended drawer-rail on `>= 1024dp` with user-toggleable collapse/expand button mirroring `Sidebar.tsx` `PanelLeftClose`/`PanelLeftOpen`).
    - Rail Header: `BusinessSwitcher` compact/full trigger + Quick-Add (`+`) action.
    - Rail Scrollable Sections:
      - Primary (10): Overview, Transactions, Expenses, Revenue, Invoices, Customers, Budgets, Recurring, Reports, Currencies (`FX` badge).
      - Workspace (3): AI Assistant (`NEW` badge), Calendar, Settings.
    - Rail Footer: Free-plan `"Unlock more with Pro"` card (extended mode only, `planSlug == 'free'`) + User Profile menu (`Account Settings`, `Business Profile`, `Logout`).
    - Trailing `Expanded(Column([ShellAppBar, OfflineBanner, LifecycleBanners, Expanded(child)]))`.
- **Two-Pane Master-Detail Support (`>= 840dp`):**
  - Transactions, Customers, Invoices, AI Copilot, and Settings render side-by-side detail panes within the shell content area (`05_MOBILE_INFORMATION_ARCHITECTURE.md`).

---

## 5. UI Components and Design System Mapping

- **`ShellAppBar`:**
  - **Leading (Phones; hidden on Tablet Extended Rail where `BusinessSwitcher` lives in rail header):** `BusinessSwitcherPill` (`36dp` height inside `48dp` tap area) showing AFAB monogram (`afab-logo-light`/`dark`), active business name (truncated cleanly), plan pill (`Plus` `Zap` / `Pro` `Crown`), or `Locked` amber badge (`!editable`).
  - **Trailing:**
    1. **Ask Copilot Button (`Sparkles`):** Visible on all routes except `/ai`. Icon-only `40x40dp` (`48dp` touch) pill on phones; `"Ask Copilot"` pill on tablets. Opens `GlobalCopilotSheet` preloaded with active route `screenContext`.
    2. **Notification Bell (`Bell`):** `40x40dp` (`48dp` touch) button with red unread badge (`1..9`, `9+`) → pushes `NotificationsScreen` (or side popover on `>= 840dp`).
    3. **Tablet Upgrade CTA:** Shown on `>= 600dp` when `planSlug` is `'free'` or `'plus'` (hidden on `'pro'`), matching `DashboardHeader.tsx:150,281`.
- **`LifecycleBanners` (Stacked above route body):**
  1. **`PastDueGraceBanner` (`subscription.status == "PAST_DUE"`):** Red-amber gradient border card (`#EF4444` 30% border), `AlertTriangle`, remaining days/hours pill (`~{graceDays} day(s) / {graceHours}h remaining`), explanation of downgrade to Free after 3 days, `"Update Payment Method"` button (`POST /billing/portal` → `flutter_custom_tabs`).
  2. **`ReadOnlyBusinessBanner` (`activeBusiness.editable == false`):** Amber tint (`#F59E0B` 10% fill, 30% border), `Lock` icon, `"{businessName}" is Locked`, `"Manage Allocation"` & `"Upgrade Plan"` buttons → `/plans`.
  3. **`AllocationAttentionBanner` (`allocationAttentionRequired && !isReadOnlyBusiness`):** `primary` tint card, `Building2` icon, `"Choose Businesses"` CTA → `/plans`.
  4. **`OfflineBanner`:** Neutral dark/amber slim strip when `connectivity_plus` reports offline (`APP-04`).
- **`MoreHubScreen` Tiles:** `AfabCard` grouped containers, `AfabInsetPanel` icon tiles (`36x36dp` tinted background), `AfabStatusBadge` (`FX`, `NEW`, `Pro`/`Plus`/`Free`), directional `ChevronRight` (`matchTextDirection: true`).

---

## 6. Data Models and State Management

- **Providers Watched by Shell:**
  - `userProfileProvider` (`GET /api/v1/user/me`) — user name, email, avatar, `planTier`, `compactMode`.
  - `subscriptionSnapshotProvider` (`GET /api/v1/subscription/me`) — `planSlug`, `status`, `gracePeriodHoursRemaining`, `gracePeriodEndsAt`, `allocationAttentionRequired`.
  - `activeBusinessProvider` (`GET /api/v1/business/mine` + `GET /api/v1/business`) — `id`, `name`, `currency`, `editable`, `userRole`.
  - `unreadNotificationCountProvider` (derived from `notificationsProvider`, `GET /api/v1/notifications`).
  - `connectivityStatusProvider` (`connectivity_plus` stream).
  - `railCollapsedProvider` (`bool`, persisted in `SharedPreferences` for tablets).
- **Copilot Context Provider (`copilotContextProvider`):** Tracks active screen metadata (`{'page': routeName, 'period': ...}`) so tapping `Ask Copilot` in `ShellAppBar` passes accurate route context into `GlobalCopilotSheet`.

---

## 7. API Contracts and Data Flow

- `GET /api/v1/user/me` (profile & preferences)
- `GET /api/v1/subscription/me` (plan tier, `PAST_DUE` grace period, `allocationAttentionRequired`)
- `GET /api/v1/business/mine` & `GET /api/v1/business` (active workspace metadata & editable status)
- `GET /api/v1/notifications` (unread badge hydration on shell mount + resume)
- `POST /api/v1/billing/portal` (`{ locale, returnPath: "/dashboard/settings/subscription" }`) from `PastDueGraceBanner` `"Update Payment Method"`
- `POST /api/v1/auth/logout` (with `Cookie` + `X-CSRF-Token`) from Profile Menu / `MoreHubScreen` Logout.
- **Note on `403 BUSINESS_READ_ONLY`:** If `GET /business/mine` returns `403 BUSINESS_READ_ONLY`, `ApiErrorInterceptor` clears `activeBusinessId`, triggers `businessListProvider` refresh, and surfaces `BusinessReadOnlySheet` (`APP-04`) without crashing the shell.

---

## 8. User Interactions and Event Handling

- **Tap Business Switcher Pill:** Opens `BusinessSwitcherSheet` (`DASH-03`).
- **Tap Ask Copilot Icon:** Opens `GlobalCopilotSheet` over current tab.
- **Tap Notifications Bell:** Pushes `NotificationsScreen` (`DASH-04`) and forces `notificationsProvider` refresh.
- **Tap Bottom Nav / Rail Item:** Switches branch via `navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)`. Tapping active tab pops nested stack back to tab root.
- **Tap `"Update Payment Method"` (`PastDueGraceBanner`):** Calls `POST /billing/portal`, opens returned Stripe Portal URL in `flutter_custom_tabs`; on custom tab close, refreshes `subscriptionSnapshotProvider` & `businessListProvider`.
- **Tap `"Logout"` (`MoreHubScreen` / Tablet Profile Menu):** Shows confirmation dialog (or immediate progress indicator), calls `POST /auth/logout` (best-effort), wipes RAM JWT + `EncryptedCookieStorage` + Riverpod caches, routes to `/login`.

---

## 9. Validation, Error, Loading, and Empty States

- **Shell Hydration:** Shell renders immediately with cached/skeleton placeholders for `ShellAppBar` business name and avatar while `userProfileProvider` and `activeBusinessProvider` resolve; never blocks bottom navigation on non-critical header calls (`notifications`, `subscription`).
- **Portal Error (`PastDueGraceBanner`):** Displays `AfabToast` error (`"Could not open Stripe Payment Portal"`) and re-enables button.
- **Logout Network Failure:** Always clears local session (`SessionTokenHolder`, `EncryptedCookieStorage`, `activeBusinessId`) in `finally` block (matching `Sidebar.tsx:135`) and navigates to `/login`.
- **Banners Visibility Rules:**
  - `LifecycleBanners` renders zero height (`SizedBox.shrink()`) when `!isPastDue && !isReadOnlyBusiness && !needsAllocationAttention`.
  - `AllocationAttentionBanner` is suppressed when `isReadOnlyBusiness` is already true (matching `LifecycleBanners.tsx:205`) to avoid stacked redundant banners.

---

## 10. Localization (EN/AR) and RTL Behavior

- **ARB Keys:** Migrates `Dashboard.sidebar.*` and `Dashboard.header.*`, plus extracts Web's inline `isAr` ternaries from `DashboardHeader.tsx` (`"Ask Copilot"`, `"Notifications"`, `"Mark all read"`, `"Upgrade to Pro"`), `Sidebar.tsx` (`"Unlock more with Pro"`, `"Upgrade Now"`, `"Account Settings"`, `"Business Profile"`, `"Logout"`), and `LifecycleBanners.tsx` (grace period banner, locked business banner, allocation attention banner) into `app_en.arb` / `app_ar.arb`.
- **More Hub Labels:**
  - Tab labels: `Home`/`الرئيسية`, `Finance`/`المالية`, `Copilot`/`المساعد الذكي`, `Invoices`/`الفواتير`, `More`/`المزيد`.
  - Section headers (`Money & Operations`, `Intelligence & FX`, `Workspace & Billing`, `Preferences & Account`) localized cleanly in EN & AR.
- **RTL Mirroring:**
  - `NavigationBar` destinations mirror order automatically in `Directionality(rtl)`.
  - `NavigationRail` automatically moves to the right edge in Arabic RTL (`Scaffold` handles start/end placement).
  - `PanelLeftClose` / `PanelLeftOpen`, `LogOut`, and `ArrowRight` icons set `matchTextDirection: true`.

---

## 11. Accessibility and Responsive Guardrails

- **No Horizontal Overflow:** On `320dp` phones, `BusinessSwitcherPill` uses `Expanded` + `TextOverflow.ellipsis` so trailing `Sparkles` and `Bell` buttons never push off-screen.
- **Banner Responsiveness:** On `< 600dp`, `LifecycleBanners` stack text above full-width / wrapped action buttons (`Wrap`), whereas on `>= 600dp` text sits beside trailing action buttons.
- **Labels & Semantics:**
  - Bottom nav labels stay visible (`NavigationDestinationLabelBehavior.alwaysShow` on `>= 360dp`, concise single-word EN/AR labels so none wrap to 2 lines).
  - Notification bell announces `"Notifications, {unreadCount} unread"` via `Semantics`.
- **Keyboard Avoidance:** `NavigationBar` is hidden or pushed beneath keyboard properly (`Scaffold.resizeToAvoidBottomInset: true`) and full-screen forms push onto root navigator (`parentNavigatorKey`) to cover the bottom nav cleanly.

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **Theme & Language Toggles Moved Out of Top AppBar (`DashboardHeader.tsx:180-189`):** On phones, squeezing Business Switcher + Theme + Language + Copilot + Bell + Upgrade into a `360dp` AppBar causes crowding. Mobile keeps `ShellAppBar` focused on **Business Switcher + Ask Copilot + Bell** (with Upgrade on tablets) and places Theme (`AppearanceSettingsScreen`) & Language (`LanguageSettingsScreen` — fixing Web's `[...slug]` `"Coming Soon"` bug) in Settings / `MoreHubScreen`.
2. **Duplicate Mounted Sidebar Fix (`Sidebar.tsx:478`):** Web previously had to conditionally mount mobile drawer to avoid duplicate `BusinessSwitcher` API calls; Flutter's `StatefulShellRoute` + single `AdaptiveShell` + Riverpod `keepAlive`/deduplicated providers guarantee 1 fetch per lifecycle.
3. **Inline `isAr` Strings Extracted:** All hardcoded Arabic/English ternaries in `Sidebar.tsx`, `DashboardHeader.tsx`, and `LifecycleBanners.tsx` are moved into typed ARB keys.
4. **No Full-App Reload on Business Switch:** Changing workspace updates Riverpod state seamlessly inside the shell instead of reloading the page.

---

## 13. Testing and Verification Plan

- **Widget Tests (`test/widget/shell/adaptive_shell_test.dart`):**
  - Width `390dp` renders `NavigationBar` (5 tabs) and hides `NavigationRail`.
  - Width `768dp` renders collapsed `NavigationRail` (`72dp`) with all 13 destinations.
  - Width `1280dp` renders extended `NavigationRail` (`248dp`) + collapse toggle.
  - `Tab 2 (Copilot)` hides `Ask Copilot` icon in `ShellAppBar`.
  - `PAST_DUE` subscription renders `PastDueGraceBanner` with accurate `graceHours` & `"Update Payment Method"`.
  - `editable == false` renders `ReadOnlyBusinessBanner` and suppresses `AllocationAttentionBanner`.
  - `MoreHubScreen` renders all 4 categories and navigates to every destination without missing routes, in both `en` (LTR) and `ar` (RTL).

---

## 14. Dependencies and Risks

- **Package Dependencies:** `go_router`, `flutter_riverpod`, `connectivity_plus`, `flutter_custom_tabs`, `lucide_icons_flutter`.
- **Technical Risks:**
  - **Nested Tab Stack vs Root Modal Routes:** Full-screen forms (`AddEditTransaction`, `CreateEditInvoice`) and `NotificationsScreen` should push with `parentNavigatorKey: rootNavigatorKey` when hiding the bottom nav is desired, while keeping branch-local pushes inside tabs where back-stack preservation matters.
  - **Custom Tabs Portal Return:** When returning from Stripe Billing Portal (`PastDueGraceBanner`), `WidgetsBindingObserver.didChangeAppLifecycleState(AppLifecycleState.resumed)` should refresh `subscriptionSnapshotProvider` so `PAST_DUE` banner clears immediately after payment update.
