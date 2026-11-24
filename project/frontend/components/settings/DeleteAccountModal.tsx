"use client";

import { useEffect, useState } from "react";
import { useLocale } from "next-intl";
import { SettingsService } from "@/lib/api/settings";
import { AuthStore } from "@/lib/auth-store";
import {
  Dialog,
  DialogContent,
  DialogTitle,
} from "@/components/ui/dialog";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { AfabLoader } from "@/components/ui/afab-loader";
import {
  AlertCircle,
  AlertTriangle,
  ArrowLeft,
  Building2,
  CheckCircle2,
  Download,
  ShieldAlert,
  Sparkles,
  Trash2,
} from "lucide-react";

interface DeleteProfileSummary {
  firstName?: string;
  lastName?: string;
  email?: string;
  avatarUrl?: string | null;
  businessName?: string;
  planTier?: string;
}

interface DeleteBusinessSummary {
  name?: string;
}

interface DeleteAccountModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  profile: DeleteProfileSummary | null;
  business: DeleteBusinessSummary | null;
}

export function DeleteAccountModal({
  open,
  onOpenChange,
  profile,
  business,
}: DeleteAccountModalProps) {
  const locale = useLocale();
  const isArabic = locale === "ar";

  const [step, setStep] = useState<1 | 2 | 3>(1);
  const [isExporting, setIsExporting] = useState(false);
  const [exportDone, setExportDone] = useState<{
    filename: string;
    transactionsCount: number;
    businessesCount: number;
  } | null>(null);
  const [exportError, setExportError] = useState("");

  const [confirmInput, setConfirmInput] = useState("");
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState("");
  const [preflight, setPreflight] = useState<{
    canDelete: boolean;
    blockingBusinesses: Array<{
      businessId: string;
      businessName: string;
      activeMemberCount: number;
      hasOtherActiveMembers: boolean;
    }>;
    guidance: string;
  } | null>(null);
  const [archivingBusinessId, setArchivingBusinessId] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    let active = true;
    SettingsService.getDeletionPreflight()
      .then((res) => {
        if (active) setPreflight(res);
      })
      .catch(() => {
        if (active) setPreflight(null);
      });
    return () => {
      active = false;
    };
  }, [open]);

  const handleArchiveBlockingBusiness = async (businessId: string) => {
    setArchivingBusinessId(businessId);
    setDeleteError("");
    try {
      await SettingsService.archiveBusiness(businessId);
      const refreshed = await SettingsService.getDeletionPreflight();
      setPreflight(refreshed);
    } catch (err: unknown) {
      setDeleteError(
        err instanceof Error ? err.message : "Failed to archive business."
      );
    } finally {
      setArchivingBusinessId(null);
    }
  };

  const handleOpenChange = (nextOpen: boolean) => {
    if (isDeleting) return;
    if (!nextOpen) {
      setStep(1);
      setExportDone(null);
      setExportError("");
      setConfirmInput("");
      setDeleteError("");
      setIsExporting(false);
    }
    onOpenChange(nextOpen);
  };

  const fullName =
    `${profile?.firstName || ""} ${profile?.lastName || ""}`.trim() ||
    profile?.email ||
    "Account";
  const email = profile?.email || "";
  const initials = `${profile?.firstName?.[0] || ""}${profile?.lastName?.[0] || ""}`.toUpperCase();
  const expectedPhrase = `delete ${email}`;
  const isPhraseMatch =
    email.length > 0 &&
    confirmInput.trim().toLowerCase() === expectedPhrase.toLowerCase();

  const handleExportBeforeDelete = async () => {
    setIsExporting(true);
    setExportError("");
    try {
      const result = await SettingsService.exportMyData();
      setExportDone({
        filename: result.filename,
        transactionsCount: result.summary.transactionsCount,
        businessesCount: result.summary.businessesCount,
      });
    } catch (err: unknown) {
      setExportError(
        err instanceof Error
          ? err.message
          : isArabic
          ? "تعذر تصدير البيانات حالياً. يمكنك المحاولة مرة أخرى."
          : "Failed to export data right now. Please try again."
      );
    } finally {
      setIsExporting(false);
    }
  };

  const handleConfirmDelete = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isPhraseMatch || isDeleting) return;

    setIsDeleting(true);
    setDeleteError("");

    try {
      await SettingsService.deleteAccount(confirmInput.trim());
      AuthStore.clearAuth();
      window.location.href = `/${locale}/login?accountDeleted=1`;
    } catch (err: unknown) {
      setDeleteError(
        err instanceof Error
          ? err.message
          : isArabic
          ? "فشل حذف الحساب. يرجى المحاولة مرة أخرى."
          : "Failed to delete account. Please try again."
      );
      setIsDeleting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="flex flex-col gap-0 w-[calc(100%-2rem)] sm:max-w-[480px] rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0d1117] p-0 overflow-hidden shadow-2xl">
        {/* GitHub-style Top Header Bar */}
        <div className="w-full min-w-0 px-5 py-3.5 pe-12 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between gap-3">
          <div className="flex items-center gap-2 min-w-0">
            {step > 1 && (
              <button
                type="button"
                onClick={() => {
                  setDeleteError("");
                  setStep((prev) => (prev === 3 ? 2 : 1));
                }}
                disabled={isDeleting}
                className="p-1 -ms-1 rounded-lg text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.06] transition-colors cursor-pointer shrink-0"
                title={isArabic ? "رجوع" : "Back"}
              >
                <ArrowLeft className="w-4 h-4 rtl:rotate-180" />
              </button>
            )}
            <DialogTitle className="text-sm font-bold text-gray-900 dark:text-white truncate">
              {isArabic ? `حذف ${fullName}` : `Delete ${fullName}`}
            </DialogTitle>
          </div>
          <span className="text-[11px] font-mono text-gray-400 dark:text-gray-500 shrink-0">
            {step}/3
          </span>
        </div>

        <div className="w-full min-w-0 p-5 sm:p-6 space-y-5">
          {/* GitHub-style Centered Target Identity Block */}
          <div className="flex flex-col items-center text-center pt-1 pb-2">
            <div className="relative mb-3">
              <Avatar className="w-14 h-14 border-2 border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-[#161b22]">
                <AvatarImage src={profile?.avatarUrl || undefined} />
                <AvatarFallback className="text-base font-bold bg-red-500/10 text-red-600 dark:text-red-400">
                  {initials || "U"}
                </AvatarFallback>
              </Avatar>
              <span className="absolute -bottom-1 -end-1 w-5 h-5 rounded-full bg-red-600 text-white flex items-center justify-center ring-2 ring-white dark:ring-[#0d1117]">
                <ShieldAlert className="w-3 h-3" />
              </span>
            </div>

            <h3 className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">
              {fullName}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400 font-mono mt-0.5">
              {email}
            </p>

            <div className="flex items-center justify-center gap-4 mt-2.5 text-xs text-gray-500 dark:text-gray-400">
              <span className="inline-flex items-center gap-1.5">
                <Building2 className="w-3.5 h-3.5 text-gray-400" />
                {business?.name ||
                  profile?.businessName ||
                  (isArabic ? "مساحة عملي" : "My Workspace")}
              </span>
              <span className="inline-flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5 text-purple-400" />
                {(profile?.planTier || "FREE").toUpperCase()}
              </span>
            </div>
          </div>

          {/* ── STEP 1: Confirm Data Export First ── */}
          {step === 1 && (
            <div className="space-y-4 animate-in fade-in duration-200">
              <div className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/80 dark:bg-[#161b22]/80 p-4 space-y-3">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-lg bg-[var(--primary)]/10 text-[var(--primary-hover)] dark:text-[var(--primary)] flex items-center justify-center shrink-0">
                    <Download className="w-4 h-4" />
                  </div>
                  <div className="space-y-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 dark:text-white">
                      {isArabic
                        ? "هل تريد تصدير نسخة من بياناتك أولاً؟"
                        : "Export a copy of your data first?"}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
                      {isArabic
                        ? "قبل حذف حسابك نهائياً، نوصي بتنزيل نسخة احتياطية كاملة (JSON) تشمل ملفك الشخصي وشركاتك ومعاملاتك."
                        : "Before permanently deleting your account, we recommend downloading a complete JSON archive of your profile, businesses, categories, and transactions."}
                    </p>
                  </div>
                </div>

                {exportError && (
                  <div className="p-2.5 rounded-lg border border-red-500/25 bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 flex items-center gap-2 text-xs">
                    <AlertCircle className="w-4 h-4 shrink-0" />
                    <span>{exportError}</span>
                  </div>
                )}

                {exportDone ? (
                  <div className="p-3 rounded-lg border border-emerald-500/30 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-300 space-y-2 text-xs">
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex items-start gap-2 min-w-0 flex-1">
                        <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />
                        <div className="min-w-0 flex-1">
                          <p className="font-semibold">
                            {isArabic ? "تم تصدير بياناتك بنجاح" : "Data exported successfully"}
                          </p>
                          <p className="text-[11px] opacity-85 font-mono break-all mt-0.5">
                            {exportDone.filename}
                          </p>
                          <p className="text-[11px] opacity-80 mt-0.5">
                            {exportDone.businessesCount}{" "}
                            {isArabic
                              ? "شركات"
                              : exportDone.businessesCount === 1
                              ? "workspace"
                              : "workspaces"}
                            {" · "}
                            {exportDone.transactionsCount}{" "}
                            {isArabic
                              ? "معاملات"
                              : exportDone.transactionsCount === 1
                              ? "transaction"
                              : "transactions"}
                          </p>
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={handleExportBeforeDelete}
                        disabled={isExporting}
                        className="text-[11px] font-semibold underline shrink-0 cursor-pointer hover:opacity-80"
                      >
                        {isArabic ? "تنزيل مجدداً" : "Download again"}
                      </button>
                    </div>
                  </div>
                ) : (
                  <button
                    type="button"
                    onClick={handleExportBeforeDelete}
                    disabled={isExporting}
                    className="w-full py-2.5 px-4 rounded-lg border border-[var(--primary)]/40 bg-[var(--primary)]/10 hover:bg-[var(--primary)]/20 text-[var(--primary-hover)] dark:text-[#c4b5fd] text-xs font-semibold flex items-center justify-center gap-2 transition-colors cursor-pointer disabled:opacity-60"
                  >
                    {isExporting ? (
                      <>
                        <AfabLoader size="xs" />
                        <span>
                          {isArabic ? "جاري تجهيز ملف البيانات..." : "Preparing your data export..."}
                        </span>
                      </>
                    ) : (
                      <>
                        <Download className="w-4 h-4" />
                        <span>
                          {isArabic ? "تصدير بياناتي أولاً (.json)" : "Export My Data First (.json)"}
                        </span>
                      </>
                    )}
                  </button>
                )}
              </div>

              <button
                type="button"
                onClick={() => setStep(2)}
                disabled={isExporting}
                className="w-full py-2.5 px-4 rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-100 hover:bg-gray-200 dark:bg-[#21262d] dark:hover:bg-[#30363d] text-gray-900 dark:text-gray-100 text-sm font-semibold text-center leading-snug transition-colors cursor-pointer disabled:opacity-50"
              >
                {exportDone
                  ? isArabic
                    ? "متابعة إلى حذف الحساب"
                    : "Continue to delete this account"
                  : isArabic
                  ? "تخطي التصدير — أريد حذف هذا الحساب"
                  : "I want to delete this account"}
              </button>
            </div>
          )}

          {/* ── STEP 2: GitHub-style "Unexpected bad things" Warning ── */}
          {step === 2 && (
            <div className="space-y-4 animate-in fade-in duration-200">
              <div className="rounded-lg border border-amber-500/40 bg-amber-50 dark:bg-amber-950/35 px-4 py-3 flex items-center gap-3">
                <AlertTriangle className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0" />
                <p className="text-xs font-semibold text-amber-900 dark:text-amber-200">
                  {isArabic
                    ? "ستحدث أشياء غير قابلة للتراجع إذا لم تقرأ هذا!"
                    : "Unexpected bad things will happen if you don’t read this!"}
                </p>
              </div>

              <div className="relative ps-5 py-1 space-y-2.5 text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
                <span className="absolute start-1.5 top-2.5 bottom-2.5 w-px bg-gray-300 dark:bg-gray-700" />
                <span className="absolute start-[3px] top-2.5 w-2 h-2 rounded-full bg-gray-400 dark:bg-gray-500" />
                <p>
                  {isArabic ? (
                    <>
                      سيؤدي هذا إلى حذف حساب <strong className="text-gray-900 dark:text-white">{fullName}</strong>{" "}
                      (<span className="font-mono">{email}</span>) نهائياً، بما في ذلك جميع الشركات ومساحات العمل
                      والمعاملات المالية والفئات والاشتراكات والجلسات النشطة.
                    </>
                  ) : (
                    <>
                      This will deactivate and anonymize the{" "}
                      <strong className="text-gray-900 dark:text-white">{fullName}</strong>{" "}
                      user account (<span className="font-mono">{email}</span>) and revoke all active sessions.
                      Archived business financial ledgers and audit trails are preserved safely — owned active businesses must be transferred or archived first.
                    </>
                  )}
                </p>
                <p className="text-red-600 dark:text-red-400 font-medium">
                  {isArabic
                    ? "هذا الإجراء نهائي ولا يمكن استعادة الحساب أو البيانات بعد الحذف."
                    : "This action is permanent and cannot be undone."}
                </p>
              </div>

              <button
                type="button"
                onClick={() => setStep(3)}
                className="w-full py-2.5 px-4 rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-100 hover:bg-gray-200 dark:bg-[#21262d] dark:hover:bg-[#30363d] text-gray-900 dark:text-gray-100 text-sm font-semibold transition-colors cursor-pointer"
              >
                {isArabic
                  ? "لقد قرأت وفهمت هذه الآثار"
                  : "I have read and understand these effects"}
              </button>
            </div>
          )}

          {/* ── STEP 3: GitHub-style Type Phrase to Confirm ── */}
          {step === 3 && (
            <form onSubmit={handleConfirmDelete} className="space-y-4 animate-in fade-in duration-200">
              {preflight && !preflight.canDelete && (
                <div className="p-3.5 rounded-lg border border-amber-500/40 bg-amber-50 dark:bg-amber-950/35 text-amber-900 dark:text-amber-200 space-y-2.5 text-xs">
                  <div className="flex items-start gap-2">
                    <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5 text-amber-600 dark:text-amber-400" />
                    <p className="font-medium leading-relaxed">{preflight.guidance}</p>
                  </div>
                  <div className="space-y-1.5">
                    {preflight.blockingBusinesses.map((b) => (
                      <div
                        key={b.businessId}
                        className="flex items-center justify-between gap-2 rounded-md bg-white/80 dark:bg-[#0d1117]/80 px-2.5 py-2 border border-amber-500/20"
                      >
                        <span className="font-semibold truncate">{b.businessName}</span>
                        <button
                          type="button"
                          disabled={archivingBusinessId === b.businessId}
                          onClick={() => handleArchiveBlockingBusiness(b.businessId)}
                          className="px-2.5 py-1 rounded-md text-[11px] font-semibold bg-amber-600 hover:bg-amber-700 text-white disabled:opacity-50 shrink-0 cursor-pointer"
                        >
                          {archivingBusinessId === b.businessId
                            ? isArabic ? "جاري الأرشفة..." : "Archiving..."
                            : isArabic ? "أرشفة الشركة" : "Archive Business"}
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {deleteError && (
                <div className="p-3 rounded-lg border border-red-500/30 bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 flex items-start gap-2 text-xs">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{deleteError}</span>
                </div>
              )}

              <div className="space-y-2.5">
                <label
                  htmlFor="delete-account-confirm-input"
                  className="block text-sm font-semibold text-gray-900 dark:text-white leading-snug"
                >
                  {isArabic ? (
                    <>
                      للتأكيد، اكتب{" "}
                      <span className="font-mono text-red-600 dark:text-red-400 select-all">
                        &quot;{expectedPhrase}&quot;
                      </span>{" "}
                      في المربع أدناه
                    </>
                  ) : (
                    <>
                      To confirm, type{" "}
                      <span className="font-mono text-red-600 dark:text-red-400 select-all">
                        &quot;{expectedPhrase}&quot;
                      </span>{" "}
                      in the box below
                    </>
                  )}
                </label>

                <input
                  id="delete-account-confirm-input"
                  type="text"
                  dir="ltr"
                  autoFocus
                  autoComplete="off"
                  spellCheck={false}
                  value={confirmInput}
                  onChange={(e) => setConfirmInput(e.target.value)}
                  disabled={isDeleting}
                  placeholder={expectedPhrase}
                  className={`w-full rounded-lg px-3.5 py-2.5 text-sm font-mono text-left bg-white dark:bg-[#0d1117] text-gray-900 dark:text-white placeholder:text-gray-400/60 dark:placeholder:text-gray-600 border-2 outline-none transition-colors ${
                    isPhraseMatch
                      ? "border-emerald-500 focus:border-emerald-500"
                      : "border-red-500/75 focus:border-red-500"
                  }`}
                />
              </div>

              <button
                type="submit"
                disabled={!isPhraseMatch || isDeleting || (preflight !== null && !preflight.canDelete)}
                className={`w-full py-2.5 px-4 rounded-lg text-sm font-semibold flex items-center justify-center gap-2 transition-all border ${
                  isPhraseMatch && !isDeleting && !(preflight !== null && !preflight.canDelete)
                    ? "bg-red-600 hover:bg-red-700 text-white border-red-600 shadow-lg shadow-red-600/20 cursor-pointer"
                    : "bg-gray-100 dark:bg-[#21262d] text-red-500/60 dark:text-red-400/50 border-gray-200 dark:border-gray-800 cursor-not-allowed"
                }`}
              >
                {isDeleting ? (
                  <>
                    <AfabLoader size="xs" />
                    <span>{isArabic ? "جاري حذف الحساب..." : "Deleting account..."}</span>
                  </>
                ) : (
                  <>
                    <Trash2 className="w-4 h-4" />
                    <span>{isArabic ? "حذف هذا الحساب نهائياً" : "Delete this account"}</span>
                  </>
                )}
              </button>
            </form>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
