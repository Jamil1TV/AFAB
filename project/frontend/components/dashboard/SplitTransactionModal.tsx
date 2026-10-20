"use client";

import { useState } from "react";
import { X, Plus, Trash2, Layers, Check, AlertCircle } from "lucide-react";
import { CategoryItem, TransactionItem, TransactionService } from "@/lib/api/transactions";
import { formatCurrency } from "@/lib/currency";
import { useTranslations } from "next-intl";

interface SplitLine {
  id: string;
  categoryId: string;
  amount: string;
  description: string;
}

interface SplitTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  categories: CategoryItem[];
  currency?: string;
  initialTransaction?: TransactionItem | null;
}

export function SplitTransactionModal({
  isOpen,
  onClose,
  onSuccess,
  categories,
  currency = "USD",
  initialTransaction = null,
}: SplitTransactionModalProps) {
  const t = useTranslations("Transactions");

  const [totalAmount, setTotalAmount] = useState(
    initialTransaction ? initialTransaction.amount.toString() : ""
  );
  const [description, setDescription] = useState(
    initialTransaction ? initialTransaction.description : ""
  );
  const [type, setType] = useState<"INCOME" | "EXPENSE">(
    initialTransaction ? initialTransaction.type : "EXPENSE"
  );
  const [transactionDate, setTransactionDate] = useState(
    initialTransaction ? initialTransaction.transactionDate : new Date().toISOString().split("T")[0]
  );
  const [paymentMethod, setPaymentMethod] = useState(
    initialTransaction?.paymentMethod || "CARD"
  );

  const availableCategories = categories.filter((c) => c.type === type);

  const [lines, setLines] = useState<SplitLine[]>([
    {
      id: "1",
      categoryId: availableCategories[0]?.id || "",
      amount: "",
      description: "Line item 1",
    },
    {
      id: "2",
      categoryId: availableCategories[1]?.id || availableCategories[0]?.id || "",
      amount: "",
      description: "Line item 2",
    },
  ]);

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const totalNum = parseFloat(totalAmount) || 0;
  const allocatedSum = lines.reduce((sum, line) => {
    const val = parseFloat(line.amount) || 0;
    return sum + val;
  }, 0);
  const remaining = Math.round((totalNum - allocatedSum) * 100) / 100;
  const isBalanced = totalNum > 0 && Math.abs(remaining) < 0.001;

  const handleAddLine = () => {
    setLines((prev) => [
      ...prev,
      {
        id: Date.now().toString(),
        categoryId: availableCategories[0]?.id || "",
        amount: remaining > 0 ? remaining.toFixed(2) : "",
        description: `Line item ${prev.length + 1}`,
      },
    ]);
  };

  const handleRemoveLine = (id: string) => {
    if (lines.length <= 2) {
      setError("A split transaction must have at least 2 lines.");
      return;
    }
    setLines((prev) => prev.filter((l) => l.id !== id));
  };

  const handleLineChange = (id: string, field: keyof SplitLine, value: string) => {
    setLines((prev) =>
      prev.map((l) => (l.id === id ? { ...l, [field]: value } : l))
    );
  };

  const handleFillRemaining = (id: string) => {
    const currentVal = parseFloat(lines.find((l) => l.id === id)?.amount || "0") || 0;
    const target = currentVal + remaining;
    if (target > 0) {
      handleLineChange(id, "amount", target.toFixed(2));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim() || totalNum <= 0) {
      setError("Please provide a valid overall description and positive total amount.");
      return;
    }
    if (!isBalanced) {
      setError(`All lines must sum to ${formatCurrency(totalNum, currency)}. Remaining unallocated: ${formatCurrency(remaining, currency)}.`);
      return;
    }
    for (const line of lines) {
      if (!line.categoryId) {
        setError("Please choose a category for every split line.");
        return;
      }
      const amt = parseFloat(line.amount);
      if (isNaN(amt) || amt <= 0) {
        setError("Every line must have a positive allocated amount.");
        return;
      }
    }

    setSubmitting(true);
    setError(null);

    try {
      await TransactionService.createTransaction({
        type,
        amount: totalNum,
        description: description.trim(),
        transactionDate,
        paymentMethod,
        splitItems: lines.map((l) => ({
          categoryId: l.categoryId,
          amount: parseFloat(l.amount),
          description: l.description.trim() || undefined,
        })),
      });

      onSuccess();
      onClose();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Failed to create split transaction";
      setError(message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div 
        className="relative w-full max-w-2xl overflow-hidden rounded-3xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] p-6 sm:p-8 shadow-2xl transition-all"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 pb-4 mb-6">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-500/10 text-[#8b5cf6] border border-purple-500/20">
              <Layers className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                Split Transaction
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Allocate a single payment across multiple categories and cost centers
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg p-2 text-gray-400 hover:text-gray-600 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && (
          <div className="mb-4 rounded-xl bg-rose-500/10 border border-rose-500/20 p-3 text-xs text-rose-500 flex items-center gap-2">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Parent Details Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 p-4 rounded-2xl bg-gray-50/50 dark:bg-white/[0.02] border border-gray-100 dark:border-gray-800/80">
            <div>
              <label className="text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider block mb-1">
                Total Amount ({currency})
              </label>
              <input
                type="number"
                step="0.01"
                required
                value={totalAmount}
                onChange={(e) => setTotalAmount(e.target.value)}
                placeholder="1000.00"
                className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#101424] px-3 py-2 text-sm font-bold text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none"
              />
            </div>
            <div>
              <label className="text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider block mb-1">
                Vendor / Master Description
              </label>
              <input
                type="text"
                required
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Amazon, Office Depot, etc."
                className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#101424] px-3 py-2 text-sm text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none"
              />
            </div>
            <div>
              <label className="text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider block mb-1">
                Date
              </label>
              <input
                type="date"
                required
                value={transactionDate}
                onChange={(e) => setTransactionDate(e.target.value)}
                className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#101424] px-3 py-2 text-sm text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none"
              />
            </div>
          </div>

          {/* Allocation Lines */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                Split Lines ({lines.length})
              </span>
              <button
                type="button"
                onClick={handleAddLine}
                className="text-xs font-bold text-[#8b5cf6] hover:text-[#7c3aed] flex items-center gap-1 transition-colors"
              >
                <Plus className="h-3.5 w-3.5" /> Add Line
              </button>
            </div>

            <div className="space-y-2.5 max-h-56 overflow-y-auto pr-1">
              {lines.map((line, idx) => (
                <div
                  key={line.id}
                  className="p-3 rounded-2xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-[#101424] flex items-center gap-2.5"
                >
                  <span className="text-xs font-mono text-gray-400 w-4 text-center">
                    {idx + 1}
                  </span>

                  {/* Category Select */}
                  <select
                    value={line.categoryId}
                    onChange={(e) => handleLineChange(line.id, "categoryId", e.target.value)}
                    className="flex-1 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#0c101c] px-3 py-1.5 text-xs text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none"
                  >
                    {availableCategories.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.name}
                      </option>
                    ))}
                  </select>

                  {/* Line Description */}
                  <input
                    type="text"
                    value={line.description}
                    onChange={(e) => handleLineChange(line.id, "description", e.target.value)}
                    placeholder="Memo (optional)"
                    className="flex-1 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#0c101c] px-3 py-1.5 text-xs text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none"
                  />

                  {/* Amount Input */}
                  <div className="relative w-28">
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={line.amount}
                      onChange={(e) => handleLineChange(line.id, "amount", e.target.value)}
                      placeholder="0.00"
                      className="w-full rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#0c101c] px-2.5 py-1.5 text-xs font-bold text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none text-right"
                    />
                  </div>

                  {/* Auto-fill button if remaining */}
                  {remaining !== 0 && (
                    <button
                      type="button"
                      onClick={() => handleFillRemaining(line.id)}
                      title="Adjust line to balance remaining amount"
                      className="px-2 py-1 rounded-lg text-[10px] font-bold text-[#8b5cf6] bg-purple-500/10 hover:bg-purple-500/20 transition-colors shrink-0"
                    >
                      Fill
                    </button>
                  )}

                  {/* Delete Line */}
                  <button
                    type="button"
                    onClick={() => handleRemoveLine(line.id)}
                    className="p-1.5 text-gray-400 hover:text-rose-500 transition-colors shrink-0"
                    title="Remove line"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Allocation Balance Summary Bar */}
          <div className="p-3.5 rounded-2xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.02] flex items-center justify-between text-xs">
            <div className="flex items-center gap-4">
              <div>
                <span className="text-gray-400 block text-[10px] uppercase">Total</span>
                <span className="font-bold text-gray-900 dark:text-white">
                  {formatCurrency(totalNum, currency)}
                </span>
              </div>
              <div>
                <span className="text-gray-400 block text-[10px] uppercase">Allocated</span>
                <span className="font-bold text-[#8b5cf6]">
                  {formatCurrency(allocatedSum, currency)}
                </span>
              </div>
            </div>

            <div>
              <span className="text-gray-400 block text-[10px] uppercase text-right">
                Remaining Balance
              </span>
              <div className="flex items-center gap-1.5 font-bold">
                {isBalanced ? (
                  <span className="text-emerald-500 flex items-center gap-1">
                    <Check className="h-4 w-4" /> Balanced ($0.00)
                  </span>
                ) : (
                  <span className="text-rose-500">
                    {formatCurrency(remaining, currency)}
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-3 pt-3 border-t border-gray-100 dark:border-gray-800/60">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2.5 rounded-xl text-xs font-bold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting || !isBalanced}
              className="px-6 py-2.5 rounded-xl text-xs font-bold bg-[#8b5cf6] text-white hover:bg-[#7c3aed] disabled:opacity-50 transition-all shadow-lg shadow-[#8b5cf6]/25"
            >
              {submitting ? "Saving Split..." : "Confirm Split Transaction"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
