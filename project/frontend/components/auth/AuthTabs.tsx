"use client";

import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";

interface AuthTabsProps {
  activeTab: "login" | "signup";
}

export function AuthTabs({ activeTab }: AuthTabsProps) {
  const t = useTranslations("Auth.login");

  return (
    <div className="flex rounded-xl bg-gray-100 dark:bg-[#0d1120] p-1 mb-8">
      <Link
        href="/login"
        className={`flex-1 py-2.5 text-center text-sm font-semibold rounded-lg transition-all duration-200 ${
          activeTab === "login"
            ? "bg-white dark:bg-[#1a1f35] text-gray-900 dark:text-white shadow-sm"
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
            ? "bg-white dark:bg-[#1a1f35] text-gray-900 dark:text-white shadow-sm"
            : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
        }`}
        aria-current={activeTab === "signup" ? "page" : undefined}
      >
        {t("tabSignUp")}
      </Link>
    </div>
  );
}
