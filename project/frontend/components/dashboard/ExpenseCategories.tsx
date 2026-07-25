import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts";
import { ChartContainer } from "@/components/ui/chart-container";
import { useTranslations } from "next-intl";
import { formatCurrency } from "@/lib/currency";

export function ExpenseCategories({ categories, currency = "USD" }: { categories: any[]; currency?: string }) {
  const tCharts = useTranslations("Dashboard.charts");

  const totalExpense = (categories || []).reduce((acc, cat) => acc + (parseFloat(cat.amount) || 0), 0);

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm flex flex-col h-full">
      <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-6">{tCharts("categoriesTitle")}</h3>
      
      <div className="flex-1 flex flex-col sm:flex-row items-center gap-6">
        <div className="relative h-40 w-40 shrink-0">
          <ChartContainer className="h-full w-full">
            <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0}>
            <PieChart>
              <Pie
                data={categories && categories.length > 0 ? categories : [{ name: "None", value: 1, color: "#374151" }]}
                innerRadius={55}
                outerRadius={75}
                paddingAngle={5}
                dataKey="value"
                stroke="none"
              >
                {(categories && categories.length > 0 ? categories : [{ color: "#374151" }]).map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip 
                formatter={(value: any) => [formatCurrency(value, currency), '']}
                contentStyle={{ 
                  backgroundColor: 'rgba(12, 16, 28, 0.9)', 
                  borderColor: 'rgba(255, 255, 255, 0.1)',
                  borderRadius: '8px',
                  color: '#fff',
                  fontSize: '12px'
                }}
                itemStyle={{ color: '#fff' }}
              />
            </PieChart>
            </ResponsiveContainer>
          </ChartContainer>
          
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-base font-bold text-gray-900 dark:text-white">{formatCurrency(totalExpense, currency)}</span>
            <span className="text-[10px] text-gray-500 font-medium">{tCharts("total")}</span>
          </div>
        </div>

        <div className="flex-1 w-full space-y-3">
          {(categories || []).map((category) => (
            <div key={category.name} className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span 
                  className="h-2 w-2 rounded-full" 
                  style={{ backgroundColor: category.color }} 
                />
                <span className="font-medium text-gray-600 dark:text-gray-300">{category.name}</span>
              </div>
              <span className="font-semibold text-gray-900 dark:text-white">
                {formatCurrency(category.amount || category.value, currency)}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
