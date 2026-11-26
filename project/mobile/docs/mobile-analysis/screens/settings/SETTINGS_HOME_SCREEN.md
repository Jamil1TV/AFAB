# SET-01 — Settings Home Screen (`SettingsHomeScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-01` |
| **Screen Name** | Settings Home (`SettingsHomeScreen`) |
| **Route Path** | `/settings` (nested under More Hub branch on Phone; direct rail item on Tablet) |
| **Feature Module** | `lib/features/settings/presentation/settings_home_screen.dart` |
| **Web Equivalent** | `settings/layout.tsx` + `settings/page.tsx` + `SettingsProvider.tsx` |
| **Priority** | P1 (Core Workspace & Account Shell) |

---

## 2. Purpose and User Goal

Provide a clean, thumb-friendly categorized Settings Hub on mobile phones and an adaptive two-pane master-detail workspace on tablets. Users can view their personal account summary, current subscription tier, and active business workspace at a glance, then navigate directly to any of the **11 AFAB Settings sections** (including Subscription & Billing and the newly functional native Language switcher) or sign out safely.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/settings/layout.tsx` | 11-tab desktop sidebar (`w-60` / `w-[60px]`), plus mobile horizontal pill strip + redundant dropdown menu (`mobileNavOpen`). | **Adapted (`Implemented and Connected`):** On Phones (`< 600dp`), replaces the cramped horizontal strip + dropdown with a structured categorized vertical Settings Hub list (`SettingsHomeScreen`) that pushes sub-screens. On Tablets (`>= 600dp` / `>= 840dp`), renders a `260dp` persistent category rail alongside the active detail pane. |
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/settings/page.tsx` | Server redirect `redirect('/[locale]/dashboard/settings/general')`. | **Adapted:** Phone stays on `/settings` Hub (pushing `/settings/general`, etc. on tap); Tablet auto-selects `GeneralSettingsScreen` (`SET-02`) in the right detail pane so no blank pane ever appears. |
| `Web/project/frontend/components/settings/SettingsProvider.tsx` | Fetches `GET /user/me` and `GET /business/mine` via `Promise.allSettled` on mount, showing full-screen `AfabLoader` while loading. | **Improved:** Uses Riverpod `userProfileProvider` + `activeBusinessProvider` (reusing cached shell state instead of blocking with a full-screen spinner if already hydrated). Gracefully handles `403 BUSINESS_READ_ONLY` on `/business/mine` so user-level settings remain accessible. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  1. Phone `MoreHubScreen` (Tab 4 → *Preferences & Account* → **Settings**).
  2. Tablet `NavigationRail` (*Workspace Section* → **Settings**).
  3. Deep Links: `/dashboard/settings` → `SettingsHomeScreen` (Phone) or `GeneralSettingsScreen` (Tablet detail pane); `/dashboard/settings/<tab>` → pushes or selects matching tab directly.
  4. User Profile tile in Tablet Rail footer → `/settings/general` or `/settings`.
- **Outgoing Routes (All 11 Web Tabs + Account Actions):**
  1. `general` → `/settings/general` (`SET-02` — `GeneralSettingsScreen`)
  2. `business-profile` → `/settings/business-profile` (`SET-03` — `BusinessProfileScreen`)
  3. `signature` → `/settings/signature` (`SET-06` — `SignatureSettingsScreen`)
  4. `subscription` → `/plans` / `/settings/subscription` (`PLN-01` — `PlansAndSubscriptionScreen`)
  5. `users-permissions` → `/settings/users-permissions` (`SET-09` — `SettingsComingSoonScreen`)
  6. `notifications` → `/settings/notifications` (`SET-09` — `SettingsComingSoonScreen`)
  7. `security` → `/settings/security` (`SET-04` — `SecuritySettingsScreen`)
  8. `integrations` → `/settings/integrations` (`SET-09` — `SettingsComingSoonScreen`)
  9. `data-export` → `/settings/data-export` (`SET-07` — `DataExportSettingsScreen`)
  10. `appearance` → `/settings/appearance` (`SET-05` — `AppearanceSettingsScreen`)
  11. `language` → `/settings/language` (`SET-08` — `LanguageSettingsScreen`)
  - **Sign Out CTA** at the bottom of the Settings Hub → confirmation dialog → `POST /api/v1/auth/logout` + full local session clear → `/login`.

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone Layout (`< 600dp`)
1. **Top AppBar:** Standard `SliverAppBar` / `AppBar` with title `"Settings"` (`t("title")`), back arrow to `MoreHubScreen`, and subtle active workspace pill.
2. **User Header Card (`AfabCard`):**
   - `56dp` circular `Avatar` (photo/DiceBear via `cached_network_image`, fallback initials on `primary` 15% tint).
   - Full Name (`firstName + lastName`), Email (`LTR`), Plan Tier badge (`FREE` / `PLUS` / `PRO` pill), and Active Business summary chip (`businessName` + `EDITABLE` / `READ_ONLY` indicator).
   - Quick `"Edit Profile"` icon button or tap action opening `EditProfileSheet` / navigating to General Settings.
3. **Categorized Hub Sections (4 Grouped `AfabCard` Lists):**
   - **Account & Workspace:**
     - General (`Settings` icon) — Business basics, formats, profile, preferences
     - Business Profile (`Building2` icon) — Company info, fiscal ID, address
     - Subscription & Billing (`CreditCard` icon) — Plan tier badge (`FREE`/`PLUS`/`PRO`), Stripe billing
     - Users & Permissions (`Users` icon) — *"Coming Soon"* subtle badge
   - **Security & Preferences:**
     - Security & 2FA (`ShieldCheck` icon) — 2FA status dot (`Enabled`/`Disabled`), password, sessions, biometrics
     - Appearance & Theme (`Palette` icon) — Theme mode, colors, fonts, density
     - Wet Signature Vault (`FileSignature` icon) — *"Device-Local"* subtle chip
     - Language (`Globe` icon) — Current language pill (`English` / `العربية`)
     - Notifications (`Bell` icon) — *"Coming Soon"* subtle badge
   - **Data & Connections:**
     - Data & Export (`Download` icon) — Excel, PDF, CSV reports
     - Integrations (`Webhook` icon) — *"Coming Soon"* subtle badge
4. **Footer Actions:**
   - Full-width soft/danger-outlined **Sign Out** button (`LogOut` icon).
   - App version label (`v1.0.0`).

### Tablet Layout (`>= 600dp` / `>= 840dp` Master-Detail)
- **Left Pane (`260dp` fixed width):** Compact User Header summary + scrollable vertical list of all 11 Settings items with active `3dp` start-edge `primary` indicator bar (matching `settings/layout.tsx:86-88`) and `10% primary` background fill.
- **Right Pane (`Expanded`):** Renders the selected Settings screen inline (`GeneralSettingsScreen` selected by default, mirroring Web's `/settings` → `/settings/general` redirect). Changes in `Appearance` or `Language` update the entire tablet split-view live.

---

## 6. UI Components and Interactive Elements

| Component | Widget / Package | Behavior |
|---|---|---|
| **User Header Card** | `AfabCard` + `CachedNetworkImage` | Displays `UserProfileDTO` (`firstName`, `lastName`, `email`, `avatarUrl`, `planTier`) and `BusinessDTO` (`name`, `currency`, `editable`). Tapping `"Edit"` opens `EditProfileSheet` or navigates to `GeneralSettingsScreen`. |
| **Settings Category Group** | `AfabCard` + `ListTile` / `InkWell` rows | `48dp+` row height, `1px` hairline `border` dividers (`AfabColors.border`), leading `36x36dp` tinted icon tile, title, concise 1-line subtitle, optional status pill (`2FA On`, `PRO`, `Soon`, `EN/AR`), trailing `ChevronRight` (`matchTextDirection: true`). |
| **Read-Only Workspace Banner** | `AfabInsetPanel` (amber warning) | Shown above workspace-scoped rows if `business?.editable == false`, explaining business fields are locked while user settings remain editable. |
| **Sign Out Button** | `AfabButton` (danger-soft) | Opens confirmation modal; executes `AuthRepository.logout()`. |

---

## 7. Data Requirements and API Contracts

| Endpoint | Method | Purpose | Response DTO / Key Fields |
|---|---|---|---|
| `/api/v1/user/me` | `GET` | Hydrate user profile header, `planTier`, `twoFactorEnabled`, and preference defaults | `UserProfileDTO` (`id`, `firstName`, `lastName`, `email`, `phoneNumber`, `avatarUrl`, `emailVerified`, `businessId`, `businessName`, `currency`, `twoFactorEnabled`, `planTier`, `enableAiInsights`, `compactMode`, `autoCategorizeTransactions`, `showTips`) |
| `/api/v1/business/mine` | `GET` | Hydrate active workspace summary & `userRole` / `editable` flags | `BusinessDTO` (`id`, `name`, `currency`, `userRole`, `accessMode`, `editable`, `primary`) |
| `/api/v1/business` | `GET` | Fallback list if `/business/mine` throws `403 BUSINESS_READ_ONLY` | `List<BusinessDTO>` |
| `/api/v1/auth/logout` | `POST` | Revoke refresh token cookie & clear session on Sign Out | `200 ErrorResponse` (with `refreshToken` cookie + `X-CSRF-Token` header) |

---

## 8. State Management and Caching

- **`settingsBootstrapProvider` (`FutureProvider` / `AsyncNotifier`):**
  - Watches `userProfileProvider` and `activeBusinessProvider`.
  - Runs `GET /user/me` and `GET /business/mine` in parallel (`Future.wait` / `AsyncValue`) on cold start or pull-to-refresh.
  - Keyed by `(userId, activeBusinessId)` so switching businesses via `BusinessSwitcherSheet` automatically refreshes `business` metadata while preserving user profile.
- **`selectedSettingsTabProvider` (Tablet state):** Holds active `SettingsTabId` (default `SettingsTabId.general`).
- **Pull-to-Refresh:** `RefreshIndicator` invalidates `userProfileProvider` and `activeBusinessProvider`.

---

## 9. User Actions, Validation, and Error Handling

- **Tap any of the 11 tabs:**
  - Phone: `context.push('/settings/<tab>')` (or `/plans` for `subscription`).
  - Tablet: Updates `selectedSettingsTabProvider` (if dirty changes exist in `General` or `BusinessProfile`, prompts discard confirmation before switching pane).
- **403 `BUSINESS_READ_ONLY` during `/business/mine`:**
  - Do **NOT** block access to `SettingsHomeScreen` or user-scoped settings (`Security`, `Appearance`, `Language`, `Subscription`, `AccountDeletionFlow`). Display an inline `READ_ONLY` workspace badge and allow tapping it to open `BusinessSwitcherSheet` / `BusinessAllocationSheet`.
- **Network / 5xx Failure:**
  - If cached `userProfile` / `activeBusiness` exist in memory, keep hub navigable with a compact top retry banner. If cold-load fails completely, render `AfabErrorState` with a `"Retry"` button.

---

## 10. Permissions, Security, and Tenant Isolation

- **Authenticated Route:** Protected by `GoRouter` auth, email-verification, and onboarding guards.
- **Role & Workspace Scope:**
  - User-scoped tabs (`Security`, `Appearance`, `Language`, `Subscription`, `Account Deletion`) remain usable regardless of `business.userRole` or `business.editable`.
  - Business-scoped tabs (`General` business fields, `Business Profile`, `Data & Export`) enforce `X-Business-Id` via `TenantInterceptor` and respect `OWNER`/`ADMIN` + `editable` guards inside those destination screens.
- **Sign Out Cleanup:** Must call `POST /auth/logout`, clear `SessionTokenHolder` RAM JWT, wipe `PersistCookieJar`, clear `activeBusinessId`, and invalidate all Riverpod providers.

---

## 11. Localization (EN/AR) and RTL Behavior

- Uses `settings.json` keys (`title`, `subtitle`, `tabs.*`, `comingSoon`) migrated into `app_en.arb` and `app_ar.arb`.
- Hub subtitles and status badges (`Device-Local`, `Coming Soon`, `Enabled`/`Disabled`) must be localized in `app_en.arb` and `app_ar.arb` (no hardcoded strings).
- **RTL Mirroring:** Trailing chevrons (`Icons.chevron_right` with `matchTextDirection: true` or `LucideIcons.chevronRight`) flip left in Arabic; `3dp` active indicator bar on Tablet rail uses `AlignmentDirectional.centerStart`.
- User email in header card forces `TextDirection.ltr` inside RTL cards so email addresses never reorder around punctuation.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Responsive:**
  - `< 600dp`: Single-column scrollable list (`CustomScrollView` / `ListView`), `16dp` outer horizontal padding, `48dp+` minimum tap targets.
  - `600–839dp`: Tablet portrait — `240dp` category list + right detail pane (or hub grid if user prefers, defaulting to split view).
  - `>= 840dp`: Tablet landscape — `260dp` Settings rail + fluid right detail pane (`maxWidth: 960dp` centered content).
- **Accessibility:** Every tile has a `Semantics` label combining tab name, subtitle, and status badge (e.g., `"Security, Two-Factor Authentication Enabled"`). Respects `MediaQuery.textScalerOf(context)` without text clipping.
- **States:**
  - **Loading:** Shimmer skeleton matching User Header Card + 3 grouped card blocks.
  - **Error:** Retryable error banner/screen on `GET /user/me` failure.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **All 11 Tabs Reachable:** Verify all 11 Web settings tabs (`general`, `business-profile`, `signature`, `subscription`, `users-permissions`, `notifications`, `security`, `integrations`, `data-export`, `appearance`, `language`) are listed, localized in EN & AR, and navigate to their target screen.
2. **Phone vs Tablet Adaptive Layout:** Widget test at `390x844` renders categorized Hub list; at `1024x768` renders master-detail split view defaulting to `GeneralSettingsScreen`.
3. **Read-Only Resilience:** When `/business/mine` returns `403 BUSINESS_READ_ONLY`, Settings Hub still renders user profile and permits navigating to Security, Appearance, Language, and Subscription.
4. **Sign Out Flow:** Tapping Sign Out -> Confirm calls `POST /auth/logout`, wipes cookies/RAM JWT, and redirects to `/login`.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Package Dependency** | `flutter_riverpod`, `go_router`, `cached_network_image`, `lucide_icons_flutter` | All verified in `06_FLUTTER_ARCHITECTURE.md`. |
| **Upstream Screen Dependencies** | Links directly to `SET-02`..`SET-09` and `PLN-01` (`PlansAndSubscriptionScreen`). | Build `SET-01` alongside `SET-02`/`SET-03`/`SET-08`/`SET-09` in Roadmap task `P6-02`. |
| **Risk: `READ_ONLY` `/business/mine` Failure** | `SettingsProvider` on Web calls `/business/mine`, which throws `403 BUSINESS_READ_ONLY` on locked workspaces. | Catch `BusinessReadOnlyFailure` specifically in `settingsBootstrapProvider` and fall back to `GET /business` metadata so Settings never crashes. |
