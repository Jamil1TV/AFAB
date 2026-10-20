"use client";

import { useId, useMemo } from "react";
import { LucideIcon } from "lucide-react";
import { useTranslations } from "next-intl";

interface KpiCardProps {
  title: string;
  value: string;
  change: string;
  isPositive: boolean;
  icon: LucideIcon;
  data: number[];
}

export function KpiCard({ title, value, change, isPositive, icon: Icon, data }: KpiCardProps) {
  const tKpi = useTranslations("Dashboard.kpi");
  const gradientId = useId();

  const isZero = !data || data.length === 0 || data.every((val) => val === 0);

  // SVG Smooth Sparkline Generator
  const { pathD, areaD, strokeColor, fillColor } = useMemo(() => {
    const stroke = isZero ? "#64748b" : isPositive ? "#10b981" : "#ef4444";
    const fill = stroke;

    // Normalize points to guarantee at least 3 points for a smooth, natural curve
    let raw = (data && data.length > 0) ? [...data] : [0, 0, 0, 0, 0, 0];
    
    // Ensure all points are valid numbers
    raw = raw.map((v) => (typeof v === "number" && !isNaN(v) ? v : 0));

    let points: number[] = [];
    if (raw.length === 1) {
      const v = raw[0];
      // Generate a pleasant organic rise for single value instead of a flat dot
      points = [v * 0.2, v * 0.55, v * 0.85, v];
    } else if (raw.length === 2) {
      points = [raw[0], (raw[0] * 2 + raw[1]) / 3, (raw[0] + raw[1] * 2) / 3, raw[1]];
    } else {
      points = raw;
    }

    const min = Math.min(...points);
    const max = Math.max(...points);
    const range = max - min || (max !== 0 ? Math.abs(max) : 1);

    const width = 100;
    const height = 40;
    const padding = 5;
    const usableHeight = height - padding * 2;

    const coords = points.map((val, idx) => {
      const x = (idx / (points.length - 1)) * width;
      const normalized = (val - min) / range;
      const y = height - padding - normalized * usableHeight;
      return { x, y: isNaN(y) ? height / 2 : y };
    });

    // Build smooth cubic Bézier spline
    let path = `M ${coords[0].x.toFixed(1)},${coords[0].y.toFixed(1)}`;
    for (let i = 0; i < coords.length - 1; i++) {
      const p0 = coords[Math.max(0, i - 1)];
      const p1 = coords[i];
      const p2 = coords[i + 1];
      const p3 = coords[Math.min(coords.length - 1, i + 2)];

      const cp1x = p1.x + (p2.x - p0.x) / 6;
      const cp1y = p1.y + (p2.y - p0.y) / 6;
      const cp2x = p2.x - (p3.x - p1.x) / 6;
      const cp2y = p2.y - (p3.y - p1.y) / 6;

      path += ` C ${cp1x.toFixed(1)},${cp1y.toFixed(1)} ${cp2x.toFixed(1)},${cp2y.toFixed(1)} ${p2.x.toFixed(1)},${p2.y.toFixed(1)}`;
    }

    const area = `${path} L ${width},${height} L 0,${height} Z`;

    return {
      pathD: path,
      areaD: area,
      strokeColor: stroke,
      fillColor: fill,
    };
  }, [data, isPositive, isZero]);

  return (
    <div className="group relative overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-lg dark:hover:shadow-[#8b5cf6]/5">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-50 dark:bg-white/[0.03] text-gray-500 dark:text-gray-400 group-hover:bg-[#8b5cf6]/10 group-hover:text-[#7c3aed] dark:group-hover:text-[#a78bfa] transition-colors">
            <Icon className="h-5 w-5" />
          </div>
          <span className="text-xs sm:text-sm font-medium text-gray-500 dark:text-gray-400 leading-tight">
            {title}
          </span>
        </div>
      </div>

      <div className="mt-4 flex items-end justify-between gap-2">
        <div className="min-w-0 flex-1">
          <h3 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white truncate">
            {value}
          </h3>
          <div className="mt-1 flex items-center gap-1.5 flex-wrap">
            <span
              className={`inline-flex items-center rounded-md px-1.5 py-0.5 text-xs font-medium ${
                isZero
                  ? "bg-gray-100 text-gray-600 dark:bg-white/5 dark:text-gray-400"
                  : isPositive
                  ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400"
                  : "bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-400"
              }`}
            >
              {change}
            </span>
            <span className="text-xs text-gray-400 dark:text-gray-500">
              {tKpi("vsLastMonth")}
            </span>
          </div>
        </div>

        {/* High-Performance SVG Sparkline (No Recharts size errors, perfectly smoothed) */}
        <div className="h-10 w-24 shrink-0 opacity-70 transition-opacity duration-300 group-hover:opacity-100 flex items-end justify-end">
          <svg
            viewBox="0 0 100 40"
            className="w-full h-full overflow-visible"
            preserveAspectRatio="none"
          >
            <defs>
              <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={fillColor} stopOpacity={isZero ? 0.05 : 0.4} />
                <stop offset="100%" stopColor={fillColor} stopOpacity={0} />
              </linearGradient>
            </defs>
            <path d={areaD} fill={`url(#${gradientId})`} />
            <path
              d={pathD}
              fill="none"
              stroke={strokeColor}
              strokeWidth={isZero ? 1.5 : 2.2}
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeDasharray={isZero ? "3 3" : undefined}
            />
          </svg>
        </div>
      </div>
    </div>
  );
}
