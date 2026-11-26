# AI-03 — Business Memory Manager Screen (`BUSINESS_MEMORY_SCREEN.md`)

> **Domain:** AI Copilot v2 (`lib/features/ai/`)
> **Spec ID:** `AI-03`
> **Target Flutter File:** `lib/features/ai/presentation/business_memory_screen.dart`
> **Presentation:** Full Screen Route on Phone & Medium Tablet (`/dashboard/ai/memory`); Docked Inline Side Pane / Modal Sheet on Large Tablet (`>= 1024dp`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `AI-03` |
| **Screen Name** | Business Memory Manager |
| **Flutter Widget** | `BusinessMemoryScreen` (`ConsumerStatefulWidget`) + reusable `BusinessMemoryBody` |
| **Route Path** | `/dashboard/ai/memory` (`AppRoutes.aiMemory`) |
| **Navigation Role** | Secondary route pushed from `AiCopilotScreen` (`AI-01`) header `Memory` button or `MEMORY` evidence chip; inline side pane (`400–480dp`) on `>= 1024dp` tablets |
| **Access Scope** | Authenticated + Verified + Onboarded user; `GET` allowed for all active members, while Create / Edit / Approve / Delete require `EDITABLE` workspace (`BusinessAccessGuard.assertEditable`) |
| **Priority** | `P2` (Roadmap task `P5-02`) |

---

## 2. Web Source Reference & Parity Status

| Web Source File | Role in Web | Web Parity Status | Mobile Adaptation |
|---|---|---|---|
| `Web/project/frontend/components/ai/BusinessMemoryDrawer.tsx` | Slide-over drawer (275 lines): create memory form (`6` types), memory list cards, `hasVector` badge (`Vectorized` / `Keyword Indexed`), Approve (`PROPOSED`), Delete | Implemented and Connected | Adds status filter tabs (`ALL` / `PROPOSED` / `APPROVED` / `EXPIRED`), **Edit** UI (`PATCH /ai/memory/{id}`), Delete confirmation dialog, and explicit `READ_ONLY` business guard |
| `Web/project/frontend/app/[locale]/(dashboard)/dashboard/ai/page.tsx` | Header `Business Memory` button + count badge (`memories.length`) + `refreshMemoryAndStatus()` | Implemented and Connected | Header `Memory` pill pushes `BusinessMemoryScreen` (`< 1024dp`) or toggles side pane (`>= 1024dp`) |
| `Web/project/frontend/lib/api/ai.ts` | `listMemory(status)`, `createMemory`, `updateMemory`, `deleteMemory`, `BusinessMemoryItem` | Implemented and Connected | `AiRepository` supporting all 4 status filters (`ALL`, `PROPOSED`, `APPROVED`, `EXPIRED`) & full CRUD |
| `Web/project/backend/src/main/java/com/afab/ai/service/BusinessMemoryService.java` | Enforces `ALLOWED_MEMORY_TYPES` (`6`), `ALLOWED_STATUSES` (`PROPOSED`, `APPROVED`, `EXPIRED`), `BusinessAccessGuard.assertEditable`, SHA-256 `contentHash`, conditional `pgvector` embedding, soft-delete (`DELETED`) | Authoritative | Full 1:1 backend parity (unlocking `status` filter & `PATCH` editing already implemented in Java) |
| `Web/project/backend/src/main/java/com/afab/ai/dto/BusinessMemoryDTO.java`, `BusinessMemoryRequest.java`, `BusinessMemoryUpdateRequest.java` | Request/Response DTO contracts & Jakarta Bean Validation (`@Size(max=160)` title, `@Size(max=2000)` content) | Authoritative | Enforced client-side + `fieldErrors` mapping |

---

## 3. Purpose and User Value

Business Memory lets business owners and team members teach AFAB Copilot durable, tenant-isolated facts—such as recurring supplier habits, seasonal sales cycles, categorization rules, historical decisions, and operational constraints—so the Copilot understands **why** behind the numbers.

On mobile, `BusinessMemoryScreen` improves on Web's drawer by exposing **all backend capabilities**:
1. **Status Filtering (`ALL` / `PROPOSED` / `APPROVED` / `EXPIRED`):** Quickly review AI-proposed memories awaiting approval (`PROPOSED`), inspect active vectorized knowledge (`APPROVED`), or audit expired rules (`EXPIRED`).
2. **6 Structured Memory Types:** Categorize every rule accurately (`BUSINESS_PROFILE`, `TRANSACTION_CONTEXT`, `SUPPLIER_PATTERN`, `CATEGORIZATION_PREFERENCE`, `DECISION_HISTORY`, `OPERATIONAL_CONSTRAINT`).
3. **Full Create, Edit, Approve & Delete Lifecycle:** Create new immediately-approved rules, edit existing titles/content/types/statuses via `PATCH /api/v1/ai/memory/{id}` (automatically re-vectorizing on the backend), 1-tap approve `PROPOSED` items, and safely delete obsolete entries.
4. **Vector vs. Lexical Transparency:** Clearly shows whether each memory is semantically indexed in `pgvector` (`Vectorized`) or currently falls back to keyword search (`Keyword Indexed`) when Ollama embeddings are offline or the memory is not yet approved.

---

## 4. Navigation, Entry Points, and Exit Paths

### Entry Points
- **`AiCopilotScreen` (`AI-01`) Header:** Tapping the `Business Memory` button (`Brain` icon + `memories.length` pill).
- **`AiCopilotScreen` / `GlobalCopilotSheet` Evidence & Approved Memory Links:** Tapping a `MEMORY` evidence chip or an approved `SAVE_MEMORY` draft card's `View Record` button (`/dashboard/ai` context).

### Exit Paths
- **Back / Close Button:** Pops `BusinessMemoryScreen` back to `AiCopilotScreen` (or collapses side pane on `>= 1024dp` tablet), keeping `aiStatusProvider` (`approvedMemories`) and `aiMemoryProvider` synchronized.
- **Create / Edit Bottom Sheet:** Tapping `+ Add Memory` FAB/button or `Edit` on a memory card opens `MemoryFormSheet` (`AfabBottomSheet`); saving or cancelling returns to `AI-03`.
- **Read-Only Workspace CTA:** If `activeBusiness.editable == false`, tapping `Manage Workspaces` in the Read-Only notice opens `BusinessAllocationSheet`.

---

## 5. Layout and Visual Hierarchy

```text
┌──────────────────────────────────────────────────────┐
│ AppBar (56dp)                                        │
│ [← Back]  [🧠 Business Memory]          [+ Add]      │
├──────────────────────────────────────────────────────┤
│ Subtitle Banner (collapsible / compact)              │
│ "Teach AFAB recurring supplier patterns, seasonal    │
│  context, and categorization rules..."               │
├──────────────────────────────────────────────────────┤
│ [Conditional] Read-Only Business Guard Banner        │
│ "Workspace is read-only. Memory editing disabled."   │
├──────────────────────────────────────────────────────┤
│ Status Filter Segmented Bar (AfabSegmentedBar)       │
│  [ All ]  [ Proposed ]  [ Approved ]  [ Expired ]    │
├──────────────────────────────────────────────────────┤
│ Scrollable Memory List (RefreshIndicator)            │
│  ├─ Memory Card (AfabCard)                           │
│  │   ├─ Badges Row: [Type Pill] [● Vectorized/Lex]   │
│  │   │              [Status Pill if Proposed/Exp]    │
│  │   ├─ Title (Bold 14sp)                            │
│  │   ├─ Content (Selectable / 13sp muted, multiline) │
│  │   ├─ Footer Meta: Source + Updated timestamp      │
│  │   └─ Actions (if EDITABLE): [✓ Approve] [✎] [🗑]  │
│  └─ ...                                              │
└──────────────────────────────────────────────────────┘
```

*(On Tablet `>= 840dp` / `>= 1024dp` inline side pane: `+ Add` opens an inline collapsible form card at the top of the pane—matching Web `BusinessMemoryDrawer.tsx`—while phone `< 600dp` uses an `+ Add` button/FAB opening a clean `AfabBottomSheet` so the list retains full viewport height.)*

---

## 6. UI Components and Interactive Controls

1. **Status Filter Tabs (`AfabSegmentedBar`):**
   - Segments: `ALL` (`All`), `PROPOSED` (`Proposed`), `APPROVED` (`Approved`), `EXPIRED` (`Expired`).
   - Selecting a segment triggers `GET /api/v1/ai/memory?status=<SEGMENT>` (or switches cached family provider `aiMemoryProvider(status)`).
2. **Memory Form (`MemoryFormSheet` on Phone / Inline Card on Tablet):**
   - **Memory Type Selector (`AfabSelectField`):** Lists all 6 exact backend `memoryType` enum values with localized labels:
     - `BUSINESS_PROFILE` → `"Business Profile"` / `"ملف العمل"`
     - `TRANSACTION_CONTEXT` → `"Transaction Context"` / `"سياق معاملة"`
     - `SUPPLIER_PATTERN` → `"Supplier Pattern"` / `"نمط مورد"`
     - `CATEGORIZATION_PREFERENCE` → `"Category Rule"` / `"قاعدة تصنيف"`
     - `DECISION_HISTORY` → `"Decision History"` / `"سجل قرار"`
     - `OPERATIONAL_CONSTRAINT` → `"Constraint"` / `"قيد تشغيلي"`
   - **Short Title (`AfabTextField`):** Required, `maxLength: 160`, placeholder `e.g. High sales season before Eid`.
   - **Business Context / Fact (`AfabTextField` multiline):** Required, `minLines: 3`, `maxLines: 6`, `maxLength: 2000`, character counter, placeholder `e.g. Supplier STEG bills electricity every two months; classify as Utilities.`.
   - **Status Toggle (Edit mode only):** Allows switching between `APPROVED` and `PROPOSED` (or keeping current status).
   - **Submit Button:** `Save & Vectorize` (Create) / `Save Changes` (Edit) with loading spinner (`Saving...`), disabled when `!editable`, busy, or required fields blank.
3. **Memory Card (`BusinessMemoryCard`):**
   - **Type Pill:** `primary` 10% tint (`types.<memoryType>`).
   - **Index Status Pill:**
     - `hasVector == true`: Emerald (`#10B981` 10% fill) with green dot + `Vectorized` (`vectorReady`).
     - `hasVector == false`: Amber (`#F59E0B` 10% fill) + `Keyword Indexed` (`lexicalOnly`).
   - **Lifecycle Status Badge (when `status != "APPROVED"`):** Amber `Proposed` or Gray `Expired` pill so status is unmistakable under `ALL`.
   - **Action Controls (hidden/disabled when `!activeBusiness.editable`):**
     - `Approve` (`Check`, emerald) — shown when `status == "PROPOSED"` → calls `PATCH /api/v1/ai/memory/{id}` with `{ status: "APPROVED" }`.
     - `Edit` (`Pencil`) — opens `MemoryFormSheet` prefilled with existing `memoryType`, `title`, `content`, `status`.
     - `Delete` (`Trash2`, danger) — opens confirmation dialog (`Delete this memory? Copilot will stop using it.`) → `DELETE /api/v1/ai/memory/{id}`.

---

## 7. State Management and Data Flow

### Riverpod Providers
| Provider | Type | Responsibility |
|---|---|---|
| `memoryStatusFilterProvider` | `NotifierProvider<MemoryStatusFilterNotifier, String>` | Holds selected filter: `"ALL"` (default), `"PROPOSED"`, `"APPROVED"`, or `"EXPIRED"`. |
| `aiMemoryProvider` | `AsyncNotifierProvider.family<AiMemoryNotifier, List<BusinessMemory>, String>` | Fetches `GET /api/v1/ai/memory?status={filter}`; exposes `createMemory()`, `updateMemory()`, `approveMemory()`, `deleteMemory()`. Watches `activeBusinessIdProvider`. |
| `memoryMutationBusyIdProvider` | `StateProvider<String?>` | Tracks in-flight item ID to disable duplicate taps on Approve/Edit/Delete buttons. |

### Mutation Sync Rules
- Every Create / Edit / Approve / Delete mutation awaits API completion, then invalidates:
  - `aiMemoryProvider` (all status buckets)
  - `aiStatusProvider` (updates `approvedMemories` count in `AI-01` header & status)
- Switching active business via `BusinessSwitcherSheet` automatically disposes/re-fetches `aiMemoryProvider` for the new `X-Business-Id`.

---

## 8. API Contracts and Data Mapping

| Endpoint | Method | Auth / Guard | Request DTO | Response DTO |
|---|---|---|---|---|
| `/api/v1/ai/memory?status=ALL` | `GET` | JWT | Query `status`: `ALL` \| `PROPOSED` \| `APPROVED` \| `EXPIRED` | `200 List<BusinessMemoryDTO>` |
| `/api/v1/ai/memory` | `POST` | JWT + `EDITABLE` | `BusinessMemoryRequest { memoryType, title(<=160), content(<=2000), status?("APPROVED"), expiresAt? }` | `201 BusinessMemoryDTO` |
| `/api/v1/ai/memory/{id}` | `PATCH` | JWT + `EDITABLE` | `BusinessMemoryUpdateRequest { memoryType?, title?(<=160), content?(<=2000), status?, expiresAt? }` | `200 BusinessMemoryDTO` |
| `/api/v1/ai/memory/{id}` | `DELETE` | JWT + `EDITABLE` | Path `id: UUID` | `204 No Content` |

### `BusinessMemoryDTO` Field Mapping
- `id` (`UUID` → `String`)
- `memoryType` (`BUSINESS_PROFILE` | `TRANSACTION_CONTEXT` | `SUPPLIER_PATTERN` | `CATEGORIZATION_PREFERENCE` | `DECISION_HISTORY` | `OPERATIONAL_CONSTRAINT`)
- `title` (`String`)
- `content` (`String`)
- `sourceType` (`String`, e.g., `"USER_NOTE"`, `"COPILOT_PROPOSAL"`)
- `sourceId` (`UUID?`)
- `status` (`"PROPOSED"` | `"APPROVED"` | `"EXPIRED"`)
- `visibility` (`"BUSINESS"`)
- `modelId` (`String?`)
- `hasVector` (`bool` — computed server-side via `vectorRepository.findMemoryIdsWithVectors(businessId)`)
- `expiresAt` (`Instant?` → `DateTime?`)
- `createdAt`, `updatedAt` (`Instant` → `DateTime`)

---

## 9. Validation, Business Rules, and Edge Cases

1. **Field Constraints (`BusinessMemoryRequest.java` & `BusinessMemoryUpdateRequest.java`):**
   - `memoryType`: required, must match one of `BusinessMemoryService.ALLOWED_MEMORY_TYPES` (`6` values).
   - `title`: required (`@NotBlank` on create), `1..160` characters (`@Size(max = 160)`).
   - `content`: required (`@NotBlank` on create), `1..2000` characters (`@Size(max = 2000)`).
   - `status`: validated against `ALLOWED_STATUSES` (`PROPOSED`, `APPROVED`, `EXPIRED`). Create defaults to `"APPROVED"` (matching Web `BusinessMemoryDrawer.tsx:49`).
2. **`EDITABLE` Business Guard (`BusinessAccessGuard.assertEditable`):**
   - Read (`GET /ai/memory`) succeeds even on `READ_ONLY` businesses.
   - Create (`POST`), Edit/Approve (`PATCH`), and Delete (`DELETE`) throw `403 BUSINESS_READ_ONLY` on `READ_ONLY` workspaces.
   - Mobile proactively checks `activeBusinessProvider.editable`: hides `+ Add`, `Approve`, `Edit`, and `Delete` controls and shows a `Read-Only Workspace` banner with `Manage Workspaces` CTA. If a race condition still returns `403 BUSINESS_READ_ONLY`, global `ApiErrorInterceptor` triggers `BusinessReadOnlySheet`.
3. **Vector Embedding Timing & Fallback:**
   - Backend only embeds memories into `pgvector` when `status == "APPROVED"` and Ollama `embeddinggemma-2:270m` is online (`ragIndexService.embedMemoryIfPossible`).
   - If Ollama was offline at save time, `hasVector` returns `false` (`Keyword Indexed`). Editing or tapping `Sync Index` in `AI-01` will generate the missing vector once Ollama is back online (`BusinessMemoryService.java:141`).
4. **Soft Delete Behavior:** `DELETE /api/v1/ai/memory/{id}` sets `status = "DELETED"` server-side (invisible to `ALL`/`PROPOSED`/`APPROVED`/`EXPIRED`). Mobile prompts confirmation before deleting.
5. **Cross-Tenant Ownership Check:** Backend throws `403 ForbiddenException` if memory `id` belongs to a different `businessId`.

---

## 10. Loading, Empty, Error, and Offline States

| State | UI Presentation | Recovery Action |
|---|---|---|
| **Loading (`AsyncLoading`)** | 4 shimmer placeholder cards (`AfabCard` skeleton) below status filter tabs | Auto-resolves on `GET /ai/memory` |
| **Empty (`ALL`)** | `AfabEmptyState` (`Brain` icon + `memory.empty` message) + `+ Add Memory` CTA (if `editable`) | Tap `+ Add Memory` to create first rule |
| **Empty (Filtered: `PROPOSED`/`EXPIRED`)** | Filter-specific empty message (e.g., `"No proposed memories awaiting review"`) + `Show All` button | Switch filter back to `ALL` |
| **Validation Error (`400`)** | Inline field error text under `title` / `content` (`fieldErrors` or client validators) | Correct input & resubmit |
| **Read-Only Guard (`403`)** | Inline `Read-Only Workspace` amber/rose banner; write buttons hidden | Tap `Manage Workspaces` → `BusinessAllocationSheet` |
| **Load / Mutation Error** | Retryable `AfabEmptyState` error card on load failure; `AfabToast` error on mutation failure | Tap `Retry` / Pull-to-refresh (`RefreshIndicator`) |
| **Offline (`connectivity_plus`)** | Global `OfflineBanner`; cached memories visible read-only; Create/Edit/Approve/Delete disabled with offline tooltip | Auto-re-enables on reconnect |

---

## 11. Localization and RTL Behavior

- **ARB Keys:** Uses all keys under `AI.memory.*` (`title`, `subtitle`, `addTitle`, `titleLabel`, `titlePlaceholder`, `typeLabel`, `contentLabel`, `contentPlaceholder`, `saveButton`, `saving`, `empty`, `vectorReady`, `lexicalOnly`, `approve`, `delete`, and all 6 `types.*` keys) from `messages/{en,ar}/ai.json`.
- **Additional Mobile ARB Keys:** Localizes newly surfaced mobile controls (`ALL`, `PROPOSED`, `APPROVED`, `EXPIRED` filter labels, `Edit Memory`, `Save Changes`, `Delete confirmation`, `Read-Only Workspace` notice) in both `app_en.arb` and `app_ar.arb`.
- **RTL & BiDi:**
  - Uses `EdgeInsetsDirectional` and `AlignmentDirectional` across all cards and sheets.
  - Because users may author memories in English, French, Arabic, or Tunisian Derja, memory `title` and `content` text fields use per-text script directionality (`TextDirection.rtl` if Arabic script detected or UI locale is `ar` with no Latin lead, `TextDirection.ltr` otherwise) so mixed-language rules render cleanly.

---

## 12. Responsive and Adaptive Behavior

| Breakpoint | Presentation & Layout |
|---|---|
| `compactSmall` (`< 360dp`) | Full-screen pushed route; `AfabSegmentedBar` scrolls horizontally if 4 status pills exceed width; `+ Add` FAB at bottom-end; cards stack badges cleanly via `Wrap`. |
| `compact` (`360–599dp`) | Full-screen pushed route (`Scaffold`); `+ Add` button in AppBar or bottom-end FAB opens `MemoryFormSheet` (`isScrollControlled: true`, `SafeArea` + `viewInsets.bottom`). |
| `medium` (`600–839dp`) | Full-screen pushed route or `460dp` centered/end modal sheet; 2-column card grid when width permits (`>= 700dp`) or comfortable single-column `maxWidth: 680dp`. |
| `expanded` (`>= 840dp` / `>= 1024dp`) | On `>= 1024dp` inside `AiCopilotScreen`, docks as an inline `400–440dp` end-edge side pane with an inline collapsible `Add New Memory` card (matching Web `BusinessMemoryDrawer.tsx`). When opened standalone via route, constrains content to `maxWidth: 720dp`. |

---

## 13. Accessibility and Testing Criteria

### Accessibility
- Minimum `48x48dp` touch targets on status filter segments, `Approve`, `Edit`, `Delete` card action buttons, and `+ Add`.
- Clear `Semantics` labels: e.g., `"Approve memory: <title>"`, `"Edit memory: <title>"`, `"Delete memory: <title>"`, `"Index status: Vectorized"` / `"Keyword Indexed"`.
- Character counter announced for `title` (`0/160`) and `content` (`0/2000`) inputs.

### Mandatory Test Coverage
1. **Unit Tests (`test/unit/ai/business_memory_repository_test.dart`):**
   - Verifies `GET /ai/memory?status=ALL|PROPOSED|APPROVED|EXPIRED`, `POST /ai/memory`, `PATCH /api/v1/ai/memory/{id}`, `DELETE /api/v1/ai/memory/{id}`, all 6 `memoryType` enum mappings, `hasVector`, and `403 BUSINESS_READ_ONLY` mapping.
2. **Widget Tests (`test/widget/ai/business_memory_screen_test.dart`):**
   - Tests all 4 states (Loading shimmer, Empty state, Error + Retry, Populated list with `Vectorized` & `Keyword Indexed` badges).
   - Tests status filter tab switching (`ALL` → `PROPOSED` → `APPROVED` → `EXPIRED`).
   - Tests Create (`160`/`2000` validation), Edit (`PATCH`), Approve (`PROPOSED` → `APPROVED`), and Delete confirmation dialog.
   - Tests `editable == false` hiding write controls and rendering Read-Only banner.
   - Tests Phone (`390dp`), Tablet Side Pane (`1280dp`), Light/Dark, and EN/AR RTL with zero overflow.

---

## 14. Dependencies and Risks

### Package Dependencies
- `flutter_riverpod: ^3.5.0`, `go_router: ^18.1.3`, `dio: ^5.9.2`, `freezed_annotation` + `json_annotation`, `lucide_icons_flutter: ^3.1.25`, `intl: ^0.20.2`, `shimmer: ^3.0.0`, `connectivity_plus: ^6.1.0`.

### Technical Risks & Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| **Ollama Embedding Model Offline (`hasVector = false`)** | Newly created or edited memories save to PostgreSQL with `Keyword Indexed` only, reducing semantic recall until embedded. | Surface clear amber `Keyword Indexed` pill + tooltip explaining that keyword search works immediately and tapping `Sync Index` (when Ollama is online) will vectorize it. |
| **Accidental Deletion of High-Value Business Rules** | Web drawer deletes in 1 click without confirmation, risking accidental thumb taps on mobile. | Require explicit `AlertDialog` confirmation before calling `DELETE /api/v1/ai/memory/{id}`. |
| **`READ_ONLY` Workspace Downgrade Mid-Session** | User opens Memory Manager, plan downgrades in background, and `POST`/`PATCH`/`DELETE` fails with `403 BUSINESS_READ_ONLY`. | Check `activeBusinessProvider.editable` proactively and handle `403 BUSINESS_READ_ONLY` globally via `ApiErrorInterceptor` → `BusinessReadOnlySheet`. |
| **Status Drift Between `AI-01` Draft Proposals and `AI-03`** | Approving a `SAVE_MEMORY` card in `AI-01`/`AI-02` creates an `APPROVED` memory not yet reflected in cached `AI-03` list. | Invalidate `aiMemoryProvider` inside `approveMemoryDraft()` so `AI-03` and `AI-01` header badge count update immediately. |
