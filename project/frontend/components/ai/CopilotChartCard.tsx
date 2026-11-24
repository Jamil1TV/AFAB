"use client";

import { Download } from "lucide-react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  LineChart,
  Line,
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from "recharts";
import { ChartContainer } from "@/components/ui/chart-container";
import { AiChartSpec } from "@/lib/api/ai";
import { chartTooltipStyle, CHART_PALETTE } from "@/lib/design-tokens";
import { formatCurrency } from "@/lib/currency";

const SERIES_COLORS: Record<string, string> = {
  primary: "var(--primary)",
  emerald: "#10b981",
  rose: "#ef4444",
  amber: "#f59e0b",
  sky: "#0ea5e9",
};

function resolveSeriesColor(token: string, idx: number): string {
  return SERIES_COLORS[token] || CHART_PALETTE[idx % CHART_PALETTE.length];
}

export function CopilotChartCard({ chart }: { chart: AiChartSpec }) {
  if (!chart || !chart.data || chart.data.length === 0) return null;

  const currency = chart.currency || "USD";
  const series = chart.series || [];
  const xKey = chart.xKey || "name";

  const handleDownloadCsv = () => {
    const keys = [xKey, ...series.map((s) => s.key)];
    const rows = [
      keys.join(","),
      ...chart.data.map((row) =>
        keys
          .map((k) => `"${String(row[k] ?? "").replace(/"/g, '""')}"`)
          .join(",")
      ),
    ];
    const blob = new Blob(["\uFEFF" + rows.join("\r\n")], {
      type: "text/csv;charset=utf-8;",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${(chart.title || "copilot-chart").toLowerCase().replace(/[^a-z0-9]+/g, "-")}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const tooltipFormatter = (value: unknown) => {
    const num = Number(value);
    return Number.isFinite(num) ? formatCurrency(num, currency) : String(value ?? "");
  };

  return (
    <div className="rounded-2xl border border-gray-200/80 dark:border-gray-800 bg-[var(--surface-inset)] p-3.5 sm:p-4 space-y-3">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <h4 className="text-xs font-bold text-gray-900 dark:text-white truncate">
            {chart.title}
          </h4>
          {chart.subtitle && (
            <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-0.5">
              {chart.subtitle}
            </p>
          )}
        </div>
        <button
          type="button"
          onClick={handleDownloadCsv}
          title="Download CSV"
          className="inline-flex items-center gap-1 rounded-lg border border-gray-200 dark:border-gray-800 bg-[var(--card)] px-2 py-1 text-[10.5px] font-semibold text-gray-600 dark:text-gray-300 hover:border-[var(--primary)]/40 hover:text-[var(--primary)] transition-colors shrink-0"
        >
          <Download className="h-3 w-3" />
          <span>CSV</span>
        </button>
      </div>

      <ChartContainer className="h-56 w-full">
        <ResponsiveContainer width="100%" height="100%" minWidth={1} minHeight={1} initialDimension={{ width: 320, height: 224 }}>
          {chart.chartType === "donut" ? (
            <PieChart>
              <Pie
                data={chart.data}
                dataKey={series[0]?.key || "value"}
                nameKey={xKey}
                innerRadius={52}
                outerRadius={82}
                paddingAngle={3}
              >
                {chart.data.map((_, idx) => (
                  <Cell
                    key={`cell-${idx}`}
                    fill={CHART_PALETTE[idx % CHART_PALETTE.length]}
                  />
                ))}
              </Pie>
              <Tooltip
                contentStyle={chartTooltipStyle.contentStyle}
                itemStyle={chartTooltipStyle.itemStyle}
                formatter={tooltipFormatter}
              />
              <Legend wrapperStyle={{ fontSize: "11px" }} />
            </PieChart>
          ) : chart.chartType === "area" ? (
            <AreaChart data={chart.data} margin={{ top: 6, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,0.16)" />
              <XAxis dataKey={xKey} tick={{ fontSize: 11, fill: "#9ca3af" }} />
              <YAxis tick={{ fontSize: 11, fill: "#9ca3af" }} width={56} />
              <Tooltip
                contentStyle={chartTooltipStyle.contentStyle}
                itemStyle={chartTooltipStyle.itemStyle}
                labelStyle={chartTooltipStyle.labelStyle}
                formatter={tooltipFormatter}
              />
              <Legend wrapperStyle={{ fontSize: "11px" }} />
              {series.map((s, idx) => {
                const color = resolveSeriesColor(s.colorToken, idx);
                return (
                  <Area
                    key={s.key}
                    type="monotone"
                    dataKey={s.key}
                    name={s.label}
                    stroke={color}
                    fill={color}
                    fillOpacity={0.14}
                    strokeWidth={2}
                  />
                );
              })}
            </AreaChart>
          ) : chart.chartType === "line" ? (
            <LineChart data={chart.data} margin={{ top: 6, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,0.16)" />
              <XAxis dataKey={xKey} tick={{ fontSize: 11, fill: "#9ca3af" }} />
              <YAxis tick={{ fontSize: 11, fill: "#9ca3af" }} width={56} />
              <Tooltip
                contentStyle={chartTooltipStyle.contentStyle}
                itemStyle={chartTooltipStyle.itemStyle}
                labelStyle={chartTooltipStyle.labelStyle}
                formatter={tooltipFormatter}
              />
              <Legend wrapperStyle={{ fontSize: "11px" }} />
              {series.map((s, idx) => (
                <Line
                  key={s.key}
                  type="monotone"
                  dataKey={s.key}
                  name={s.label}
                  stroke={resolveSeriesColor(s.colorToken, idx)}
                  strokeWidth={2.2}
                  dot={{ r: 3 }}
                />
              ))}
            </LineChart>
          ) : (
            <BarChart data={chart.data} margin={{ top: 6, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,0.16)" />
              <XAxis dataKey={xKey} tick={{ fontSize: 11, fill: "#9ca3af" }} />
              <YAxis tick={{ fontSize: 11, fill: "#9ca3af" }} width={56} />
              <Tooltip
                contentStyle={chartTooltipStyle.contentStyle}
                itemStyle={chartTooltipStyle.itemStyle}
                labelStyle={chartTooltipStyle.labelStyle}
                formatter={tooltipFormatter}
              />
              <Legend wrapperStyle={{ fontSize: "11px" }} />
              {series.map((s, idx) => (
                <Bar
                  key={s.key}
                  dataKey={s.key}
                  name={s.label}
                  fill={resolveSeriesColor(s.colorToken, idx)}
                  radius={[6, 6, 0, 0]}
                />
              ))}
            </BarChart>
          )}
        </ResponsiveContainer>
      </ChartContainer>
    </div>
  );
}
