# AFAB Tailwind CSS Design System

**Complete guide to build AFAB's design system with Tailwind CSS v4**

---

## 📋 Table of Contents

1. [Colors](#colors)
2. [Typography](#typography)
3. [Spacing](#spacing)
4. [Border Radius](#border-radius)
5. [Shadows](#shadows)
6. [Icons](#icons)
7. [Breakpoints](#breakpoints)
8. [Dark Mode](#dark-mode)
9. [Tailwind Configuration](#tailwind-configuration)
10. [CSS Variables Setup](#css-variables-setup)
11. [Component Examples](#component-examples)
12. [Usage Guide](#usage-guide)

---

## 🎨 Colors

### Primary Brand Colors

| Token | Light Value | Dark Value | Usage |
|-------|-------------|-----------|-------|
| **primary** | #6C4CF5 | #6C4CF5 | Buttons, links, active states |
| **primary-hover** | #5B3FF0 | #7E5CF5 | Hover state for primary |
| **primary-active** | #4A31D9 | #5B3FF0 | Active/pressed state |
| **secondary** | #8B5CF6 | #8B5CF6 | Secondary actions |
| **accent** | #A78BFA | #A78BFA | Accents, highlights |

### Semantic Colors

| State | Color | Usage |
|-------|-------|-------|
| **success** | #22C55E | Success messages, positive trends |
| **warning** | #F59E0B | Warnings, pending states |
| **danger/error** | #EF4444 | Errors, deletions, warnings |
| **info** | #3B82F6 | Information, neutral alerts |

### Grayscale (Light Theme)

| Name | Color | Usage |
|------|-------|-------|
| **background** | #FFFFFF | Page background |
| **surface** | #F7F8FC | Card backgrounds, secondary containers |
| **card** | #FFFFFF | Card background |
| **border** | #ECEEF5 | Borders, dividers |
| **text-primary** | #111827 | Main text content |
| **text-secondary** | #6B7280 | Secondary text, labels |
| **text-muted** | #9CA3AF | Helper text, disabled text |

### Grayscale (Dark Theme)

| Name | Color | Usage |
|------|-------|-------|
| **background** | #0B1020 | Page background |
| **surface** | #1A2235 | Card backgrounds, secondary containers |
| **card** | #111827 | Card background |
| **border** | #232533 | Borders, dividers |
| **text-primary** | #F8FAFC | Main text content |
| **text-secondary** | #CBD5E1 | Secondary text, labels |
| **text-muted** | #94A3B8 | Helper text, disabled text |

### Color Mapping to Tailwind

```css
/* In tailwind.config.ts */
colors: {
  primary: {
    50: '#F3ECFF',    /* very light */
    100: '#E8D9FF',
    200: '#D0B3FF',
    300: '#B88BFF',
    400: '#A168FF',
    500: '#6C4CF5',   /* base primary */
    600: '#5B3FF0',   /* hover */
    700: '#4A31D9',   /* active */
    800: '#3A24A8',
    900: '#2A1977',
  },
  secondary: '#8B5CF6',
  accent: '#A78BFA',
  success: '#22C55E',
  warning: '#F59E0B',
  danger: '#EF4444',
  error: '#EF4444',
  info: '#3B82F6',
}
```

---

## 🔤 Typography

### Font Families

```typescript
// Install these fonts
import { Inter, Plus_Jakarta_Sans, JetBrains_Mono } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });
const plusJakartaSans = Plus_Jakarta_Sans({ subsets: ['latin'] });
const jetbrainsMono = JetBrains_Mono({ subsets: ['latin'] });
```

**Usage:**
- **Inter** - UI/component text (default)
- **Plus Jakarta Sans** - Marketing/hero headings
- **JetBrains Mono** - Code, IDs, technical text

### Type Scale

| Usage | Size | Line Height | Weight | Tailwind Class |
|-------|------|-------------|--------|----------------|
| **Hero** | 48px | 56px | 700 | text-5xl font-bold |
| **Page Title** | 36px | 44px | 700 | text-4xl font-bold |
| **KPI Value** | 30px | 36px | 700 | text-3xl font-bold |
| **Section Title** | 24px | 32px | 600 | text-2xl font-semibold |
| **Card Title** | 20px | 28px | 600 | text-xl font-semibold |
| **Table Header** | 18px | 26px | 600 | text-lg font-semibold |
| **Body (regular)** | 16px | 24px | 400 | text-base |
| **Body (small)** | 14px | 20px | 400 | text-sm |
| **Label** | 14px | 20px | 500 | text-sm font-medium |
| **Helper/Caption** | 12px | 16px | 400 | text-xs |

### Tailwind Typography Setup

```typescript
// tailwind.config.ts
extend: {
  fontSize: {
    'xs': ['12px', { lineHeight: '16px' }],
    'sm': ['14px', { lineHeight: '20px' }],
    'base': ['16px', { lineHeight: '24px' }],
    'lg': ['18px', { lineHeight: '26px' }],
    'xl': ['20px', { lineHeight: '28px' }],
    '2xl': ['24px', { lineHeight: '32px' }],
    '3xl': ['30px', { lineHeight: '36px' }],
    '4xl': ['36px', { lineHeight: '44px' }],
    '5xl': ['48px', { lineHeight: '56px' }],
  },
  fontWeight: {
    thin: '100',
    extralight: '200',
    light: '300',
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    extrabold: '800',
    black: '900',
  },
}
```

### Common Text Styles

```tailwind
<!-- Hero Text -->
<h1 class="text-5xl font-bold text-text-primary">Welcome</h1>

<!-- Page Title -->
<h2 class="text-4xl font-bold text-text-primary">Dashboard</h2>

<!-- KPI Value -->
<span class="text-3xl font-bold text-primary">$45,231</span>

<!-- Section Title -->
<h3 class="text-2xl font-semibold text-text-primary">Recent Transactions</h3>

<!-- Card Title -->
<h4 class="text-xl font-semibold text-text-primary">Revenue</h4>

<!-- Body Text -->
<p class="text-base text-text-secondary">Secondary information</p>

<!-- Label -->
<label class="text-sm font-medium text-text-secondary">Email</label>

<!-- Helper Text -->
<p class="text-xs text-text-muted">Additional help text</p>
```

---

## 📏 Spacing System

### Base Unit: 4px

### Spacing Scale

| Token | Value | Tailwind Class |
|-------|-------|----------------|
| px | 1px | px |
| 0 | 0px | 0 |
| 1 | 4px | 1 |
| 2 | 8px | 2 |
| 3 | 12px | 3 |
| 4 | 16px | 4 |
| 5 | 20px | 5 |
| 6 | 24px | 6 |
| 8 | 32px | 8 |
| 10 | 40px | 10 |
| 12 | 48px | 12 |
| 16 | 64px | 16 |
| 20 | 80px | 20 |
| 24 | 96px | 24 |

### Semantic Spacing

```typescript
// tailwind.config.ts
spacing: {
  // Container widths
  container: '1440px',
  
  // Sidebar
  sidebar: '240px',
  'sidebar-collapsed': '80px',
  
  // Right panel
  'right-panel': '320px',
}
```

### Common Spacing Patterns

```tailwind
<!-- Page Padding -->
<div class="px-8 py-8">  <!-- 32px padding on all sides -->
  Content
</div>

<!-- Card Padding -->
<div class="p-6">  <!-- 24px padding -->
  Card content
</div>

<!-- Section Gap -->
<div class="flex flex-col gap-6">  <!-- 24px gap between items -->
  Items
</div>

<!-- Margin -->
<div class="mb-8">  <!-- 32px margin bottom -->
  Content
</div>
```

---

## 🔲 Border Radius

| Element | Radius | Tailwind Class |
|---------|--------|----------------|
| **Buttons** | 14px | rounded-lg |
| **Inputs** | 12px | rounded-md |
| **Cards** | 20px | rounded-2xl |
| **Modals/Dialogs** | 24px | rounded-3xl |
| **Badges** | 9999px | rounded-full |
| **Tables** | 16px | rounded-xl |
| **Charts** | 20px | rounded-2xl |

### Tailwind Radius Configuration

```typescript
// tailwind.config.ts
borderRadius: {
  none: '0',
  sm: '12px',   // inputs
  md: '14px',   // buttons
  lg: '16px',   // tables
  xl: '20px',   // cards, charts
  '2xl': '24px', // modals, dialogs
  full: '9999px', // badges
}
```

### Usage Examples

```tailwind
<!-- Button -->
<button class="px-4 py-2 rounded-md bg-primary text-white">
  Click me
</button>

<!-- Card -->
<div class="p-6 rounded-2xl bg-card border border-border">
  Card content
</div>

<!-- Input -->
<input class="px-3 py-2 rounded-md border border-border" type="text" />

<!-- Badge -->
<span class="px-3 py-1 rounded-full bg-primary text-white">
  New
</span>
```

---

## 💫 Shadows

### Light Theme Shadows

```css
/* Extra Small */
box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);

/* Small */
box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);

/* Medium (Default Card) */
box-shadow: 0 8px 30px rgba(15, 23, 42, 0.06);

/* Large */
box-shadow: 0 12px 40px rgba(15, 23, 42, 0.10);

/* Hover (Interactive) */
box-shadow: 0 12px 40px rgba(99, 102, 241, 0.15);
```

### Dark Theme Approach

**In dark mode, use subtle borders instead of shadows:**

```css
border: 1px solid rgba(35, 37, 51, 0.5);
```

### Tailwind Shadow Configuration

```typescript
// tailwind.config.ts
boxShadow: {
  xs: '0 1px 2px rgba(15, 23, 42, 0.04)',
  sm: '0 4px 12px rgba(15, 23, 42, 0.08)',
  md: '0 8px 30px rgba(15, 23, 42, 0.06)',
  lg: '0 12px 40px rgba(15, 23, 42, 0.10)',
  hover: '0 12px 40px rgba(99, 102, 241, 0.15)',
  none: 'none',
}
```

### Usage

```tailwind
<!-- Card with shadow -->
<div class="p-6 rounded-2xl bg-card shadow-md">
  Content
</div>

<!-- Hover effect -->
<div class="p-6 rounded-2xl bg-card shadow-md hover:shadow-hover transition-shadow">
  Hoverable content
</div>

<!-- Dark mode: border instead -->
<div class="p-6 rounded-2xl bg-card border border-border dark:border-dark-border shadow-md dark:shadow-none">
  Content
</div>
```

---

## 🎯 Icons

### Icon Library: Lucide React

```bash
npm install lucide-react
```

### Common Icon Sizes

| Size | Px | Usage |
|------|----|----|
| **sm** | 16px | Small buttons, labels |
| **md** | 20px | Regular buttons, nav items |
| **lg** | 24px | Card headers, section icons |
| **xl** | 32px | Large buttons, hero icons |

### Icon Usage

```typescript
import { 
  Dashboard, 
  Wallet, 
  Receipt, 
  BarChart3, 
  Users, 
  Settings,
  Sparkles,
  Calendar,
  Shield,
  Bell,
  Download,
  Upload,
  Globe,
  Moon,
  Sun
} from 'lucide-react';

// In component
<Dashboard size={20} className="text-primary" />
<Bell size={24} className="text-text-secondary" />
```

---

## 📱 Breakpoints

| Device | Width | Tailwind Prefix |
|--------|-------|-----------------|
| **Mobile** | 375px | *none* |
| **Small Mobile** | 640px | sm: |
| **Tablet** | 768px | md: |
| **Large Tablet** | 1024px | lg: |
| **Desktop** | 1280px | xl: |
| **Large Desktop** | 1536px | 2xl: |

### Mobile-First Approach

```tailwind
<!-- Mobile first: single column -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <!-- On mobile: 1 column -->
  <!-- On tablet: 2 columns -->
  <!-- On desktop: 3 columns -->
</div>

<!-- Hide on mobile, show on desktop -->
<div class="hidden lg:block">
  Desktop only content
</div>

<!-- Different padding per breakpoint -->
<div class="px-4 md:px-6 lg:px-8">
  Content
</div>
```

---

## 🌓 Dark Mode

### Setup in tailwind.config.ts

```typescript
// tailwind.config.ts
module.exports = {
  darkMode: 'class', // or 'media'
  // ...
}
```

### CSS Variables for Dark Mode

```css
/* globals.css */

@layer base {
  :root {
    /* Light theme colors */
    --background: #FFFFFF;
    --surface: #F7F8FC;
    --card: #FFFFFF;
    --border: #ECEEF5;
    --text-primary: #111827;
    --text-secondary: #6B7280;
    --text-muted: #9CA3AF;
    --primary: #6C4CF5;
    --primary-hover: #5B3FF0;
    --primary-active: #4A31D9;
  }

  .dark {
    /* Dark theme colors */
    --background: #0B1020;
    --surface: #1A2235;
    --card: #111827;
    --border: #232533;
    --text-primary: #F8FAFC;
    --text-secondary: #CBD5E1;
    --text-muted: #94A3B8;
    --primary: #6C4CF5;
    --primary-hover: #7E5CF5;
    --primary-active: #5B3FF0;
  }
}
```

### Using Dark Mode in Components

```tailwind
<!-- Text color changes with theme -->
<p class="text-text-primary dark:text-text-primary">
  Text that changes in dark mode
</p>

<!-- Background changes -->
<div class="bg-surface dark:bg-dark-surface">
  Adapts to theme
</div>

<!-- Complete component adaptation -->
<div class="bg-card dark:bg-dark-card border border-border dark:border-dark-border rounded-2xl shadow-md dark:shadow-none p-6">
  Card content
</div>
```

---

## ⚙️ Tailwind Configuration

### Complete tailwind.config.ts

```typescript
import type { Config } from 'tailwindcss'
import defaultTheme from 'tailwindcss/defaultTheme'

const config: Config = {
  darkMode: 'class',
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      // ====== COLORS ======
      colors: {
        primary: {
          50: '#F3ECFF',
          100: '#E8D9FF',
          200: '#D0B3FF',
          300: '#B88BFF',
          400: '#A168FF',
          500: '#6C4CF5', // base
          600: '#5B3FF0', // hover
          700: '#4A31D9', // active
          800: '#3A24A8',
          900: '#2A1977',
        },
        secondary: '#8B5CF6',
        accent: '#A78BFA',
        success: '#22C55E',
        warning: '#F59E0B',
        danger: '#EF4444',
        error: '#EF4444',
        info: '#3B82F6',

        // Light theme
        background: 'hsl(var(--background))',
        surface: 'hsl(var(--surface))',
        card: 'hsl(var(--card))',
        border: 'hsl(var(--border))',
        'text-primary': 'hsl(var(--text-primary))',
        'text-secondary': 'hsl(var(--text-secondary))',
        'text-muted': 'hsl(var(--text-muted))',
      },

      // ====== TYPOGRAPHY ======
      fontFamily: {
        inter: ['Inter', ...defaultTheme.fontFamily.sans],
        'jakarta': ['Plus Jakarta Sans', ...defaultTheme.fontFamily.sans],
        mono: ['JetBrains Mono', ...defaultTheme.fontFamily.mono],
      },
      fontSize: {
        'xs': ['12px', { lineHeight: '16px' }],
        'sm': ['14px', { lineHeight: '20px' }],
        'base': ['16px', { lineHeight: '24px' }],
        'lg': ['18px', { lineHeight: '26px' }],
        'xl': ['20px', { lineHeight: '28px' }],
        '2xl': ['24px', { lineHeight: '32px' }],
        '3xl': ['30px', { lineHeight: '36px' }],
        '4xl': ['36px', { lineHeight: '44px' }],
        '5xl': ['48px', { lineHeight: '56px' }],
      },

      // ====== SPACING ======
      spacing: {
        'sidebar': '240px',
        'sidebar-collapsed': '80px',
        'right-panel': '320px',
      },
      maxWidth: {
        container: '1440px',
      },

      // ====== BORDER RADIUS ======
      borderRadius: {
        'xs': '4px',
        'sm': '12px',
        'md': '14px',
        'lg': '16px',
        'xl': '20px',
        '2xl': '24px',
        'full': '9999px',
      },

      // ====== SHADOWS ======
      boxShadow: {
        'xs': '0 1px 2px rgba(15, 23, 42, 0.04)',
        'sm': '0 4px 12px rgba(15, 23, 42, 0.08)',
        'md': '0 8px 30px rgba(15, 23, 42, 0.06)',
        'lg': '0 12px 40px rgba(15, 23, 42, 0.10)',
        'hover': '0 12px 40px rgba(99, 102, 241, 0.15)',
      },

      // ====== ANIMATIONS ======
      animation: {
        'fade-in': 'fadeIn 0.2s ease-in-out',
        'slide-up': 'slideUp 0.25s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
      },
      keyframes: {
        fadeIn: {
          'from': { opacity: '0' },
          'to': { opacity: '1' },
        },
        slideUp: {
          'from': { transform: 'translateY(10px)', opacity: '0' },
          'to': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          'from': { transform: 'scale(0.95)', opacity: '0' },
          'to': { transform: 'scale(1)', opacity: '1' },
        },
      },

      // ====== TRANSITIONS ======
      transitionDuration: {
        'quick': '150ms',
        'base': '200ms',
        'slow': '250ms',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}

export default config
```

---

## 🎨 CSS Variables Setup

### globals.css

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700&family=JetBrains+Mono:wght@400;500&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

/* ====== COLOR VARIABLES ====== */

:root {
  /* Light Theme (default) */
  --background: #FFFFFF;
  --surface: #F7F8FC;
  --card: #FFFFFF;
  --border: #ECEEF5;
  --text-primary: #111827;
  --text-secondary: #6B7280;
  --text-muted: #9CA3AF;
  
  /* Primary Colors */
  --primary: #6C4CF5;
  --primary-hover: #5B3FF0;
  --primary-active: #4A31D9;
  --secondary: #8B5CF6;
  --accent: #A78BFA;
  
  /* Semantic */
  --success: #22C55E;
  --warning: #F59E0B;
  --danger: #EF4444;
  --info: #3B82F6;
}

.dark {
  /* Dark Theme */
  --background: #0B1020;
  --surface: #1A2235;
  --card: #111827;
  --border: #232533;
  --text-primary: #F8FAFC;
  --text-secondary: #CBD5E1;
  --text-muted: #94A3B8;
}

/* ====== REUSABLE UTILITIES ====== */

@layer components {
  /* Containers */
  .container-main {
    @apply max-w-container mx-auto px-8 py-8;
  }

  .container-md {
    @apply max-w-4xl mx-auto;
  }

  /* Cards */
  .card {
    @apply bg-card rounded-2xl shadow-md;
  }

  .card-padding {
    @apply p-6;
  }

  .card-hover {
    @apply hover:shadow-lg transition-shadow;
  }

  /* Typography */
  .text-hero {
    @apply text-5xl font-bold text-text-primary;
  }

  .text-page-title {
    @apply text-4xl font-bold text-text-primary;
  }

  .text-section-title {
    @apply text-2xl font-semibold text-text-primary;
  }

  .text-card-title {
    @apply text-xl font-semibold text-text-primary;
  }

  .text-body {
    @apply text-base text-text-secondary;
  }

  .text-label {
    @apply text-sm font-medium text-text-secondary;
  }

  .text-helper {
    @apply text-xs text-text-muted;
  }

  /* Buttons */
  .btn-primary {
    @apply px-4 py-2.5 rounded-md bg-primary text-white font-medium 
           hover:bg-primary-hover active:bg-primary-active 
           transition-colors duration-quick disabled:opacity-50;
  }

  .btn-secondary {
    @apply px-4 py-2.5 rounded-md border border-border bg-surface text-text-primary font-medium 
           hover:bg-surface/80 active:bg-surface/60 
           transition-colors duration-quick;
  }

  .btn-ghost {
    @apply px-4 py-2.5 rounded-md text-primary font-medium 
           hover:bg-primary/10 active:bg-primary/20 
           transition-colors duration-quick;
  }

  .btn-danger {
    @apply px-4 py-2.5 rounded-md bg-danger text-white font-medium 
           hover:opacity-90 active:opacity-80 
           transition-opacity duration-quick;
  }

  /* Inputs */
  .input-base {
    @apply w-full px-3 py-2 rounded-md border border-border 
           bg-card text-text-primary placeholder-text-muted
           focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent
           transition-all duration-quick disabled:opacity-50;
  }

  .input-error {
    @apply border-danger focus:ring-danger;
  }

  .input-success {
    @apply border-success focus:ring-success;
  }

  /* Badges */
  .badge-primary {
    @apply inline-flex items-center px-3 py-1 rounded-full 
           bg-primary/10 text-primary text-sm font-medium;
  }

  .badge-success {
    @apply inline-flex items-center px-3 py-1 rounded-full 
           bg-success/10 text-success text-sm font-medium;
  }

  .badge-warning {
    @apply inline-flex items-center px-3 py-1 rounded-full 
           bg-warning/10 text-warning text-sm font-medium;
  }

  .badge-danger {
    @apply inline-flex items-center px-3 py-1 rounded-full 
           bg-danger/10 text-danger text-sm font-medium;
  }

  /* Layout */
  .sidebar-layout {
    @apply flex h-screen bg-background;
  }

  .content-wrapper {
    @apply flex-1 flex flex-col overflow-hidden;
  }

  .page-content {
    @apply flex-1 overflow-y-auto bg-background;
  }

  /* Divider */
  .divider {
    @apply h-px bg-border;
  }

  /* Focus Ring */
  .focus-ring {
    @apply focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2;
  }
}

/* ====== ANIMATIONS ====== */

@layer utilities {
  /* Smooth transitions */
  .transition-quick {
    @apply transition-all duration-150;
  }

  .transition-base {
    @apply transition-all duration-200;
  }

  .transition-slow {
    @apply transition-all duration-250;
  }

  /* Scrollbar styling */
  .scrollbar-thin {
    scrollbar-width: thin;
    scrollbar-color: rgba(107, 114, 128, 0.5) transparent;
  }

  .scrollbar-thin::-webkit-scrollbar {
    width: 8px;
  }

  .scrollbar-thin::-webkit-scrollbar-track {
    background: transparent;
  }

  .scrollbar-thin::-webkit-scrollbar-thumb {
    background-color: rgba(107, 114, 128, 0.5);
    border-radius: 4px;
  }

  .dark .scrollbar-thin::-webkit-scrollbar-thumb {
    background-color: rgba(71, 85, 105, 0.5);
  }
}
```

---

## 💻 Component Examples

### Button Component

```typescript
// components/ui/Button.tsx
import React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition-colors duration-quick focus-ring disabled:opacity-50 disabled:cursor-not-allowed',
  {
    variants: {
      variant: {
        primary: 'bg-primary text-white hover:bg-primary-hover active:bg-primary-active',
        secondary: 'bg-surface text-text-primary border border-border hover:bg-surface/80',
        ghost: 'text-primary hover:bg-primary/10',
        danger: 'bg-danger text-white hover:opacity-90',
      },
      size: {
        sm: 'px-3 py-2 text-sm',
        md: 'px-4 py-2.5 text-base',
        lg: 'px-6 py-3 text-lg',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
)

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>, VariantProps<typeof buttonVariants> {}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => (
    <button
      className={buttonVariants({ variant, size, className })}
      ref={ref}
      {...props}
    />
  )
)

Button.displayName = 'Button'

export { Button, buttonVariants }
```

### Card Component

```typescript
// components/ui/Card.tsx
import React from 'react'

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  hoverable?: boolean
}

const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, hoverable = false, ...props }, ref) => (
    <div
      ref={ref}
      className={`rounded-2xl bg-card shadow-md ${hoverable ? 'hover:shadow-lg transition-shadow' : ''} ${className || ''}`}
      {...props}
    />
  )
)

Card.displayName = 'Card'

const CardContent = ({ className = '', ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={`p-6 ${className}`} {...props} />
)

export { Card, CardContent }
```

### Input Component

```typescript
// components/ui/Input.tsx
import React from 'react'

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
  success?: boolean
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, error, success, ...props }, ref) => {
    let errorClass = ''
    if (error) errorClass = 'border-danger focus:ring-danger'
    if (success) errorClass = 'border-success focus:ring-success'

    return (
      <input
        ref={ref}
        className={`w-full px-3 py-2 rounded-md border border-border bg-card text-text-primary placeholder-text-muted focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all duration-quick disabled:opacity-50 ${errorClass} ${className || ''}`}
        {...props}
      />
    )
  }
)

Input.displayName = 'Input'

export { Input }
```

### Badge Component

```typescript
// components/ui/Badge.tsx
import React from 'react'

interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'primary' | 'success' | 'warning' | 'danger' | 'neutral'
}

const Badge: React.FC<BadgeProps> = ({ variant = 'primary', className, ...props }) => {
  const variants: Record<string, string> = {
    primary: 'bg-primary/10 text-primary',
    success: 'bg-success/10 text-success',
    warning: 'bg-warning/10 text-warning',
    danger: 'bg-danger/10 text-danger',
    neutral: 'bg-surface text-text-secondary',
  }

  return (
    <div
      className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${variants[variant]} ${className || ''}`}
      {...props}
    />
  )
}

export { Badge }
```

---

## 📚 Usage Guide

### Step 1: Install Dependencies

```bash
npm install -D tailwindcss postcss autoprefixer next-themes
npm install lucide-react
npm install -D @tailwindcss/forms
```

### Step 2: Update tailwind.config.ts

Use the configuration from the [Tailwind Configuration](#⚙️-tailwind-configuration) section above.

### Step 3: Update globals.css

Use the CSS from the [CSS Variables Setup](#🎨-css-variables-setup) section above.

### Step 4: Apply in Components

```typescript
// Light/Dark aware component
<div className="bg-card border border-border rounded-2xl shadow-md p-6">
  <h3 className="text-card-title mb-2">Card Title</h3>
  <p className="text-body">Card content</p>
</div>

// Button with variants
<Button variant="primary" size="md">
  Click me
</Button>

// Responsive layout
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <Card>Item 1</Card>
  <Card>Item 2</Card>
  <Card>Item 3</Card>
</div>

// Dark mode
<div className="bg-background dark:bg-dark-background">
  <p className="text-text-primary dark:text-dark-text-primary">
    Content
  </p>
</div>
```

### Step 5: Using CSS Variables

```css
/* You can also use CSS variables directly */
.custom-element {
  background-color: var(--primary);
  color: var(--text-primary);
  border-color: var(--border);
}
```

---

## ✅ Quick Checklist

Before building components, ensure:

- [ ] Tailwind config includes all colors, fonts, spacing
- [ ] globals.css has all CSS variables defined
- [ ] Dark mode works (toggle in browser dev tools)
- [ ] Fonts are properly imported from Google Fonts
- [ ] All Lucide icons are installed
- [ ] Theme toggle component is working
- [ ] RTL layout works for Arabic
- [ ] Responsive breakpoints tested
- [ ] Component library installed (shadcn/ui)
- [ ] Accessibility basics tested (focus states, contrast)

---

## 🎨 Color Reference Card

Print this for quick reference:

```
PRIMARY:        #6C4CF5 (hover: #5B3FF0, active: #4A31D9)
SECONDARY:      #8B5CF6
ACCENT:         #A78BFA
SUCCESS:        #22C55E
WARNING:        #F59E0B
DANGER:         #EF4444

LIGHT THEME:
  Background:   #FFFFFF
  Surface:      #F7F8FC
  Border:       #ECEEF5
  Text Primary: #111827

DARK THEME:
  Background:   #0B1020
  Surface:      #1A2235
  Border:       #232533
  Text Primary: #F8FAFC

TYPOGRAPHY:
  Font:         Inter (UI), Plus Jakarta Sans (Hero), JetBrains Mono (Code)
  Sizes:        12/14/16/18/20/24/30/36/48px

SPACING:
  Base Unit:    4px
  Scale:        4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96

RADIUS:
  Inputs:       12px (rounded-md)
  Buttons:      14px (rounded-md)
  Cards:        20px (rounded-2xl)
  Modals:       24px (rounded-3xl)
  Badges:       9999px (rounded-full)

SHADOWS:
  Light:        0 8px 30px rgba(15,23,42,.06)
  Hover:        0 12px 40px rgba(99,102,241,.15)
  Dark:         Use borders instead
```

---

## 📞 Support

For questions or issues:
1. Check the Tailwind CSS documentation: https://tailwindcss.com
2. Review AFAB design system documentation
3. Test in your browser's dev tools
4. Verify CSS variables are loading in computed styles

