"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { 
  Plus, 
  Search, 
  Download, 
  Filter, 
  ChevronLeft, 
  ChevronRight, 
  Eye, 
  Trash2, 
  X,
  CreditCard,
  Building2,
  Calendar as CalendarIcon,
  TrendingUp,
  TrendingDown,
  Wallet,
  Layers,
  Repeat,
  DollarSign,
  ArrowUpRight,
  ArrowDownLeft,
  PieChart as PieChartIcon,
  ShoppingBag,
  Palette,
  Mail
} from "lucide-react";
import { useTranslations } from "next-intl";
import { ResponsiveContainer, AreaChart, Area, PieChart, Pie, Cell, Tooltip } from "recharts";
import { ChartContainer } from "@/components/ui/chart-container";
import { AfabLoader } from "@/components/ui/afab-loader";

import { KpiCard } from "@/components/dashboard/KpiCard";
import { AddTransactionModal } from "@/components/dashboard/AddTransactionModal";
import { ExpenseService, ExpenseSummaryResponse } from "@/lib/api/expenses";
import { TransactionService, TransactionResponse, CategoryItem, TransactionItem } from "@/lib/api/transactions";
import { UserService } from "@/lib/api/dashboard";
import { formatCurrency } from "@/lib/currency";

export default function ExpensesPage() {
  const t = useTranslations("Expenses");
  const tKpi = useTranslations("Expenses.kpi");
  const tCharts = useTranslations("Expenses.charts");
  const tFilters = useTranslations("Expenses.filters");
  const tWidgets = useTranslations("Expenses.widgets");
  const tTable = useTranslations("Expenses.table");

  const [summary, setSummary] = useState<ExpenseSummaryResponse | null>(null);
  const [expensesData, setExpensesData] = useState<TransactionResponse | null>(null);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [period, setPeriod] = useState<"WEEKLY" | "MONTHLY" | "YEARLY">("MONTHLY");
  const [page, setPage] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedTx, setSelectedTx] = useState<TransactionItem | null>(null);

  const searchInputRef = useRef<HTMLInputElement>(null);

  // Keyboard shortcut ⌘K listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        searchInputRef.current?.focus();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [sumRes, listRes] = await Promise.all([
        ExpenseService.getSummary(),
        ExpenseService.getExpenses({
          categoryId: categoryFilter || undefined,
          search: search || undefined,
          page,
          size: 15,
        })
      ]);
      setSummary(sumRes);
      setExpensesData(listRes);
    } catch (err) {
      console.error("Failed to load expenses data:", err);
    } finally {
      setLoading(false);
    }
  }, [categoryFilter, search, page]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    TransactionService.getCategories()
      .then(setCategories)
      .catch((err) => console.error("Failed to load categories:", err));
    UserService.getProfile()
      .then(setUserProfile)
      .catch((err) => console.error("Failed to load user profile:", err));
  }, []);

  const handleExportCSV = () => {
    if (!expensesData || !expensesData.content || expensesData.content.length === 0) return;
    const headers = ["ID,Description,Amount,Currency,Category,Date,Payment Method,Status"];
    const rows = expensesData.content.map((tx) =>
      `"${tx.id}","${tx.description.replace(/"/g, '""')}",${tx.amount},"${tx.currency}","${tx.categoryName}","${tx.transactionDate}","${tx.paymentMethod}","${tx.status}"`
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `afab_expenses_${new Date().toISOString().split("T")[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const currency = summary?.currency || userProfile?.currency || "USD";

  // Dynamic Chart Sparklines
  const hasExpenses = Boolean(expensesData?.content && expensesData.content.length > 0);
  const totalExpData = (summary?.totalExpenses && hasExpenses) 
    ? expensesData!.content.map(t => t.amount) 
    : [0, 0, 0, 0, 0, 0, 0];
  const avgExpData = (summary?.avgPerDay && hasExpenses) 
    ? [summary.avgPerDay, summary.avgPerDay * 1.1, summary.avgPerDay * 0.9, summary.avgPerDay] 
    : [0, 0, 0, 0, 0, 0, 0];
  const highestExpData = (summary?.highestExpenseAmount && hasExpenses)
    ? [summary.highestExpenseAmount * 0.5, summary.highestExpenseAmount * 0.8, summary.highestExpenseAmount]
    : [0, 0, 0, 0, 0, 0, 0];
  const categoryCountData = (summary?.categoryCount && hasExpenses)
    ? [1, 2, 3, summary.categoryCount]
    : [0, 0, 0, 0, 0, 0, 0];
  const recurringData = (summary?.recurringTotal && hasExpenses)
    ? [summary.recurringTotal, summary.recurringTotal, summary.recurringTotal]
    : [0, 0, 0, 0, 0, 0, 0];

  // Category chart color fallbacks
  const defaultColors = ["#9f78ff", "#ffb95f", "#4edea3", "#f43f5e", "#38bdf8"];
  const categoryPieData = (summary?.categoryBreakdown && summary.categoryBreakdown.length > 0)
    ? summary.categoryBreakdown.map((cat, idx) => ({
        name: cat.name,
        value: cat.amount,
        percentage: cat.percentage,
        color: cat.color || defaultColors[idx % defaultColors.length]
      }))
    : [{ name: "No Data", value: 1, percentage: 0, color: "#374151" }];

  // Mock Overview area chart points
  const overviewChartData = hasExpenses && expensesData?.content
    ? expensesData.content.slice(0, 7).reverse().map((t, idx) => ({
        date: `Day ${idx + 1}`,
        amount: t.amount
      }))
    : [
        { date: "May 12", amount: 0 },
        { date: "May 13", amount: 0 },
        { date: "May 14", amount: 0 },
        { date: "May 15", amount: 0 },
        { date: "May 16", amount: 0 },
        { date: "May 17", amount: 0 },
        { date: "May 18", amount: 0 },
      ];

  if (loading && !expensesData) {
    return (
      <div className="flex h-[75vh] items-center justify-center">
        <AfabLoader text="Loading Expenses Dashboard..." />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-700">
      
      {/* ── Page Header & Controls ── */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white sm:text-3xl tracking-tight">
            {t("title")}
          </h1>
          <p className="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
            {t("subtitle")}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Period Toggle Tabs */}
          <div className="flex items-center rounded-xl bg-gray-100 dark:bg-[#080c18] border border-gray-200 dark:border-gray-800/60 p-1 text-xs font-semibold">
            {(["WEEKLY", "MONTHLY", "YEARLY"] as const).map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  period === p
                    ? "bg-[#8b5cf6] text-white shadow-sm"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                }`}
              >
                {p}
              </button>
            ))}
          </div>

          <button
            onClick={handleExportCSV}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/[0.05] transition-all shadow-sm"
          >
            <Download className="h-4 w-4" />
            {t("export")}
          </button>
          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#8b5cf6] text-white text-xs font-bold hover:bg-[#7c3aed] transition-all shadow-lg shadow-[#8b5cf6]/25"
          >
            <Plus className="h-4 w-4" />
            {t("createExpense")}
          </button>
        </div>
      </div>

      {/* ── 5 KPI Summary Cards ── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <KpiCard
          title={tKpi("totalExpenses")}
          value={formatCurrency(summary?.totalExpenses || 0, currency)}
          change={(summary?.totalExpenses || 0) === 0 ? "0.0%" : "+8.4%"}
          isPositive={false}
          icon={Wallet}
          data={totalExpData}
        />
        <KpiCard
          title={tKpi("avgPerDay")}
          value={formatCurrency(summary?.avgPerDay || 0, currency)}
          change={(summary?.avgPerDay || 0) === 0 ? "0.0%" : "+12.6%"}
          isPositive={false}
          icon={CalendarIcon}
          data={avgExpData}
        />
        <KpiCard
          title={tKpi("highestExpense")}
          value={formatCurrency(summary?.highestExpenseAmount || 0, currency)}
          change={summary?.highestExpenseTitle || "None"}
          isPositive={true}
          icon={TrendingUp}
          data={highestExpData}
        />
        <KpiCard
          title={tKpi("categories")}
          value={(summary?.categoryCount || 0).toString()}
          change={tKpi("newThisMonth")}
          isPositive={true}
          icon={Layers}
          data={categoryCountData}
        />
        <KpiCard
          title={tKpi("recurring")}
          value={formatCurrency(summary?.recurringTotal || 0, currency)}
          change={`${summary?.recurringPercentage || 0}% ${tKpi("ofTotal")}`}
          isPositive={true}
          icon={Repeat}
          data={recurringData}
        />
      </div>

      {/* ── Middle Section: Charts & Categories ── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Expenses Overview Area Chart */}
        <div className="lg:col-span-2 rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-base font-bold text-gray-900 dark:text-white">
                {tCharts("overviewTitle")}
              </h3>
              <p className="text-xs text-gray-400 mt-0.5">
                Visual analysis of business spend over time
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className="inline-flex items-center gap-1 text-xs font-bold text-red-500 dark:text-red-400">
                <span className="h-2 w-2 rounded-full bg-red-500" />
                {formatCurrency(summary?.totalExpenses || 0, currency)}
              </span>
            </div>
          </div>

          <div className="h-64 w-full">
            <ChartContainer className="h-full w-full">
              <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0}>
                <AreaChart data={overviewChartData}>
                  <defs>
                    <linearGradient id="expenseChartGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.35} />
                      <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <Tooltip
                    formatter={(val: any) => [formatCurrency(val, currency), "Expense"]}
                    contentStyle={{
                      backgroundColor: "rgba(12, 16, 28, 0.95)",
                      borderColor: "rgba(255, 255, 255, 0.1)",
                      borderRadius: "12px",
                      color: "#fff",
                      fontSize: "12px",
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="amount"
                    stroke="#8b5cf6"
                    strokeWidth={2.5}
                    fillOpacity={1}
                    fill="url(#expenseChartGrad)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </ChartContainer>
          </div>
        </div>

        {/* By Category Donut Chart */}
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-bold text-gray-900 dark:text-white">
              {tCharts("categoryTitle")}
            </h3>
          </div>

          <div className="relative h-44 w-full flex items-center justify-center my-2">
            <ChartContainer className="h-full w-full">
              <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0}>
                <PieChart>
                  <Pie
                    data={categoryPieData}
                    innerRadius={55}
                    outerRadius={75}
                    paddingAngle={5}
                    dataKey="value"
                    stroke="none"
                  >
                    {categoryPieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip
                    formatter={(val: any) => [formatCurrency(val, currency), ""]}
                    contentStyle={{
                      backgroundColor: "rgba(12, 16, 28, 0.95)",
                      borderColor: "rgba(255, 255, 255, 0.1)",
                      borderRadius: "10px",
                      color: "#fff",
                      fontSize: "12px",
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </ChartContainer>

            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-lg font-extrabold text-gray-900 dark:text-white">
                {formatCurrency(summary?.totalExpenses || 0, currency)}
              </span>
              <span className="text-[10px] font-medium text-gray-400 uppercase">
                Total Spend
              </span>
            </div>
          </div>

          <div className="space-y-2.5 mt-2">
            {categoryPieData.slice(0, 3).map((cat) => (
              <div key={cat.name} className="flex items-center justify-between text-xs font-medium">
                <div className="flex items-center gap-2">
                  <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ backgroundColor: cat.color }} />
                  <span className="text-gray-700 dark:text-gray-300">{cat.name}</span>
                </div>
                <div className="text-right">
                  <span className="font-bold text-gray-900 dark:text-white">{cat.percentage}%</span>
                  <span className="text-[10px] text-gray-400 ml-1.5">({formatCurrency(cat.value, currency)})</span>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

      {/* ── Bottom Section: Data Table & Side Cards ── */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        
        {/* Expenses Table (3 columns) */}
        <div className="lg:col-span-3 rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm overflow-hidden flex flex-col justify-between">
          <div>
            {/* Table Header Controls */}
            <div className="p-5 border-b border-gray-100 dark:border-gray-800/60 flex flex-col sm:flex-row gap-3 items-center justify-between">
              <div className="relative w-full sm:max-w-xs">
                <Search className="pointer-events-none absolute inset-y-0 left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  ref={searchInputRef}
                  type="text"
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(0);
                  }}
                  placeholder={tFilters("searchPlaceholder")}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] pl-9 pr-12 py-2 text-xs font-semibold text-gray-900 dark:text-white placeholder-gray-400 focus:border-[#8b5cf6] focus:outline-none"
                />
                <span className="absolute inset-y-0 right-3 top-1/2 -translate-y-1/2 text-[10px] font-mono text-gray-400">
                  ⌘K
                </span>
              </div>

              <div className="flex items-center gap-2.5 w-full sm:w-auto">
                <select
                  value={categoryFilter}
                  onChange={(e) => {
                    setCategoryFilter(e.target.value);
                    setPage(0);
                  }}
                  className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-semibold text-gray-700 dark:text-gray-300 focus:border-[#8b5cf6] focus:outline-none"
                >
                  <option value="">{tFilters("allCategories")}</option>
                  {categories.map((cat) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Table View */}
            {!expensesData || expensesData.content.length === 0 ? (
              <div className="py-16 text-center">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-gray-100 dark:bg-white/5 text-gray-400 mb-3">
                  <Wallet className="h-6 w-6" />
                </div>
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tTable("noExpenses")}</h3>
                <p className="text-xs text-gray-400 mt-1 max-w-sm mx-auto">{tTable("noExpensesSubtitle")}</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-gray-100 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18]/50 text-gray-400 font-bold uppercase tracking-wider">
                      <th className="px-6 py-3.5">{tTable("date")}</th>
                      <th className="px-6 py-3.5">{tTable("description")}</th>
                      <th className="px-6 py-3.5">{tTable("category")}</th>
                      <th className="px-6 py-3.5">{tTable("account")}</th>
                      <th className="px-6 py-3.5 text-right">{tTable("amount")}</th>
                      <th className="px-6 py-3.5 text-center">{tTable("status")}</th>
                      <th className="px-6 py-3.5 text-right">{tTable("actions")}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800/40 text-gray-700 dark:text-gray-300 font-medium">
                    {expensesData.content.map((tx) => (
                      <tr
                        key={tx.id}
                        className="hover:bg-gray-50/80 dark:hover:bg-white/[0.02] transition-colors group cursor-pointer"
                        onClick={() => setSelectedTx(tx)}
                      >
                        <td className="px-6 py-4 text-gray-500 dark:text-gray-400">{tx.transactionDate}</td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-purple-600 text-white font-bold text-xs shadow-sm">
                              <ArrowDownLeft className="h-4 w-4" />
                            </div>
                            <div>
                              <p className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-[#8b5cf6] transition-colors">
                                {tx.description}
                              </p>
                              <p className="text-[10px] text-gray-400 font-normal">Ref: #{tx.id.substring(0, 8)}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-[11px] font-semibold border border-current/20"
                            style={{
                              backgroundColor: `${tx.categoryColor}15`,
                              color: tx.categoryColor,
                            }}
                          >
                            <span className="h-1.5 w-1.5 rounded-full" style={{ backgroundColor: tx.categoryColor }} />
                            {tx.categoryName}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <span className="inline-flex items-center gap-1.5 rounded-md bg-gray-100 dark:bg-white/5 px-2 py-0.5 text-[11px] font-medium text-gray-600 dark:text-gray-400">
                            <CreditCard className="h-3 w-3 text-gray-400" />
                            {tx.paymentMethod.replace(/_/g, " ")}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right">
                          <span className="text-sm font-bold text-gray-900 dark:text-white">
                            -{formatCurrency(tx.amount, tx.currency || currency)}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-center">
                          <span className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[10px] font-bold bg-emerald-500/10 text-emerald-500">
                            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                            {tx.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right">
                          <button
                            onClick={() => setSelectedTx(tx)}
                            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05]"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Pagination Controls */}
          {expensesData && expensesData.totalPages > 1 && (
            <div className="p-4 border-t border-gray-100 dark:border-gray-800/60 flex items-center justify-between text-xs text-gray-500">
              <span>
                Showing {page * 15 + 1} to {Math.min((page + 1) * 15, expensesData.totalElements)} of {expensesData.totalElements}
              </span>
              <div className="flex items-center gap-1">
                <button
                  disabled={page === 0}
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 disabled:opacity-30 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
                <span className="px-3 font-semibold text-gray-900 dark:text-white">{page + 1}</span>
                <button
                  disabled={page >= expensesData.totalPages - 1}
                  onClick={() => setPage((p) => p + 1)}
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 disabled:opacity-30 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Side Cards Column (1 column) */}
        <div className="space-y-6">
          
          {/* Top Spending Categories Progress */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
                {tWidgets("topCategories")}
              </h4>
            </div>

            <div className="space-y-3.5">
              {(summary?.categoryBreakdown || []).slice(0, 4).map((cat, idx) => (
                <div key={cat.name} className="space-y-1">
                  <div className="flex items-center justify-between text-xs font-semibold">
                    <span className="text-gray-900 dark:text-white">{cat.name}</span>
                    <span className="text-gray-400 font-mono">{formatCurrency(cat.amount, currency)}</span>
                  </div>
                  <div className="h-1.5 w-full bg-gray-100 dark:bg-white/5 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{
                        width: `${cat.percentage}%`,
                        backgroundColor: cat.color || defaultColors[idx % defaultColors.length]
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Recurring Subscriptions */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
                {tWidgets("recurring")}
              </h4>
            </div>

            <div className="space-y-3">
              {(summary?.recurringList || []).map((item) => (
                <div key={item.name} className="flex items-center justify-between p-2 rounded-xl hover:bg-gray-50 dark:hover:bg-white/[0.02] transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-purple-500/10 text-purple-400 font-bold text-xs border border-purple-500/20">
                      <Repeat className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-gray-900 dark:text-white">{item.name}</p>
                      <p className="text-[10px] text-gray-400 uppercase font-medium">{item.billingCycle} • {item.dueDate}</p>
                    </div>
                  </div>
                  <span className="text-xs font-bold text-gray-900 dark:text-white font-mono">
                    {formatCurrency(item.amount, currency)}
                  </span>
                </div>
              ))}
            </div>
          </div>

        </div>

      </div>

      {/* Transaction Detail Drawer Modal */}
      {selectedTx && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="relative w-full max-w-md overflow-hidden rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 pb-4">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-600 text-white font-bold text-xs">
                  <ArrowDownLeft className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-gray-900 dark:text-white">{selectedTx.description}</h3>
                  <p className="text-xs text-gray-400">Ref: #{selectedTx.id}</p>
                </div>
              </div>
              <button onClick={() => setSelectedTx(null)} className="text-gray-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-5 space-y-4 text-xs">
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Amount</span>
                <span className="text-base font-bold text-white">
                  -{formatCurrency(selectedTx.amount, selectedTx.currency || currency)}
                </span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Category</span>
                <span className="font-semibold text-white">{selectedTx.categoryName}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Payment Method</span>
                <span className="font-semibold text-white">{selectedTx.paymentMethod.replace(/_/g, " ")}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Date</span>
                <span className="font-semibold text-white">{selectedTx.transactionDate}</span>
              </div>
            </div>

            <div className="mt-6 flex justify-end">
              <button
                onClick={() => setSelectedTx(null)}
                className="px-4 py-2 rounded-xl bg-gray-100 dark:bg-white/10 text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Expense Modal */}
      <AddTransactionModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={() => fetchData()}
        categories={categories}
        currency={currency}
      />

    </div>
  );
}
