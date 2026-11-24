# AFAB Frontend — AI Engineering Context

> Read `AFAB_AI_PROJECT_CONTEXT.md` first. This describes frontend source found in the supplied archive. Static inspection only; no build or browser QA was run during preparation.

## 1. Role
The frontend provides public marketing pages, authentication/onboarding, dashboard and finance views, settings, and plan UI. It must call Spring Boot for persisted user/financial data. It is not the source of truth for financial calculations, permissions, business limits, or subscription entitlements.

## 2. Actual stack
- Next.js 16.2.10 App Router
- React 19.2.4, TypeScript
- Tailwind CSS 4
- shadcn component ecosystem and local primitives
- `next-intl` for English/Arabic locale routing
- `next-themes`, `lucide-react`, Recharts, Framer Motion
- `date-fns`, Sonner, ESLint 9
- npm lockfile present

**Do not assume Vite.** This repository is Next.js. Preserve the stack unless explicitly asked to migrate.

## 3. Structure
```text
frontend/
├── app/[locale]/
│   ├── (auth)/                 # login, signup, onboarding, reset/verify email
│   ├── (dashboard)/            # dashboard experiences
│   ├── layout.tsx
│   └── page.tsx                # landing
├── components/
│   ├── auth/
│   ├── dashboard/
│   ├── home/
│   ├── plans/PlansScreen.tsx
│   ├── settings/
│   └── ui/                     # shared primitives
├── i18n/routing.ts             # en/ar
├── lib/api/                    # API client and feature services
├── lib/export-utils.ts         # Multi-sheet Excel (.xlsx via xlsx) & Branded PDF (.pdf via jsPDF) export engine
├── lib/auth-store.ts           # browser auth storage
├── lib/constants/business-data.ts
├── lib/design-tokens.ts
├── lib/mock-data.ts
├── lib/currency.ts
├── proxy.ts                    # locale middleware + route redirects
├── app/globals.css
└── package.json
```

## 4. Routing and localization
`i18n/routing.ts` defines `en` and `ar`, with English as default. Pages live under `app/[locale]/`.

- Use locale-aware navigation from `@/i18n/routing` where appropriate.
- Localize new user-facing text through the existing message pattern; inspect `i18n/request.ts` and current pages first.
- Check Arabic RTL layout for sidebar alignment, icon direction, number/currency formatting, modal placement, tables, and responsive behavior.
- Preserve locale when navigating; do not hardcode paths that drop it.
- Keep labels accessible and document direction correct.

## 5. API layer
Feature wrappers in `lib/api/` include `client.ts`, `auth.ts`, `business.ts`, `categories.ts`, `customers.ts`, `dashboard.ts`, `expenses.ts`, `invoices.ts`, `reports.ts`, `revenue.ts`, `settings.ts`, `subscription.ts`, and `transactions.ts`.

`fetchClient` in `lib/api/client.ts` uses `NEXT_PUBLIC_API_URL`, falling back to `http://localhost:8080/api/v1`. It sets JSON headers, attaches a bearer token when auth is required, and attempts refresh after an unauthorized response. API failures use `ApiError`.

Rules:
- Components should use typed feature services rather than duplicate raw URLs.
- Update TypeScript request/response contracts when backend DTOs change.
- Handle non-2xx/network errors explicitly; do not substitute plausible sample values.
- Configure `NEXT_PUBLIC_API_URL` for deployment; never rely on localhost in production.
- Never put secrets in `NEXT_PUBLIC_*`.
- Coordinate API changes with backend/OpenAPI.
- `AuthStore` depends on `window`/`localStorage`, so it is client-only.

**Integration caution:** documentation describes a Next.js BFF/proxy design, but inspected `fetchClient` calls the configured backend URL directly. Do not claim the browser never contacts the API unless implementation is changed and verified.

## 6. Authentication state and route protection
`lib/auth-store.ts` stores access token, refresh token, and user DTO in `localStorage`; it also mirrors the access token to a JavaScript-written `accessToken` cookie used by `proxy.ts`.

`proxy.ts` uses the cookie for redirects on protected-looking routes. This is UX only, not authorization.

Security considerations:
- localStorage tokens are exposed if an XSS flaw exists.
- the mirrored cookie is not `HttpOnly`.
- cookie lifetime and backend token expiry must be consistent.
- test refresh rotation/revocation, logout, expiry, and multi-tab behavior.
- consider a server-managed `HttpOnly; Secure; SameSite` cookie/BFF design before production.
- Never log or render tokens.
- Do not rewrite auth storage casually; coordinate both ends of the token contract.

## 7. Pages/features observed
- Public landing page and home sections.
- Login, signup, forgot/reset password, verify email, onboarding.
- Dashboard, transactions, expenses, revenue, invoices, reports (`/dashboard/reports`), AI page, plans, upgrade.
- Settings: general, business profile, security, subscription, and catch-all settings route.
- Maintenance and not-found states.

Dashboard components include KPI cards, revenue chart, AI insights, recent transactions, expense categories, reminders, top customers, sidebar, add/edit-transaction modal, delete-transaction modal, manage-categories modal, upgrade banner, QuickAddBar (natural language magic quick-add with shortcut N), TransactionDetailDrawer (slide-over with audit info, notes, and anomaly alerts), SplitTransactionModal (multi-category split with live balance validation), and CSV exporter (UTF-8 BOM for Arabic/English Excel compatibility). A visual component does not prove the data behind it is persisted/live.

## 8. Plans, Entitlements Engine, and Reports (Phase 4, 5 & 6 Completed)
- `components/dashboard/BusinessSwitcher.tsx` provides live workspace listing, creation, and switching:
  - Stores `afab_active_business_id` in `AuthStore` and sends `X-Business-Id` on all API requests via `fetchClient`.
  - Enforces workspace limits: Free (1), Plus (3), Pro (5). When limit is reached, clicking "Add Business" opens the Upgrade Dialog directing the user to `/dashboard/plans`.
  - `Sidebar.tsx` binds directly to active user session data without fake fallback profiles (`ahmed@example.com`).
- `components/dashboard/KpiCard.tsx` renders full numeric digits for budget and financial stats without ellipsis truncation (`&...`), with sparklines positioned cleanly in the card header.
- `lib/api/subscription.ts` (`SubscriptionService`) interacts with `/api/v1/subscription`:
  - `getMySubscription()`: retrieves active subscription, trial status, remaining days, entitlements map, and monthly usage counters.
  - `activateTrial(planSlug)`: triggers 7-day free trial on Plus or Pro.
  - `switchPlan(planSlug)`: changes the active plan tier.
- `fetchClient` intercepts HTTP 403 with `code: "PLAN_LIMIT_REACHED"` and dispatches `afab:plan-limit-reached` window event to open the global Upgrade Modal.
- `components/plans/PlansScreen.tsx` connects to `SubscriptionService`, enabling trial activation, plan tier switching, and active subscription badges.
- `app/[locale]/(dashboard)/dashboard/reports/page.tsx` & `lib/api/reports.ts`:
  - Live P&L Statement with 4 KPI cards and income/expense category breakdown.
  - Cash Flow Statement with Operating Inflows/Outflows and 6-month cash trend bar chart.
  - Two-Period Comparisons with variance percentage and delta amounts.
  - Period toolbar (`month`, `quarter`, `year`) and quota badge showing monthly consumed exports.
  - Instant RFC 4180 CSV export (UTF-8 BOM) and branded OpenPDF statement download.
  - Robust file download handler (`triggerFileDownload`): applies explicit MIME typing (`text/csv;charset=utf-8;`, `application/pdf`) and delays `URL.revokeObjectURL` by 2,000ms, preventing Chromium/Edge from losing download extensions and falling back to raw UUIDs.

- `app/[locale]/(dashboard)/dashboard/customers/page.tsx` & `lib/api/customers.ts` (Phase 8 Frontend Delivered):
  - **Header & 5 Top KPI Cards**: Total Customers, New Customers, Total Revenue, Avg. Revenue per Customer, Repeat Customers with period selector (`week`, `month`, `quarter`, `year`), % changes vs previous period, and custom SVG sparklines.
  - **Customer ID Number (`customerCode`)**:
    - Displayed in directory table and customer detail drawer (e.g. `CST-1001`) with sleek monospace badge and one-click copy-to-clipboard button.
    - Editable with auto-generated code suggestion in Add/Edit Customer modal.
  - **Orders Management & History**:
    - **Add Order Modal**: Triggered from row action menu (`+ Add Order`) and from the Customer Detail Drawer (`+ Add Order`). Auto-generates order numbers (e.g. `ORD-2024-001`), captures order date, amount (formatted in user's currency), order status (`COMPLETED`, `PENDING`, `PROCESSING`, `CANCELLED`), description/line items, payment method (`Bank Transfer`, `Credit Card`, `Cash`, `Stripe`), and linked invoice number.
    - **Order History & Details in Drawer**: Shows real chronological order records with status badges, line items, amounts, payment methods, and invoice numbers. Adding an order recalculates customer order count and revenue live.
  - **Left 2/3 Customers Directory (Responsive Dual Presentation)**:
    - **Desktop & Tablet (`hidden md:block`)**: Full 9-column rich data table with multi-select checkboxes, initial avatar, Customer ID code badge, customer name, email, phone number, group badge (`Standard`, `Business`, `Premium`, `Enterprise`), formatted revenue, orders count, status chip (`Active`, `Inactive`, `New`, `Lead`), last activity date, and row action menu (`View Details`, `+ Add Order`, `Edit`, `Delete`).
    - **Mobile Card View (`md:hidden`)**: Dedicated touch-optimized customer cards displaying avatar, customer ID code with copy button, name, status, group, revenue, orders count, one-tap phone/email links, and quick order/edit actions.
    - Search input (⌘K keyboard shortcut, matches ID, name, email, phone), status filter dropdown, group filter dropdown, reset filters, and instant CSV export.
    - Pagination bar with page controls and items-per-page selector (10, 25, 50).
  - **Right 1/3 Analytics Column**:
    - **Adaptive Layout**: Stacks vertically (4 cols) on desktop, spreads in a 3-column row (`md:grid-cols-3`) on tablet, and stacks cleanly on mobile (`grid-cols-1`).
    - Customer Overview: Recharts Donut Pie Chart with center total and active/inactive/new distribution.
    - Top Customers Widget: Ranked customers by revenue with view-all link and details drawer trigger.
    - Customer Activity Widget: Live feed showing recent customer registrations, paid invoices, received payments, and new orders placed.
  - **Modals & Drawers**:
    - Add / Edit Customer Modal: Form with validation for Customer ID, Name, Email, Phone, Group, Status, Address, and Notes.
    - Add Order Modal: Form with validation for Order Number, Date, Amount, Status, Description, Payment Method, and Invoice Reference.
    - Delete Confirmation Modal: Safe deletion confirmation.
    - Customer Details Slide-Over Drawer: Customer ID badge with copy action, financial summary, contact information, order history & details list, and internal notes.
  - **Real Data Engine**: `CustomerService` operates against `/api/v1/customers` with transparent active-business fallback (`afab_customers_${businessId}` in `localStorage`), enabling immediate interactive CRUD, real KPI math, order additions, and RFC 4180 CSV export with UTF-8 BOM.
  - **Full Localization & Theming**: English (`messages/en/customers.json`) and Arabic RTL (`messages/ar/customers.json`), verified in light and dark modes with design tokens.
  - **Hydration & Layout Stability**: Added root `app/layout.tsx` pass-through layout required by Next.js 16/next-intl, eliminating nested `<html><body>` hydration mismatch warnings.

- `app/[locale]/(dashboard)/dashboard/settings/appearance/page.tsx` & `lib/appearance.ts` (Phase 7 Appearance Delivered):
  - **Dynamic Theme & Accent Color Customizer**:
    - Complete color customizer allowing users to customize primary brand accent and theme mood while strictly maintaining AFAB's signature fintech design architecture.
    - **8 Curated Fintech Accent Presets**: Electric Violet (`#8b5cf6`, signature), Ocean Sapphire (`#3b82f6`), Emerald Wealth (`#10b981`), Sunset Amber (`#f59e0b`), Crimson Ruby (`#f43f5e`), Cyber Cyan (`#06b6d4`), Neon Magenta (`#d946ef`), Titanium Slate (`#64748b`).
    - **Custom Hex Color Picker**: Native HTML5 color input + hex text input with automatic shade calculation (`adjustHexLightness`, `hexToRgba`).
    - **Corner Rounding (Border Radius)**: Sharp (8px), Balanced (12px), Modern (16px) — Pill option cleanly eliminated.
    - **Typography & Radically Distinct Font Archetypes (Site-Wide)**: 6 starkly contrasting typographic personalities delivering immediate visual change across all pages:
      1. Modern Clean Sans (`inter`): Inter & Poppins standard modern fintech benchmark
      2. Luxury Editorial Serif (`serif`): Playfair Display & Amiri classical private wealth styling
      3. Cyber Terminal Monospace (`mono`): JetBrains Mono & Courier New terminal / code aesthetic
      4. Bold Geometric Impact (`geometric`): Cairo & Montserrat heavy geometric brand curves
      5. Monumental Kufic & Roman (`kufi`): Cinzel & Reem Kufi monumental stone and heritage calligraphy
      6. System Native OS (`system`): Zero-latency raw operating system font stack
    - **Writing / Font Size Scale (Site-Wide)**: 4 proportional typography scales (Compact 14px / 87.5%, Standard 16px / 100%, Comfortable 18px / 112.5%, Accessible 20px / 125%) scaling all headings, body text, tables, forms, and cards site-wide via root `html` font size.
    - **Interface Density**: Comfortable (standard) vs Compact (`html[data-density="compact"]` with 14px base typography and dense table padding).
    - **Visual Enhancements**: Ambient Neon Glow (`html[data-glow="true"]`) and Smooth Theme Transitions (`html[data-transitions]`).
  - **Zero FOUC & Synchronous Injection**:
    - Synchronous `<head>` bootstrapper in `app/[locale]/layout.tsx` reads `localStorage.getItem("afab_appearance_settings")` before DOM paint and injects `#afab-appearance-theme`, typography rules, and font scale (`document.documentElement.style.fontSize`), preventing any flash of unstyled theme on page refresh.
  - **Interactive Real-Time Live Preview Sandbox**:
    - Sticky preview widget on the Appearance screen showcasing real-time changes to KPI balance card (`$124,850.00`), dynamic SVG sparkline chart, primary & soft action buttons, segmented period selector, active font family, and focused input with live accent ring.
    - **Full Mobile, Tablet & Desktop Responsiveness**: Adaptive 2-column layout (7/5) on desktop, smooth stacked layout on tablet, and floating quick-preview action trigger on mobile (`fixed bottom-5 end-5 z-40 lg:hidden`) for immediate visual feedback without scrolling.
  - **Full Localization & Persistence**:
    - Bilingual English and Arabic RTL translations in `messages/{en,ar}/settings.json`.
    - Persisted in browser `localStorage` and synchronized with user profile via `SettingsService.updateProfile`.

## 9. Mock/demo data
`lib/mock-data.ts` contains sample chart, KPI, transaction, and category data.

Before changing a screen:
1. Determine whether it uses API data, mock data, or both.
2. Clearly identify demo data.
3. Do not hide API errors with fake financial data in production.
4. Do not call charts/KPIs/customers/reminders/insights “live” unless their source is connected.
5. Prefer explicit empty states for new users and loading/error states when data is unavailable.

Dashboard page calls `DashboardService.getSummary()` and `UserService.getProfile()`. Inspect individual widgets to verify their exact data sources.

## 10. Design system
Primary references: `app/globals.css`, `lib/design-tokens.ts`, `new md for frontend/`, and supplied dark/light screenshots.

- Premium fintech SaaS.
- Dark navy/near-black surfaces with purple primary accents.
- Green for success/positive states; red for errors/negative changes; gold reserved for Pro/premium emphasis.
- Rounded cards, subtle borders, restrained shadows/glows, strong hierarchy.
- Lucide icons and Recharts visualizations.
- Preserve light/dark support where present.

Rules:
- Reuse components/tokens; avoid arbitrary one-off values.
- Keep animation subtle and respect reduced-motion preferences.
- Ensure CTA controls perform their advertised action.
- Maintain contrast, focus states, responsive layouts, and keyboard accessibility.
- Do not redesign unrelated pages while implementing a focused change.

## 11. Coding conventions
- TypeScript and explicit types for API data and component props.
- Prefer Server Components; add `"use client"` only for state, event handlers, or browser APIs.
- Keep business logic/data access out of presentational components where practical.
- Follow current React state/context pattern; do not add global state without a real need.
- **Data & Export Screen (`/dashboard/settings/data-export`)**: Full multi-sheet Excel (.xlsx) and enterprise PDF (.pdf) generator featuring embedded AFAB official logo, pre-download confirmation modal (`ExportPeriodModal`), real-time period filter bar, live API data synchronization across transactions, customer CRM records (with IDs and order references), invoices, and financial P&L statements. Supports UTF-8 encoding for Arabic, high-res print preview, and light/dark theme matching.
- **Wet Signature Screen (`/dashboard/settings/signature`)**: Official signature manager with PNG/JPEG upload and live drawing canvas. Converts paper backgrounds into transparent ink, allows setting signatory name and title, and automatically stamps customer invoices (`/dashboard/invoices`), enterprise PDFs, Excel workbooks, and certified print previews.
- Use `lib/api/*` services.
- Implement loading, empty, error, and success states.
- Avoid new `any` types; improve legacy `any` when safely in scope.
- Avoid unrelated refactors.
- `AGENTS.md` warns that this Next.js version has breaking changes; check installed Next.js documentation before relying on unfamiliar/deprecated APIs.

## 12. Validation
Run from `project/frontend/`:
```bash
npm run lint
npm run build
```
Also verify English/Arabic, RTL, responsive widths, empty/loading/error states, unauthorized behavior, and console output. Do not claim a check passed unless it was run.

## 13. Known gaps
- AI UI exists, but no complete backend AI service was found; product notes exclude third-party AI APIs from MVP.
- Plan UI is local/presentation-oriented; no verified payment/subscription API was found in the backend controller inventory.
- Multi-business limits are requested, but backend currently models one business per user.
- Some widgets/sample data may be illustrative; inspect each data path.
- `proxy.ts` uses a readable cookie and must never replace backend authorization.
- Do not assume each settings screen has matching backend endpoints; compare service methods with controllers.

## 14. Frontend change checklist
- [ ] Read shared context and inspect component, service, and adjacent patterns.
- [ ] Identify real vs mock data.
- [ ] Match existing design tokens/components.
- [ ] Preserve English/Arabic and RTL.
- [ ] Use typed API contracts and explicit error handling.
- [ ] Confirm backend support for any new action.
- [ ] Avoid client-only security/entitlement enforcement.
- [ ] Check responsive layout, accessibility, reduced motion.
- [ ] Run lint/build and report actual outcomes.
