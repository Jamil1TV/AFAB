"use client";

import { Search, Bell, Plus, Calendar as CalendarIcon, Menu, Globe } from "lucide-react";
import { ThemeToggle } from "@/components/theme-toggle";
import { useLocale, useTranslations } from "next-intl";
import { useRouter, usePathname } from "@/i18n/routing";

export function DashboardHeader() {
  const locale = useLocale();
  const tLang = useTranslations("Common.language");
  const tHeader = useTranslations("Dashboard.header");
  const router = useRouter();
  const pathname = usePathname();

  const toggleLanguage = () => {
    const nextLocale = locale === "en" ? "ar" : "en";
    router.replace(pathname, { locale: nextLocale });
  };

  return (
    <header className="sticky top-0 z-30 flex h-16 shrink-0 items-center gap-4 border-b border-gray-200 dark:border-gray-800/60 bg-white/80 dark:bg-[#080c18]/80 px-4 backdrop-blur-md sm:gap-6 sm:px-6">
      {/* Mobile menu trigger (hidden on desktop) */}
      <button className="flex h-9 w-9 items-center justify-center rounded-lg text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] lg:hidden">
        <Menu className="h-5 w-5" />
      </button>

      {/* Global Search */}
      <div className="flex flex-1 items-center">
        <div className="relative w-full max-w-md">
          <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
            <Search className="h-4 w-4 text-gray-400" />
          </div>
          <input
            type="text"
            placeholder={tHeader("search")}
            className="block w-full rounded-full border border-gray-200 dark:border-gray-700/60 bg-gray-50 dark:bg-[#12162b] py-2 pl-10 pr-3 text-sm text-gray-900 dark:text-white placeholder:text-gray-500 focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
          />
          <div className="absolute inset-y-0 right-0 flex items-center pr-2">
            <kbd className="hidden items-center gap-1 rounded border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-1.5 font-mono text-[10px] font-medium text-gray-500 sm:flex">
              <span className="text-xs">⌘</span>K
            </kbd>
          </div>
        </div>
      </div>

      {/* Right side actions */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Date Selector (hidden on very small screens) */}
        <div className="hidden sm:flex items-center gap-2 rounded-lg border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-[#12162b] px-3 py-1.5 text-sm font-medium text-gray-600 dark:text-gray-300 shadow-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-white/[0.05] transition-colors mr-2">
          <CalendarIcon className="h-4 w-4 text-gray-400" />
          <span>{tHeader("thisMonth")}</span>
        </div>

        {/* Theme Toggle */}
        <ThemeToggle />

        {/* Language Switcher */}
        <button 
          onClick={toggleLanguage}
          className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-white/[0.06] px-4 py-2 text-sm font-medium text-gray-600 dark:text-gray-300 transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.1]"
        >
          <Globe className="h-4 w-4" />
          <span className="hidden sm:inline-block">{tLang("switchTo")}</span>
        </button>

        {/* Notifications */}
        <button className="relative flex h-9 w-9 items-center justify-center rounded-full text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] transition-colors">
          <Bell className="h-5 w-5" />
          <span className="absolute right-2 top-2 flex h-2 w-2">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-[#8b5cf6] opacity-75"></span>
            <span className="relative inline-flex h-2 w-2 rounded-full bg-[#7c3aed]"></span>
          </span>
        </button>

        {/* Create Button */}
        <button className="hidden sm:flex items-center gap-1.5 rounded-full bg-[#7c3aed] px-4 py-2 text-sm font-semibold text-white shadow-md shadow-[#7c3aed]/20 hover:bg-[#6d28d9] transition-all hover:scale-[1.02] active:scale-[0.98] ml-1">
          <Plus className="h-4 w-4" />
          {tHeader("create")}
        </button>
        
        {/* Mobile Create Button */}
        <button className="flex sm:hidden h-9 w-9 items-center justify-center rounded-full bg-[#7c3aed] text-white shadow-md shadow-[#7c3aed]/20 hover:bg-[#6d28d9] transition-all ml-1">
          <Plus className="h-4 w-4" />
        </button>
      </div>
    </header>
  );
}
