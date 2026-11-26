# 13 — Technical Risks, Architecture Decision Records (ADRs) & Open Questions

---

## 1. Architecture Decision Records (ADRs)

| ADR | Decision | Alternatives Considered | Rationale & Trade-offs |
|---|---|---|---|
| **ADR-01** | **Encrypted `PersistCookieJar` (`flutter_secure_storage`) + RAM-only Access JWT** | Ask backend to return `refreshToken` in JSON body | Preserves existing P0 backend security (`HttpOnly` cookie + SHA-256 hash + CSRF double-submit) with zero backend changes for login/refresh. |
| **ADR-02** | **5-Tab Phone `StatefulShellRoute` + Tablet `NavigationRail`** | Put all 13 web items in a Drawer-only phone app | Keeps top daily workflows (Dashboard, Finance, Copilot, Invoices) 1 tap away while preserving all 13 destinations cleanly in `MoreHubScreen` & Tablet Rail. |
| **ADR-03** | **Strict `Decimal` (`decimal` package) + Explicit 3-Decimal Minor-Unit Map** | `double` (`num`) everywhere like JS `Number` | Eliminates IEEE-754 rounding errors on splits/invoices/FX and fixes Web's `toFixed(2)` truncation of `TND`/`KWD`/`BHD`/`OMR`. |
| **ADR-04** | **Riverpod 3.x + GoRouter 18.x + Dio 5.9.x + Freezed 4.x** | BLoC + http + Navigator 1.0 | Compile-safe DI, clean `AsyncValue` states, effortless business-switch cache invalidation, native `ResponseType.stream` for AI SSE. |
| **ADR-05** | **Fix Confirmed Web Bugs in Mobile Presentation/Mapping Layer** | Blindly replicate Web bugs 1:1 | Mobile uses exact backend DTO contracts (`ExpenseCategories` numeric `value`, `CategoryDTO.systemDefault`, `CustomerDTO.outstandingBalance`, `InvoiceDTO.subtotal`, Duplicate `POST`, `_` token preservation). |
| **ADR-06** | **Honest Labeling of Synthetic FX & Local-Only Features** | Claim Binance WebStream / Server Sync | Clearly badge simulated FX history/tick charts, local-only FX alerts, and device-local wet signatures rather than misleading users. |

---

## 2. Register of Confirmed Web & Backend Bugs Impacting Mobile

### High / Critical Severity
1. **Password Reset Token `_` Stripping (`reset-password/page.tsx:24`):** Web regex strips `_` from Base64URL tokens. **Mobile Fix:** Pass raw token verbatim (`Uri.decodeComponent` only).
2. **`ExpenseCategories` Always Shows `$0.00` (`ExpenseCategories.tsx:9,64`):** Web `parseFloat("USD 500.00") → NaN`. **Mobile Fix:** Read numeric `value` field directly.
3. **`CategoryDTO.isSystemDefault` JSON Mismatch (`CategoryDTO.java:61`):** Serializes as `"systemDefault"`. **Mobile Fix:** Map `@JsonKey(name: 'systemDefault')`.
4. **Transaction Duplicate Calls `PUT /transactions/` (`transactions/page.tsx:165`):** Empty string `id` triggers Edit mode. **Mobile Fix:** Separate `TransactionFormMode { create, duplicate, edit }`.
5. **Customer Details Drawer Empty Orders & `$0` Outstanding (`customers/page.tsx`):** List omits `orders`; drawer skips `GET /customers/{id}` and calculates wrong `pendingBalance`. **Mobile Fix:** Always fetch `GET /customers/{id}` and bind `outstandingBalance`.
6. **Active Session Detection & Revoke-Other Broken (`application.yml:90` + `UserController.java:294,351`):** `refreshToken` `Path=/api/v1/auth` means `/user/me/sessions` never receives cookie (`currentSession` always `false`; "Revoke All Other" revokes current session too!). **Mobile Mitigation:** Warn user before "Log Out All Sessions" and clear local session automatically.
7. **Business Logo Upload Fails 500-Char Limit (`BusinessProfile.tsx` vs `UpdateBusinessRequest`):** Uncompressed data URI rejected by `@Size(max=500)`. **Mobile Mitigation:** Accept HTTPS URL only until backend MinIO logo upload exists.
8. **Account Deletion Deadlock on `READ_ONLY` Businesses (`UserAccountService` vs `BusinessController`):** Owned `READ_ONLY` businesses block deletion (`409`), yet `DELETE /business/{id}` rejects them (`403 BUSINESS_READ_ONLY`). **Mobile Mitigation:** Detect `READ_ONLY` blocking businesses in preflight UI and guide user to Transfer Ownership or upgrade/allocate before deletion.

### Medium / Low Severity
9. `invoices/page.tsx` missing `SENT` filter pill & AI reminder check; `openPrintableInvoiceWindow` reads `subtotalAmount` instead of `subtotal`.
10. `SplitTransactionModal` stale `categoryId`, hardcoded `EXPENSE`/`CARD`/`$`.
11. `ManageCategoriesModal` 3rd color `"var(--primary)"` breaks hex parsing; no Edit UI.
12. `currencies/page.tsx` `useEffect` resets `viewBaseCurrency`; `1Y` history returns 52 days instead of weeks; `BinanceLiveChart` is 100% synthetic.
13. `reports/page.tsx` hardcodes `comparisonPeriod=last_month`, hides Pro custom dates, exports P&L only; backend OpenPDF lacks Arabic TTF.
14. `SecuritySettings` does not clear local session after `POST /auth/change-password`; Login Alerts & Contact Support are dead UI.
15. `maintenance/page.tsx` nested inside `(dashboard)/`; `not-found.tsx` links to missing `/support`.
16. Seeded entitlements `invoices.per_month`, `team.users`, `forecast.cashflow`, `ai.recommendations` are not enforced by backend.

---

## 3. Store Policy & External Integration Risks

| Risk | Impact | Mitigation |
|---|---|---|
| **Apple App Store (Guideline 3.1.1) & Google Play Billing Policy** | Using Stripe Checkout inside an iOS/Android app for digital SaaS subscriptions (`Plus`/`Pro`) risks app rejection unless compliant with store rules (e.g., reader/companion web billing or native StoreKit/Play Billing). | **Product/Legal Decision Required before P6-01:** Decide between (a) companion/web-only upgrade CTA on iOS/Android, (b) Apple/Google IAP + RevenueCat synced to backend `subscriptions`, or (c) external link entitlement (region-dependent). |
| **Stripe `sanitizeReturnPath` Rejects `afab://`** | `StripeBillingService` forces `{frontendUrl}/{locale}/dashboard/settings/subscription`. | Use **App Links (Android) / Universal Links (iOS)** pointing to `{frontendUrl}/{locale}/dashboard/settings/subscription` or add allowlisted mobile callback in backend. |
| **Ollama LLM Cold-Start & `maxConcurrentRequests=1`** | Mobile cellular networks may drop idle HTTP connections during 30–90s Deep Mode inference. | Rely on backend `6s` SSE `ping` frames, set `receiveTimeout: 130s`, show live `warming_model` phase indicator, and allow `CancelToken` abort. |
| **Play Store / App Store Permissions** | Camera, Photo Library, Microphone (`speech_to_text`), Biometrics (`local_auth`), File Storage. | Declare clear usage descriptions in `Info.plist` & `AndroidManifest.xml`, request just-in-time on action tap. |

---

## 4. Remaining Open Questions Requiring Stakeholder Confirmation

1. **App Store Billing Strategy:** Should mobile trigger Stripe Checkout via Custom Tabs/Universal Links, link users out to web billing ("Manage plan on web"), or integrate native Apple IAP / Google Play Billing?
2. **3-Decimal Currency Display:** Should mobile render `3` decimal places for `TND`/`KWD`/`BHD`/`OMR` (true ISO-4217 accounting) or match Web's `toFixed(2)`? *(Blueprint recommends ISO-4217 3-decimal display while preserving backend `NUMERIC(19,4)`.)*
3. **Minimal Backend Patch Approval:** Can the 5 small backend compatibility fixes (session `sid` claim, mobile Stripe callback allowlist, MinIO business logo upload, `READ_ONLY` deletion archive, Arabic font in OpenPDF) be scheduled alongside Mobile Phase 2/6?
4. **Production Domain & Universal Links:** What are the exact staging/production API and Web hostnames for Android `assetlinks.json` and iOS `apple-app-site-association`?
