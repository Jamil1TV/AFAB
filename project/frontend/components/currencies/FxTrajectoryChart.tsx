"use client";

import React, { useState, useMemo, useRef } from "react";
import { HistoricalRatePoint } from "@/lib/api/currencies";
import { 
  TrendingUp, 
  TrendingDown, 
  LineChart as LineChartIcon, 
  BarChart2
} from "lucide-react";

interface FxTrajectoryChartProps {
  fromCurrency: string;
  toCurrency: string;
  data: HistoricalRatePoint[];
  timeframe: string;
  onTimeframeChange: (tf: string) => void;
  isLoading?: boolean;
  isArabic?: boolean;
}

export function FxTrajectoryChart({
  fromCurrency,
  toCurrency,
  data,
  timeframe,
  onTimeframeChange,
  isLoading = false,
  isArabic = false,
}: FxTrajectoryChartProps) {
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
  const [showMovingAverage, setShowMovingAverage] = useState<boolean>(true);
  const [chartMode, setChartMode] = useState<"line" | "bars">("line");
  const containerRef = useRef<HTMLDivElement>(null);

  // Compute key stats
  const { minRate, maxRate, avgRate, startRate, currentRate, changePercent, isPositive, volatility } = useMemo(() => {
    if (!data || data.length === 0) {
      return {
        minRate: 1,
        maxRate: 1,
        avgRate: 1,
        startRate: 1,
        currentRate: 1,
        changePercent: 0,
        isPositive: true,
        volatility: 0,
      };
    }

    const rates = data.map((d) => d.rate);
    const min = Math.min(...rates);
    const max = Math.max(...rates);
    const sum = rates.reduce((acc, r) => acc + r, 0);
    const avg = sum / rates.length;
    const start = rates[0];
    const current = rates[rates.length - 1];
    const change = start !== 0 ? ((current - start) / start) * 100 : 0;
    const vol = avg > 0 ? ((max - min) / avg) * 100 : 0;

    return {
      minRate: min,
      maxRate: max,
      avgRate: avg,
      startRate: start,
      currentRate: current,
      changePercent: change,
      isPositive: change >= 0,
      volatility: vol,
    };
  }, [data]);

  // SVG coordinates math — ample right padding so labels never clip
  const width = 800;
  const height = 290;
  const paddingLeft = 20;
  const paddingRight = 75; // Plenty of room for 0.2887 numbers!
  const paddingTop = 25;
  const paddingBottom = 40;
  const chartHeight = height - paddingTop - paddingBottom;
  const chartWidth = width - paddingLeft - paddingRight;

  const points = useMemo(() => {
    if (!data || data.length === 0) return [];

    const range = maxRate - minRate || 0.0001;

    return data.map((item, index) => {
      const x = paddingLeft + (index / Math.max(data.length - 1, 1)) * chartWidth;
      const normalizedRate = (item.rate - minRate) / range;
      const y = paddingTop + (1 - normalizedRate) * chartHeight;
      return { x, y, ...item };
    });
  }, [data, minRate, maxRate, chartHeight, chartWidth, paddingTop, paddingLeft]);

  // Compute 5-day / 7-day Simple Moving Average (SMA)
  const maPoints = useMemo(() => {
    if (!points || points.length < 3) return [];
    const windowSize = Math.min(5, points.length);

    return points.map((p, idx) => {
      const startIdx = Math.max(0, idx - windowSize + 1);
      const slice = points.slice(startIdx, idx + 1);
      const avgY = slice.reduce((sum, item) => sum + item.y, 0) / slice.length;
      return { x: p.x, y: avgY };
    });
  }, [points]);

  // Construct SVG paths
  const { linePath, areaPath, maPath } = useMemo(() => {
    if (points.length === 0) return { linePath: "", areaPath: "", maPath: "" };
    if (points.length === 1) {
      const p = points[0];
      return {
        linePath: `M ${paddingLeft} ${p.y} L ${width - paddingRight} ${p.y}`,
        areaPath: `M ${paddingLeft} ${p.y} L ${width - paddingRight} ${p.y} L ${width - paddingRight} ${height - paddingBottom} L ${paddingLeft} ${height - paddingBottom} Z`,
        maPath: "",
      };
    }

    let d = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const p0 = points[i];
      const p1 = points[i + 1];
      const cx = (p0.x + p1.x) / 2;
      d += ` C ${cx} ${p0.y}, ${cx} ${p1.y}, ${p1.x} ${p1.y}`;
    }

    const last = points[points.length - 1];
    const first = points[0];
    const area = `${d} L ${last.x} ${height - paddingBottom} L ${first.x} ${height - paddingBottom} Z`;

    // Moving average path
    let maD = "";
    if (maPoints.length > 1) {
      maD = `M ${maPoints[0].x} ${maPoints[0].y}`;
      for (let i = 0; i < maPoints.length - 1; i++) {
        const p0 = maPoints[i];
        const p1 = maPoints[i + 1];
        const cx = (p0.x + p1.x) / 2;
        maD += ` C ${cx} ${p0.y}, ${cx} ${p1.y}, ${p1.x} ${p1.y}`;
      }
    }

    return { linePath: d, areaPath: area, maPath: maD };
  }, [points, maPoints, height, paddingBottom, paddingLeft, paddingRight, width]);

  // Mouse hover tracking
  const handleMouseMove = (e: React.MouseEvent<SVGSVGElement>) => {
    if (!containerRef.current || points.length === 0) return;
    const rect = containerRef.current.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const relativeX = (mouseX / rect.width) * width;

    let closestIdx = 0;
    let minDistance = Infinity;
    points.forEach((p, idx) => {
      const dist = Math.abs(p.x - relativeX);
      if (dist < minDistance) {
        minDistance = dist;
        closestIdx = idx;
      }
    });

    setHoveredIndex(closestIdx);
  };

  const handleMouseLeave = () => {
    setHoveredIndex(null);
  };

  const activePoint = hoveredIndex !== null && points[hoveredIndex] ? points[hoveredIndex] : points[points.length - 1];

  const strokeColor = isPositive ? "#10b981" : "#ef4444";
  const gradientId = isPositive ? "fxTrajectoryGreen" : "fxTrajectoryRed";

  const timeframes = [
    { key: "1W", labelEn: "1W", labelAr: "أسبوع" },
    { key: "1M", labelEn: "1M", labelAr: "شهر" },
    { key: "3M", labelEn: "3M", labelAr: "3 أشهر" },
    { key: "1Y", labelEn: "1Y", labelAr: "سنة" },
  ];

  return (
    <div className="afab-card p-6 flex flex-col justify-between transition-all duration-200">
      {/* Top Header & Stat Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-gray-100 dark:border-gray-800/60">
        <div>
          <div className="flex items-center gap-2">
            <span className="afab-card-title tracking-tight">
              {fromCurrency} / {toCurrency}
            </span>
            <span className="afab-badge afab-badge-primary">
              Spot Market
            </span>
            <span className="text-[10px] font-mono text-gray-400 dark:text-gray-500">
              Vol: {volatility.toFixed(2)}%
            </span>
          </div>

          <div className="flex items-baseline gap-3 mt-1.5 flex-wrap">
            <span className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white tracking-tight font-mono">
              {(activePoint ? activePoint.rate : currentRate).toFixed(4)}
            </span>
            <div
              className={`afab-badge ${
                isPositive
                  ? "afab-badge-success"
                  : "afab-badge-danger"
              }`}
            >
              {isPositive ? <TrendingUp className="h-3.5 w-3.5" /> : <TrendingDown className="h-3.5 w-3.5" />}
              <span>{changePercent >= 0 ? "+" : ""}{changePercent.toFixed(2)}%</span>
            </div>
            {activePoint && (
              <span className="text-xs text-gray-400 dark:text-gray-500 font-mono">
                {activePoint.date}
              </span>
            )}
          </div>
        </div>

        {/* Right Controls: Chart Mode, Moving Average Toggle, Timeframe Selector */}
        <div className="flex items-center gap-2 flex-wrap self-start sm:self-auto">
          {/* Chart style toggle (Line vs Bar) */}
          <div className="afab-segmented">
            <button
              type="button"
              onClick={() => setChartMode("line")}
              title="Line Chart"
              className={`afab-segment px-2 py-1 ${
                chartMode === "line" ? "afab-segment-active" : ""
              }`}
            >
              <LineChartIcon className="h-3.5 w-3.5" />
            </button>
            <button
              type="button"
              onClick={() => setChartMode("bars")}
              title="Bar / Candlestick view"
              className={`afab-segment px-2 py-1 ${
                chartMode === "bars" ? "afab-segment-active" : ""
              }`}
            >
              <BarChart2 className="h-3.5 w-3.5" />
            </button>
          </div>

          {/* MA-5 Toggle */}
          <button
            type="button"
            onClick={() => setShowMovingAverage(!showMovingAverage)}
            title="Toggle Moving Average"
            className={`px-2.5 py-1.5 text-[11px] font-bold rounded-xl border transition-all ${
              showMovingAverage
                ? "bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30"
                : "bg-gray-100 dark:bg-[#080c18] text-gray-500 dark:text-gray-400 border-gray-200 dark:border-gray-800/60"
            }`}
          >
            MA-5
          </button>

          {/* Timeframe Selector Pills */}
          <div className="afab-segmented">
            {timeframes.map((tf) => {
              const active = timeframe === tf.key;
              return (
                <button
                  key={tf.key}
                  type="button"
                  onClick={() => onTimeframeChange(tf.key)}
                  className={`afab-segment px-2.5 py-1 ${
                    active ? "afab-segment-active" : ""
                  }`}
                >
                  {isArabic ? tf.labelAr : tf.labelEn}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Trailing Area Chart Graphic */}
      <div 
        ref={containerRef} 
        className="relative w-full h-[290px] mt-4 select-none"
      >
        {isLoading && (
          <div className="absolute inset-0 z-10 flex items-center justify-center bg-white/60 dark:bg-[#0c101c]/60 backdrop-blur-xs">
            <span className="inline-block h-6 w-6 rounded-full border-2 border-[#8b5cf6] border-t-transparent animate-spin" />
          </div>
        )}

        <svg
          viewBox={`0 0 ${width} ${height}`}
          className="w-full h-full overflow-visible"
          onMouseMove={handleMouseMove}
          onMouseLeave={handleMouseLeave}
        >
          <defs>
            <linearGradient id="fxTrajectoryGreen" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#10b981" stopOpacity="0.30" />
              <stop offset="100%" stopColor="#10b981" stopOpacity="0.00" />
            </linearGradient>
            <linearGradient id="fxTrajectoryRed" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#ef4444" stopOpacity="0.30" />
              <stop offset="100%" stopColor="#ef4444" stopOpacity="0.00" />
            </linearGradient>
          </defs>

          {/* Horizontal Reference Grid Lines & Rates (Aligned cleanly in paddingRight) */}
          {[0, 0.33, 0.66, 1].map((ratio, i) => {
            const y = paddingTop + ratio * chartHeight;
            const rateVal = maxRate - ratio * (maxRate - minRate);
            return (
              <g key={i}>
                <line
                  x1={paddingLeft}
                  y1={y}
                  x2={width - paddingRight}
                  y2={y}
                  stroke="currentColor"
                  className="text-gray-200 dark:text-gray-800/50"
                  strokeDasharray="3 3"
                  strokeWidth="1"
                />
                <text
                  x={width - paddingRight + 8}
                  y={y + 3.5}
                  fontSize="10"
                  fontFamily="monospace"
                  fill="currentColor"
                  className="text-gray-400 dark:text-gray-500 font-bold select-none"
                >
                  {rateVal.toFixed(4)}
                </text>
              </g>
            );
          })}

          {/* Bar Chart Mode */}
          {chartMode === "bars" && points.map((p, idx) => {
            const barW = Math.max(3, chartWidth / (points.length * 2));
            const isUp = idx === 0 || p.rate >= points[idx - 1].rate;
            const barColor = isUp ? "#10b981" : "#ef4444";
            const barH = height - paddingBottom - p.y;
            return (
              <rect
                key={idx}
                x={p.x - barW / 2}
                y={p.y}
                width={barW}
                height={Math.max(2, barH)}
                fill={barColor}
                opacity="0.8"
                rx="1"
              />
            );
          })}

          {/* Line Chart Mode: Area Fill */}
          {chartMode === "line" && areaPath && (
            <path
              d={areaPath}
              fill={`url(#${gradientId})`}
              className="transition-all duration-300"
            />
          )}

          {/* Line Chart Mode: Line Path */}
          {chartMode === "line" && linePath && (
            <path
              d={linePath}
              fill="none"
              stroke={strokeColor}
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="transition-all duration-300"
            />
          )}

          {/* Moving Average Line Overlay */}
          {showMovingAverage && maPath && (
            <path
              d={maPath}
              fill="none"
              stroke="#f59e0b"
              strokeWidth="1.5"
              strokeDasharray="3 3"
              opacity="0.85"
            />
          )}

          {/* Hover Crosshair & Indicator Point */}
          {activePoint && hoveredIndex !== null && (
            <g>
              {/* Vertical guideline */}
              <line
                x1={activePoint.x}
                y1={paddingTop}
                x2={activePoint.x}
                y2={height - paddingBottom}
                stroke="currentColor"
                className="text-gray-300 dark:text-gray-600"
                strokeDasharray="2 2"
                strokeWidth="1"
              />

              {/* Glowing Outer Ring */}
              <circle
                cx={activePoint.x}
                cy={activePoint.y}
                r="6"
                fill={strokeColor}
                opacity="0.3"
                className="animate-ping"
              />

              {/* Center Dot */}
              <circle
                cx={activePoint.x}
                cy={activePoint.y}
                r="4.5"
                fill={strokeColor}
                stroke="#FFFFFF"
                strokeWidth="2"
              />
            </g>
          )}
        </svg>

        {/* Hover Tooltip Overlay */}
        {activePoint && hoveredIndex !== null && (
          <div
            style={{
              position: "absolute",
              left: `${(activePoint.x / width) * 100}%`,
              top: `${(activePoint.y / height) * 100 - 18}%`,
              transform: "translate(-50%, -100%)",
              pointerEvents: "none",
            }}
            className="z-20 flex flex-col items-center bg-[#0c101c]/95 backdrop-blur-md text-white text-[11px] font-mono px-3 py-1.5 rounded-xl shadow-xl border border-[#8b5cf6]/20 whitespace-nowrap"
          >
            <span className="font-bold text-emerald-400">
              1 {fromCurrency} = {activePoint.rate.toFixed(4)} {toCurrency}
            </span>
            <span className="text-[10px] text-gray-400">
              {activePoint.date}
            </span>
          </div>
        )}
      </div>

      {/* Trailing Stats Bottom Ribbon */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-4 mt-2 border-t border-gray-100 dark:border-gray-800/60 text-xs">
        <div className="afab-inset p-3">
          <span className="text-gray-400 dark:text-gray-500 block text-[10px] uppercase font-bold tracking-wider">
            {isArabic ? "أدنى سعر" : "Period Low"}
          </span>
          <span className="font-bold text-gray-900 dark:text-white font-mono mt-0.5 block">
            {minRate.toFixed(4)}
          </span>
        </div>

        <div className="afab-inset p-3">
          <span className="text-gray-400 dark:text-gray-500 block text-[10px] uppercase font-bold tracking-wider">
            {isArabic ? "متوسط السعر" : "Period Avg"}
          </span>
          <span className="font-bold text-gray-900 dark:text-white font-mono mt-0.5 block">
            {avgRate.toFixed(4)}
          </span>
        </div>

        <div className="afab-inset p-3">
          <span className="text-gray-400 dark:text-gray-500 block text-[10px] uppercase font-bold tracking-wider">
            {isArabic ? "أعلى سعر" : "Period High"}
          </span>
          <span className="font-bold text-gray-900 dark:text-white font-mono mt-0.5 block">
            {maxRate.toFixed(4)}
          </span>
        </div>

        <div className="afab-inset p-3">
          <span className="text-gray-400 dark:text-gray-500 block text-[10px] uppercase font-bold tracking-wider">
            {isArabic ? "التقلب والانتشار" : "Spread & Vol"}
          </span>
          <span className="font-bold text-[#7c3aed] dark:text-[#a78bfa] font-mono mt-0.5 block">
            {((maxRate - minRate)).toFixed(4)} ({volatility.toFixed(1)}%)
          </span>
        </div>
      </div>
    </div>
  );
}
