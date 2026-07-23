'use client';

import Link from "next/link";
import { Home, LayoutGrid, ArrowRight, Globe } from "lucide-react";
import { Inter, Poppins, Geist_Mono } from "next/font/google";
import { ThemeProvider } from "@/components/theme-provider";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import { AnimatedStars } from "@/components/animated-stars";
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
    if (typeof window !== 'undefined' && window.location.pathname.startsWith('/ar')) {
      setLocale('ar');
    }
  }, []);

  const isArabic = locale === 'ar';

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
    <html lang={locale} dir={isArabic ? 'rtl' : 'ltr'} className={`${inter.variable} ${poppins.variable} ${geistMono.variable}`}>
      <body className="min-h-screen bg-background font-sans antialiased">
        <ThemeProvider
            attribute="class"
            defaultTheme="system"
            enableSystem
            disableTransitionOnChange
        >
          <div className="flex h-screen w-full flex-col items-center justify-center bg-[#F8F9FB] dark:bg-[#0a0e1a] font-sans overflow-hidden relative">
            
            {/* ── Header Controls ── */}
            <div className={`absolute top-6 z-50 flex items-center gap-3 ${isArabic ? 'left-6' : 'right-6'}`}>
              <Button variant="outline" size="sm" onClick={toggleLanguage} className="gap-2 rounded-xl border-border bg-card/80 backdrop-blur-md">
                <Globe className="h-4 w-4" />
                {isArabic ? 'English' : 'العربية'}
              </Button>
              <ThemeToggle />
            </div>

            {/* ── Background Floating Numbers ── */}
            <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
              <span className="absolute top-[20%] left-[15%] text-[80px] font-black text-[#e9d5ff] dark:text-[#1e1b4b] animate-float-slow rotate-12 opacity-50">4</span>
              <span className="absolute top-[60%] left-[10%] text-[50px] font-black text-[#e9d5ff] dark:text-[#1e1b4b] animate-float rotate-[-15deg] opacity-50" style={{ animationDelay: '1s' }}>0</span>
              <span className="absolute top-[30%] right-[15%] text-[100px] font-black text-[#e9d5ff] dark:text-[#1e1b4b] animate-float-delayed rotate-6 opacity-50" style={{ animationDelay: '2s' }}>4</span>
              <span className="absolute top-[70%] right-[20%] text-[60px] font-black text-[#e9d5ff] dark:text-[#1e1b4b] animate-float rotate-[-12deg] opacity-50" style={{ animationDelay: '0.5s' }}>0</span>
              {/* ── Night Sky Stars Background ── */}
              <AnimatedStars />
            </div>

            {/* ── UFO Graphic Area ── */}
            <div className="relative w-full max-w-2xl h-[340px] flex flex-col items-center justify-start pointer-events-none mt-[-50px]">
              
              {/* Clouds & Elements */}
              <div className="absolute inset-0 z-0">
                {/* Top Left Small Cloud */}
                <div className="absolute top-[40px] left-[25%] opacity-70 animate-float-slow">
                  <div className="relative w-[80px] h-[30px]">
                    <div className="absolute bottom-0 w-full h-full bg-gradient-to-t from-[#e9d5ff]/80 to-white dark:from-white/10 dark:to-white/5 rounded-full" />
                    <div className="absolute bottom-[10px] left-[10px] w-[30px] h-[30px] bg-white dark:bg-white/10 rounded-full" />
                    <div className="absolute bottom-[5px] right-[15px] w-[40px] h-[40px] bg-white dark:bg-white/10 rounded-full" />
                  </div>
                </div>

                {/* Bottom Left Big Cloud */}
                <div className="absolute top-[160px] left-[15%] opacity-90 animate-float-delayed" style={{ transform: 'scale(1.2)' }}>
                  <div className="relative w-[120px] h-[40px]">
                    <div className="absolute bottom-0 w-full h-full bg-gradient-to-t from-[#e9d5ff]/80 to-white dark:from-white/10 dark:to-white/5 rounded-full" />
                    <div className="absolute bottom-[15px] left-[15px] w-[50px] h-[50px] bg-white dark:bg-white/10 rounded-full" />
                    <div className="absolute bottom-[10px] right-[20px] w-[60px] h-[60px] bg-white dark:bg-white/10 rounded-full" />
                  </div>
                </div>

                {/* Bottom Right Big Cloud */}
                <div className="absolute top-[180px] right-[15%] opacity-80 animate-float" style={{ transform: 'scale(1.5)' }}>
                  <div className="relative w-[100px] h-[35px]">
                    <div className="absolute bottom-0 w-full h-full bg-gradient-to-t from-[#e9d5ff]/80 to-white dark:from-white/10 dark:to-white/5 rounded-full" />
                    <div className="absolute bottom-[10px] left-[10px] w-[40px] h-[40px] bg-white dark:bg-white/10 rounded-full" />
                    <div className="absolute bottom-[5px] right-[15px] w-[50px] h-[50px] bg-white dark:bg-white/10 rounded-full" />
                  </div>
                </div>

                {/* Planet */}
                <div className="absolute top-[60px] right-[28%] w-10 h-10 rounded-full bg-gradient-to-tr from-[#e9d5ff] to-[#f3e8ff] dark:from-[#3b0764] dark:to-[#6b21a8] animate-float-slow rotate-12 opacity-80 shadow-inner">
                  <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-14 h-2.5 rounded-[50%] border-2 border-[#d8b4fe] dark:border-[#9333ea] shadow-sm" />
                </div>

                {/* Stars */}
                <div className="absolute top-[20px] left-[35%] text-[#d8b4fe] text-[10px] animate-pulse">✦</div>
                <div className="absolute top-[70px] left-[20%] text-[#d8b4fe] text-[14px] animate-pulse" style={{ animationDelay: '0.5s' }}>✦</div>
                <div className="absolute top-[30px] right-[35%] text-[#d8b4fe] text-[12px] animate-pulse" style={{ animationDelay: '1s' }}>✦</div>
                <div className="absolute top-[120px] right-[20%] text-[#d8b4fe] text-[10px] animate-pulse" style={{ animationDelay: '1.5s' }}>✦</div>
              </div>

              {/* UFO & Beam Container */}
              <div className="relative z-10 flex flex-col items-center mt-4 w-full">
                
                {/* Bobbing UFO and Beam */}
                <div className="relative flex flex-col items-center animate-float w-full" style={{ animationDuration: '4s' }}>
                  
                  {/* UFO Body */}
                  <div className="relative z-20 flex flex-col items-center">
                    {/* Glass Dome */}
                    <div className="w-[80px] h-[45px] bg-gradient-to-br from-[#d8b4fe] to-[#8b5cf6] rounded-t-full border-b border-[#d8b4fe]/50 relative z-20 shadow-[inset_0_4px_10px_rgba(255,255,255,0.6)]">
                      {/* Dome Highlight */}
                      <div className="absolute top-2 left-3 w-6 h-3 bg-white/50 rounded-full rotate-[-20deg]" />
                    </div>
                    
                    {/* Saucer Disc */}
                    <div className="relative z-10 w-[200px] h-[35px] -mt-[10px] bg-gradient-to-b from-[#ffffff] to-[#e2e8f0] dark:from-gray-300 dark:to-gray-500 rounded-full border-[1.5px] border-white dark:border-gray-200 shadow-[0_10px_20px_rgba(139,92,246,0.2)] flex items-center justify-center gap-6">
                       {/* Saucer Base Detail */}
                       <div className="absolute inset-0 rounded-full shadow-[inset_0_-4px_10px_rgba(0,0,0,0.1)]" />
                       {/* Glowing Lights */}
                       <div className="w-2.5 h-2.5 rounded-full bg-[#d8b4fe] shadow-[0_0_8px_#a855f7] animate-pulse z-10" />
                       <div className="w-3.5 h-3.5 rounded-full bg-[#c084fc] shadow-[0_0_10px_#9333ea] animate-pulse z-10" style={{ animationDelay: '0.3s' }}/>
                       <div className="w-2.5 h-2.5 rounded-full bg-[#d8b4fe] shadow-[0_0_8px_#a855f7] animate-pulse z-10" style={{ animationDelay: '0.6s' }}/>
                    </div>
                    
                    {/* UFO Bottom Core */}
                    <div className="relative z-0 w-[80px] h-[20px] -mt-[10px] bg-gradient-to-b from-[#e9d5ff] to-[#c084fc] dark:from-purple-800 dark:to-purple-900 rounded-b-full border border-purple-200 dark:border-purple-700 shadow-[0_5px_15px_rgba(139,92,246,0.3)]" />
                  </div>

                  {/* Tractor Beam */}
                  <div 
                    className="absolute top-[65px] w-[260px] h-[180px] bg-gradient-to-b from-[#c084fc]/30 via-[#e9d5ff]/20 to-transparent dark:from-[#8b5cf6]/30 dark:via-[#6b21a8]/20 dark:to-transparent z-0 opacity-80 animate-pulse"
                    style={{ clipPath: 'polygon(35% 0, 65% 0, 100% 100%, 0 100%)', animationDuration: '3s' }}
                  />
                </div>

                {/* Floating 404 inside beam - separate animation so it floats independently! */}
                <div className="absolute top-[130px] z-10 animate-float-delayed" style={{ animationDuration: '5s' }}>
                  <div className="px-8 py-3 border-[2.5px] border-dashed border-[#c084fc] dark:border-[#8b5cf6] rounded-2xl bg-white/60 dark:bg-[#131825]/60 backdrop-blur-md shadow-[0_0_20px_rgba(139,92,246,0.2)] flex items-center justify-center">
                    <span className="text-[40px] font-black text-[#8b5cf6] dark:text-[#d8b4fe] tracking-widest leading-none drop-shadow-sm animate-pulse" style={{ animationDuration: '2s' }}>404</span>
                  </div>
                </div>

              </div>
            </div>

            {/* ── Content Area ── */}
            <div className="text-center z-10 relative mt-[20px]">
              <h1 className="text-display-lg text-[#111827] dark:text-white">
                404
              </h1>
              <h2 className="mt-2 text-headline-md text-[#1f2937] dark:text-gray-100">
                {isArabic ? "الصفحة غير موجودة" : "Page Not Found"}
              </h2>
              <p className="mt-3 text-body-md text-[#6b7280] dark:text-gray-400 max-w-md mx-auto leading-relaxed">
                {isArabic ? (
                  <>عذراً، الصفحة التي تبحث عنها غير موجودة<br/>أو تم نقلها.</>
                ) : (
                  <>Sorry, the page you're looking for doesn't exist<br/>or has been moved.</>
                )}
              </p>

              <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-3">
                <Link
                  href={`/${locale}`}
                  className="flex items-center gap-2 rounded-xl bg-gradient-purple px-6 py-3.5 text-label-md text-white transition-all hover:opacity-90 active:scale-[0.98] shadow-lg shadow-purple-900/20 w-full sm:w-auto justify-center font-semibold"
                >
                  <Home className="w-4 h-4" strokeWidth={2.5} />
                  {isArabic ? "العودة للرئيسية" : "Go Back Home"}
                </Link>
                <Link
                  href={`/${locale}/dashboard`}
                  className="flex items-center gap-2 rounded-xl border border-border bg-card px-6 py-3.5 text-label-md text-foreground transition-all hover:bg-muted active:scale-[0.98] shadow-sm w-full sm:w-auto justify-center font-semibold"
                >
                  <LayoutGrid className="w-4 h-4" strokeWidth={2.5} />
                  {isArabic ? "الذهاب للوحة القيادة" : "Go to Dashboard"}
                </Link>
              </div>
              
              <div className="mt-12">
                <Link href={`/${locale}/support`} className="text-label-md text-muted-foreground hover:text-foreground flex items-center justify-center gap-1.5 transition-colors">
                  {isArabic ? "تحتاج مساعدة؟" : "Need help?"} <span className="text-primary font-semibold">{isArabic ? "اتصل بالدعم" : "Contact Support"}</span> 
                  <ArrowRight className={`w-4 h-4 text-primary transition-transform ${isArabic ? 'rotate-180' : ''}`} />
                </Link>
              </div>
            </div>

          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}
