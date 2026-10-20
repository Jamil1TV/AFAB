"use client";

import React, { useState, useMemo } from "react";
import { Calculator, ArrowRight, ShieldAlert, Sparkles, TrendingUp, TrendingDown, DollarSign } from "lucide-react";
import { CurrencyPair } from "@/lib/api/currencies";

interface FxInvoiceRiskSimulatorProps {
  baseCurrency?: string;
  marketPairs: CurrencyPair[];
  isArabic?: boolean;
}

export function FxInvoiceRiskSimulator({
  baseCurrency = "QAR",
  marketPairs = [],
  isArabic = false,
}: FxInvoiceRiskSimulatorProps) {
  const [foreignCurrency, setForeignCurrency] = useState<string>("USD");
  const [invoiceAmount, setInvoiceAmount] = useState<number>(10000);
  const [paymentTermsDays, setPaymentTermsDays] = useState<number>(30);

  // Find or calculate rate between foreignCurrency and baseCurrency
  const spotRate = useMemo(() => {
    if (foreignCurrency === baseCurrency) return 1.0;
    // Pair matching: baseCurrency/foreignCurrency or foreignCurrency/baseCurrency
    const direct = marketPairs.find((p) => p.base === foreignCurrency && p.target === baseCurrency);
    if (direct) return direct.rate;

    const inverse = marketPairs.find((p) => p.base === baseCurrency && p.target === foreignCurrency);
    if (inverse && inverse.rate > 0) return 1 / inverse.rate;

    // Fallback baseline lookup
    if (foreignCurrency === "USD" && baseCurrency === "QAR") return 3.64;
    if (foreignCurrency === "EUR" && baseCurrency === "QAR") return 4.08;
    if (foreignCurrency === "USD" && baseCurrency === "TND") return 2.99;
    if (foreignCurrency === "EUR" && baseCurrency === "TND") return 3.35;
    return 1.0;
  }, [foreignCurrency, baseCurrency, marketPairs]);

  const currentValue = invoiceAmount * spotRate;

  // Sensitivity scenarios: +3%, +1.5%, 0%, -1.5%, -3%
  const scenarios = [
    { label: "+3.0% (Foreign Currency Gains)", deltaPct: 0.03, isPositive: true },
    { label: "+1.5% (Foreign Currency Gains)", deltaPct: 0.015, isPositive: true },
    { label: "0.0% (Spot Baseline)", deltaPct: 0.0, isPositive: true },
    { label: "-1.5% (Foreign Currency Drops)", deltaPct: -0.015, isPositive: false },
    { label: "-3.0% (Foreign Currency Drops)", deltaPct: -0.03, isPositive: false },
  ];

  const supportedCurrencies = ["USD", "EUR", "GBP", "TND", "AED", "SAR", "CAD"];

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-xs flex flex-col justify-between transition-all duration-200">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800/80">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400">
            <Calculator className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {isArabic ? "حاسبة مخاطر الفواتير الأجنبية" : "Invoice FX Risk & Sensitivity Simulator"}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {isArabic ? "تقدير أثر تقلبات أسعار الصرف على فواتير ومشتريات العملاء الدوليين" : "Simulate how currency shifts impact your foreign receivables over time"}
            </p>
          </div>
        </div>

        <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-purple-500/10 text-purple-600 dark:text-purple-400 uppercase tracking-wider">
          Risk Tool
        </span>
      </div>

      {/* Simulator Inputs Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 py-4">
        {/* Invoice Amount */}
        <div>
          <label className="text-xs font-semibold text-gray-500 dark:text-gray-400 block mb-1">
            {isArabic ? "مبلغ الفاتورة بالعملة الأجنبية" : "Foreign Invoice Amount"}
          </label>
          <input
            type="number"
            min="0"
            value={invoiceAmount || ""}
            onChange={(e) => setInvoiceAmount(parseFloat(e.target.value) || 0)}
            className="w-full rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/70 dark:bg-gray-800/60 p-2.5 text-sm font-black font-mono text-gray-900 dark:text-white outline-none focus:border-purple-500"
          />
        </div>

        {/* Foreign Currency */}
        <div>
          <label className="text-xs font-semibold text-gray-500 dark:text-gray-400 block mb-1">
            {isArabic ? "عملة الفاتورة" : "Billing Currency"}
          </label>
          <select
            value={foreignCurrency}
            onChange={(e) => setForeignCurrency(e.target.value)}
            className="w-full rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/70 dark:bg-gray-800/60 p-2.5 text-sm font-bold text-gray-900 dark:text-white outline-none cursor-pointer focus:border-purple-500"
          >
            {supportedCurrencies.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>

        {/* Payment Terms */}
        <div>
          <label className="text-xs font-semibold text-gray-500 dark:text-gray-400 block mb-1">
            {isArabic ? "أجل السداد (أيام)" : "Payment Terms (Net Days)"}
          </label>
          <select
            value={paymentTermsDays}
            onChange={(e) => setPaymentTermsDays(parseInt(e.target.value, 10))}
            className="w-full rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/70 dark:bg-gray-800/60 p-2.5 text-sm font-bold text-gray-900 dark:text-white outline-none cursor-pointer focus:border-purple-500"
          >
            <option value={15}>Net 15 Days</option>
            <option value={30}>Net 30 Days</option>
            <option value={60}>Net 60 Days</option>
            <option value={90}>Net 90 Days</option>
          </select>
        </div>
      </div>

      {/* Current Spot Valuation Banner */}
      <div className="flex items-center justify-between p-4 rounded-xl bg-purple-50/50 dark:bg-purple-950/20 border border-purple-100 dark:border-purple-900/30">
        <div>
          <span className="text-[11px] font-semibold text-gray-500 dark:text-gray-400 block">
            {isArabic ? "القيمة الحالية بالعملة الأساسية" : "Today's Value in Base Currency"}
          </span>
          <span className="text-xl font-black text-gray-900 dark:text-white font-mono">
            {currentValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {baseCurrency}
          </span>
        </div>
        <div className="text-right">
          <span className="text-[11px] font-semibold text-purple-600 dark:text-purple-400 block">
            Spot Rate Applied
          </span>
          <span className="text-xs font-mono font-bold text-gray-700 dark:text-gray-300">
            1 {foreignCurrency} = {spotRate.toFixed(4)} {baseCurrency}
          </span>
        </div>
      </div>

      {/* Sensitivity Scenarios Matrix */}
      <div className="pt-4 space-y-2">
        <span className="text-xs font-bold text-gray-700 dark:text-gray-300 block">
          {isArabic ? `حساسية تقلبات الصرف عند التحصيل بعد ${paymentTermsDays} يوماً:` : `FX Sensitivity Scenarios upon Settlement (Net ${paymentTermsDays}):`}
        </span>

        <div className="grid grid-cols-1 sm:grid-cols-5 gap-2 text-xs">
          {scenarios.map((s, idx) => {
            const scenarioRate = spotRate * (1 + s.deltaPct);
            const scenarioVal = invoiceAmount * scenarioRate;
            const diff = scenarioVal - currentValue;
            const isZero = s.deltaPct === 0;

            return (
              <div
                key={idx}
                className={`p-3 rounded-xl border transition-all ${
                  isZero
                    ? "border-purple-300 dark:border-purple-800 bg-purple-50/30 dark:bg-purple-950/30"
                    : s.isPositive
                    ? "border-emerald-200/80 dark:border-emerald-900/30 bg-emerald-50/20 dark:bg-emerald-950/10"
                    : "border-rose-200/80 dark:border-rose-900/30 bg-rose-50/20 dark:bg-rose-950/10"
                }`}
              >
                <span className="text-[10px] font-bold text-gray-500 dark:text-gray-400 block">
                  {s.deltaPct > 0 ? `+${(s.deltaPct * 100).toFixed(1)}%` : s.deltaPct < 0 ? `${(s.deltaPct * 100).toFixed(1)}%` : "Spot"}
                </span>

                <span className="text-sm font-black font-mono text-gray-900 dark:text-white block mt-1">
                  {scenarioVal.toLocaleString(undefined, { maximumFractionDigits: 0 })}
                </span>

                <span
                  className={`text-[10px] font-bold block mt-0.5 ${
                    isZero
                      ? "text-gray-400"
                      : s.isPositive
                      ? "text-emerald-600 dark:text-emerald-400"
                      : "text-rose-600 dark:text-rose-400"
                  }`}
                >
                  {isZero ? "Base Value" : `${diff > 0 ? "+" : ""}${diff.toLocaleString(undefined, { maximumFractionDigits: 0 })} ${baseCurrency}`}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
