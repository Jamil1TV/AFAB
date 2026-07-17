# AFAB Design System - Quick Reference Card

**Print this or keep it open while designing**

---

## 🎨 Color Palette

### Primary Colors

```
PRIMARY              #6C4CF5  ███ (Main brand color)
PRIMARY HOVER        #5B3FF0  ███ (Hover state)
PRIMARY ACTIVE       #4A31D9  ███ (Active/pressed)
SECONDARY            #8B5CF6  ███ (Secondary actions)
ACCENT               #A78BFA  ███ (Highlights)
```

### Semantic Colors

```
SUCCESS              #22C55E  ███ (Positive actions, approved)
WARNING              #F59E0B  ███ (Warnings, pending)
DANGER/ERROR         #EF4444  ███ (Errors, deletions)
INFO                 #3B82F6  ███ (Information, neutral)
```

### Light Theme Grayscale

```
BACKGROUND           #FFFFFF  ███ (Page background)
SURFACE              #F7F8FC  ███ (Secondary containers)
CARD                 #FFFFFF  ███ (Card background)
BORDER               #ECEEF5  ███ (Borders, dividers)
TEXT PRIMARY         #111827  ███ (Main text)
TEXT SECONDARY       #6B7280  ███ (Secondary text)
TEXT MUTED           #9CA3AF  ███ (Helper text)
```

### Dark Theme Grayscale

```
BACKGROUND           #0B1020  ███ (Page background)
SURFACE              #1A2235  ███ (Secondary containers)
CARD                 #111827  ███ (Card background)
BORDER               #232533  ███ (Borders, dividers)
TEXT PRIMARY         #F8FAFC  ███ (Main text)
TEXT SECONDARY       #CBD5E1  ███ (Secondary text)
TEXT MUTED           #94A3B8  ███ (Helper text)
```

---

## 🔤 Typography

### Fonts

| Font | Usage | Weight |
|------|-------|--------|
| **Inter** | UI components, body text | 400, 500, 600, 700 |
| **Plus Jakarta Sans** | Marketing, hero headings | 600, 700 |
| **JetBrains Mono** | Code, IDs, technical | 400, 500 |

### Type Scale

| Size | Usage | px | Line Height | Example |
|------|-------|-----|------------|---------|
| Hero | Page intro text | 48 | 56 | Main title |
| Page Title | Page heading | 36 | 44 | Dashboard |
| KPI Number | Large stats | 30 | 36 | $45,231 |
| Section Title | Content section | 24 | 32 | Recent Transactions |
| Card Title | Card heading | 20 | 28 | Revenue |
| Table Header | Column header | 18 | 26 | Name |
| Body | Regular text | 16 | 24 | Description text |
| Label | Form labels | 14 | 20 | Email |
| Helper | Small text | 12 | 16 | Additional info |

### Font Weight

```
100 - Thin
200 - Extra Light
300 - Light
400 - Normal (regular text)
500 - Medium (labels, semi-bold)
600 - Semi Bold (card titles, buttons)
700 - Bold (page titles, headings)
800 - Extra Bold
900 - Black
```

---

## 📏 Spacing System

### Base Unit: 4px

```
1 = 4px      5 = 20px     12 = 48px
2 = 8px      6 = 24px     16 = 64px
3 = 12px     8 = 32px     20 = 80px
4 = 16px     10 = 40px    24 = 96px
```

### Common Spacing

```
Padding:      p-4 (16px), p-6 (24px), p-8 (32px)
Margin:       m-6 (24px), mb-8 (32px)
Gap:          gap-4 (16px), gap-6 (24px)
Border Radius: rounded-md (14px), rounded-2xl (20px)
```

---

## 🔲 Border Radius

| Element | Radius | Class |
|---------|--------|-------|
| Buttons | 14px | rounded-md |
| Inputs | 12px | rounded-md |
| Cards | 20px | rounded-2xl |
| Modals | 24px | rounded-3xl |
| Badges | 9999px | rounded-full |
| Tables | 16px | rounded-xl |

---

## 💫 Shadows

### Light Mode Shadows

```
xs:   0 1px 2px rgba(15, 23, 42, 0.04)
sm:   0 4px 12px rgba(15, 23, 42, 0.08)
md:   0 8px 30px rgba(15, 23, 42, 0.06)  ← Default card
lg:   0 12px 40px rgba(15, 23, 42, 0.10)
hover: 0 12px 40px rgba(99, 102, 241, 0.15)  ← Interactive hover
```

### Dark Mode

**Use subtle borders instead of shadows**
```
border: 1px solid #232533  (border-border)
```

---

## 🎯 Component Sizes

### Buttons

| Size | Padding | Font | Class |
|------|---------|------|-------|
| Small | 12px 12px | 14px | px-3 py-1.5 text-sm |
| Medium | 10px 16px | 16px | px-4 py-2.5 text-base |
| Large | 12px 24px | 18px | px-6 py-3 text-lg |
| Icon | 40x40 | N/A | h-10 w-10 |

### Button Variants

```
Primary:   Purple bg, white text, hover darker
Secondary: Light bg, border, gray text, hover lighter
Ghost:     Transparent, text only, hover tint
Outline:   Purple border, purple text, hover tint
Danger:    Red bg, white text, hover darker
```

### Input Height

```
Small:  h-9   (36px)
Medium: h-10  (40px)
Large:  h-12  (48px)
```

---

## 📱 Responsive Breakpoints

| Device | Width | Prefix | Usage |
|--------|-------|--------|-------|
| Mobile | 375px | *none* | Default styles |
| Tablet | 768px | md: | md:grid-cols-2 |
| Desktop | 1280px | lg: | lg:grid-cols-3 |
| Wide | 1536px | 2xl: | 2xl:grid-cols-4 |

### Responsive Pattern

```
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
  <!-- Mobile: 1 column -->
  <!-- Tablet: 2 columns -->
  <!-- Desktop: 3 columns -->
</div>
```

---

## 🌓 Dark Mode

### Switching Theme

```html
<!-- Add to html element -->
<html class="dark">
  <!-- Dark theme applied -->
</html>
```

### Using Dark Colors

```tailwind
<!-- Light by default, dark on dark theme -->
<div class="bg-background dark:bg-dark-background">
  <p class="text-text-primary dark:text-dark-text-primary">
    Text changes color
  </p>
</div>
```

### In Dark Mode
- Light shadows → Use borders instead
- Colors stay consistent
- Text contrast improves

---

## 🎯 Component Classes Quick List

### Text Classes

```
.text-hero               → 48px bold
.text-page-title         → 36px bold
.text-kpi                → 30px bold
.text-section-title      → 24px semibold
.text-card-title         → 20px semibold
.text-body               → 16px regular
.text-body-sm            → 14px regular
.text-label              → 14px medium
.text-helper             → 12px regular
```

### Button Classes

```
.btn-primary             → Purple bg button
.btn-secondary           → Outlined button
.btn-ghost               → Text-only button
.btn-danger              → Red button
.btn-sm, .btn-md, .btn-lg → Sizes
```

### Card Classes

```
.card                    → Card base
.card-padding            → p-6 standard padding
.card-hover              → Adds hover shadow
```

### Input Classes

```
.input-base              → Input field styling
.input-error             → Red error state
.input-success           → Green success state
.label-base              → Label styling
```

### Badge Classes

```
.badge-primary           → Purple badge
.badge-success           → Green badge
.badge-warning           → Orange badge
.badge-danger            → Red badge
.badge-neutral           → Gray badge
```

---

## 🎨 Color Usage Guide

| Component | Color | Use When |
|-----------|-------|----------|
| Primary Button | #6C4CF5 | Main action, next step |
| Secondary Button | #8B5CF6 | Alternative action |
| Success Badge | #22C55E | Action completed, verified |
| Warning Badge | #F59E0B | Attention needed, pending |
| Danger Badge | #EF4444 | Error, deletion, critical |
| Info Badge | #3B82F6 | Information, neutral |

---

## ✅ Component Checklist

When building a component, ensure:

- [ ] Uses correct text size from scale
- [ ] Uses correct spacing (multiples of 4px)
- [ ] Uses correct border radius
- [ ] Has proper hover/active states
- [ ] Works in light and dark modes
- [ ] Has proper focus ring
- [ ] Is responsive (mobile first)
- [ ] Uses semantic colors
- [ ] Follows WCAG AA contrast
- [ ] Uses proper font weight

---

## 📐 Common Spacing Patterns

```
Card Padding:             p-6 (24px)
Page Container Padding:   px-8 py-8 (32px)
Section Gap:              gap-6 (24px)
List Item Gap:            gap-4 (16px)
Form Field Gap:           gap-3 (12px)
Margin Between Sections:  mb-8 (32px)
```

---

## 🎯 Icon Sizes

Using Lucide React:

```
Small Icon:    <Icon size={16} />   (sm)
Regular Icon:  <Icon size={20} />   (md)
Large Icon:    <Icon size={24} />   (lg)
Extra Large:   <Icon size={32} />   (xl)
```

---

## 📋 Reusable Components Available

### Layout
- AppShell (sidebar + header + content)
- Sidebar
- TopNavbar
- PageHeader

### Forms
- Input
- Select
- DatePicker
- Checkbox
- Radio
- Switch

### Feedback
- Button (all variants)
- Badge (all colors)
- Card
- Modal
- Toast
- Alert

### Charts
- LineChart (Recharts)
- AreaChart (Recharts)
- BarChart (Recharts)
- PieChart (Recharts)

### Tables
- DataTable
- Pagination

---

## 🚀 Quick Copy-Paste Classes

### Create a Card

```html
<div class="rounded-2xl bg-card shadow-md p-6">
  <h3 class="text-card-title mb-2">Title</h3>
  <p class="text-body text-text-secondary">Content</p>
</div>
```

### Create a Button

```html
<button class="btn-primary">Click Me</button>
<button class="btn-secondary">Secondary</button>
<button class="btn-ghost">Ghost</button>
```

### Create a Form Field

```html
<div>
  <label class="label-base">Email</label>
  <input class="input-base" type="email" />
</div>
```

### Create a Responsive Grid

```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <div class="card p-6">Item 1</div>
  <div class="card p-6">Item 2</div>
  <div class="card p-6">Item 3</div>
</div>
```

---

## 🎨 Accessibility

### Color Contrast (WCAG AA)

✅ Purple (#6C4CF5) on White (#FFFFFF) - Passes
✅ Text colors meet WCAG AA minimum 4.5:1 ratio
✅ All status colors accessible (not color-only)

### Focus States

- All interactive elements have visible focus ring
- Focus ring: 2px ring with primary color
- Ring offset: 2px (optional)

### Keyboard Navigation

- Tab through all buttons
- Enter to activate
- Space to toggle
- Arrow keys for menus/selects

---

## 📚 Files to Keep Open

1. **AFAB_Tailwind_CSS_Design_System.md** - Comprehensive guide
2. **AFAB_Tailwind_Ready_to_Copy_Files.md** - Copy/paste code
3. **AFAB_Design_Quick_Reference.md** - This file (quick lookup)

---

## 🔗 Important Links

- Tailwind CSS Docs: https://tailwindcss.com
- Lucide Icons: https://lucide.dev
- Color Tool: https://www.tailwindshades.com

---

**Print this card and keep it visible while designing! 🎨**

