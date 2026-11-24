"use client";

import React, { useState, useRef, useEffect, useMemo, useCallback } from "react";
import { Link, useRouter } from "@/i18n/routing";
import { useLocale } from "next-intl";
import { BusinessService } from "@/lib/api/business";
import { SubscriptionService } from "@/lib/api/subscription";
import { AuthStore } from "@/lib/auth-store";
import {
  Building2,
  Plus,
  Check,
  Crown,
  Zap,
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
  editable: boolean;
  primary: boolean;
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
  const [lockedBusinessTarget, setLockedBusinessTarget] = useState<BusinessItem | null>(null);
  const [currentPlanSlug, setCurrentPlanSlug] = useState<string | null>(null);
  const [newBusinessName, setNewBusinessName] = useState("");
  const [newBusinessCurrency, setNewBusinessCurrency] = useState("USD");
  const switcherRef = useRef<HTMLDivElement>(null);

  // Active plan & business limits (FREE: 1, PLUS: 3, PRO: 5)
  const planTier = (
    currentPlanSlug ||
    profile?.planTier ||
    profile?.planType ||
    "FREE"
  ).toUpperCase();
  const maxBusinesses = planTier.includes("PRO") ? 5 : planTier.includes("PLUS") ? 3 : 1;
  const isFreePlan = planTier.includes("FREE");
  const resolvedBadgeSlug =
    currentPlanSlug ||
    (profile?.planTier || profile?.planType || "").toLowerCase() ||
    null;
  const showPlanBadge = resolvedBadgeSlug === "plus" || resolvedBadgeSlug === "pro";
  const isProPlan = resolvedBadgeSlug === "pro";

  // Multi-business storage with primary business default
  const primaryBusinessName = profile?.businessName || profile?.workspaceName || "My Business";

  const [businesses, setBusinesses] = useState<BusinessItem[]>([
    {
      id: "primary",
      name: primaryBusinessName,
      currency: "USD",
      plan: planTier,
      isActive: true,
      editable: true,
      primary: true,
    },
  ]);

  const fetchBusinesses = useCallback(async () => {
    try {
      const list = await BusinessService.list();
      if (list && list.length > 0) {
        const activeFromApi = list.find((b) => Boolean(b.active) && b.editable !== false);
        const currentStoredId = AuthStore.getActiveBusinessId();
        if (currentStoredId) {
          const storedBiz = list.find((b) => b.id === currentStoredId);
          if (storedBiz && storedBiz.editable === false) {
            const unlocked = activeFromApi || list.find((b) => b.editable !== false);
            AuthStore.setActiveBusinessId(unlocked ? unlocked.id : null);
          }
        } else if (activeFromApi) {
          AuthStore.setActiveBusinessId(activeFromApi.id);
        }

        setBusinesses(
          list.map((b) => ({
            id: b.id,
            name: b.name,
            currency: b.currency,
            plan: b.userRole || planTier,
            isActive: Boolean(b.active),
            editable: b.editable !== false,
            primary: Boolean(b.primary),
            country: b.country,
          }))
        );
      }
    } catch (err) {
      console.error("Failed to load businesses:", err);
    }
  }, [planTier]);

  const fetchPlan = useCallback(async () => {
    const cachedTier = AuthStore.getUser()?.planTier;
    if (cachedTier) {
      setCurrentPlanSlug(cachedTier.toLowerCase());
    }
    try {
      const sub = await SubscriptionService.getMySubscription();
      const slug = sub?.planSlug?.toLowerCase() || "free";
      setCurrentPlanSlug(slug);
      AuthStore.updateUser({ planTier: slug.toUpperCase() });
    } catch {
      if (!cachedTier) {
        setCurrentPlanSlug((profile?.planTier || profile?.planType || "free").toLowerCase());
      }
    }
  }, [profile?.planTier, profile?.planType]);

  useEffect(() => {
    fetchBusinesses();
    fetchPlan();
    const handleSubUpdated = () => {
      fetchBusinesses();
      fetchPlan();
    };
    const handleProfileUpdated = () => {
      fetchPlan();
    };
    window.addEventListener("afab:subscription-updated", handleSubUpdated);
    window.addEventListener("afab_profile_updated", handleProfileUpdated);
    return () => {
      window.removeEventListener("afab:subscription-updated", handleSubUpdated);
      window.removeEventListener("afab_profile_updated", handleProfileUpdated);
    };
  }, [fetchBusinesses, fetchPlan]);

  const editableBusinessesCount = useMemo(
    () => businesses.filter((b) => b.editable).length,
    [businesses]
  );
  const isAtLimit = editableBusinessesCount >= maxBusinesses;

  const activeBusiness = useMemo(() => {
    return (
      businesses.find((b) => b.isActive && b.editable) ||
      businesses.find((b) => b.editable) ||
      businesses[0]
    );
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

  const handleSelectBusiness = async (biz: BusinessItem) => {
    if (!biz.editable) {
      setIsOpen(false);
      setLockedBusinessTarget(biz);
      return;
    }
    try {
      await BusinessService.switchActive(biz.id);
      AuthStore.setActiveBusinessId(biz.id);
      setIsOpen(false);
      window.location.reload();
    } catch (err) {
      console.error("Failed to switch business:", err);
    }
  };

  const handleAddBusinessClick = () => {
    setIsOpen(false);
    if (isAtLimit) {
      setIsUpgradeModalOpen(true);
    } else {
      setIsCreateModalOpen(true);
    }
  };

  const handleCreateBusiness = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBusinessName.trim()) return;

    try {
      const created = await BusinessService.create({
        name: newBusinessName.trim(),
        currency: newBusinessCurrency,
      });
      if (created?.id) {
        AuthStore.setActiveBusinessId(created.id);
      }
      setIsCreateModalOpen(false);
      setNewBusinessName("");
      window.location.reload();
    } catch (err) {
      console.error("Failed to create business:", err);
    }
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
        } rounded-xl hover:bg-gray-100 dark:hover:bg-white/[0.06] transition-all cursor-pointer group select-none border border-transparent hover:border-[var(--primary)]/30`}
      >
        <div className={`flex items-center ${collapsed ? "justify-center" : "gap-2.5"} overflow-hidden min-w-0`}>
          {/* Official AFAB Logo (Light & Dark variants) */}
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#050814] shadow-sm group-hover:scale-105 transition-transform overflow-hidden">
            <img
              src="/assets/afab-logo-light.png"
              alt="AFAB Logo"
              className="h-full w-full object-cover dark:hidden"
            />
            <img
              src="/assets/afab-logo-dark.png"
              alt="AFAB Logo Dark"
              className="h-full w-full object-cover hidden dark:block"
            />
          </div>

          {!collapsed && (
            <div className="flex flex-col overflow-hidden min-w-0 text-start">
              <div className="flex items-center gap-1.5 min-w-0">
                <span className="truncate text-sm font-bold text-gray-900 dark:text-white group-hover:text-[var(--primary)] dark:group-hover:text-[var(--primary)] transition-colors">
                  {activeBusiness.name}
                </span>
                {showPlanBadge && (
                  <span
                    className={`inline-flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-[9px] font-bold tracking-wide shrink-0 ${
                      isProPlan
                        ? "bg-gradient-to-r from-amber-500 to-orange-500 text-white shadow-sm shadow-amber-500/20"
                        : "bg-[var(--primary)] text-white shadow-sm shadow-[var(--primary)]/20"
                    }`}
                  >
                    {isProPlan ? (
                      <Crown className="h-2.5 w-2.5 fill-current" />
                    ) : (
                      <Zap className="h-2.5 w-2.5 fill-current" />
                    )}
                    <span>{isProPlan ? "Pro" : "Plus"}</span>
                  </span>
                )}
                {!activeBusiness.editable && (
                  <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-500/25 shrink-0">
                    <Lock className="w-2.5 h-2.5" />
                    {isArabic ? "مقفلة" : "Locked"}
                  </span>
                )}
              </div>
              <span className="truncate text-[10px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                {activeBusiness.plan}
              </span>
            </div>
          )}
        </div>

        {!collapsed && (
          <ChevronsUpDown
            className={`h-4 w-4 text-gray-400 group-hover:text-[var(--primary)] shrink-0 ms-1 transition-transform duration-200 ${
              isOpen ? "rotate-180 text-[var(--primary)] dark:text-[var(--primary)]" : ""
            }`}
          />
        )}
      </div>

      {/* ── Dropdown Switcher Popover ── */}
      {isOpen && (
        <div
          className={`absolute z-50 top-full mt-2 ${
            collapsed ? "start-full ms-2 -top-1 w-64" : "start-0 end-0 w-full"
          } rounded-2xl bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 p-2 shadow-2xl shadow-black/40 backdrop-blur-xl animate-in fade-in zoom-in-95 duration-150`}
        >
          {/* Header & Plan Limit Status */}
          <div className="px-2.5 py-1.5 border-b border-gray-100 dark:border-gray-800/80 flex items-center justify-between gap-2">
            <p className="text-[10px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-400 truncate">
              {isArabic ? "مساحات العمل" : "Workspaces"}
            </p>
            <span
              className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold shrink-0 ${
                isAtLimit
                  ? "bg-[var(--primary)]/10 text-[var(--primary)] dark:text-[var(--primary)] border border-[var(--primary)]/20"
                  : "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
              }`}
            >
              {isAtLimit ? (
                <>
                  <Lock className="w-2.5 h-2.5 shrink-0" />
                  <span>{editableBusinessesCount} / {maxBusinesses} {isArabic ? "الحد الأقصى" : "Max"}</span>
                </>
              ) : (
                <>
                  <Crown className="w-2.5 h-2.5 shrink-0" />
                  <span>{editableBusinessesCount} / {maxBusinesses} {isArabic ? "نشطة" : "Active"}</span>
                </>
              )}
            </span>
          </div>

          {/* Businesses List */}
          <div className="py-1.5 space-y-1 max-h-56 overflow-y-auto custom-scrollbar">
            {businesses.map((biz) => {
              const isSelected = biz.isActive && biz.editable;
              const isLocked = !biz.editable;
              return (
                <div
                  key={biz.id}
                  onClick={() => handleSelectBusiness(biz)}
                  role="button"
                  tabIndex={0}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      handleSelectBusiness(biz);
                    }
                  }}
                  className={`flex items-center justify-between p-2 rounded-xl text-start cursor-pointer transition-all ${
                    isSelected
                      ? "bg-[var(--primary)]/10 border border-[var(--primary)]/30 shadow-sm"
                      : isLocked
                      ? "bg-amber-50/40 dark:bg-amber-500/[0.04] hover:bg-amber-50/80 dark:hover:bg-amber-500/10 border border-amber-500/15 opacity-85"
                      : "hover:bg-gray-50 dark:hover:bg-white/[0.04] border border-transparent"
                  }`}
                >
                  <div className="flex items-center gap-2.5 min-w-0 flex-1">
                    <div
                      className={`h-7 w-7 rounded-lg flex items-center justify-center shrink-0 ${
                        isSelected
                          ? "bg-[var(--primary)] text-white shadow-sm shadow-[var(--primary)]/30"
                          : isLocked
                          ? "bg-amber-500/10 text-amber-600 dark:text-amber-400"
                          : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300"
                      }`}
                    >
                      {isLocked ? <Lock className="w-3.5 h-3.5" /> : <Building2 className="w-3.5 h-3.5" />}
                    </div>
                    <div className="truncate min-w-0 flex-1">
                      <div className="flex items-center gap-1.5">
                        <p className="text-xs font-bold text-gray-900 dark:text-white truncate">
                          {biz.name}
                        </p>
                        {biz.editable ? (
                          <span className="px-1.5 py-0.2 rounded-full text-[9px] font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shrink-0">
                            {isArabic ? "نشطة" : "Active"}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-0.5 px-1.5 py-0.2 rounded-full text-[9px] font-bold bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20 shrink-0">
                            <Lock className="w-2 h-2" />
                            {isArabic ? "مقفلة" : "Locked"}
                          </span>
                        )}
                      </div>
                      <p className="text-[10px] text-gray-500 dark:text-gray-400 truncate">
                        {biz.currency} • {isLocked ? (isArabic ? "البيانات محفوظة" : "Data Saved") : biz.plan}
                      </p>
                    </div>
                  </div>
                  {isSelected && (
                    <div className="h-4 w-4 rounded-full bg-[var(--primary)] text-white flex items-center justify-center shrink-0 ms-1.5">
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
              className="flex w-full items-center justify-between p-2 rounded-xl text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-[var(--primary)]/10 dark:hover:bg-[var(--primary)]/10 hover:text-[var(--primary)] dark:hover:text-[var(--primary)] transition-colors group cursor-pointer"
            >
              <div className="flex items-center gap-2 min-w-0">
                <div className="h-6 w-6 rounded-lg border border-dashed border-gray-300 dark:border-gray-700 flex items-center justify-center group-hover:border-[var(--primary)] text-gray-400 group-hover:text-[var(--primary)] transition-colors shrink-0">
                  <Plus className="w-3.5 h-3.5" />
                </div>
                <span className="truncate">{isArabic ? "إضافة عمل جديد" : "Add Business"}</span>
              </div>
              {isAtLimit ? (
                <span className="flex items-center gap-1 text-[10px] font-bold text-[var(--primary)] dark:text-[var(--primary)] bg-[var(--primary)]/10 px-1.5 py-0.5 rounded-full border border-[var(--primary)]/20 shrink-0 ms-1.5">
                  <Crown className="w-2.5 h-2.5 shrink-0" />
                  UPGRADE
                </span>
              ) : (
                <Plus className="w-3.5 h-3.5 text-gray-400 group-hover:text-[var(--primary)] shrink-0" />
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
              href="/dashboard/settings/subscription"
              onClick={() => setIsOpen(false)}
              className="flex w-full items-center justify-between px-2.5 py-1.5 text-xs text-[var(--primary)] dark:text-[var(--primary)] hover:bg-[var(--primary)]/10 dark:hover:bg-[var(--primary)]/10 rounded-lg transition-colors cursor-pointer font-medium"
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
        <DialogContent className="max-w-md p-6 bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl rounded-3xl">
          <DialogHeader className="text-start space-y-3">
            <div className="h-12 w-12 rounded-2xl bg-gradient-to-br from-[var(--primary)] to-[var(--accent)] flex items-center justify-center text-white shadow-lg shadow-[var(--primary)]/30">
              <Crown className="w-6 h-6" />
            </div>
            <div>
              <DialogTitle className="text-xl font-bold text-gray-900 dark:text-white">
                {isArabic ? "حد الباقة الحالية للأعمال" : "Workspace Plan Limit Reached"}
              </DialogTitle>
              <DialogDescription className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {isArabic
                  ? `باقتك الحالية (${planTier}) تدعم حتى ${maxBusinesses} مساحة عمل (${businesses.length}/${maxBusinesses} مستخدمة). باقة Plus تدعم حتى 3 شركات، وباقة Pro تدعم حتى 5 شركات.`
                  : `Your current ${planTier} plan allows up to ${maxBusinesses} workspace(s) (${businesses.length}/${maxBusinesses} used). Upgrade to Plus for up to 3 businesses or Pro for up to 5 businesses.`}
              </DialogDescription>
            </div>
          </DialogHeader>

          {/* Features Highlights */}
          <div className="my-4 p-4 rounded-xl bg-[var(--primary)]/5 dark:bg-[var(--primary)]/10 border border-[var(--primary)]/20 space-y-2.5">
            <p className="text-xs font-bold text-[var(--primary)] dark:text-[var(--primary)] uppercase tracking-wider">
              {isArabic ? "ميزات الخطة المدفوعة:" : "What you get with Pro:"}
            </p>
            <div className="space-y-2 text-xs text-gray-700 dark:text-gray-300">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-[var(--primary)] dark:text-[var(--primary)] shrink-0" />
                <span>{isArabic ? "شركات ومساحات عمل متعددة وغير محدودة" : "Multiple independent businesses & workspaces"}</span>
              </div>
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-[var(--primary)] dark:text-[var(--primary)] shrink-0" />
                <span>{isArabic ? "محفظة مالية موحدة وتحويل مباشر للعملات" : "Consolidated multi-currency portfolio analytics"}</span>
              </div>
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-[var(--primary)] dark:text-[var(--primary)] shrink-0" />
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
                router.push("/dashboard/settings/subscription");
              }}
              className="afab-btn-primary font-bold shadow-md shadow-[var(--primary)]/25"
            >
              <Crown className="w-4 h-4 ltr:mr-1.5 rtl:ml-1.5" />
              {isArabic ? "ترقية إلى برو الآن" : "Upgrade to Pro"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* ── Create New Business Modal (For Pro Plan / Upgraded Users) ── */}
      <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
        <DialogContent className="max-w-md p-6 bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl rounded-3xl">
          <DialogHeader className="text-start space-y-2">
            <div className="h-10 w-10 rounded-xl bg-[var(--primary)]/10 text-[var(--primary)] flex items-center justify-center">
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
              <Label className="text-xs font-medium text-gray-700 dark:text-gray-300">
                {isArabic ? "اسم الشركة" : "Business Name"}
              </Label>
              <Input
                required
                value={newBusinessName}
                onChange={(e) => setNewBusinessName(e.target.value)}
                placeholder="e.g. Acme Global Ltd."
                className="rounded-xl border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18]"
              />
            </div>

            <div className="space-y-1.5">
              <Label className="text-xs font-medium text-gray-700 dark:text-gray-300">
                {isArabic ? "العملة الأساسية" : "Base Currency"}
              </Label>
              <select
                value={newBusinessCurrency}
                onChange={(e) => setNewBusinessCurrency(e.target.value)}
                className="afab-select w-full py-2.5 text-sm"
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
                className="rounded-xl border-gray-200 dark:border-gray-800 text-gray-700 dark:text-gray-300"
              >
                {isArabic ? "إلغاء" : "Cancel"}
              </Button>
              <Button
                type="submit"
                className="rounded-xl bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-bold shadow-lg shadow-[var(--primary)]/25"
              >
                {isArabic ? "إنشاء الشركة" : "Create Business"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* ── Locked Business Modal (When clicking a locked workspace in navbar) ── */}
      <Dialog
        open={Boolean(lockedBusinessTarget)}
        onOpenChange={(open) => {
          if (!open) setLockedBusinessTarget(null);
        }}
      >
        <DialogContent className="max-w-md p-6 bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl rounded-3xl">
          <DialogHeader className="text-start space-y-3">
            <div className="h-12 w-12 rounded-2xl bg-amber-500/10 border border-amber-500/25 flex items-center justify-center text-amber-600 dark:text-amber-400">
              <Lock className="w-6 h-6" />
            </div>
            <div>
              <DialogTitle className="text-xl font-bold text-gray-900 dark:text-white">
                {isArabic
                  ? `شركة "${lockedBusinessTarget?.name || ""}" مقفلة`
                  : `"${lockedBusinessTarget?.name || "Business"}" is Locked`}
              </DialogTitle>
              <DialogDescription className="text-xs text-gray-500 dark:text-gray-400 mt-1 leading-relaxed">
                {isArabic
                  ? `تتيح باقتك الحالية (${planTier}) فتح ${maxBusinesses} شركة نشطة فقط في نفس الوقت. تم قفل هذه الشركة ولا يمكن فتحها أو قراءة بياناتها حالياً، ولكن جميع بياناتها المالية (المعاملات والفواتير والعملاء والتقارير) محفوظة بالكامل بأمان.`
                  : `Your current ${planTier} plan allows ${maxBusinesses} active unlocked business(es). This business is locked and cannot be opened or viewed right now, while all of its transactions, invoices, customers, and reports remain safely stored inside it.`}
              </DialogDescription>
            </div>
          </DialogHeader>

          <div className="my-3 p-4 rounded-xl bg-[var(--primary)]/5 dark:bg-[var(--primary)]/10 border border-[var(--primary)]/20 space-y-2 text-xs text-gray-700 dark:text-gray-300">
            <div className="flex items-start gap-2">
              <ShieldCheck className="w-4 h-4 text-[var(--primary)] dark:text-[var(--primary)] shrink-0 mt-0.5" />
              <span>
                {isArabic
                  ? "ترقية الباقة إلى Plus (3 شركات) أو Pro (5 شركات) تعيد فتح الوصول فوراً إلى شركاتك وبياناتها."
                  : "Upgrade to Plus (3 businesses) or Pro (5 businesses) to immediately unlock simultaneous access and restore all saved data."}
              </span>
            </div>
            <div className="flex items-start gap-2">
              <Briefcase className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
              <span>
                {isArabic
                  ? "أو يمكنك تبديل الشركة النشطة في إعدادات الاشتراك لقفل شركة أخرى وفتح هذه الشركة بدلاً منها."
                  : "Or swap your active business allocation in Subscription Settings to lock another business and unlock this one instead."}
              </span>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-end gap-2.5 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setLockedBusinessTarget(null);
                router.push("/dashboard/settings/subscription");
              }}
              className="border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 text-xs"
            >
              {isArabic ? "تبديل الشركة النشطة" : "Swap Active Business"}
            </Button>
            <Button
              type="button"
              onClick={() => {
                setLockedBusinessTarget(null);
                router.push("/dashboard/settings/subscription");
              }}
              className="afab-btn-primary font-bold shadow-md shadow-[var(--primary)]/25 text-xs"
            >
              <Crown className="w-4 h-4 ltr:mr-1.5 rtl:ml-1.5" />
              {isArabic ? "ترقية الباقة لفتح الشركة" : "Upgrade to Unlock"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
