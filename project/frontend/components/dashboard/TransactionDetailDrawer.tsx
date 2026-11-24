"use client";

import { useEffect, useState, useRef } from "react";
import {
  X,
  ArrowUpRight,
  ArrowDownLeft,
  Tag,
  Calendar,
  CreditCard,
  AlertTriangle,
  TrendingUp,
  ShieldCheck,
  Clock,
  Copy,
  Pencil,
  Trash2,
  Layers,
  FileText,
  Paperclip,
  Upload,
  Download,
  Globe,
  Loader2,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { TransactionItem } from "@/lib/api/transactions";
import { ReceiptApi, ReceiptItem } from "@/lib/api/receipts";
import { formatCurrency } from "@/lib/currency";
import { toast } from "sonner";

interface TransactionDetailDrawerProps {
  transaction: TransactionItem | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit: (tx: TransactionItem) => void;
  onDuplicate: (tx: TransactionItem) => void;
  onDelete: (tx: TransactionItem) => void;
  currency?: string;
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

export function TransactionDetailDrawer({
  transaction,
  isOpen,
  onClose,
  onEdit,
  onDuplicate,
  onDelete,
  currency = "USD",
}: TransactionDetailDrawerProps) {
  const t = useTranslations("Transactions.drawer");
  const [receipts, setReceipts] = useState<ReceiptItem[]>([]);
  const [loadingReceipts, setLoadingReceipts] = useState(false);
  const [uploadingReceipt, setUploadingReceipt] = useState(false);
  const [receiptError, setReceiptError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const txId = isOpen ? transaction?.id : undefined;

  useEffect(() => {
    if (!txId) return;
    let active = true;
    ReceiptApi.listForTransaction(txId)
      .then((list) => {
        if (!active) return;
        setReceipts(list);
        setReceiptError(null);
      })
      .catch((err: unknown) => {
        if (!active) return;
        setReceiptError(err instanceof Error ? err.message : "Failed to load receipts");
      })
      .finally(() => {
        if (active) setLoadingReceipts(false);
      });
    return () => {
      active = false;
    };
  }, [txId]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen || !transaction) return null;

  const isExpense = transaction.type === "EXPENSE";
  const baseCurr = transaction.baseCurrency || transaction.currency || currency;
  const origCurr = transaction.originalCurrency;
  const hasForeignFx = Boolean(origCurr && origCurr !== baseCurr && transaction.exchangeRate != null);

  const handleReceiptUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !transaction.id) return;
    e.target.value = "";

    const allowed = ["application/pdf", "image/jpeg", "image/png", "image/webp"];
    if (file.type && !allowed.includes(file.type)) {
      toast.error(t("invalidReceiptType"));
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      toast.error(t("receiptTooLarge"));
      return;
    }

    setUploadingReceipt(true);
    setReceiptError(null);
    try {
      const uploaded = await ReceiptApi.upload(transaction.id, file);
      setReceipts((prev) => [uploaded, ...prev]);
      toast.success(t("receiptUploaded"));
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Receipt upload failed";
      setReceiptError(msg);
      toast.error(msg);
    } finally {
      setUploadingReceipt(false);
    }
  };

  const handleDownloadReceipt = async (receipt: ReceiptItem) => {
    try {
      await ReceiptApi.downloadFile(receipt.id, receipt.originalFilename);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to download receipt");
    }
  };

  const handleDeleteReceipt = async (receiptId: string) => {
    try {
      await ReceiptApi.delete(receiptId);
      setReceipts((prev) => prev.filter((r) => r.id !== receiptId));
      toast.success(t("receiptDeleted"));
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to delete receipt");
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="absolute inset-0" onClick={onClose} />

      <div className="fixed inset-y-0 end-0 flex max-w-full ps-6 sm:ps-10">
        <div className="w-screen max-w-md transform transition ease-in-out duration-300 bg-white dark:bg-[#0c101c] border-s border-gray-200 dark:border-gray-800 shadow-2xl flex flex-col justify-between">
          {/* Header */}
          <div className="p-5 sm:p-6 border-b border-gray-200/80 dark:border-gray-800/80">
            <div className="flex items-center justify-between pb-3">
              <span className="text-xs font-semibold tracking-wider text-gray-500 dark:text-gray-400 uppercase">
                {t("title")}
              </span>
              <button
                onClick={onClose}
                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Type & Status Badges */}
            <div className="flex items-center flex-wrap gap-2 mb-3">
              <span
                className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold tracking-wide uppercase border ${
                  isExpense
                    ? "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20"
                    : "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
                }`}
              >
                {isExpense ? <ArrowDownLeft className="h-3 w-3" /> : <ArrowUpRight className="h-3 w-3" />}
                {transaction.type}
              </span>

              <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700">
                {transaction.status}
              </span>

              {transaction.taxDeductible && (
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-teal-500/10 text-teal-600 dark:text-teal-400 border border-teal-500/20">
                  <ShieldCheck className="h-3 w-3" />
                  {t("taxWriteOff")}
                </span>
              )}
            </div>

            {/* Hero Amount */}
            <div className="mt-2">
              <div
                className={`text-2xl sm:text-3xl font-bold tracking-tight ${
                  isExpense ? "text-rose-600 dark:text-rose-400" : "text-emerald-600 dark:text-emerald-400"
                }`}
              >
                {isExpense ? "-" : "+"}
                {formatCurrency(transaction.amount, baseCurr)}
              </div>
              {hasForeignFx && transaction.originalAmount != null && origCurr && (
                <p className="mt-1 text-xs text-indigo-600 dark:text-indigo-400 font-medium flex items-center gap-1 flex-wrap">
                  <Globe className="h-3.5 w-3.5 shrink-0" />
                  <span>
                    {t("original")}: {formatCurrency(transaction.originalAmount, origCurr)} @{" "}
                    {transaction.exchangeRate} {origCurr}/{baseCurr}
                  </span>
                </p>
              )}
              <p className="mt-1 text-sm font-medium text-gray-800 dark:text-gray-200 break-words">
                {transaction.description}
              </p>
            </div>
          </div>

          {/* Drawer Body */}
          <div className="flex-1 overflow-y-auto p-5 sm:p-6 space-y-6">
            {transaction.potentialDuplicate && (
              <div className="p-3.5 rounded-2xl bg-amber-500/10 border border-amber-500/25 flex items-start gap-3 text-amber-700 dark:text-amber-400">
                <AlertTriangle className="h-5 w-5 shrink-0 mt-0.5" />
                <div className="text-xs">
                  <span className="font-bold block">{t("potentialDuplicate")}</span>
                  {t("potentialDuplicateDesc")}
                </div>
              </div>
            )}

            {transaction.priceHikePercentage && transaction.priceHikePercentage > 0 && (
              <div className="p-3.5 rounded-2xl bg-indigo-500/10 border border-indigo-500/25 flex items-start gap-3 text-indigo-700 dark:text-indigo-400">
                <TrendingUp className="h-5 w-5 shrink-0 mt-0.5" />
                <div className="text-xs">
                  <span className="font-bold block">
                    {t("priceIncrease", { pct: transaction.priceHikePercentage })}
                  </span>
                  {t("priceIncreaseDesc")}
                </div>
              </div>
            )}

            {/* Meta Attributes Grid */}
            <div className="rounded-2xl border border-gray-200/80 dark:border-gray-800/80 bg-gray-50/80 dark:bg-white/[0.02] p-4 space-y-3.5">
              <div className="flex items-center justify-between gap-2 text-xs">
                <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                  <Tag className="h-3.5 w-3.5" /> {t("category")}
                </span>
                <span className="font-semibold text-gray-900 dark:text-white flex items-center gap-1.5">
                  <span
                    className="w-2 h-2 rounded-full"
                    style={{ backgroundColor: transaction.categoryColor || "var(--primary)" }}
                  />
                  {transaction.categoryName || t("uncategorized")}
                </span>
              </div>

              <div className="flex items-center justify-between gap-2 text-xs">
                <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                  <Calendar className="h-3.5 w-3.5" /> {t("date")}
                </span>
                <span className="font-semibold text-gray-900 dark:text-white">{transaction.transactionDate}</span>
              </div>

              <div className="flex items-center justify-between gap-2 text-xs">
                <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                  <CreditCard className="h-3.5 w-3.5" /> {t("paymentMethod")}
                </span>
                <span className="font-semibold text-gray-900 dark:text-white">
                  {transaction.paymentMethod?.replace("_", " ") || "CARD"}
                </span>
              </div>

              <div className="flex items-center justify-between gap-2 text-xs">
                <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                  <Globe className="h-3.5 w-3.5" /> {t("fxSnapshot")}
                </span>
                <span className="font-semibold text-gray-900 dark:text-white text-end">
                  {transaction.legacyFx
                    ? t("legacyFx", { currency: baseCurr })
                    : `${origCurr || baseCurr} → ${baseCurr} (${transaction.fxRateSource || "IDENTITY"})`}
                </span>
              </div>

              {transaction.taxDeductible && transaction.taxRate && (
                <div className="flex items-center justify-between gap-2 text-xs">
                  <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                    <ShieldCheck className="h-3.5 w-3.5" /> {t("taxRate")}
                  </span>
                  <span className="font-semibold text-teal-600 dark:text-teal-400">{transaction.taxRate}%</span>
                </div>
              )}
            </div>

            {/* Private Receipts Section */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider flex items-center gap-1.5">
                  <Paperclip className="h-3.5 w-3.5 text-[var(--primary)]" /> {t("receipts")} ({receipts.length})
                </h4>
                <button
                  type="button"
                  disabled={uploadingReceipt}
                  onClick={() => fileInputRef.current?.click()}
                  className="inline-flex items-center gap-1 text-xs font-semibold text-[var(--primary-hover)] dark:text-[var(--primary)] hover:underline disabled:opacity-50"
                >
                  {uploadingReceipt ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  ) : (
                    <Upload className="h-3.5 w-3.5" />
                  )}
                  {uploadingReceipt ? t("uploading") : t("attachReceipt")}
                </button>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="application/pdf,image/jpeg,image/png,image/webp"
                  onChange={handleReceiptUpload}
                  className="hidden"
                />
              </div>

              {receiptError && (
                <div className="mb-2 rounded-xl border border-rose-500/30 bg-rose-500/10 px-3 py-2 text-xs text-rose-600 dark:text-rose-400">
                  {receiptError}
                </div>
              )}

              {loadingReceipts ? (
                <div className="p-3 rounded-xl border border-gray-200 dark:border-gray-800 text-xs text-gray-500 dark:text-gray-400 flex items-center gap-2">
                  <Loader2 className="h-3.5 w-3.5 animate-spin" /> {t("loadingReceipts")}
                </div>
              ) : receipts.length === 0 ? (
                <div className="p-3.5 rounded-xl border border-dashed border-gray-300 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.01] text-xs text-gray-500 dark:text-gray-400 text-center">
                  {t("noReceipts")}
                </div>
              ) : (
                <div className="space-y-2">
                  {receipts.map((r) => (
                    <div
                      key={r.id}
                      className="p-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/80 dark:bg-white/[0.02] flex items-center justify-between gap-2 text-xs"
                    >
                      <div className="min-w-0">
                        <p className="font-semibold text-gray-900 dark:text-white truncate">{r.originalFilename}</p>
                        <p className="text-[11px] text-gray-500 dark:text-gray-400">
                          {r.contentType} • {formatBytes(r.fileSizeBytes)}
                        </p>
                      </div>
                      <div className="flex items-center gap-1 shrink-0">
                        <button
                          type="button"
                          onClick={() => handleDownloadReceipt(r)}
                          title={t("downloadReceipt")}
                          className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-[var(--primary-hover)] dark:hover:text-[var(--primary)] hover:bg-[var(--primary)]/10 transition-colors"
                        >
                          <Download className="h-3.5 w-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDeleteReceipt(r.id)}
                          title={t("deleteReceipt")}
                          className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-rose-600 dark:hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {transaction.isSplit && transaction.splitItems && transaction.splitItems.length > 0 && (
              <div>
                <h4 className="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                  <Layers className="h-3.5 w-3.5 text-[var(--primary)]" /> {t("splitAllocation")}
                </h4>
                <div className="space-y-2">
                  {transaction.splitItems.map((item, idx) => (
                    <div
                      key={item.id || idx}
                      className="p-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#080c18] flex items-center justify-between text-xs"
                    >
                      <div className="flex items-center gap-2 min-w-0">
                        <span
                          className="w-2 h-2 rounded-full shrink-0"
                          style={{ backgroundColor: item.categoryColor || "var(--primary)" }}
                        />
                        <div className="min-w-0">
                          <p className="font-semibold text-gray-900 dark:text-white truncate">{item.categoryName}</p>
                          {item.description && (
                            <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate">{item.description}</p>
                          )}
                        </div>
                      </div>
                      <span className="font-bold text-gray-900 dark:text-white shrink-0">
                        {formatCurrency(item.amount, baseCurr)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {transaction.notes && (
              <div>
                <h4 className="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                  <FileText className="h-3.5 w-3.5 text-gray-400" /> {t("notesTitle")}
                </h4>
                <div className="p-3.5 rounded-2xl border border-gray-200 dark:border-gray-800 bg-gray-50/70 dark:bg-white/[0.02] text-xs text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
                  {transaction.notes}
                </div>
              </div>
            )}

            <div className="pt-2 border-t border-gray-200/80 dark:border-gray-800/60 text-[11px] text-gray-500 dark:text-gray-400 space-y-1">
              <div className="flex items-center gap-1">
                <Clock className="h-3 w-3 shrink-0" />
                <span className="truncate">
                  {t("transactionId")}: <span className="font-mono text-[10px]">{transaction.id}</span>
                </span>
              </div>
              {transaction.createdAt && (
                <div>
                  {t("created")}: {new Date(transaction.createdAt).toLocaleString()}
                </div>
              )}
            </div>
          </div>

          {/* Footer Action Buttons */}
          <div className="p-4 border-t border-gray-200/80 dark:border-gray-800/80 bg-gray-50 dark:bg-[#080c18] flex items-center justify-between gap-2">
            <button
              onClick={() => onDuplicate(transaction)}
              className="flex-1 py-2.5 px-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors flex items-center justify-center gap-1.5"
            >
              <Copy className="h-3.5 w-3.5" /> {t("duplicate")}
            </button>
            <button
              onClick={() => onEdit(transaction)}
              className="flex-1 py-2.5 px-3 rounded-xl bg-[var(--primary)] text-white text-xs font-bold hover:bg-[var(--primary-hover)] transition-colors flex items-center justify-center gap-1.5 shadow-md shadow-[var(--primary)]/20"
            >
              <Pencil className="h-3.5 w-3.5" /> {t("edit")}
            </button>
            <button
              onClick={() => onDelete(transaction)}
              className="p-2.5 rounded-xl border border-rose-200 dark:border-rose-900/50 text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-500/10 transition-colors"
              title={t("deleteTooltip")}
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
