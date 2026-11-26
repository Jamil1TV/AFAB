# `FIN-05` — Manage Categories Screen (`ManageCategoriesScreen`)

> **Domain:** Financial Core (`features/categories`)
> **Priority:** P1 (Category CRUD — Fixes `systemDefault` JSON Mismatch, `"var(--primary)"` Swatch Bug & Missing Edit UI)
> **Status:** Complete Mobile Specification (Verified against Web & Backend Sources)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `FIN-05` |
| **Screen Name** | `ManageCategoriesScreen` |
| **Route Path (`GoRouter`)** | `/categories` (Pushed from `TransactionsScreen`, `MoreHubScreen`, `AddEditTransactionScreen`, `SplitTransactionScreen`, or Tablet Modal) |
| **Feature Module** | `lib/features/categories/presentation/screens/manage_categories_screen.dart` |
| **Web Source Equivalent** | `Web/project/frontend/components/dashboard/ManageCategoriesModal.tsx` + `lib/api/categories.ts` |
| **Backend Controllers** | `CategoryController.java` (`/api/v1/categories`: `GET`, `POST`, `PUT /{id}`, `DELETE /{id}`) |
| **Access Level** | Authenticated (`EDITABLE` business required for Create, Edit, Delete; `READ_ONLY` allows viewing only) |

---

## 2. Purpose & User Jobs

1. **Organize Income & Expense Taxonomies:** Browse all system-default and business-custom categories separated into `Expense Categories` and `Income Categories` tabs.
2. **Create Custom Categories:** Add business-specific categories with custom name, icon (`Tag`, `DollarSign`, `Briefcase`, `TrendingUp`, `Building`, `Laptop`, `Users`, `Package`, `Plane`, `ShoppingBag`), and valid hex color swatch.
3. **Edit Custom Categories (`PUT /categories/{id}`):** Rename or change the icon/color of custom categories (exposing the backend endpoint that Web omitted).
4. **Safely Delete Unused Categories:** Delete custom categories with confirmation, clearly surfacing backend `409 Conflict` usage counts when a category is referenced by active transactions, while locking system-default categories.

---

## 3. Navigation & Entry/Exit Flows

### Entry Points
- `Manage Categories` button on `TRANSACTIONS_SCREEN.md` (`FIN-01`).
- `MoreHubScreen` → `Money & Operations` → `Categories` (`/categories`).
- Quick link inside `CategoryPickerSheet` on `FIN-03` (`AddEditTransactionScreen`) / `FIN-04` (`SplitTransactionScreen`).

### Exit Points
| Trigger | Behavior |
|---|---|
| Back / Close | Pops route; any category changes already invalidated `categoryListProvider` and `transactionListProvider`. |
| Tap `+ New Category` | Opens inline expandable form or `CategoryEditorSheet` (`mode: create`, `type: activeTab`). |
| Tap `Edit` on custom category | Opens `CategoryEditorSheet` (`mode: edit`, pre-filled `name`, `icon`, `color`; `type` locked since `UpdateCategoryRequest` has no `type`). |
| Tap `Delete` on custom category | Shows styled `DeleteCategoryConfirmDialog` → `DELETE /api/v1/categories/{id}`. |

---

## 4. Layout & Visual Architecture

- **AppBar:** Back arrow (`matchTextDirection: true`), title `Manage Categories`, trailing `+` quick-add icon (disabled in `READ_ONLY` workspace).
- **Tab Switcher (`AfabSegmentedBar`):**
  - `Expense Categories` (active fill `AfabColors.primary`)
  - `Income Categories` (active fill `#10B981`)
- **Inline / Top Alerts:** Success banner (`CheckCircle2`, emerald) or Error banner (`AlertCircle`, danger — e.g., `409` in-use count or `409` duplicate name).
- **Create CTA Card (Top of List):** Dashed-border `"New Category"` trigger card (`+ New Category`) when `activeBusiness.editable == true`.
- **Category List (`ListView.separated`):**
  - Each `CategoryTile` (`AfabInsetPanel` / `AfabCard`):
    - Leading `36x36dp` rounded icon badge with resolved category hex `color` background + white Lucide icon mapped from `cat.icon`.
    - Center: `cat.name` (`14sp` SemiBold) + `cat.type` muted subtitle.
    - Trailing:
      - If `cat.systemDefault == true` (or `cat.businessId == null`): `Lock` pill `"System Default"` (non-editable, non-deletable).
      - If custom (`cat.systemDefault == false`): `"Custom"` pill + `Pencil` Edit icon button + `Trash2` Delete icon button (loading spinner while `deletingId == cat.id`).
- **Category Editor Sheet (`CategoryEditorSheet` — Create & Edit):**
  - Header (`New Category (EXPENSE|INCOME)` or `Edit Category`) + close button.
  - `Category Name` `AfabTextField` (`maxLength: 100`, required).
  - `Color` palette row: 8 pure hex swatches (`#10B981`, `#06B6D4`, `#8B5CF6`, `#3B82F6`, `#F59E0B`, `#EF4444`, `#EC4899`, `#64748B`) with active ring indicator. **Never** `"var(--primary)"`.
  - `Icon` grid: 10 Lucide icons (`Tag`, `DollarSign`, `Briefcase`, `TrendingUp`, `Building`, `Laptop`, `Users`, `Package`, `Plane`, `ShoppingBag`).
  - `Cancel` + `Create Category` / `Save Changes` buttons.

---

## 5. UI Components & Interactive Controls

| Component | Behavior |
|---|---|
| **`CategoryTabBar`** | Switches `EXPENSE` ↔ `INCOME`, clears transient alert banners, filters list immediately. |
| **`CategoryTile`** | Displays resolved icon (`CategoryIconMapper.resolve(cat.icon)`) and safely parsed color (`ColorParser.parseHex(cat.color)`). Note: Web `ManageCategoriesModal.tsx:327` ignores `cat.icon` and renders `<Tag />` for every row! Mobile renders the actual selected icon! |
| **`ColorSwatchPicker`** | Sends uppercase or lowercase valid hex (`#8B5CF6`) to backend; never stores CSS variable names. |
| **`IconPickerGrid`** | Maps exact backend icon string names (`"Tag"`, `"DollarSign"`, etc.) to `LucideIcons.*`. |
| **`DeleteCategoryConfirmDialog`** | Styled Material dialog replacing Web's `window.confirm(t("deleteConfirm"))`. |

---

## 6. Data Requirements & API Contracts

### 6.1 `GET /api/v1/categories`
- **Response (`200 OK` — `List<CategoryDTO>`):**
  ```json
  [
    {
      "id": "uuid",
      "businessId": null,
      "name": "Software",
      "type": "EXPENSE",
      "icon": "Laptop",
      "color": "#8b5cf6",
      "systemDefault": true,
      "createdAt": "2026-01-01T00:00:00Z",
      "updatedAt": "2026-01-01T00:00:00Z"
    }
  ]
  ```
- **Critical JSON Contract Note (`CategoryDTO.java:61`):** Java `public boolean isSystemDefault()` serializes via Jackson as **`"systemDefault"`**, NOT `"isSystemDefault"`. Map `@JsonKey(name: 'systemDefault')` with fallback `systemDefault || businessId == null`.

### 6.2 `POST /api/v1/categories`
- **Request (`CreateCategoryRequest.java`):** `{ name (1..100), type ("INCOME"|"EXPENSE"), icon? (<=50), color? (<=30) }`.
- **Responses:** `201 Created` (`CategoryDTO`); `409 Conflict` if duplicate `(businessId, name ignoreCase, type)`; `403 BUSINESS_READ_ONLY`.

### 6.3 `PUT /api/v1/categories/{id}`
- **Request (`UpdateCategoryRequest.java`):** `{ name? (1..100), icon? (<=50), color? (<=30) }`.
- **Responses:** `200 OK` (`CategoryDTO`); `403 ForbiddenException` on system defaults (`business == null`) or foreign business; `409 Conflict` on duplicate name; `404` if missing.

### 6.4 `DELETE /api/v1/categories/{id}`
- **Responses:** `204 No Content`; `403` on system defaults; `409 Conflict` (`"Cannot delete category '<name>' because it is currently used by <N> transaction(s)."`).

---

## 7. State Management & Data Flow

```text
categoryListProvider (AsyncNotifierProvider<List<CategoryEntity>>)
  ├── watches: activeBusinessIdProvider
  ├── fetchCategories() -> GET /api/v1/categories
  ├── createCategory(...) -> POST /api/v1/categories -> appends & invalidates transactions/budgets
  ├── updateCategory(id, ...) -> PUT /api/v1/categories/{id} -> replaces item & invalidates transactions/budgets
  └── deleteCategory(id) -> DELETE /api/v1/categories/{id} -> removes item & invalidates transactions
```

- Any mutation also invalidates `transactionListProvider`, `expenseSummaryProvider`, `revenueSummaryProvider`, and `budgetListProvider` so updated category names/colors/icons propagate immediately across the app.

---

## 8. Business Logic, Validation & Edge Cases

1. **System Default Protection:**
   - A category is system-default if `cat.systemDefault == true || cat.businessId == null`. Hide Edit and Delete controls; render `Lock` badge.
2. **Duplicate Name Validation:**
   - Trim `name` (`1..100` chars); check case-insensitive uniqueness within the active `type` client-side for instant feedback, and also handle backend `409 Conflict`.
3. **409 In-Use Delete Error Parsing:**
   - Backend `CategoryService.java:116` returns: `"Cannot delete category '...' because it is currently used by N transaction(s)."`
   - Extract the integer usage count `N` via regex `r'used by (\d+) transaction'` when present, and display a localized message with the exact count (falling back to `txCatInUseError` if format differs).
4. **Defensive Color Parser (`ColorParser.parseHex`):**
   - Existing DB rows created via Web may literally contain `"var(--primary)"`!
   - If `rawColor == null || rawColor.isEmpty || rawColor.startsWith('var(')` → return `AfabColors.primary` (or active accent color).
   - Otherwise parse `#RRGGBB` or `#AARRGGBB` safely inside `try/catch`, falling back to `AfabColors.primary` on invalid strings so the UI never throws `FormatException`.
5. **Defensive Icon Mapper (`CategoryIconMapper`):**
   - Map known icon names (`Tag`, `DollarSign`, `Briefcase`, `TrendingUp`, `Building`, `Laptop`, `Users`, `Package`, `Plane`, `ShoppingBag`) plus common backend seeded names (`Utensils`, `Car`, `Home`, `Zap`, `Wifi`, `CreditCard`, `Receipt`) to `LucideIcons.*`, defaulting to `LucideIcons.tag`.

---

## 9. Web Parity, Confirmed Bugs & Mobile Fixes

| Confirmed Web Bug / Gap | Web Source Location | Mobile Fix |
|---|---|---|
| **`systemDefault` JSON Key Mismatch:** `CategoryDTO.isSystemDefault()` serializes as `"systemDefault"`, while Web reads `cat.isSystemDefault` (`undefined`), exposing Delete buttons on system defaults! | `CategoryDTO.java:61`, `categories.ts:10`, `ManageCategoriesModal.tsx:109,340` | Mobile maps `@JsonKey(name: 'systemDefault')` with `businessId == null` fallback. |
| **`"var(--primary)"` Swatch Bug:** Web's 3rd swatch stores literal CSS variable `"var(--primary)"` in PostgreSQL, breaking hex opacity concatenation (`${color}15`) and non-CSS platforms. | `ManageCategoriesModal.tsx:35` | Mobile uses `#8B5CF6` (pure hex) in swatch picker and maps legacy `"var(--primary)"` defensively in `ColorParser`. |
| **Missing Edit Category UI:** `CategoryController.java:46` & `categories.ts:40` implement `PUT /categories/{id}`, yet Web has zero Edit button or modal. | `ManageCategoriesModal.tsx:339-361` | Mobile adds full Edit (`PUT /categories/{id}`) for custom categories. |
| **All Rows Render Static `<Tag />` Icon:** Web lets user pick an icon on create, then ignores `cat.icon` when rendering the category list! | `ManageCategoriesModal.tsx:327` | Mobile renders `CategoryIconMapper.resolve(cat.icon)` on every tile. |
| **Browser `confirm()` & Untranslated 409 Count:** Web uses `confirm(...)` and drops the exact transaction count from the 409 error. | `ManageCategoriesModal.tsx:110,122-123` | Mobile uses native confirmation dialog and displays exact transaction usage count from `409` error. |

---

## 10. Design Tokens & Visual Styling

- **Tab Active Colors:** `EXPENSE` tab uses `AfabColors.primary`; `INCOME` tab uses `#10B981`.
- **Category Badge:** `36x36dp` rounded `10dp` tile with `ColorParser.parseHex(cat.color)` background and `#FFFFFF` `18dp` Lucide icon.
- **System Default Chip:** Neutral surface pill (`#E5E7EB` light / `#1F2937` dark) with `Lock` `12dp` icon.
- **Custom Chip:** `primary` 10% tint + `primary` foreground.

---

## 11. Localization (EN/AR) & RTL Behavior

- **Namespace:** `transactions.json` → `categoriesModal.*` (`20` keys) + new ARB keys for `Edit Category`, `Save Changes`, `Update Success`, and `txCatInUseWithCount(int count)` using ICU pluralization (`{count, plural, =1{1 transaction} other{{count} transactions}}`).
- **RTL Layout:** Tabs, category tile leading icon + trailing action buttons, and back arrow automatically mirror in `TextDirection.rtl`.

---

## 12. Responsive & Adaptive Design (Phone & Tablet)

| Breakpoint | Layout Adaptation |
|---|---|
| `compactSmall` & `compact` (`< 600dp`) | Full-screen pushed page; `CategoryEditorSheet` opens as draggable modal bottom sheet (`isScrollControlled: true` + keyboard padding). |
| `medium` & `expanded` (`>= 600dp`) | Centered constrained modal/page (`maxWidth: 620dp`); 2-column category grid or spacious list with inline Edit/Create panel. |

---

## 13. Accessibility, Security & Performance

- **Accessibility:** Color swatches include accessible color names (`"Emerald"`, `"Cyan"`, `"Violet"`, etc.) via `Semantics` so color-blind and screen-reader users can select swatches reliably; `48dp` minimum hit targets on Edit/Delete/swatch buttons.
- **Security:** `EDITABLE` business guard; ownership/system-default validation on backend.
- **Performance:** Category list is small (`~10–50` rows) and kept cached in `categoryListProvider` per active business to eliminate redundant `/categories` fetches across Finance screens.

---

## 14. Dependencies and Risks

- **Dependencies:** `categoryListProvider`, `ColorParser`, `CategoryIconMapper`, `lucide_icons_flutter`.
- **Risks & Mitigations:**
  1. **Legacy `"var(--primary)"` Rows in Existing DBs:** Existing users may have custom categories saved with `"var(--primary)"`. *Mitigation:* `ColorParser` intercepts `"var(--primary)"` cleanly; editing & saving such a category upgrades its stored value to `#8B5CF6`.
  2. **Deleting In-Use Category:** Backend returns `409 Conflict`. *Mitigation:* Display clear error banner explaining how many transactions use the category and keep the dialog dismissed without losing list state.
