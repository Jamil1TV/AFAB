import type { Metadata } from "next";
import { Inter, Poppins, Geist_Mono } from "next/font/google";
import { NextIntlClientProvider } from 'next-intl';
import { getMessages } from 'next-intl/server';
import { notFound } from 'next/navigation';
import { routing } from '@/i18n/routing';
import { ThemeProvider } from "@/components/theme-provider";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Toaster } from "@/components/ui/sonner";
import { ScrollToTop } from "@/components/scroll-to-top";
import { ChunkErrorRecovery } from "@/components/ChunkErrorRecovery";
import "../globals.css";

/* ──────────────────────────────────────────────────────
   AFAB Premium Typography
   Inter (body) & Poppins (headlines)
   ────────────────────────────────────────────────────── */
const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

const poppins = Poppins({
  variable: "--font-heading",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "AFAB — AI Finance Assistant for Business",
  description:
    "Enterprise-grade financial management powered by intelligent automation. Track income, expenses, budgets, and investments with AI-driven insights.",
  keywords: [
    "finance",
    "AI",
    "business",
    "accounting",
    "budgeting",
    "expense tracking",
  ],
};

export default async function RootLayout({
  children,
  params
}: Readonly<{
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}>) {
  const { locale } = await params;

  // Ensure that the incoming `locale` is valid
  if (!routing.locales.includes(locale as any)) {
    notFound();
  }

  // Providing all messages to the client
  // side is the easiest way to get started
  const messages = await getMessages();

  // Determine text direction
  const dir = locale === 'ar' ? 'rtl' : 'ltr';

  return (
    <html
      lang={locale}
      dir={dir}
      suppressHydrationWarning
      data-scroll-behavior="smooth"
      className={`${inter.variable} ${poppins.variable} ${geistMono.variable}`}
    >
            <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Amiri:ital,wght@0,400;0,700;1,400&family=Cairo:wght@600;700;800;900&family=Cinzel:wght@600;700;800;900&family=JetBrains+Mono:wght@400;500;700;800&family=Montserrat:wght@600;700;800&family=Playfair+Display:ital,wght@0,500;0,700;0,900;1,500&family=Reem+Kufi:wght@500;600;700&display=swap"
          rel="stylesheet"
        />
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  // Synchronously apply customized appearance theme before render
                  var rawApp = localStorage.getItem('afab_appearance_settings');
                  if (rawApp) {
                    var s = JSON.parse(rawApp);
                    var presets = {
                      purple: { primary: '#8b5cf6', hover: '#7c3aed', glow: 'rgba(139, 92, 246, 0.35)', sec: '#191832' },
                      blue: { primary: '#3b82f6', hover: '#2563eb', glow: 'rgba(59, 130, 246, 0.35)', sec: '#172554' },
                      emerald: { primary: '#10b981', hover: '#059669', glow: 'rgba(16, 185, 129, 0.35)', sec: '#064e3b' },
                      amber: { primary: '#f59e0b', hover: '#d97706', glow: 'rgba(245, 158, 11, 0.35)', sec: '#451a03' },
                      rose: { primary: '#f43f5e', hover: '#e11d48', glow: 'rgba(244, 63, 94, 0.35)', sec: '#4c0519' },
                      cyan: { primary: '#06b6d4', hover: '#0891b2', glow: 'rgba(6, 182, 212, 0.35)', sec: '#083344' },
                      magenta: { primary: '#d946ef', hover: '#c026d3', glow: 'rgba(217, 70, 239, 0.35)', sec: '#4a044e' },
                      slate: { primary: '#64748b', hover: '#475569', glow: 'rgba(100, 116, 139, 0.35)', sec: '#1e293b' }
                    };
                    var fontFamilies = {
                      inter: { body: "var(--font-sans), 'Inter', sans-serif", heading: "var(--font-heading), 'Poppins', sans-serif" },
                      serif: { body: "'Playfair Display', 'Amiri', Georgia, serif", heading: "'Playfair Display', 'Amiri', Georgia, serif" },
                      mono: { body: "'JetBrains Mono', 'Courier New', monospace", heading: "'JetBrains Mono', 'Courier New', monospace" },
                      geometric: { body: "'Cairo', 'Montserrat', sans-serif", heading: "'Cairo', 'Montserrat', sans-serif" },
                      kufi: { body: "'Reem Kufi', 'Cinzel', serif", heading: "'Cinzel', 'Reem Kufi', serif" },
                      system: { body: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif", heading: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" }
                    };
                    var fontSizes = {
                      sm: '87.5%',
                      md: '100%',
                      lg: '112.5%',
                      xl: '125%'
                    };
                    var p = presets[s.accentPreset] || presets.purple;
                    var pr = (s.accentPreset === 'custom' && s.customPrimaryColor) ? s.customPrimaryColor : p.primary;
                    var ph = p.hover || pr;
                    var rad = s.radius === 'sm' ? '0.5rem' : s.radius === 'lg' ? '1rem' : '0.75rem';
                    var f = fontFamilies[s.fontFamily] || fontFamilies.inter;
                    var fsz = fontSizes[s.fontSize] || '100%';
                    var css = ':root{--font-family-body:' + f.body + ';--font-family-heading:' + f.heading + ';--primary:' + pr + ';--primary-hover:' + ph + ';--ring:' + pr + ';--sidebar-primary:' + pr + ';--radius:' + rad + ';--glow-color:' + p.glow + ';}' +
                              '.dark{--primary:' + pr + ';--primary-hover:' + ph + ';--background:#060813;--card:#0c101c;--popover:#0c101c;--surface-inset:#080c18;--border:#171f2c;--secondary:' + p.sec + ';--ring:' + pr + ';--sidebar-primary:' + pr + ';--radius:' + rad + ';--glow-color:' + p.glow + ';}' +
                              'body, p, span, a, button, input, select, textarea, label, td, th {font-family:' + f.body + '!important;}' +
                              'h1,h2,h3,h4,h5,h6,.afab-page-title,.afab-card-title,.text-headline-lg,.text-headline-md,.text-display-lg{font-family:' + f.heading + '!important;}';
                    var st = document.createElement('style');
                    st.id = 'afab-appearance-theme';
                    st.textContent = css;
                    document.head.appendChild(st);
                    if (s.density) document.documentElement.setAttribute('data-density', s.density);
                    if (s.enableGlow !== undefined) document.documentElement.setAttribute('data-glow', s.enableGlow ? 'true' : 'false');
                    document.documentElement.style.fontSize = fsz;
                    document.documentElement.setAttribute('data-font', s.fontFamily || 'inter');
                    document.documentElement.setAttribute('data-font-size', s.fontSize || 'md');
                  }
                } catch(e) {}

                try {
                  // Suppress console hydration noise caused by third-party browser translation extensions
                  var origError = console.error;
                  console.error = function() {
                    var args = Array.prototype.slice.call(arguments);
                    var str = args.join(' ');
                    if (str.indexOf('translate-tooltip') !== -1 || (str.indexOf('Hydration') !== -1 && (str.indexOf('translate') !== -1 || str.indexOf('extension') !== -1))) {
                      return;
                    }
                    origError.apply(console, args);
                  };

                  // Hide extension tooltips via CSS without mutating DOM during React hydration
                  var extStyle = document.createElement('style');
                  extStyle.textContent = '.translate-tooltip-mtz, [class*="translate-tooltip"] { display: none !important; }';
                  document.head.appendChild(extStyle);

                  // Only safely clean up DOM nodes after React hydration has fully completed
                  window.addEventListener('load', function() {
                    setTimeout(function() {
                      var els = document.querySelectorAll('.translate-tooltip-mtz');
                      for (var i = 0; i < els.length; i++) els[i].remove();
                    }, 1000);
                  });
                } catch (e) {}
              })();
            `,
          }}
        />
      </head>
      <body className="min-h-screen bg-background font-sans antialiased" suppressHydrationWarning>
        <NextIntlClientProvider messages={messages}>
          <ThemeProvider
            attribute="class"
            defaultTheme="system"
            enableSystem
            disableTransitionOnChange
          >
            <TooltipProvider>
              <ChunkErrorRecovery />
              {children}
              <ScrollToTop />
              <Toaster />
            </TooltipProvider>
          </ThemeProvider>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
