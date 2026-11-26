# SET-10 — Account Deletion Flow (`AccountDeletionFlow`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-10` |
| **Screen Name** | Account Deletion Preflight & Confirmation Flow (`AccountDeletionFlow`) |
| **Route Path** | `/settings/delete-account` (full-screen modal flow pushed from `SET-02`) |
| **Feature Module** | `lib/features/settings/presentation/account_deletion_flow.dart` |
| **Web Equivalent** | `Web/project/frontend/components/settings/DeleteAccountModal.tsx` + `UserAccountService.java` |
| **Priority** | P1 (Critical Account Lifecycle, Data Export & Tombstone Integrity) |

---

## 2. Purpose and User Goal

Guide users safely through AFAB's GitHub-style **3-step permanent account deletion workflow**: (1) optionally export a complete GDPR-style JSON backup of their account data, (2) review accurate English & Arabic consequences explaining tombstone anonymization and ledger preservation, and (3) resolve any blocking active owned businesses (via Archive or Ownership Transfer) before confirming with `"delete <email>"` to deactivate and anonymize the account.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `DeleteAccountModal.tsx` (3-Step Flow) | Step 1: JSON export (`GET /user/me/export`); Step 2: consequences; Step 3: `GET /user/me/deletion-preflight` blocking businesses + Archive Business (`DELETE /business/{id}`) + `"delete <email>"` confirmation (`DELETE /user/me`). | **Implemented but Incomplete → Upgraded on Mobile:** Preserves the exact 3-step structure and identity summary card while fixing 3 confirmed Web/UX gaps below. |
| `DeleteAccountModal.tsx:372-377` (Arabic Step 2 Copy Bug) | **Confirmed Bug:** Arabic text falsely states all businesses, workspaces, and financial transactions will be permanently deleted, contradicting `UserAccountService.java:278-285` and the English text! | **Bug-Fixed:** Rewrites Arabic Step 2 copy to match English & backend reality: user account is deactivated and anonymized (tombstone record), sessions & memberships are revoked, while business financial ledgers & audit trails are preserved safely. |
| `DeleteAccountModal.tsx:416-433` (Missing Ownership Transfer UI) | Preflight DTO returns `hasOtherActiveMembers` (`UserAccountService.java:397`), and backend provides `GET /business/{id}/members` + `POST /business/{id}/transfer-ownership`, yet Web only offers `"Archive Business"`. | **Upgraded on Mobile:** When `hasOtherActiveMembers == true`, offers **both** `"Transfer Ownership"` (member picker sheet → `POST /transfer-ownership`) **and** `"Archive Business"` (`DELETE /business/{id}`). |
| `UserAccountService.java` vs `BusinessController.java` (`READ_ONLY` Deadlock) | **Confirmed Backend Deadlock:** Owned `READ_ONLY` businesses block deletion (`409 Conflict`), yet `DELETE /business/{id}` AND `GET /business/{id}/members` reject `READ_ONLY` businesses with `403 BUSINESS_READ_ONLY`! | **Mitigated Honestly:** Cross-checks `blockingBusinesses` against `GET /business` (`editable == false`); flags `READ_ONLY` blockers immediately with an explicit warning and deep links to `BusinessAllocationSheet` / `PlansAndSubscriptionScreen` (to reallocate/upgrade) or Support. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `GeneralSettingsScreen` (`SET-02`) → `"Delete Account"` danger row.
- **Exit / Completion Paths:**
  - User cancels / taps Close (`X`) before final deletion (blocked while `isDeleting == true`).
  - From Step 3 `READ_ONLY` deadlock banner → `"Manage Workspace Allocation"` (`BusinessAllocationSheet`) or `"View Plans"` (`PlansAndSubscriptionScreen`).
  - On `DELETE /api/v1/user/me` (`200 OK`) → immediate full local sign-out → `/login` with `"Your account has been deactivated and anonymized"` banner.

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

Presented as a **full-screen modal route** on Phones (`< 600dp`) and a **centered `maxWidth: 520dp` modal dialog** on Tablets (`>= 600dp`).

1. **Top Header Bar:**
   - Back arrow (Steps 2 & 3), Title `"Delete <Full Name>"`, Step counter `"1/3"`, `"2/3"`, `"3/3"`, and Close (`X`) button (disabled while `isDeleting`).
2. **Target Identity Summary Card (`AfabInsetPanel`):**
   - `56dp` circular Avatar + red `ShieldAlert` corner badge.
   - `fullName`, `email` (`LTR` monospace), active `businessName`, and `planTier` pill (`FREE`/`PLUS`/`PRO`).
3. **Step 1 — Export Data Before Deletion:**
   - Card explaining JSON backup contents (`profile`, `businesses`, `categories`, `transactions`, `activeSessions`).
   - Primary-soft button: `"Export My Data First (.json)"` → calls `GET /user/me/export` → saves `afab-account-export-YYYY-MM-DD.json` → opens `share_plus` + displays emerald summary card (`filename`, `businessesCount`, `transactionsCount`, `"Share / Save again"`).
   - Bottom CTA: `"Continue to delete this account"` (if exported) or `"Skip Export — I want to delete this account"`.
4. **Step 2 — Consequences & Tombstone Disclosure:**
   - Amber alert banner: `"Unexpected bad things will happen if you don't read this!"` (localized).
   - Vertical timeline rule + bullet disclosing:
     - User account (`fullName`, `email`) is deactivated & anonymized (tombstone record); all active sessions & team memberships are revoked; active Stripe subscription is canceled best-effort.
     - **Existing business financial ledgers and audit trails are preserved safely**; owned active businesses must be transferred or archived first.
     - Red emphasis line: `"This action is permanent and cannot be undone."`
   - Bottom CTA: `"I have read and understand these effects"`.
5. **Step 3 — Preflight Resolution & Typed Confirmation:**
   - **Preflight Blocking Businesses Card (shown when `preflight != null && !preflight.canDelete`):**
     - Displays `preflight.guidance` and each `BlockingBusinessDTO` (`businessName`, `activeMemberCount` badge):
       - **If `editable == false` (`READ_ONLY` Deadlock):** Shows red/amber deadlock badge: *"This workspace is currently Read-Only after a plan downgrade and cannot be archived or transferred while locked. Reallocate an active slot or upgrade your plan first."* + `"Manage Allocations"` button.
       - **If `editable == true`:**
         - `"Archive Business"` button (`DELETE /business/{id}` with confirm dialog).
         - If `hasOtherActiveMembers == true`: `"Transfer Ownership"` button → opens `OwnershipTransferSheet` (`GET /business/{id}/members` → select active member → `POST /business/{id}/transfer-ownership`).
   - **Typed Confirmation Input:**
     - Prompt: `To confirm, type "delete <email>" in the box below` (`"delete <email>"` selectable monospace).
     - `TextField` forced `TextDirection.ltr`, `autocorrect: false`, `enableSuggestions: false`, border turns emerald on case-insensitive match (`confirmInput.trim().toLowerCase() == "delete $email".toLowerCase()`), else red.
   - **Destructive Submit CTA:**
     - `"Delete this account"` (`bg: AfabColors.danger`), enabled **ONLY** when `isPhraseMatch && preflight?.canDelete == true && !isDeleting`.

---

## 6. UI Components and Interactive Elements

| Component | Details |
|---|---|
| `AccountIdentityHeader` | Avatar + red `ShieldAlert` badge + `fullName` + `email` (`LTR`) + workspace & plan pills. |
| `BlockingBusinessCard` | `AfabInsetPanel` showing business name, member count, `"Transfer Ownership"` action (when `hasOtherActiveMembers && editable`), `"Archive"` action (when `editable`), or `READ_ONLY` deadlock guidance. |
| `OwnershipTransferSheet` | Modal bottom sheet fetching `GET /business/{id}/members`, filtering out `currentUser.id`, requiring explicit confirmation (`"You will become an ADMIN and lose OWNER privileges for <businessName>"`) before calling `POST /business/{id}/transfer-ownership`. |
| `ConfirmationPhraseField` | `TextDirection.ltr` monospace input matching `"delete <email>"` case-insensitively (`UserAccountService.java:294`). |

---

## 7. Data Requirements and API Contracts

| Endpoint | Method | Purpose / Request | Response / Errors |
|---|---|---|---|
| `/api/v1/user/me/deletion-preflight` | `GET` | Fetched on flow open & after each archive/transfer | `200 AccountDeletionPreflightDTO { canDelete, blockingBusinesses[{ businessId, businessName, activeMemberCount, hasOtherActiveMembers }], guidance }` |
| `/api/v1/business` | `GET` | Cross-reference `blockingBusinesses[].businessId` to detect `editable == false` (`READ_ONLY` deadlock) | `200 List<BusinessDTO>` |
| `/api/v1/user/me/export` | `GET` | Step 1 JSON backup | `200` attachment `afab-account-export-YYYY-MM-DD.json` |
| `/api/v1/business/{id}/members` | `GET` | Populate Ownership Transfer member list (requires `EDITABLE`) | `200 List<BusinessMemberDTO>` (`403 BUSINESS_READ_ONLY` if locked) |
| `/api/v1/business/{id}/transfer-ownership` | `POST` | `{ targetUserId: UUID }` (`OWNER` only; note no `assertEditable` on backend, though `/members` requires `EDITABLE`) | `200 BusinessDTO` (`403`, `404`, `409`) |
| `/api/v1/business/{id}` | `DELETE` | Soft-archive blocking business (`OWNER` + `EDITABLE`) | `204 No Content` (`403 BUSINESS_READ_ONLY` if locked) |
| `/api/v1/user/me` | `DELETE` | `{ confirmation: "delete <email>" }` | `200 ErrorResponse` + clears `refreshToken` & `afab_csrf` cookies (`400 DELETE_CONFIRMATION_INVALID`, `409 ConflictException` if blocking biz) |

---

## 8. State Management and Caching

- **`accountDeletionControllerProvider` (`AutoDisposeAsyncNotifier`):**
  - Holds `step (1|2|3)`, `preflight`, `businessEditabilityMap (Map<UUID, bool>)`, `exportResult`, `resolvingBusinessId`, `confirmInput`, `isDeleting`, `error`.
- **Cache Invalidation:**
  - Archiving or transferring ownership refreshes `preflight`, `businessListProvider`, and `activeBusinessProvider` (if the archived business was active, `BusinessController` clears `user.activeBusinessId`, so mobile switches to next available editable workspace or clears `activeBusinessId`).
  - Successful `DELETE /user/me` runs **complete local wipe**: clears `SessionTokenHolder`, wipes `PersistCookieJar`, deletes biometric lock flag in `flutter_secure_storage`, clears `SharedPreferences` workspace IDs, invalidates all Riverpod providers, and routes to `/login`.

---

## 9. User Actions, Validation, and Error Handling

- **Preflight Fetch Failure on Open:** If `GET /user/me/deletion-preflight` fails offline/5xx, disable final Delete button on Step 3 and show `"Unable to verify blocking businesses"` + `"Retry"` button (never allow blind submission without preflight status, fixing Web's `preflight !== null` gap where `preflight == null` allowed submitting and hitting `409`!).
- **409 Conflict (`DELETE /user/me`):** Re-fetches `GET /user/me/deletion-preflight` automatically so newly discovered blocking businesses appear immediately.
- **403 `BUSINESS_READ_ONLY` on Archive:** Catches `BusinessReadOnlyFailure` and renders the `READ_ONLY` deadlock recovery guidance cleanly without losing Step 3 state.
- **400 `DELETE_CONFIRMATION_INVALID`:** Displays exact backend validation message inline below the phrase field.

---

## 10. Permissions, Security, and Tenant Isolation

- **Tombstone & Ledger Integrity (`UserAccountService.java:278-364`):**
  - User row becomes `status = "DELETED"`, `deletedAt = now`, `firstName = "Deleted"`, `lastName = "User"`, `email = "deleted-<uuid>@deleted.afab.local"`, clears phone/avatar/2FA/password hash, revokes all `RefreshToken`s and verification/reset tokens, sets `BusinessMember.status = "REMOVED"`, cancels Stripe sub best-effort, and preserves financial ledgers & audit logs.
- **Irreversible Guard:** `confirmation` must match `"delete <email>"`; back button and close button are locked while `DELETE /user/me` is in-flight.

---

## 11. Localization (EN/AR) and RTL Behavior

- **Critical Arabic Copy Fix:** Fixes `DeleteAccountModal.tsx:372-377` in `app_ar.arb` so Step 2 explicitly states:
  - *سيؤدي هذا إلى تعطيل حساب `<fullName>` (`<email>`) وإخفاء بياناته الشخصية وإلغاء جميع الجلسات النشطة. يتم الاحتفاظ بسجلات الشركات المالية وسجلات التدقيق بأمان — يجب نقل ملكية الشركات النشطة التي تملكها أو أرشفتها أولاً.*
- **LTR Isolation:** Email, `"delete <email>"` target phrase, and confirmation `TextField` force `TextDirection.ltr` so `"delete user@example.com"` never scrambles BiDi order in Arabic.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Keyboard Insets:** Step 3 wraps content in `SingleChildScrollView` + `viewInsetsOf(context).bottom` padding so the typed confirmation box and `"Delete this account"` button remain visible above the keyboard on `320dp` phones.
- **Accessibility:** Step indicator announces `"Step 3 of 3"`; destructive button explicitly includes `Semantics` hint `"Permanent action, cannot be undone"`.
- **States:** Preflight loading spinner on Step 3 header; per-business spinner during Archive/Transfer; inline error banners for export, transfer, archive, and deletion failures.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Step 1 Export & Share:** Tapping `"Export My Data First (.json)"` downloads JSON from `/user/me/export`, shows workspace/transaction counts, and triggers `share_plus`.
2. **Step 2 Accurate EN & AR Disclosure:** Both English and Arabic Step 2 views accurately state account anonymization & ledger preservation (no false claim of ledger deletion).
3. **Blocking Business — Archive & Transfer Ownership:** When `preflight.canDelete == false`, user can either archive an `EDITABLE` solo business (`DELETE /business/{id}`) or transfer ownership (`GET /members` + `POST /transfer-ownership`) when `hasOtherActiveMembers == true`, refreshing `canDelete` to `true`.
4. **`READ_ONLY` Deadlock Detection:** When a blocking business has `editable == false`, Step 3 warns about the `READ_ONLY` deadlock and offers direct navigation to `BusinessAllocationSheet` / `Plans`.
5. **Phrase Match & Full Local Wipe:** `"delete <email>"` enables final CTA; `DELETE /user/me` `200 OK` wipes RAM JWT, `CookieJar`, biometric lock, and routes to `/login`.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Packages** | `share_plus`, `path_provider`, `flutter_secure_storage`, `flutter_riverpod`, `go_router` | Verified in `06_FLUTTER_ARCHITECTURE.md`. |
| **Critical Backend Deadlock (`READ_ONLY` Business)** | Owned `READ_ONLY` businesses block `DELETE /user/me` (`409`), yet `DELETE /business/{id}` & `GET /business/{id}/members` block `READ_ONLY` businesses (`403 BUSINESS_READ_ONLY`). | Detect via `GET /business` (`editable == false`) in Step 3, warn clearly, guide to `BusinessAllocationSheet` / `Plans`, and propose backend patch (`04_AUTHENTICATION_AND_SECURITY.md` §4.4). |
| **Risk: Preflight Unavailable Offline** | Web allows submitting Step 3 when `preflight == null`. | Mobile requires a valid `preflight` response (`preflight != null && preflight.canDelete`) before enabling final deletion. |
