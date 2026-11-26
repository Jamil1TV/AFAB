# AI-02 — Global Contextual Copilot Sheet (`GLOBAL_COPILOT_SHEET.md`)

> **Domain:** AI Copilot v2 (`lib/features/ai/`)
> **Spec ID:** `AI-02`
> **Target Flutter File:** `lib/features/ai/presentation/global_copilot_sheet.dart`
> **Presentation:** Modal Draggable Bottom Sheet (`< 600dp`) / Directional End Side Sheet (`>= 600dp`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `AI-02` |
| **Screen Name** | Global Contextual Copilot Sheet |
| **Flutter Widget** | `GlobalCopilotSheet` (`ConsumerStatefulWidget`) + `copilotLauncherProvider` |
| **Route Path** | Modal overlay hosted by `AdaptiveShell` (accessible from any non-`/dashboard/ai` authenticated route) |
| **Navigation Role** | Contextual quick-assist overlay triggered from AppBar, Dashboard KPI cards, AI Pulse insights, Invoices, Budgets, and Reports |
| **Access Scope** | Authenticated + Verified + Onboarded user; `X-Business-Id` tenant-scoped (`READ_ONLY` guard applies to writes) |
| **Priority** | `P2` (Roadmap task `P5-02`) |

---

## 2. Web Source Reference & Parity Status

| Web Source File | Role in Web | Web Parity Status | Mobile Adaptation |
|---|---|---|---|
| `Web/project/frontend/components/ai/GlobalCopilotDrawer.tsx` | Slide-over global drawer (`max-w-xl`, 565 lines): header, `Full View` link, empty quick starters, SSE stream, draft cards, two-zone composer | Implemented and Connected | `DraggableScrollableSheet` on Phone (`< 600dp`), directional Side Sheet (`480–560dp`) on Tablet (`>= 600dp`) |
| `Web/project/frontend/components/ai/CopilotContextProvider.tsx` | Global `openCopilot(OpenCopilotOptions)` context, `launchRequest` nonce, `Ctrl+K` / `Cmd+K` shortcut | Implemented and Connected | Riverpod `copilotLauncherProvider` (`openCopilot(prompt, autoSend, screenContext, reasoningMode)`) + hardware keyboard `Ctrl/Cmd+K` shortcut on tablets |
| `Web/project/frontend/components/dashboard/DashboardHeader.tsx` | AppBar `Ask Copilot` pill button (hidden when pathname starts with `/dashboard/ai`) | Implemented and Connected | Persistent `ShellAppBar` trailing `Sparkles` icon button (hidden on Tab 2 `AiCopilotScreen`) |
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/page.tsx` | 4 `KpiCard.onAskAi` triggers (`revenue`, `expenses`, `profit`, `cashflow`) with `autoSend: true` | Implemented and Connected | `AfabKpiCard.onAskAi` callbacks passing exact `screenContext` & localized/structured prompts |
| `Web/project/frontend/components/dashboard/AIInsightsCard.tsx` | `Investigate in Copilot` CTA on each `PulseAlert` (`screenContext: { source: "AIInsightsCard", alertType }`) | Implemented and Connected | Native pulse alert card action invoking `openCopilot` with `al.copilotPrompt` |
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/invoices/page.tsx` | `Draft AI Reminder` `Sparkles` button on `OVERDUE`, `UNPAID`, `PARTIALLY_PAID` invoices | Implemented and Connected | Invoice card/detail `Draft AI Reminder` action passing `{ page: "invoices", invoiceNumber }` |
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/budgets/page.tsx` | `Ask AI` `Sparkles` button on each Budget card | Implemented and Connected | Budget card `Ask AI` action passing `{ page: "budgets", budgetId, budgetName }` |
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/reports/page.tsx` | `Explain Report` header button | Implemented and Connected | Reports AppBar/action `Explain Report` passing `{ page: "reports", tab: activeTab, period }` |

---

## 3. Purpose and User Value

`GlobalCopilotSheet` brings AFAB Copilot v2 directly into any financial workflow without forcing the user to abandon their current screen, scroll position, or filters. By carrying structured `screenContext` metadata (which backend `AiCopilotService.buildUiContextBlock()` injects as `<ui_context>` into the system prompt) and optional `autoSend: true` prompts, users can:

1. Tap `Ask Copilot` from the Shell AppBar to ask a quick question, snap a receipt, or dictate a voice note from anywhere in the app.
2. Tap `Ask AI` on a Dashboard KPI card, Pulse anomaly alert, Budget card, or Financial Report to get an immediate, context-grounded explanation and `fl_chart` breakdown.
3. Tap `Draft AI Reminder` on an overdue/unpaid Invoice to instantly generate an editable Email + WhatsApp `CopilotReminderCard` grounded in that exact invoice's number, due date, and remaining balance.
4. Escalate any multi-turn sheet session into the full-featured `AiCopilotScreen` (`AI-01`) with a single tap on `Full View`.

---

## 4. Navigation, Entry Points, and Exit Paths

### All Verified Entry Points & `OpenCopilotOptions` Payloads
| Entry Point | Source Screen | `autoSend` | `screenContext` | Prompt Seed |
|---|---|---|---|---|
| **Shell AppBar `Ask Copilot`** | Any non-AI route (`ShellAppBar`) | `false` | Optional `{ page: currentRouteName }` | `null` (shows empty starters or existing drawer thread) |
| **Hardware Shortcut `Ctrl+K` / `Cmd+K`** | Tablet / keyboard on non-AI routes | `false` | `null` | Toggles sheet open/closed |
| **KPI Card `Ask AI` (Revenue / Expenses / Profit / Cashflow)** | `DashboardScreen` | `true` | `{ page: "dashboard", metric: "revenue" \| "expenses" \| "profit" \| "cashflow", period }` | Structured prompt with metric value, change %, and period |
| **Pulse Alert `Investigate in Copilot`** | `DashboardScreen` (`AIInsightsCard`) | `true` | `{ source: "AIInsightsCard", alertType: al.type }` | `al.copilotPrompt` |
| **Invoice `Draft AI Reminder`** | `InvoicesScreen` / `InvoiceDetailsScreen` (`OVERDUE`/`UNPAID`/`PARTIALLY_PAID`) | `true` | `{ page: "invoices", invoiceNumber: inv.invoiceNumber }` | `"Draft an Email & WhatsApp payment reminder for invoice <num> (<customer>, balance <amt> <cur>, due <dueDate>)."` |
| **Budget `Ask AI`** | `BudgetsScreen` | `true` | `{ page: "budgets", budgetId: b.id, budgetName: b.name }` | `"Analyze my budget \"<name>\" (<pct>% consumed: <spent> / <limit> <cur>, <start> to <end>) and list the transactions driving it."` |
| **Reports `Explain Report`** | `ReportsScreen` | `true` | `{ page: "reports", tab: activeTab, period }` | `"Analyze my <TAB> financial report for period \"<period>\" and explain key changes, anomalies, and recommendations."` |

### Exit Paths
- **Dismiss Sheet (`X` button, backdrop tap, or drag-down):** Closes the modal while preserving the sheet's in-memory `conversationId` and `messages` for the current business session (matching Web `GlobalCopilotDrawer` state).
- **`Full View` (`openWorkspace` button):** Closes `GlobalCopilotSheet` and navigates via `GoRouter` to `/dashboard/ai` (Tab 2), passing `conversationId` if one was created in the sheet so `AI-01` loads the full conversation via `GET /api/v1/ai/conversations/{id}`.
- **Approved Draft `View Record` / Evidence Chip Tap:** Closes sheet and navigates to the target record's native mobile screen (`/dashboard/transactions`, `/dashboard/invoices`, `/dashboard/budgets`, `/dashboard/ai/memory`, etc.).

---

## 5. Layout and Visual Hierarchy

### 5.1 Phone Presentation (`width < 600dp`)
`showModalBottomSheet` with `DraggableScrollableSheet(initialChildSize: 0.88, minChildSize: 0.50, maxChildSize: 0.96)`:
```text
┌──────────────────────────────────────────────────────┐
│                   ─── (Drag Handle)                  │
│ [Sparkles] AFAB Copilot         [Full View ↗]  [ ✕ ] │
│            Quick analysis, drafts & files            │
├──────────────────────────────────────────────────────┤
│ [Context Pill (optional, e.g., Invoice INV-2026-01)] │
├──────────────────────────────────────────────────────┤
│ Scrollable Message Canvas                            │
│  ├─ If empty & !sending:                             │
│  │   Dashed Inset Card:                              │
│  │   "Ask AFAB Copilot anything" + description       │
│  │   [Morning CFO Brief]  [Overdue Invoices & Cash]  │
│  └─ Else:                                            │
│      CopilotMessageBubble list                       │
│      + [If sending] CopilotThinkingCard              │
│      + [If !sending] Follow-up suggestion pills      │
├──────────────────────────────────────────────────────┤
│ Two-Zone Composer (SafeArea + viewInsets.bottom)     │
│  ├─ Staged attachment chips (max 3) + interim voice  │
│  ├─ Zone 1: Multiline TextField                      │
│  └─ Zone 2: [📎] [⚡Fast | 🧠Deep]       [TN 🎤] [↑/■]│
│  Supported hint: JPG, PNG, WEBP, PDF, XLSX, CSV...   │
└──────────────────────────────────────────────────────┘
```

### 5.2 Tablet Presentation (`width >= 600dp`)
- Directional slide-over modal sheet anchored to `AlignmentDirectional.centerEnd` (`maxWidth: 480dp` on `600–839dp`, `540dp` on `>= 840dp`), full viewport height, dimmed backdrop (`Colors.black54`), `1px` `border` on start edge, matching Web `GlobalCopilotDrawer`.

---

## 6. UI Components and Interactive Controls

1. **Sheet Header:**
   - Leading: `32x32dp` `Sparkles` icon tile (`primary` 15% fill, 25% border) + `AFAB Copilot` (`drawerTitle`) + `Quick financial analysis, drafts & files` (`drawerSubtitle` adapted for mobile without desktop `Ctrl+K` text on touch phones).
   - Trailing: `Full View` outlined chip (`ExternalLink` icon) + `Close` icon button (`X`).
2. **Empty State Card (`messages.isEmpty && !sending`):**
   - `AfabInsetPanel` with dashed border, `Sparkles` icon, `drawerEmptyTitle`, `drawerEmptyDesc`, and 2 starter pills:
     - `Morning CFO Brief` → sends `morningBriefPrompt`.
     - `Overdue Invoices & Cash` → sends `prompts.invoicesText`.
3. **Message Canvas:**
   - Reuses shared `CopilotMessageBubble` (per-message RTL/LTR, Markdown, `fl_chart`, all 5 action draft cards including `CopilotReminderCard` and `CopilotMemoryProposalCard`, evidence grid, Copy button) and `CopilotThinkingCard` (live phase shimmer, timer, thinking trace, tool wave pills, streaming Markdown).
   - Note: Web `GlobalCopilotDrawer` omits the `Regenerate` prop on `CopilotMessageBubble` (line 358); mobile may optionally pass `onRegenerate` for the latest assistant message or keep exact Web parity.
4. **Follow-Up Chips:** Horizontal wrap of compact pill buttons below the latest response.
5. **Two-Zone Composer:**
   - Identical shared `CopilotComposer` widget used in `AI-01`, configured in compact mode (`maxLines: 4`, compact `Attach` icon-only on narrow screens, `Fast`/`Deep` segmented toggle, `VoiceDictationButton`, `Send`/`Stop` button, and single-line `supportedHint` caption below).
   - Attachment button opens native Camera / Photo Library / File Picker bottom sheet (`<= 10 MB`, max 3).

---

## 7. State Management and Data Flow

### Riverpod Providers
1. **`copilotLauncherProvider` (`NotifierProvider<CopilotLauncherNotifier, CopilotLaunchRequest?>`):**
   - Exposes `openCopilot({String? prompt, bool autoSend = false, Map<String, String>? screenContext, AiReasoningMode? reasoningMode})`, `closeCopilot()`, `clearLaunchRequest()`.
   - `AdaptiveShell` listens to `copilotLauncherProvider` to present/dismiss `GlobalCopilotSheet`.
2. **`globalCopilotSheetControllerProvider` (`NotifierProvider<GlobalCopilotSheetController, GlobalCopilotSheetState>`):**
   - Persists `conversationId`, `messages`, `reasoningMode`, `stagedAttachments`, `sending`, `streamingText`, `thinkingText`, `streamPhase`, `activeTools`, `completedTools`, `followUps`, `pendingScreenContext`, and `CancelToken`.
   - Watches `activeBusinessIdProvider` and `sessionProvider`: resets all drawer state and cancels any active SSE stream whenever the user switches business or signs out.
3. **`launchRequest` Consumption Lifecycle:**
   - When sheet opens with a non-null `launchRequest`:
     1. Apply `launchRequest.reasoningMode` if provided.
     2. Store `launchRequest.screenContext` in `pendingScreenContext`.
     3. If `launchRequest.prompt` is non-empty:
        - If `launchRequest.autoSend == true`: immediately execute `send(promptOverride: launchRequest.prompt, modeOverride: launchRequest.reasoningMode, screenContextOverride: launchRequest.screenContext)` and clear `pendingScreenContext`.
        - Else (`autoSend == false`): populate composer `TextEditingController` with `launchRequest.prompt` and focus input.
     4. Call `clearLaunchRequest()` immediately so sheet rebuilds do not re-trigger the prompt.

---

## 8. API Contracts and Data Mapping

`GlobalCopilotSheet` uses the exact same `AiRepository` methods as `AI-01`, with `screenContext` populated in `AiChatRequest`:

| Endpoint | Method | Purpose in `AI-02` |
|---|---|---|
| `/api/v1/ai/chat/stream` | `POST` | Streams SSE response with `AiChatRequest { message, conversationId, locale, reasoningMode, attachmentIds, screenContext }` |
| `/api/v1/ai/attachments/stage` | `POST` | Stages Camera/Gallery/Document attachments (`multipart/form-data`, `<= 10 MB`, max 3) |
| `/api/v1/ai/attachments/{id}/preview` | `GET` | Loads thumbnail preview for staged/message image chips and transaction draft cards |
| `/api/v1/ai/actions/approve-transaction` | `POST` | Approves `CREATE_TRANSACTION` draft + promotes staged receipt |
| `/api/v1/ai/actions/approve-invoice` | `POST` | Approves `CREATE_INVOICE` draft |
| `/api/v1/ai/actions/approve-budget` | `POST` | Approves `CREATE_BUDGET` draft |
| `/api/v1/ai/actions/approve-memory` | `POST` | Approves `SAVE_MEMORY` draft |
| `/api/v1/ai/messages/{messageId}/drafts/{draftId}/dismiss` | `PATCH` | Dismisses pending draft |

### Backend `screenContext` Handling (`AiCopilotService.buildUiContextBlock`)
- Accepts `Map<String, String>` up to **12 entries** (`count++ < 12` in `AiCopilotService.java:923`).
- Wrapped inside `<ui_context> ... </ui_context>` and treated strictly as untrusted context data (cannot override system instructions).

---

## 9. Validation, Business Rules, and Edge Cases

1. **Duplicate Launch Prevention:** `CopilotLaunchRequest` carries a monotonic `nonce` (`DateTime.now().microsecondsSinceEpoch`) and is cleared immediately after consumption so orientation changes or modal animations never re-send `autoSend` prompts.
2. **Send Guard During Active Stream:** If `sending == true` when an `autoSend` trigger arrives, ignore or queue safely with a toast (`Copilot is already responding`) rather than launching concurrent streams against `maxConcurrentRequests = 1`.
3. **Plan Limit Rollback (`403 PLAN_LIMIT_REACHED`):** Removes optimistic user bubble, restores prompt text into input field, reverts `deep` → `fast` if applicable, and triggers the global `PlanLimitBottomSheet`.
4. **Read-Only Workspace (`activeBusiness.editable == false`):** If triggered from an AppBar or read-only context, disable composer send/attachments and show Read-Only notice banner linking to `BusinessAllocationSheet`.
5. **Single-Turn Context Clearing:** `pendingScreenContext` is cleared as soon as it is attached to the outgoing turn (`GlobalCopilotDrawer.tsx:101`), preventing stale KPI/invoice context from bleeding into unrelated follow-up questions.
6. **Clean Stream Abort on Business Switch / Logout:** Never leave orphaned SSE listeners running after switching tenants. (Note: closing the sheet via `X` while a stream is running can either keep streaming in `globalCopilotSheetControllerProvider` so the answer is ready when re-opened, or abort cleanly—keep controller alive across sheet hide/show within the same business, and abort on `Stop` or business change.)

---

## 10. Loading, Empty, Error, and Offline States

| State | UI Presentation | Recovery Action |
|---|---|---|
| **Empty Thread** | Dashed `AfabInsetPanel` card (`Ask AFAB Copilot anything`) + 2 quick-action pills | Tap pill, type, dictate, or attach file |
| **Streaming / Thinking** | `CopilotThinkingCard` with live timer, phase shimmer, tool pills, and streaming Markdown | Tap `Stop` (`Square`) to abort `CancelToken` |
| **Network / AI Error** | Rolls back optimistic message, restores input text, displays non-blocking `AfabToast` error | Edit/retry send or tap `Full View` to inspect `AiModelStatusBadge` |
| **Plan Quota Exhausted (`403`)** | Global `PlanLimitBottomSheet` triggered + reverts `deep` to `fast` | Upgrade CTA → `PlansAndSubscriptionScreen` |
| **Offline (`connectivity_plus`)** | Composer send & quick-starter pills disabled with subtle offline hint banner | Auto-enabled when connectivity returns |

---

## 11. Localization and RTL Behavior

- All sheet chrome (`drawerTitle`, `drawerSubtitle`, `openWorkspace`, `drawerEmptyTitle`, `drawerEmptyDesc`, `morningBriefButton`, `prompts.invoicesTitle`, `attachments.supportedHint`) uses `context.l10n` (`app_en.arb` / `app_ar.arb`).
- **Auto-Send Prompt Language Note:** In Web (`dashboard/page.tsx`, `invoices/page.tsx`, `budgets/page.tsx`, `reports/page.tsx`), several `openCopilot` triggers pass English template strings even when UI locale is Arabic. Because `AiChatRequest.locale` is sent and `AiLanguageResolver` detects language, mobile should localize or preserve clear prompts while ensuring `AiChatRequest.locale` always reflects `localeProvider` (`en` / `ar`) so the backend responds appropriately.
- Tablet side sheet slides in from `EdgeInsetsDirectional` end edge (`right` in LTR, `left` in RTL).
- Per-message RTL/LTR bubble directionality, LTR `MoneyText`, and LTR code/chart rules match `AI-01` verbatim.

---

## 12. Responsive and Adaptive Behavior

| Breakpoint | Presentation | Sizing & Ergonomics |
|---|---|---|
| `compactSmall` (`< 360dp`) | `DraggableScrollableSheet` (`0.92` initial, `0.96` max) | Compact header (hide `drawerSubtitle` if needed to avoid clipping `Full View`), `Fast`/`Deep` icons + short labels, `fl_chart` `190dp` height. |
| `compact` (`360–599dp`) | `DraggableScrollableSheet` (`0.88` initial, `0.50` min, `0.96` max) | Full bottom-sheet drag handle, `AnimatedPadding` for `viewInsets.bottom` so keyboard pushes composer up without obscuring latest message. |
| `medium` (`600–839dp`) | End-edge Modal Side Sheet (`width: 460dp`, full height) | Roomy 2-column Evidence & Draft form layout inside sheet. |
| `expanded` (`>= 840dp`) | End-edge Modal Side Sheet (`width: 540dp`, full height) | Matches Web `max-w-xl` drawer proportions; supports `Ctrl+K` / `Cmd+K` toggle shortcut. |

---

## 13. Accessibility and Testing Criteria

### Accessibility
- Screen-reader announcement (`SemanticsService.announce`) when `GlobalCopilotSheet` opens, especially for `autoSend` launches from KPI/Invoice/Budget cards.
- Minimum `48x48dp` touch targets on `Full View`, `Close`, `Attach`, `Mic`, and `Send`/`Stop`.
- Drag handle supports semantic `Dismiss` / `Close` action for TalkBack & VoiceOver users who cannot drag.

### Mandatory Test Coverage
1. **Unit Tests (`test/unit/ai/copilot_launcher_test.dart`):**
   - Verifies `openCopilot` sets `launchRequest` with `screenContext` and `autoSend`, clears once consumed, and resets drawer state on `activeBusinessIdProvider` change.
2. **Widget Tests (`test/widget/ai/global_copilot_sheet_test.dart`):**
   - Empty state starters, `autoSend: true` with `screenContext: { page: "invoices", invoiceNumber: "INV-001" }` rendering `CopilotReminderCard` (`Email` / `WhatsApp` toggle), `Full View` navigation to `/dashboard/ai`, Phone `DraggableScrollableSheet` vs Tablet Side Sheet across Light/Dark & EN/AR with zero overflow.
3. **Integration Test (`integration_test/global_copilot_context_test.dart`):**
   - From `InvoicesScreen`, tap `Draft AI Reminder` on an `OVERDUE` invoice → verify `GlobalCopilotSheet` opens, sends `screenContext`, streams SSE `propose_payment_reminder`, and renders `CopilotReminderCard`.

---

## 14. Dependencies and Risks

### Package Dependencies
- Shares `lib/features/ai/` components and packages with `AI-01` (`flutter_riverpod`, `go_router`, `dio`, `fl_chart`, `flutter_markdown_plus`, `image_picker`, `file_picker`, `flutter_image_compress`, `speech_to_text`, `url_launcher`, `share_plus`).

### Technical Risks & Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| **Stale `screenContext` Across Turns** | Sending invoice #1's `screenContext` on a later unrelated question confuses the LLM. | Clear `pendingScreenContext` immediately upon turn dispatch (`GlobalCopilotDrawer.tsx:101`). |
| **Keyboard Overlap Inside `DraggableScrollableSheet`** | Soft keyboard covers composer or pushes drag handle off-screen on short phones. | Wrap sheet body in `SafeArea` + `AnimatedPadding(bottom: viewInsets.bottom)` and auto-expand `DraggableScrollableController` toward `0.95` when composer gains focus. |
| **Duplicate `autoSend` on Widget Rebuild** | Re-triggering `openCopilot` prompt on `OrientationBuilder` / `MediaQuery` rebuilds. | Consume `launchRequest` once using `nonce` tracking + immediate `clearLaunchRequest()`. |
| **Hidden Concurrent Requests with `AI-01`** | Backend `maxConcurrentRequests = 1` queues requests if user switches quickly from sheet to Tab 2 while streaming. | Share or coordinate active stream `CancelToken` / `isBusy` state across `aiStudioControllerProvider` and `globalCopilotSheetControllerProvider`. |
