import type {Config} from 'tailwindcss';

const config: Config = {
  darkMode: 'class',
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: '1rem',
        sm: '1.25rem',
        lg: '2rem',
        xl: '2.5rem',
        '2xl': '3rem'
      },
      screens: {
        '2xl': '1440px'
      }
    },
    extend: {
      colors: {
        background: 'var(--background)',
        foreground: 'var(--foreground)',
        surface: 'var(--surface)',
        card: 'var(--card)',
        'card-foreground': 'var(--card-foreground)',
        popover: 'var(--popover)',
        'popover-foreground': 'var(--popover-foreground)',
        primary: 'var(--primary)',
        'primary-foreground': 'var(--primary-foreground)',
        secondary: 'var(--secondary)',
        'secondary-foreground': 'var(--secondary-foreground)',
        accent: 'var(--accent)',
        'accent-foreground': 'var(--accent-foreground)',
        muted: 'var(--muted)',
        'muted-foreground': 'var(--muted-foreground)',
        success: 'var(--success)',
        warning: 'var(--warning)',
        danger: 'var(--danger)',
        destructive: 'var(--destructive)',
        'destructive-foreground': 'var(--destructive-foreground)',
        border: 'var(--border)',
        input: 'var(--input)',
        ring: 'var(--ring)',
        overlay: 'var(--overlay)',
        nav: 'var(--nav-background)',
        'nav-foreground': 'var(--nav-foreground)',
        sidebar: 'var(--sidebar-background)',
        'sidebar-foreground': 'var(--sidebar-foreground)',
        'sidebar-active': 'var(--sidebar-active)',
        'sidebar-active-foreground': 'var(--sidebar-active-foreground)',
        'sidebar-hover': 'var(--sidebar-hover)',
        'chart-1': 'var(--chart-1)',
        'chart-2': 'var(--chart-2)',
        'chart-3': 'var(--chart-3)',
        'chart-4': 'var(--chart-4)',
        'chart-5': 'var(--chart-5)'
      },
      spacing: {
        18: 'var(--space-18)',
        22: 'var(--space-22)',
        30: 'var(--space-30)'
      },
      borderRadius: {
        xs: 'var(--radius-xs)',
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
        '2xl': 'var(--radius-2xl)'
      },
      boxShadow: {
        xs: 'var(--shadow-xs)',
        sm: 'var(--shadow-sm)',
        md: 'var(--shadow-md)',
        lg: 'var(--shadow-lg)',
        glass: 'var(--shadow-glass)'
      },
      transitionDuration: {
        fast: 'var(--duration-fast)',
        normal: 'var(--duration-normal)',
        slow: 'var(--duration-slow)'
      },
      transitionTimingFunction: {
        premium: 'var(--ease-premium)'
      },
      opacity: {
        disabled: 'var(--opacity-disabled)'
      },
      zIndex: {
        header: 'var(--z-header)',
        sidebar: 'var(--z-sidebar)',
        drawer: 'var(--z-drawer)',
        modal: 'var(--z-modal)',
        popover: 'var(--z-popover)',
        toast: 'var(--z-toast)'
      },
      maxWidth: {
        dashboard: 'var(--container-dashboard)',
        content: 'var(--container-content)',
        modal: 'var(--modal-width)',
        drawer: 'var(--drawer-width)'
      },
      width: {
        sidebar: 'var(--sidebar-width)',
        'sidebar-collapsed': 'var(--sidebar-collapsed-width)',
        drawer: 'var(--drawer-width)'
      },
      height: {
        navbar: 'var(--navbar-height)',
        'button-sm': 'var(--button-sm)',
        'button-md': 'var(--button-md)',
        'button-lg': 'var(--button-lg)',
        'input-md': 'var(--input-md)'
      },
      minHeight: {
        navbar: 'var(--navbar-height)'
      },
      fontSize: {
        display: 'var(--text-display)',
        h1: 'var(--text-h1)',
        h2: 'var(--text-h2)',
        h3: 'var(--text-h3)',
        h4: 'var(--text-h4)',
        title: 'var(--text-title)',
        subtitle: 'var(--text-subtitle)',
        bodylg: 'var(--text-body-lg)',
        body: 'var(--text-body)',
        bodysm: 'var(--text-body-sm)',
        caption: 'var(--text-caption)',
        overline: 'var(--text-overline)',
        label: 'var(--text-label)',
        button: 'var(--text-button)',
        table: 'var(--text-table)',
        nav: 'var(--text-nav)',
        sidebar: 'var(--text-sidebar)',
        kpi: 'var(--text-kpi)'
      },
      fontFamily: {
        sans: ['var(--font-sans)']
      },
      backdropBlur: {
        glass: 'var(--blur-glass)'
      },
      screens: {
        xs: '420px',
        '3xl': '1680px'
      }
    }
  }
};

export default config;
