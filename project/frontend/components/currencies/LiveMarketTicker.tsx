"use client";

import React, { useRef, useState, useMemo } from "react";
import { CurrencyPair } from "@/lib/api/currencies";
import { TrendingUp, TrendingDown, ChevronLeft, ChevronRight, Filter } from "lucide-react";

interface LiveMarketTickerProps {
  pairs: CurrencyPair[];
  activePairSymbol?: string;
  onSelectPair?: (pair: CurrencyPair) => void;
  isArabic?: boolean;
}

export function LiveMarketTicker({
  pairs,
  activePairSymbol,
  onSelectPair,
  isArabic = false,
}: LiveMarketTickerProps) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [activeCategory, setActiveCategory] = useState<string>("ALL");

  const categories = [
    { key: "ALL", labelEn: "All Pairs", labelAr: "الكل" },
    { key: "MAJORS", labelEn: "Majors", labelAr: "العملات الكبرى" },
    { key: "MENA", labelEn: "MENA / Gulf", labelAr: "الشرق الأوسط والخليج" },
    { key: "ASIA", labelEn: "Asia-Pac", labelAr: "آسيا والمحيط الهادئ" },
  ];

  const filteredPairs = useMemo(() => {
    if (activeCategory === "ALL") return pairs;
    if (activeCategory === "MAJORS") {
      return pairs.filter((p) => ["USD", "EUR", "GBP", "CHF"].includes(p.target) || ["USD", "EUR"].includes(p.base));
    }
    if (activeCategory === "MENA") {
      return pairs.filter((p) => ["QAR", "TND", "AED", "SAR", "KWD", "MAD", "EGP"].includes(p.target) || ["QAR", "TND", "AED"].includes(p.base));
    }
    if (activeCategory === "ASIA") {
      return pairs.filter((p) => ["JPY", "CNY", "AUD", "CAD"].includes(p.target));
    }
    return pairs;
  }, [pairs, activeCategory]);

  const handleScroll = (direction: "left" | "right") => {
    if (!scrollRef.current) return;
    const distance = 280;
    scrollRef.current.scrollBy({
      left: direction === "left" ? -distance : distance,
      behavior: "smooth",
    });
  };

  return (
    <div className="w-full rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900/90 p-3 shadow-xs space-y-2">
      {/* Category Pills & Navigation Bar */}
      <div className="flex items-center justify-between gap-2 px-1">
        <div className="flex items-center gap-1.5 overflow-x-auto scrollbar-none py-0.5">
          {/* Live Indicator */}
          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 font-bold text-[10px] shrink-0 border border-emerald-500/20">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span className="uppercase tracking-wider">
              {isArabic ? "مباشر" : "Live FX"}
            </span>
          </div>

          {categories.map((c) => (
            <button
              key={c.key}
              type="button"
              onClick={() => setActiveCategory(c.key)}
              className={`px-2.5 py-0.5 rounded-lg text-xs font-bold transition-all shrink-0 ${
                activeCategory === c.key
                  ? "bg-purple-600 text-white shadow-xs"
                  : "bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              }`}
            >
              {isArabic ? c.labelAr : c.labelEn}
            </button>
          ))}
        </div>

        {/* Scroll Arrow Buttons */}
        <div className="flex items-center gap-1 shrink-0">
          <button
            type="button"
            onClick={() => handleScroll(isArabic ? "right" : "left")}
            className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-500 hover:text-purple-600 dark:hover:text-purple-400 transition-colors shadow-2xs"
            title="Scroll Left"
          >
            <ChevronLeft className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => handleScroll(isArabic ? "left" : "right")}
            className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-500 hover:text-purple-600 dark:hover:text-purple-400 transition-colors shadow-2xs"
            title="Scroll Right"
          >
            <ChevronRight className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>

      {/* Horizontal Scrolling Pairs Strip with ScrollRef */}
      <div 
        ref={scrollRef}
        className="flex items-center gap-2.5 overflow-x-auto scrollbar-none py-1 scroll-smooth"
      >
        {filteredPairs.map((p) => {
          const isPositive = p.change24h >= 0;
          const isActive = activePairSymbol === p.symbol;

          return (
            <button
              key={p.symbol}
              type="button"
              onClick={() => onSelectPair && onSelectPair(p)}
              className={`flex items-center gap-2.5 px-3 py-1.5 rounded-xl border text-xs font-medium transition-all duration-150 shrink-0 ${
                isActive
                  ? "bg-purple-600 text-white border-purple-600 shadow-md ring-1 ring-purple-400"
                  : "bg-gray-50/80 dark:bg-gray-800/60 border-gray-200/70 dark:border-gray-700/60 text-gray-700 dark:text-gray-300 hover:border-purple-400 dark:hover:border-purple-500 hover:bg-white dark:hover:bg-gray-800"
              }`}
            >
              <span className={`font-black ${isActive ? "text-white" : "text-gray-900 dark:text-white"}`}>
                {p.symbol}
              </span>

              <span className={`font-mono font-bold ${isActive ? "text-purple-100" : "text-gray-800 dark:text-gray-200"}`}>
                {p.rate.toFixed(4)}
              </span>

              <span
                className={`flex items-center gap-0.5 text-[11px] font-bold ${
                  isActive
                    ? "text-white"
                    : isPositive
                    ? "text-emerald-600 dark:text-emerald-400"
                    : "text-rose-600 dark:text-rose-400"
                }`}
              >
                {isPositive ? "+" : ""}{p.change24h.toFixed(2)}%
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
