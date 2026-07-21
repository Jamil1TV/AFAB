"use client";

import { useState, useEffect } from "react";
import { UserService } from "@/lib/api/dashboard";
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
  LogOut,
  User as UserIcon,
  ChevronsUpDown
} from "lucide-react";

import { useTranslations } from "next-intl";

interface UserProfile {
  id: number;
  name: string;
  email: string;
  workspaceName: string;
  planType: string;
}

type NavItem = {
  name: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
};

export function Sidebar() {
  const tSidebar = useTranslations("Dashboard.sidebar");
  const pathname = usePathname();
  const [profile, setProfile] = useState<UserProfile | null>(null);

  useEffect(() => {
    UserService.getProfile().then(setProfile).catch(console.error);
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
      const isActive = pathname === item.href;
      
      return (
        <Link
          key={item.name}
          href={item.href}
          className={`group flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 ${
            isActive 
              ? "bg-primary/10 text-primary" 
              : "text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] dark:hover:text-gray-200"
          }`}
        >
          <div className="flex items-center gap-3">
            <item.icon className={`h-4.5 w-4.5 ${isActive ? "text-primary" : "text-gray-400 group-hover:text-gray-500 dark:group-hover:text-gray-300"}`} />
            {item.name}
          </div>
          {item.badge && (
            <span className="rounded-full bg-primary px-2 py-0.5 text-[10px] font-bold text-primary-foreground shadow-sm">
              {item.badge}
            </span>
          )}
        </Link>
      );
    });
  };

  return (
    <aside className="hidden w-64 flex-col border-r border-gray-200 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18] lg:flex sticky top-0 h-screen">
      {/* ── Brand / Workspace Selector ── */}
      <div className="flex h-16 shrink-0 items-center px-4 border-b border-gray-200 dark:border-gray-800/60">
        <div className="flex w-full items-center justify-between rounded-xl hover:bg-gray-100 dark:hover:bg-white/[0.05] p-1.5 transition-colors cursor-pointer">
          <div className="flex items-center gap-2.5 overflow-hidden">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-primary to-primary/80 text-primary-foreground shadow-md shadow-primary/20">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" className="currentColor">
                <path d="M12 2L2 12L12 22L22 12L12 2Z" fill="currentColor" opacity="0.3" />
                <path d="M12 7L7 12L12 17L17 12L12 7Z" fill="currentColor" />
              </svg>
            </div>
            <div className="flex flex-col overflow-hidden">
              <span className="truncate text-sm font-bold text-gray-900 dark:text-white">{profile?.workspaceName || "Acme Corp"}</span>
              <span className="truncate text-[10px] font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{profile?.planType || tSidebar("freePlan")}</span>
            </div>
          </div>
          <ChevronsUpDown className="h-4 w-4 text-gray-400" />
        </div>
      </div>

      {/* ── Navigation ── */}
      <div className="flex-1 overflow-y-auto px-3 py-4 custom-scrollbar">
        <nav className="space-y-1">
          {renderNavItems(mainNavItems)}
        </nav>

        <div className="mt-8 mb-2 px-3">
          <h4 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500">
            {tSidebar("workspace")}
          </h4>
        </div>
        
        <nav className="space-y-1">
          {renderNavItems(workspaceItems)}
        </nav>
      </div>

      {/* ── Upgrade Card ── */}
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

      {/* ── User Profile & Settings ── */}
      <div className="border-t border-gray-200 dark:border-gray-800/60 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3 cursor-pointer group">
            <div className="relative h-9 w-9 rounded-full border border-gray-200 dark:border-gray-700/50 bg-white dark:bg-gray-800 overflow-hidden shadow-sm">
              <img src="https://i.pravatar.cc/150?u=a042581f4e29026024d" alt="User" className="h-full w-full object-cover" />
            </div>
            <div className="flex flex-col">
              <span className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-primary transition-colors">{profile?.name || "Ahmed J."}</span>
              <span className="text-xs text-gray-500">{tSidebar("owner")}</span>
            </div>
          </div>
        </div>
      </div>
    </aside>
  );
}
