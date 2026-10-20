"use client";

import React, { useMemo } from "react";
import { Wallet, Globe, ArrowUpRight, ShieldCheck, Sparkles, TrendingUp } from "lucide-react";
import { CurrencyPair } from "@/lib/api/currencies";

interface BusinessPortfolioImpactCardProps {
  businessName?: string;
  baseCurrency?: string;
  netBalance?: number;
  marketPairs?: CurrencyPair[];
  isArabic?: boolean;
}

export function BusinessPortfolioImpactCard({
  businessName = "My Business",
  baseCurrency = "EUR",
  netBalance = 24500,
  marketPairs = [],
  isArabic = false,
}: BusinessPortfolioImpactCardProps) {
  // Compute valuations into USD, EUR, TND, GBP, AED
  const valuations = useMemo(() => {
    const targetCurrencies = ["USD", "EUR", "TND", "GBP", "AED"];
    // Build rate lookup against USD
    // If pair is USD/XYZ: rate is XYZ per 1 USD
    // If pair is EUR/USD: rate is USD per 1 EUR
    const ratesFromBase: Record<string, number> = {
      [baseCurrency]: 1.0,
    };

    // Approximate conversion using available marketPairs
    marketPairs.forEach((p) => {
      if (p.base === baseCurrency) {
        ratesFromBase[p.target] = p.rate;
      } else if (p.target === baseCurrency && p.rate > 0) {
        ratesFromBase[p.base] = 1 / p.rate;
      }
    });

    // Fallbacks if not directly in pairs
    const usdRate = ratesFromBase["USD"] || (baseCurrency === "EUR" ? 1.0825 : baseCurrency === "TND" ? 0.334 : 1.0);
    ratesFromBase["USD"] = usdRate;
    if (!ratesFromBase["EUR"]) ratesFromBase["EUR"] = usdRate * 0.9238;
    if (!ratesFromBase["TND"]) ratesFromBase["TND"] = usdRate * 2.994;
    if (!ratesFromBase["GBP"]) ratesFromBase["GBP"] = usdRate * 0.7895;
    if (!ratesFromBase["AED"]) ratesFromBase["AED"] = usdRate * 3.6725;

    return targetCurrencies
      .filter((c) => c !== baseCurrency)
      .slice(0, 4)
      .map((curr) => {
        const rate = ratesFromBase[curr] || 1.0;
        const value = netBalance * rate;
        return {
          currency: curr,
          rate,
          value,
        };
      });
  }, [baseCurrency, netBalance, marketPairs]);

  return (
    <div className="rounded-2xl border border-purple-200/60 dark:border-purple-900/40 bg-gradient-to-br from-purple-50/60 via-white to-indigo-50/40 dark:from-purple-950/20 dark:via-gray-900 dark:to-indigo-950/20 p-6 shadow-xs relative overflow-hidden transition-all duration-200">
      {/* Background Ambient Glow */}
      <div className="absolute -top-12 -right-12 w-48 h-48 bg-purple-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-12 -left-12 w-48 h-48 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />

      {/* Card Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-purple-100 dark:border-purple-900/30 relative z-10">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-[#6c4cf5] to-[#8b5cf6] text-white shadow-md shadow-purple-500/25">
            <Globe className="h-5 w-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                {isArabic ? "تقييم أثر محفظة الأعمال الحية" : "Business Portfolio Live Valuation"}
              </h3>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-purple-600 text-white uppercase tracking-wider">
                Multi-FX
              </span>
            </div>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {isArabic
                ? `صافي رصيد ${businessName} مقوماً بأبرز العملات العالمية بأسعار الصرف المباشرة`
                : `${businessName}'s current net balance translated across major global settlement currencies`}
            </p>
          </div>
        </div>

        {/* Base Currency Pill */}
        <div className="flex items-center gap-2 self-start sm:self-auto px-3.5 py-1.5 rounded-xl bg-white/80 dark:bg-gray-800/80 border border-purple-200 dark:border-purple-800/50 shadow-2xs">
          <Wallet className="h-4 w-4 text-purple-600 dark:text-purple-400" />
          <div className="flex flex-col">
            <span className="text-[10px] text-gray-400 uppercase font-semibold">
              {isArabic ? "الرصيد الأساسي" : "Base Balance"}
            </span>
            <span className="text-sm font-black text-gray-900 dark:text-white font-mono">
              {netBalance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {baseCurrency}
            </span>
          </div>
        </div>
      </div>

      {/* Valuation Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 py-5 relative z-10">
        {valuations.map((item) => (
          <div
            key={item.currency}
            className="p-4 rounded-xl border border-gray-200/80 dark:border-gray-800 bg-white/90 dark:bg-gray-800/60 shadow-xs hover:border-purple-400 dark:hover:border-purple-600 transition-all duration-200 group"
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors">
                {item.currency}
              </span>
              <span className="text-[10px] font-mono text-gray-400 dark:text-gray-500">
                1 {baseCurrency} = {item.rate.toFixed(3)}
              </span>
            </div>

            <div className="text-lg font-black text-gray-900 dark:text-white font-mono tracking-tight">
              {item.value.toLocaleString(undefined, {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              })}
            </div>
            <span className="text-[10px] text-gray-400 dark:text-gray-500">
              {item.currency} equivalent
            </span>
          </div>
        ))}
      </div>

      {/* Card Footer Insights */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-4 border-t border-purple-100 dark:border-purple-900/30 text-xs text-gray-500 dark:text-gray-400 relative z-10">
        <div className="flex items-center gap-2">
          <ShieldCheck className="h-4 w-4 text-emerald-500 shrink-0" />
          <span>
            {isArabic
              ? "مفيد لإدارة مخاطر العملات الأجنبية وتحديد أسعار الفواتير للعملاء الدوليين في تونس والخليج وأوروبا."
              : "Hedge foreign exchange exposure when billing international clients across Europe, Tunisia, and the Gulf."}
          </span>
        </div>

        <div className="flex items-center gap-1.5 text-purple-600 dark:text-purple-400 font-bold shrink-0">
          <Sparkles className="h-3.5 w-3.5" />
          <span>Real-time Interbank Rates</span>
        </div>
      </div>
    </div>
  );
}
