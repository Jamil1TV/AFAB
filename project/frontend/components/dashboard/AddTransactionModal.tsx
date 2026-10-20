"use client";

import { useState } from "react";
import { X, Calendar, Tag, CreditCard, ArrowUpRight, ArrowDownLeft } from "lucide-react";
import { CategoryItem, TransactionItem, TransactionService } from "@/lib/api/transactions";
import { useTranslations } from "next-intl";

interface AddTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  categories: CategoryItem[];
  currency?: string;
  transactionToEdit?: TransactionItem | null;
}

type FormModalProps = Omit<AddTransactionModalProps, "isOpen">;

function TransactionFormModal({
  onClose,
  onSuccess,
  categories,
  currency = "USD",
  transactionToEdit = null,
}: FormModalProps) {
  const tModal = useTranslations("Transactions.modal");

  const [type, setType] = useState<"INCOME" | "EXPENSE">(transactionToEdit?.type || "EXPENSE");
  const [description, setDescription] = useState(transactionToEdit?.description || "");
  const [amount, setAmount] = useState(transactionToEdit ? transactionToEdit.amount.toString() : "");
  const [categoryId, setCategoryId] = useState(transactionToEdit?.categoryId || "");
  const [transactionDate, setTransactionDate] = useState(
    transactionToEdit?.transactionDate || new Date().toISOString().split("T")[0]
  );
  const [paymentMethod, setPaymentMethod] = useState(transactionToEdit?.paymentMethod || "BANK_TRANSFER");
  const [notes, setNotes] = useState(transactionToEdit?.notes || "");
  const [taxDeductible, setTaxDeductible] = useState(transactionToEdit?.taxDeductible || false);
  const [taxRate, setTaxRate] = useState(transactionToEdit?.taxRate ? transactionToEdit.taxRate.toString() : "");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const filteredCategories = categories.filter(
    (c) => c.type.toUpperCase() === type.toUpperCase()
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim() || !amount || parseFloat(amount) <= 0) {
      setError("Please enter a valid description and positive amount.");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const payload = {
        type,
        amount: parseFloat(amount),
        description: description.trim(),
        transactionDate,
        categoryId: categoryId || undefined,
        paymentMethod,
        notes: notes.trim() || undefined,
        taxDeductible,
        taxRate: taxRate ? parseFloat(taxRate) : undefined,
      };

      if (transactionToEdit) {
        await TransactionService.updateTransaction(transactionToEdit.id, payload);
      } else {
        await TransactionService.createTransaction(payload);
      }

      onSuccess();
      onClose();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Failed to save transaction.";
      setError(message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div 
        className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 sm:p-8 shadow-2xl transition-all"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 pb-4">
          <div>
            <h2 className="text-xl font-bold tracking-tight text-gray-900 dark:text-white">
              {transactionToEdit ? tModal("editTitle") : tModal("title")}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {transactionToEdit ? tModal("editSubtitle") : tModal("subtitle")}
            </p>
          </div>
          <button
            onClick={onClose}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-white/[0.05] dark:hover:text-white transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="mt-6 space-y-5">
          {error && (
            <div className="rounded-xl bg-red-50 dark:bg-red-500/10 p-3 text-xs font-medium text-red-600 dark:text-red-400 border border-red-200 dark:border-red-500/20">
              {error}
            </div>
          )}

          {/* Type Toggle Tabs */}
          <div className="grid grid-cols-2 gap-2 p-1.5 bg-gray-100 dark:bg-[#080c18] rounded-2xl border border-gray-200/50 dark:border-gray-800/60">
            <button
              type="button"
              onClick={() => {
                setType("INCOME");
                setCategoryId("");
              }}
              className={`flex items-center justify-center gap-2 py-2.5 rounded-xl text-xs font-bold transition-all ${
                type === "INCOME"
                  ? "bg-emerald-500 text-white shadow-md shadow-emerald-500/20"
                  : "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              }`}
            >
              <ArrowUpRight className="h-4 w-4" />
              {tModal("incomeTab")}
            </button>
            <button
              type="button"
              onClick={() => {
                setType("EXPENSE");
                setCategoryId("");
              }}
              className={`flex items-center justify-center gap-2 py-2.5 rounded-xl text-xs font-bold transition-all ${
                type === "EXPENSE"
                  ? "bg-purple-600 text-white shadow-md shadow-purple-600/20"
                  : "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              }`}
            >
              <ArrowDownLeft className="h-4 w-4" />
              {tModal("expenseTab")}
            </button>
          </div>

          {/* Description Input */}
          <div>
            <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
              {tModal("descriptionLabel")} *
            </label>
            <input
              type="text"
              required
              maxLength={255}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder={tModal("descriptionPlaceholder")}
              className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
            />
          </div>

          {/* Amount & Date Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                {tModal("amountLabel")} *
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 start-0 flex items-center ps-3.5 text-xs font-bold text-gray-500 dark:text-gray-400">
                  {currency === "QAR" ? "QAR" : currency === "AED" ? "AED" : currency === "SAR" ? "SAR" : currency === "EUR" ? "€" : currency === "GBP" ? "£" : "$"}
                </div>
                <input
                  type="number"
                  step="any"
                  min="0.0001"
                  required
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder={tModal("amountPlaceholder")}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] ps-12 pe-4 py-2.5 text-sm font-semibold text-gray-900 dark:text-white placeholder-gray-400 focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                {tModal("dateLabel")} *
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 start-0 flex items-center ps-3.5 text-gray-400">
                  <Calendar className="h-4 w-4" />
                </div>
                <input
                  type="date"
                  required
                  value={transactionDate}
                  onChange={(e) => setTransactionDate(e.target.value)}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] ps-9 pe-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
                />
              </div>
            </div>
          </div>

          {/* Category & Payment Method Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                {tModal("categoryLabel")}
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 start-0 flex items-center ps-3.5 text-gray-400">
                  <Tag className="h-4 w-4" />
                </div>
                <select
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  className="w-full appearance-none rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] ps-9 pe-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
                >
                  <option value="">{tModal("selectCategory")}</option>
                  {filteredCategories.map((cat) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                {tModal("methodLabel")}
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 start-0 flex items-center ps-3.5 text-gray-400">
                  <CreditCard className="h-4 w-4" />
                </div>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value)}
                  className="w-full appearance-none rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] ps-9 pe-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
                >
                  <option value="BANK_TRANSFER">{tModal("bankTransfer")}</option>
                  <option value="CARD">{tModal("card")}</option>
                  <option value="CASH">{tModal("cash")}</option>
                  <option value="OTHER">{tModal("other")}</option>
                </select>
              </div>
            </div>
          </div>

          {/* Notes Input */}
          <div>
            <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
              {tModal("notesLabel")}
            </label>
            <input
              type="text"
              maxLength={1000}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={tModal("notesPlaceholder")}
              className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
            />
          </div>

          {/* Tax Deductible Toggle */}
          <div className="p-3.5 rounded-2xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.02] flex items-center justify-between">
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={taxDeductible}
                onChange={(e) => setTaxDeductible(e.target.checked)}
                className="w-4 h-4 rounded text-[#8b5cf6] focus:ring-[#8b5cf6] border-gray-300 dark:border-gray-700"
              />
              <span className="text-xs font-semibold text-gray-800 dark:text-gray-200">
                Tax Deductible Business Expense
              </span>
            </label>
            {taxDeductible && (
              <div className="flex items-center gap-1.5">
                <span className="text-[11px] text-gray-400">VAT / Tax %</span>
                <input
                  type="number"
                  step="0.1"
                  value={taxRate}
                  onChange={(e) => setTaxRate(e.target.value)}
                  placeholder="e.g. 19"
                  className="w-20 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#0c101c] px-2 py-1 text-xs text-right text-gray-900 dark:text-white"
                />
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-800/60">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2.5 rounded-xl text-xs font-bold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
            >
              {tModal("cancel")}
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-6 py-2.5 rounded-xl text-xs font-bold bg-[#8b5cf6] text-white hover:bg-[#7c3aed] disabled:opacity-50 transition-all shadow-lg shadow-[#8b5cf6]/25"
            >
              {submitting ? tModal("saving") : (transactionToEdit ? tModal("updateSubmit") : tModal("submit"))}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function AddTransactionModal(props: AddTransactionModalProps) {
  if (!props.isOpen) return null;
  return (
    <TransactionFormModal
      key={props.transactionToEdit ? props.transactionToEdit.id : "new"}
      {...props}
    />
  );
}
