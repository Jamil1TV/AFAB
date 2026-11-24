"use client";

import React, { useMemo } from "react";
import { TrendingUp, TrendingDown } from "lucide-react";
import { CurrencyPair } from "@/lib/api/currencies";

interface FeaturedPairCardProps {
  pair: CurrencyPair;
  isSelected?: boolean;
  onSelect?: (pair: CurrencyPair) => void;
  isArabic?: boolean;
}

export function FeaturedPairCard({
  pair,
  isSelected = false,
  onSelect,
  isArabic = false,
}: FeaturedPairCardProps) {
  const isPositive = pair.change24h >= 0;

  // Mini sparkline SVG math
  const { pathData, areaData } = useMemo(() => {
    const data = pair.sparkline && pair.sparkline.length > 0 ? pair.sparkline : [pair.rate * 0.99, pair.rate];
    const width = 120;
    const height = 45;
    const pad = 4;
    const min = Math.min(...data);
    const max = Math.max(...data);
    const range = max - min || 0.0001;

    const points = data.map((val, idx) => {
      const x = pad + (idx / Math.max(data.length - 1, 1)) * (width - pad * 2);
      const y = pad + (1 - (val - min) / range) * (height - pad * 2);
      return { x, y };
    });

    let line = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const p0 = points[i];
      const p1 = points[i + 1];
      const cx = (p0.x + p1.x) / 2;
      line += ` C ${cx} ${p0.y}, ${cx} ${p1.y}, ${p1.x} ${p1.y}`;
    }

    const last = points[points.length - 1];
    const first = points[0];
    const area = `${line} L ${last.x} ${height} L ${first.x} ${height} Z`;

    return { pathData: line, areaData: area };
  }, [pair.sparkline, pair.rate]);

  // 24h range percent calculation for the slider bar
  const rangePercent = useMemo(() => {
    const high = pair.high24h || pair.rate * 1.01;
    const low = pair.low24h || pair.rate * 0.99;
    const diff = high - low;
    if (diff <= 0) return 50;
    const pos = ((pair.rate - low) / diff) * 100;
    return Math.min(Math.max(pos, 5), 95);
  }, [pair.rate, pair.high24h, pair.low24h]);

  const strokeColor = isPositive ? "#10b981" : "#ef4444";
  const gradientId = `spark_${pair.symbol.replace("/", "_")}_${isPositive ? "up" : "down"}`;

  return (
    <div
      onClick={() => onSelect && onSelect(pair)}
      className={`afab-card afab-card-hover group cursor-pointer p-5 relative overflow-hidden ${
        isSelected
          ? "border-[var(--primary)] dark:border-[var(--primary)] ring-2 ring-[var(--primary)]/20"
          : ""
      }`}
    >
      {/* Top Header: Pair symbol & 24h change badge */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <span className="font-bold text-base text-gray-900 dark:text-white group-hover:text-[var(--primary)] transition-colors">
            {pair.symbol}
          </span>
          <span className="text-[10px] font-semibold text-gray-400 dark:text-gray-500 uppercase">
            FX
          </span>
        </div>

        <div
          className={`afab-badge ${
            isPositive
              ? "afab-badge-success"
              : "afab-badge-danger"
          }`}
        >
          {isPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
          <span>{pair.change24h >= 0 ? "+" : ""}{pair.change24h.toFixed(2)}%</span>
        </div>
      </div>

      {/* Middle: Spot Rate & Mini Sparkline */}
      <div className="flex items-baseline justify-between gap-3 my-2">
        <div>
          <span className="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white tracking-tight font-mono">
            {pair.rate.toFixed(4)}
          </span>
          <span className="text-[10px] text-gray-400 dark:text-gray-500 block font-medium">
            1 {pair.base} = {pair.rate.toFixed(4)} {pair.target}
          </span>
        </div>

        {/* Mini SVG Sparkline */}
        <div className="w-[110px] h-[40px] shrink-0">
          <svg viewBox="0 0 120 45" className="w-full h-full overflow-visible">
            <defs>
              <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={strokeColor} stopOpacity="0.28" />
                <stop offset="100%" stopColor={strokeColor} stopOpacity="0.00" />
              </linearGradient>
            </defs>
            <path d={areaData} fill={`url(#${gradientId})`} />
            <path
              d={pathData}
              fill="none"
              stroke={strokeColor}
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>
      </div>

      {/* 24h Low / High Range Bar */}
      <div className="pt-3 border-t border-gray-100 dark:border-gray-800/60 mt-2 space-y-1">
        <div className="flex items-center justify-between text-[10px] text-gray-400 dark:text-gray-500 font-mono">
          <span>L: {pair.low24h.toFixed(4)}</span>
          <span>H: {pair.high24h.toFixed(4)}</span>
        </div>
        <div className="h-1.5 w-full bg-gray-100 dark:bg-white/[0.06] rounded-full relative overflow-hidden">
          <div
            style={{ width: `${rangePercent}%` }}
            className={`h-full rounded-full transition-all duration-300 ${
              isPositive ? "bg-emerald-500" : "bg-red-500"
            }`}
          />
        </div>

        {/* Quick action footer */}
        <div className="flex items-center justify-between pt-2">
          <span className="text-[11px] font-semibold text-[var(--primary)] group-hover:underline">
            {isArabic ? "تحليل الرسم البياني ←" : "Analyze Chart →"}
          </span>
          <span className="text-[10px] text-gray-400 dark:text-gray-500 font-medium">
            Spot FX
          </span>
        </div>
      </div>
    </div>
  );
}
