# SET-05 — Appearance Settings Screen (`AppearanceSettingsScreen`)

---

## 1. Screen Identity

| Attribute | Value |
|---|---|
| **Screen ID** | `SET-05` |
| **Screen Name** | Appearance & Theme Settings (`AppearanceSettingsScreen`) |
| **Route Path** | `/settings/appearance` |
| **Feature Module** | `lib/features/settings/presentation/appearance_settings_screen.dart` + `lib/core/theme/appearance_theme_builder.dart` |
| **Web Equivalent** | `settings/appearance/page.tsx` + `AppearanceSettings.tsx` + `lib/appearance.ts` |
| **Priority** | P2 (Personalization & Design System Engine) |

---

## 2. Purpose and User Goal

Give users real-time visual customization of AFAB Mobile—theme mode (`System`/`Light`/`Dark`), 8 brand accent presets or custom hex, 4 dark surface moods, 6 typography pairings (EN & AR), 4 font size scales, 3 corner-radius tiers, layout density (`Comfortable`/`Compact`), and ambient glow/transition effects—with an interactive Live Preview card and instant theme application across the app.

---

## 3. Web Source Mapping and Parity Status

| Web Source | Web Behavior | Mobile Adaptation & Parity Status |
|---|---|---|
| `AppearanceSettings.tsx` + `lib/appearance.ts` | ThemeMode (`light`/`dark`/`system`), 8 accents + custom hex, 6 font families, 4 font sizes, 3 radii, density, glow, transitions, Live Preview card, Reset & Save. | **Improved (`Implemented but Incomplete` on Web):** Implements 100% of Web controls via Flutter `ThemeData` + `AfabColors` `ThemeExtension` + `google_fonts`, **and exposes the 4 `DARK_SURFACE_PRESETS` (`midnight`, `oled`, `slate`, `charcoal`)** that `lib/appearance.ts` defined (`darkSurface`) but Web never rendered in UI. |
| `AppearanceSettings.tsx:171-181` (Backend Sync) | Sends `{ appearanceSettings, compactMode }` to `PUT /user/me`. Backend `UpdateUserRequest` ignores `appearanceSettings` and persists only `compactMode`. | **Honest Storage Split:** Persists all 10 `AppearanceSettings` fields locally in `SharedPreferences` (`afab_appearance_settings`) and syncs `compactMode` (`density == 'compact'`) to `PUT /user/me`, with a clear `"Saved on this device"` notice. |

---

## 4. Navigation and Entry Points

- **Entry Points:**
  - `SettingsHomeScreen` (`SET-01`) → **Appearance**.
  - Tablet Settings rail → **Appearance**.
  - Deep link `/dashboard/settings/appearance`.
- **In-Screen Shortcut:**
  - On Phone (`< 840dp`), a floating `"Live Preview"` pill scrolls smoothly to the Live Preview card (matching `AppearanceSettings.tsx:893-907`).

---

## 5. Layout and Visual Hierarchy (Phone & Tablet)

### Phone Layout (`< 600dp`, Single-Column Scrollable)
1. **Top AppBar:** Title `"Appearance & Theme"` + trailing `"Reset"` icon/text action and `"Save"` CTA.
2. **Device-Local Notice Banner (`AfabInsetPanel`):** Concise note explaining theme/color/font settings apply immediately on this device while Compact Mode syncs with your AFAB account.
3. **Section 1 — Theme Mode (`AfabCard`):** 3 miniature preview cards (`Light`, `Dark`, `System`) with active `primary` ring + checkmark badge.
4. **Section 2 — Dark Surface Mood (`AfabCard`):** 2x2 grid (`Midnight Navy`, `OLED Pure Black`, `Deep Slate`, `Charcoal Eclipse`) showing exact background/card swatches (`#060813`, `#000000`, `#090D16`, `#111318`) — enabled/highlighted when Dark or System-Dark is active.
5. **Section 3 — Brand Accent Color (`AfabCard`):**
   - 2-col (phone) / 4-col (tablet) grid of 8 preset swatches (`purple`, `blue`, `emerald`, `amber`, `rose`, `cyan`, `magenta`, `slate`) with circle swatch + hex label.
   - Custom Hex row: color swatch preview (opens native HSV/palette picker sheet) + `#RRGGBB` `LTR` monospace `TextField` (`maxLength: 7`).
6. **Section 4 — Typography & Font Family (`AfabCard`):**
   - 6 selectable font cards (`inter`, `serif`, `mono`, `geometric`, `kufi`, `system`), each rendering its category badge, description, and live EN/AR sample box rendered in that actual `TextStyle` (`$124,850`).
7. **Section 5 — Font Size Scale (`AfabCard`):**
   - 2x2 / 4-col cards (`Compact 14px / 87.5%`, `Standard 16px / 100%`, `Comfortable 18px / 112.5%`, `Accessible 20px / 125%`) showing scaled `"Aa"` preview.
8. **Section 6 — Corner Rounding (`AfabCard`):**
   - 3 cards (`Sharp 8dp`, `Balanced 12dp`, `Modern 16dp`) with rounded-square illustration.
9. **Section 7 — Interface Density & Visual Effects (`AfabCard`):**
   - 2 density cards: `Comfortable` vs `Compact Mode` (notes backend account sync).
   - 2 switches: `Ambient Neon Glow` (`enableGlow`) and `Smooth Theme Transitions` (`smoothTransitions`).
10. **Section 8 — Real-Time Live Preview Card (`AfabCard`):**
    - Interactive sandbox reflecting every change immediately: `$124,850.00` tabular balance, `+14.2%` pill, `fl_chart` mini sparkline in live `primary` color, `Day`/`Week`/`Month` `AfabSegmentedBar`, focusable sample `AfabTextField`, Primary & Secondary buttons (with ambient glow when enabled), Verified badge, and current hex readout.

### Tablet Layout (`>= 600dp` / `>= 840dp`)
- `7:5` two-column layout matching `AppearanceSettings.tsx:248`: Left column controls, Right column sticky Live Preview card.

---

## 6. UI Components and Interactive Elements

| Component | Details |
|---|---|
| `AppearanceThemeBuilder` | Pure Dart builder transforming `AppearanceSettings` into Flutter `ThemeData` (`light` & `dark`), `AfabColors` `ThemeExtension`, `TextTheme` (with `google_fonts ^8.2.1` + `FontFeature.tabularFigures()`), and `BorderRadius` tokens (`sm`/`md`/`lg`). |
| `AccentSwatchGrid` | 8 preset buttons (`purple #8B5CF6`, `blue #3B82F6`, `emerald #10B981`, `amber #F59E0B`, `rose #F43F5E`, `cyan #06B6D4`, `magenta #D946EF`, `slate #64748B`) + custom hex validation (`^#[0-9A-Fa-f]{6}$`) deriving `primaryHover (-12%)`, `lightTint (+90%)`, `darkSecondary (-75%)`, `darkSecondaryFg (+30%)`, `glow (0.40 alpha)`. |
| `DarkSurfaceGrid` | 4 cards rendering live miniature dark cards using exact hexes from `DARK_SURFACE_PRESETS` (`midnight`, `oled`, `slate`, `charcoal`). |
| `FontFamilyCard` | Uses `GoogleFonts.inter`/`poppins`, `playfairDisplay`/`amiri`, `jetBrainsMono`, `cairo`/`montserrat`, `cinzel`/`reemKufi`, or platform default so users preview real glyphs before selecting. |
| `LivePreviewCard` | Renders live `fl_chart` `LineChart` sparkline, interactive `AfabSegmentedBar`, `AfabTextField`, `AfabButton` primary/soft, and `AfabStatusBadge`. |

---

## 7. Data Requirements and API Contracts

- **Local Persistence (`SharedPreferences` key `afab_appearance_settings`):**
  - JSON matching `AppearanceSettings` (`themeMode`, `accentPreset`, `customPrimaryColor`, `darkSurface`, `radius`, `density`, `fontFamily`, `fontSize`, `enableGlow`, `smoothTransitions`).
- **Backend Sync (`PUT /api/v1/user/me`):**
  - On **Save Preferences**: sends `{ "compactMode": settings.density == "compact" }` to `PUT /api/v1/user/me` (`UpdateUserRequest`).
  - Returns `200 UserProfileDTO`; updates `userProfileProvider.compactMode` (keeping General Settings `SET-02` in sync).
  - *Note:* If backend call fails offline, local `SharedPreferences` save still succeeds and user is informed compact-mode cloud sync will retry later.

---

## 8. State Management and Caching

- **`appearanceProvider` (`NotifierProvider<AppearanceNotifier, AppearanceSettings>`):**
  - Hydrated synchronously/at startup from `SharedPreferences` before `MaterialApp.router` builds (zero theme flash).
  - Also syncs initial `compactMode` from `userProfileProvider` when `GET /user/me` completes (only overriding `density` if user explicitly changed it on another device/web, or prioritizing explicit local changes until saved).
  - Every tap calls `updateSetting(...)` → immediately updates `appearanceProvider` state so `AfabApp` rebuilds `ThemeData` in real time, and persists to `SharedPreferences`.
- **`Reset Defaults`:** Restores `DEFAULT_APPEARANCE_SETTINGS` (`system`, `purple`, `#8B5CF6`, `midnight`, `md`, `comfortable`, `inter`, `md`, `true`, `true`).

---

## 9. User Actions, Validation, and Error Handling

- **Custom Hex Input:** Validated against `^#[0-9A-Fa-f]{6}$` (uppercase/lowercase accepted, `LTR` forced). Incomplete hex typing updates input text without breaking active theme until 6 valid hex digits are entered.
- **Font Loading Offline Fallback:** If `google_fonts` cannot fetch a font over network on first use, gracefully falls back to bundled `Cairo` / system font without throwing uncaught exceptions; bundle core `Inter` and `Cairo` TTFs in `assets/fonts/`.
- **System Reduced Motion Override:** If OS `MediaQuery.disableAnimationsOf(context)` is `true`, animations remain disabled regardless of `smoothTransitions`.

---

## 10. Permissions, Security, and Tenant Isolation

- **User/Device-Scoped:** Not tenant-scoped; no sensitive PII or tokens stored in `afab_appearance_settings`.
- **Safe Text Scaling:** Combined in-app font scale (`0.875x`..`1.25x`) × OS `MediaQuery.textScalerOf(context)` is clamped (`0.85x..1.45x`) across app layouts to prevent clipped text or `RenderFlex` overflow.

---

## 11. Localization (EN/AR) and RTL Behavior

- Migrates all `settings.appearance.*` keys and `appearance.ts` `nameEn`/`nameAr`/`descEn`/`descAr`/`sampleEn`/`sampleAr` strings into `app_en.arb` and `app_ar.arb`.
- **Script-Aware Font Pairing:** In Arabic (`Locale('ar')`), font pairings automatically prioritize Arabic companion faces (`Cairo`, `Amiri`, `Reem Kufi`, system Arabic) as primary family with English fallback, while Latin numbers/codes remain crisp.
- **LTR Isolation:** Custom hex field (`#8B5CF6`), hex readout badge, and `$124,850.00` preview amount use `TextDirection.ltr`.

---

## 12. Responsive, Accessibility, and Empty/Loading/Error States

- **Accessibility:**
  - Contrast warning helper: if a user enters a very light custom hex (e.g. `#FFFFFF` or `#FEF08A`) where white button foreground fails `4.5:1` contrast, show a subtle `"Low contrast"` warning hint or adapt foreground contrast (`ThemeData.estimateBrightnessForColor`).
  - Selected preset cards announce `"Selected"` via `Semantics(selected: true)`.
- **Responsive:** Accent grid `2` cols (`< 360dp`), `2–4` cols (`360–599dp`), `4` cols (`>= 600dp`). Font size grid `2` cols on phones, `4` cols on tablets.

---

## 13. Acceptance Criteria and Testing Scenarios

1. **Instant Live Update:** Switching accent preset from `purple` to `emerald` updates both the Live Preview card and the app's `ThemeData.colorScheme.primary` immediately.
2. **Dark Surface Presets Exposed:** Switching `darkSurface` to `oled` sets `AfabColors.background = #000000` and `surface = #0A0A0A` in Dark Mode.
3. **Custom Hex Derivation:** Entering `#0EA5E9` validates hex, activates `"Custom"`, and derives `primaryHover`, `lightTint`, and `darkSecondary`.
4. **Compact Mode Backend Sync:** Selecting `Compact` and tapping `Save Preferences` sends `PUT /user/me` with `{ compactMode: true }` and updates `GeneralSettingsScreen`.
5. **Typography & Scale Safety:** Testing `xl (1.25x)` + `mono` / `kufi` in both EN and AR on `320x568` produces zero `RenderFlex` overflow errors.

---

## 14. Dependencies and Risks

| Type | Detail | Mitigation |
|---|---|---|
| **Packages** | `google_fonts: ^8.2.1`, `shared_preferences: ^2.5.4`, `fl_chart: ^1.3.1` | Bundle `Inter` & `Cairo` TTFs locally in `assets/fonts/` for guaranteed offline rendering. |
| **Missing Backend Sync** | `UpdateUserRequest.java` lacks `appearanceSettings` JSON field. | Document as optional P3 backend proposal (`04_AUTHENTICATION_AND_SECURITY.md` §4.5); keep honest device-local notice in UI. |
| **OS vs In-App Font Scaling** | Multiplying `xl (1.25x)` by OS `1.3x` could break tight cards. | Clamp effective `TextScaler` at `1.45x` app-wide (`07_DESIGN_SYSTEM.md` §2.6). |
