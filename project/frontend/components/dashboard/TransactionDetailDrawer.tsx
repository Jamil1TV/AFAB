"use client";

import { useEffect } from "react";
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
  FileText
} from "lucide-react";
import { TransactionItem } from "@/lib/api/transactions";
import { formatCurrency } from "@/lib/currency";
import { useTranslations } from "next-intl";

interface TransactionDetailDrawerProps {
  transaction: TransactionItem | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit: (tx: TransactionItem) => void;
  onDuplicate: (tx: TransactionItem) => void;
  onDelete: (tx: TransactionItem) => void;
  currency?: string;
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
  const t = useTranslations("Transactions");

  // Close on Escape key
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

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="absolute inset-0" onClick={onClose} />

      <div className="fixed inset-y-0 right-0 flex max-w-full pl-10">
        <div className="w-screen max-w-md transform transition ease-in-out duration-300 bg-white dark:bg-[#0c101c] border-l border-gray-200 dark:border-gray-800 shadow-2xl flex flex-col justify-between">
          {/* Header */}
          <div className="p-6 border-b border-gray-100 dark:border-gray-800/80">
            <div className="flex items-center justify-between pb-3">
              <span className="text-xs font-semibold tracking-wider text-gray-400 uppercase">
                Transaction Details
              </span>
              <button
                onClick={onClose}
                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Type & Status Badges */}
            <div className="flex items-center gap-2 mb-3">
              <span
                className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold tracking-wide uppercase border ${
                  isExpense
                    ? "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20"
                    : "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
                }`}
              >
                {isExpense ? (
                  <ArrowDownLeft className="h-3 w-3" />
                ) : (
                  <ArrowUpRight className="h-3 w-3" />
                )}
                {transaction.type}
              </span>

              <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-gray-700">
                {transaction.status}
              </span>

              {transaction.taxDeductible && (
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-teal-500/10 text-teal-600 dark:text-teal-400 border border-teal-500/20">
                  <ShieldCheck className="h-3 w-3" />
                  Tax Write-off
                </span>
              )}
            </div>

            {/* Hero Amount */}
            <div className="mt-2">
              <div
                className={`text-3xl font-extrabold tracking-tight ${
                  isExpense
                    ? "text-rose-600 dark:text-rose-400"
                    : "text-emerald-600 dark:text-emerald-400"
                }`}
              >
                {isExpense ? "-" : "+"}
                {formatCurrency(transaction.amount, transaction.currency || currency)}
              </div>
              <p className="mt-1 text-sm font-medium text-gray-800 dark:text-gray-200">
                {transaction.description}
              </p>
            </div>
          </div>

          {/* Drawer Body */}
          <div className="flex-1 overflow-y-auto p-6 space-y-6">
            {/* Anomaly / Duplicate Warnings */}
            {transaction.potentialDuplicate && (
              <div className="p-3.5 rounded-2xl bg-amber-500/10 border border-amber-500/25 flex items-start gap-3 text-amber-600 dark:text-amber-400">
                <AlertTriangle className="h-5 w-5 shrink-0 mt-0.5" />
                <div className="text-xs">
                  <span className="font-bold block">Potential Duplicate Charge</span>
                  Another transaction with the same amount and description was detected within 48 hours.
                </div>
              </div>
            )}

            {transaction.priceHikePercentage && transaction.priceHikePercentage > 0 && (
              <div className="p-3.5 rounded-2xl bg-indigo-500/10 border border-indigo-500/25 flex items-start gap-3 text-indigo-600 dark:text-indigo-400">
                <TrendingUp className="h-5 w-5 shrink-0 mt-0.5" />
                <div className="text-xs">
                  <span className="font-bold block">Price Increase Detected (+{transaction.priceHikePercentage}%)</span>
                  This recurring vendor cost is higher than previous billing cycles.
                </div>
              </div>
            )}

            {/* Meta Attributes Grid */}
            <div className="rounded-2xl border border-gray-100 dark:border-gray-800/80 bg-gray-50/50 dark:bg-white/[0.02] p-4 space-y-3.5">
              {/* Category */}
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                  <Tag className="h-3.5 w-3.5" /> Category
                </span>
                <span className="font-semibold text-gray-900 dark:text-white flex items-center gap-1.5">
                  <span
                    className="w-2 h-2 rounded-full"
                    style={{ backgroundColor: transaction.categoryColor || "#8b5cf6" }}
                  />
                  {transaction.categoryName || "Uncategorized"}
                </span>
              </div>

              {/* Date */}
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                  <Calendar className="h-3.5 w-3.5" /> Date
                </span>
                <span className="font-semibold text-gray-900 dark:text-white">
                  {transaction.transactionDate}
                </span>
              </div>

              {/* Payment Method */}
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                  <CreditCard className="h-3.5 w-3.5" /> Payment Method
                </span>
                <span className="font-semibold text-gray-900 dark:text-white">
                  {transaction.paymentMethod?.replace("_", " ") || "CARD"}
                </span>
              </div>

              {/* Tax Rate if deductible */}
              {transaction.taxDeductible && transaction.taxRate && (
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                    <ShieldCheck className="h-3.5 w-3.5" /> Tax / VAT Rate
                  </span>
                  <span className="font-semibold text-teal-600 dark:text-teal-400">
                    {transaction.taxRate}%
                  </span>
                </div>
              )}
            </div>

            {/* Split Breakdown */}
            {transaction.isSplit && transaction.splitItems && transaction.splitItems.length > 0 && (
              <div>
                <h4 className="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                  <Layers className="h-3.5 w-3.5 text-[#8b5cf6]" /> Split Allocation
                </h4>
                <div className="space-y-2">
                  {transaction.splitItems.map((item, idx) => (
                    <div
                      key={item.id || idx}
                      className="p-3 rounded-xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-[#101424] flex items-center justify-between text-xs"
                    >
                      <div className="flex items-center gap-2">
                        <span
                          className="w-2 h-2 rounded-full"
                          style={{ backgroundColor: item.categoryColor || "#8b5cf6" }}
                        />
                        <div>
                          <p className="font-semibold text-gray-900 dark:text-white">
                            {item.categoryName}
                          </p>
                          {item.description && (
                            <p className="text-[11px] text-gray-400">{item.description}</p>
                          )}
                        </div>
                      </div>
                      <span className="font-bold text-gray-900 dark:text-white">
                        {formatCurrency(item.amount, transaction.currency || currency)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Notes Section */}
            {transaction.notes && (
              <div>
                <h4 className="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                  <FileText className="h-3.5 w-3.5 text-gray-400" /> Notes & Context
                </h4>
                <div className="p-3.5 rounded-2xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.02] text-xs text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
                  {transaction.notes}
                </div>
              </div>
            )}

            {/* Audit Trail */}
            <div className="pt-2 border-t border-gray-100 dark:border-gray-800/60 text-[11px] text-gray-400 space-y-1">
              <div className="flex items-center gap-1">
                <Clock className="h-3 w-3" />
                <span>Transaction ID: <span className="font-mono text-[10px]">{transaction.id}</span></span>
              </div>
              {transaction.createdAt && (
                <div>Created: {new Date(transaction.createdAt).toLocaleString()}</div>
              )}
            </div>
          </div>

          {/* Footer Action Buttons */}
          <div className="p-4 border-t border-gray-100 dark:border-gray-800/80 bg-gray-50/50 dark:bg-[#080c18] flex items-center justify-between gap-2">
            <button
              onClick={() => onDuplicate(transaction)}
              className="flex-1 py-2.5 px-3 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#101424] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex items-center justify-center gap-1.5"
            >
              <Copy className="h-3.5 w-3.5" /> Duplicate
            </button>
            <button
              onClick={() => onEdit(transaction)}
              className="flex-1 py-2.5 px-3 rounded-xl bg-[#8b5cf6] text-white text-xs font-bold hover:bg-[#7c3aed] transition-colors flex items-center justify-center gap-1.5 shadow-md shadow-[#8b5cf6]/20"
            >
              <Pencil className="h-3.5 w-3.5" /> Edit
            </button>
            <button
              onClick={() => onDelete(transaction)}
              className="p-2.5 rounded-xl border border-rose-200 dark:border-rose-900/50 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-500/10 transition-colors"
              title="Delete transaction"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
