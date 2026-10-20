"use client";

import React, { useState, useEffect } from "react";
import { useTranslations } from "next-intl";
import { 
  ArrowRightLeft, 
  Coins, 
  CheckCircle2, 
  AlertCircle, 
  RefreshCw, 
  ArrowRight, 
  ShieldCheck, 
  TrendingUp,
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
  const [convertExisting, setConvertExisting] = useState<boolean>(true);

  useEffect(() => {
    if (!isOpen || !newCurrency || oldCurrency === newCurrency) return;

    let isMounted = true;
    setLoading(true);
    setError(null);

    CurrencyService.previewChange(newCurrency)
      .then((data) => {
        if (isMounted) {
          setPreview(data);
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
    } catch (err: any) {
      console.error("Failed to update base currency:", err);
      setError(err?.message || "Failed to update business currency. Please try again.");
      setSubmitting(false);
    }
  };

  const rate = preview?.exchangeRate ?? 1.0;
  const oldBalance = preview?.currentNetBalance ?? 0;
  const projectedBalance = preview?.projectedNetBalance ?? (oldBalance * rate);
  const count = preview?.transactionsCount ?? 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div 
        className="relative w-full max-w-xl rounded-2xl bg-white dark:bg-[#111827] border border-gray-200 dark:border-gray-800 shadow-2xl overflow-hidden transition-all duration-300"
        role="dialog"
        aria-modal="true"
      >
        {/* Modal Header */}
        <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/80 px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400">
              <ArrowRightLeft className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">
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
            className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 space-y-5 max-h-[80vh] overflow-y-auto">
          {error && (
            <div className="flex items-start gap-3 rounded-xl bg-red-500/10 border border-red-500/20 p-3.5 text-sm text-red-600 dark:text-red-400">
              <AlertCircle className="h-5 w-5 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {loading ? (
            <div className="flex flex-col items-center justify-center py-12 space-y-3">
              <RefreshCw className="h-8 w-8 text-purple-500 animate-spin" />
              <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                Fetching real-time market exchange rate...
              </p>
            </div>
          ) : (
            <>
              {/* Currency Migration Flow Indicator */}
              <div className="flex items-center justify-between p-4 rounded-xl bg-gradient-to-r from-purple-50 via-indigo-50/50 to-blue-50 dark:from-purple-950/20 dark:via-indigo-950/20 dark:to-blue-950/20 border border-purple-100 dark:border-purple-900/30">
                <div className="flex flex-col">
                  <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">From</span>
                  <span className="text-xl font-black text-gray-900 dark:text-white tracking-tight">{oldCurrency}</span>
                </div>
                <div className="flex flex-col items-center px-4">
                  <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-purple-600 text-white text-xs font-bold shadow-sm">
                    <span>1 {oldCurrency} = {rate.toFixed(4)} {newCurrency}</span>
                  </div>
                  <span className="text-[10px] text-purple-600 dark:text-purple-400 font-medium mt-1 flex items-center gap-1">
                    <span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                    Live Market Rate
                  </span>
                </div>
                <div className="flex flex-col items-end">
                  <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">To</span>
                  <span className="text-xl font-black text-purple-600 dark:text-purple-400 tracking-tight">{newCurrency}</span>
                </div>
              </div>

              {/* Balance Conversion Card */}
              <div className="grid grid-cols-2 gap-3">
                <div className="p-3.5 rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/60 dark:bg-gray-900/50">
                  <span className="text-xs text-gray-500 dark:text-gray-400 block mb-1">
                    {t("currentBalance")}
                  </span>
                  <span className="text-lg font-bold text-gray-800 dark:text-gray-200">
                    {oldBalance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {oldCurrency}
                  </span>
                </div>

                <div className="p-3.5 rounded-xl border border-purple-200 dark:border-purple-900/40 bg-purple-50/40 dark:bg-purple-950/20">
                  <span className="text-xs text-purple-600 dark:text-purple-400 font-medium block mb-1">
                    {t("projectedBalance")}
                  </span>
                  <span className="text-lg font-bold text-purple-700 dark:text-purple-300">
                    {projectedBalance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {newCurrency}
                  </span>
                </div>
              </div>

              {/* Transactions count badge */}
              <div className="flex items-center justify-between text-xs px-3 py-2 rounded-lg bg-gray-100/70 dark:bg-gray-800/60 text-gray-600 dark:text-gray-300">
                <span className="flex items-center gap-1.5 font-medium">
                  <Coins className="h-4 w-4 text-purple-500" />
                  {t("transactionsAffected")}:
                </span>
                <span className="font-bold text-gray-900 dark:text-white bg-white dark:bg-gray-700 px-2 py-0.5 rounded shadow-xs">
                  {count} transaction{count === 1 ? "" : "s"}
                </span>
              </div>

              {/* Options selection */}
              <div className="space-y-3 pt-1">
                <label className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                  {t("optionsTitle")}
                </label>

                {/* Option 1: Convert all transactions (Recommended) */}
                <div
                  onClick={() => setConvertExisting(true)}
                  className={`cursor-pointer rounded-xl border p-4 transition-all duration-200 ${
                    convertExisting
                      ? "border-purple-600 bg-purple-50/50 dark:border-purple-500 dark:bg-purple-950/30 shadow-xs"
                      : "border-gray-200 dark:border-gray-800 hover:border-gray-300 dark:hover:border-gray-700"
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <input
                      type="radio"
                      checked={convertExisting}
                      onChange={() => setConvertExisting(true)}
                      className="mt-1 h-4 w-4 text-purple-600 focus:ring-purple-500"
                    />
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-bold text-gray-900 dark:text-white">
                          {t("optionConvert", { rate: rate.toFixed(4) })}
                        </span>
                        <span className="rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 text-[10px] font-bold px-2 py-0.5 border border-emerald-500/20">
                          Recommended
                        </span>
                      </div>
                      <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
                        {t("optionConvertDesc")}
                      </p>
                    </div>
                  </div>
                </div>

                {/* Option 2: Keep numbers as-is */}
                <div
                  onClick={() => setConvertExisting(false)}
                  className={`cursor-pointer rounded-xl border p-4 transition-all duration-200 ${
                    !convertExisting
                      ? "border-purple-600 bg-purple-50/50 dark:border-purple-500 dark:bg-purple-950/30 shadow-xs"
                      : "border-gray-200 dark:border-gray-800 hover:border-gray-300 dark:hover:border-gray-700"
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <input
                      type="radio"
                      checked={!convertExisting}
                      onChange={() => setConvertExisting(false)}
                      className="mt-1 h-4 w-4 text-purple-600 focus:ring-purple-500"
                    />
                    <div className="space-y-1">
                      <span className="text-sm font-bold text-gray-900 dark:text-white">
                        {t("optionKeep")}
                      </span>
                      <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
                        {t("optionKeepDesc")}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Safety notice */}
              <div className="flex items-center gap-2 pt-1 text-[11px] text-gray-500 dark:text-gray-400">
                <ShieldCheck className="h-4 w-4 text-emerald-500 shrink-0" />
                <span>Multi-tenant isolated, verified with live market rates, recorded in business audit log.</span>
              </div>
            </>
          )}
        </div>

        {/* Modal Actions */}
        <div className="flex items-center justify-end gap-3 border-t border-gray-100 dark:border-gray-800/80 px-6 py-4 bg-gray-50/50 dark:bg-gray-900/30">
          <button
            type="button"
            onClick={onClose}
            disabled={submitting}
            className="rounded-xl px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            {t("cancel")}
          </button>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={loading || submitting}
            className="flex items-center gap-2 rounded-xl bg-[#6c4cf5] hover:bg-[#5b3ce0] text-white px-5 py-2 text-sm font-semibold shadow-md shadow-purple-500/20 disabled:opacity-50 transition-all duration-200"
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
