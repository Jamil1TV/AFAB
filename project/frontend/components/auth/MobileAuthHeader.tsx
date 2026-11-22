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
        <div className="flex h-10 w-10 items-center justify-center overflow-hidden rounded-xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm">
          <img
            src="/assets/afablogo.png"
            alt="AFAB Logo"
            className="h-7 w-7 object-contain dark:hidden"
          />
          <img
            src="/assets/afablogo_dark.png"
            alt="AFAB Logo Dark"
            className="h-7 w-7 object-contain hidden dark:block"
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
          className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] px-3 py-2 text-sm font-medium text-gray-600 dark:text-gray-300 transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.05]"
        >
          <Globe className="h-4 w-4" />
          <span className="hidden sm:inline">{tLang("switchTo")}</span>
        </button>
      </div>
    </div>
  );
}
