"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useLocale } from "next-intl";
import { Link, usePathname } from "@/i18n/routing";
import {
  AlertTriangle,
  Lock,
  CreditCard,
  ArrowRight,
  Building2,
  Loader2,
  Crown,
} from "lucide-react";
import { SubscriptionService, SubscriptionSnapshot } from "@/lib/api/subscription";
import { BusinessService, BusinessData } from "@/lib/api/business";
import { toast } from "sonner";

export function LifecycleBanners() {
  const locale = useLocale();
  const isAr = locale === "ar";
  const pathname = usePathname();

  const [subscription, setSubscription] = useState<SubscriptionSnapshot | null>(null);
  const [activeBusiness, setActiveBusiness] = useState<BusinessData | null>(null);
  const [openingPortal, setOpeningPortal] = useState(false);

  const loadLifecycleState = useCallback(async () => {
    try {
      const [sub, biz] = await Promise.all([
        SubscriptionService.getMySubscription().catch(() => null),
        BusinessService.getMine().catch(() => null),
      ]);
      if (sub) setSubscription(sub);
      if (biz) setActiveBusiness(biz);
    } catch {
      // Non-blocking banner fetch
    }
  }, []);

  useEffect(() => {
    loadLifecycleState();
  }, [loadLifecycleState, pathname]);

  useEffect(() => {
    const handleReadOnlyBlocked = (event: Event) => {
      const detail = (event as CustomEvent).detail;
      toast.error(
        detail?.message ||
          (isAr
            ? "هذه الشركة مقفلة حالياً. قم بترقية باقتك أو تبديل الشركة النشطة من إعدادات الاشتراك."
            : "This business is locked under your current plan. Upgrade your plan or swap your active business in Subscription Settings.")
      );
      loadLifecycleState();
    };

    const handleSubUpdated = () => {
      loadLifecycleState();
    };

    window.addEventListener("afab:business-read-only", handleReadOnlyBlocked);
    window.addEventListener("afab:subscription-updated", handleSubUpdated);
    return () => {
      window.removeEventListener("afab:business-read-only", handleReadOnlyBlocked);
      window.removeEventListener("afab:subscription-updated", handleSubUpdated);
    };
  }, [isAr, loadLifecycleState]);

  const handleUpdatePaymentMethod = async () => {
    if (openingPortal) return;
    setOpeningPortal(true);
    try {
      const res = await SubscriptionService.createPortalSession(
        locale,
        pathname?.startsWith("/dashboard") ? pathname : "/dashboard/settings/subscription"
      );
      if (res?.url) {
        window.location.assign(res.url);
        return;
      }
    } catch (err: unknown) {
      toast.error(
        err instanceof Error
          ? err.message
          : isAr
          ? "تعذر فتح بوابة تحديث الدفع"
          : "Could not open Stripe Payment Portal"
      );
    } finally {
      setOpeningPortal(false);
    }
  };

  const isPastDue = subscription?.status === "PAST_DUE";
  const isReadOnlyBusiness = activeBusiness && activeBusiness.editable === false;
  const needsAllocationAttention = Boolean(subscription?.allocationAttentionRequired);

  if (!isPastDue && !isReadOnlyBusiness && !needsAllocationAttention) {
    return null;
  }

  const graceHours = subscription?.gracePeriodHoursRemaining ?? 72;
  const graceDays = Math.max(1, Math.ceil(graceHours / 24));
  const graceEndFormatted = subscription?.gracePeriodEndsAt
    ? new Date(subscription.gracePeriodEndsAt).toLocaleDateString(isAr ? "ar" : "en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      })
    : null;

  return (
    <div className="px-4 sm:px-6 pt-3 space-y-2.5 shrink-0">
      {/* 1. Payment Failure & 3-Day Grace Period Warning Banner */}
      {isPastDue && (
        <div className="rounded-2xl border border-red-500/30 bg-gradient-to-r from-red-500/10 via-amber-500/5 to-red-500/10 p-3.5 sm:px-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 shadow-sm">
          <div className="flex items-start gap-3">
            <div className="h-9 w-9 rounded-xl bg-red-500/15 border border-red-500/25 text-red-600 dark:text-red-400 flex items-center justify-center shrink-0 mt-0.5">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <div className="text-xs space-y-0.5">
              <div className="flex flex-wrap items-center gap-2">
                <span className="font-bold text-red-700 dark:text-red-300">
                  {isAr
                    ? "تعذر تحصيل دفعة الاشتراك — فترة سماح لمدة 3 أيام نشطة"
                    : "Subscription Payment Failed — 3-Day Grace Period Active"}
                </span>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-500/20 text-red-700 dark:text-red-300">
                  {isAr
                    ? `متبقي حوالي ${graceDays} أيام (${graceHours} ساعة)`
                    : `~${graceDays} day(s) / ${graceHours}h remaining`}
                </span>
              </div>
              <p className="text-gray-700 dark:text-gray-300">
                {isAr
                  ? `تستمر مزايا باقة ${subscription?.planName} الحالية خلال فترة السماح${
                      graceEndFormatted ? ` حتى ${graceEndFormatted}` : ""
                    }. إذا لم ينجح الدفع بعد 3 أيام، سيتم تحويل الحساب إلى الخطة المجانية (شركة واحدة قابلة للتعديل وباقي الشركات قراءة فقط مع حفظ كافة البيانات).`
                  : `Your ${subscription?.planName} entitlements remain active during the grace period${
                      graceEndFormatted ? ` until ${graceEndFormatted}` : ""
                    }. If payment remains unsuccessful after 3 days, your account will downgrade to Free (1 editable business, remaining businesses preserved as read-only).`}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              disabled={openingPortal}
              onClick={handleUpdatePaymentMethod}
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-red-600 hover:bg-red-500 text-white shadow-sm inline-flex items-center gap-1.5 transition-all disabled:opacity-60"
            >
              {openingPortal ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <CreditCard className="w-3.5 h-3.5" />
              )}
              <span>{isAr ? "تحديث وسيلة الدفع" : "Update Payment Method"}</span>
            </button>
          </div>
        </div>
      )}

      {/* 2. Read-Only Active Business Banner */}
      {isReadOnlyBusiness && (
        <div className="rounded-2xl border border-amber-500/30 bg-amber-50/90 dark:bg-amber-500/10 p-3 sm:px-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div className="flex items-start sm:items-center gap-3">
            <div className="h-8 w-8 rounded-xl bg-amber-500/15 border border-amber-500/25 text-amber-600 dark:text-amber-400 flex items-center justify-center shrink-0">
              <Lock className="w-4 h-4" />
            </div>
            <div className="text-xs">
              <p className="font-bold text-gray-900 dark:text-white">
                {isAr
                  ? `شركة "${activeBusiness.name}" مقفلة (Locked)`
                  : `"${activeBusiness.name}" is Locked`}
              </p>
              <p className="text-gray-600 dark:text-gray-300">
                {isAr
                  ? "جميع بيانات هذه الشركة محفوظة بأمان، ولا يمكن فتحها أو عرضها في الباقة الحالية. يمكنك تبديل الشركة النشطة أو ترقية باقتك لإعادة فتحها."
                  : "All data in this business is safely saved, and access is locked under your current plan limits. Swap your active business allocation or upgrade your plan to unlock it."}
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2 shrink-0">
            <Link
              href="/dashboard/settings/subscription"
              className="afab-btn-secondary px-3 py-1.5 text-xs inline-flex items-center gap-1.5"
            >
              <Building2 className="w-3.5 h-3.5" />
              <span>{isAr ? "تغيير تخصيص الشركات" : "Manage Allocation"}</span>
            </Link>
            <Link
              href="/dashboard/settings/subscription"
              className="afab-btn-primary px-3.5 py-1.5 text-xs inline-flex items-center gap-1.5"
            >
              <Crown className="w-3.5 h-3.5" />
              <span>{isAr ? "ترقية الباقة" : "Upgrade Plan"}</span>
            </Link>
          </div>
        </div>
      )}

      {/* 3. Business Allocation Attention Required Banner */}
      {needsAllocationAttention && !isReadOnlyBusiness && (
        <div className="rounded-2xl border border-purple-500/30 bg-purple-50/80 dark:bg-purple-500/10 p-3 sm:px-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div className="flex items-center gap-3 text-xs">
            <div className="h-8 w-8 rounded-xl bg-[#8b5cf6]/15 text-[#7c3aed] dark:text-[#a78bfa] flex items-center justify-center shrink-0">
              <Building2 className="w-4 h-4" />
            </div>
            <div>
              <p className="font-bold text-gray-900 dark:text-white">
                {isAr
                  ? "يرجى مراجعة تخصيص الشركات القابلة للتعديل"
                  : "Business Allocation Needs Your Attention"}
              </p>
              <p className="text-gray-600 dark:text-gray-300">
                {isAr
                  ? "تم الإبقاء على شركتك الرئيسية قابلة للتعديل تلقائياً. يمكنك اختيار الشركات التي تفضل إدارتها من إعدادات الاشتراك."
                  : "We kept your designated primary business editable by default. Choose which businesses you prefer to actively manage in Subscription Settings."}
              </p>
            </div>
          </div>

          <Link
            href="/dashboard/settings/subscription"
            className="afab-btn-primary px-3.5 py-1.5 text-xs inline-flex items-center gap-1.5 shrink-0"
          >
            <span>{isAr ? "اختيار الشركات" : "Choose Businesses"}</span>
            <ArrowRight className="w-3.5 h-3.5 rtl:rotate-180" />
          </Link>
        </div>
      )}
    </div>
  );
}
