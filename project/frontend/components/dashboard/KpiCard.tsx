"use client";

import { useId } from "react";
import { LucideIcon } from "lucide-react";
import { ResponsiveContainer, AreaChart, Area } from "recharts";
import { ChartContainer } from "@/components/ui/chart-container";
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
  const chartData = (data && data.length > 0 ? data : [0, 0, 0, 0, 0, 0, 0]).map((val, i) => ({ value: val, index: i }));

  const strokeColor = isZero ? "#6b7280" : isPositive ? "#10b981" : "#ef4444";

  return (
    <div className="group relative overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-lg dark:hover:shadow-[#8b5cf6]/5">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-50 dark:bg-white/[0.03] text-gray-500 dark:text-gray-400 group-hover:bg-[#8b5cf6]/10 group-hover:text-[#7c3aed] dark:group-hover:text-[#a78bfa] transition-colors">
            <Icon className="h-5 w-5" />
          </div>
          <span className="text-sm font-medium text-gray-500 dark:text-gray-400">
            {title}
          </span>
        </div>
      </div>

      <div className="mt-4 flex items-end justify-between">
        <div>
          <h3 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            {value}
          </h3>
          <div className="mt-1 flex items-center gap-1.5">
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

        {/* Mini Chart */}
        <ChartContainer className="h-12 w-24 opacity-60 transition-opacity duration-300 group-hover:opacity-100">
          <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={strokeColor} stopOpacity={isZero ? 0.05 : 0.3} />
                  <stop offset="95%" stopColor={strokeColor} stopOpacity={0} />
                </linearGradient>
              </defs>
              <Area
                type="monotone"
                dataKey="value"
                stroke={strokeColor}
                strokeWidth={isZero ? 1.5 : 2}
                strokeDasharray={isZero ? "4 4" : undefined}
                fillOpacity={1}
                fill={`url(#${gradientId})`}
                isAnimationActive={false}
              />
            </AreaChart>
          </ResponsiveContainer>
        </ChartContainer>
      </div>
    </div>
  );
}
