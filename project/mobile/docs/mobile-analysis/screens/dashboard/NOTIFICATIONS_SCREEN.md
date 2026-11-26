# DASH-04 — Notifications Screen (`NotificationsScreen`)

> **Spec ID:** `DASH-04`
> **Phase / Task:** Phase 2 (`P2-02`)
> **Verified Web Sources:** `Web/project/frontend/components/dashboard/DashboardHeader.tsx` (lines 57–148, 191–278), `lib/api/notifications.ts`
> **Verified Backend Sources:** `NotificationController.java`, `NotificationService.java`, `NotificationDTO.java`, `NotificationsResponse.java`

---

## 1. Screen Identity

- **Screen Name:** `NotificationsScreen`
- **Route Name & Path:** `AppRoutes.notifications` (`/notifications`, pushed onto root navigator from `ShellAppBar` Bell on phones; optional `400dp` side popover/panel on `>= 840dp` tablets)
- **Feature Module:** `lib/features/notifications/presentation/screens/notifications_screen.dart`
- **Backend Scope:** **User-scoped** persistent notifications (max 30 newest records across the user's account)

---

## 2. Purpose and Functional Parity

Replaces Web's desktop-only bell dropdown (`DashboardHeader.tsx`) with a touch-first, pull-to-refresh notifications center supporting single-item mark-as-read, bulk mark-all-read, severity visual distinction, and safe `actionUrl` deep navigation.

---

## 3. Navigation and Entry/Exit Paths

- **Entry Paths:**
  - Tapping the Notification Bell icon in `ShellAppBar` (`DASH-02`).
- **Exit Paths:**
  - Back button (`AppBar` back arrow / system back) returns to previous shell tab.
  - Tapping a notification item with a non-null `actionUrl`:
    1. Marks notification as read via `PUT /api/v1/notifications/{id}/read` (if `!read`).
    2. Maps `actionUrl` to a valid `GoRouter` route and navigates there (popping `NotificationsScreen` first).
    - Known `actionUrl` targets (verified in `NotificationService.java` & `StripeBillingService`):
      - `/dashboard/settings/subscription*` → `/plans`
      - `/dashboard/invoices*` → `/invoices`
      - `/dashboard/budgets*` → `/budgets`
      - `/dashboard/transactions*` → `/transactions`
      - `/dashboard*` → `/dashboard`
    - Unknown or malformed `actionUrl` → marks read cleanly and stays on `NotificationsScreen` (or falls back to `/dashboard` with warning log, never crashing `GoRouter`).

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

- **Phone (`< 600dp`):**
  - Dedicated full-screen route with `AppBar`:
    - Title: `"Notifications"` + optional unread count pill (`"{unreadCount} unread"`).
    - Trailing Action: `"Mark all read"` text/icon button (`CheckCheck`), visible/enabled only when `unreadCount > 0`.
  - Body: `RefreshIndicator` + `ListView.separated` of up to 30 notification cards (`8dp` vertical gap or hairline `border` divider).
- **Tablet (`>= 600dp`):**
  - Centered constrained feed (`maxWidth: 640dp`) when pushed, OR anchored modal popover/side drawer (`width: 400dp`) from the Bell button on `>= 840dp`.

---

## 5. UI Components and Design System Mapping

| Element | Flutter Widget | Design Tokens |
|---|---|---|
| Screen Header | `AppBar` | `surface` bg, `1px border` bottom, `CheckCheck` trailing action in `primary` |
| Notification Row | `InkWell` + `Container` | Unread: `primary.withValues(alpha: 0.06)` bg + `8dp` `primary` dot; Read: `surface` bg, `0.78` text opacity |
| Severity Icon | `36x36dp` rounded-`10dp` tile | `ERROR` → `AlertCircle` (`#EF4444`), `WARNING` → `AlertTriangle` (`#F59E0B`), `SUCCESS` → `CheckCircle2` (`#10B981`), `INFO` → `Info` (`primary`) |
| Title & Body | `Text` (`titleSmall` Bold / `bodySmall` `textMuted`) | Max 2 lines title, expandable or full body text (`n.message`), optional subtle `"View →"` chip when `actionUrl != null` |
| Timestamp | `Text` (`labelSmall` `textMuted`) | Localized Gregorian date + time (`MMM d, HH:mm` / `intl` `ar` equivalent, Western digits `0-9`) |
| Empty State | `AfabEmptyState` | `BellOff` / `Bell` icon tile, `"No notifications yet"` |

---

## 6. Data Models and State Management

### 6.1 Models (`freezed`)
- `NotificationItem` (`NotificationDTO.java`):
  - `String id` (UUID)
  - `String type` (e.g., `"BILLING_PAYMENT_FAILED"`, `"SUBSCRIPTION_RENEWED"`, etc.)
  - `NotificationSeverity severity` (`INFO`, `SUCCESS`, `WARNING`, `ERROR` — default `INFO`)
  - `String title`
  - `String message`
  - `String? actionUrl`
  - `bool read`
  - `DateTime? readAt`
  - `DateTime createdAt`
- `NotificationsState` (`NotificationsResponse.java`):
  - `int unreadCount`
  - `List<NotificationItem> notifications`

### 6.2 Riverpod Providers (`lib/features/notifications/presentation/providers/`)
- `notificationsProvider`: `AsyncNotifierProvider<NotificationsNotifier, NotificationsState>`
  - Watches `sessionStatusProvider` (invalidated on logout/login). Does **not** clear on business switch because backend notifications are **user-scoped** (`NotificationRepository.findTop30ByUserIdOrderByCreatedAtDesc`), though refreshing on focus is safe.
  - Methods: `refresh()`, `markAsRead(String id)`, `markAllAsRead()`.
- `unreadNotificationCountProvider`: `Provider<int>` derived from `notificationsProvider.valueOrNull?.unreadCount ?? 0`, consumed by `ShellAppBar` Bell badge (`"9+"` if `> 9`).

---

## 7. API Contracts and Data Flow

1. **`GET /api/v1/notifications`**
   - Auth: `Authorization: Bearer <jwt>`.
   - Response: `200 NotificationsResponse { unreadCount: long, notifications: NotificationDTO[<=30] }`.
   - Note: `NotificationService.getNotifications()` returns top 30 ordered by `createdAt DESC`, plus full DB `unreadCount` (`countByUserIdAndReadAtIsNull`).
2. **`PUT /api/v1/notifications/{id}/read`**
   - Auth: `Authorization: Bearer <jwt>`.
   - Response: `200 NotificationsResponse` (returns updated `unreadCount` and `notifications` list).
   - Error: `404` if notification belongs to another user or does not exist.
3. **`PUT /api/v1/notifications/read-all`**
   - Auth: `Authorization: Bearer <jwt>`.
   - Response: `200 NotificationsResponse` (`unreadCount == 0`, all `read == true`).

---

## 8. User Interactions and Event Handling

- **Open Screen:** Triggers `notificationsProvider.refresh()` in background while immediately displaying previously cached items if available.
- **Tap Notification Item:**
  - Optimistically marks item `read = true` and decrements `unreadCount` locally if `!item.read`, then calls `PUT /api/v1/notifications/{id}/read` and replaces state with authoritative server `NotificationsResponse`.
  - If `item.actionUrl` is non-empty, resolves route via `ActionUrlRouter.resolve(item.actionUrl)` and navigates.
- **Tap `"Mark all read"`:** Disables button briefly with inline spinner, calls `PUT /api/v1/notifications/read-all`, updates state with returned `NotificationsResponse`.
- **Pull-to-Refresh:** Calls `GET /api/v1/notifications` and updates list + badge.

---

## 9. Validation, Error, Loading, and Empty States

- **Initial Loading:** `ListView` of 6 `Shimmer` notification row skeletons (`APP-01`).
- **Empty State:** `AfabEmptyState` with `Bell` icon, `"No notifications yet"` / `"لا توجد إشعارات حالياً"`.
- **Error State (initial fetch fails):** `AfabEmptyState` error variant with `"Retry"` button.
- **Mutation Failure (`markAsRead` / `markAllAsRead`):** Rolls back optimistic read state on failure and displays non-blocking `AfabToast` error (fixing Web's silent `catch {}` swallow in `DashboardHeader.tsx:117,127`).

---

## 10. Localization (EN/AR) and RTL Behavior

- Extracts inline `isAr` strings from `DashboardHeader.tsx:215-269` into ARB keys:
  - `notificationsTitle` (`"Notifications"` / `"الإشعارات"`)
  - `notificationsMarkAllRead` (`"Mark all read"` / `"تحديد الكل كمقروء"`)
  - `notificationsEmptyTitle` (`"No notifications yet"` / `"لا توجد إشعارات حالياً"`)
  - `notificationsEmptySubtitle` (`"Billing alerts and important workspace updates will appear here."` / `"ستظهر هنا تنبيهات الفوترة وتحديثات مساحة العمل المهمة."`)
- **Backend Content Language Caveat:** Note in UI/docs that notification `title` and `message` strings stored in PostgreSQL by `NotificationService` (e.g., Stripe webhook events) are generated server-side in English; mobile renders them cleanly with automatic LTR/RTL paragraph alignment while wrapping numbers/dates in Western digits `0-9`.

---

## 11. Accessibility and Responsive Guardrails

- Minimum `64dp` row height, `48x48dp` `"Mark all read"` tap target.
- Unread state is communicated via **both** color tint, bold title weight, `8dp` dot, AND `Semantics(label: "Unread notification: ...")` (never color alone).
- Long notification messages wrap cleanly without `RenderFlex` overflow (`Expanded` around text column).

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **Silent Error Swallowing Fixed (`DashboardHeader.tsx:117-129`):** Web silently ignores `markAsRead` / `markAllAsRead` errors. Mobile rolls back optimistic UI and surfaces a toast.
2. **Dead Click-Outside / Cramped Dropdown Replaced:** Web renders an `80`–`96` width absolute `div` that clips on small phones. Mobile provides a full dedicated screen on phones with pull-to-refresh and keyboard/safe-area safety.
3. **Missing `actionUrl` Safety:** Mobile introduces an explicit `ActionUrlMapper` converting Web paths (`/dashboard/settings/subscription`, etc.) into valid `GoRouter` locations instead of assuming Web Next.js routes exist verbatim.
4. **Honest Scope (No Invented Push/Settings APIs):** Because `/dashboard/settings/notifications` is a Web `"Coming Soon"` page and backend has no FCM/APNs device-token registration endpoint, mobile relies on in-app fetch (`GET /notifications`) on shell boot, app resume, and post-billing events rather than fabricating push notification infrastructure.

---

## 13. Testing and Verification Plan

- **Unit Tests (`test/unit/notifications/`):**
  - `ActionUrlMapper` maps `/dashboard/settings/subscription?x=1` → `/plans`, `/dashboard/invoices` → `/invoices`, unknown paths → `null` safely.
  - `NotificationsNotifier` decrements `unreadCount` optimistically and reconciles with `NotificationsResponse`.
- **Widget Tests (`test/widget/notifications/notifications_screen_test.dart`):**
  - Renders `ERROR`, `WARNING`, `SUCCESS`, `INFO` severity icons and unread indicators.
  - Tapping `"Mark all read"` calls `PUT /notifications/read-all` and hides button when `unreadCount == 0`.
  - Tapping item with `actionUrl` calls `PUT /notifications/{id}/read` and navigates to `/plans`.
  - Empty state & error retry state verified in `en` and `ar`.

---

## 14. Dependencies and Risks

- **Package Dependencies:** `flutter_riverpod`, `go_router`, `intl`, `shimmer`, `lucide_icons_flutter`.
- **Technical Risks:**
  - **Producers Limited to Billing Today:** `NotificationService.notifyUser` is currently invoked primarily by `StripeBillingService` (payment failed, renewal, downgrade). When additional domain producers are added on the backend in the future, `ActionUrlMapper` should be extended for any new `actionUrl` patterns.
  - **30-Item Cap:** Backend returns `findTop30ByUserIdOrderByCreatedAtDesc` without pagination; `NotificationsScreen` displays `"Showing latest 30 notifications"` footer note if `notifications.length == 30`.
