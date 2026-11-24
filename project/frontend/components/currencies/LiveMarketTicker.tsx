"use client";

import React, { useRef, useState, useMemo } from "react";
import { CurrencyPair } from "@/lib/api/currencies";
import { ChevronLeft, ChevronRight } from "lucide-react";

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
    <div className="afab-card w-full p-3 space-y-2">
      {/* Category Pills & Navigation Bar */}
      <div className="flex items-center justify-between gap-2 px-1">
        <div className="flex items-center gap-2 overflow-x-auto scrollbar-none py-0.5">
          {/* Live Indicator */}
          <div className="afab-badge afab-badge-success px-2.5 py-1 rounded-lg uppercase tracking-wider shrink-0 border border-emerald-500/20">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span>
              {isArabic ? "مباشر" : "Live FX"}
            </span>
          </div>

          <div className="afab-segmented">
            {categories.map((c) => (
              <button
                key={c.key}
                type="button"
                onClick={() => setActiveCategory(c.key)}
                className={`afab-segment px-2.5 py-1 ${
                  activeCategory === c.key ? "afab-segment-active" : ""
                }`}
              >
                {isArabic ? c.labelAr : c.labelEn}
              </button>
            ))}
          </div>
        </div>

        {/* Scroll Arrow Buttons */}
        <div className="flex items-center gap-1 shrink-0">
          <button
            type="button"
            onClick={() => handleScroll(isArabic ? "right" : "left")}
            className="afab-page-btn h-7 w-7"
            title="Scroll Left"
          >
            <ChevronLeft className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => handleScroll(isArabic ? "left" : "right")}
            className="afab-page-btn h-7 w-7"
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
                  ? "bg-[var(--primary)] text-white border-[var(--primary)] shadow-sm shadow-[var(--primary)]/25"
                  : "bg-gray-50/50 dark:bg-[#080c18] border-gray-200 dark:border-gray-800/60 text-gray-700 dark:text-gray-300 hover:border-[var(--primary)]/50 hover:bg-gray-100/60 dark:hover:bg-white/[0.04]"
              }`}
            >
              <span className={`font-bold ${isActive ? "text-white" : "text-gray-900 dark:text-white"}`}>
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
                    : "text-red-600 dark:text-red-400"
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
