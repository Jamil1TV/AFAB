"use client";

import { useState, useMemo, useRef, useEffect } from "react";
import { Sparkles, ArrowRight, Check, Tag, Calendar, CreditCard, ShieldCheck } from "lucide-react";
import { CategoryItem, TransactionService } from "@/lib/api/transactions";
import { parseNaturalLanguageTransaction } from "@/lib/nlp-transaction-parser";
import { useTranslations } from "next-intl";

interface QuickAddBarProps {
  categories: CategoryItem[];
  currency?: string;
  onSuccess: () => void;
}

export function QuickAddBar({ categories, currency = "USD", onSuccess }: QuickAddBarProps) {
  const t = useTranslations("Transactions");
  const [input, setInput] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [justAdded, setJustAdded] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Live NLP Parsing
  const parsed = useMemo(() => {
    return parseNaturalLanguageTransaction(input, categories);
  }, [input, categories]);

  // Global keyboard shortcut: Press 'N' to focus quick-add bar when not in another input
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (
        (e.key === "n" || e.key === "N") &&
        !["INPUT", "TEXTAREA", "SELECT"].includes((e.target as HTMLElement).tagName) &&
        !e.metaKey &&
        !e.ctrlKey
      ) {
        e.preventDefault();
        inputRef.current?.focus();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!input.trim() || !parsed.amount || parsed.amount <= 0) {
      setError("Please include an amount, e.g. 'Paid $45 to Figma'");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      await TransactionService.createTransaction({
        type: parsed.type,
        amount: parsed.amount,
        description: parsed.description,
        transactionDate: parsed.transactionDate,
        categoryId: parsed.categoryId,
        paymentMethod: parsed.paymentMethod,
        taxDeductible: parsed.taxDeductible,
      });

      setInput("");
      setJustAdded(true);
      setTimeout(() => setJustAdded(false), 3000);
      onSuccess();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Failed to record transaction";
      setError(message);
    } finally {
      setSubmitting(false);
    }
  };

  const hasContent = input.trim().length > 0;

  return (
    <div className="relative group w-full rounded-2xl p-[1px] bg-gradient-to-r from-purple-500/20 via-indigo-500/10 to-purple-500/20 hover:from-purple-500/40 hover:to-indigo-500/30 transition-all duration-300">
      <div className="relative rounded-[15px] bg-white/95 dark:bg-[#0c101c]/95 backdrop-blur-xl border border-purple-500/15 dark:border-purple-500/20 p-3 sm:p-4 shadow-xl shadow-purple-500/5">
        <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
          {/* Magic Icon & Input */}
          <div className="relative flex-1 flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-purple-500/10 text-[#8b5cf6] border border-purple-500/20">
              <Sparkles className="h-4 w-4 animate-pulse" />
            </div>
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => {
                setInput(e.target.value);
                if (error) setError(null);
              }}
              placeholder="Magic Quick-Add: 'Paid $120 to Figma yesterday via card' or 'Received $1,500 from Client'..."
              className="w-full bg-transparent text-sm sm:text-base font-medium text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none"
            />
          </div>

          {/* Action Button & Key Hint */}
          <div className="flex items-center justify-end gap-2 shrink-0">
            <kbd className="hidden sm:inline-flex items-center gap-1 px-2 py-1 text-[10px] font-semibold tracking-wider text-gray-400 bg-gray-100 dark:bg-gray-800/80 rounded-md border border-gray-200 dark:border-gray-700">
              Press <span className="text-[#8b5cf6]">N</span> to focus
            </kbd>
            <button
              type="submit"
              disabled={submitting || !parsed.amount}
              className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 shadow-md ${
                parsed.amount
                  ? "bg-[#8b5cf6] hover:bg-[#7c3aed] text-white shadow-[#8b5cf6]/25"
                  : "bg-gray-100 dark:bg-gray-800/50 text-gray-400 cursor-not-allowed"
              }`}
            >
              {justAdded ? (
                <>
                  <Check className="h-3.5 w-3.5 text-emerald-400" />
                  <span>Added!</span>
                </>
              ) : (
                <>
                  <span>Quick Add</span>
                  <ArrowRight className="h-3.5 w-3.5" />
                </>
              )}
            </button>
          </div>
        </form>

        {/* Live Natural Language Entity Preview Chips */}
        {hasContent && (
          <div className="mt-3 pt-3 border-t border-gray-100 dark:border-gray-800/60 flex flex-wrap items-center gap-2 animate-in fade-in slide-in-from-top-1 duration-200 text-xs">
            <span className="text-[11px] font-medium text-gray-400">Parsed as:</span>

            {/* Type Chip */}
            <span
              className={`px-2 py-0.5 rounded-full font-bold text-[10px] uppercase tracking-wide border ${
                parsed.type === "INCOME"
                  ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
                  : "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20"
              }`}
            >
              {parsed.type}
            </span>

            {/* Amount Chip */}
            {parsed.amount ? (
              <span className="px-2 py-0.5 rounded-lg bg-gray-100 dark:bg-gray-800 font-bold text-gray-900 dark:text-white border border-gray-200 dark:border-gray-700">
                {parsed.type === "EXPENSE" ? "-" : "+"}
                {currency} {parsed.amount.toFixed(2)}
              </span>
            ) : (
              <span className="px-2 py-0.5 rounded-lg bg-amber-500/10 text-amber-500 border border-amber-500/20 italic">
                Awaiting amount...
              </span>
            )}

            {/* Description Chip */}
            {parsed.description && (
              <span className="px-2 py-0.5 rounded-lg bg-purple-500/10 text-[#8b5cf6] border border-purple-500/20 font-medium">
                &ldquo;{parsed.description}&rdquo;
              </span>
            )}

            {/* Category Chip */}
            {parsed.categoryName ? (
              <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700">
                <span
                  className="w-1.5 h-1.5 rounded-full"
                  style={{ backgroundColor: parsed.categoryColor || "#8b5cf6" }}
                />
                <Tag className="h-3 w-3 text-gray-400" />
                <span>{parsed.categoryName}</span>
              </span>
            ) : (
              <span className="text-[10px] text-gray-400 italic">No category matched</span>
            )}

            {/* Date Chip */}
            <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 border border-gray-200 dark:border-gray-700">
              <Calendar className="h-3 w-3" />
              <span>{parsed.transactionDate}</span>
            </span>

            {/* Payment Method */}
            <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 border border-gray-200 dark:border-gray-700">
              <CreditCard className="h-3 w-3" />
              <span>{parsed.paymentMethod.replace("_", " ")}</span>
            </span>

            {/* Tax Deductible Tag */}
            {parsed.taxDeductible && (
              <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg bg-teal-500/10 text-teal-600 dark:text-teal-400 border border-teal-500/20 font-semibold">
                <ShieldCheck className="h-3 w-3" />
                <span>Tax Deductible</span>
              </span>
            )}
          </div>
        )}

        {/* Error Notification */}
        {error && (
          <div className="mt-2 text-xs font-semibold text-rose-500">
            {error}
          </div>
        )}
      </div>
    </div>
  );
}
