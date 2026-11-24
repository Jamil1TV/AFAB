"use client";

import { useEffect, useState } from "react";
import { ArrowUpRight, CheckCircle2, Loader2, Receipt, ShieldAlert, X } from "lucide-react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { AiActionDraft, AiService } from "@/lib/api/ai";
import { CategoryItem, CategoryService } from "@/lib/api/categories";
import { Customer, CustomerService } from "@/lib/api/customers";
import { formatCurrency } from "@/lib/currency";
import { toast } from "sonner";

interface CopilotActionDraftCardProps {
  messageId: string;
  draft: AiActionDraft;
  onUpdated: (updated: AiActionDraft) => void;
}

export function CopilotActionDraftCard({
  messageId,
  draft,
  onUpdated,
}: CopilotActionDraftCardProps) {
  const t = useTranslations("AI.drafts");
  const p = draft.payload || {};

  const [saving, setSaving] = useState(false);
  const [dismissing, setDismissing] = useState(false);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [receiptPreviewUrl, setReceiptPreviewUrl] = useState<string | null>(null);

  // Transaction state
  const [txType, setTxType] = useState<string>(String(p.type || "EXPENSE"));
  const [txAmount, setTxAmount] = useState<string>(String(p.amount ?? ""));
  const [txCurrency, setTxCurrency] = useState<string>(String(p.currency || "USD"));
  const [txDesc, setTxDesc] = useState<string>(String(p.description || ""));
  const [txDate, setTxDate] = useState<string>(
    String(p.transactionDate || new Date().toISOString().slice(0, 10))
  );
  const [txCategoryId, setTxCategoryId] = useState<string>(String(p.categoryId || ""));
  const [txMethod, setTxMethod] = useState<string>(String(p.paymentMethod || "BANK_TRANSFER"));
  const [txNotes, setTxNotes] = useState<string>(String(p.notes || ""));

  // Invoice state
  const [invCustomerId, setInvCustomerId] = useState<string>(String(p.customerId || ""));
  const [invIssueDate, setInvIssueDate] = useState<string>(
    String(p.issueDate || new Date().toISOString().slice(0, 10))
  );
  const [invDueDate, setInvDueDate] = useState<string>(
    String(p.dueDate || new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10))
  );
  const [invCurrency, setInvCurrency] = useState<string>(String(p.currency || "USD"));
  const [invNotes, setInvNotes] = useState<string>(String(p.notes || ""));
  const [invIssueImmediately, setInvIssueImmediately] = useState<boolean>(false);

  // Budget state
  const [budName, setBudName] = useState<string>(String(p.name || ""));
  const [budAmount, setBudAmount] = useState<string>(String(p.amount ?? ""));
  const [budCategoryId, setBudCategoryId] = useState<string>(String(p.categoryId || ""));
  const [budPeriod, setBudPeriod] = useState<string>(String(p.periodType || "MONTHLY"));
  const [budAlert, setBudAlert] = useState<string>(String(p.alertThresholdPercent ?? 80));

  useEffect(() => {
    if (draft.actionType === "CREATE_TRANSACTION" || draft.actionType === "CREATE_BUDGET") {
      CategoryService.getCategories().then(setCategories).catch(() => {});
    } else if (draft.actionType === "CREATE_INVOICE") {
      CustomerService.getCustomers({ page: 0, size: 100 })
        .then((res) => setCustomers(res.content || []))
        .catch(() => {});
    }
  }, [draft.actionType]);

  useEffect(() => {
    if (!draft.stagedAttachmentId || draft.status !== "PENDING") return;
    let active = true;
    let url: string | null = null;
    AiService.fetchAttachmentPreviewUrl(draft.stagedAttachmentId)
      .then((u) => {
        if (!active) {
          URL.revokeObjectURL(u);
          return;
        }
        url = u;
        setReceiptPreviewUrl(u);
      })
      .catch(() => {});
    return () => {
      active = false;
      if (url) URL.revokeObjectURL(url);
    };
  }, [draft.stagedAttachmentId, draft.status]);

  if (draft.status === "APPROVED") {
    return (
      <div className="rounded-2xl border border-emerald-500/30 bg-emerald-500/[0.08] px-4 py-3 flex items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-2 min-w-0">
          <CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" />
          <div className="min-w-0">
            <p className="font-bold text-emerald-800 dark:text-emerald-300 truncate">
              {t("savedBadge")} · {draft.title}
            </p>
            <p className="text-[11px] text-emerald-700/80 dark:text-emerald-400/80 truncate">
              {draft.summary}
            </p>
          </div>
        </div>
        {draft.createdEntityHref && (
          <Link
            href={draft.createdEntityHref}
            className="inline-flex items-center gap-1 rounded-xl border border-emerald-500/30 bg-[var(--card)] px-2.5 py-1.5 font-semibold text-emerald-600 dark:text-emerald-400 hover:bg-emerald-500/10 shrink-0"
          >
            <span>{t("viewRecord")}</span>
            <ArrowUpRight className="h-3.5 w-3.5" />
          </Link>
        )}
      </div>
    );
  }

  if (draft.status === "DISMISSED") {
    return (
      <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-[var(--surface-inset)] px-3.5 py-2 text-[11px] text-gray-400 dark:text-gray-500 flex items-center justify-between">
        <span>
          {t("dismissedBadge")} · {draft.title}
        </span>
      </div>
    );
  }

  const handleDismiss = async () => {
    if (dismissing || saving) return;
    setDismissing(true);
    try {
      const updated = await AiService.dismissDraft(messageId, draft.draftId);
      onUpdated(updated);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : t("dismissFailed"));
    } finally {
      setDismissing(false);
    }
  };

  const handleApprove = async () => {
    if (saving) return;
    setSaving(true);
    try {
      let updated: AiActionDraft;
      if (draft.actionType === "CREATE_TRANSACTION") {
        const numeric = Number(txAmount);
        if (!Number.isFinite(numeric) || numeric <= 0) {
          toast.error(t("invalidAmount"));
          return;
        }
        updated = await AiService.approveTransactionDraft({
          messageId,
          draftId: draft.draftId,
          type: txType,
          amount: numeric,
          originalCurrency: txCurrency.toUpperCase(),
          description: txDesc.trim() || "Transaction",
          transactionDate: txDate,
          categoryId: txCategoryId || null,
          paymentMethod: txMethod,
          status: "COMPLETED",
          notes: txNotes,
          stagedAttachmentId: draft.stagedAttachmentId || null,
          extractedOcrText: typeof p.extractedOcrText === "string" ? p.extractedOcrText : undefined,
        });
      } else if (draft.actionType === "CREATE_INVOICE") {
        const rawItems = Array.isArray(p.items) ? p.items : [];
        const items = rawItems.map((it: Record<string, unknown>) => ({
          description: String(it.description || "Services"),
          quantity: Number(it.quantity ?? 1),
          unitPrice: Number(it.unitPrice ?? 0),
          taxRate: Number(it.taxRate ?? 0),
        }));
        updated = await AiService.approveInvoiceDraft({
          messageId,
          draftId: draft.draftId,
          customerId: invCustomerId || null,
          issueDate: invIssueDate,
          dueDate: invDueDate,
          currency: invCurrency.toUpperCase(),
          discountAmount: Number(p.discountAmount ?? 0),
          notes: invNotes,
          issueImmediately: invIssueImmediately,
          items,
        });
      } else {
        const numeric = Number(budAmount);
        if (!Number.isFinite(numeric) || numeric <= 0) {
          toast.error(t("invalidAmount"));
          return;
        }
        updated = await AiService.approveBudgetDraft({
          messageId,
          draftId: draft.draftId,
          name: budName.trim() || "Budget",
          amount: numeric,
          categoryId: budCategoryId || null,
          periodType: budPeriod,
          alertThresholdPercent: Number(budAlert) || 80,
        });
      }
      toast.success(t("approvedToast"));
      onUpdated(updated);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : t("approveFailed"));
    } finally {
      setSaving(false);
    }
  };

  const filteredCategories = categories.filter((c) =>
    draft.actionType === "CREATE_BUDGET" ? c.type === "EXPENSE" : c.type === txType
  );
  const rawInvItems = Array.isArray(p.items) ? (p.items as Array<Record<string, unknown>>) : [];

  return (
    <div className="rounded-2xl border border-[var(--primary)]/30 bg-[var(--surface-inset)] p-4 space-y-3 shadow-xs">
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0">
          <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-[var(--primary)]/15 text-[var(--primary)]">
            <ShieldAlert className="h-4 w-4" />
          </span>
          <div className="min-w-0">
            <div className="flex items-center gap-1.5 flex-wrap">
              <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-600 dark:text-amber-400">
                {t("pendingReview")}
              </span>
              <h4 className="text-xs font-bold text-gray-900 dark:text-white truncate">
                {draft.title}
              </h4>
            </div>
            <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5">
              {t("reviewHint")}
            </p>
          </div>
        </div>
        <button
          type="button"
          onClick={handleDismiss}
          disabled={dismissing || saving}
          className="p-1 rounded-lg text-gray-400 hover:bg-red-500/10 hover:text-red-500"
          title={t("dismiss")}
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </div>

      {receiptPreviewUrl && (
        <div className="flex items-center gap-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-[var(--card)] p-2">
          <img
            src={receiptPreviewUrl}
            alt="Staged receipt"
            className="h-12 w-12 rounded-lg object-cover border border-gray-200 dark:border-gray-700 shrink-0"
          />
          <div className="min-w-0 text-[11px]">
            <p className="font-semibold text-gray-800 dark:text-gray-200 flex items-center gap-1">
              <Receipt className="h-3.5 w-3.5 text-[var(--primary)]" />
              <span>{t("receiptLinked")}</span>
            </p>
            <p className="text-gray-500 dark:text-gray-400 truncate">
              {t("receiptWillSave")}
            </p>
          </div>
        </div>
      )}

      {draft.actionType === "CREATE_TRANSACTION" && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs">
          <div>
            <label className="afab-label text-[10.5px]">{t("type")}</label>
            <select
              value={txType}
              onChange={(e) => setTxType(e.target.value)}
              className="afab-input py-1.5 text-xs"
            >
              <option value="EXPENSE">EXPENSE</option>
              <option value="INCOME">INCOME</option>
            </select>
          </div>
          <div className="grid grid-cols-3 gap-1.5">
            <div className="col-span-2">
              <label className="afab-label text-[10.5px]">{t("amount")}</label>
              <input
                type="number"
                step="0.01"
                value={txAmount}
                onChange={(e) => setTxAmount(e.target.value)}
                className="afab-input py-1.5 text-xs"
              />
            </div>
            <div>
              <label className="afab-label text-[10.5px]">{t("currency")}</label>
              <input
                type="text"
                maxLength={3}
                value={txCurrency}
                onChange={(e) => setTxCurrency(e.target.value.toUpperCase())}
                className="afab-input py-1.5 text-xs font-mono uppercase"
              />
            </div>
          </div>
          <div className="sm:col-span-2">
            <label className="afab-label text-[10.5px]">{t("description")}</label>
            <input
              type="text"
              value={txDesc}
              onChange={(e) => setTxDesc(e.target.value)}
              className="afab-input py-1.5 text-xs"
            />
          </div>
          <div>
            <label className="afab-label text-[10.5px]">{t("date")}</label>
            <input
              type="date"
              value={txDate}
              onChange={(e) => setTxDate(e.target.value)}
              className="afab-input py-1.5 text-xs"
            />
          </div>
          <div>
            <label className="afab-label text-[10.5px]">{t("category")}</label>
            <select
              value={txCategoryId}
              onChange={(e) => setTxCategoryId(e.target.value)}
              className="afab-input py-1.5 text-xs"
            >
              <option value="">Uncategorized</option>
              {filteredCategories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="afab-label text-[10.5px]">{t("paymentMethod")}</label>
            <select
              value={txMethod}
              onChange={(e) => setTxMethod(e.target.value)}
              className="afab-input py-1.5 text-xs"
            >
              <option value="CASH">CASH</option>
              <option value="CARD">CARD</option>
              <option value="BANK_TRANSFER">BANK_TRANSFER</option>
              <option value="OTHER">OTHER</option>
            </select>
          </div>
          <div>
            <label className="afab-label text-[10.5px]">{t("notes")}</label>
            <input
              type="text"
              value={txNotes}
              onChange={(e) => setTxNotes(e.target.value)}
              className="afab-input py-1.5 text-xs"
            />
          </div>
        </div>
      )}

      {draft.actionType === "CREATE_INVOICE" && (
        <div className="space-y-2.5 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
            <div>
              <label className="afab-label text-[10.5px]">{t("customer")}</label>
              <select
                value={invCustomerId}
                onChange={(e) => setInvCustomerId(e.target.value)}
                className="afab-input py-1.5 text-xs"
              >
                <option value="">{String(p.customerName || "Walk-in / Unassigned")}</option>
                {customers.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="afab-label text-[10.5px]">{t("issueDate")}</label>
              <input
                type="date"
                value={invIssueDate}
                onChange={(e) => setInvIssueDate(e.target.value)}
                className="afab-input py-1.5 text-xs"
              />
            </div>
            <div>
              <label className="afab-label text-[10.5px]">{t("dueDate")}</label>
              <input
                type="date"
                value={invDueDate}
                onChange={(e) => setInvDueDate(e.target.value)}
                className="afab-input py-1.5 text-xs"
              />
            </div>
          </div>
          <div className="rounded-xl border border-gray-200/80 dark:border-gray-800 bg-[var(--card)] p-2.5 space-y-1">
            {rawInvItems.map((it, idx) => (
              <div key={idx} className="flex items-center justify-between gap-2 text-[11px]">
                <span className="truncate font-medium text-gray-800 dark:text-gray-200">
                  {String(it.description)} × {String(it.quantity ?? 1)}
                </span>
                <span className="font-mono font-semibold text-gray-900 dark:text-white shrink-0">
                  {formatCurrency(Number(it.unitPrice ?? 0) * Number(it.quantity ?? 1), invCurrency)}
                </span>
              </div>
            ))}
            <div className="pt-1.5 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between text-xs font-bold">
              <span>{t("total")}</span>
              <span className="text-[var(--primary)]">
                {formatCurrency(Number(p.totalAmount ?? 0), invCurrency)}
              </span>
            </div>
          </div>
          <div className="flex items-center justify-between gap-2 flex-wrap">
            <label className="inline-flex items-center gap-1.5 text-[11px] text-gray-600 dark:text-gray-300 cursor-pointer">
              <input
                type="checkbox"
                checked={invIssueImmediately}
                onChange={(e) => setInvIssueImmediately(e.target.checked)}
                className="rounded border-gray-300 text-[var(--primary)]"
              />
              <span>{t("issueImmediately")}</span>
            </label>
            <input
              type="text"
              value={invNotes}
              onChange={(e) => setInvNotes(e.target.value)}
              placeholder={t("notes")}
              className="afab-input py-1 text-xs max-w-xs"
            />
          </div>
        </div>
      )}

      {draft.actionType === "CREATE_BUDGET" && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs">
          <div>
            <label className="afab-label text-[10.5px]">{t("budgetName")}</label>
            <input
              type="text"
              value={budName}
              onChange={(e) => setBudName(e.target.value)}
              className="afab-input py-1.5 text-xs"
            />
          </div>
          <div>
            <label className="afab-label text-[10.5px]">{t("amount")}</label>
            <input
              type="number"
              step="0.01"
              value={budAmount}
              onChange={(e) => setBudAmount(e.target.value)}
              className="afab-input py-1.5 text-xs"
            />
          </div>
          <div>
            <label className="afab-label text-[10.5px]">{t("category")}</label>
            <select
              value={budCategoryId}
              onChange={(e) => setBudCategoryId(e.target.value)}
              className="afab-input py-1.5 text-xs"
            >
              <option value="">Overall Business Expenses</option>
              {filteredCategories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-1.5">
            <div>
              <label className="afab-label text-[10.5px]">{t("period")}</label>
              <select
                value={budPeriod}
                onChange={(e) => setBudPeriod(e.target.value)}
                className="afab-input py-1.5 text-xs"
              >
                <option value="MONTHLY">MONTHLY</option>
                <option value="QUARTERLY">QUARTERLY</option>
                <option value="YEARLY">YEARLY</option>
              </select>
            </div>
            <div>
              <label className="afab-label text-[10.5px]">{t("alertPct")}</label>
              <input
                type="number"
                min={10}
                max={100}
                value={budAlert}
                onChange={(e) => setBudAlert(e.target.value)}
                className="afab-input py-1.5 text-xs"
              />
            </div>
          </div>
        </div>
      )}

      <div className="flex items-center justify-end gap-2 pt-1">
        <button
          type="button"
          onClick={handleDismiss}
          disabled={dismissing || saving}
          className="afab-btn-secondary px-3 py-1.5 text-xs"
        >
          {t("dismiss")}
        </button>
        <button
          type="button"
          onClick={handleApprove}
          disabled={saving || dismissing}
          className="afab-btn-primary px-3.5 py-1.5 text-xs"
        >
          {saving ? (
            <>
              <Loader2 className="h-3.5 w-3.5 animate-spin" />
              <span>{t("saving")}</span>
            </>
          ) : (
            <>
              <CheckCircle2 className="h-3.5 w-3.5" />
              <span>{t("approveSave")}</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
}
