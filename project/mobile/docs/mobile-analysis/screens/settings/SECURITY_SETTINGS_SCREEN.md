# SET-04 — Security Settings Screen (`SecuritySettingsScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-04` |
| **Screen Name** | Security & 2FA Settings (`SecuritySettingsScreen`) |
| **Route Path** | `/settings/security` |
| **Feature Module** | `lib/features/settings/presentation/security_settings_screen.dart` |
| **Web Equivalent** | `settings/security/page.tsx` + `SecuritySettings.tsx` |
| **Priority** | P1 (Authentication, 2FA & Session Control) |

---

## 2. Purpose and User Goal

Provide users with full control over their account security: changing their password (with safe forced re-login), enabling/managing/disabling TOTP Two-Factor Authentication and emergency backup codes, inspecting and revoking active refresh-token sessions across devices, and configuring native device-local Biometric App Lock.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `SecuritySettings.tsx` (Overview & Tips Cards) | Renders security score summary (2FA, password, fake Login Alerts, session count) and 4 security tips. | **Improved:** Keeps 2FA, Password, and Active Sessions count + 4 Security Tips; **removes fake Login Alerts item**. |
| `SecuritySettings.tsx:74-99` (Change Password) | Calls `POST /auth/change-password`. **Bug:** Backend revokes all sessions & clears cookies, yet Web stays on page with stale JWT in RAM. | **Bug-Fixed:** On `200 OK`, immediately runs full local sign-out (`SessionTokenHolder.clear()`, `cookieJar.deleteAll()`, reset Riverpod caches) and navigates to `/login` with a confirmation toast. |
| `SecuritySettings.tsx:101-192, 558-840` (2FA Setup / Manage / Disable) | 3-step Setup (`GET /user/2fa/setup` → QR + secret → 6-digit TOTP `POST /user/2fa/enable` → 8 backup codes + copy/download `.txt`) + Manage modal (`POST /user/2fa/backup-codes`, `POST /user/2fa/disable` via password). | **Implemented and Connected:** Native `qr_flutter_plus` QR display, 6-box OTP entry, `share_plus` `.txt` export for backup codes, and bottom sheets for Setup & Manage/Disable. |
| `SecuritySettings.tsx:194-212, 408-493` (Active Sessions) | Fetches `GET /user/me/sessions`, renders table with `currentSession` badge, single revoke (`DELETE /user/me/sessions/{id}`), and "Log Out All Other Sessions" (`DELETE /user/me/sessions`). **Backend Caveat:** `refreshToken` cookie has `Path=/api/v1/auth`, so `currentSession` is always `false` and `DELETE /sessions` revokes ALL sessions including current! | **Mitigated Honestly:** Converts table to touch cards on phone (`< 600dp`); warns user before `"Log Out All Sessions"` that **this device will also be signed out**, then clears local session on `200 OK`. Documents `sid` JWT claim backend proposal. |
| `SecuritySettings.tsx:391-403, 543-555` (Login Alerts & Contact Support) | **UI Only:** `<Switch defaultChecked />` with no handler and dead `<Button>Contact Support</Button>`. | **Omitted on Mobile:** Both dead UI-only controls are excluded. |
| *(Mobile-Native Enhancement)* | Not present on Web. | **Added:** **Biometric App Lock** (`local_auth ^3.0.0`) toggle stored in `flutter_secure_storage`, gating app resume/cold-start locally. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `SettingsHomeScreen` (`SET-01`) → **Security**.
  - Tablet Settings rail → **Security**.
  - Deep link `/dashboard/settings/security`.
- **Child Modals / Sheets:**
  - `ChangePasswordSheet`
  - `TwoFactorSetupSheet` (3-step wizard)
  - `TwoFactorManageSheet` (Regenerate backup codes + Disable 2FA)
  - `RevokeAllSessionsConfirmDialog`
- **Post-Action Redirects:**
  - Successful `Change Password` or `Log Out All Sessions` → `/login`.

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone Layout (`< 600dp`)
1. **Top AppBar:** Title `"Security"`.
2. **Security Overview Card (`AfabCard`):**
   - Emerald/amber shield badge + summary title (`"Your account is secure"` or `"Action recommended: Enable 2FA"` when 2FA is off).
   - 3 status pills (`AfabInsetPanel`):
     - Two-Factor Authentication: `Enabled` (green dot) / `Disabled` (amber dot)
     - Password: `Strong` / `Last changed: <date>`
     - Active Sessions: `<N> Active Sessions`
3. **Authentication & Device Security Card (`AfabCard` with hairline dividers):**
   - **Password row:** `Key` tile, last changed date (`profile.passwordChangedAt`), `"Change Password"` button.
   - **Two-Factor Authentication row:** `Lock` tile, `Enabled`/`Disabled` badge, `"Enable 2FA"` primary button or `"Manage 2FA"` secondary button.
   - **Biometric App Lock row (Native):** `Fingerprint` / `ScanFace` tile, `"Require Face ID / Fingerprint to open AFAB"` subtitle, `Switch` toggle (disabled with note if device hardware unsupported/not enrolled).
4. **Active Sessions Card (`AfabCard`):**
   - Header: `"Active Sessions"` + `"Log Out All Sessions"` danger-text button (labeled accurately due to cookie-path caveat).
   - Info banner (`AfabInsetPanel`): Subtle note explaining session identification caveat if backend does not mark `currentSession = true`.
   - Touch-friendly list of session cards (`deviceInfo` icon + name, `ipAddress` in `LTR`, `createdAt` & `expiresAt` formatted date, status badge, trailing `"Log Out"` icon button with confirmation).
5. **Security Tips Card (`AfabCard`):**
   - 4 best-practice checklist items (`t("security.tip1Title")`..`tip4Desc`), with Tip 2 check icon dynamically reflecting `twoFactorEnabled`.

### Tablet Layout (`>= 600dp` / `>= 840dp`)
- `2:1` layout matching `SecuritySettings.tsx:222`:
  - Left 2/3: Overview + Auth/Biometrics Card + Active Sessions (data table on `>= 840dp`, cards on `< 840dp`).
  - Right 1/3: Security Tips card (without the omitted dead Contact Support card).

---

## 6. UI Components and Interactive Elements

| Component | Package / Widget | Details |
|---|---|---|
| `ChangePasswordSheet` | `AfabBottomSheet` | `Current Password`, `New Password` (`>= 8` chars + `PasswordStrengthIndicator`), `Confirm New Password`, obscure toggles, warning note (`"You will be signed out and asked to sign in with your new password."`). |
| `TwoFactorSetupSheet` | 3-step `PageView` / stateful sheet | **Step 1:** `QrImageView` (`qr_flutter_plus ^1.0.1`) rendering `qrCodeUri` on white rounded surface + copyable `secret` (`LTR`, monospace). **Step 2:** 6-digit `OTP` boxes (`LTR`, numeric keyboard) + `Verify & Enable 2FA`. **Step 3:** 2x4 grid of 8 recovery codes + `Copy All` + `Save/Share (.txt)` (`share_plus`) + `Done`. |
| `TwoFactorManageSheet` | `AfabBottomSheet` | Section A: `"Regenerate Backup Codes"` button → displays new 8-code grid + Copy & Share `.txt`. Section B: Red-tinted `"Disable Two-Factor Authentication"` form requiring current password. |
| `BiometricLockTile` | `SwitchListTile` + `local_auth` | Checks `canCheckBiometrics \|\| isDeviceSupported()`. Enabling triggers biometric prompt first; stores boolean in `flutter_secure_storage`. |
| `SessionCard` | `AfabInsetPanel` | Device icon (`Smartphone` / `Laptop` / `Monitor` parsed from `deviceInfo`), IP (`LTR`), created/expires timestamps, and single-revoke trash/logout icon button. |

---

## 7. Data Requirements and API Contracts

| Endpoint | Method | Request Body | Response / Status |
|---|---|---|---|
| `/api/v1/auth/change-password` | `POST` | `{ currentPassword, newPassword (>=8) }` | `200 ErrorResponse` + clears cookies & revokes all refresh tokens (`400 CHANGE_PASSWORD_FAILED`, `401`) |
| `/api/v1/user/2fa/setup` | `GET` | — | `200 TwoFactorSetupResponse { secret, qrCodeUri, backupCodes[8] }` |
| `/api/v1/user/2fa/enable` | `POST` | `{ secret, code, backupCodes[] }` | `200` empty (`400 INVALID_CODE`) |
| `/api/v1/user/2fa/disable` | `POST` | `{ password }` *(backend ignores `code`)* | `200` empty (`401 INVALID_PASSWORD`, `400 DISABLE_FAILED`) |
| `/api/v1/user/2fa/backup-codes` | `POST` | — | `200 List<String>` (8 codes, `400 FAILED`) |
| `/api/v1/user/me/sessions` | `GET` | *(Cookie `refreshToken` not sent due to `Path=/api/v1/auth`)* | `200 List<SessionDTO> { id, deviceInfo, ipAddress, createdAt, expiresAt, currentSession }` |
| `/api/v1/user/me/sessions/{tokenId}` | `DELETE` | Path `tokenId: UUID` | `200` empty (`403`, `400`) |
| `/api/v1/user/me/sessions` | `DELETE` | *(Cookie `refreshToken` null → revokes ALL)* | `200` empty |

---

## 8. State Management and Caching

- **`securitySettingsProvider` (`AutoDisposeAsyncNotifier`):**
  - Holds `twoFactorEnabled` (mirrored with `userProfileProvider`), `sessions: List<SessionDTO>`, `biometricEnabled: bool`, `biometricAvailable: bool`.
- **Session Revocation Updates:**
  - Single revoke removes `tokenId` optimistically or after `200 OK` and refreshes `sessions`.
  - `changePassword` `200 OK` and `revokeAllSessions` `200 OK` invoke `authNotifier.forceLocalLogout(reason: ...)` which clears `SessionTokenHolder`, wipes `PersistCookieJar`, resets all Riverpod providers, and routes to `/login`.

---

## 9. User Actions, Validation, and Error Handling

- **Change Password Validation:** `currentPassword` non-empty; `newPassword.length >= 8`; `newPassword == confirmPassword`; disables submit while loading. Maps `400 CHANGE_PASSWORD_FAILED` to inline banner.
- **2FA Setup Validation:** `setupCode` must be 6 digits (`^[0-9]{6}$`). Displays `400 INVALID_CODE` inline above OTP boxes. Closing Step 3 refreshes `userProfileProvider` (`twoFactorEnabled = true`).
- **2FA Disable Validation:** Password required. Displays `401 INVALID_PASSWORD` inline inside red Disable box.
- **Revoke All Confirmation:** Displays alert dialog warning: *"All active sessions—including this device—will be signed out immediately."* Requires explicit confirm before calling `DELETE /user/me/sessions`.

---

## 10. Permissions, Security, and Tenant Isolation

- **User-Scoped Domain:** Security settings operate strictly on the authenticated user (`/auth/change-password`, `/user/2fa/*`, `/user/me/sessions*`), independent of active workspace or `READ_ONLY` locks.
- **Biometric Flag Security:** Stored in `flutter_secure_storage` (Keystore / Keychain), never `SharedPreferences`. Clears on logout/account deletion.
- **Backup Code Handling:** Never logged by `AppLogger`; `.txt` share uses temporary cache file cleared after share completion or app restart.
- **Native Platform Permissions:** Requires `USE_BIOMETRIC` in `AndroidManifest.xml` and `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`.

---

## 11. Localization (EN/AR) and RTL Behavior

- Uses `settings.security.*` ARB keys plus mobile-specific keys for Biometric App Lock and the `"Log Out All Sessions"` current-device warning.
- **LTR Isolation:** Password inputs, 6-digit OTP boxes, Base32 TOTP `secret`, 8-character backup codes, and IP addresses (`ipAddress`) always enforce `TextDirection.ltr`.
- QR code container keeps a crisp white `#FFFFFF` background (`16dp` padding) in both Light and Dark modes so authenticator cameras scan reliably.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Responsive:** Sessions render as stacked cards on `< 840dp` and as a clean table on `>= 840dp` tablets.
- **Accessibility:** OTP input announces `"6-digit verification code"`; Copy Secret/Codes buttons announce `"Copied to clipboard"`; QR image provides `Semantics` label `"Two-factor authentication QR code"`.
- **States:** Shimmer rows while `sessions` load; empty state `"No active sessions found"` if list empty; inline retry on `GET /user/me/sessions` failure.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Change Password Forced Logout:** Changing password (`200 OK`) wipes `SessionTokenHolder` + `CookieJar` and routes user to `/login` (never leaving stale JWT in RAM).
2. **3-Step 2FA Enable & Disable:** Scanning/copying secret, entering 6-digit OTP (`POST /user/2fa/enable`), viewing/sharing 8 backup codes, regenerating codes, and disabling via password (`POST /user/2fa/disable`) all match backend DTOs.
3. **Revoke-All Cookie Caveat Handled:** Confirming `"Log Out All Sessions"` calls `DELETE /user/me/sessions`, shows warning beforehand, and performs clean local logout.
4. **Biometric App Lock:** Toggling Biometrics invokes `local_auth` verification and persists state in `flutter_secure_storage`.
5. **Dead Controls Omitted:** Neither `"Login Alerts"` switch nor `"Contact Support"` button is present.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Packages** | `local_auth: ^3.0.0`, `qr_flutter_plus: ^1.0.1`, `flutter_secure_storage: ^10.2.0`, `share_plus: ^13.3.1` | Verified in `06_FLUTTER_ARCHITECTURE.md`. |
| **Backend Session Caveat (`Path=/api/v1/auth`)** | `GET /user/me/sessions` always returns `currentSession: false`; `DELETE /user/me/sessions` revokes current session too. | Warn user clearly and perform local logout after revoke-all. Propose adding JWT `sid` claim in backend (`04_AUTHENTICATION_AND_SECURITY.md` §4.1). |
| **Backend 2FA Disable Caveat** | `TwoFactorDisableRequest` accepts `code`, but `AuthService.disableTwoFactor` validates only `password`. | Only prompt for `password` in `TwoFactorManageSheet`. |
