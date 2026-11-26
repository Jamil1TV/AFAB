# AI-01 — AFAB Copilot Studio Screen (`AI_COPILOT_SCREEN.md`)

> **Domain:** AI Copilot v2 (`lib/features/ai/`)
> **Spec ID:** `AI-01`
> **Target Flutter File:** `lib/features/ai/presentation/ai_copilot_screen.dart`
> **Route:** `/dashboard/ai` (Tab 2 root in Phone `StatefulShellRoute`; Workspace section in Tablet `NavigationRail`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `AI-01` |
| **Screen Name** | AFAB Copilot Studio |
| **Flutter Widget** | `AiCopilotScreen` (`ConsumerStatefulWidget`) |
| **Route Path** | `/dashboard/ai` (`AppRoutes.aiCopilot`) |
| **Navigation Role** | Primary Tab 2 (`Copilot` / المساعد الذكي) on Phone (`< 600dp`); Workspace Rail destination (`AI Copilot`, `NEW` badge) on Tablet (`>= 600dp`) |
| **Access Scope** | Authenticated + Verified + Onboarded user; workspace-scoped via `X-Business-Id` (`READ_ONLY` workspaces disable mutating AI turns, sync, and draft approvals) |
| **Priority** | `P2` (Roadmap tasks `P5-01`, `P5-02`) |

---

## 2. Web Source Reference & Parity Status

| Web Source File | Role in Web | Web Parity Status | Mobile Adaptation |
|---|---|---|---|
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/ai/page.tsx` | Main Copilot Studio workspace (1,258 lines): sidebar, quota meter, header, welcome, SSE loop, composer | Implemented and Connected | Native `Scaffold` + drawer/split-pane history, `AfabBottomSheet` health/attachments, native keyboard-safe two-zone composer |
| `Web/project/frontend/lib/api/ai.ts` | `AiService` (21 API/SSE wrappers + DTO interfaces) | Implemented and Connected | `AiRepository` + `Dio` + `SseClient` (`ResponseType.stream` + `CancelToken`) |
| `Web/project/frontend/lib/image-compress.ts` | Client-side Canvas image resize (`<= 1024px`, JPEG `0.85`, skip `<= 1.2 MB`) | Implemented and Connected | `flutter_image_compress` with identical `1024px` max dimension and `85` JPEG quality |
| `Web/project/frontend/components/ai/AiModelStatusBadge.tsx` | Live Ollama/model health pill & diagnostic popover | Implemented and Connected | Interactive status pill in AppBar opening `AiModelHealthSheet` (phone) / anchored popover (tablet) |
| `Web/project/frontend/components/ai/CopilotWelcome.tsx` | Hero, Live Financial Pulse strip, 2x2 action bento grid, quick pills | Implemented and Connected | Scrollable welcome view with responsive 1-col/2x2 bento grid and live Pulse strip |
| `Web/project/frontend/components/ai/CopilotThinkingCard.tsx` | Elapsed timer, rotating phase shimmer, deep reasoning trace, tool pills, live streaming preview | Implemented and Connected | Native animated shimmer card + collapsible thinking trace + `flutter_markdown_plus` live stream |
| `Web/project/frontend/components/ai/CopilotMessageBubble.tsx` | User/Assistant bubbles, avatar, reasoning trace, tools strip, charts, drafts, evidence grid, copy/regenerate/tokens | Implemented and Connected | Per-message directional `Bubble` + native touch actions (replacing hover-only copy/delete) |
| `Web/project/frontend/components/ai/CopilotMarkdown.tsx` | Custom Markdown parser (headings, bold/italic/code, LTR fenced code blocks, tables, blockquotes, lists) | Implemented and Connected | `flutter_markdown_plus` with custom `CodeBlockBuilder` (LTR + Copy) and horizontal-scroll `Table` |
| `Web/project/frontend/components/ai/CopilotChartCard.tsx` | Recharts Bar/Line/Area/Donut + UTF-8 BOM CSV download | Implemented and Connected | `fl_chart` touch-interactive Bar/Line/Area/Pie charts + UTF-8 BOM CSV export via `share_plus` |
| `Web/project/frontend/components/ai/CopilotActionDraftCard.tsx` | Editable `CREATE_TRANSACTION`, `CREATE_INVOICE`, `CREATE_BUDGET` draft cards + receipt preview | Implemented and Connected | Native form cards with DatePicker, Category/Customer selectors, Approve & Dismiss |
| `Web/project/frontend/components/ai/CopilotReminderCard.tsx` | Editable Email & WhatsApp payment reminder card (`mailto:` / `wa.me`) | Implemented and Connected | Native channel toggle, editable text fields, Copy + `url_launcher` (`mailto:` / `https://wa.me/`) |
| `Web/project/frontend/components/ai/CopilotMemoryProposalCard.tsx` | Inline `SAVE_MEMORY` proposal card (`Ignore` / `Approve & Remember`) | Implemented and Connected | Inline editable title/content card calling `/ai/actions/approve-memory` or `/dismiss` |
| `Web/project/frontend/components/ai/AttachmentPreviewChip.tsx` | Staged & message attachment chip with authenticated preview thumbnail | Implemented and Connected | Thumbnail via local file or `GET /ai/attachments/{id}/preview` + `CachedNetworkImage` / memory bytes |
| `Web/project/frontend/components/ai/VoiceDictationButton.tsx` | Web Speech API (`en-US`, `fr-FR`, `ar-TN`) dictation with interim preview | Implemented and Connected | `speech_to_text: ^7.5.0` with EN/FR/AR-TN cycler, live interim chip, and mic permission handling |
| **Backend Sources** | `AiController.java` (21 endpoints), `AiCopilotService.java`, `AiActionExecutionService.java`, `AiAttachmentService.java`, `AiFileExtractor.java`, `AiFinanceToolRegistry.java` (16 tools), `AiLanguageResolver.java`, `AiProperties.java` | Authoritative | 100% contract parity; mobile adds delete confirmation dialog to protect archived conversations |

---

## 3. Purpose and User Value

AFAB Copilot Studio is the full-screen private AI CFO workspace grounded deterministically in the active business's PostgreSQL ledger, invoices, customers, budgets, recurring commitments, receipts, and Business Memory via hybrid RAG (`pgvector` cosine + PostgreSQL FTS). Users can:

1. Ask financial questions or request simulations in **5 sticky polyglot modes**: English (`EN`), French (`FR`), Modern Standard Arabic (`AR_MSA`), Tunisian Derja in Arabic script (`AR_DERJA_SCRIPT`), and Tunisian Derja in Latin/Arabizi (`AR_DERJA_ARABIZI`).
2. Switch between **Fast** (`numCtx=6144`, `maxOutputTokens=1024`, `maxToolCalls=4`) and **Deep Analysis** (`numCtx=8192`, `maxOutputTokens=2048`, `maxToolCalls=6`, `think=true` live reasoning trace) modes.
3. Snap receipt photos, pick gallery images, or upload documents (`PDF`, `XLSX`, `CSV`, `TXT`, `JSON`, `MD`, `<= 10 MB`, max 3 per turn) for multimodal analysis and 1-tap conversion into persisted transactions + MinIO receipts.
4. Dictate prompts hands-free in English, French, or Tunisian Arabic (`ar-TN`).
5. Inspect real-time tool execution (`16` deterministic BigDecimal/domain tools), interactive `fl_chart` visualizations (with CSV export), verified evidence links, and Human-in-the-Loop editable action drafts (never mutating the database without explicit user approval).
6. Manage conversation history, monitor monthly AI token/query quotas, inspect local Ollama model readiness, and manually trigger RAG index synchronization.

---

## 4. Navigation, Entry Points, and Exit Paths

### Entry Points
- **Phone Bottom Navigation Bar:** Tab 2 (`Copilot` — elevated accent `Sparkles` icon).
- **Tablet NavigationRail:** Workspace section item `AI Copilot` (`NEW` badge).
- **Global Copilot Sheet (`AI-02`):** Tapping `Full View` (`openWorkspace`) closes `GlobalCopilotSheet` and routes to `/dashboard/ai`, optionally carrying the active `conversationId` as query/extra state so the user continues the same thread seamlessly.
- **Evidence / Draft Action Deep Links (Return):** Returning via back navigation from pushed transaction/invoice/budget screens.

### Exit Paths
- **Business Memory (`AI-03`):** Tapping the Header `Memory` pill (`Brain` + `memories.length` badge) pushes `BusinessMemoryScreen` (`/dashboard/ai/memory`) on `< 1024dp` or toggles the inline right-hand `BusinessMemory` side pane on `>= 1024dp`.
- **Evidence Chips & Approved Draft `View Record` Links:**
  - `href == "/dashboard/transactions"` → switches/pushes Transactions screen (`Tab 1`).
  - `href == "/dashboard/invoices"` → switches/pushes Invoices screen (`Tab 3`).
  - `href == "/dashboard/customers"` → pushes `CustomersScreen`.
  - `href == "/dashboard/budgets"` → pushes `BudgetsScreen`.
  - `href == "/dashboard/recurring"` → pushes `RecurringTransactionsScreen`.
  - `href == "/dashboard/expenses"` → pushes `ExpensesScreen`.
  - `href == "/dashboard/revenue"` → pushes `RevenueScreen`.
  - `href == "/dashboard/ai"` (e.g., `MEMORY` evidence or `SAVE_MEMORY` approved draft) → opens `BusinessMemoryScreen` (`AI-03`).
  - `href == "/dashboard"` → switches to Home Tab 0 (`DashboardScreen`).
- **Quota Upgrade CTA:** Tapping `Upgrade Plan` inside the Quota Meter or `Plan Quota Exhausted` banner pushes `PlansAndSubscriptionScreen` (`/dashboard/settings/subscription`).
- **Back Navigation:** On Phone root tab (`Tab 2`), Android system back closes open Conversation Drawer / Health Sheet first; if none open, switches to Tab 0 (`Home`) per `05_MOBILE_INFORMATION_ARCHITECTURE.md`.

---

## 5. Layout and Visual Hierarchy

### 5.1 Phone Layout (`width < 600dp`) & Medium Tablet (`600–839dp`)
```text
┌──────────────────────────────────────────────────────────┐
│ Studio AppBar (56dp)                                     │
│ [≡ History] [Sparkles + Title / ActiveLang]              │
│             [● Health Pill]  [+New] [↻ Sync(N)] [🧠 (M)] │
├──────────────────────────────────────────────────────────┤
│ [Conditional] Local Ollama Offline Banner (Amber)        │
│ [Conditional] Plan Quota Exhausted Banner (Red + CTA)    │
│ [Conditional] Inline Chat Error Banner (Red + Dismiss)   │
├──────────────────────────────────────────────────────────┤
│ Conversation Canvas (Expanded ListView / Welcome Scroll) │
│  ├─ If messages.isEmpty && !sending:                     │
│  │   CopilotWelcome (Hero + Live Pulse Strip +           │
│  │   Morning CFO Brief CTA + 2x2 Bento + Quick Pills)    │
│  └─ Else:                                                │
│      List of CopilotMessageBubble (User / Assistant)     │
│      + [If sending] CopilotThinkingCard                  │
│      + [If !sending && followUps] Follow-Up Chips        │
│                                      [↓ Jump to Latest]  │
├──────────────────────────────────────────────────────────┤
│ Flagship Two-Zone Composer (SafeArea bottom)             │
│  ├─ Staged Attachment Chips (Horizontal Wrap, max 3)     │
│  ├─ [If listening] Live Interim Voice Pill (Red pulse)   │
│  ├─ Zone 1: Auto-growing multiline TextField (max 4000)  │
│  └─ Zone 2: [📎 Attach] [⚡Fast | 🧠Deep]   [TN 🎤] [↑/■] │
└──────────────────────────────────────────────────────────┘
```

### 5.2 Tablet Landscape Layout (`width >= 840dp` / `>= 1024dp`)
- **Left Pane (`280dp`, collapsible via `PanelLeftClose`/`PanelLeftOpen`):**
  - `New Chat` full-width outlined-soft CTA (`Plus` + `Sparkles`).
  - Search conversations input (`Search`).
  - `Conversations` section header + total count pill.
  - Scrollable date-grouped conversation list (`Today`, `Yesterday`, `Previous 7 days`, `Earlier`).
  - Pinned bottom **Monthly AI Quota Meter Card** (`AfabInsetPanel`).
- **Center Pane (Expanded `flex: 1`):** Studio Header, conditional banners, centered `ConstrainedBox(maxWidth: 768)` conversation canvas, floating Jump-to-Latest FAB, and centered `ConstrainedBox(maxWidth: 768)` Two-Zone Composer.
- **Right Pane (`420dp`, `>= 1024dp` optional toggle):** Inline `BusinessMemoryScreen` (`AI-03`) side pane when `Memory` is toggled open; on `600–1023dp`, `BusinessMemory` opens as a modal side sheet (`440dp`).

---

## 6. UI Components and Interactive Controls

### 6.1 Studio Header Controls
1. **Conversation Drawer Trigger:**
   - `< 840dp`: `IconButton(LucideIcons.menu)` opens left/start `Drawer` (width `min(304dp, 82% screen)`), containing `New Chat`, Search, grouped history, and the Quota Meter card at the bottom.
   - `>= 840dp`: `IconButton(PanelLeftClose / PanelLeftOpen)` toggles inline left sidebar.
2. **Title & Language Badge:** Displays `activeConversation.title` (truncated 1 line) or `l10n.aiTitle`. When `activeLanguage != null`, displays compact pill (`EN`, `FR`, `AR`, `دارجة`, `Derja`).
3. **`AiModelStatusBadge` Pill:**
   - Color-coded live status pill:
     - `!backendConnected` → Red pill (`Backend Offline`) with ping dot.
     - `health == null` → Neutral gray (`Checking...`).
     - `!ollamaReachable` → Amber pill (`Local Ollama Offline`).
     - `!chatModelReady` → Amber pill (`Pull Model Required`).
     - `busy` → Primary violet pill (`<chatModel> · Generating...`) with ping dot.
     - Ready + `chatModelLoaded` → Emerald pill (`<chatModel> · Hot GPU` + `<latencyMs>ms`) with ping dot.
     - Ready + cold → Emerald pill (`<chatModel> · Ready` + `<latencyMs>ms`).
   - Tap opens **Model Health Diagnostic Sheet (`AiModelHealthSheet`)**: displays Live badge, AFAB Backend API status, Local Ollama Runtime status (`Online (Xms)`/`Offline`), Chat Model (`gemma4:e4b` + `Hot GPU`/`Cold`/`Not Pulled`), Embedding Model (`embeddinggemma-2:270m` + `Ready`/`Not Pulled`), `lastChecked` localized `HH:mm:ss` timestamp, and `Check Now` button (`GET /ai/health?fresh=true`).
4. **Header Action Buttons:**
   - `New Chat` (`Plus`): visible when sidebar collapsed or `messages.isNotEmpty`. Resets active conversation and draft composer state.
   - `Sync Index` (`RefreshCw` + `(indexedChunks)`): calls `POST /api/v1/ai/index/sync`. Shows spinner while syncing; disabled on `READ_ONLY` workspace.
   - `Business Memory` (`Brain` + badge `memories.length`): opens `AI-03`.

### 6.2 Conversation Drawer (`AiConversationDrawer`)
- **Search Input:** Instant client-side filter over `conversations` by `title` (case-insensitive) with clear (`X`) button.
- **Date Grouping:** Groups by `updatedAt ?? createdAt` into `Today`, `Yesterday` (`>= midnight - 1d`), `Previous 7 days` (`>= midnight - 7d`), and `Earlier`.
- **Conversation Tile:** Tap loads `GET /api/v1/ai/conversations/{id}` and closes drawer on mobile. Trailing `Trash2` icon button (always visible at `44x44dp` hit area on touch devices, or via `Dismissible` swipe-to-delete) triggers confirmation dialog (`Delete conversation?`) → `DELETE /api/v1/ai/conversations/{id}`.
- **Quota Meter Card:**
  - Header: `Zap` icon + `AI Tokens` + `planName` uppercase pill.
  - Linear progress bar: `tokenPct = limit > 0 ? min(100, round(used / limit * 100)) : 0`. Bar color: `<75%` primary gradient, `75–89%` `#F59E0B`, `>=90%` `#EF4444`.
  - Counters (tabular figures): `<tokensUsed> / <tokensLimit | Unlimited>` and `<queriesUsed>/<queriesLimit | ∞> Queries`.
  - If `tokenPct >= 75`: renders `Upgrade Plan` gradient CTA button.

### 6.3 `CopilotWelcome` (Empty Canvas)
- **Hero:** `Sparkles` glowing badge, `heroTitleStart` + gradient `heroTitleHighlight`, `welcomeSubtitle`.
- **Live Financial Pulse Strip:** Populated from `GET /api/v1/ai/pulse`:
  - `Month Net`: formatted `MoneyText` (`emerald` if `>= 0`, `rose` if `< 0`).
  - `Overdue`: dot (`rose` if `overdueCount > 0`, `emerald` if `0`) + count or `All clear`.
  - `Alerts`: dot (`amber` if `highCount + mediumCount > 0`, `emerald` if `0`) + count or `Healthy`.
  - Fallback while loading/unavailable: 3 capability chips (`On-device Ollama privacy`, `Verified BigDecimal tools`, `EN · AR · FR · Tunisian Derja`).
  - Primary CTA button: `Morning CFO Brief` (`Sunrise` icon) → immediately sends `morningBriefPrompt`.
- **2x2 Bento Action Grid:**
  1. `Monthly Profit & Loss` → auto-sends `pnlText`.
  2. `90-Day Cashflow Forecast` → auto-sends `forecastText`.
  3. `Scan Receipt or Import File` (`Upload` badge) → opens Attachment Source Bottom Sheet.
  4. `Derja / Multilingual Check` → auto-sends `"Kadeh sraft hal chhar w chniya akther masarif?"`.
- **Quick Suggestion Pills:** `Overdue Invoices & Cash` (send), `Budget Health Check` (send), `Log an expense by chat` (prefills `"Log expense: "` and opens keyboard).

### 6.4 Message Stream & `CopilotThinkingCard`
- **User Bubble:** Staged/sent `AttachmentPreviewChip`s above, gradient primary bubble (`borderRadiusDirectional` with `bottomEnd: 6dp`), timestamp + Copy action (`Icons.copy`, toast `Copied`).
- **Live `CopilotThinkingCard` (while `sending == true`):**
  - Before first `delta`: animated top shimmer hairline, rotating phase headline (`activeTools.last` label → `deepThinkingLive` if `thinkingText` present → `warmingModel` if `streamPhase == 'warming_model'` → cycling 1.8s phases `memory` / `ledger` / `synthesis`), live elapsed timer (`0.0s` incrementing every 200ms), collapsible `Copilot Reasoning` trace (`thinkingText`), completed tool chips (emerald + `evidenceCount` badge) & active tool chips (animated 3-bar wave indicator), and 3-line skeleton shimmer.
  - Once `streamingText` arrives: switches to `Live response` card with pulsing indicator dot, completed tool badges, and streaming `CopilotMarkdown` with blinking cursor.
- **Assistant Card (`CopilotMessageBubble`):**
  - Header: `AFAB Copilot`, `modelId` mono pill, `Deep Analysis` pill (if `reasoningMode == "deep"`), `<seconds>s` latency, `HH:mm` timestamp.
  - Collapsible `Copilot Reasoning` accordion (collapsed by default on completed messages).
  - `toolsUsed` emerald pill strip (mapped via 16 localized tool keys + fallback).
  - `CopilotMarkdown` body (`flutter_markdown_plus`).
  - `CopilotChartCard` list (`fl_chart` Bar / Line / Area / Donut + CSV export).
  - `actionDrafts` list dispatching by `draft.actionType`:
    - `CREATE_TRANSACTION` / `CREATE_INVOICE` / `CREATE_BUDGET` → `CopilotActionDraftCard`
    - `PAYMENT_REMINDER` → `CopilotReminderCard`
    - `SAVE_MEMORY` → `CopilotMemoryProposalCard`
  - `Verified Sources & Evidence` grid (`1 col` phone, `2 col` tablet) with color-coded type badges (`INVOICE` rose, `TRANSACTION` primary, `BUDGET` emerald, `MEMORY` indigo, `CUSTOMER` sky).
  - Footer: `dataCoverage` status (`coverageRag` vs `coveragePartial`), `Copy` button, `Regenerate` button (only on latest assistant message when `!sending`), and `totalTokens` badge.
- **Suggested Follow-Up Chips:** Wrap list of pill buttons below the last message when `!sending && suggestedFollowUps.isNotEmpty`.
- **Jump to Latest FAB:** Appears at bottom-end when scroll offset is `> 140dp` from bottom.

### 6.5 Two-Zone Command Composer
- **Staged Attachments Row:** Horizontal wrap of `AttachmentPreviewChip` (max 3) with image thumbnail or file-type icon, file size, and remove (`X`) button.
- **Live Voice Interim Pill:** Visible while `speech_to_text` is actively listening (`Listening: <interimVoice>`).
- **Zone 1 (Input):** Multiline `TextField` (`maxLength: 4000`, `minLines: 1`, `maxLines: 5`, `textInputAction: TextInputAction.newline`), auto-detecting directionality or aligned to UI locale.
- **Zone 2 (Action Bar):**
  - Left: `Attach` button (`Paperclip`, shows spinner during staging upload; opens Camera / Photo Library / File Picker bottom sheet) + segmented `Fast` (`Zap`) / `Deep` (`Brain`) mode toggle.
  - Right: `VoiceDictationButton` (`EN` / `FR` / `TN` language cycler + Mic toggle) + `Send` (`ArrowUp`, disabled if both text and staged attachments are empty) or `Stop` (`Square` red button during active SSE stream).

---

## 7. State Management and Data Flow

### Riverpod Providers (`lib/features/ai/presentation/providers/`)
| Provider | Type | Lifecycle & Responsibility |
|---|---|---|
| `aiStatusProvider` | `AsyncNotifierProvider<AiStatusNotifier, AiStatus>` | Fetches `GET /ai/status`, tracks `indexedChunks`, `approvedMemories`, `quota`. Invalidated on business switch, sync, or chat turn completion. |
| `aiHealthProvider` | `NotifierProvider<AiHealthNotifier, AiHealthState>` | Polls `GET /ai/health?fresh=false` every 8s while `AppLifecycleState.resumed`; exposes `checkNow()` (`fresh=true`). Tracks `backendConnected`. |
| `aiPulseProvider` | `FutureProvider<AiPulse>` | Fetches `GET /ai/pulse` (cached 60s; invalidated on transaction/invoice/budget mutations or AI draft approvals). |
| `aiConversationsProvider` | `AsyncNotifierProvider<AiConversationsNotifier, List<AiConversationSummary>>` | Lists, filters (`searchQueryProvider`), and deletes conversations; scoped to `activeBusinessIdProvider`. |
| `aiStudioControllerProvider` | `NotifierProvider<AiStudioController, AiStudioState>` | Manages `activeConversationId`, `activeLanguage`, `messages`, `reasoningMode`, `stagedAttachments`, `sending`, `streamPhase`, `streamingText`, `thinkingText`, `activeTools`, `completedTools`, `suggestedFollowUps`, `quotaExhaustedMsg`, `chatError`, and active `CancelToken`. |
| `aiMemoryProvider` | `AsyncNotifierProvider.family<AiMemoryNotifier, List<BusinessMemory>, String>` | Shared with `AI-03` for header badge count and memory proposal refresh. |

### Mutation & Cache Invalidation Rules
- **Turn `done`:** Updates `messages`, `activeConversationId`, `activeLanguage`, `suggestedFollowUps`, `quota`, and triggers background refresh of `aiStatusProvider` + `aiConversationsProvider`.
- **Draft Approved:**
  - `CREATE_TRANSACTION` → invalidates `dashboardProvider`, `transactionsProvider`, `expensesProvider`, `revenueProvider`, `budgetsProvider`, `aiPulseProvider`.
  - `CREATE_INVOICE` → invalidates `dashboardProvider`, `invoicesProvider`, `customersProvider`, `aiPulseProvider`.
  - `CREATE_BUDGET` → invalidates `dashboardProvider`, `budgetsProvider`, `aiPulseProvider`.
  - `SAVE_MEMORY` → invalidates `aiMemoryProvider`, `aiStatusProvider`.
- **Business Switch / Logout:** All AI providers watch `activeBusinessIdProvider` and `sessionProvider` so switching workspace cancels any in-flight `CancelToken` and resets conversation state immediately.

---

## 8. API Contracts and Data Mapping

### Endpoints Consumed by `AI-01`
| Endpoint | Method | Auth / Guard | Request | Response |
|---|---|---|---|---|
| `/api/v1/ai/status?fresh=` | `GET` | JWT | `fresh: bool` | `AiStatusDTO` (`enabled`, `ollamaReachable`, `chatModel`, `chatModelReady`, `chatModelLoaded`, `embedModel`, `embedModelReady`, `busy`, `latencyMs`, `checkedAt`, `indexedChunks`, `approvedMemories`, `quota`) |
| `/api/v1/ai/health?fresh=` | `GET` | Public | `fresh: bool` | `AiHealthDTO` |
| `/api/v1/ai/health/stream` | `GET` | Public | `Accept: text/event-stream` | SSE `event: health` every 4s (optional alternative to 8s polling) |
| `/api/v1/ai/pulse` | `GET` | JWT | — | `AiPulseDTO` (`monthRevenue`, `monthExpenses`, `monthNetProfit`, `overdueTotal`, `overdueCount`, `missingReceiptCount`, `highCount`, `mediumCount`, `infoCount`, `alerts[]`) |
| `/api/v1/ai/index/sync` | `POST` | JWT + `EDITABLE` | — | `AiIndexSyncResponseDTO` (`indexedCount`, `skippedUnchanged`, `embeddingsGenerated`, `embeddingAvailable`, `message`) |
| `/api/v1/ai/conversations` | `GET` | JWT | — | `List<AiConversationSummaryDTO>` |
| `/api/v1/ai/conversations/{id}` | `GET` | JWT | Path `id: UUID` | `AiConversationDetailDTO` (with `messages[]`) |
| `/api/v1/ai/conversations/{id}` | `DELETE` | JWT + `EDITABLE` | Path `id: UUID` | `204 No Content` |
| `/api/v1/ai/attachments/stage` | `POST` | JWT + `EDITABLE` | `multipart/form-data` part `file` (`<= 10 MB`) | `201 AiAttachmentDTO` |
| `/api/v1/ai/attachments/{id}/preview` | `GET` | JWT (biz-scoped) | Path `id: UUID` | `200 byte[]` (`Cache-Control: private, max-age=300`) |
| `/api/v1/ai/chat/stream` | `POST` | JWT + `EDITABLE` | `AiChatRequest { message, conversationId?, locale, reasoningMode, attachmentIds?, screenContext? }` | `200 text/event-stream` (see events below) |
| `/api/v1/ai/chat` | `POST` | JWT + `EDITABLE` | `AiChatRequest` | `200 AiChatResponseDTO` (non-streaming fallback) |
| `/api/v1/ai/actions/approve-transaction` | `POST` | JWT + `EDITABLE` | `ApproveTransactionDraftRequest` | `200 AiActionDraftDTO` (`APPROVED`) |
| `/api/v1/ai/actions/approve-invoice` | `POST` | JWT + `EDITABLE` | `ApproveInvoiceDraftRequest` | `200 AiActionDraftDTO` (`APPROVED`) |
| `/api/v1/ai/actions/approve-budget` | `POST` | JWT + `EDITABLE` | `ApproveBudgetDraftRequest` | `200 AiActionDraftDTO` (`APPROVED`) |
| `/api/v1/ai/actions/approve-memory` | `POST` | JWT + `EDITABLE` | `ApproveMemoryDraftRequest` | `200 AiActionDraftDTO` (`APPROVED`) |
| `/api/v1/ai/messages/{messageId}/drafts/{draftId}/dismiss` | `PATCH` | JWT + `EDITABLE` | Path `messageId: UUID`, `draftId: String` | `200 AiActionDraftDTO` (`DISMISSED`) |
| `/api/v1/categories` | `GET` | JWT | — | `List<CategoryDTO>` (for Transaction/Budget draft dropdowns) |
| `/api/v1/customers?page=0&size=100` | `GET` | JWT | — | `CustomerPageDTO` (for Invoice draft dropdown) |

### SSE Event Contract (`POST /api/v1/ai/chat/stream`)
- `event: status` → `{"phase": "warming_model" | "retrieving" | "generating", "conversationId"?, "activeLanguage"?, "reasoningMode"?}`
- `event: ping` → `{"ts": <epochMs>}` (emitted every `6s` by `HEARTBEAT_SCHEDULER`)
- `event: thought` → `{"text": "<delta>"}` (deep mode only)
- `event: tool_start` → `{"tool": "<toolName>"}`
- `event: tool_done` → `{"tool": "<toolName>", "evidenceCount": int}`
- `event: delta` → `{"text": "<markdownChunk>"}`
- `event: replace` → `{"text": "<fullRepairedMarkdown>"}` (when `AiLanguageResolver.needsLanguageRepair()` triggers)
- `event: done` → full `AiChatResponseDTO` JSON
- `event: error` → `{"code": "PLAN_LIMIT_REACHED" | "BUSINESS_READ_ONLY" | "AI_SERVICE_UNAVAILABLE" | "AI_ERROR", "message": "..."}`

### Freezed / Decimal Mapping Rules
- `AiPulse.monthRevenue`, `monthExpenses`, `monthNetProfit`, `overdueTotal`, `PulseAlert.metricValue`, `AiEvidenceItem.amount`: mapped via `DecimalJsonConverter`.
- `AiChartSpec.data`: numeric values parsed cleanly into `double` for `fl_chart` coordinates and `Decimal` for `MoneyFormatter` tooltips.
- `AiActionDraft.payload`: preserved as `Map<String, dynamic>`, with `amount`, `unitPrice`, `quantity`, `taxRate`, `discountAmount`, `totalAmount` formatted using `Decimal` in editable draft forms.

---

## 9. Validation, Business Rules, and Edge Cases

1. **Message Input:** Max `4000` characters (`@Size(max = 4000)` in `AiChatRequest.java`). Blank text is allowed **only** when `stagedAttachments.isNotEmpty` (backend generates localized `defaultAttachmentPrompt`).
2. **Attachment Limits:**
   - Max **3 attachments per turn** (`MAX_ATTACHMENTS_PER_TURN = 3`). Exceeding 3 shows snackbar/inline warning and ignores excess files.
   - Max **10 MB per file** (`10,485,760` bytes enforced by Spring multipart & `AiAttachmentService`). Mobile validates file size before uploading.
   - Allowed MIME / extensions (magic-byte validated on server): `image/jpeg`, `image/png`, `image/webp`, `application/pdf`, `.xlsx`, `.csv`, `.txt`, `.json`, `.md`. Reject binary files containing NUL bytes (`0x00`) for text extensions.
   - Staged attachments expire after **24 hours** (`expiresAt`); if expired before send, backend returns `400` prompting re-attachment.
3. **Action Draft Validation:**
   - `CREATE_TRANSACTION`: `amount > 0` (`@DecimalMin("0.0001")`), `description` non-blank (`<= 255`), `originalCurrency` 3-char ISO, `transactionDate` valid ISO date, `notes` `<= 1000`.
   - `CREATE_INVOICE`: at least 1 line item (`@NotEmpty`), `issueDate` and `dueDate` required, `notes` `<= 2000`.
   - `CREATE_BUDGET`: `name` non-blank (`<= 150`), `amount > 0`, `alertThresholdPercent` clamped `10..100`, `description` `<= 1000`.
   - `SAVE_MEMORY`: `title` non-blank (`<= 160`), `content` non-blank (`<= 2000`).
4. **Plan & Feature Entitlements:**
   - `ai.chat.tokens_per_month`, `ai.chat.queries_per_month`, and `ai.deep_reasoning` (on `reasoningMode == "deep"`) are checked server-side before inference.
   - On `403 PLAN_LIMIT_REACHED` (either HTTP response or SSE `error` event): roll back optimistic user message, restore `input` text, display `Plan Quota Exhausted` banner + `Upgrade Plan` CTA, and if `reasoningMode == "deep"`, automatically revert toggle to `"fast"`.
5. **Read-Only Workspace Guard (`403 BUSINESS_READ_ONLY`):**
   - If `activeBusiness.editable == false`: disable composer send, attachments, sync index, conversation delete, and draft approve/dismiss buttons; display clear Read-Only workspace banner.
6. **Stream Cancellation & Incomplete Streams:**
   - Tapping `Stop` cancels `CancelToken`, closes SSE stream cleanly without error toast, and clears transient thinking/tool state.
   - If stream closes unexpectedly without a `done` frame and wasn't aborted (`!cancelToken.isCancelled`), display `INCOMPLETE_STREAM` error banner and restore the user prompt into the composer so nothing is lost.
7. **Sequential Concurrency (`maxConcurrentRequests = 1`):**
   - Disable Send while `sending == true`. If Ollama is busy from another request (`health.busy == true`), show status in `AiModelStatusBadge` and rely on `6s` SSE `ping` frames + `130s` `sseDio` receive timeout.

---

## 10. Loading, Empty, Error, and Offline States

| State | UI Presentation | Recovery Action |
|---|---|---|
| **Initial Loading** | Centered `AfabLoader` (`Loading AFAB Copilot...`) inside canvas; skeleton shimmer on Pulse strip | Auto-resolves on `/ai/status`, `/ai/conversations`, `/ai/memory` completion |
| **Empty Conversation** | `CopilotWelcome` (Hero, Live Pulse strip, 2x2 Bento grid, Quick Pills) | Tap any prompt card, Morning CFO Brief, or type/dictate/attach |
| **Empty History List** | Centered text (`No saved conversations yet for this business.`) | `New Chat` CTA |
| **Ollama / Model Offline** | Amber banner below Studio Header with exact `ollama pull` LTR command | `Check Now` in `AiModelHealthSheet` |
| **Plan Quota Exhausted** | Red banner with `quotaExhaustedTitle`, server message, and `Upgrade Plan` CTA | Navigate to `PlansAndSubscriptionScreen` |
| **Stream / Network Error** | Dismissible inline red alert banner (`chatError`) + `Toast`; restores unsent text into input | Edit/retry send |
| **Offline (`connectivity_plus`)** | Global `OfflineBanner` + `AiModelStatusBadge` (`Backend Offline`); composer shows disabled offline hint while reading cached conversations remains available | Auto-reconnects via `AiHealthNotifier` when network returns |
| **Attachment Upload Error** | Toast error (`uploadFailed` or server validation message); staged chip not added | Retry pick/capture |

---

## 11. Localization and RTL Behavior

- **UI Localization (`app_en.arb` & `app_ar.arb`):** Migrates all `227` keys from `Web/project/frontend/messages/en/ai.json` and `messages/ar/ai.json` plus hardcoded Web labels (`EXPENSE`, `INCOME`, `Copy`, `Copied`, `CSV`, `Email`, `WhatsApp`, `Uncategorized`, `Overall Business Expenses`, `Dismiss error`).
- **Polyglot Per-Message Directionality (Critical Rule from `08_LOCALIZATION_AND_RTL.md`):**
  - AI response language (`EN`, `FR`, `AR_MSA`, `AR_DERJA_SCRIPT`, `AR_DERJA_ARABIZI`) is **independent** of the app UI locale (`en` / `ar`).
  - `MessageDirectionResolver` sets `Directionality(textDirection: ...)` per bubble:
    - `TextDirection.rtl` if `responseLanguage` is `AR_MSA` or `AR_DERJA_SCRIPT`, or if Arabic Unicode chars (`\u0600-\u06FF`) constitute `>= 30%` of letters in a user message.
    - `TextDirection.ltr` if `EN`, `FR`, `AR_DERJA_ARABIZI`, or predominantly Latin characters.
- **RTL Isolation & Digits:**
  - All `MoneyText` figures, percentages, token counts, latencies, `ollama pull` commands, fenced Markdown code blocks, and `fl_chart` time-series X-axes force `TextDirection.ltr` with Western Arabic digits (`0-9`) and `FontFeature.tabularFigures()`.
  - Composer input dynamically adapts `textDirection` to typed script (`TextDirection.rtl` when Arabic UI or Arabic text detected, `TextDirection.ltr` for Latin/Arabizi).
  - Directional icons (`ArrowUpRight`, `ChevronRight`, drawer slide offsets) use `EdgeInsetsDirectional`, `BorderRadiusDirectional`, and `matchTextDirection: true`.

---

## 12. Responsive and Adaptive Behavior

| Breakpoint | Layout & Interaction Adaptation |
|---|---|
| `compactSmall` (`< 360dp`) | `New Chat`, `Sync Index`, and `Memory` header buttons collapse labels to icon + compact badge (`(N)`); Welcome Bento stacks 1 column; Evidence grid 1 column; `fl_chart` height `200dp`; `Fast`/`Deep` pills compact padding. |
| `compact` (`360–599dp`) | Modal start-edge `Drawer` for conversation history + quota meter; Welcome Bento 1–2 col wrap; Evidence 1 column; `CopilotActionDraftCard` stacks form fields vertically; `BusinessMemory` pushes full screen (`AI-03`). |
| `medium` (`600–839dp`) | App wrapped in collapsed `72dp` `NavigationRail`; Conversation Drawer still modal (`320dp`); Welcome Bento 2x2 grid; Evidence 2-column grid; `CopilotActionDraftCard` 2-column grid; `BusinessMemory` opens as modal side sheet (`440dp`). |
| `expanded` (`>= 840dp` / `>= 1024dp`) | Extended `248dp` `NavigationRail`; collapsible inline `280dp` Conversation Sidebar + pinned Quota Meter; centered `maxWidth: 768dp` message canvas & composer; at `>= 1024dp`, `BusinessMemory` can dock inline as a `400dp` end-edge side pane. |
| **Keyboard & Safe Area** | `Scaffold(resizeToAvoidBottomInset: true)` + `SafeArea` bottom padding so the Two-Zone Composer glides smoothly above the soft keyboard and clears iOS Home Indicator / Android gesture bar. |

---

## 13. Accessibility and Testing Criteria

### Accessibility
- Minimum `48x48dp` touch targets on all header icon buttons, `Send`/`Stop`, `Mic`, `Attach`, `Approve`/`Dismiss`, and conversation delete buttons (never rely on desktop hover states).
- `Semantics` labels on `AiModelStatusBadge` (announcing full runtime/model state), `VoiceDictationButton` (active language + recording state), `fl_chart` summaries, and progress bar (`Monthly AI tokens X of Y used`).
- Respect `MediaQuery.disableAnimationsOf(context)` by disabling shimmer/wave/ping animations.
- WCAG AA contrast (`>= 4.5:1`) verified across Light (`#F8F9FB`) and all 4 Dark presets (`midnight`, `oled`, `slate`, `charcoal`).

### Mandatory Test Coverage
1. **Unit Tests (`test/unit/ai/`):**
   - `SseParser`: handles multi-chunk frame splits (`\r\n\r\n` & `\n\n`), `status`, `ping`, `thought`, `tool_start`, `tool_done`, `delta`, `replace`, `done`, `error` (`PLAN_LIMIT_REACHED`, `BUSINESS_READ_ONLY`), and unexpected EOF (`INCOMPLETE_STREAM`).
   - `MessageDirectionResolver`: verifies `AR_MSA`/`AR_DERJA_SCRIPT` → RTL, `EN`/`FR`/`AR_DERJA_ARABIZI` → LTR regardless of app locale.
   - `AiActionDraft` & `AiStatus` JSON/Decimal parsing (including unlimited quota `-1`, null `charts`/`actionDrafts`).
2. **Widget Tests (`test/widget/ai/ai_copilot_screen_test.dart`):**
   - Loading, Welcome + Pulse strip, populated polyglot thread, Deep thinking card, Bar/Line/Area/Donut `fl_chart` cards, all 5 draft card types (`Approve` + `Dismiss`), `AttachmentPreviewChip` (3-file cap & 10 MB rejection), `VoiceDictationButton` (EN/FR/TN cycle), Ollama offline banner, Quota exhausted banner, `320dp`/`390dp`/`840dp`/`1280dp` × Light/Dark × EN/AR zero-overflow assertions.
3. **Integration Test (`integration_test/ai_copilot_flow_test.dart`):**
   - Stage receipt image → send SSE turn → receive `tool_start`/`tool_done`/`delta`/`done` → edit & approve `CREATE_TRANSACTION` draft → verify receipt promoted & transaction/dashboard providers invalidated.

---

## 14. Dependencies and Risks

### Package Dependencies
- `flutter_riverpod: ^3.5.0`, `go_router: ^18.1.3`, `dio: ^5.9.2`, `decimal: ^3.2.6`, `intl: ^0.20.2`, `fl_chart: ^1.3.1`, `flutter_markdown_plus: ^1.0.0`, `lucide_icons_flutter: ^3.1.25`, `image_picker: ^1.2.4`, `file_picker: ^13.4.1`, `flutter_image_compress`, `speech_to_text: ^7.5.0`, `share_plus: ^13.3.1`, `path_provider: ^2.1.5`, `url_launcher: ^6.3.3`, `shimmer: ^3.0.0`, `connectivity_plus: ^6.1.0`.

### Technical Risks & Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| **Cellular Network Drop During 30–90s Deep Mode Inference** | SSE stream disconnects mid-thought when Ollama warms GPU (`10–15s`) or executes 6 tool rounds. | Backend sends `ping` every `6s`; configure `sseDio.receiveTimeout = 130s`; show live `warming_model` + elapsed timer and clean retry restoring prompt. |
| **`ar-TN` Speech-to-Text Engine Availability** | Android/iOS OS speech recognizers may lack `ar-TN` locale pack on some devices, causing `speech_to_text` initialization error. | Query `speech.locales()` at runtime; gracefully fall back `ar-TN` → `ar-SA`/`ar` or show clear localized hint when unavailable. |
| **Markdown Streaming Reflow Jitter at 60fps** | Re-parsing full Markdown on every 24-char `delta` frame can drop frames on low-end Android phones. | Coalesce incoming `delta` chunks over a `50ms` `Timer` tick before rebuilding `flutter_markdown_plus`. |
| **Attachment Memory Pressure** | Decoding multiple full-res camera photos or preview blobs can spike RAM. | Compress camera/gallery images to `<= 1024px` JPEG before staging; dispose `Uint8List`/image caches cleanly on chip removal or screen dispose. |
| **Backend `maxConcurrentRequests = 1`** | Rapid back-to-back taps or concurrent drawer + studio sends could queue/fail. | Lock composer `sending` state globally across `AiCopilotScreen` and `GlobalCopilotSheet` or surface `busy` badge clearly. |
