"use client";

import { Search, Bell, Plus, Calendar as CalendarIcon, Menu, Globe, Sparkles } from "lucide-react";
import { ThemeToggle } from "@/components/theme-toggle";
import { useLocale, useTranslations } from "next-intl";
import { useRouter, usePathname, Link } from "@/i18n/routing";
import { useSidebar } from "@/components/dashboard/Sidebar";

export function DashboardHeader() {
  const locale = useLocale();
  const tLang = useTranslations("Common.language");
  const tHeader = useTranslations("Dashboard.header");
  const router = useRouter();
  const pathname = usePathname();
  const { setMobileOpen } = useSidebar();

  const toggleLanguage = () => {
    const nextLocale = locale === "en" ? "ar" : "en";
    router.replace(pathname, { locale: nextLocale });
  };

  return (
    <header className="z-30 flex h-16 shrink-0 items-center gap-4 border-b border-gray-200 dark:border-gray-800/60 bg-white/80 dark:bg-[#080c18]/80 px-4 backdrop-blur-md sm:gap-6 sm:px-6">
      {/* Mobile menu trigger */}
      <button 
        onClick={() => setMobileOpen(true)}
        className="flex h-9 w-9 items-center justify-center rounded-lg text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] lg:hidden"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* Global Search */}
      <div className="flex flex-1 items-center">
        <div className="relative w-full max-w-md">
          <div className="pointer-events-none absolute inset-y-0 start-0 flex items-center ps-3">
            <Search className="h-4 w-4 text-gray-400" />
          </div>
          <input
            type="text"
            placeholder={tHeader("search") || (locale === "ar" ? "ابحث عن أي شيء..." : "Search anything...")}
            className="block w-full rounded-full border border-gray-200 dark:border-gray-700/60 bg-gray-50 dark:bg-[#12162b] py-2 ps-10 pe-3 text-sm text-gray-900 dark:text-white placeholder:text-gray-500 focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
          />
          <div className="absolute inset-y-0 end-0 flex items-center pe-2">
            <kbd className="hidden items-center gap-1 rounded border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-1.5 font-mono text-[10px] font-medium text-gray-500 sm:flex">
              <span className="text-xs">⌘</span>K
            </kbd>
          </div>
        </div>
      </div>

      {/* Right side actions */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Theme Toggle */}
        <ThemeToggle />

        {/* Language Switcher */}
        <button 
          onClick={toggleLanguage}
          className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-white/[0.06] px-3.5 py-1.5 text-xs sm:text-sm font-medium text-gray-600 dark:text-gray-300 transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.1]"
        >
          <Globe className="h-4 w-4" />
          <span className="hidden sm:inline-block">{tLang("switchTo")}</span>
        </button>

        {/* Notifications */}
        <button 
          aria-label="Notifications"
          className="relative flex h-9 w-9 items-center justify-center rounded-full text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] transition-colors"
        >
          <Bell className="h-5 w-5" />
          <span className="absolute -top-0.5 -end-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white shadow-sm">
            3
          </span>
        </button>

        {/* Upgrade to Pro Button */}
        <Link
          href="/dashboard/plans"
          className="flex items-center gap-1.5 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 px-3.5 py-2 text-xs sm:text-sm font-semibold text-white shadow-md shadow-purple-600/30 transition-all hover:scale-[1.02] active:scale-[0.98]"
        >
          <Sparkles className="h-3.5 w-3.5" />
          <span>{locale === "ar" ? "الترقية إلى برو" : (tHeader("upgradeToPro") || "Upgrade to Pro")}</span>
        </Link>
      </div>
    </header>
  );
}
