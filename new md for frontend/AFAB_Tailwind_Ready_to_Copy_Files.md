# AFAB Tailwind CSS - Ready-to-Copy Code Files

**Copy and paste these files directly into your project**

---

## 📂 File Structure

```
src/
├── app/
│   ├── globals.css          ← COPY THIS
│   └── layout.tsx
├── lib/
│   └── cn.ts                ← COPY THIS
├── components/
│   └── ui/
│       ├── Button.tsx       ← COPY THIS
│       ├── Card.tsx         ← COPY THIS
│       ├── Input.tsx        ← COPY THIS
│       └── Badge.tsx        ← COPY THIS
└── config/
    └── theme.ts             ← COPY THIS (optional)

tailwind.config.ts           ← COPY THIS
postcss.config.js            ← COPY THIS
```

---

## 1️⃣ tailwind.config.ts

**Location:** Root of project

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
      colors: {
        primary: {
          50: '#F3ECFF',
          100: '#E8D9FF',
          200: '#D0B3FF',
          300: '#B88BFF',
          400: '#A168FF',
          500: '#6C4CF5',
          600: '#5B3FF0',
          700: '#4A31D9',
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
      },
      fontFamily: {
        inter: ['var(--font-inter)', ...defaultTheme.fontFamily.sans],
        jakarta: ['var(--font-jakarta)', ...defaultTheme.fontFamily.sans],
        mono: ['var(--font-mono)', ...defaultTheme.fontFamily.mono],
      },
      fontSize: {
        xs: ['12px', { lineHeight: '16px' }],
        sm: ['14px', { lineHeight: '20px' }],
        base: ['16px', { lineHeight: '24px' }],
        lg: ['18px', { lineHeight: '26px' }],
        xl: ['20px', { lineHeight: '28px' }],
        '2xl': ['24px', { lineHeight: '32px' }],
        '3xl': ['30px', { lineHeight: '36px' }],
        '4xl': ['36px', { lineHeight: '44px' }],
        '5xl': ['48px', { lineHeight: '56px' }],
      },
      spacing: {
        sidebar: '240px',
        'sidebar-collapsed': '80px',
        'right-panel': '320px',
      },
      maxWidth: {
        container: '1440px',
      },
      borderRadius: {
        xs: '4px',
        sm: '12px',
        md: '14px',
        lg: '16px',
        xl: '20px',
        '2xl': '24px',
        full: '9999px',
      },
      boxShadow: {
        xs: '0 1px 2px rgba(15, 23, 42, 0.04)',
        sm: '0 4px 12px rgba(15, 23, 42, 0.08)',
        md: '0 8px 30px rgba(15, 23, 42, 0.06)',
        lg: '0 12px 40px rgba(15, 23, 42, 0.10)',
        hover: '0 12px 40px rgba(99, 102, 241, 0.15)',
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-in-out',
        'slide-up': 'slideUp 0.25s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
      },
      keyframes: {
        fadeIn: {
          from: { opacity: '0' },
          to: { opacity: '1' },
        },
        slideUp: {
          from: { transform: 'translateY(10px)', opacity: '0' },
          to: { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          from: { transform: 'scale(0.95)', opacity: '0' },
          to: { transform: 'scale(1)', opacity: '1' },
        },
      },
      transitionDuration: {
        quick: '150ms',
        base: '200ms',
        slow: '250ms',
      },
    },
  },
  plugins: [],
}

export default config
```

---

## 2️⃣ postcss.config.js

**Location:** Root of project

```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

---

## 3️⃣ src/app/globals.css

**Location:** `src/app/globals.css`

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700&family=JetBrains+Mono:wght@400;500&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

/* ====== ROOT VARIABLES ====== */

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

  /* Primary stays same in dark */
  --primary: #6C4CF5;
  --primary-hover: #7E5CF5;
  --primary-active: #5B3FF0;
}

/* ====== BASE STYLES ====== */

* {
  @apply border-border;
}

html {
  @apply scroll-smooth;
}

body {
  @apply bg-background text-text-primary transition-colors duration-base;
  font-family: Inter, system-ui, -apple-system, sans-serif;
}

/* ====== REUSABLE COMPONENTS ====== */

@layer components {
  /* -------- CONTAINERS -------- */
  .container-main {
    @apply max-w-container mx-auto px-8 py-8;
  }

  .container-md {
    @apply max-w-4xl mx-auto px-6 py-6;
  }

  /* -------- CARDS -------- */
  .card {
    @apply bg-card rounded-2xl shadow-md;
  }

  .card-padding {
    @apply p-6;
  }

  .card-hover {
    @apply hover:shadow-lg transition-shadow duration-quick;
  }

  /* -------- TYPOGRAPHY -------- */
  .text-hero {
    @apply text-5xl font-bold text-text-primary;
  }

  .text-page-title {
    @apply text-4xl font-bold text-text-primary;
  }

  .text-kpi {
    @apply text-3xl font-bold text-text-primary;
  }

  .text-section-title {
    @apply text-2xl font-semibold text-text-primary;
  }

  .text-card-title {
    @apply text-xl font-semibold text-text-primary;
  }

  .text-table-header {
    @apply text-lg font-semibold text-text-primary;
  }

  .text-body {
    @apply text-base text-text-secondary;
  }

  .text-body-sm {
    @apply text-sm text-text-secondary;
  }

  .text-label {
    @apply text-sm font-medium text-text-secondary;
  }

  .text-helper {
    @apply text-xs text-text-muted;
  }

  /* -------- BUTTONS -------- */
  .btn-primary {
    @apply inline-flex items-center justify-center px-4 py-2.5 rounded-md
           bg-primary text-white font-medium
           hover:bg-primary-hover active:bg-primary-active
           transition-colors duration-quick
           disabled:opacity-50 disabled:cursor-not-allowed
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2;
  }

  .btn-secondary {
    @apply inline-flex items-center justify-center px-4 py-2.5 rounded-md
           border border-border bg-surface text-text-primary font-medium
           hover:bg-surface/80 active:bg-surface/60
           transition-colors duration-quick
           disabled:opacity-50 disabled:cursor-not-allowed
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2;
  }

  .btn-ghost {
    @apply inline-flex items-center justify-center px-4 py-2.5 rounded-md
           text-primary font-medium
           hover:bg-primary/10 active:bg-primary/20
           transition-colors duration-quick
           disabled:opacity-50 disabled:cursor-not-allowed
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2;
  }

  .btn-outline {
    @apply inline-flex items-center justify-center px-4 py-2.5 rounded-md
           border-2 border-primary text-primary font-medium
           hover:bg-primary/5 active:bg-primary/10
           transition-colors duration-quick
           disabled:opacity-50 disabled:cursor-not-allowed
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2;
  }

  .btn-danger {
    @apply inline-flex items-center justify-center px-4 py-2.5 rounded-md
           bg-danger text-white font-medium
           hover:opacity-90 active:opacity-80
           transition-opacity duration-quick
           disabled:opacity-50 disabled:cursor-not-allowed
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-danger focus-visible:ring-offset-2;
  }

  .btn-sm {
    @apply px-3 py-1.5 text-sm;
  }

  .btn-lg {
    @apply px-6 py-3 text-lg;
  }

  /* -------- INPUTS -------- */
  .input-base {
    @apply w-full px-3 py-2 rounded-md border border-border
           bg-card text-text-primary placeholder-text-muted
           focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent
           transition-all duration-quick
           disabled:opacity-50 disabled:cursor-not-allowed;
  }

  .input-error {
    @apply border-danger focus:ring-danger;
  }

  .input-success {
    @apply border-success focus:ring-success;
  }

  .input-lg {
    @apply px-4 py-3 text-lg;
  }

  /* -------- LABELS -------- */
  .label-base {
    @apply block text-label font-medium text-text-secondary mb-2;
  }

  /* -------- BADGES -------- */
  .badge-primary {
    @apply inline-flex items-center gap-2 px-3 py-1 rounded-full
           bg-primary/10 text-primary text-sm font-medium;
  }

  .badge-success {
    @apply inline-flex items-center gap-2 px-3 py-1 rounded-full
           bg-success/10 text-success text-sm font-medium;
  }

  .badge-warning {
    @apply inline-flex items-center gap-2 px-3 py-1 rounded-full
           bg-warning/10 text-warning text-sm font-medium;
  }

  .badge-danger {
    @apply inline-flex items-center gap-2 px-3 py-1 rounded-full
           bg-danger/10 text-danger text-sm font-medium;
  }

  .badge-neutral {
    @apply inline-flex items-center gap-2 px-3 py-1 rounded-full
           bg-surface text-text-secondary text-sm font-medium;
  }

  /* -------- LAYOUT -------- */
  .sidebar-layout {
    @apply flex h-screen bg-background;
  }

  .content-wrapper {
    @apply flex-1 flex flex-col overflow-hidden;
  }

  .page-content {
    @apply flex-1 overflow-y-auto bg-background;
  }

  /* -------- DIVIDERS -------- */
  .divider {
    @apply h-px bg-border;
  }

  .divider-vertical {
    @apply w-px bg-border;
  }

  /* -------- FOCUS STATES -------- */
  .focus-ring {
    @apply focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2;
  }

  /* -------- TRANSITIONS -------- */
  .transition-quick {
    @apply transition-all duration-150;
  }

  .transition-base {
    @apply transition-all duration-200;
  }

  .transition-slow {
    @apply transition-all duration-250;
  }
}

/* ====== SCROLLBAR STYLING ====== */

.scrollbar-thin {
  scrollbar-width: thin;
  scrollbar-color: rgba(107, 114, 128, 0.5) transparent;
}

.scrollbar-thin::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}

.scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: rgba(107, 114, 128, 0.5);
  border-radius: 4px;
  border: 2px solid transparent;
  background-clip: content-box;
}

.scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background-color: rgba(107, 114, 128, 0.7);
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: rgba(71, 85, 105, 0.5);
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background-color: rgba(71, 85, 105, 0.7);
}

/* ====== DARK MODE SPECIFIC ====== */

.dark {
  color-scheme: dark;
}

/* Use borders in dark mode instead of shadows */
.dark .card {
  @apply shadow-none border border-border;
}
```

---

## 4️⃣ src/lib/cn.ts

**Location:** `src/lib/cn.ts`

```typescript
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

/**
 * Merge Tailwind CSS classes with clsx for conditional classes
 * and twMerge to resolve conflicting Tailwind classes
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

**Install dependencies:**
```bash
npm install clsx tailwind-merge
```

---

## 5️⃣ src/components/ui/Button.tsx

**Location:** `src/components/ui/Button.tsx`

```typescript
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/cn'

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition-colors duration-quick focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed',
  {
    variants: {
      variant: {
        primary:
          'bg-primary text-white hover:bg-primary-hover active:bg-primary-active',
        secondary:
          'bg-surface text-text-primary border border-border hover:bg-surface/80 active:bg-surface/60',
        ghost: 'text-primary hover:bg-primary/10 active:bg-primary/20',
        outline:
          'border-2 border-primary text-primary hover:bg-primary/5 active:bg-primary/10',
        danger:
          'bg-danger text-white hover:opacity-90 active:opacity-80',
        success:
          'bg-success text-white hover:opacity-90 active:opacity-80',
      },
      size: {
        sm: 'px-3 py-1.5 text-sm',
        md: 'px-4 py-2.5 text-base',
        lg: 'px-6 py-3 text-lg',
        icon: 'h-10 w-10 p-0',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => (
    <button
      className={cn(buttonVariants({ variant, size, className }))}
      ref={ref}
      {...props}
    />
  )
)

Button.displayName = 'Button'

export { Button, buttonVariants }
```

**Install dependencies:**
```bash
npm install class-variance-authority
```

---

## 6️⃣ src/components/ui/Card.tsx

**Location:** `src/components/ui/Card.tsx`

```typescript
import * as React from 'react'
import { cn } from '@/lib/cn'

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  hoverable?: boolean
  bordered?: boolean
}

const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, hoverable = false, bordered = false, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        'rounded-2xl bg-card shadow-md',
        hoverable && 'hover:shadow-lg transition-shadow duration-quick',
        bordered && 'border border-border',
        'dark:shadow-none dark:border dark:border-border',
        className
      )}
      {...props}
    />
  )
)

Card.displayName = 'Card'

const CardHeader = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn('flex flex-col space-y-1.5 p-6 border-b border-border', className)}
      {...props}
    />
  )
)

CardHeader.displayName = 'CardHeader'

const CardTitle = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, ...props }, ref) => (
    <h2
      ref={ref}
      className={cn('text-card-title font-semibold leading-none tracking-tight', className)}
      {...props}
    />
  )
)

CardTitle.displayName = 'CardTitle'

const CardDescription = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLParagraphElement>>(
  ({ className, ...props }, ref) => (
    <p ref={ref} className={cn('text-sm text-text-secondary', className)} {...props} />
  )
)

CardDescription.displayName = 'CardDescription'

const CardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('p-6 pt-0', className)} {...props} />
  )
)

CardContent.displayName = 'CardContent'

const CardFooter = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn('flex items-center p-6 pt-0', className)}
      {...props}
    />
  )
)

CardFooter.displayName = 'CardFooter'

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }
```

---

## 7️⃣ src/components/ui/Input.tsx

**Location:** `src/components/ui/Input.tsx`

```typescript
import * as React from 'react'
import { cn } from '@/lib/cn'

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
  success?: boolean
  label?: string
  helperText?: string
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, error, success, label, helperText, ...props }, ref) => {
    let stateClass = ''
    if (error) stateClass = 'border-danger focus:ring-danger'
    if (success) stateClass = 'border-success focus:ring-success'

    return (
      <div className="w-full">
        {label && (
          <label className="label-base">
            {label}
          </label>
        )}
        <input
          type={type}
          className={cn(
            'input-base',
            stateClass,
            className
          )}
          ref={ref}
          {...props}
        />
        {helperText && (
          <p className={cn(
            'text-helper mt-1',
            error && 'text-danger',
            success && 'text-success'
          )}>
            {helperText}
          </p>
        )}
      </div>
    )
  }
)

Input.displayName = 'Input'

export { Input }
```

---

## 8️⃣ src/components/ui/Badge.tsx

**Location:** `src/components/ui/Badge.tsx`

```typescript
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/cn'

const badgeVariants = cva(
  'inline-flex items-center gap-2 rounded-full text-sm font-medium',
  {
    variants: {
      variant: {
        primary: 'bg-primary/10 text-primary',
        success: 'bg-success/10 text-success',
        warning: 'bg-warning/10 text-warning',
        danger: 'bg-danger/10 text-danger',
        info: 'bg-info/10 text-info',
        neutral: 'bg-surface text-text-secondary',
      },
    },
    defaultVariants: {
      variant: 'neutral',
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  )
}

export { Badge, badgeVariants }
```

---

## 9️⃣ src/app/layout.tsx

**Location:** `src/app/layout.tsx` (Updated)

```typescript
import type { Metadata } from 'next'
import { Inter, Plus_Jakarta_Sans, JetBrains_Mono } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
})

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-jakarta',
  weight: ['600', '700'],
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
})

export const metadata: Metadata = {
  title: 'AFAB - AI Finance Assistant for Business',
  description: 'Manage your business finances with AI-powered insights',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${inter.variable} ${plusJakarta.variable} ${jetbrainsMono.variable}`}>
        {children}
      </body>
    </html>
  )
}
```

---

## 🔟 Example Component Usage

**Location:** `src/components/examples/FormExample.tsx`

```typescript
'use client'

import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'

export default function FormExample() {
  return (
    <div className="max-w-container mx-auto p-8">
      {/* Page Title */}
      <h1 className="text-page-title mb-8">Settings</h1>

      {/* Card */}
      <Card hoverable className="mb-8">
        <CardHeader>
          <CardTitle>Business Information</CardTitle>
          <CardDescription>Update your business details</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            {/* Input Field */}
            <Input
              label="Business Name"
              placeholder="Enter your business name"
              helperText="This will appear on invoices"
            />

            {/* Input with Error */}
            <Input
              label="Email"
              type="email"
              placeholder="your@email.com"
              error={true}
              helperText="This email is already in use"
            />

            {/* Badges */}
            <div className="flex gap-2">
              <Badge variant="success">Active</Badge>
              <Badge variant="warning">Pending Review</Badge>
              <Badge variant="danger">Subscription Expired</Badge>
            </div>

            {/* Buttons */}
            <div className="flex gap-3 pt-4">
              <Button variant="primary">Save Changes</Button>
              <Button variant="secondary">Cancel</Button>
              <Button variant="ghost">Reset</Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Typography Examples */}
      <Card>
        <CardHeader>
          <CardTitle>Typography Scale</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <h1 className="text-hero">Hero Text (48px)</h1>
          <h2 className="text-page-title">Page Title (36px)</h2>
          <h3 className="text-section-title">Section Title (24px)</h3>
          <h4 className="text-card-title">Card Title (20px)</h4>
          <p className="text-body">Body text (16px) - Main content goes here</p>
          <p className="text-body-sm">Small body text (14px) - Secondary information</p>
          <p className="text-label">Label text (14px medium)</p>
          <p className="text-helper">Helper text (12px) - Additional guidance</p>
        </CardContent>
      </Card>
    </div>
  )
}
```

---

## ✅ Installation Checklist

```bash
# 1. Install Tailwind CSS
npm install -D tailwindcss postcss autoprefixer

# 2. Install dependencies for components
npm install clsx tailwind-merge class-variance-authority

# 3. Install fonts (optional, if not using Google Fonts)
npm install next-fonts

# 4. Install theme switcher (for dark mode)
npm install next-themes

# 5. Install form handling (optional)
npm install react-hook-form zod

# 6. Install UI icons
npm install lucide-react
```

---

## 🚀 Quick Start

1. **Copy `tailwind.config.ts`** to root
2. **Copy `postcss.config.js`** to root
3. **Copy `src/app/globals.css`** to your project
4. **Copy `src/lib/cn.ts`** to your project
5. **Copy component files** to `src/components/ui/`
6. **Update `src/app/layout.tsx`** with font configuration
7. **Run `npm install`** for new dependencies
8. **Start building components!**

---

## 🎨 Using Components

```typescript
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'

export default function MyPage() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Title</CardTitle>
      </CardHeader>
      <CardContent>
        <Input label="Name" placeholder="Enter name" />
        <Badge variant="success">Active</Badge>
        <Button variant="primary">Save</Button>
      </CardContent>
    </Card>
  )
}
```

---

## 🎨 Tailwind Classes Quick Reference

```tailwind
<!-- Text Sizing -->
text-xs, text-sm, text-base, text-lg, text-xl, text-2xl, text-3xl, text-4xl, text-5xl

<!-- Font Weight -->
font-light, font-normal, font-medium, font-semibold, font-bold, font-black

<!-- Colors -->
bg-primary, text-primary, border-border, bg-success, text-danger

<!-- Spacing -->
p-4, px-6, py-2, m-8, mt-4, mb-2, gap-6

<!-- Flexbox -->
flex, flex-col, items-center, justify-between, gap-4

<!-- Grid -->
grid, grid-cols-2, md:grid-cols-3, lg:grid-cols-4

<!-- Responsive -->
block, hidden, sm:block, md:hidden, lg:flex

<!-- Dark Mode -->
dark:bg-card, dark:text-text-primary, dark:border-border

<!-- Transitions -->
transition-all, duration-quick, duration-base, duration-slow
```

---

## 📱 Responsive Layout Example

```typescript
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <Card>Item 1</Card>
  <Card>Item 2</Card>
  <Card>Item 3</Card>
</div>

<!-- Mobile: 1 column -->
<!-- Tablet (md): 2 columns -->
<!-- Desktop (lg): 3 columns -->
```

---

## ✨ All Ready!

All files are ready to copy and paste. Start with the core files first, then add components as needed.

For questions, refer back to the **AFAB_Tailwind_CSS_Design_System.md** guide.

