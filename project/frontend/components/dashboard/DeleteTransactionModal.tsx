"use client";

import { AlertTriangle, X } from "lucide-react";
import { TransactionItem } from "@/lib/api/transactions";
import { formatCurrency } from "@/lib/currency";
import { useTranslations } from "next-intl";

interface DeleteTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  transaction: TransactionItem | null;
  deleting: boolean;
  currency?: string;
}

export function DeleteTransactionModal({
  isOpen,
  onClose,
  onConfirm,
  transaction,
  deleting,
  currency = "USD",
}: DeleteTransactionModalProps) {
  const t = useTranslations("Transactions.deleteModal");

  if (!isOpen || !transaction) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div
        className="relative w-full max-w-md overflow-hidden rounded-3xl border border-red-500/20 bg-white dark:bg-[#0c101c] p-6 shadow-2xl transition-all"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={onClose}
          disabled={deleting}
          className="absolute top-4 end-4 flex h-8 w-8 items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-white/[0.05] dark:hover:text-white transition-colors"
        >
          <X className="h-4 w-4" />
        </button>

        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-red-100 dark:bg-red-500/10 text-red-600 dark:text-red-400">
            <AlertTriangle className="h-6 w-6" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {t("title")}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {transaction.transactionDate}
            </p>
          </div>
        </div>

        <p className="mt-4 text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
          {t("confirmMessage")}
        </p>

        {/* Transaction Summary Card */}
        <div className="mt-4 rounded-2xl bg-gray-50 dark:bg-[#080c18] border border-gray-100 dark:border-gray-800/60 p-4 flex items-center justify-between">
          <div className="min-w-0 pr-3">
            <p className="text-xs font-semibold text-gray-900 dark:text-white truncate">
              {transaction.description}
            </p>
            <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5">
              {transaction.categoryName || "Uncategorized"} • {transaction.type}
            </p>
          </div>
          <span
            className={`text-sm font-bold shrink-0 ${
              transaction.type === "INCOME"
                ? "text-emerald-500"
                : "text-red-500"
            }`}
          >
            {transaction.type === "INCOME" ? "+" : "-"}
            {formatCurrency(transaction.amount, currency)}
          </span>
        </div>

        {/* Actions */}
        <div className="mt-6 flex items-center justify-end gap-3">
          <button
            type="button"
            onClick={onClose}
            disabled={deleting}
            className="px-4 py-2.5 rounded-xl text-xs font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
          >
            {t("cancelBtn")}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={deleting}
            className="px-5 py-2.5 rounded-xl text-xs font-bold bg-red-600 hover:bg-red-700 text-white disabled:opacity-50 transition-all shadow-md shadow-red-600/20"
          >
            {deleting ? t("deleting") : t("confirmBtn")}
          </button>
        </div>
      </div>
    </div>
  );
}
