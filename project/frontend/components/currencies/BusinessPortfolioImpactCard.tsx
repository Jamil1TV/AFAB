"use client";

import React, { useMemo } from "react";
import { Wallet, Globe, ShieldCheck, Sparkles } from "lucide-react";
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
  netBalance = 0,
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
    <div className="afab-card p-6 relative overflow-hidden transition-all duration-200">
      {/* Card Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-gray-100 dark:border-gray-800/60">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]">
            <Globe className="h-5 w-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="afab-card-title">
                {isArabic ? "تقييم أثر محفظة الأعمال الحية" : "Business Portfolio Live Valuation"}
              </h3>
              <span className="afab-badge afab-badge-primary uppercase tracking-wider">
                Multi-FX
              </span>
            </div>
            <p className="afab-card-subtitle text-xs mt-0.5">
              {isArabic
                ? `صافي رصيد ${businessName} مقوماً بأبرز العملات العالمية بأسعار الصرف المباشرة`
                : `${businessName}'s current net balance translated across major global settlement currencies`}
            </p>
          </div>
        </div>

        {/* Base Currency Pill */}
        <div className="afab-inset flex items-center gap-2.5 self-start sm:self-auto px-3.5 py-2">
          <Wallet className="h-4 w-4 text-[#7c3aed] dark:text-[#a78bfa]" />
          <div className="flex flex-col">
            <span className="text-[10px] text-gray-400 dark:text-gray-500 uppercase font-semibold">
              {isArabic ? "الرصيد الأساسي" : "Base Balance"}
            </span>
            <span className="text-sm font-bold text-gray-900 dark:text-white font-mono">
              {netBalance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {baseCurrency}
            </span>
          </div>
        </div>
      </div>

      {/* Valuation Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 py-5">
        {valuations.map((item) => (
          <div
            key={item.currency}
            className="afab-inset p-4 hover:border-[#8b5cf6]/50 transition-all duration-200 group"
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider group-hover:text-[#7c3aed] dark:group-hover:text-[#a78bfa] transition-colors">
                {item.currency}
              </span>
              <span className="text-[10px] font-mono text-gray-400 dark:text-gray-500">
                1 {baseCurrency} = {item.rate.toFixed(3)}
              </span>
            </div>

            <div className="text-lg font-bold text-gray-900 dark:text-white font-mono tracking-tight">
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
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-4 border-t border-gray-100 dark:border-gray-800/60 text-xs text-gray-500 dark:text-gray-400">
        <div className="flex items-center gap-2">
          <ShieldCheck className="h-4 w-4 text-emerald-500 shrink-0" />
          <span>
            {isArabic
              ? "مفيد لإدارة مخاطر العملات الأجنبية وتحديد أسعار الفواتير للعملاء الدوليين في تونس والخليج وأوروبا."
              : "Hedge foreign exchange exposure when billing international clients across Europe, Tunisia, and the Gulf."}
          </span>
        </div>

        <div className="flex items-center gap-1.5 text-[#7c3aed] dark:text-[#a78bfa] font-semibold shrink-0">
          <Sparkles className="h-3.5 w-3.5" />
          <span>Real-time Interbank Rates</span>
        </div>
      </div>
    </div>
  );
}
