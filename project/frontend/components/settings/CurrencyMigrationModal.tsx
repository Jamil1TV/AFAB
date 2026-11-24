"use client";

import React, { useState, useEffect } from "react";
import { useTranslations } from "next-intl";
import { 
  ArrowRightLeft, 
  Coins, 
  CheckCircle2, 
  AlertCircle, 
  RefreshCw, 
  ShieldCheck, 
  X 
} from "lucide-react";
import { CurrencyService, CurrencyChangePreview } from "@/lib/api/currencies";

interface CurrencyMigrationModalProps {
  isOpen: boolean;
  oldCurrency: string;
  newCurrency: string;
  onClose: () => void;
  onSuccess: (newCurrency: string, convertedCount: number) => void;
}

export function CurrencyMigrationModal({
  isOpen,
  oldCurrency,
  newCurrency,
  onClose,
  onSuccess,
}: CurrencyMigrationModalProps) {
  const t = useTranslations("Currencies.migrationModal");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [preview, setPreview] = useState<CurrencyChangePreview | null>(null);
  // Historical transactions are immutable — never overwritten with today's rate.
  const convertExisting = false;

  useEffect(() => {
    if (!isOpen || !newCurrency || oldCurrency === newCurrency) return;

    let isMounted = true;
    CurrencyService.previewChange(newCurrency)
      .then((data) => {
        if (isMounted) {
          setPreview(data);
          setError(null);
          setLoading(false);
        }
      })
      .catch((err) => {
        if (isMounted) {
          console.error("Failed to load currency change preview:", err);
          setError("Failed to fetch live exchange rate preview. Please try again.");
          setLoading(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, [isOpen, oldCurrency, newCurrency]);

  if (!isOpen) return null;

  const handleConfirm = async () => {
    try {
      setSubmitting(true);
      setError(null);
      const res = await CurrencyService.changeBusinessCurrency(newCurrency, convertExisting);
      setSubmitting(false);
      onSuccess(newCurrency, res.convertedTransactionsCount);
      onClose();
    } catch (err: unknown) {
      console.error("Failed to update base currency:", err);
      const msg = err instanceof Error ? err.message : "Failed to update business currency. Please try again.";
      setError(msg);
      setSubmitting(false);
    }
  };

  const rate = preview?.exchangeRate ?? 1.0;
  const oldBalance = preview?.currentNetBalance ?? 0;
  const projectedBalance = preview?.projectedNetBalance ?? (oldBalance * rate);
  const count = preview?.transactionsCount ?? 0;

  return (
    <div className="afab-overlay animate-in fade-in duration-200">
      <div 
        className="afab-modal max-w-xl !p-0 transition-all duration-300"
        role="dialog"
        aria-modal="true"
      >
        {/* Modal Header */}
        <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--primary)]/10 text-[var(--primary-hover)] dark:text-[var(--primary)]">
              <ArrowRightLeft className="h-5 w-5" />
            </div>
            <div>
              <h3 className="afab-card-title">
                {t("title")}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {t("subtitle")}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={submitting}
            className="afab-icon-btn"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 space-y-5 max-h-[80vh] overflow-y-auto custom-scrollbar">
          {error && (
            <div className="flex items-start gap-3 rounded-xl bg-red-500/10 border border-red-500/20 p-3.5 text-sm text-red-600 dark:text-red-400">
              <AlertCircle className="h-5 w-5 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {loading ? (
            <div className="flex flex-col items-center justify-center py-12 space-y-3">
              <RefreshCw className="h-8 w-8 text-[var(--primary)] animate-spin" />
              <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                Fetching real-time market exchange rate...
              </p>
            </div>
          ) : (
            <>
              {/* Currency Migration Flow Indicator */}
              <div className="afab-inset flex flex-wrap items-center justify-between gap-3 p-4">
                <div className="flex flex-col">
                  <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">From</span>
                  <span className="text-xl font-bold text-gray-900 dark:text-white tracking-tight">{oldCurrency}</span>
                </div>
                <div className="flex flex-col items-center px-2">
                  <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[var(--primary)] text-white text-xs font-bold shadow-sm">
                    <span>1 {oldCurrency} = {rate.toFixed(4)} {newCurrency}</span>
                  </div>
                  <span className="text-[10px] text-[var(--primary-hover)] dark:text-[var(--primary)] font-medium mt-1 flex items-center gap-1">
                    <span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                    Live Market Rate
                  </span>
                </div>
                <div className="flex flex-col items-end">
                  <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">To</span>
                  <span className="text-xl font-bold text-[var(--primary-hover)] dark:text-[var(--primary)] tracking-tight">{newCurrency}</span>
                </div>
              </div>

              {/* Balance Conversion Card */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="afab-inset p-3.5">
                  <span className="text-xs text-gray-500 dark:text-gray-400 block mb-1">
                    {t("currentBalance")}
                  </span>
                  <span className="text-lg font-bold text-gray-900 dark:text-white">
                    {oldBalance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {oldCurrency}
                  </span>
                </div>

                <div className="p-3.5 rounded-2xl border border-[var(--primary)]/30 bg-[var(--primary)]/5 dark:bg-[var(--primary)]/10">
                  <span className="text-xs text-[var(--primary-hover)] dark:text-[var(--primary)] font-medium block mb-1">
                    {t("projectedBalance")}
                  </span>
                  <span className="text-lg font-bold text-[var(--primary-hover)] dark:text-[var(--primary)]">
                    {projectedBalance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {newCurrency}
                  </span>
                </div>
              </div>

              {/* Transactions count badge */}
              <div className="afab-inset flex items-center justify-between text-xs px-3.5 py-2.5 text-gray-600 dark:text-gray-300">
                <span className="flex items-center gap-1.5 font-medium">
                  <Coins className="h-4 w-4 text-[var(--primary)]" />
                  {t("transactionsAffected")}:
                </span>
                <span className="afab-badge afab-badge-neutral">
                  {count} transaction{count === 1 ? "" : "s"}
                </span>
              </div>

              {/* Historical Immutability Policy Notice */}
              <div className="rounded-2xl border border-[var(--primary)]/30 bg-[var(--primary)]/5 dark:bg-[var(--primary)]/10 p-4 space-y-1.5">
                <div className="flex items-center gap-2">
                  <ShieldCheck className="h-4 w-4 text-emerald-500 shrink-0" />
                  <span className="text-sm font-bold text-gray-900 dark:text-white">
                    Historical Financial Immutability Enforced
                  </span>
                </div>
                <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
                  Updating your business base currency to <strong>{newCurrency}</strong> applies to all future transactions.
                  All <strong>{count}</strong> existing historical transaction(s) will preserve their original amounts and locked historical exchange rates — past ledgers are never overwritten with today&apos;s rate.
                </p>
              </div>
            </>
          )}
        </div>

        {/* Modal Actions */}
        <div className="flex flex-wrap items-center justify-end gap-3 border-t border-gray-100 dark:border-gray-800/60 px-6 py-4 bg-gray-50/50 dark:bg-[#080c18]">
          <button
            type="button"
            onClick={onClose}
            disabled={submitting}
            className="afab-btn-secondary"
          >
            {t("cancel")}
          </button>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={loading || submitting}
            className="afab-btn-primary"
          >
            {submitting ? (
              <>
                <RefreshCw className="h-4 w-4 animate-spin" />
                <span>Converting...</span>
              </>
            ) : (
              <>
                <CheckCircle2 className="h-4 w-4" />
                <span>{t("confirm")}</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
