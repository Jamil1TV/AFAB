"use client";

import { useState, useEffect, createContext, useContext } from "react";
import { UserService } from "@/lib/api/dashboard";
import { AuthStore } from "@/lib/auth-store";
import { Link, usePathname } from "@/i18n/routing";
import { 
  LayoutDashboard, 
  ArrowRightLeft, 
  TrendingDown, 
  TrendingUp, 
  FileText, 
  Users, 
  BarChart3, 
  Sparkles, 
  CalendarDays, 
  Settings,
  ChevronsUpDown,
  PanelLeftClose,
  PanelLeftOpen,
  LogOut,
  X
} from "lucide-react";

import { useTranslations, useLocale } from "next-intl";

interface UserProfile {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  workspaceName: string;
  planType: string;
  avatarUrl?: string;
}

type NavItem = {
  name: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
};

// Context for sidebar state (shared with layout)
export const SidebarContext = createContext<{
  collapsed: boolean;
  setCollapsed: (v: boolean) => void;
  mobileOpen: boolean;
  setMobileOpen: (v: boolean) => void;
}>({ collapsed: false, setCollapsed: () => {}, mobileOpen: false, setMobileOpen: () => {} });

export function useSidebar() {
  return useContext(SidebarContext);
}

export function SidebarProvider({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <SidebarContext.Provider value={{ collapsed, setCollapsed, mobileOpen, setMobileOpen }}>
      {children}
    </SidebarContext.Provider>
  );
}

export function Sidebar() {
  const tSidebar = useTranslations("Dashboard.sidebar");
  const t = useTranslations("Dashboard.sidebar");
  const locale = useLocale();
  const pathname = usePathname();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const { collapsed, setCollapsed, mobileOpen, setMobileOpen } = useSidebar();

  const handleLogout = () => {
    AuthStore.clearAuth();
    window.location.href = `/${locale}/login`;
  };

  useEffect(() => {
    async function fetchProfile() {
      try {
        const data = await UserService.getProfile();
        setProfile(data);
      } catch (err) {
        console.error("Failed to load user profile in Sidebar:", err);
      }
    }
    fetchProfile();
  }, []);

  const mainNavItems: NavItem[] = [
    { name: tSidebar("overview"), href: "/dashboard", icon: LayoutDashboard },
    { name: tSidebar("transactions"), href: "/dashboard/transactions", icon: ArrowRightLeft },
    { name: tSidebar("expenses"), href: "/dashboard/expenses", icon: TrendingDown },
    { name: tSidebar("revenue"), href: "/dashboard/revenue", icon: TrendingUp },
    { name: tSidebar("invoices"), href: "/dashboard/invoices", icon: FileText },
    { name: tSidebar("customers"), href: "/dashboard/customers", icon: Users },
    { name: tSidebar("reports"), href: "/dashboard/reports", icon: BarChart3 },
  ];

  const workspaceItems: NavItem[] = [
    { name: tSidebar("aiAssistant"), href: "/dashboard/ai", icon: Sparkles, badge: tSidebar("new") },
    { name: tSidebar("calendar"), href: "/dashboard/calendar", icon: CalendarDays },
    { name: tSidebar("settings"), href: "/dashboard/settings", icon: Settings },
  ];

  const renderNavItems = (items: NavItem[]) => {
    return items.map((item) => {
      const isActive = pathname === item.href || (item.href !== "/dashboard" && pathname.startsWith(item.href));
      
      return (
        <Link
          key={item.name}
          href={item.href}
          onClick={() => setMobileOpen(false)}
          title={collapsed ? item.name : undefined}
          className={`group flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 ${
            isActive 
              ? "bg-primary/10 text-primary" 
              : "text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] dark:hover:text-gray-200"
          }`}
        >
          <div className={`flex items-center ${collapsed ? "justify-center w-full" : "gap-3"}`}>
            <item.icon className={`h-5 w-5 shrink-0 ${isActive ? "text-primary" : "text-gray-400 group-hover:text-gray-500 dark:group-hover:text-gray-300"}`} />
            {!collapsed && <span>{item.name}</span>}
          </div>
          {item.badge && !collapsed && (
            <span className="rounded-full bg-primary px-2 py-0.5 text-[10px] font-bold text-primary-foreground shadow-sm">
              {item.badge}
            </span>
          )}
        </Link>
      );
    });
  };

  const sidebarContent = (
    <>
      {/* ── Brand / Workspace Selector ── */}
      <div className="flex h-16 shrink-0 items-center px-3 border-b border-gray-200 dark:border-gray-800/60">
        <div className={`flex w-full items-center ${collapsed ? "justify-center" : "justify-between"} rounded-xl hover:bg-gray-100 dark:hover:bg-white/[0.05] p-1.5 transition-colors cursor-pointer`}>
          <div className={`flex items-center ${collapsed ? "" : "gap-2.5"} overflow-hidden`}>
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-primary to-primary/80 text-primary-foreground shadow-md shadow-primary/20">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" className="currentColor">
                <path d="M12 2L2 12L12 22L22 12L12 2Z" fill="currentColor" opacity="0.3" />
                <path d="M12 7L7 12L12 17L17 12L12 7Z" fill="currentColor" />
              </svg>
            </div>
            {!collapsed && (
              <div className="flex flex-col overflow-hidden">
                <span className="truncate text-sm font-bold text-gray-900 dark:text-white">{profile?.workspaceName || "Acme Corp"}</span>
                <span className="truncate text-[10px] font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{profile?.planType || tSidebar("freePlan")}</span>
              </div>
            )}
          </div>
          {!collapsed && <ChevronsUpDown className="h-4 w-4 text-gray-400 shrink-0" />}
        </div>
      </div>

      {/* ── Navigation ── */}
      <div className="flex-1 overflow-y-auto px-3 py-4 custom-scrollbar">
        <nav className="space-y-1">
          {renderNavItems(mainNavItems)}
        </nav>

        {!collapsed && (
          <div className="mt-8 mb-2 px-3">
            <h4 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500">
              {tSidebar("workspace")}
            </h4>
          </div>
        )}
        {collapsed && <div className="my-4 border-t border-gray-200 dark:border-gray-800/60" />}
        
        <nav className="space-y-1">
          {renderNavItems(workspaceItems)}
        </nav>
      </div>

      {/* ── Upgrade Card ── */}
      {!collapsed && (
        <div className="px-4 py-4">
          <div className="relative overflow-hidden rounded-2xl bg-gradient-purple p-4 text-white shadow-lg shadow-primary/20">
            <div className="absolute -end-4 -top-4 h-24 w-24 rounded-full bg-white/10 blur-2xl" />
            <h4 className="relative z-10 text-sm font-bold">{tSidebar("upgradeTitle")}</h4>
            <p className="relative z-10 mt-1 text-xs text-white/80 leading-relaxed">
              {tSidebar("upgradeDesc")}
            </p>
            <button className="relative z-10 mt-3 w-full rounded-lg bg-white px-3 py-2 text-xs font-bold text-primary transition-transform hover:scale-[1.02] active:scale-[0.98]">
              {tSidebar("upgradeBtn")}
            </button>
          </div>
        </div>
      )}

      {/* ── User Profile & Logout ── */}
      <div className="border-t border-gray-200 dark:border-gray-800/60 p-3 space-y-2">
        <div className={`flex items-center ${collapsed ? "justify-center" : "justify-between"}`}>
          <div className={`flex items-center ${collapsed ? "justify-center" : "gap-3 w-full"} bg-white dark:bg-gray-800 p-2 rounded-xl border border-gray-100 dark:border-gray-700`}>
            <div className="w-9 h-9 rounded-lg bg-gray-100 dark:bg-gray-700 overflow-hidden shrink-0">
              {profile?.avatarUrl ? (
                <img 
                  src={profile.avatarUrl} 
                  alt="Profile" 
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-primary/10 text-primary font-semibold text-sm">
                  {profile?.firstName?.[0] || ""}{profile?.lastName?.[0] || ""}
                </div>
              )}
            </div>
            {!collapsed && (
              <div className="flex-1 min-w-0 text-left">
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {profile ? `${profile.firstName} ${profile.lastName}` : "Loading..."}
                </p>
                <p className="text-xs text-gray-500 truncate">{t("owner")}</p>
              </div>
            )}
          </div>
        </div>

        {/* Logout Button */}
        <button
          onClick={handleLogout}
          title={collapsed ? "Logout" : undefined}
          className={`flex w-full items-center ${collapsed ? "justify-center" : "gap-3"} rounded-xl px-3 py-2.5 text-sm font-medium text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors`}
        >
          <LogOut className="h-4.5 w-4.5 shrink-0" />
          {!collapsed && <span>Logout</span>}
        </button>
      </div>

      {/* ── Collapse Toggle (desktop only) ── */}
      <div className="hidden lg:flex border-t border-gray-200 dark:border-gray-800/60 p-2">
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="flex w-full items-center justify-center gap-2 rounded-lg px-3 py-2 text-xs font-medium text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
        >
          {collapsed ? <PanelLeftOpen className="h-4 w-4" /> : <PanelLeftClose className="h-4 w-4" />}
          {!collapsed && <span>Collapse</span>}
        </button>
      </div>
    </>
  );

  return (
    <>
      {/* Desktop Sidebar */}
      <aside
        className={`hidden lg:flex flex-col border-r border-gray-200 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18] sticky top-0 h-screen transition-all duration-300 ease-in-out ${
          collapsed ? "w-[68px]" : "w-64"
        }`}
      >
        {sidebarContent}
      </aside>

      {/* Mobile Overlay */}
      {mobileOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Mobile Sidebar Drawer */}
      <aside
        className={`fixed inset-y-0 start-0 z-50 flex w-72 flex-col border-r border-gray-200 dark:border-gray-800/60 bg-gray-50 dark:bg-[#080c18] transition-transform duration-300 ease-in-out lg:hidden ${
          mobileOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        {/* Close button */}
        <button
          onClick={() => setMobileOpen(false)}
          className="absolute top-4 end-4 z-10 flex h-8 w-8 items-center justify-center rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-white/[0.05]"
        >
          <X className="h-5 w-5" />
        </button>
        {sidebarContent}
      </aside>
    </>
  );
}
