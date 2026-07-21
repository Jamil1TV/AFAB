"use client";

import { useTranslations, useLocale } from "next-intl";
import { useRouter, usePathname, Link } from "@/i18n/routing";
import Image from "next/image";
import { Play, Globe } from "lucide-react";
import { ThemeToggle } from "@/components/theme-toggle";
import { DashboardMockup } from "@/components/home/dashboard-mockup";

export function HeroSection() {
  const t = useTranslations("Home.hero");
  const tLang = useTranslations("Common.language");
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();

  const toggleLanguage = () => {
    const nextLocale = locale === "en" ? "ar" : "en";
    router.replace(pathname, { locale: nextLocale });
  };

  return (
    <div className="relative flex h-full w-full flex-col overflow-hidden bg-background">
      {/* ── Background Ambient Glows ── */}
      {/* Light mode */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden dark:hidden">
        <div className="absolute -top-20 left-1/3 h-[500px] w-[500px] rounded-full bg-[#8b5cf6]/[0.03] blur-[120px]" />
      </div>
      {/* Dark mode */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden hidden dark:block">
        <div className="absolute -top-40 left-1/4 h-[600px] w-[600px] rounded-full bg-[#7c3aed]/[0.08] blur-[150px]" />
        <div className="absolute top-32 -left-20 h-[400px] w-[400px] rounded-full bg-[#6d28d9]/[0.06] blur-[120px]" />
        <div className="absolute bottom-0 right-0 h-[500px] w-[500px] rounded-full bg-blue-600/[0.03] blur-[150px]" />
      </div>

      {/* ═══════════════════════════════════════════════════
         TOP BAR — Logo + Controls
         ═══════════════════════════════════════════════════ */}
      <div className="relative z-20 flex items-center justify-between px-8 pt-6 pb-2 xl:px-10">
        <Link href="/" className="inline-flex items-center gap-3 group">
          <div className="relative h-10 w-10 flex-shrink-0 overflow-hidden rounded-[10px] bg-white shadow-sm transition-transform duration-200 group-hover:scale-105">
            <Image
              src="/assets/logo.png"
              alt="AFAB Logo"
              fill
              sizes="40px"
              className="object-cover scale-[1.15]"
              priority
            />
          </div>
          <span className="text-[22px] font-bold tracking-tight text-gray-900 dark:text-white">
            AFAB
          </span>
        </Link>

        <div className="flex items-center gap-2">
          <ThemeToggle />
          <button
            onClick={toggleLanguage}
            className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-white/[0.06] px-4 py-2 text-sm font-medium text-gray-600 dark:text-gray-300 transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.1]"
          >
            <Globe className="h-4 w-4" />
            {tLang("switchTo")}
          </button>
        </div>
      </div>

      {/* ═══════════════════════════════════════════════════
         MAIN CONTENT — Mirrors landing page hero
         ═══════════════════════════════════════════════════ */}
      <div className="relative z-10 flex flex-1 items-center px-8 py-6 xl:px-10">
        <div className="flex w-full items-center gap-8 xl:gap-10">

          {/* ── LEFT: Text content ── */}
          <div className="flex flex-col shrink-0 w-[46%] xl:w-[42%]">
            {/* Badge */}
            <div className="mb-8 inline-flex self-start items-center gap-2 rounded-full border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-white/[0.04] px-4 py-2 text-[13px] font-medium text-gray-600 dark:text-gray-300 shadow-sm dark:shadow-none">
              <span className="text-gray-400 dark:text-gray-500">•</span>
              <span>{t("badge")}</span>
              <svg width="14" height="14" viewBox="0 0 16 16" fill="none" className="text-[#8b5cf6]">
                <path d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z" fill="currentColor" />
              </svg>
            </div>

            {/* Title */}
            <h2 className="text-[2.25rem] xl:text-[2.75rem] font-extrabold tracking-tight text-gray-900 dark:text-white leading-[1.08]">
              {t("title_line1")}
              <br />
              <span className="text-[#7c3aed] dark:text-[#8b5cf6] italic">
                {t("title_line2")}
              </span>
            </h2>

            {/* Subtitle */}
            <p className="mt-5 max-w-[380px] text-[15px] leading-[1.65] text-gray-500 dark:text-gray-400">
              {t("subtitle")}
            </p>

            {/* Trust Badges */}
            <div className="mt-10 flex items-center gap-4">
              <div className="flex -space-x-3 rtl:space-x-reverse">
                {[
                  "https://i.pravatar.cc/80?u=afab1",
                  "https://i.pravatar.cc/80?u=afab2",
                  "https://i.pravatar.cc/80?u=afab3",
                  "https://i.pravatar.cc/80?u=afab4",
                ].map((src, i) => (
                  <img
                    key={i}
                    src={src}
                    alt=""
                    className="h-9 w-9 rounded-full border-[2.5px] border-background object-cover"
                  />
                ))}
              </div>
              <div className="text-[12px] text-gray-500 dark:text-gray-400 leading-tight font-medium">
                <span className="font-semibold text-gray-700 dark:text-gray-300">
                  Trusted by 12,000+
                </span>
                <br />
                business owners
              </div>
            </div>
          </div>

          {/* ── RIGHT: Dashboard Mockup ── */}
          <div className="relative flex-1 min-w-0">
            {/* Purple ambient glow behind dashboard (dark mode) */}
            <div className="absolute inset-0 hidden dark:flex items-center justify-center pointer-events-none">
              <div className="h-[80%] w-[80%] rounded-full bg-[#7c3aed]/[0.12] blur-[80px]" />
            </div>

            <div className="relative mx-auto w-full max-w-[560px] xl:max-w-[620px]">
              {/* Main dashboard with isometric tilt */}
              <div
                className="relative z-10"
                style={{
                  transform: "perspective(1500px) rotateY(-8deg) rotateX(3deg) rotateZ(-1deg)",
                  transformOrigin: "center center",
                }}
              >
                <div className="rounded-[20px] shadow-[0_20px_50px_-10px_rgba(0,0,0,0.12)] dark:shadow-[0_0_60px_-5px_rgba(124,58,237,0.3),0_0_120px_-15px_rgba(124,58,237,0.12),0_25px_50px_-12px_rgba(0,0,0,0.5)]">
                  <DashboardMockup />
                </div>
              </div>

              {/* ── Floating Element 1: Bar Chart (Top-Left) ── */}
              <div
                className="absolute z-20 flex -left-6 xl:-left-8 top-[10%] h-[52px] w-[52px] items-center justify-center rounded-[14px] bg-white dark:bg-[#12162b] border border-gray-100 dark:border-[#2a2050]/50 shadow-[0_8px_25px_rgba(0,0,0,0.08)] dark:shadow-[0_0_25px_rgba(124,58,237,0.18),0_8px_25px_rgba(0,0,0,0.3)]"
                style={{ transform: "perspective(800px) rotateY(-8deg) translateZ(40px)" }}
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" className="text-[#7c3aed] dark:text-[#a78bfa]">
                  <rect x="4" y="13" width="3.5" height="8" rx="1.2" fill="currentColor" opacity="0.35" />
                  <rect x="10.25" y="8" width="3.5" height="13" rx="1.2" fill="currentColor" opacity="0.6" />
                  <rect x="16.5" y="3" width="3.5" height="18" rx="1.2" fill="currentColor" />
                </svg>
              </div>

              {/* ── Floating Element 2: Settings/Gear (Middle-Left) ── */}
              <div
                className="absolute z-20 flex left-4 xl:left-2 top-[44%] -translate-y-1/2 h-[62px] w-[62px] items-center justify-center rounded-[16px] bg-white dark:bg-[#12162b] border border-gray-100 dark:border-[#2a2050]/50 shadow-[0_12px_35px_rgba(0,0,0,0.1)] dark:shadow-[0_0_30px_rgba(124,58,237,0.2),0_12px_35px_rgba(0,0,0,0.4)]"
                style={{ transform: "perspective(800px) rotateY(-12deg) translateZ(80px)" }}
              >
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" className="text-[#7c3aed] dark:text-[#a78bfa]">
                  <circle cx="12" cy="12" r="3" />
                  <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
                </svg>
              </div>

              {/* ── Floating Element 3: 4-Point Star (Bottom-Left) ── */}
              <div
                className="absolute z-20 flex -left-1 xl:-left-3 bottom-[14%] h-[48px] w-[48px] items-center justify-center rounded-[12px] bg-white dark:bg-[#12162b] border border-gray-100 dark:border-[#2a2050]/50 shadow-[0_8px_25px_rgba(0,0,0,0.08)] dark:shadow-[0_0_25px_rgba(124,58,237,0.18),0_8px_25px_rgba(0,0,0,0.3)]"
                style={{ transform: "perspective(800px) rotateY(-5deg) translateZ(60px)" }}
              >
                <svg width="18" height="18" viewBox="0 0 16 16" fill="none" className="text-[#7c3aed] dark:text-[#a78bfa]">
                  <path d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z" fill="currentColor" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
