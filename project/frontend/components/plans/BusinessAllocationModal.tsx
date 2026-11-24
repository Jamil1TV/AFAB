"use client";

import React, { useState, useEffect, useMemo } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  Building2,
  Check,
  Lock,
  Sparkles,
  Loader2,
  AlertCircle,
  ShieldCheck,
} from "lucide-react";
import { BusinessAllocationItem } from "@/lib/api/business";

interface BusinessAllocationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  mode: "DOWNGRADE" | "MANAGE" | "PENDING_EDIT";
  targetPlanName: string;
  targetPlanSlug: "free" | "plus" | "pro";
  maxAllowed: number;
  businesses: BusinessAllocationItem[];
  initialSelectedIds?: string[];
  isSubmitting: boolean;
  isAr: boolean;
  onSubmit: (selectedBusinessIds: string[]) => Promise<void>;
}

export function BusinessAllocationModal({
  open,
  onOpenChange,
  mode,
  targetPlanName,
  targetPlanSlug,
  maxAllowed,
  businesses,
  initialSelectedIds,
  isSubmitting,
  isAr,
  onSubmit,
}: BusinessAllocationModalProps) {
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const requiredCount = useMemo(() => {
    if (mode === "DOWNGRADE" || mode === "PENDING_EDIT") {
      return Math.min(businesses.length, maxAllowed);
    }
    return Math.min(businesses.length, maxAllowed);
  }, [businesses.length, maxAllowed, mode]);

  useEffect(() => {
    if (!open) return;
    if (initialSelectedIds && initialSelectedIds.length > 0) {
      setSelectedIds(initialSelectedIds.slice(0, maxAllowed));
      return;
    }
    const currentlyEditable = businesses
      .filter((b) => b.editable)
      .map((b) => b.id);
    if (currentlyEditable.length <= maxAllowed && currentlyEditable.length > 0) {
      setSelectedIds(currentlyEditable);
    } else {
      const sorted = [...businesses].sort((a, b) => {
        if (a.primary !== b.primary) return a.primary ? -1 : 1;
        if (a.active !== b.active) return a.active ? -1 : 1;
        return 0;
      });
      setSelectedIds(sorted.slice(0, requiredCount).map((b) => b.id));
    }
  }, [open, businesses, initialSelectedIds, maxAllowed, requiredCount]);

  const toggleBusiness = (id: string) => {
    setSelectedIds((prev) => {
      if (prev.includes(id)) {
        return prev.filter((item) => item !== id);
      }
      if (maxAllowed === 1) {
        return [id];
      }
      if (prev.length >= maxAllowed) {
        return prev;
      }
      return [...prev, id];
    });
  };

  const isExactSelectionRequired =
    mode === "DOWNGRADE" || mode === "PENDING_EDIT" || businesses.length >= maxAllowed;

  const isValid = isExactSelectionRequired
    ? selectedIds.length === requiredCount
    : selectedIds.length >= 1 && selectedIds.length <= maxAllowed;

  const readOnlyBusinesses = useMemo(
    () => businesses.filter((b) => !selectedIds.includes(b.id)),
    [businesses, selectedIds]
  );

  const editableBusinesses = useMemo(
    () => businesses.filter((b) => selectedIds.includes(b.id)),
    [businesses, selectedIds]
  );

  const handleConfirm = async () => {
    if (!isValid || isSubmitting) return;
    await onSubmit(selectedIds);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-xl p-6 bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl rounded-3xl">
        <DialogHeader className="text-start space-y-2.5">
          <div className="flex items-center justify-between gap-3">
            <div className="h-11 w-11 rounded-2xl bg-[var(--primary)]/10 border border-[var(--primary)]/25 flex items-center justify-center text-[var(--primary)]">
              <Building2 className="w-5 h-5" />
            </div>
            <span
              className={`px-3 py-1 rounded-full text-xs font-bold border ${
                isValid
                  ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/25"
                  : "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/25"
              }`}
            >
              {isAr
                ? `تم اختيار ${selectedIds.length} من ${requiredCount}`
                : `Selected ${selectedIds.length} / ${requiredCount}`}
            </span>
          </div>

          <div>
            <DialogTitle className="text-xl font-bold text-gray-900 dark:text-white">
              {mode === "DOWNGRADE"
                ? isAr
                  ? `اختر الشركات النشطة لباقة ${targetPlanName}`
                  : `Select Editable Businesses for ${targetPlanName}`
                : mode === "PENDING_EDIT"
                ? isAr
                  ? `تعديل اختيار الشركات لباقة ${targetPlanName} القادمة`
                  : `Update Scheduled ${targetPlanName} Business Allocation`
                : isAr
                ? "إدارة تخصيص الشركات القابلة للتعديل"
                : "Manage Editable Business Allocation"}
            </DialogTitle>
            <DialogDescription className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {isAr
                ? `تدعم باقة ${targetPlanName} عدد ${maxAllowed} شركات نشطة ومفتوحة. اختر ${requiredCount} شركات ترغب في الاستمرار بإدارتها، وستُقفل باقي الشركات مع حفظ كافة بياناتها بالكامل حتى تقوم بالترقية أو تبديل التخصيص.`
                : `Your ${targetPlanName} plan supports ${maxAllowed} active unlocked business${
                    maxAllowed > 1 ? "es" : ""
                  }. Choose which ${requiredCount} business${
                    requiredCount > 1 ? "es" : ""
                  } to keep unlocked; the remaining businesses will be locked with all data safely preserved.`}
            </DialogDescription>
          </div>
        </DialogHeader>

        {/* Businesses Selection List */}
        <div className="my-3 space-y-2 max-h-64 overflow-y-auto custom-scrollbar pr-1">
          {businesses.map((biz) => {
            const checked = selectedIds.includes(biz.id);
            const disabledToAdd = !checked && maxAllowed > 1 && selectedIds.length >= maxAllowed;

            return (
              <div
                key={biz.id}
                role="button"
                tabIndex={0}
                onClick={() => {
                  if (!disabledToAdd) toggleBusiness(biz.id);
                }}
                onKeyDown={(e) => {
                  if ((e.key === "Enter" || e.key === " ") && !disabledToAdd) {
                    e.preventDefault();
                    toggleBusiness(biz.id);
                  }
                }}
                className={`flex items-center justify-between p-3 rounded-2xl border transition-all ${
                  checked
                    ? "bg-[var(--primary)]/10 border-[var(--primary)] shadow-sm cursor-pointer"
                    : disabledToAdd
                    ? "bg-gray-50/60 dark:bg-[#080c18]/50 border-gray-200 dark:border-gray-800/70 opacity-65 cursor-not-allowed"
                    : "bg-white dark:bg-[#080c18] border-gray-200 dark:border-gray-800 hover:border-[var(--primary)]/40 cursor-pointer"
                }`}
              >
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  {/* Checkbox */}
                  <div
                    className={`w-5 h-5 rounded-md flex items-center justify-center border transition-colors shrink-0 ${
                      checked
                        ? "bg-[var(--primary)] border-[var(--primary)] text-white"
                        : "border-gray-300 dark:border-gray-700 bg-white dark:bg-[#0c101c]"
                    }`}
                  >
                    {checked && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>

                  {/* Logo or Icon */}
                  <div className="h-9 w-9 rounded-xl bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 flex items-center justify-center overflow-hidden shrink-0">
                    {biz.logoUrl ? (
                      <img
                        src={biz.logoUrl}
                        alt={biz.name}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <Building2 className="w-4 h-4 text-[var(--primary)]" />
                    )}
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-1.5">
                      <p className="text-xs font-bold text-gray-900 dark:text-white truncate">
                        {biz.name}
                      </p>
                      {biz.primary && (
                        <span className="px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-[var(--primary)]/10 text-[var(--primary)] border border-[var(--primary)]/20">
                          {isAr ? "رئيسية" : "Primary"}
                        </span>
                      )}
                      {biz.active && (
                        <span className="px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20">
                          {isAr ? "الحالية" : "Current"}
                        </span>
                      )}
                    </div>
                    <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate">
                      {biz.currency}
                      {biz.industry ? ` • ${biz.industry}` : ""}
                      {biz.country ? ` • ${biz.country}` : ""}
                      {" • "}
                      {biz.editable
                        ? isAr
                          ? "الحالة الحالية: مفتوحة (نشطة)"
                          : "Current: Active (Unlocked)"
                        : isAr
                        ? "الحالة الحالية: مقفلة (البيانات محفوظة)"
                        : "Current: Locked (Data Saved)"}
                    </p>
                  </div>
                </div>

                <div className="ms-2 shrink-0">
                  {checked ? (
                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                      <Check className="w-3 h-3" />
                      {isAr ? "نشطة ومفتوحة" : "Unlocked"}
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-semibold bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20">
                      <Lock className="w-2.5 h-2.5" />
                      {isAr ? "مقفلة" : "Locked"}
                    </span>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        {/* Summary of Editable vs Read-Only Outcome */}
        <div className="rounded-2xl bg-gray-50 dark:bg-[#080c18] border border-gray-200 dark:border-gray-800 p-3.5 space-y-2 text-xs">
            <div className="flex items-start gap-2">
              <ShieldCheck className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
              <p className="text-gray-700 dark:text-gray-300">
                <strong className="text-gray-900 dark:text-white">
                  {isAr ? "ستبقى مفتوحة ونشطة:" : "Will remain Active (Unlocked):"}
                </strong>{" "}
                {editableBusinesses.length > 0
                  ? editableBusinesses.map((b) => b.name).join(", ")
                  : isAr
                  ? "لم يتم الاختيار بعد"
                  : "None selected"}
              </p>
            </div>

            {readOnlyBusinesses.length > 0 && (
              <div className="flex items-start gap-2">
                <Lock className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                <p className="text-gray-700 dark:text-gray-300">
                  <strong className="text-gray-900 dark:text-white">
                    {isAr
                      ? "ستُقفل مع حفظ كافة البيانات بداخلها:"
                      : "Will be Locked (all data safely vaulted until you upgrade or swap):"}
                  </strong>{" "}
                  {readOnlyBusinesses.map((b) => b.name).join(", ")}
                </p>
              </div>
            )}

          {!isValid && (
            <div className="flex items-center gap-2 text-amber-600 dark:text-amber-400 font-semibold pt-1">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>
                {isAr
                  ? `يرجى اختيار ${requiredCount} شركات بالضبط للمتابعة.`
                  : `Please select exactly ${requiredCount} business${
                      requiredCount > 1 ? "es" : ""
                    } to continue.`}
              </span>
            </div>
          )}
        </div>

        <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
          <button
            type="button"
            disabled={isSubmitting}
            onClick={() => onOpenChange(false)}
            className="afab-btn-secondary px-4 py-2 text-xs"
          >
            {isAr ? "إلغاء" : "Cancel"}
          </button>
          <button
            type="button"
            disabled={!isValid || isSubmitting}
            onClick={handleConfirm}
            className="afab-btn-primary px-5 py-2 text-xs inline-flex items-center gap-1.5 disabled:opacity-50"
          >
            {isSubmitting ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin" />
            ) : (
              <Sparkles className="w-3.5 h-3.5" />
            )}
            <span>
              {mode === "DOWNGRADE"
                ? isAr
                  ? `تأكيد التخفيض إلى ${targetPlanName}`
                  : `Confirm Downgrade to ${targetPlanName}`
                : isAr
                ? "حفظ تخصيص الشركات"
                : "Save Business Allocation"}
            </span>
          </button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
