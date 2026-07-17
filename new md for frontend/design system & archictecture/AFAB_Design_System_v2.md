# AFAB Design System v2

## Enterprise Design Specification

> Version: 2.0

# 1. Design Principles

-   Premium FinTech aesthetic
-   Consistency over creativity
-   Accessibility by default
-   Component-first architecture
-   Responsive from the beginning
-   Light and Dark themes share identical layouts

------------------------------------------------------------------------

# 2. Design Tokens

## Colors

### Brand

  Token            Value
  ---------------- ---------
  primary          #6C4CF5
  primary-hover    #5B3FF0
  primary-active   #4A31D9
  secondary        #8B5CF6
  accent           #A78BFA

### Semantic

| success \| #22C55E \|
| warning \| #F59E0B \|
| danger \| #EF4444 \|
| info \| #3B82F6 \|

### Light Theme

background: #FFFFFF surface: #F7F8FC card: #FFFFFF border: #ECEEF5
text-primary: #111827 text-secondary: #6B7280 text-muted: #9CA3AF

### Dark Theme

background: #0B1020 surface: #1A2235 card: #111827 border: #232533
text-primary: #F8FAFC text-secondary: #CBD5E1 text-muted: #94A3B8

------------------------------------------------------------------------

# 3. Typography

## Fonts

-   Inter (UI)
-   Plus Jakarta Sans (Marketing)
-   JetBrains Mono (IDs / Code)

## Scale

48 Hero 36 Page Title 30 KPI 24 Section 20 Card 18 Table Header 16 Body
14 Label 12 Helper

------------------------------------------------------------------------

# 4. Spacing System

Base Unit: 4px

Spacing Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96

Container Max Width: 1440px

Dashboard Content Padding: 32px

Card Padding: 24px

------------------------------------------------------------------------

# 5. Radius

Buttons: 14px Inputs: 12px Cards: 20px Dialogs: 24px Badges: 9999px

------------------------------------------------------------------------

# 6. Elevation

Light: - xs - sm - md - lg

Dark: Prefer borders over shadows.

------------------------------------------------------------------------

# 7. Grid

Desktop: 12-column

Tablet: 8-column

Mobile: 4-column

------------------------------------------------------------------------

# 8. Motion

Library: Framer Motion

Durations: Hover 150ms Button 180ms Modal 200ms Drawer 250ms Page 250ms

Animations: Fade Slide Scale Opacity

Avoid bouncing animations.

------------------------------------------------------------------------

# 9. Icons

Library: Lucide React

Icon Sizes: 16 18 20 24

------------------------------------------------------------------------

# 10. Component Variants

Buttons - Primary - Secondary - Ghost - Outline - Danger - Success

Inputs - Default - Error - Disabled - Success

Cards - Default - Hover - Selected

Badges - Success - Warning - Error - Neutral - AI

------------------------------------------------------------------------

# 11. Charts

Library: Recharts

Allowed: - Line - Area - Bar - Pie - Donut

Rules: - No 3D - Minimal colors - Clear legends - Accessible contrast

------------------------------------------------------------------------

# 12. Tables

Requirements: - Sorting - Filtering - Pagination - Sticky header -
Responsive - Empty state - Loading skeleton

------------------------------------------------------------------------

# 13. Accessibility

Target: WCAG AA

Requirements: - Keyboard navigation - Focus indicators - Screen reader
labels - Contrast compliance - RTL support

------------------------------------------------------------------------

# 14. RTL Rules

English: LTR

Arabic: RTL

Requirements: - Auto layout direction - Mirrored spacing where
appropriate - Localized dates and numbers

------------------------------------------------------------------------

# 15. Tailwind Mapping

Recommended: - CSS variables for theme colors - Utility-first styling -
Design tokens exposed through Tailwind config - Reusable class patterns
for spacing, typography, and colors

------------------------------------------------------------------------

# 16. Definition of Done

Every new component must: - Support Light & Dark themes - Be
responsive - Be reusable - Be typed with TypeScript - Be accessible -
Include loading and error states - Follow the design tokens - Pass
linting and formatting checks
