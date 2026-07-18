"use client";

import { useTranslations } from "next-intl";
import { useTheme } from "next-themes";
import Image from "next/image";
import { Play } from "lucide-react";
import { useEffect, useState } from "react";
import { DashboardMockup } from "./dashboard-mockup";

export function HeroSection() {
  const t = useTranslations("Home.hero");
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const isDark = mounted && resolvedTheme === "dark";

  return (
    <section className="relative overflow-hidden pt-28 pb-12 lg:pt-36 lg:pb-16">
      {/* ── Background Ambient Glows ── */}
      {/* Light mode: very subtle */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden dark:hidden">
        <div className="absolute -top-20 left-1/3 h-[500px] w-[500px] rounded-full bg-[#8b5cf6]/[0.03] blur-[120px]" />
      </div>
      {/* Dark mode: deep purple ambient */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden hidden dark:block">
        <div className="absolute -top-40 left-1/4 h-[600px] w-[600px] rounded-full bg-[#7c3aed]/[0.08] blur-[150px]" />
        <div className="absolute top-32 -left-20 h-[400px] w-[400px] rounded-full bg-[#6d28d9]/[0.06] blur-[120px]" />
        <div className="absolute bottom-0 right-0 h-[500px] w-[500px] rounded-full bg-blue-600/[0.03] blur-[150px]" />
      </div>

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col lg:flex-row lg:items-center lg:gap-12 xl:gap-16">

          {/* ═══════════════════════════════════════════ */}
          {/* LEFT COLUMN – Text Content                 */}
          {/* ═══════════════════════════════════════════ */}
          <div className="flex flex-col items-center text-center lg:items-start lg:text-start lg:w-[45%] xl:w-[42%] z-10 shrink-0">

            {/* Badge */}
            <div className="mb-8 inline-flex items-center gap-2 rounded-full border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-white/[0.04] px-4 py-2 text-[13px] font-medium text-gray-600 dark:text-gray-300 shadow-sm dark:shadow-none">
              <span className="text-gray-400 dark:text-gray-500">•</span>
              <span>{t("badge")}</span>
              <svg width="14" height="14" viewBox="0 0 16 16" fill="none" className="text-[#8b5cf6]">
                <path d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z" fill="currentColor" />
              </svg>
            </div>

            {/* Title */}
            <h1 className="text-[2.75rem] sm:text-[3.25rem] md:text-[3.5rem] lg:text-[3.75rem] font-extrabold tracking-tight text-gray-900 dark:text-white leading-[1.08] max-w-[600px]">
              {t("title_line1")}
              <br />
              <span className="text-[#7c3aed] dark:text-[#8b5cf6] italic">
                {t("title_line2")}
              </span>
            </h1>

            {/* Subtitle */}
            <p className="mt-6 max-w-[420px] text-[17px] leading-[1.6] text-gray-500 dark:text-gray-400">
              {t("subtitle")}
            </p>

            {/* CTA Buttons */}
            <div className="mt-10 flex flex-wrap items-center justify-center lg:justify-start gap-4">
              <button className="relative inline-flex items-center justify-center rounded-xl bg-[#7c3aed] dark:bg-[#8b5cf6] px-8 py-[14px] text-[15px] font-bold text-white transition-all duration-200 hover:bg-[#6d28d9] dark:hover:bg-[#7c3aed] shadow-[0_4px_14px_rgba(124,58,237,0.35)] dark:shadow-[0_0_25px_rgba(139,92,246,0.4)]">
                {t("getStartedFree")}
              </button>
              <button className="inline-flex items-center justify-center gap-2.5 rounded-xl border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-transparent px-8 py-[14px] text-[15px] font-bold text-gray-900 dark:text-white transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.04] shadow-sm dark:shadow-none">
                <span className="flex h-6 w-6 items-center justify-center rounded-full bg-gray-900 dark:bg-white">
                  <Play className="h-3 w-3 fill-white text-white dark:fill-gray-900 dark:text-gray-900 ml-[1px]" />
                </span>
                {t("watchDemo")}
              </button>
            </div>

            {/* Trust Badges */}
            <div className="mt-14 flex items-center justify-center lg:justify-start gap-4">
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
                    className="h-10 w-10 rounded-full border-[2.5px] border-white dark:border-[#0a0e1a] object-cover"
                  />
                ))}
              </div>
              <div className="text-[13px] text-gray-500 dark:text-gray-400 leading-tight font-medium">
                <span className="font-semibold text-gray-700 dark:text-gray-300">Trusted by 12,000+</span>
                <br />
                business owners
              </div>
            </div>
          </div>

          {/* ═══════════════════════════════════════════ */}
          {/* RIGHT COLUMN – Dashboard Preview           */}
          {/* ═══════════════════════════════════════════ */}
          <div className="relative flex-1 mt-16 lg:mt-0 min-w-0">

            {/* Purple ambient glow behind dashboard (dark mode) */}
            <div className="absolute inset-0 hidden dark:flex items-center justify-center pointer-events-none">
              <div className="h-[80%] w-[80%] rounded-full bg-[#7c3aed]/[0.12] blur-[80px]" />
            </div>

            {/* ── MOBILE: Show mobile app screenshot ── */}
            <div className="relative z-10 flex justify-center lg:hidden">
              <div className="relative mx-auto w-full max-w-[280px] sm:max-w-[320px]">
                <div className="rounded-[36px] overflow-hidden shadow-[0_20px_50px_-10px_rgba(0,0,0,0.15)] dark:shadow-[0_0_60px_-5px_rgba(124,58,237,0.3),0_25px_50px_-12px_rgba(0,0,0,0.5)] border border-gray-200/60 dark:border-[#1e1b4b]/40 bg-white dark:bg-[#0a0d16]">
                  <img
                    src={isDark ? "/images/mobile-dark.png" : "/images/mobile-light.png"}
                    alt="AFAB Mobile App"
                    className="w-full h-auto block"
                  />
                </div>
              </div>
            </div>

            {/* ── DESKTOP: Show full dashboard mockup ── */}
            <div className="relative hidden lg:block mx-auto lg:ml-auto lg:mr-0 w-full max-w-[720px] xl:max-w-[780px]">

              {/* Main dashboard with isometric tilt */}
              <div
                className="relative z-10"
                style={{
                  transform: "perspective(1500px) rotateY(-8deg) rotateX(3deg) rotateZ(-1deg)",
                  transformOrigin: "center center",
                }}
              >
                {/* Purple glow shadow wrapper */}
                <div className="rounded-[20px] shadow-[0_20px_50px_-10px_rgba(0,0,0,0.12)] dark:shadow-[0_0_60px_-5px_rgba(124,58,237,0.3),0_0_120px_-15px_rgba(124,58,237,0.12),0_25px_50px_-12px_rgba(0,0,0,0.5)]">
                  <DashboardMockup />
                </div>
              </div>

              {/* ── Floating Element 1: Bar Chart (Top-Left) ── */}
              <div
                className="absolute z-20 flex -left-8 xl:-left-10 top-[10%] h-[60px] w-[60px] items-center justify-center rounded-[16px] bg-white dark:bg-[#12162b] border border-gray-100 dark:border-[#2a2050]/50 shadow-[0_8px_25px_rgba(0,0,0,0.08)] dark:shadow-[0_0_25px_rgba(124,58,237,0.18),0_8px_25px_rgba(0,0,0,0.3)]"
                style={{ transform: "perspective(800px) rotateY(-8deg) translateZ(40px)" }}
              >
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" className="text-[#7c3aed] dark:text-[#a78bfa]">
                  <rect x="4" y="13" width="3.5" height="8" rx="1.2" fill="currentColor" opacity="0.35" />
                  <rect x="10.25" y="8" width="3.5" height="13" rx="1.2" fill="currentColor" opacity="0.6" />
                  <rect x="16.5" y="3" width="3.5" height="18" rx="1.2" fill="currentColor" />
                </svg>
              </div>

              {/* ── Floating Element 2: Settings/Gear (Middle-Left) ── */}
              <div
                className="absolute z-20 flex left-6 xl:left-4 top-[44%] -translate-y-1/2 h-[72px] w-[72px] items-center justify-center rounded-[18px] bg-white dark:bg-[#12162b] border border-gray-100 dark:border-[#2a2050]/50 shadow-[0_12px_35px_rgba(0,0,0,0.1)] dark:shadow-[0_0_30px_rgba(124,58,237,0.2),0_12px_35px_rgba(0,0,0,0.4)]"
                style={{ transform: "perspective(800px) rotateY(-12deg) translateZ(80px)" }}
              >
                <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" className="text-[#7c3aed] dark:text-[#a78bfa]">
                  <circle cx="12" cy="12" r="3" />
                  <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
                </svg>
              </div>

              {/* ── Floating Element 3: 4-Point Star (Bottom-Left) ── */}
              <div
                className="absolute z-20 flex -left-2 xl:-left-4 bottom-[14%] h-[56px] w-[56px] items-center justify-center rounded-[14px] bg-white dark:bg-[#12162b] border border-gray-100 dark:border-[#2a2050]/50 shadow-[0_8px_25px_rgba(0,0,0,0.08)] dark:shadow-[0_0_25px_rgba(124,58,237,0.18),0_8px_25px_rgba(0,0,0,0.3)]"
                style={{ transform: "perspective(800px) rotateY(-5deg) translateZ(60px)" }}
              >
                <svg width="22" height="22" viewBox="0 0 16 16" fill="none" className="text-[#7c3aed] dark:text-[#a78bfa]">
                  <path d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z" fill="currentColor" />
                </svg>
              </div>

            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
