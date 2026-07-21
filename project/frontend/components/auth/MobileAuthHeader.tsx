"use client";

import { useTranslations, useLocale } from "next-intl";
import { useRouter, usePathname, Link } from "@/i18n/routing";
import { Globe } from "lucide-react";
import { ThemeToggle } from "@/components/theme-toggle";

export function MobileAuthHeader() {
  const tLang = useTranslations("Common.language");
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();

  const toggleLanguage = () => {
    const nextLocale = locale === "en" ? "ar" : "en";
    router.replace(pathname, { locale: nextLocale });
  };

  return (
    <div className="mb-8 flex w-full max-w-[440px] items-center justify-between lg:hidden">
      {/* Logo */}
      <Link href="/" className="flex items-center gap-3">
        <div className="relative h-10 w-10 overflow-hidden rounded-[10px] bg-white shadow-sm">
          <img
            src="/assets/logo.png"
            alt="AFAB Logo"
            className="h-full w-full object-cover scale-[1.15]"
          />
        </div>
        <span className="text-[22px] font-bold tracking-tight text-gray-900 dark:text-white">
          AFAB
        </span>
      </Link>

      {/* Controls */}
      <div className="flex items-center gap-2">
        <ThemeToggle />
        <button
          onClick={toggleLanguage}
          className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-white/[0.06] px-3 py-2 text-sm font-medium text-gray-600 dark:text-gray-300 transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.1]"
        >
          <Globe className="h-4 w-4" />
          <span className="hidden sm:inline">{tLang("switchTo")}</span>
        </button>
      </div>
    </div>
  );
}
