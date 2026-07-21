'use client';

import Link from 'next/link';
import { LayoutDashboard, HeadphonesIcon, Globe } from 'lucide-react';
import { Inter, Poppins, Geist_Mono } from "next/font/google";
import { ThemeProvider } from "@/components/theme-provider";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import { useState, useEffect } from "react";
import "./globals.css";

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

export default function NotFoundPage() {
  const [locale, setLocale] = useState('en');

  useEffect(() => {
    if (window.location.pathname.startsWith('/ar')) {
      setLocale('ar');
    }
  }, []);

  const toggleLanguage = () => {
    const nextLocale = locale === 'en' ? 'ar' : 'en';
    const path = window.location.pathname;
    let newPath = path;
    if (path.startsWith(`/${locale}`)) {
      newPath = path.replace(`/${locale}`, `/${nextLocale}`);
    } else {
      newPath = `/${nextLocale}${path}`;
    }
    window.location.href = newPath;
  };

  return (
    <html lang={locale} dir={locale === 'ar' ? 'rtl' : 'ltr'} className={`${inter.variable} ${poppins.variable} ${geistMono.variable}`}>
      <body className="min-h-screen bg-background font-sans antialiased">
        <ThemeProvider
            attribute="class"
            defaultTheme="system"
            enableSystem
            disableTransitionOnChange
        >
          <div className="flex flex-col min-h-screen items-center justify-center p-6 relative overflow-hidden">
              {/* Header Actions */}
              <div className="absolute top-6 right-6 flex items-center gap-3 z-50">
                  <ThemeToggle />
                  <Button variant="outline" size="sm" onClick={toggleLanguage} className="gap-2">
                    <Globe className="h-4 w-4" />
                    {locale === 'en' ? 'العربية' : 'English'}
                  </Button>
              </div>

              {/* Ambient Background Effects */}
              <div className="absolute inset-0 pointer-events-none overflow-hidden z-0 flex items-center justify-center">
                  <div className="absolute top-0 left-0 w-[40vw] h-[40vw] bg-primary/10 blur-[120px] rounded-full mix-blend-screen translate-x-[-20%] translate-y-[-20%]"></div>
                  <div className="absolute bottom-0 right-0 w-[40vw] h-[40vw] bg-primary/20 blur-[120px] rounded-full mix-blend-screen translate-x-[20%] translate-y-[20%]"></div>
              </div>

              <main className="relative z-10 w-full max-w-4xl mx-auto flex flex-col items-center">
                  
                  {/* Typography & Message */}
                  <div className="text-center space-y-4 max-w-2xl px-4">
                      <h1 className="font-heading text-[120px] leading-none font-extrabold tracking-tighter bg-clip-text text-transparent bg-gradient-to-br from-primary to-primary/50 opacity-90 mb-2">
                          404
                      </h1>
                      
                      <h2 className="font-heading text-3xl md:text-4xl text-foreground font-bold">
                          Page Not Found
                      </h2>
                      
                      <p className="font-sans text-muted-foreground text-lg leading-relaxed">
                          The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.
                      </p>
                  </div>

                  {/* Action Buttons */}
                  <div className="mt-12 flex flex-col sm:flex-row items-center gap-4 w-full justify-center">
                      {/* Primary Action */}
                      <Link href="/dashboard" className="group relative px-8 py-4 bg-primary text-primary-foreground font-semibold rounded-xl overflow-hidden transition-all duration-300 hover:shadow-[0_0_30px_rgba(124,58,237,0.5)] active:scale-95 flex items-center gap-2">
                          <LayoutDashboard className="h-5 w-5" />
                          Back to Dashboard
                          <div className="absolute inset-0 bg-white/10 opacity-0 group-hover:opacity-100 transition-opacity"></div>
                      </Link>

                      {/* Secondary Action */}
                      <Link href="/" className="px-8 py-4 bg-card border border-border text-foreground font-semibold rounded-xl transition-all duration-300 hover:bg-muted active:scale-95 flex items-center gap-2 shadow-sm">
                          <HeadphonesIcon className="h-5 w-5" />
                          Contact Support
                      </Link>
                  </div>

                  {/* Footer / Subtle Navigation */}
                  <footer className="mt-16 pt-8 border-t border-border/50 w-full text-center">
                      <div className="flex flex-wrap justify-center gap-x-8 gap-y-4 text-muted-foreground text-xs uppercase tracking-widest opacity-60 font-semibold">
                          <Link href="/" className="hover:text-primary transition-colors">Home</Link>
                          <Link href="/" className="hover:text-primary transition-colors">System Status</Link>
                          <Link href="/" className="hover:text-primary transition-colors">Security</Link>
                          <Link href="/" className="hover:text-primary transition-colors">Privacy Policy</Link>
                      </div>
                  </footer>
              </main>
          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}
