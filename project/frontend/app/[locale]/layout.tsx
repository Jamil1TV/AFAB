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
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  var clean = function() {
                    var els = document.querySelectorAll('.translate-tooltip-mtz, [class*="translate-tooltip"]');
                    for (var i = 0; i < els.length; i++) els[i].remove();
                  };
                  clean();
                  var obs = new MutationObserver(function(mutations) {
                    for (var i = 0; i < mutations.length; i++) {
                      var m = mutations[i];
                      for (var j = 0; j < m.addedNodes.length; j++) {
                        var node = m.addedNodes[j];
                        if (node.nodeType === 1 && (node.className && typeof node.className === 'string' && node.className.indexOf('translate-tooltip') !== -1)) {
                          node.remove();
                        }
                      }
                    }
                  });
                  obs.observe(document.documentElement, { childList: true, subtree: true });
                  window.addEventListener('DOMContentLoaded', function() {
                    setTimeout(function() { obs.disconnect(); }, 1500);
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
