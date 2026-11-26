# SET-09 — Settings Coming Soon Screen (`SettingsComingSoonScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-09` |
| **Screen Name** | Settings Coming Soon (`SettingsComingSoonScreen`) |
| **Route Path** | `/settings/users-permissions`, `/settings/notifications`, `/settings/integrations` |
| **Feature Module** | `lib/features/settings/presentation/settings_coming_soon_screen.dart` |
| **Web Equivalent** | `Web/project/frontend/app/[locale]/(dashboard)/dashboard/settings/[...slug]/page.tsx` |
| **Priority** | P3 (Honest Feature Parity Placeholder) |

---

## 2. Purpose and User Goal

Provide an honest, transparent Coming Soon screen for the **3 Settings tabs** that have no write/configuration APIs implemented in the AFAB backend (`Users & Permissions`, `Notifications Preferences`, and `Integrations & Webhooks`), while optionally surfacing a strictly read-only workspace member list (`GET /api/v1/business/{id}/members`) inside `Users & Permissions` without inventing any unimplemented APIs.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `settings/[...slug]/page.tsx` | Catch-all route matching `users-permissions`, `notifications`, `integrations`, and `language`. Renders centered `.afab-card` with tab icon, tab label, `"Coming Soon"` heading, and `"This section is coming soon."` subtitle. | **Adapted (`Coming Soon` — 3 Tabs):** `language` is promoted to `SET-08` (`LanguageSettingsScreen`). The remaining 3 tabs (`users-permissions`, `notifications`, `integrations`) render `SettingsComingSoonScreen`. For `users-permissions`, optionally displays read-only `GET /business/{id}/members` alongside the Coming Soon notice for team invites & RBAC. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `SettingsHomeScreen` (`SET-01`) → tap **Users & Permissions**, **Notifications**, or **Integrations** (all clearly badged `"Coming Soon"` in the hub so users are never surprised).
  - Tablet Settings rail → selecting any of the 3 tabs loads `SettingsComingSoonScreen` in the right detail pane.
  - Deep links: `/dashboard/settings/users-permissions`, `/dashboard/settings/notifications`, `/dashboard/settings/integrations`.
- **Outgoing Navigation:**
  - `"Back to Settings"` button (pops to `SettingsHomeScreen` on Phone; switches to `General` on Tablet).
  - On `notifications` tab: helpful cross-link button `"View In-App Notifications"` → navigates to `NotificationsScreen` (`GET /api/v1/notifications` feed).

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Standard Coming Soon Layout (`notifications`, `integrations`, and fallback)
1. **Top AppBar:** Localized tab title (`Users & Permissions`, `Notifications`, `Integrations`).
2. **Centered Hero Card (`AfabCard`, `maxWidth: 520dp`):**
   - `56x56dp` rounded icon container (`primary` 10% fill, `primary` icon: `Users`, `Bell`, or `Webhook`).
   - Tab Title (`t("tabs.<tab>")`).
   - `"Coming Soon"` `AfabStatusBadge` (neutral/primary pill).
   - Concise honest description of what is not yet available in this release (e.g., team invitations & role management / push & email alert rules / bank feeds & webhooks) — **zero fake toggles, zero mock API keys, zero fake webhook URLs**.
   - `"Back to Settings"` secondary button (and `"Open Notifications Center"` shortcut on the `notifications` tab).

### `users-permissions` Tab Variant (Read-Only Members Preview + Coming Soon)
1. **Coming Soon Banner (`AfabCard`):** Explains team member invitations, role editing, and member removal are coming soon (`0` invite/role-update APIs exist on backend).
2. **Read-Only Current Workspace Members Card (`AfabCard`, when `business.editable == true`):**
   - Fetches `GET /api/v1/business/{id}/members`.
   - Lists each active `BusinessMemberDTO`: full name (`firstName + lastName`), `email` (`LTR`), role badge (`OWNER` / `ADMIN` / `MEMBER`), `status`, and `joinedAt`.
   - If `business.editable == false` (returns `403 BUSINESS_READ_ONLY`), displays a concise read-only workspace notice instead of throwing an uncaught error.

---

## 6. UI Components and Interactive Elements

| Component | Details |
|---|---|
| `ComingSoonHeroCard` | `AfabCard` matching Web `[...slug]/page.tsx:36-46` with icon tile, title, `"Coming Soon"` badge, localized description, and back button. |
| `ReadOnlyMembersList` | Shown only on `users-permissions` tab when `editable == true`. Renders `BusinessMemberDTO` tiles with role `AfabStatusBadge` (`OWNER`, `ADMIN`, `MEMBER`). Zero edit/invite/remove buttons (except ownership transfer lives in `AccountDeletionFlow` `SET-10`). |

---

## 7. Data Requirements and API Contracts

- **For `notifications` & `integrations`:** **Zero API calls** (no invented endpoints).
- **For `users-permissions` (Optional Read-Only Enhancement):**
  - **`GET /api/v1/business/{id}/members`** (`BusinessController.listMembers`):
    - Guards: Active member + `BusinessAccessGuard.assertEditable(business)` (throws `403 BUSINESS_READ_ONLY` when `editable == false`).
    - Response: `200 List<BusinessMemberDTO>` (`memberId`, `userId`, `firstName`, `lastName`, `email`, `role`, `status`, `joinedAt`).
- **Strict Negative Contract:** Do **NOT** invent or call any `POST /members/invite`, `PATCH /members/{id}/role`, `PUT /notifications/preferences`, or `POST /integrations/webhooks` endpoints.

---

## 8. State Management and Caching

- **`comingSoonTab` Route Parameter:** Enum `ComingSoonSettingsTab { usersPermissions, notifications, integrations }`.
- **`businessMembersProvider(businessId)` (`AutoDisposeFutureProvider.family`):**
  - Only invoked when `tab == usersPermissions` AND `activeBusiness.editable == true`.
  - Invalidated automatically on workspace switch or ownership transfer.

---

## 9. User Actions, Validation, and Error Handling

- **`403 BUSINESS_READ_ONLY` on `/business/{id}/members`:** Caught cleanly and displayed as an inline `"Workspace is in Read-Only mode"` note inside `users-permissions` without breaking the Coming Soon screen.
- **Network Error on `/members`:** Shows compact inline `"Could not load workspace members"` + `"Retry"` button while keeping the Coming Soon card visible.

---

## 10. Permissions, Security, and Tenant Isolation

- **Tenant Scoping:** `GET /business/{id}/members` passes `X-Business-Id` and targets `activeBusiness.id`. Never caches members across business switches.
- **Zero Fake Controls:** Strictly avoids Web-style mock cards (no fake Slack/QuickBooks toggle cards, no fake notification switches like `SecuritySettings` had).

---

## 11. Localization (EN/AR) and RTL Behavior

- Uses `settings.tabs.{usersPermissions,notifications,integrations}`, `settings.comingSoon`, and `settings.comingSoonDesc` from `app_en.arb` and `app_ar.arb`, plus localized honest copy for each of the 3 tabs.
- Member `email` addresses in `ReadOnlyMembersList` force `TextDirection.ltr`.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Responsive:** Centered card (`maxWidth: 520dp`) with generous whitespace; adapts cleanly from `320dp` small phones to `1280dp` tablets.
- **States:** Loading shimmer for `ReadOnlyMembersList` on `users-permissions`; empty state `"Only you are in this workspace"` if `members.length <= 1`.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Honest Coming Soon Rendering:** All 3 routes (`users-permissions`, `notifications`, `integrations`) render matching icon, title, `"Coming Soon"` badge, and zero fake forms/toggles.
2. **No Invented APIs:** Network tests confirm zero unverified endpoints are called on `notifications` or `integrations`.
3. **Read-Only Members Preview:** On `users-permissions`, `GET /business/{id}/members` renders `OWNER`/`ADMIN`/`MEMBER` badges accurately on `EDITABLE` workspaces and degrades gracefully on `READ_ONLY` workspaces.
4. **Language Excluded:** Navigating to `/settings/language` routes to `SET-08` (`LanguageSettingsScreen`), NOT `SettingsComingSoonScreen`.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Backend Gap** | No invite/RBAC mutation, notification-rule, or webhook integration endpoints exist. | Clearly mark `"Coming Soon"` in `SettingsHomeScreen` (`SET-01`) and `SET-09` to manage user expectations honestly. |
| **Risk: `READ_ONLY` `GET /members` `403`** | Backend `BusinessController.listMembers` enforces `BusinessAccessGuard.assertEditable()`. | Gate call on `business.editable == true` and catch `BusinessReadOnlyFailure` cleanly. |
