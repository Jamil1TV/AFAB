"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Link, usePathname } from "@/i18n/routing";
import { SettingsProvider } from "@/components/settings/SettingsProvider";
import { 
  Settings, Building2, CreditCard, Users, Bell, 
  ShieldCheck, Webhook, Download, Palette, Globe,
  ChevronDown, PanelLeftClose, PanelLeftOpen
} from "lucide-react";

export default function SettingsLayout({
  children,
}: {
  children: React.ReactNode;
  params?: Promise<any>;
}) {
  const t = useTranslations("settings");
  const pathname = usePathname();
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  
  const tabs = [
    { id: "general", path: "/dashboard/settings/general", label: t("tabs.general"), icon: <Settings className="w-4 h-4" /> },
    { id: "business-profile", path: "/dashboard/settings/business-profile", label: t("tabs.businessProfile"), icon: <Building2 className="w-4 h-4" /> },
    { id: "subscription", path: "/dashboard/settings/subscription", label: t("tabs.subscription"), icon: <CreditCard className="w-4 h-4" /> },
    { id: "users-permissions", path: "/dashboard/settings/users-permissions", label: t("tabs.usersPermissions"), icon: <Users className="w-4 h-4" /> },
    { id: "notifications", path: "/dashboard/settings/notifications", label: t("tabs.notifications"), icon: <Bell className="w-4 h-4" /> },
    { id: "security", path: "/dashboard/settings/security", label: t("tabs.security"), icon: <ShieldCheck className="w-4 h-4" /> },
    { id: "integrations", path: "/dashboard/settings/integrations", label: t("tabs.integrations"), icon: <Webhook className="w-4 h-4" /> },
    { id: "data-export", path: "/dashboard/settings/data-export", label: t("tabs.dataExport"), icon: <Download className="w-4 h-4" /> },
    { id: "appearance", path: "/dashboard/settings/appearance", label: t("tabs.appearance"), icon: <Palette className="w-4 h-4" /> },
    { id: "language", path: "/dashboard/settings/language", label: t("tabs.language"), icon: <Globe className="w-4 h-4" /> },
  ];

  const activeTab = tabs.find(tab => pathname === tab.path) || tabs[0];

  return (
    <SettingsProvider>
      <div className="flex h-full">
        
        {/* ── Desktop Settings Sidebar (fixed, scrolls independently) ── */}
        <aside className={`hidden lg:flex flex-col shrink-0 border-r rtl:border-r-0 rtl:border-l border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] transition-all duration-300 ease-in-out overflow-x-hidden ${
          collapsed ? "w-[60px]" : "w-60"
        }`}>
          
          {/* Settings Header */}
          <div className={`shrink-0 p-4 border-b border-gray-100 dark:border-gray-800/60 ${collapsed ? "px-2" : ""}`}>
            {!collapsed && (
              <div className="min-w-0 text-start">
                <h2 className="text-lg font-bold text-gray-900 dark:text-white truncate">
                  {t("title")}
                </h2>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 truncate">
                  {t("subtitle")}
                </p>
              </div>
            )}
            {collapsed && (
              <div className="flex justify-center">
                <Settings className="w-5 h-5 text-gray-400" />
              </div>
            )}
          </div>

          {/* Nav Items (scrollable) */}
          <nav className="flex-1 overflow-y-auto p-2 space-y-0.5 custom-scrollbar">
            {tabs.map((tab) => {
              const isActive = pathname === tab.path;
              return (
                <Link
                  key={tab.id}
                  href={tab.path}
                  title={collapsed ? tab.label : undefined}
                  className={`group flex items-center ${collapsed ? "justify-center" : "gap-3"} px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 relative
                    ${isActive 
                      ? "bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]" 
                      : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/[0.05] hover:text-gray-900 dark:hover:text-white"
                    }`}
                >
                  {/* Active indicator bar */}
                  {isActive && (
                    <div className="absolute start-0 top-1/2 -translate-y-1/2 w-[3px] h-5 bg-[#8b5cf6] rounded-full" />
                  )}
                  <span className={`shrink-0 ${isActive ? "text-[#7c3aed] dark:text-[#a78bfa]" : "text-gray-400 dark:text-gray-500 group-hover:text-gray-600 dark:group-hover:text-gray-300"}`}>
                    {tab.icon}
                  </span>
                  {!collapsed && <span className="truncate">{tab.label}</span>}
                </Link>
              );
            })}
          </nav>

          {/* Collapse Toggle */}
          <div className="shrink-0 border-t border-gray-100 dark:border-gray-800/60 p-2">
            <button
              onClick={() => setCollapsed(!collapsed)}
              title={collapsed ? (t("expand") || "Expand") : (t("collapse") || "Collapse")}
              className="flex w-full items-center justify-center gap-2 rounded-xl px-3 py-2 text-xs font-medium text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
            >
              {collapsed ? <PanelLeftOpen className="h-4 w-4 rtl:rotate-180" /> : <PanelLeftClose className="h-4 w-4 rtl:rotate-180" />}
              {!collapsed && <span>{t("collapse") || "Collapse"}</span>}
            </button>
          </div>
        </aside>

        {/* ── Main Content Column ── */}
        <div className="flex-1 min-w-0 overflow-y-auto custom-scrollbar">
          <div className="afab-page">

            {/* Mobile Navigation (horizontally scrollable tab strip + dropdown, visible < lg) */}
            <div className="lg:hidden space-y-3">
              <div>
                <h2 className="text-lg font-bold text-gray-900 dark:text-white">
                  {t("title")}
                </h2>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {t("subtitle")}
                </p>
              </div>
              <nav className="flex items-center gap-1.5 overflow-x-auto scrollbar-none rounded-2xl border border-gray-200 bg-white p-1.5 shadow-sm dark:border-gray-800/60 dark:bg-[#0c101c]">
                {tabs.map((tab) => {
                  const isActive = pathname === tab.path;
                  return (
                    <Link
                      key={tab.id}
                      href={tab.path}
                      className={`inline-flex items-center gap-2 whitespace-nowrap rounded-xl px-3 py-2 text-xs font-semibold transition-all ${
                        isActive
                          ? "bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]"
                          : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/[0.05] hover:text-gray-900 dark:hover:text-white"
                      }`}
                    >
                      <span className={isActive ? "text-[#7c3aed] dark:text-[#a78bfa]" : "text-gray-400 dark:text-gray-500"}>
                        {tab.icon}
                      </span>
                      {tab.label}
                    </Link>
                  );
                })}
              </nav>

              <button
                onClick={() => setMobileNavOpen(!mobileNavOpen)}
                className="afab-card flex items-center justify-between w-full px-4 py-3 text-sm font-medium text-gray-900 dark:text-white"
              >
                <div className="flex items-center gap-3">
                  <span className="text-[#7c3aed] dark:text-[#a78bfa]">{activeTab.icon}</span>
                  {activeTab.label}
                </div>
                <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform duration-200 ${mobileNavOpen ? "rotate-180" : ""}`} />
              </button>
              
              {mobileNavOpen && (
                <div className="afab-popover overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
                  {tabs.map((tab) => {
                    const isActive = pathname === tab.path;
                    return (
                      <Link
                        key={tab.id}
                        href={tab.path}
                        onClick={() => setMobileNavOpen(false)}
                        className={`flex items-center gap-3 rounded-xl px-4 py-2.5 text-sm font-medium transition-colors
                          ${isActive 
                            ? "bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]" 
                            : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/[0.05] hover:text-gray-900 dark:hover:text-white"
                          }`}
                      >
                        <span className={isActive ? "text-[#7c3aed] dark:text-[#a78bfa]" : "text-gray-400 dark:text-gray-500"}>
                          {tab.icon}
                        </span>
                        {tab.label}
                      </Link>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Page Content */}
            {children}
          </div>
        </div>

      </div>
    </SettingsProvider>
  );
}
