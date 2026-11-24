"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import {
  Bell,
  Menu,
  Globe,
  Sparkles,
  CheckCheck,
  AlertTriangle,
  CheckCircle2,
  Info,
  AlertCircle,
} from "lucide-react";
import { ThemeToggle } from "@/components/theme-toggle";
import { useLocale, useTranslations } from "next-intl";
import { useRouter, usePathname, Link } from "@/i18n/routing";
import { useSidebar } from "@/components/dashboard/Sidebar";
import { NotificationService, NotificationItem } from "@/lib/api/notifications";
import { SubscriptionService } from "@/lib/api/subscription";
import { AuthStore } from "@/lib/auth-store";

export function DashboardHeader() {
  const locale = useLocale();
  const isAr = locale === "ar";
  const tLang = useTranslations("Common.language");
  const tHeader = useTranslations("Dashboard.header");
  const router = useRouter();
  const pathname = usePathname();
  const { setMobileOpen } = useSidebar();

  const [notifOpen, setNotifOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [currentPlanSlug, setCurrentPlanSlug] = useState<string | null>(null);
  const notifRef = useRef<HTMLDivElement>(null);

  const loadSubscriptionPlan = useCallback(async (force: boolean = false) => {
    const cachedTier = AuthStore.getUser()?.planTier;
    if (cachedTier) {
      setCurrentPlanSlug(cachedTier.toLowerCase());
    }
    try {
      const sub = await SubscriptionService.getMySubscription(force);
      const slug = sub?.planSlug?.toLowerCase() || "free";
      setCurrentPlanSlug(slug);
      AuthStore.updateUser({ planTier: slug.toUpperCase() });
    } catch {
      if (!cachedTier) {
        setCurrentPlanSlug("free");
      }
    }
  }, []);

  const loadNotifications = useCallback(async (force: boolean = false) => {
    try {
      const res = await NotificationService.list(force);
      if (res) {
        setUnreadCount(res.unreadCount ?? 0);
        setNotifications(res.notifications ?? []);
      }
    } catch {
      // Non-blocking notification fetch
    }
  }, []);

  useEffect(() => {
    loadNotifications(false);
    loadSubscriptionPlan(false);
  }, [loadNotifications, loadSubscriptionPlan]);

  useEffect(() => {
    const handleSubUpdated = () => {
      loadNotifications(true);
      loadSubscriptionPlan(true);
    };
    const handleProfileUpdated = (event: Event) => {
      const detail = (event as CustomEvent)?.detail;
      const nextTier = detail?.planTier || AuthStore.getUser()?.planTier;
      if (nextTier) {
        setCurrentPlanSlug(String(nextTier).toLowerCase());
      }
    };
    window.addEventListener("afab:subscription-updated", handleSubUpdated);
    window.addEventListener("afab_profile_updated", handleProfileUpdated);
    return () => {
      window.removeEventListener("afab:subscription-updated", handleSubUpdated);
      window.removeEventListener("afab_profile_updated", handleProfileUpdated);
    };
  }, [loadNotifications, loadSubscriptionPlan]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setNotifOpen(false);
      }
    }
    if (notifOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [notifOpen]);

  const handleMarkAsRead = async (item: NotificationItem) => {
    try {
      if (!item.read) {
        const res = await NotificationService.markAsRead(item.id);
        setUnreadCount(res.unreadCount ?? 0);
        setNotifications(res.notifications ?? []);
      }
      if (item.actionUrl) {
        setNotifOpen(false);
        router.push(item.actionUrl);
      }
    } catch {
      // Ignore error
    }
  };

  const handleMarkAllRead = async () => {
    try {
      const res = await NotificationService.markAllAsRead();
      setUnreadCount(res.unreadCount ?? 0);
      setNotifications(res.notifications ?? []);
    } catch {
      // Ignore error
    }
  };

  const toggleLanguage = () => {
    const nextLocale = locale === "en" ? "ar" : "en";
    router.replace(pathname, { locale: nextLocale });
  };

  const renderSeverityIcon = (severity: string) => {
    switch (severity?.toUpperCase()) {
      case "ERROR":
        return <AlertCircle className="w-4 h-4 text-red-500 shrink-0 mt-0.5" />;
      case "WARNING":
        return <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />;
      case "SUCCESS":
        return <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />;
      default:
        return <Info className="w-4 h-4 text-[var(--primary)] shrink-0 mt-0.5" />;
    }
  };

  const showUpgradeToPro = currentPlanSlug === "free" || currentPlanSlug === "plus";

  return (
    <header className="z-30 flex h-16 shrink-0 items-center justify-between gap-4 border-b border-gray-200 dark:border-gray-800/60 bg-white/80 dark:bg-[#080c18]/80 px-4 backdrop-blur-md sm:gap-6 sm:px-6">
      {/* Mobile menu trigger */}
      <button
        onClick={() => setMobileOpen(true)}
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] lg:hidden"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* Right side actions */}
      <div className="ms-auto flex items-center gap-2 sm:gap-3 shrink-0">
        {/* Theme Toggle */}
        <ThemeToggle />

        {/* Language Switcher */}
        <button
          onClick={toggleLanguage}
          className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] px-3.5 py-1.5 text-xs sm:text-sm font-medium text-gray-600 dark:text-gray-300 transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.06]"
        >
          <Globe className="h-4 w-4" />
          <span className="hidden sm:inline-block">{tLang("switchTo")}</span>
        </button>

        {/* Real Persisted Notifications Dropdown */}
        <div className="relative" ref={notifRef}>
          <button
            type="button"
            aria-label="Notifications"
            onClick={() => {
              const next = !notifOpen;
              setNotifOpen(next);
              if (next) loadNotifications(true);
            }}
            className="relative flex h-9 w-9 items-center justify-center rounded-full text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/[0.05] transition-colors"
          >
            <Bell className="h-5 w-5" />
            {unreadCount > 0 && (
              <span className="absolute -top-0.5 -end-0.5 flex h-4 min-w-4 px-1 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white shadow-sm">
                {unreadCount > 9 ? "9+" : unreadCount}
              </span>
            )}
          </button>

          {notifOpen && (
            <div className="absolute end-0 mt-2 w-80 sm:w-96 rounded-2xl bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl p-3 z-50">
              <div className="flex items-center justify-between px-1 pb-2.5 border-b border-gray-100 dark:border-gray-800">
                <span className="text-xs font-bold text-gray-900 dark:text-white">
                  {isAr ? "الإشعارات" : "Notifications"}
                </span>
                {unreadCount > 0 && (
                  <button
                    type="button"
                    onClick={handleMarkAllRead}
                    className="inline-flex items-center gap-1 text-[11px] font-semibold text-[var(--primary-hover)] dark:text-[var(--primary)] hover:underline"
                  >
                    <CheckCheck className="w-3.5 h-3.5" />
                    <span>{isAr ? "تحديد الكل كمقروء" : "Mark all read"}</span>
                  </button>
                )}
              </div>

              <div className="divide-y divide-gray-100 dark:divide-gray-800/60 max-h-80 overflow-y-auto custom-scrollbar">
                {notifications.length === 0 ? (
                  <div className="py-8 text-center text-xs text-gray-400 dark:text-gray-500">
                    {isAr ? "لا توجد إشعارات حالياً" : "No notifications yet"}
                  </div>
                ) : (
                  notifications.map((n) => (
                    <div
                      key={n.id}
                      onClick={() => handleMarkAsRead(n)}
                      role="button"
                      tabIndex={0}
                      className={`p-2.5 rounded-xl transition-colors cursor-pointer flex items-start gap-2.5 ${
                        n.read
                          ? "opacity-75 hover:bg-gray-50 dark:hover:bg-white/[0.03]"
                          : "bg-[var(--primary)]/5 dark:bg-[var(--primary)]/10 hover:bg-[var(--primary)]/15"
                      }`}
                    >
                      {renderSeverityIcon(n.severity)}
                      <div className="min-w-0 flex-1 text-start">
                        <div className="flex items-center justify-between gap-2">
                          <p className="text-xs font-bold text-gray-900 dark:text-white truncate">
                            {n.title}
                          </p>
                          {!n.read && (
                            <span className="h-2 w-2 rounded-full bg-[var(--primary)] shrink-0" />
                          )}
                        </div>
                        <p className="text-[11px] text-gray-600 dark:text-gray-400 leading-snug mt-0.5">
                          {n.message}
                        </p>
                        <p className="text-[10px] text-gray-400 dark:text-gray-500 mt-1">
                          {new Date(n.createdAt).toLocaleDateString(
                            isAr ? "ar" : "en-US",
                            {
                              month: "short",
                              day: "numeric",
                              hour: "2-digit",
                              minute: "2-digit",
                            }
                          )}
                        </p>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>

        {/* Upgrade to Pro Button (shown for Free and Plus plans; hidden for Pro) */}
        {showUpgradeToPro && (
          <Link
            href={
              currentPlanSlug === "plus"
                ? "/dashboard/settings/subscription?changePlan=true"
                : "/dashboard/settings/subscription"
            }
            className="flex items-center gap-1.5 rounded-xl bg-gradient-to-r from-[var(--primary)] to-[var(--primary-hover)] hover:opacity-95 px-3.5 py-2 text-xs sm:text-sm font-semibold text-white shadow-md shadow-[var(--glow-color)] transition-all hover:scale-[1.02] active:scale-[0.98]"
          >
            <Sparkles className="h-3.5 w-3.5" />
            <span>
              {isAr
                ? "الترقية إلى برو"
                : tHeader("upgradeToPro") || "Upgrade to Pro"}
            </span>
          </Link>
        )}
      </div>
    </header>
  );
}
