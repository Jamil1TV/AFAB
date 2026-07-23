"use client";

import { usePathname } from "@/i18n/routing";
import { useTranslations } from "next-intl";
import { 
  Settings, Building2, CreditCard, Users, Bell, 
  ShieldCheck, Webhook, Download, Palette, Globe 
} from "lucide-react";

export default function SettingsCatchAllPage() {
  const pathname = usePathname();
  const t = useTranslations("settings");
  
  // Extract the slug from the pathname (e.g. /dashboard/settings/notifications -> notifications)
  const parts = pathname.split("/");
  const activeTab = parts[parts.length - 1];

  const tabs = [
    { id: "general", label: t("tabs.general"), icon: <Settings className="w-4 h-4" /> },
    { id: "business-profile", label: t("tabs.businessProfile"), icon: <Building2 className="w-4 h-4" /> },
    { id: "subscription", label: t("tabs.subscription"), icon: <CreditCard className="w-4 h-4" /> },
    { id: "users-permissions", label: t("tabs.usersPermissions"), icon: <Users className="w-4 h-4" /> },
    { id: "notifications", label: t("tabs.notifications"), icon: <Bell className="w-4 h-4" /> },
    { id: "security", label: t("tabs.security"), icon: <ShieldCheck className="w-4 h-4" /> },
    { id: "integrations", label: t("tabs.integrations"), icon: <Webhook className="w-4 h-4" /> },
    { id: "data-export", label: t("tabs.dataExport"), icon: <Download className="w-4 h-4" /> },
    { id: "appearance", label: t("tabs.appearance"), icon: <Palette className="w-4 h-4" /> },
    { id: "language", label: t("tabs.language"), icon: <Globe className="w-4 h-4" /> },
  ];

  const currentTab = tabs.find(t => t.id === activeTab);

  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-12 text-center">
      <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4 text-primary">
        {currentTab?.icon || <Settings className="w-8 h-8" />}
      </div>
      <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
        {currentTab?.label || "Coming Soon"}
      </h3>
      <p className="text-gray-500">
        This section is coming soon.
      </p>
    </div>
  );
}
