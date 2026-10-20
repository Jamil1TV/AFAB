"use client";

import React, { useState, useRef, useEffect, useMemo } from "react";
import { Link, useRouter } from "@/i18n/routing";
import { useLocale } from "next-intl";
import {
  Building2,
  Plus,
  Check,
  Crown,
  Lock,
  Sparkles,
  Settings,
  ChevronsUpDown,
  CreditCard,
  X,
  ArrowRight,
  ShieldCheck,
  Briefcase,
  AlertCircle
} from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export interface BusinessItem {
  id: string;
  name: string;
  currency: string;
  plan: string;
  isActive: boolean;
  country?: string;
}

interface BusinessSwitcherProps {
  collapsed: boolean;
  profile: any;
}

export function BusinessSwitcher({ collapsed, profile }: BusinessSwitcherProps) {
  const locale = useLocale();
  const isArabic = locale === "ar";
  const router = useRouter();

  const [isOpen, setIsOpen] = useState(false);
  const [isUpgradeModalOpen, setIsUpgradeModalOpen] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [newBusinessName, setNewBusinessName] = useState("");
  const [newBusinessCurrency, setNewBusinessCurrency] = useState("USD");
  const switcherRef = useRef<HTMLDivElement>(null);

  // Active plan (defaults to FREE)
  const planType = (profile?.planType || "FREE PLAN").toUpperCase();
  const isFreePlan = planType.includes("FREE");

  // Multi-business storage with primary business default
  const primaryBusinessName = profile?.businessName || profile?.workspaceName || "NexusDev";

  const [businesses, setBusinesses] = useState<BusinessItem[]>(() => {
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("afab_user_businesses");
        if (stored) {
          const parsed = JSON.parse(stored);
          if (Array.isArray(parsed) && parsed.length > 0) return parsed;
        }
      } catch (e) {
        // fallback
      }
    }
    return [
      {
        id: "primary",
        name: primaryBusinessName,
        currency: "USD",
        plan: planType,
        isActive: true,
      },
    ];
  });

  // Keep primary business name synchronized with profile
  useEffect(() => {
    if (primaryBusinessName) {
      setBusinesses((prev) => {
        const updated = prev.map((b) =>
          b.id === "primary" ? { ...b, name: primaryBusinessName, plan: planType } : b
        );
        return updated;
      });
    }
  }, [primaryBusinessName, planType]);

  const activeBusiness = useMemo(() => {
    return businesses.find((b) => b.isActive) || businesses[0];
  }, [businesses]);

  // Click outside to close switcher popover
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (switcherRef.current && !switcherRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isOpen]);

  const handleSelectBusiness = (id: string) => {
    setBusinesses((prev) => {
      const updated = prev.map((b) => ({
        ...b,
        isActive: b.id === id,
      }));
      if (typeof window !== "undefined") {
        localStorage.setItem("afab_user_businesses", JSON.stringify(updated));
      }
      return updated;
    });
    setIsOpen(false);
  };

  const handleAddBusinessClick = () => {
    setIsOpen(false);
    if (isFreePlan) {
      // Free plan limit reached: prompt upgrade
      setIsUpgradeModalOpen(true);
    } else {
      // Pro / Plus plan: allow creating new business
      setIsCreateModalOpen(true);
    }
  };

  const handleCreateBusiness = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBusinessName.trim()) return;

    const newId = `biz_${Date.now()}`;
    const newBiz: BusinessItem = {
      id: newId,
      name: newBusinessName.trim(),
      currency: newBusinessCurrency,
      plan: planType,
      isActive: true,
    };

    setBusinesses((prev) => {
      const updated = prev.map((b) => ({ ...b, isActive: false })).concat(newBiz);
      if (typeof window !== "undefined") {
        localStorage.setItem("afab_user_businesses", JSON.stringify(updated));
      }
      return updated;
    });

    setNewBusinessName("");
    setIsCreateModalOpen(false);
  };

  return (
    <div className="relative w-full" ref={switcherRef}>
      {/* ── Brand Button Trigger ── */}
      <div
        onClick={() => setIsOpen(!isOpen)}
        role="button"
        tabIndex={0}
        aria-expanded={isOpen}
        aria-label="Workspace & Business Selector"
        className={`flex w-full items-center ${
          collapsed ? "justify-center p-1.5" : "justify-between p-2"
        } rounded-xl hover:bg-gray-100 dark:hover:bg-white/[0.06] transition-all cursor-pointer group select-none border border-transparent hover:border-purple-200 dark:hover:border-purple-500/20`}
      >
        <div className={`flex items-center ${collapsed ? "justify-center" : "gap-2.5"} overflow-hidden min-w-0`}>
          {/* Logo / Business Icon */}
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#6c4cf5] to-[#8b5cf6] text-white shadow-md shadow-purple-500/25 group-hover:scale-105 transition-transform">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" className="currentColor">
              <path d="M12 2L2 12L12 22L22 12L12 2Z" fill="currentColor" opacity="0.3" />
              <path d="M12 7L7 12L12 17L17 12L12 7Z" fill="currentColor" />
            </svg>
          </div>

          {!collapsed && (
            <div className="flex flex-col overflow-hidden min-w-0 text-start">
              <div className="flex items-center gap-1.5">
                <span className="truncate text-sm font-bold text-gray-900 dark:text-white group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors">
                  {activeBusiness.name}
                </span>
              </div>
              <span className="truncate text-[10px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                {activeBusiness.plan}
              </span>
            </div>
          )}
        </div>

        {!collapsed && (
          <ChevronsUpDown
            className={`h-4 w-4 text-gray-400 group-hover:text-purple-500 shrink-0 ms-1 transition-transform duration-200 ${
              isOpen ? "rotate-180 text-purple-600 dark:text-purple-400" : ""
            }`}
          />
        )}
      </div>

      {/* ── Dropdown Switcher Popover ── */}
      {isOpen && (
        <div
          className={`absolute z-50 top-full mt-2 ${
            collapsed ? "start-full ms-2 -top-1 w-64" : "start-0 end-0 w-full"
          } rounded-2xl bg-white dark:bg-[#0e1326] border border-gray-200 dark:border-[#232b45] p-2 shadow-2xl shadow-purple-900/10 dark:shadow-black/80 backdrop-blur-xl animate-in fade-in zoom-in-95 duration-150`}
        >
          {/* Header & Plan Limit Status */}
          <div className="px-2.5 py-1.5 border-b border-gray-100 dark:border-gray-800/80 flex items-center justify-between gap-2">
            <p className="text-[10px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-400 truncate">
              {isArabic ? "مساحات العمل" : "Workspaces"}
            </p>
            <span
              className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold shrink-0 ${
                isFreePlan
                  ? "bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20"
                  : "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
              }`}
            >
              {isFreePlan ? (
                <>
                  <Lock className="w-2.5 h-2.5 shrink-0" />
                  <span>1 / 1 {isArabic ? "مجاني" : "Free"}</span>
                </>
              ) : (
                <>
                  <Crown className="w-2.5 h-2.5 shrink-0" />
                  <span>{businesses.length} {isArabic ? "نشطة" : "Active"}</span>
                </>
              )}
            </span>
          </div>

          {/* Businesses List */}
          <div className="py-1.5 space-y-1 max-h-56 overflow-y-auto custom-scrollbar">
            {businesses.map((biz) => {
              const isSelected = biz.isActive;
              return (
                <div
                  key={biz.id}
                  onClick={() => handleSelectBusiness(biz.id)}
                  role="button"
                  tabIndex={0}
                  className={`flex items-center justify-between p-2 rounded-xl text-start cursor-pointer transition-all ${
                    isSelected
                      ? "bg-purple-50 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-800/60"
                      : "hover:bg-gray-50 dark:hover:bg-white/[0.04] border border-transparent"
                  }`}
                >
                  <div className="flex items-center gap-2.5 min-w-0 flex-1">
                    <div
                      className={`h-7 w-7 rounded-lg flex items-center justify-center shrink-0 ${
                        isSelected
                          ? "bg-purple-600 text-white shadow-sm shadow-purple-500/30"
                          : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300"
                      }`}
                    >
                      <Building2 className="w-3.5 h-3.5" />
                    </div>
                    <div className="truncate min-w-0 flex-1">
                      <p className="text-xs font-bold text-gray-900 dark:text-white truncate">
                        {biz.name}
                      </p>
                      <p className="text-[10px] text-gray-500 dark:text-gray-400 truncate">
                        {biz.currency} • {biz.plan}
                      </p>
                    </div>
                  </div>
                  {isSelected && (
                    <div className="h-4 w-4 rounded-full bg-purple-600 text-white flex items-center justify-center shrink-0 ms-1.5">
                      <Check className="w-2.5 h-2.5" />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Add Business Action Button */}
          <div className="pt-1.5 border-t border-gray-100 dark:border-gray-800/80">
            <button
              type="button"
              onClick={handleAddBusinessClick}
              className="flex w-full items-center justify-between p-2 rounded-xl text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-purple-50 dark:hover:bg-purple-950/30 hover:text-purple-600 dark:hover:text-purple-400 transition-colors group cursor-pointer"
            >
              <div className="flex items-center gap-2 min-w-0">
                <div className="h-6 w-6 rounded-lg border border-dashed border-gray-300 dark:border-gray-700 flex items-center justify-center group-hover:border-purple-500 text-gray-400 group-hover:text-purple-500 transition-colors shrink-0">
                  <Plus className="w-3.5 h-3.5" />
                </div>
                <span className="truncate">{isArabic ? "إضافة عمل جديد" : "Add Business"}</span>
              </div>
              {isFreePlan ? (
                <span className="flex items-center gap-1 text-[10px] font-bold text-purple-600 dark:text-purple-400 bg-purple-500/10 px-1.5 py-0.5 rounded-full border border-purple-500/20 shrink-0 ms-1.5">
                  <Crown className="w-2.5 h-2.5 shrink-0" />
                  PRO
                </span>
              ) : (
                <Plus className="w-3.5 h-3.5 text-gray-400 group-hover:text-purple-500 shrink-0" />
              )}
            </button>
          </div>

          {/* Quick Management Shortcuts */}
          <div className="pt-1 mt-1 border-t border-gray-100 dark:border-gray-800/80 space-y-0.5">
            <Link
              href="/dashboard/settings"
              onClick={() => setIsOpen(false)}
              className="flex w-full items-center gap-2 px-2.5 py-1.5 text-xs text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-white/[0.04] rounded-lg transition-colors cursor-pointer"
            >
              <Settings className="w-3.5 h-3.5 shrink-0" />
              <span className="truncate">{isArabic ? "إعدادات الشركة" : "Business Settings"}</span>
            </Link>

            <Link
              href="/dashboard/plans"
              onClick={() => setIsOpen(false)}
              className="flex w-full items-center justify-between px-2.5 py-1.5 text-xs text-purple-600 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-950/30 rounded-lg transition-colors cursor-pointer font-medium"
            >
              <span className="flex items-center gap-2 truncate">
                <CreditCard className="w-3.5 h-3.5 shrink-0" />
                <span className="truncate">{isArabic ? "الترقية والاشتراكات" : "Plans & Upgrades"}</span>
              </span>
              <ArrowRight className="w-3 h-3 rtl:rotate-180 shrink-0 ms-1" />
            </Link>
          </div>
        </div>
      )}

      {/* ── Free Plan Limit / Upgrade Dialog ── */}
      <Dialog open={isUpgradeModalOpen} onOpenChange={setIsUpgradeModalOpen}>
        <DialogContent className="max-w-md p-6 bg-white dark:bg-[#0c1024] border border-gray-200 dark:border-purple-500/30 shadow-2xl rounded-2xl">
          <DialogHeader className="text-start space-y-3">
            <div className="h-12 w-12 rounded-2xl bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center text-white shadow-lg shadow-purple-500/30">
              <Crown className="w-6 h-6" />
            </div>
            <div>
              <DialogTitle className="text-xl font-black text-gray-900 dark:text-white">
                {isArabic ? "افتح إمكانية إدارة شركات متعددة" : "Manage Multiple Businesses with Pro"}
              </DialogTitle>
              <DialogDescription className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {isArabic
                  ? "أنت حالياً على الخطة المجانية، والتي تدعم شركة واحدة فقط (1/1). للترقية وإضافة شركات إضافية مع فواتير وتقارير موحدة، انتقل إلى خطة برو."
                  : "You are currently on the Free Plan, which supports 1 business workspace (1/1 used). Upgrade to Pro to manage multiple entities with consolidated reporting."}
              </DialogDescription>
            </div>
          </DialogHeader>

          {/* Features Highlights */}
          <div className="my-4 p-4 rounded-xl bg-purple-50/50 dark:bg-purple-950/20 border border-purple-200/60 dark:border-purple-800/40 space-y-2.5">
            <p className="text-xs font-bold text-purple-900 dark:text-purple-300 uppercase tracking-wider">
              {isArabic ? "ميزات الخطة المدفوعة:" : "What you get with Pro:"}
            </p>
            <div className="space-y-2 text-xs text-gray-700 dark:text-gray-300">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-purple-600 dark:text-purple-400 shrink-0" />
                <span>{isArabic ? "شركات ومساحات عمل متعددة وغير محدودة" : "Multiple independent businesses & workspaces"}</span>
              </div>
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-purple-600 dark:text-purple-400 shrink-0" />
                <span>{isArabic ? "محفظة مالية موحدة وتحويل مباشر للعملات" : "Consolidated multi-currency portfolio analytics"}</span>
              </div>
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-purple-600 dark:text-purple-400 shrink-0" />
                <span>{isArabic ? "مساعد الذكاء الاصطناعي بلا حدود للتقارير والفواتير" : "Unlimited AI Assistant queries & automated insights"}</span>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-3 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsUpgradeModalOpen(false)}
              className="border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300"
            >
              {isArabic ? "لاحقاً" : "Maybe Later"}
            </Button>
            <Button
              type="button"
              onClick={() => {
                setIsUpgradeModalOpen(false);
                router.push("/dashboard/plans");
              }}
              className="bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-bold shadow-md shadow-purple-500/25"
            >
              <Crown className="w-4 h-4 ltr:mr-1.5 rtl:ml-1.5" />
              {isArabic ? "ترقية إلى برو الآن" : "Upgrade to Pro"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* ── Create New Business Modal (For Pro Plan / Upgraded Users) ── */}
      <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
        <DialogContent className="max-w-md p-6 bg-white dark:bg-[#0c1024] border border-gray-200 dark:border-purple-500/30 shadow-2xl rounded-2xl">
          <DialogHeader className="text-start space-y-2">
            <div className="h-10 w-10 rounded-xl bg-purple-600/10 text-purple-600 flex items-center justify-center">
              <Building2 className="w-5 h-5" />
            </div>
            <div>
              <DialogTitle className="text-lg font-bold text-gray-900 dark:text-white">
                {isArabic ? "إنشاء شركة / مساحة عمل جديدة" : "Create New Business Workspace"}
              </DialogTitle>
              <DialogDescription className="text-xs text-gray-500 dark:text-gray-400">
                {isArabic
                  ? "أدخل اسم الشركة وعملتها الأساسية لإعداد مساحة العمل الجديدة."
                  : "Enter business details to launch an independent workspace."}
              </DialogDescription>
            </div>
          </DialogHeader>

          <form onSubmit={handleCreateBusiness} className="space-y-4 my-2">
            <div className="space-y-1.5">
              <Label className="text-xs font-bold text-gray-700 dark:text-gray-300">
                {isArabic ? "اسم الشركة" : "Business Name"}
              </Label>
              <Input
                required
                value={newBusinessName}
                onChange={(e) => setNewBusinessName(e.target.value)}
                placeholder="e.g. Acme Global Ltd."
                className="border-gray-200 dark:border-gray-700 dark:bg-gray-900/60"
              />
            </div>

            <div className="space-y-1.5">
              <Label className="text-xs font-bold text-gray-700 dark:text-gray-300">
                {isArabic ? "العملة الأساسية" : "Base Currency"}
              </Label>
              <select
                value={newBusinessCurrency}
                onChange={(e) => setNewBusinessCurrency(e.target.value)}
                className="w-full rounded-md border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900/60 px-3 py-2 text-xs font-semibold text-gray-900 dark:text-white outline-none focus:border-purple-500"
              >
                <option value="USD">USD ($) — US Dollar</option>
                <option value="EUR">EUR (€) — Euro</option>
                <option value="AED">AED (د.إ) — UAE Dirham</option>
                <option value="SAR">SAR (﷼) — Saudi Riyal</option>
                <option value="QAR">QAR (﷼) — Qatari Riyal</option>
                <option value="GBP">GBP (£) — British Pound</option>
                <option value="TND">TND (DT) — Tunisian Dinar</option>
              </select>
            </div>

            <div className="flex items-center justify-end gap-3 pt-3">
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsCreateModalOpen(false)}
                className="border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300"
              >
                {isArabic ? "إلغاء" : "Cancel"}
              </Button>
              <Button
                type="submit"
                className="bg-purple-600 hover:bg-purple-700 text-white font-bold"
              >
                {isArabic ? "إنشاء الشركة" : "Create Business"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
