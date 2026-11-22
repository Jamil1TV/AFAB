"use client";

import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";

interface AuthTabsProps {
  activeTab: "login" | "signup";
}

export function AuthTabs({ activeTab }: AuthTabsProps) {
  const t = useTranslations("Auth.login");

  return (
    <div className="flex rounded-xl border border-gray-200 bg-gray-100 dark:border-gray-800/60 dark:bg-[#080c18] p-1 mb-8">
      <Link
        href="/login"
        className={`flex-1 py-2.5 text-center text-sm font-semibold rounded-lg transition-all duration-200 ${
          activeTab === "login"
            ? "bg-white dark:bg-[#0c101c] text-gray-900 dark:text-white shadow-sm"
            : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
        }`}
        aria-current={activeTab === "login" ? "page" : undefined}
      >
        {t("tabLogin")}
      </Link>
      <Link
        href="/signup"
        className={`flex-1 py-2.5 text-center text-sm font-semibold rounded-lg transition-all duration-200 ${
          activeTab === "signup"
            ? "bg-white dark:bg-[#0c101c] text-gray-900 dark:text-white shadow-sm"
            : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
        }`}
        aria-current={activeTab === "signup" ? "page" : undefined}
      >
        {t("tabSignUp")}
      </Link>
    </div>
  );
}
