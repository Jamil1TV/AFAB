"use client";

import { useState, useEffect } from "react";
import { 
  FileText, 
  Download, 
  TrendingUp, 
  TrendingDown, 
  DollarSign, 
  PieChart as PieChartIcon, 
  BarChart3, 
  Calendar, 
  ArrowUpRight, 
  ArrowDownRight, 
  Sparkles, 
  Lock, 
  Loader2, 
  ChevronRight,
  Filter,
  CheckCircle2,
  AlertCircle
} from "lucide-react";
import { useLocale } from "next-intl";
import { motion, AnimatePresence } from "framer-motion";
import { 
  ResponsiveContainer, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  Tooltip, 
  Cell, 
  PieChart, 
  Pie 
} from "recharts";
import { 
  ReportService, 
  ProfitAndLossReport, 
  CashFlowReport, 
  ComparisonReport 
} from "@/lib/api/reports";
import { SubscriptionService, SubscriptionSnapshot } from "@/lib/api/subscription";
import { toast } from "sonner";
import { Link } from "@/i18n/routing";

export default function ReportsPage() {
  const locale = useLocale();
  const isAr = locale === "ar";

  const [activeTab, setActiveTab] = useState<"pnl" | "cashflow" | "comparison">("pnl");
  const [period, setPeriod] = useState<string>("this_month");
  const [pnlReport, setPnlReport] = useState<ProfitAndLossReport | null>(null);
  const [cashFlowReport, setCashFlowReport] = useState<CashFlowReport | null>(null);
  const [comparisonReport, setComparisonReport] = useState<ComparisonReport | null>(null);
  const [subscription, setSubscription] = useState<SubscriptionSnapshot | null>(null);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isExportingCsv, setIsExportingCsv] = useState<boolean>(false);
  const [isExportingPdf, setIsExportingPdf] = useState<boolean>(false);
  const [planGatedMessage, setPlanGatedMessage] = useState<string | null>(null);

  useEffect(() => {
    loadSubscription();
  }, []);

  useEffect(() => {
    loadReportData();
  }, [activeTab, period]);

  async function loadSubscription() {
    try {
      const sub = await SubscriptionService.getMySubscription();
      setSubscription(sub);
    } catch (err) {
      console.warn("Could not load subscription for reports", err);
    }
  }

  async function loadReportData() {
    setIsLoading(true);
    setPlanGatedMessage(null);
    try {
      if (activeTab === "pnl") {
        const data = await ReportService.getProfitAndLoss(period);
        setPnlReport(data);
      } else if (activeTab === "cashflow") {
        const data = await ReportService.getCashFlow(period);
        setCashFlowReport(data);
      } else if (activeTab === "comparison") {
        const data = await ReportService.getComparison(period, "last_month");
        setComparisonReport(data);
      }
    } catch (err: any) {
      if (err?.code === "PLAN_LIMIT_REACHED" || err?.status === 403) {
        setPlanGatedMessage(err.message || (isAr ? "هذا التقرير يتطلب ترقية خطتك" : "This report requires a plan upgrade"));
      } else {
        toast.error(err?.message || (isAr ? "فشل تحميل التقرير" : "Failed to load report data"));
      }
    } finally {
      setIsLoading(false);
    }
  }

  const handleExportCsv = async () => {
    setIsExportingCsv(true);
    try {
      await ReportService.downloadCsv(period);
      toast.success(isAr ? "تم تصدير ملف CSV بنجاح!" : "CSV report exported successfully!");
      loadSubscription(); // update remaining quota
    } catch (err: any) {
      toast.error(err?.message || (isAr ? "فشل تصدير ملف CSV" : "Failed to export CSV"));
    } finally {
      setIsExportingCsv(false);
    }
  };

  const handleExportPdf = async () => {
    setIsExportingPdf(true);
    try {
      await ReportService.downloadPdf(period);
      toast.success(isAr ? "تم تصدير ملف PDF بنجاح!" : "PDF statement exported successfully!");
      loadSubscription(); // update remaining quota
    } catch (err: any) {
      toast.error(err?.message || (isAr ? "فشل تصدير ملف PDF" : "Failed to export PDF"));
    } finally {
      setIsExportingPdf(false);
    }
  };

  const currency = pnlReport?.currency || cashFlowReport?.currency || "USD";
  const exportLimit = subscription?.entitlements?.["export.per_month"] ?? 5;
  const exportUsed = subscription?.usage?.["export.per_month"] ?? 0;

  const COLORS = ["#7c3aed", "#10b981", "#3b82f6", "#f59e0b", "#ec4899", "#8b5cf6"];

  return (
    <div className="space-y-8 pb-12">
      {/* ── Page Header ── */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-purple-600/10 dark:bg-purple-500/20 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <FileText className="w-5 h-5" />
            </div>
            <span>{isAr ? "التقارير المالية والتحليلات" : "Financial Reports & Analytics"}</span>
          </h1>
          <p className="text-slate-500 dark:text-slate-400 text-sm mt-1">
            {isAr 
              ? "بيانات مالية شاملة وقوائم دخل مبنية بدقة على الأساس النقدي الفعلي."
              : "Comprehensive cash-basis financial statements and performance metrics."}
          </p>
        </div>

        {/* Export Toolbar */}
        <div className="flex flex-wrap items-center gap-2.5">
          <div className="hidden lg:flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-100 dark:bg-[#11172A] border border-slate-200 dark:border-slate-800 text-xs text-slate-600 dark:text-slate-300">
            <Sparkles className="w-3.5 h-3.5 text-purple-500" />
            <span>
              {isAr ? "عمليات التصدير الشهرية:" : "Monthly Exports:"}{" "}
              <strong className="text-purple-600 dark:text-purple-400">
                {exportUsed} / {exportLimit === -1 ? (isAr ? "غير محدود" : "Unlimited") : exportLimit}
              </strong>
            </span>
          </div>

          <button
            type="button"
            onClick={handleExportCsv}
            disabled={isExportingCsv || !!planGatedMessage}
            className="px-4 py-2 rounded-xl bg-white dark:bg-[#11172A] hover:bg-slate-50 dark:hover:bg-[#161F38] text-slate-700 dark:text-slate-200 font-semibold text-xs border border-slate-200 dark:border-slate-800 shadow-sm flex items-center gap-2 transition-all cursor-pointer disabled:opacity-50"
          >
            {isExportingCsv ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin" />
            ) : (
              <Download className="w-3.5 h-3.5 text-slate-500" />
            )}
            <span>{isAr ? "تصدير CSV" : "Export CSV"}</span>
          </button>

          <button
            type="button"
            onClick={handleExportPdf}
            disabled={isExportingPdf || !!planGatedMessage}
            className="px-4 py-2 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-semibold text-xs shadow-md shadow-purple-900/30 flex items-center gap-2 transition-all cursor-pointer hover:scale-[1.01] active:scale-[0.99] disabled:opacity-50"
          >
            {isExportingPdf ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin" />
            ) : (
              <Download className="w-3.5 h-3.5" />
            )}
            <span>{isAr ? "تحميل تقرير PDF" : "Download PDF"}</span>
          </button>
        </div>
      </div>

      {/* ── Filters & Tabs Bar ── */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 p-2 rounded-2xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm">
        {/* Report Type Tabs */}
        <div className="flex items-center gap-1 overflow-x-auto pb-1 sm:pb-0">
          <button
            type="button"
            onClick={() => setActiveTab("pnl")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === "pnl"
                ? "bg-purple-600 text-white shadow-md shadow-purple-900/30"
                : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
            }`}
          >
            <BarChart3 className="w-3.5 h-3.5" />
            <span>{isAr ? "الأرباح والخسائر (P&L)" : "Profit & Loss (P&L)"}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("cashflow")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === "cashflow"
                ? "bg-purple-600 text-white shadow-md shadow-purple-900/30"
                : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
            }`}
          >
            <TrendingUp className="w-3.5 h-3.5" />
            <span>{isAr ? "التدفقات النقدية" : "Cash Flow"}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("comparison")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === "comparison"
                ? "bg-purple-600 text-white shadow-md shadow-purple-900/30"
                : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
            }`}
          >
            <Sparkles className="w-3.5 h-3.5 text-amber-500" />
            <span>{isAr ? "مقارنة الفترات" : "Period Comparison"}</span>
          </button>
        </div>

        {/* Period Dropdown / Pills */}
        <div className="flex items-center gap-1.5 self-end sm:self-auto">
          <Calendar className="w-4 h-4 text-slate-400 ms-1" />
          <select
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
            className="px-3 py-1.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#11172A] text-xs font-semibold text-slate-700 dark:text-slate-200 focus:outline-none focus:border-purple-500"
          >
            <option value="this_month">{isAr ? "هذا الشهر" : "This Month"}</option>
            <option value="last_month">{isAr ? "الشهر الماضي" : "Last Month"}</option>
            <option value="this_quarter">{isAr ? "هذا الربع (Quarter)" : "This Quarter"}</option>
            <option value="this_year">{isAr ? "هذا العام (سنوي)" : "This Year (Annual)"}</option>
            <option value="last_year">{isAr ? "العام الماضي" : "Last Year"}</option>
          </select>
        </div>
      </div>

      {/* ── Plan Gated Notice (If Level Restricted) ── */}
      {planGatedMessage && (
        <div className="p-6 rounded-3xl bg-gradient-to-r from-purple-900/20 via-indigo-900/20 to-purple-900/20 border-2 border-purple-500/40 text-center space-y-4">
          <div className="w-12 h-12 rounded-full bg-purple-500/20 text-purple-400 flex items-center justify-center mx-auto">
            <Lock className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">
              {isAr ? "ميزة متقدمة تتطلب ترقية الخطة" : "Advanced Report Requires Upgrade"}
            </h3>
            <p className="text-xs text-slate-600 dark:text-slate-300 max-w-md mx-auto mt-1">
              {planGatedMessage}
            </p>
          </div>
          <Link
            href="/dashboard/plans"
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-bold text-xs shadow-lg shadow-purple-900/40 transition-colors"
          >
            <span>{isAr ? "ترقية الخطة الآن" : "Upgrade Plan Now"}</span>
            <ChevronRight className="w-4 h-4 rtl:rotate-180" />
          </Link>
        </div>
      )}

      {isLoading ? (
        <div className="py-20 flex flex-col items-center justify-center gap-3 text-slate-400">
          <Loader2 className="w-8 h-8 animate-spin text-purple-600" />
          <span className="text-xs font-medium">{isAr ? "جاري تجميع وحساب التقرير المالي..." : "Compiling financial statements..."}</span>
        </div>
      ) : !planGatedMessage && (
        <>
          {/* ══════════════════════════════════════════════════════════════
              TAB 1: PROFIT & LOSS (P&L)
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === "pnl" && pnlReport && (
            <div className="space-y-8">
              {/* Top 4 Financial KPI Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                {/* Total Revenue */}
                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm relative overflow-hidden">
                  <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-semibold mb-2">
                    <span>{isAr ? "إجمالي الإيرادات" : "Total Revenue"}</span>
                    <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                      <ArrowUpRight className="w-4 h-4" />
                    </div>
                  </div>
                  <div className="text-2xl sm:text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
                    {currency} {pnlReport.totalRevenue?.toLocaleString()}
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1">
                    {isAr ? "الإيرادات النقدية المكتسبة" : "Actual cash received"}
                  </p>
                </div>

                {/* Total Expenses */}
                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm relative overflow-hidden">
                  <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-semibold mb-2">
                    <span>{isAr ? "إجمالي المصروفات" : "Total Expenses"}</span>
                    <div className="w-8 h-8 rounded-xl bg-rose-500/10 text-rose-500 flex items-center justify-center">
                      <ArrowDownRight className="w-4 h-4" />
                    </div>
                  </div>
                  <div className="text-2xl sm:text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
                    {currency} {pnlReport.totalExpenses?.toLocaleString()}
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1">
                    {isAr ? "المصروفات التشغيلية المدفوعة" : "Operating cash spent"}
                  </p>
                </div>

                {/* Net Operating Income */}
                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm relative overflow-hidden">
                  <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-semibold mb-2">
                    <span>{isAr ? "صافي الدخل التشغيلي" : "Net Operating Income"}</span>
                    <div className="w-8 h-8 rounded-xl bg-purple-500/10 text-purple-500 flex items-center justify-center">
                      <DollarSign className="w-4 h-4" />
                    </div>
                  </div>
                  <div className={`text-2xl sm:text-3xl font-extrabold tracking-tight ${
                    pnlReport.netOperatingIncome >= 0 ? "text-emerald-500" : "text-rose-500"
                  }`}>
                    {currency} {pnlReport.netOperatingIncome?.toLocaleString()}
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1">
                    {isAr ? "الفائض النقدي بعد النفقات" : "Revenue minus expenses"}
                  </p>
                </div>

                {/* Profit Margin */}
                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm relative overflow-hidden">
                  <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-semibold mb-2">
                    <span>{isAr ? "هامش الربح الصافي" : "Net Profit Margin"}</span>
                    <div className="w-8 h-8 rounded-xl bg-indigo-500/10 text-indigo-500 flex items-center justify-center">
                      <TrendingUp className="w-4 h-4" />
                    </div>
                  </div>
                  <div className="text-2xl sm:text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
                    {pnlReport.profitMarginPct?.toFixed(1)}%
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1">
                    {isAr ? "نسبة الربح من الإيرادات" : "Efficiency of operations"}
                  </p>
                </div>
              </div>

              {/* Category Breakdowns: Revenue vs Expenses */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Revenue Breakdown */}
                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm space-y-4">
                  <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
                    <span>{isAr ? "تفصيل الإيرادات حسب التصنيف" : "Revenue by Category"}</span>
                  </h3>

                  {pnlReport.revenueBreakdown && pnlReport.revenueBreakdown.length > 0 ? (
                    <div className="space-y-3">
                      {pnlReport.revenueBreakdown.map((cat, idx) => (
                        <div key={idx} className="space-y-1.5">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-semibold text-slate-700 dark:text-slate-200">{cat.categoryName}</span>
                            <span className="font-bold text-slate-900 dark:text-white">
                              {currency} {cat.amount.toLocaleString()} ({cat.percentage.toFixed(1)}%)
                            </span>
                          </div>
                          <div className="w-full h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                            <div 
                              className="h-full bg-emerald-500 rounded-full transition-all duration-500"
                              style={{ width: `${Math.min(100, Math.max(2, cat.percentage))}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-xs text-slate-400 py-6 text-center">
                      {isAr ? "لا توجد معاملات إيرادات مسجلة لهذه الفترة." : "No income recorded for this period."}
                    </p>
                  )}
                </div>

                {/* Expense Breakdown */}
                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm space-y-4">
                  <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-rose-500" />
                    <span>{isAr ? "تفصيل المصروفات حسب التصنيف" : "Expenses by Category"}</span>
                  </h3>

                  {pnlReport.expenseBreakdown && pnlReport.expenseBreakdown.length > 0 ? (
                    <div className="space-y-3">
                      {pnlReport.expenseBreakdown.map((cat, idx) => (
                        <div key={idx} className="space-y-1.5">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-semibold text-slate-700 dark:text-slate-200">{cat.categoryName}</span>
                            <span className="font-bold text-slate-900 dark:text-white">
                              {currency} {cat.amount.toLocaleString()} ({cat.percentage.toFixed(1)}%)
                            </span>
                          </div>
                          <div className="w-full h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                            <div 
                              className="h-full bg-rose-500 rounded-full transition-all duration-500"
                              style={{ width: `${Math.min(100, Math.max(2, cat.percentage))}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-xs text-slate-400 py-6 text-center">
                      {isAr ? "لا توجد مصروفات مسجلة لهذه الفترة." : "No expenses recorded for this period."}
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              TAB 2: CASH FLOW STATEMENT
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === "cashflow" && cashFlowReport && (
            <div className="space-y-8">
              {/* Summary Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm">
                  <span className="text-xs font-semibold text-slate-500 dark:text-slate-400">
                    {isAr ? "التدفق النقدي الداخل (Inflow)" : "Total Cash Inflow"}
                  </span>
                  <div className="text-2xl font-extrabold text-emerald-500 mt-2">
                    +{currency} {cashFlowReport.cashInflow?.toLocaleString()}
                  </div>
                </div>

                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm">
                  <span className="text-xs font-semibold text-slate-500 dark:text-slate-400">
                    {isAr ? "التدفق النقدي الخارج (Outflow)" : "Total Cash Outflow"}
                  </span>
                  <div className="text-2xl font-extrabold text-rose-500 mt-2">
                    -{currency} {cashFlowReport.cashOutflow?.toLocaleString()}
                  </div>
                </div>

                <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm">
                  <span className="text-xs font-semibold text-slate-500 dark:text-slate-400">
                    {isAr ? "صافي التغير النقدي" : "Net Cash Change"}
                  </span>
                  <div className={`text-2xl font-extrabold mt-2 ${
                    cashFlowReport.netCashChange >= 0 ? "text-emerald-500" : "text-rose-500"
                  }`}>
                    {currency} {cashFlowReport.netCashChange?.toLocaleString()}
                  </div>
                </div>
              </div>

              {/* Monthly Trend Chart */}
              <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm space-y-4">
                <h3 className="text-base font-bold text-slate-900 dark:text-white">
                  {isAr ? "مسار التدفقات النقدية (آخر 6 أشهر)" : "6-Month Cash Flow Trend"}
                </h3>

                <div className="h-72 w-full pt-4">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={cashFlowReport.monthlyTrend || []}>
                      <XAxis dataKey="month" stroke="#64748b" fontSize={11} tickLine={false} />
                      <YAxis stroke="#64748b" fontSize={11} tickLine={false} />
                      <Tooltip 
                        contentStyle={{ 
                          backgroundColor: "#0F172A", 
                          borderColor: "#334155", 
                          borderRadius: "12px",
                          color: "#fff",
                          fontSize: "12px"
                        }} 
                      />
                      <Bar dataKey="inflow" name={isAr ? "الداخل" : "Inflow"} fill="#10b981" radius={[6, 6, 0, 0]} />
                      <Bar dataKey="outflow" name={isAr ? "الخارج" : "Outflow"} fill="#ef4444" radius={[6, 6, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              TAB 3: PERIOD COMPARISON
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === "comparison" && comparisonReport && (
            <div className="space-y-6">
              <div className="p-6 rounded-3xl bg-white dark:bg-[#0D1224] border border-slate-200 dark:border-slate-800/80 shadow-sm space-y-6">
                <h3 className="text-base font-bold text-slate-900 dark:text-white">
                  {isAr ? "مقارنة النمو والأداء بين الفترات" : "Comparative Financial Variance"}
                </h3>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  {/* Revenue Growth */}
                  <div className="p-5 rounded-2xl bg-slate-50 dark:bg-[#11172A] border border-slate-200 dark:border-slate-800 space-y-2">
                    <span className="text-xs font-semibold text-slate-500">{isAr ? "نمو الإيرادات" : "Revenue Growth"}</span>
                    <div className="flex items-baseline gap-2">
                      <span className="text-2xl font-bold text-slate-900 dark:text-white">
                        {currency} {comparisonReport.primaryRevenue?.toLocaleString()}
                      </span>
                      <span className={`text-xs font-extrabold px-2 py-0.5 rounded-full ${
                        comparisonReport.revenueDifferencePct >= 0 
                          ? "bg-emerald-500/15 text-emerald-500" 
                          : "bg-rose-500/15 text-rose-500"
                      }`}>
                        {comparisonReport.revenueDifferencePct >= 0 ? "+" : ""}
                        {comparisonReport.revenueDifferencePct?.toFixed(1)}%
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-400">
                      {isAr ? "مقارنة بالفترة السابقة:" : "vs previous:"} {currency} {comparisonReport.comparisonRevenue?.toLocaleString()}
                    </p>
                  </div>

                  {/* Expenses Change */}
                  <div className="p-5 rounded-2xl bg-slate-50 dark:bg-[#11172A] border border-slate-200 dark:border-slate-800 space-y-2">
                    <span className="text-xs font-semibold text-slate-500">{isAr ? "تغير المصروفات" : "Expense Change"}</span>
                    <div className="flex items-baseline gap-2">
                      <span className="text-2xl font-bold text-slate-900 dark:text-white">
                        {currency} {comparisonReport.primaryExpenses?.toLocaleString()}
                      </span>
                      <span className={`text-xs font-extrabold px-2 py-0.5 rounded-full ${
                        comparisonReport.expensesDifferencePct <= 0 
                          ? "bg-emerald-500/15 text-emerald-500" 
                          : "bg-rose-500/15 text-rose-500"
                      }`}>
                        {comparisonReport.expensesDifferencePct >= 0 ? "+" : ""}
                        {comparisonReport.expensesDifferencePct?.toFixed(1)}%
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-400">
                      {isAr ? "مقارنة بالفترة السابقة:" : "vs previous:"} {currency} {comparisonReport.comparisonExpenses?.toLocaleString()}
                    </p>
                  </div>

                  {/* Net Income Growth */}
                  <div className="p-5 rounded-2xl bg-slate-50 dark:bg-[#11172A] border border-slate-200 dark:border-slate-800 space-y-2">
                    <span className="text-xs font-semibold text-slate-500">{isAr ? "تغير صافي الدخل" : "Net Income Change"}</span>
                    <div className="flex items-baseline gap-2">
                      <span className="text-2xl font-bold text-slate-900 dark:text-white">
                        {currency} {comparisonReport.primaryNetIncome?.toLocaleString()}
                      </span>
                      <span className={`text-xs font-extrabold px-2 py-0.5 rounded-full ${
                        comparisonReport.netIncomeDifferencePct >= 0 
                          ? "bg-emerald-500/15 text-emerald-500" 
                          : "bg-rose-500/15 text-rose-500"
                      }`}>
                        {comparisonReport.netIncomeDifferencePct >= 0 ? "+" : ""}
                        {comparisonReport.netIncomeDifferencePct?.toFixed(1)}%
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-400">
                      {isAr ? "مقارنة بالفترة السابقة:" : "vs previous:"} {currency} {comparisonReport.comparisonNetIncome?.toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
