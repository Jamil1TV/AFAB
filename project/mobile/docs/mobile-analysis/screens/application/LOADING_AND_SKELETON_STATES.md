# APP-01 — Loading & Shimmer Skeleton States (`AfabLoader` & Screen Skeletons)

> **Spec ID:** `APP-01`
> **Phase / Task:** Phase 0 (`P0-04`, `P0-06`)
> **Verified Web Sources:** `Web/project/frontend/app/[locale]/loading.tsx`, `components/ui/afab-loader.tsx`, `app/[locale]/(dashboard)/dashboard/page.tsx` (lines 81–87)
> **Verified Mobile Architecture Refs:** `07_DESIGN_SYSTEM.md`, `09_RESPONSIVE_AND_ADAPTIVE_DESIGN.md`, `FOLDER_STRUCTURE.md`

---

## 1. Screen Identity

- **Screen / Component Names:** `AfabLoader` (Quantum `"A"` Monogram), `GlobalLoadingOverlay`, `AfabSkeletonBox`, and per-feature Shimmer Skeleton widgets (`DashboardSkeleton`, `LedgerListSkeleton`, `CardGridSkeleton`, `DetailPaneSkeleton`, `AiCopilotSkeleton`, `SettingsSkeleton`)
- **File Paths:**
  - `lib/shared/widgets/afab_loader.dart`
  - `lib/shared/widgets/afab_skeletons.dart`
  - `lib/features/app_states/presentation/global_loading_overlay.dart`
- **Scope:** Cross-cutting loading UI across Splash, Auth transitions, Dashboard, Financial Ledgers, AI Copilot, Billing, and Settings

---

## 2. Purpose and Functional Parity

Provides full visual and brand parity with AFAB Web's custom animated geometric `"A"` monogram (`afab-loader.tsx`) while upgrading Web's spinner-only route transitions (`loading.tsx` / `dashboard/page.tsx`) to **native layout-preserving `shimmer` skeletons** so screens feel instantaneous and avoid jarring layout jumps.

---

## 3. Navigation and Entry/Exit Paths

- **When `AfabLoader` is Rendered:**
  1. **Cold-Start Session Restoration (`SplashScreen`):** `size: xl` (`112dp`) or `lg` (`80dp`) centered on `#F8F9FB` / `#060813` while `POST /auth/refresh` + `GET /user/me` execute.
  2. **Blocking Transitions / Modal Processing Overlay (`GlobalLoadingOverlay`):** `size: lg` (`80dp`) with translucent scrim (`background.withValues(alpha: 0.80)`) during Stripe Checkout verification (`POST /billing/checkout/verify`) or Account Deletion execution.
  3. **Inline / Compact Status (`xs` `20dp`, `sm` `32dp`, `md` `56dp`):** AI model warming banner, PDF/XLSX export preparation, or empty-canvas boot inside `AiCopilotScreen`.
- **When `Shimmer` Skeletons are Rendered:**
  - Initial `AsyncLoading` (where `valueOrNull == null`) on `DashboardScreen`, `TransactionsScreen`, `ExpensesScreen`, `RevenueScreen`, `CustomersScreen`, `InvoicesScreen`, `BudgetsScreen`, `RecurringTransactionsScreen`, `CurrenciesScreen`, `ReportsScreen`, `NotificationsScreen`, and `Settings` screens.
- **When Inline Button Spinners are Rendered:**
  - `AfabButton(isLoading: true)` (`18dp` `CircularProgressIndicator`) during form submissions (`Login`, `CreateBusiness`, `SaveTransaction`, `RecordPayment`) so the user maintains visual anchor on the button tapped.

---

## 4. Layout and Visual Hierarchy (Phone & Tablet)

- **`AfabLoader` Layered Vector Anatomy (100x100 logical coordinate space):**
  1. **Layer 1 — Ambient Luminescent Aura (`size != xs`):** Soft radial blur (`primary` 35% → `#06B6D4` 30% → `#10B981` 25%) pulsing scale `0.95 -> 1.15 -> 0.95` (`2.4s`).
  2. **Layer 2 — Outer Orbital Holographic Rings (`size != xs`):**
     - Outer dashed ring (`r = 45`, `strokeWidth = 1.2`, dash `18, 12, 6, 12`) rotating clockwise (`4s` linear).
     - Inner dashed ring (`r = 41`, `strokeWidth = 1.0`, `#06B6D4` 35% alpha, dash `4, 8`) rotating counter-clockwise (`6s` linear).
     - Orbiting satellite photon dot (`r = 2.2` + `r = 4.0` halo at `cx=50, cy=5`, `3s` clockwise).
  3. **Layer 3 — Clipped `"A"` Monogram Interior (`PathFillType.evenOdd`):**
     - Exact Web SVG path scaled to `Size`: outer apex `(50, 10)` → right leg `(86, 88)` → `(68, 88)` → `(58, 64)` → `(42, 64)` → `(32, 88)` → `(14, 88)` + triangular counter `(50, 28) -> (43, 50) -> (57, 50)`.
     - Inside `canvas.clipPath(aPath)`:
       - Base silhouette (`primary` 15% light / 25% dark).
       - Rising fluid wave gradient (`#3B82F6` → `primary` → `#06B6D4` → `#10B981`) oscillating vertically (`2.2s`) with horizontal crest ripple (`1.6s`).
       - Diagonal shimmer streak (`28°` tilt sweeping `-120 -> 160` over `1.8s`).
       - Pulsing quantum core circle at `(50, 39)` (`r = 6`, `#06B6D4`).
  4. **Layer 4 — Perimeter Contour & Running Laser Tracer:**
     - `Path` stroke (`1.2–2.2dp` per size) gradient (`primary -> #06B6D4 -> #10B981`) + animated `PathMetric` dash tracer (`35` dash / `150` gap, `2.2s` linear).
  5. **Optional Text Label:** Animated opacity pulse (`12–13sp` SemiBold) localized via `context.l10n` below the loader (`gap: 12dp`).

---

## 5. UI Components and Design System Mapping

### 5.1 `AfabLoaderSize` Scale
| Enum | Box Size (`dp`) | Show Orbital Rings & Glow | Stroke Width (`dp`) | Primary Usage |
|---|---|---|---|---|
| `xs` | `20 x 20` | `false` | `1.2` | Inline status chips, compact loading badges |
| `sm` | `32 x 32` | `true` | `1.5` | Small inline card/pane loaders, AI thinking chip |
| `md` | `56 x 56` | `true` | `1.8` | Sheet/dialog loading states (default) |
| `lg` | `80 x 80` | `true` | `2.0` | `GlobalLoadingOverlay`, blocking workspace transitions |
| `xl` | `112 x 112` | `true` | `2.2` | `SplashScreen` cold-start brand boot |

### 5.2 Per-Screen Shimmer Skeleton Catalog (`shimmer: ^3.0.0`)
- **Base Shimmer Colors:**
  - Light mode (`#F8F9FB` / `#FFFFFF`): `baseColor = #E5E7EB`, `highlightColor = #F9FAFB`.
  - Dark mode (`midnight`/`oled`/`slate`/`charcoal`): `baseColor = surfaceInset` (`#111827` / `#171F2C`), `highlightColor = border` (`#1F2937` / `#2A3447`).
- **Skeleton Layouts:**
  1. `DashboardSkeleton`: Header title + segmented bar placeholder → 2x2 (phone) / 4x1 (tablet) `AfabKpiCard` skeleton boxes → `220dp` chart area skeleton → AI card skeleton → 5 transaction row skeletons.
  2. `LedgerListSkeleton`: KPI summary strip (3 chips) + filter bar pills + `8` transaction/expense/revenue card rows (`40dp` leading icon + 2 text bars + trailing amount bar).
  3. `CardGridSkeleton`: Used by `BudgetsScreen`, `RecurringTransactionsScreen`, `CustomersScreen`, `InvoicesScreen` — summary strip + responsive `1`/`2`/`3`-column card skeletons with progress bar placeholders.
  4. `DetailPaneSkeleton`: Top hero amount + status pill + 4 metadata inset rows + attachment/line-item list placeholders (used inside `TransactionDetails`, `InvoiceDetails`, `CustomerDetails` & tablet split panes).
  5. `AiCopilotSkeleton`: Alternating assistant/user bubble placeholders + prompt composer bar placeholder.
  6. `SettingsSkeleton`: Grouped list tile skeletons (`36dp` leading icon + title/subtitle bars).

---

## 6. Data Models and State Management

- `AfabLoader` is a pure stateless/animated presentation widget driven by `AnimationController`s (disposed cleanly in `State.dispose()`).
- `AsyncValue` Pattern across Riverpod screens:
  - `when(data: ..., loading: () => <ScreenSkeleton>(), error: ...)` when no prior data exists.
  - When `isRefreshing` (`hasValue && isLoading`), keep showing `data` + thin `LinearProgressIndicator(minHeight: 2)` below `ShellAppBar` so pull-to-refresh or period switches never flash back to skeletons.
- `globalLoadingOverlayProvider`: `NotifierProvider<GlobalLoadingNotifier, String?>` (null = hidden; non-null localized message = shows blocking `GlobalLoadingOverlay`).

---

## 7. API Contracts and Data Flow

- No direct API calls. Consumed reactively by `AsyncValue` states from `Dio` repositories and `GoRouter` boot sequence.
- `SplashScreen` (`P1-01`) displays `AfabLoader(size: AfabLoaderSize.xl)` during `POST /api/v1/auth/refresh` + `GET /api/v1/user/me` with **zero artificial `Future.delayed` timers**.

---

## 8. User Interactions and Event Handling

- **Non-Blocking Skeletons:** Scrolling or switching tabs remains responsive while a single tab's `Shimmer` skeleton is active; Android system back pops cleanly.
- **Blocking `GlobalLoadingOverlay`:** Intercepts touch events via `AbsorbPointer` + `PopScope(canPop: false)` during atomic operations (e.g., `POST /billing/checkout/verify` or `DELETE /user/me`) to prevent mid-flight double execution.
- **Ticker Pause:** Uses `TickerMode` automatically when route is offscreen inside `StatefulShellRoute.indexedStack` so inactive tabs consume 0% GPU/CPU animation cycles.

---

## 9. Validation, Error, Loading, and Empty States

- **Slow Network Escalation:** If a screen skeleton remains in `AsyncLoading` beyond `10s`, show an unobtrusive inline hint (`"Still loading…"` / `"لا يزال التحميل جارياً..."`) or rely on `Dio` `15s` connect / `30s` receive timeout to transition cleanly to the screen's `Error` state with `"Retry"`.
- **Static Accessibility Fallback:** When `MediaQuery.disableAnimationsOf(context)` is `true` (or `AppearanceSettings.smoothTransitions == false` for non-essential shimmer), `AfabLoader` stops orbital/wave animations and renders a crisp static gradient `"A"` monogram with `Semantics(liveRegion: true)`, and skeletons render static muted `baseColor` boxes without shimmer sweep.

---

## 10. Localization (EN/AR) and RTL Behavior

- **Fixes Web Hardcoded English (`loading.tsx:6`, `dashboard/page.tsx:84`):**
  - `loadingWorkspace` (`"Loading AFAB workspace..."` / `"جاري تحميل مساحة عمل AFAB..."`)
  - `loadingFinancialStats` (`"Loading real-time financial stats..."` / `"جاري تحميل الإحصائيات المالية..."`)
  - `loadingGeneric` (`"Loading..."` / `"جاري التحميل..."`)
- **RTL Skeleton Mirroring:** All `Shimmer` skeletons inherit `Directionality.of(context)` via `EdgeInsetsDirectional` and `CrossAxisAlignment.start`, mirroring avatar/icon placement and shimmer sweep direction (`ShimmerDirection.rtl` in Arabic, `ShimmerDirection.ltr` in English).

---

## 11. Accessibility and Responsive Guardrails

- `AfabLoader` wraps in `Semantics(label: text ?? context.l10n.loadingGeneric, liveRegion: true)` and excludes decorative inner `CustomPaint` layers from screen-reader traversal (`ExcludeSemantics`).
- Skeleton containers use `ExcludeSemantics` + single outer `Semantics(label: context.l10n.loadingGeneric)` so TalkBack/VoiceOver does not read 20 meaningless placeholder rectangles.
- Skeletons adapt column counts (`1` col `< 360dp`, `2` cols `360–599dp`, `2–4` cols `>= 600dp`) using the exact same `AfabBreakpoints` as live content to guarantee zero `RenderFlex` overflow.

---

## 12. Web Bugs Fixed and Mobile Divergences

1. **Hardcoded English in `loading.tsx:6` & `dashboard/page.tsx:84`:** Localized into `app_en.arb` / `app_ar.arb`.
2. **Lack of Structural Skeletons on Web:** Web replaces whole pages with a centered `AfabLoader`; Mobile uses `shimmer` layout-matched skeletons for data fetches and reserves `AfabLoader` for brand boot (`Splash`), blocking overlays, and AI studio empty-state warming.
3. **Missing Reduced-Motion Support in `afab-loader.tsx`:** Web runs infinite `framer-motion` loops unconditionally; Mobile respects `MediaQuery.disableAnimationsOf(context)`.

---

## 13. Testing and Verification Plan

- **Widget & Golden Tests (`test/widget/app_states/loading_and_skeletons_test.dart`):**
  - `AfabLoader` renders cleanly at all 5 sizes (`xs`, `sm`, `md`, `lg`, `xl`) without layout exceptions.
  - `MediaQuery(data: MediaQueryData(disableAnimations: true))` disables continuous ticker animation cleanly.
  - `DashboardSkeleton` and `LedgerListSkeleton` render with 0 overflow at `320x568`, `390x844`, `768x1024`, `1280x800` in Light, Dark (`oled`/`midnight`), `en`, and `ar`.
  - Verify `Semantics` label `"Loading..."` / `"جاري التحميل..."` is exposed.

---

## 14. Dependencies and Risks

- **Package Dependencies:** `shimmer: ^3.0.0`, `flutter_riverpod: ^3.5.0`.
- **Technical Risks:**
  - **CustomPainter Mask Performance:** `canvas.saveLayer` for `BlendMode` clipping can be costly if used repeatedly in lists. Since `AfabLoader` uses `canvas.clipPath(aPath)` (vector clip, no offscreen `saveLayer` needed) and appears at most once per viewport, GPU cost remains negligible (`< 0.5ms`/frame).
  - **Skeleton Drift:** Keep `DashboardSkeleton` and `LedgerListSkeleton` aligned whenever card paddings change in `07_DESIGN_SYSTEM.md` (`compact` vs `comfortable` density).
