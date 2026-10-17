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
Feature wrappers in `lib/api/` include `client.ts`, `auth.ts`, `business.ts`, `dashboard.ts`, `expenses.ts`, `invoices.ts`, `revenue.ts`, `settings.ts`, and `transactions.ts`.

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
- Dashboard, transactions, expenses, revenue, invoices, AI page, plans, upgrade.
- Settings: general, business profile, security, subscription, and catch-all settings route.
- Maintenance and not-found states.

Dashboard components include KPI cards, revenue chart, AI insights, recent transactions, expense categories, reminders, top customers, sidebar, add-transaction modal, and upgrade banner. A visual component does not prove the data behind it is persisted/live.

## 8. Plans and multi-business requirement
`components/plans/PlansScreen.tsx` defines display plan data and local React state for billing/trial/checkout presentation. Treat it as presentation, not a subscription backend.

Requested limits:
- Free: 1 business
- Plus: up to 3 businesses
- Pro: up to 5 businesses

Rules:
- Show limits consistently on cards and comparison table.
- Keep plan limits in one typed configuration source.
- Use clear business-limit messaging and accessible tooltips.
- Do not infer payment/trial success from local state.
- Never enforce caps only in React; backend entitlements must enforce them.
- Current backend is one-business-per-user. True multi-business support requires coordinated backend/schema/authz changes.
- Do not invent yearly prices/discounts without confirmation.
- $9.99 Plus / $19.99 Pro are mockup proposals, not verified payment configuration.

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
