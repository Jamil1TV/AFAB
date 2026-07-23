import type { Metadata } from "next";
import { ReactNode } from "react";
import Image from "next/image";
import { useTranslations, useLocale } from "next-intl";
import { AuthHeroGraphic } from "@/components/auth/auth-hero-graphic";
import { ThemeToggle } from "@/components/theme-toggle";
import { LanguageSwitcher } from "@/components/language-switcher";
import { AnimatedStars } from "@/components/animated-stars";

export const metadata: Metadata = {
  title: "Login — AFAB",
  description: "Sign in to your AFAB account. AI-powered financial management for your business.",
};

export default function AuthLayout({
  children,
}: {
  children: ReactNode;
}) {
  const t = useTranslations("Auth");
  const locale = useLocale();
  const isArabic = locale === 'ar';

  return (
    <div className="flex h-[100dvh] w-full font-sans bg-[#F9FAFB] dark:bg-[#0D111C] relative overflow-hidden">
      
      {/* ── Animated Stars Background ── */}
      <AnimatedStars />

      {/* ── Top Right Controls (Theme & Language) ── */}
      <div className={`absolute top-4 sm:top-6 z-50 flex items-center gap-2 sm:gap-3 ${isArabic ? 'left-4 sm:left-6' : 'right-4 sm:right-6'}`}>
        <LanguageSwitcher />
        <ThemeToggle />
      </div>

      {/* ── Main Container: Matches the seamless background of the mockups ── */}
      <div className="mx-auto flex h-full w-full max-w-[1440px] flex-col lg:flex-row">
        
        {/* ── Left Panel: Branding & Hero ────────────────────── */}
        <div className="relative hidden h-full w-full flex-col p-8 lg:flex lg:w-[45%] xl:w-[50%]">
          
          {/* Top Logo */}
          <div className="flex items-center gap-4 relative z-20 shrink-0">
            <div className="flex h-14 w-14 items-center justify-center rounded-[18px] bg-white shadow-sm dark:bg-[#161B2B] overflow-hidden">
              <Image src="/assets/afablogo.png" alt="AFAB Logo" width={44} height={44} className="object-contain dark:hidden" />
              <Image src="/assets/afablogo_dark.png" alt="AFAB Logo Dark" width={44} height={44} className="object-contain hidden dark:block" />
            </div>
            <div>
              <h2 className="text-[28px] font-extrabold text-gray-900 tracking-tight dark:text-white leading-none">AFAB</h2>
            </div>
          </div>

          {/* Text Content */}
          <div className="relative z-20 mt-6 flex flex-col pl-2 shrink-0">
            {/* Reduced text size slightly so it fits perfectly on smaller screens without forced breaks */}
            <h1 className="text-[2.5rem] font-bold leading-[1.15] tracking-[-0.02em] text-gray-900 dark:text-white relative z-20 xl:text-[3rem] flex flex-col gap-0.5">
              <span>{t("heroTitlePart1")}</span>
              <span className="text-[#6c2bd9] dark:text-[#8b5cf6]">{t("heroTitlePart2")}</span>
            </h1>
            <p className="mt-3 text-[14px] leading-relaxed text-gray-600 dark:text-gray-400 relative z-20 max-w-[480px]">
              {t("heroSubtitle")}
            </p>
          </div>

          {/* Unified CSS 3D Graphic */}
          <div className="relative flex-1 min-h-0 w-full flex items-center justify-center pointer-events-none z-10">
            <div className="w-full h-full flex items-center justify-center">
              <AuthHeroGraphic />
            </div>
          </div>

          {/* Bottom Testimonial */}
          <div className="relative z-20 pl-2 shrink-0">
            <span className="block font-serif text-[50px] leading-none text-[#8b5cf6] opacity-60 mb-[-15px]">&ldquo;</span>
            <p className="text-[13px] italic leading-relaxed text-gray-700 dark:text-gray-300 max-w-[260px] font-medium">
              {t("testimonialPart1")}<br/>{t("testimonialPart2")}
            </p>
          </div>
        </div>

        {/* ── Right Panel: Form Area ────────────────────── */}
        <div className="relative z-20 flex h-full w-full flex-col items-center overflow-y-auto px-4 py-24 sm:px-8 sm:py-12 lg:w-[55%] xl:w-[50%]">
          
          <div className="my-auto w-full flex flex-col items-center justify-center gap-6">
            {/* Mobile Logo (Hidden on Desktop) */}
            <div className="flex lg:hidden items-center gap-4 shrink-0">
              <div className="flex h-16 w-16 items-center justify-center rounded-[20px] bg-white shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] dark:bg-[#161B2B] dark:border dark:border-[#2A3042]/50 overflow-hidden">
                <Image src="/assets/afablogo.png" alt="AFAB Logo" width={52} height={52} className="object-contain dark:hidden" />
                <Image src="/assets/afablogo_dark.png" alt="AFAB Logo Dark" width={52} height={52} className="object-contain hidden dark:block" />
              </div>
              <h2 className="text-[32px] font-extrabold text-gray-900 tracking-tight dark:text-white leading-none">AFAB</h2>
            </div>

            {children}
          </div>

        </div>
      </div>
    </div>
  );
}
