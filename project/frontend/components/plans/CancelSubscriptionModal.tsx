"use client";

import React, { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  AlertTriangle,
  Building2,
  Calendar,
  Check,
  Lock,
  ShieldCheck,
  Loader2,
  CreditCard,
} from "lucide-react";
import { BusinessAllocationItem } from "@/lib/api/business";

interface CancelSubscriptionModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  planName: string;
  isTrial: boolean;
  effectiveEndDate: string | null;
  businesses: BusinessAllocationItem[];
  isSubmitting: boolean;
  isAr: boolean;
  onConfirmCancel: (selectedBusinessIds: string[]) => Promise<void>;
}

export function CancelSubscriptionModal({
  open,
  onOpenChange,
  planName,
  isTrial,
  effectiveEndDate,
  businesses,
  isSubmitting,
  isAr,
  onConfirmCancel,
}: CancelSubscriptionModalProps) {
  const [selectedBusinessId, setSelectedBusinessId] = useState<string>("");

  useEffect(() => {
    if (!open || businesses.length === 0) return;
    const primaryOrActive =
      businesses.find((b) => b.primary) ||
      businesses.find((b) => b.active) ||
      businesses[0];
    setSelectedBusinessId(primaryOrActive?.id || "");
  }, [open, businesses]);

  const handleConfirm = async () => {
    const ids =
      businesses.length > 0 && selectedBusinessId
        ? [selectedBusinessId]
        : [];
    await onConfirmCancel(ids);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg p-6 bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl rounded-3xl">
        <DialogHeader className="text-start space-y-3">
          <div className="h-12 w-12 rounded-2xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-600 dark:text-amber-400">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div>
            <DialogTitle className="text-xl font-bold text-gray-900 dark:text-white">
              {isTrial
                ? isAr
                  ? `إلغاء الفترة التجريبية لباقة ${planName}`
                  : `Cancel Your ${planName} 7-Day Free Trial?`
                : isAr
                ? `إلغاء اشتراك ${planName}؟`
                : `Cancel Your ${planName} Subscription?`}
            </DialogTitle>
            <DialogDescription className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {isAr
                ? "يرجى مراجعة تفاصيل الإلغاء وما سيحدث لشركاتك وبياناتك المالية."
                : "Please review when your access ends and how your businesses will be preserved."}
            </DialogDescription>
          </div>
        </DialogHeader>

        <div className="my-3 space-y-3">
          {/* Key lifecycle guarantees */}
          <div className="rounded-2xl bg-gray-50 dark:bg-[#080c18] border border-gray-200/80 dark:border-gray-800 p-4 space-y-2.5 text-xs">
            <div className="flex items-start gap-2.5">
              <Calendar className="w-4 h-4 text-[#7c3aed] dark:text-[#a78bfa] shrink-0 mt-0.5" />
              <div>
                <p className="font-bold text-gray-900 dark:text-white">
                  {isAr ? "موعد انتهاء الوصول المدفوع:" : "When paid access ends:"}
                </p>
                <p className="text-gray-600 dark:text-gray-400 mt-0.5">
                  {effectiveEndDate
                    ? isAr
                      ? `ستحتفظ بكافة مزايا ${planName} حتى ${effectiveEndDate}.`
                      : `You keep full ${planName} access and features until ${effectiveEndDate}.`
                    : isAr
                    ? `ستحتفظ بكافة مزايا ${planName} حتى نهاية الفترة الحالية.`
                    : `You keep full ${planName} access until the end of your current period.`}
                </p>
              </div>
            </div>

            <div className="flex items-start gap-2.5">
              <CreditCard className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
              <div>
                <p className="font-bold text-gray-900 dark:text-white">
                  {isAr ? "الرسوم والمدفوعات القادمة:" : "Future payments & billing:"}
                </p>
                <p className="text-gray-600 dark:text-gray-400 mt-0.5">
                  {isTrial
                    ? isAr
                      ? "لن يتم تحصيل أي دفعة عند انتهاء الفترة التجريبية، ولن يتجدد الاشتراك."
                      : "No payment will be collected when your trial ends, and your subscription will not renew."
                    : isAr
                    ? "لن يتم تجديد اشتراكك تلقائياً ولن يتم تحصيل أي مبالغ إضافية."
                    : "Your subscription will not renew and no additional charges will be collected."}
                </p>
              </div>
            </div>

            <div className="flex items-start gap-2.5">
              <ShieldCheck className="w-4 h-4 text-sky-600 dark:text-sky-400 shrink-0 mt-0.5" />
              <div>
                <p className="font-bold text-gray-900 dark:text-white">
                  {isAr ? "ماذا يحدث لشركاتك وبياناتك:" : "What happens to your businesses:"}
                </p>
                <p className="text-gray-600 dark:text-gray-400 mt-0.5">
                  {isAr
                    ? "لن يتم حذف أي شركة أو سجل مالي. عند التحول للخطة المجانية، تبقى شركة واحدة نشطة ومفتوحة، وتُقفل باقي الشركات (تظهر في شريط التنقل فقط وتبقى كافة بياناتها محفوظة حتى الترقية أو التبديل)."
                    : "Zero data is deleted. When your account moves to Free, 1 business remains active and additional businesses are locked (visible in the navbar with all financial data safely stored until you upgrade or swap)."}
                </p>
              </div>
            </div>
          </div>

          {/* 1-Business Pre-selection when user owns > 1 business */}
          {businesses.length > 1 && (
            <div className="rounded-2xl border border-purple-200 dark:border-purple-500/25 bg-purple-50/40 dark:bg-purple-950/15 p-4 space-y-2.5">
              <div className="flex items-center justify-between gap-2">
                <p className="text-xs font-bold text-gray-900 dark:text-white">
                  {isAr
                    ? "اختر الشركة التي ستبقى قابلة للتعديل في الخطة المجانية (1 من " +
                      businesses.length +
                      "):"
                    : `Select the 1 business to keep Editable on Free (1 of ${businesses.length}):`}
                </p>
                <span className="afab-badge afab-badge-primary px-2 py-0.5 rounded-full text-[10px]">
                  1 / 1
                </span>
              </div>

              <div className="space-y-1.5 max-h-44 overflow-y-auto custom-scrollbar">
                {businesses.map((biz) => {
                  const isSelected = biz.id === selectedBusinessId;
                  return (
                    <div
                      key={biz.id}
                      role="button"
                      tabIndex={0}
                      onClick={() => setSelectedBusinessId(biz.id)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter" || e.key === " ") {
                          e.preventDefault();
                          setSelectedBusinessId(biz.id);
                        }
                      }}
                      className={`flex items-center justify-between p-2.5 rounded-xl border text-xs cursor-pointer transition-all ${
                        isSelected
                          ? "bg-white dark:bg-[#0c101c] border-[#8b5cf6] shadow-sm"
                          : "bg-white/60 dark:bg-[#080c18]/60 border-gray-200 dark:border-gray-800 hover:border-purple-300"
                      }`}
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        <div
                          className={`h-7 w-7 rounded-lg flex items-center justify-center shrink-0 ${
                            isSelected
                              ? "bg-[#8b5cf6] text-white"
                              : "bg-gray-100 dark:bg-gray-800 text-gray-500"
                          }`}
                        >
                          <Building2 className="w-3.5 h-3.5" />
                        </div>
                        <div className="truncate">
                          <p className="font-bold text-gray-900 dark:text-white truncate">
                            {biz.name}
                          </p>
                          <p className="text-[10px] text-gray-500 dark:text-gray-400">
                            {biz.currency}
                            {biz.industry ? ` • ${biz.industry}` : ""}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-2 shrink-0">
                        {isSelected ? (
                          <span className="inline-flex items-center gap-1 text-[10px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 rounded-full">
                            <Check className="w-3 h-3" />
                            {isAr ? "تبقى نشطة" : "Remains Active"}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[10px] font-medium text-amber-600 dark:text-amber-400 bg-amber-500/10 border border-amber-500/20 px-2 py-0.5 rounded-full">
                            <Lock className="w-2.5 h-2.5" />
                            {isAr ? "تُقفل (البيانات محفوظة)" : "Becomes Locked"}
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
          <button
            type="button"
            disabled={isSubmitting}
            onClick={() => onOpenChange(false)}
            className="afab-btn-primary px-4 py-2 text-xs"
          >
            {isAr ? "الاحتفاظ بالاشتراك" : "Keep Subscription"}
          </button>
          <button
            type="button"
            disabled={isSubmitting || (businesses.length > 1 && !selectedBusinessId)}
            onClick={handleConfirm}
            className="px-4 py-2 rounded-xl text-xs font-bold border border-red-500/30 bg-red-500/10 hover:bg-red-500/20 text-red-600 dark:text-red-400 transition-all inline-flex items-center gap-1.5 disabled:opacity-50"
          >
            {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
            <span>{isAr ? "تأكيد الإلغاء" : "Confirm Cancellation"}</span>
          </button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
