"use client";

import { useState, useEffect, createContext, useContext, useMemo, useSyncExternalStore } from "react";
import { UserService } from "@/lib/api/dashboard";
import { AuthStore, UserDto } from "@/lib/auth-store";
import { AuthService } from "@/lib/api/auth";
import { Link, usePathname, useRouter } from "@/i18n/routing";
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
  Coins,
  PiggyBank,
  Repeat,
  ChevronsUpDown,
  PanelLeftClose,
  PanelLeftOpen,
  LogOut,
  X,
  ArrowRight,
  ChevronDown
} from "lucide-react";

import { useTranslations, useLocale } from "next-intl";
import { BusinessSwitcher } from "./BusinessSwitcher";
import { SubscriptionService } from "@/lib/api/subscription";

interface UserProfile {
  id: number | string;
  firstName: string;
  lastName: string;
  email: string;
  businessName?: string;
  workspaceName?: string;
  planType?: string;
  planTier?: string;
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

const subscribeToStorage = (callback: () => void) => {
  if (typeof window === "undefined") return () => {};
  window.addEventListener("storage", callback);
  window.addEventListener("afab_profile_updated", callback);
  return () => {
    window.removeEventListener("storage", callback);
    window.removeEventListener("afab_profile_updated", callback);
  };
};

const getStoredUserRaw = (): string | null => {
  if (typeof window === "undefined") return null;
  try {
    return sessionStorage.getItem("afab_user");
  } catch {
    return null;
  }
};

const getServerUserRaw = (): null => null;

export function Sidebar() {
  const tSidebar = useTranslations("Dashboard.sidebar");
  const t = useTranslations("Dashboard.sidebar");
  const locale = useLocale();
  const pathname = usePathname();
  const router = useRouter();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const storedUserRaw = useSyncExternalStore(
    subscribeToStorage,
    getStoredUserRaw,
    getServerUserRaw
  );
  const cachedUser = useMemo<UserDto | null>(() => {
    if (!storedUserRaw) return null;
    try {
      return JSON.parse(storedUserRaw) as UserDto;
    } catch {
      return null;
    }
  }, [storedUserRaw]);
  const { collapsed, setCollapsed, mobileOpen, setMobileOpen } = useSidebar();
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);
  const [planSlug, setPlanSlug] = useState<string | null>(null);

  const handleNavigate = (path: string) => {
    setUserMenuOpen(false);
    router.push(path);
  };

  const handleLogout = async () => {
    if (loggingOut) return;
    setLoggingOut(true);
    try {
      await AuthService.logout();
    } catch (err) {
      console.error("Logout failed:", err);
    } finally {
      AuthStore.clearAuth();
      window.location.href = `/${locale}/login`;
    }
  };

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      const target = event.target as HTMLElement | null;
      if (target && !target.closest("[data-user-menu]")) {
        setUserMenuOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    async function fetchProfileAndPlan() {
      const cachedTier = AuthStore.getUser()?.planTier;
      if (cachedTier) {
        setPlanSlug(cachedTier.toLowerCase());
      }
      try {
        const [data, sub] = await Promise.all([
          UserService.getProfile(),
          SubscriptionService.getMySubscription().catch(() => null),
        ]);
        setProfile(data);
        const resolvedSlug = (
          sub?.planSlug ||
          data?.planTier ||
          data?.planType ||
          cachedTier ||
          "free"
        ).toLowerCase();
        setPlanSlug(resolvedSlug);
        AuthStore.updateUser({ planTier: resolvedSlug.toUpperCase() });
      } catch (err) {
        console.error("Failed to load user profile in Sidebar:", err);
        if (!cachedTier) {
          setPlanSlug("free");
        }
      }
    }
    fetchProfileAndPlan();

    const handleProfileUpdated = (event: Event) => {
      const detail = (event as CustomEvent).detail;
      if (detail) {
        setProfile((prev) => (prev ? { ...prev, ...detail } : prev));
        if (detail.planTier) {
          setPlanSlug(String(detail.planTier).toLowerCase());
        }
      } else {
        fetchProfileAndPlan();
      }
    };

    const handleSubUpdated = () => {
      fetchProfileAndPlan();
    };

    window.addEventListener("afab_profile_updated", handleProfileUpdated);
    window.addEventListener("afab:subscription-updated", handleSubUpdated);
    return () => {
      window.removeEventListener("afab_profile_updated", handleProfileUpdated);
      window.removeEventListener("afab:subscription-updated", handleSubUpdated);
    };
  }, []);

  const mainNavItems: NavItem[] = [
    { name: tSidebar("overview"), href: "/dashboard", icon: LayoutDashboard },
    { name: tSidebar("transactions"), href: "/dashboard/transactions", icon: ArrowRightLeft },
    { name: tSidebar("expenses"), href: "/dashboard/expenses", icon: TrendingDown },
    { name: tSidebar("revenue"), href: "/dashboard/revenue", icon: TrendingUp },
    { name: tSidebar("invoices"), href: "/dashboard/invoices", icon: FileText },
    { name: tSidebar("customers"), href: "/dashboard/customers", icon: Users },
    { name: tSidebar("budgets"), href: "/dashboard/budgets", icon: PiggyBank },
    { name: tSidebar("recurring"), href: "/dashboard/recurring", icon: Repeat },
    { name: tSidebar("reports"), href: "/dashboard/reports", icon: BarChart3 },
    { name: tSidebar("currencies") || "Currencies", href: "/dashboard/currencies", icon: Coins, badge: "FX" },
  ];

  const workspaceItems: NavItem[] = [
    { name: tSidebar("aiAssistant"), href: "/dashboard/ai", icon: Sparkles, badge: tSidebar("new") },
    { name: tSidebar("calendar"), href: "/dashboard/calendar", icon: CalendarDays },
    { name: tSidebar("settings"), href: "/dashboard/settings", icon: Settings },
  ];

  const devSafePrefetch = process.env.NODE_ENV === "production" ? undefined : false;

  const renderNavItems = (items: NavItem[]) => {
    return items.map((item) => {
      const isActive = 
        pathname === item.href || 
        (item.href !== "/dashboard" && pathname.startsWith(item.href));
      
      return (
        <Link
          key={item.name}
          href={item.href}
          prefetch={devSafePrefetch}
          onClick={() => setMobileOpen(false)}
          title={collapsed ? item.name : undefined}
          className={`group flex items-center ${collapsed ? "justify-center" : "justify-between"} rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 ${
            isActive 
              ? "bg-[var(--primary)]/10 text-[var(--primary)] dark:bg-[var(--primary)]/20 dark:text-[var(--primary)] shadow-sm font-semibold" 
              : "text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] dark:hover:text-gray-200"
          }`}
        >
          <div className={`flex items-center ${collapsed ? "justify-center w-full" : "gap-3 min-w-0"}`}>
            <item.icon className={`h-5 w-5 shrink-0 ${isActive ? "text-[var(--primary)]" : "text-gray-400 group-hover:text-gray-500 dark:group-hover:text-gray-300"}`} />
            {!collapsed && <span className="truncate">{item.name}</span>}
          </div>
          {item.badge && !collapsed && (
            <span className="rounded-full bg-[var(--primary)]/10 dark:bg-[var(--primary)]/20 border border-[var(--primary)]/25 dark:border-[var(--primary)]/30 px-2 py-0.5 text-[10px] font-bold text-[var(--primary)] shadow-sm shrink-0 ms-2">
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
      <div className="flex h-16 shrink-0 items-center px-3 border-b border-gray-200 dark:border-gray-800/60 relative z-30">
        <BusinessSwitcher collapsed={collapsed} profile={profile} />
      </div>

      {/* ── Navigation ── */}
      <div className="flex-1 overflow-y-auto px-3 py-4 custom-scrollbar">
        <nav className="space-y-1">
          {renderNavItems(mainNavItems)}
        </nav>

        {!collapsed && (
          <div className="mt-8 mb-2 px-3">
            <h4 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 truncate">
              {tSidebar("workspace")}
            </h4>
          </div>
        )}
        {collapsed && <div className="my-4 border-t border-gray-200 dark:border-gray-800/60 mx-1" />}
        
        <nav className="space-y-1">
          {renderNavItems(workspaceItems)}
        </nav>
      </div>

      {/* ── Upgrade Card (shown ONLY for Free plan when sidebar is expanded) ── */}
      {!collapsed && planSlug === "free" && (
        <div className="px-3 py-3 shrink-0">
          <div className="relative overflow-hidden rounded-2xl bg-gradient-to-b from-purple-50/90 via-indigo-50/40 to-white dark:from-[#131735] dark:via-[#0f132b] dark:to-[#090c1e] border border-purple-200/80 dark:border-purple-500/25 p-4 shadow-md shadow-purple-500/5 dark:shadow-2xl dark:shadow-black/60 transition-all">
            {/* Ambient decorative lighting */}
            <div className="absolute -end-4 -top-4 h-24 w-24 rounded-full bg-purple-500/15 dark:bg-purple-600/25 blur-2xl pointer-events-none" />
            <div className="absolute -start-4 -bottom-4 h-20 w-20 rounded-full bg-indigo-500/10 dark:bg-indigo-600/20 blur-xl pointer-events-none" />

            <h4 className="relative z-10 text-sm font-bold text-gray-900 dark:text-white">
              {locale === "ar" ? "افتح المزيد مع برو" : (tSidebar("upgradeCardTitle") || "Unlock more with Pro")}
            </h4>
            <p className="relative z-10 mt-1 text-xs text-gray-600 dark:text-gray-300 leading-snug">
              {locale === "ar" ? "احصل على ميزات الذكاء الاصطناعي المتقدمة وإدارة شركات متعددة." : (tSidebar("upgradeCardDesc") || "Get advanced AI features and manage multiple businesses.")}
            </p>

            <div className="relative my-2.5 h-20 w-full flex items-center justify-center">
              {/* Radial glow halo */}
              <div className="absolute h-16 w-16 rounded-full bg-purple-500/25 dark:bg-purple-600/35 blur-xl pointer-events-none" />
              <div className="relative rounded-2xl p-1 bg-[#090d20] border border-purple-200/80 dark:border-purple-500/40 shadow-md shadow-purple-500/15 dark:shadow-[0_0_25px_rgba(139,92,246,0.35)] overflow-hidden">
                <img 
                  src="/images/plans/crystal-cube.jpg" 
                  alt="Pro Crystal"
                  className="h-16 w-16 object-cover rounded-xl transition-transform hover:scale-105 duration-300" 
                />
              </div>
            </div>

            <Link 
              href="/dashboard/settings/subscription"
              prefetch={devSafePrefetch}
              className="relative z-10 flex items-center justify-center gap-1.5 w-full rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 px-3 py-2.5 text-xs font-bold text-white shadow-md shadow-purple-600/30 dark:shadow-purple-900/50 transition-all hover:scale-[1.02] active:scale-[0.98]"
            >
              <span>{locale === "ar" ? "الترقية الآن" : (tSidebar("upgradeBtn") || "Upgrade Now")}</span>
              <ArrowRight className="h-3.5 w-3.5 rtl:rotate-180" />
            </Link>
          </div>
        </div>
      )}

      {/* ── User Profile & Dropdown (with Logout inside) ── */}
      <div 
        data-user-menu="true"
        className={`border-t border-gray-200 dark:border-gray-800/60 ${collapsed ? "p-2" : "p-3"} shrink-0 relative z-30`}
      >
        <div 
          onClick={() => setUserMenuOpen(!userMenuOpen)}
          role="button"
          tabIndex={0}
          className={`flex items-center ${collapsed ? "justify-center p-1" : "gap-3 w-full bg-white dark:bg-[#0c101c] p-2.5 rounded-xl border border-gray-200 dark:border-gray-800/60 shadow-sm"} cursor-pointer hover:bg-gray-50 dark:hover:bg-white/[0.04] transition-all`}
        >
          <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-amber-500 to-purple-600 p-[1.5px] shrink-0">
            <div className="w-full h-full rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden flex items-center justify-center text-xs font-bold text-gray-900 dark:text-white">
              {profile?.avatarUrl ? (
                <img 
                  src={profile.avatarUrl} 
                  alt="Profile" 
                  className="w-full h-full object-cover"
                />
              ) : (
                <span>
                  {profile?.firstName
                    ? `${profile.firstName[0]}${profile?.lastName?.[0] || ""}`
                    : (cachedUser?.firstName?.[0] || "U")}
                </span>
              )}
            </div>
          </div>
          {!collapsed && (
            <div className="flex-1 min-w-0 text-start flex items-center justify-between">
              <div className="overflow-hidden min-w-0">
                <p className="text-xs sm:text-sm font-bold text-gray-900 dark:text-white truncate">
                  {profile?.firstName
                    ? `${profile.firstName} ${profile.lastName}`
                    : cachedUser?.firstName
                      ? `${cachedUser.firstName} ${cachedUser.lastName}`
                      : (locale === "ar" ? "حسابي" : "My Account")}
                </p>
                <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate">
                  {profile?.businessName || tSidebar("businessOwner") || (locale === "ar" ? "مالك العمل" : "Business Owner")}
                </p>
              </div>
              <ChevronDown className={`h-4 w-4 text-gray-400 shrink-0 ms-1 transition-transform duration-200 ${userMenuOpen ? "rotate-180 text-primary" : ""}`} />
            </div>
          )}
        </div>

        {/* Dropdown Menu Popup (positioned above profile) */}
        {userMenuOpen && (
          <div 
            onMouseDown={(e) => e.stopPropagation()}
            className={`absolute z-50 bottom-full ${collapsed ? "start-full ms-2 mb-0" : "start-3 end-3 mb-2"} rounded-2xl bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 p-2 shadow-2xl shadow-black/50 backdrop-blur-md`}
          >
            {/* User Info Header */}
            <div className="px-3 py-2 border-b border-gray-100 dark:border-gray-800/80">
              <p className="text-xs font-bold text-gray-900 dark:text-white truncate">
                {profile?.firstName
                  ? `${profile.firstName} ${profile.lastName}`
                  : cachedUser?.firstName
                    ? `${cachedUser.firstName} ${cachedUser.lastName}`
                    : (locale === "ar" ? "حسابي" : "My Account")}
              </p>
              <p className="text-[10px] text-gray-500 dark:text-gray-400 truncate">
                {profile?.email || cachedUser?.email || ""}
              </p>
            </div>

            {/* Menu Links */}
            <div className="py-1 space-y-0.5">
              <Link
                href="/dashboard/settings/general"
                prefetch={devSafePrefetch}
                onClick={() => setUserMenuOpen(false)}
                className="flex w-full items-center gap-2.5 px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.06] rounded-xl transition-colors text-start cursor-pointer"
              >
                <Settings className="h-4 w-4 text-gray-400 shrink-0" />
                <span>{locale === "ar" ? "إعدادات الحساب" : (tSidebar("accountSettings") || "Account Settings")}</span>
              </Link>
              <Link
                href="/dashboard/settings/business-profile"
                prefetch={devSafePrefetch}
                onClick={() => setUserMenuOpen(false)}
                className="flex w-full items-center gap-2.5 px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.06] rounded-xl transition-colors text-start cursor-pointer"
              >
                <Sparkles className="h-4 w-4 text-purple-400 shrink-0" />
                <span>{locale === "ar" ? "الملف التجاري" : (tSidebar("businessProfile") || "Business Profile")}</span>
              </Link>
            </div>

            {/* Logout Action Inside Dropdown */}
            <div className="pt-1 border-t border-gray-100 dark:border-gray-800/80">
              <button
                type="button"
                disabled={loggingOut}
                onClick={async (e) => {
                  e.stopPropagation();
                  await handleLogout();
                }}
                className="flex w-full items-center gap-2.5 px-3 py-2 text-xs font-semibold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors text-start cursor-pointer disabled:opacity-50"
              >
                {loggingOut ? (
                  <div className="h-4 w-4 border-2 border-red-500 border-t-transparent rounded-full animate-spin shrink-0" />
                ) : (
                  <LogOut className="h-4 w-4 rtl:rotate-180 shrink-0" />
                )}
                <span>
                  {loggingOut 
                    ? (locale === "ar" ? "جاري تسجيل الخروج..." : "Logging out...") 
                    : (locale === "ar" ? "تسجيل الخروج" : (tSidebar("logout") || "Logout"))}
                </span>
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ── Collapse Toggle (desktop only) ── */}
      <div className="hidden lg:flex border-t border-gray-200 dark:border-gray-800/60 p-2 shrink-0">
        <button
          onClick={() => setCollapsed(!collapsed)}
          title={collapsed ? (tSidebar("expand") || "Expand") : (tSidebar("collapse") || "Collapse")}
          className="flex w-full items-center justify-center gap-2 rounded-lg px-3 py-2 text-xs font-medium text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
        >
          {collapsed ? (
            <PanelLeftOpen className="h-4 w-4 rtl:rotate-180" />
          ) : (
            <PanelLeftClose className="h-4 w-4 rtl:rotate-180" />
          )}
          {!collapsed && <span>{tSidebar("collapse") || "Collapse"}</span>}
        </button>
      </div>
    </>
  );

  return (
    <>
      {/* Desktop Sidebar */}
      <aside
        className={`hidden lg:flex flex-col border-r rtl:border-r-0 rtl:border-l border-gray-200 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18] sticky top-0 h-screen transition-all duration-300 ease-in-out shrink-0 ${
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

      {/* Mobile Sidebar Drawer — only mount children when open to avoid duplicate BusinessSwitcher/Link prefetches */}
      {mobileOpen && (
        <aside
          className="fixed inset-y-0 start-0 z-50 flex w-72 flex-col border-r rtl:border-r-0 rtl:border-l border-gray-200 dark:border-gray-800/60 bg-gray-50 dark:bg-[#080c18] transition-transform duration-300 ease-in-out lg:hidden translate-x-0"
        >
          {/* Close button */}
          <button
            onClick={() => setMobileOpen(false)}
            aria-label="Close sidebar"
            className="absolute top-4 end-4 z-20 flex h-8 w-8 items-center justify-center rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
          {sidebarContent}
        </aside>
      )}
    </>
  );
}
