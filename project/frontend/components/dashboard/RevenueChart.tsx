"use client";

import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip } from "recharts";
import { ChartContainer } from "@/components/ui/chart-container";
import { useTranslations, useLocale } from "next-intl";
import { formatCurrency } from "@/lib/currency";

export function RevenueChart({ data, currency = "USD" }: { data: any[]; currency?: string }) {
  const tCharts = useTranslations("Dashboard.charts");
  const locale = useLocale();

  // Localize month names if month string (e.g. "2026-05") is provided
  const chartData = (data || []).map((item) => {
    let displayName = item.name || item.month;
    if (item.month && item.month.includes("-")) {
      try {
        const [year, month] = item.month.split("-");
        const date = new Date(parseInt(year, 10), parseInt(month, 10) - 1, 1);
        displayName = date.toLocaleString(locale, { month: "short" });
      } catch {
        displayName = item.name || item.month;
      }
    }
    return {
      ...item,
      displayName,
    };
  });

  const isAllZero = chartData.length === 0 || chartData.every((d) => (d.revenue || 0) === 0 && (d.expenses || 0) === 0);

  return (
    <div className="relative rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm overflow-hidden">
      <div className="mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">{tCharts("revenueTitle")}</h3>
            {isAllZero && (
              <span className="rounded-full bg-purple-500/10 border border-purple-500/20 px-2 py-0.5 text-[10px] font-semibold text-purple-600 dark:text-purple-400">
                {locale === "ar" ? "في انتظار المعاملات" : "Awaiting data"}
              </span>
            )}
          </div>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {isAllZero
              ? (locale === "ar" ? "أضف معاملتك الأولى لعرض تدفقك النقدي الحقيقي" : "Add your first transaction to visualize live cash flow")
              : tCharts("revenueSubtitle")}
          </p>
        </div>
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <span className="h-2.5 w-2.5 rounded-full bg-[#8b5cf6]"></span>
            <span className="text-xs font-medium text-gray-600 dark:text-gray-300">{tCharts("revenueLabel")}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="h-2.5 w-2.5 rounded-full bg-[#0ea5e9]"></span>
            <span className="text-xs font-medium text-gray-600 dark:text-gray-300">{tCharts("expensesLabel")}</span>
          </div>
        </div>
      </div>

      <ChartContainer className="h-[300px] w-full">
        <ResponsiveContainer width="100%" height="100%" minHeight={300} minWidth={0}>
          <AreaChart data={chartData} margin={{ top: 10, right: 0, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorExpenses" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#0ea5e9" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#0ea5e9" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="currentColor" className="text-gray-200 dark:text-gray-800/50" />
            <XAxis 
              dataKey="displayName" 
              axisLine={false} 
              tickLine={false} 
              tick={{ fontSize: 12 }} 
              stroke="currentColor"
              className="text-gray-400 dark:text-gray-500"
              dy={10}
            />
            <YAxis 
              axisLine={false} 
              tickLine={false} 
              tick={{ fontSize: 12 }} 
              tickFormatter={(value) => formatCurrency(value, currency)}
              stroke="currentColor"
              className="text-gray-400 dark:text-gray-500"
            />
            <Tooltip
              formatter={(value: any) => [formatCurrency(value, currency), ""]}
              contentStyle={{ 
                backgroundColor: 'rgba(12, 16, 28, 0.9)', 
                borderColor: 'rgba(139, 92, 246, 0.2)',
                borderRadius: '12px',
                color: '#fff',
                boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)'
              }}
              itemStyle={{ color: '#e5e7eb' }}
            />
            <Area 
              type="monotone" 
              dataKey="revenue" 
              stroke="#8b5cf6" 
              strokeWidth={3}
              fillOpacity={1} 
              fill="url(#colorRevenue)" 
            />
            <Area 
              type="monotone" 
              dataKey="expenses" 
              stroke="#0ea5e9" 
              strokeWidth={3}
              fillOpacity={1} 
              fill="url(#colorExpenses)" 
            />
          </AreaChart>
        </ResponsiveContainer>
      </ChartContainer>
    </div>
  );
}
