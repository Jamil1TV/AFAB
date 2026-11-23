"use client";

import { useState, useEffect } from "react";
import { 
  FileText, 
  Download, 
  TrendingUp, 
  TrendingDown, 
  DollarSign, 
  CreditCard,
  Wallet,
  Layers,
  PieChart as PieChartIcon, 
  BarChart3, 
  Calendar, 
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
  CartesianGrid,
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
import { PageHeader } from "@/components/dashboard/PageHeader";
import { KpiCard } from "@/components/dashboard/KpiCard";
import { EmptyState } from "@/components/dashboard/EmptyState";
import { AfabLoader } from "@/components/ui/afab-loader";
import { ChartContainer } from "@/components/ui/chart-container";
import { CHART_PALETTE, chartSemantic, chartTooltipStyle } from "@/lib/design-tokens";
import { formatCurrency } from "@/lib/currency";

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

  const COLORS = CHART_PALETTE;

  return (
    <div className="afab-page">
      {/* ── Page Header ── */}
      <PageHeader
        title={isAr ? "التقارير المالية والتحليلات" : "Financial Reports & Analytics"}
        subtitle={
          isAr 
            ? "بيانات مالية شاملة وقوائم دخل مبنية بدقة على الأساس النقدي الفعلي."
            : "Comprehensive cash-basis financial statements and performance metrics."
        }
        actions={
          <>
            <div className="hidden lg:flex items-center gap-1.5 px-3 py-2 rounded-xl bg-gray-50/50 dark:bg-[#080c18] border border-gray-200 dark:border-gray-800/60 text-xs text-gray-600 dark:text-gray-300">
              <Sparkles className="w-3.5 h-3.5 text-[#8b5cf6]" />
              <span>
                {isAr ? "عمليات التصدير الشهرية:" : "Monthly Exports:"}{" "}
                <strong className="text-[#7c3aed] dark:text-[#a78bfa]">
                  {exportUsed} / {exportLimit === -1 ? (isAr ? "غير محدود" : "Unlimited") : exportLimit}
                </strong>
              </span>
            </div>

            <button
              type="button"
              onClick={handleExportCsv}
              disabled={isExportingCsv || !!planGatedMessage}
              className="afab-btn-secondary"
            >
              {isExportingCsv ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <Download className="w-3.5 h-3.5 text-gray-500 dark:text-gray-400" />
              )}
              <span>{isAr ? "تصدير CSV" : "Export CSV"}</span>
            </button>

            <button
              type="button"
              onClick={handleExportPdf}
              disabled={isExportingPdf || !!planGatedMessage}
              className="afab-btn-primary"
            >
              {isExportingPdf ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <Download className="w-3.5 h-3.5" />
              )}
              <span>{isAr ? "تحميل تقرير PDF" : "Download PDF"}</span>
            </button>
          </>
        }
      />

      {/* ── Filters & Tabs Bar ── */}
      <div className="afab-toolbar flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        {/* Report Type Tabs */}
        <div className="afab-segmented">
          <button
            type="button"
            onClick={() => setActiveTab("pnl")}
            className={`afab-segment ${
              activeTab === "pnl" ? "afab-segment-active" : ""
            }`}
          >
            <BarChart3 className="w-3.5 h-3.5" />
            <span>{isAr ? "الأرباح والخسائر (P&L)" : "Profit & Loss (P&L)"}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("cashflow")}
            className={`afab-segment ${
              activeTab === "cashflow" ? "afab-segment-active" : ""
            }`}
          >
            <TrendingUp className="w-3.5 h-3.5" />
            <span>{isAr ? "التدفقات النقدية" : "Cash Flow"}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("comparison")}
            className={`afab-segment ${
              activeTab === "comparison" ? "afab-segment-active" : ""
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            <span>{isAr ? "مقارنة الفترات" : "Period Comparison"}</span>
          </button>
        </div>

        {/* Period Dropdown / Pills */}
        <div className="flex items-center gap-1.5 self-end sm:self-auto">
          <Calendar className="w-4 h-4 text-gray-400 dark:text-gray-500 ms-1" />
          <select
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
            className="afab-select"
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
        <div className="afab-card p-6 text-center space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa] flex items-center justify-center mx-auto">
            <Lock className="w-6 h-6" />
          </div>
          <div>
            <h3 className="afab-card-title">
              {isAr ? "ميزة متقدمة تتطلب ترقية الخطة" : "Advanced Report Requires Upgrade"}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400 max-w-md mx-auto mt-1">
              {planGatedMessage}
            </p>
          </div>
          <Link
            href="/dashboard/plans"
            className="afab-btn-premium"
          >
            <span>{isAr ? "ترقية الخطة الآن" : "Upgrade Plan Now"}</span>
            <ChevronRight className="w-4 h-4 rtl:rotate-180" />
          </Link>
        </div>
      )}

      {isLoading ? (
        <AfabLoader
          className="py-20"
          text={isAr ? "جاري تجميع وحساب التقرير المالي..." : "Compiling financial statements..."}
        />
      ) : !planGatedMessage && (
        <>
          {/* ══════════════════════════════════════════════════════════════
              TAB 1: PROFIT & LOSS (P&L)
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === "pnl" && pnlReport && (
            <div className="space-y-8">
              {/* Top 4 Financial KPI Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                {/* Total Revenue */}
                <KpiCard
                  title={isAr ? "إجمالي الإيرادات" : "Total Revenue"}
                  value={formatCurrency(pnlReport.totalRevenue, currency)}
                  change={(pnlReport.totalRevenue || 0) === 0 ? "0.0%" : (isAr ? "الإيرادات المكتسبة" : "Cash received")}
                  isPositive={true}
                  icon={DollarSign}
                  data={
                    pnlReport.revenueBreakdown && pnlReport.revenueBreakdown.length > 0
                      ? [0, ...pnlReport.revenueBreakdown.map((c) => c.amount)]
                      : (pnlReport.totalRevenue || 0) > 0
                        ? [pnlReport.totalRevenue * 0.25, pnlReport.totalRevenue * 0.6, pnlReport.totalRevenue]
                        : [0, 0, 0, 0]
                  }
                />

                {/* Total Expenses */}
                <KpiCard
                  title={isAr ? "إجمالي المصروفات" : "Total Expenses"}
                  value={formatCurrency(pnlReport.totalExpenses, currency)}
                  change={(pnlReport.totalExpenses || 0) === 0 ? "0.0%" : (isAr ? "المصروفات التشغيلية" : "Cash spent")}
                  isPositive={false}
                  icon={CreditCard}
                  data={
                    pnlReport.expenseBreakdown && pnlReport.expenseBreakdown.length > 0
                      ? [0, ...pnlReport.expenseBreakdown.map((c) => c.amount)]
                      : (pnlReport.totalExpenses || 0) > 0
                        ? [pnlReport.totalExpenses * 0.25, pnlReport.totalExpenses * 0.6, pnlReport.totalExpenses]
                        : [0, 0, 0, 0]
                  }
                />

                {/* Net Operating Income */}
                <KpiCard
                  title={isAr ? "صافي الدخل التشغيلي" : "Net Operating Income"}
                  value={formatCurrency(pnlReport.netOperatingIncome, currency)}
                  change={`${pnlReport.profitMarginPct >= 0 ? "+" : ""}${(pnlReport.profitMarginPct ?? 0).toFixed(1)}%`}
                  isPositive={pnlReport.netOperatingIncome >= 0}
                  icon={Wallet}
                  data={
                    pnlReport.netOperatingIncome !== 0
                      ? [0, pnlReport.totalRevenue || 0, pnlReport.netOperatingIncome]
                      : [0, 0, 0, 0]
                  }
                />

                {/* Profit Margin */}
                <KpiCard
                  title={isAr ? "هامش الربح الصافي" : "Net Profit Margin"}
                  value={`${(pnlReport.profitMarginPct ?? 0).toFixed(1)}%`}
                  change={pnlReport.profitMarginPct >= 0 ? (isAr ? "هامش إيجابي" : "Positive margin") : (isAr ? "عجز تشغيلي" : "Operating deficit")}
                  isPositive={(pnlReport.profitMarginPct ?? 0) >= 0}
                  icon={TrendingUp}
                  data={
                    (pnlReport.profitMarginPct ?? 0) !== 0
                      ? [0, (pnlReport.profitMarginPct ?? 0) * 0.5, pnlReport.profitMarginPct ?? 0]
                      : [0, 0, 0, 0]
                  }
                />
              </div>

              {/* Category Breakdowns: Revenue vs Expenses */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Revenue Breakdown */}
                <div className="afab-card p-6 space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="afab-card-title flex items-center gap-2.5">
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-gray-50 dark:bg-white/[0.03] text-gray-500 dark:text-gray-400">
                        <TrendingUp className="h-4 w-4 text-[#10b981]" />
                      </span>
                      <span>{isAr ? "تفصيل الإيرادات حسب التصنيف" : "Revenue by Category"}</span>
                    </h3>
                    <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
                      {formatCurrency(pnlReport.totalRevenue, currency)}
                    </span>
                  </div>

                  {pnlReport.revenueBreakdown && pnlReport.revenueBreakdown.length > 0 ? (
                    <div className="space-y-3">
                      {pnlReport.revenueBreakdown.map((cat, idx) => (
                        <div key={idx} className="space-y-1.5">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-semibold text-gray-700 dark:text-gray-300">{cat.categoryName}</span>
                            <span className="font-bold text-gray-900 dark:text-white">
                              {formatCurrency(cat.amount, currency)} ({cat.percentage.toFixed(1)}%)
                            </span>
                          </div>
                          <div className="w-full h-2 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
                            <div 
                              className="h-full bg-[#10b981] rounded-full transition-all duration-500"
                              style={{ width: `${Math.min(100, Math.max(2, cat.percentage))}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <EmptyState
                      icon={TrendingUp}
                      title={isAr ? "لا توجد معاملات إيرادات مسجلة لهذه الفترة." : "No income recorded for this period."}
                      className="py-8"
                    />
                  )}
                </div>

                {/* Expense Breakdown */}
                <div className="afab-card p-6 space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="afab-card-title flex items-center gap-2.5">
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-gray-50 dark:bg-white/[0.03] text-gray-500 dark:text-gray-400">
                        <CreditCard className="h-4 w-4 text-[#8b5cf6]" />
                      </span>
                      <span>{isAr ? "تفصيل المصروفات حسب التصنيف" : "Expenses by Category"}</span>
                    </h3>
                    <span className="text-xs font-bold text-[#8b5cf6]">
                      {formatCurrency(pnlReport.totalExpenses, currency)}
                    </span>
                  </div>

                  {pnlReport.expenseBreakdown && pnlReport.expenseBreakdown.length > 0 ? (
                    <div className="space-y-3">
                      {pnlReport.expenseBreakdown.map((cat, idx) => (
                        <div key={idx} className="space-y-1.5">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-semibold text-gray-700 dark:text-gray-300">{cat.categoryName}</span>
                            <span className="font-bold text-gray-900 dark:text-white">
                              {formatCurrency(cat.amount, currency)} ({cat.percentage.toFixed(1)}%)
                            </span>
                          </div>
                          <div className="w-full h-2 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
                            <div 
                              className="h-full bg-[#8b5cf6] rounded-full transition-all duration-500"
                              style={{ width: `${Math.min(100, Math.max(2, cat.percentage))}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <EmptyState
                      icon={TrendingDown}
                      title={isAr ? "لا توجد مصروفات مسجلة لهذه الفترة." : "No expenses recorded for this period."}
                      className="py-8"
                    />
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
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <KpiCard
                  title={isAr ? "التدفق النقدي الداخل (Inflow)" : "Total Cash Inflow"}
                  value={formatCurrency(cashFlowReport.cashInflow, currency)}
                  change={(cashFlowReport.cashInflow || 0) === 0 ? "0.0%" : (isAr ? "الداخل" : "Inflow")}
                  isPositive={true}
                  icon={TrendingUp}
                  data={
                    cashFlowReport.monthlyTrend && cashFlowReport.monthlyTrend.length > 0
                      ? cashFlowReport.monthlyTrend.map((m) => m.inflow)
                      : [0, 0, 0, 0]
                  }
                />

                <KpiCard
                  title={isAr ? "التدفق النقدي الخارج (Outflow)" : "Total Cash Outflow"}
                  value={formatCurrency(cashFlowReport.cashOutflow, currency)}
                  change={(cashFlowReport.cashOutflow || 0) === 0 ? "0.0%" : (isAr ? "الخارج" : "Outflow")}
                  isPositive={false}
                  icon={TrendingDown}
                  data={
                    cashFlowReport.monthlyTrend && cashFlowReport.monthlyTrend.length > 0
                      ? cashFlowReport.monthlyTrend.map((m) => m.outflow)
                      : [0, 0, 0, 0]
                  }
                />

                <KpiCard
                  title={isAr ? "صافي التغير النقدي" : "Net Cash Change"}
                  value={formatCurrency(cashFlowReport.netCashChange, currency)}
                  change={(cashFlowReport.netCashChange || 0) >= 0 ? (isAr ? "صافي إيجابي" : "Net positive") : (isAr ? "صافي سلبي" : "Net negative")}
                  isPositive={(cashFlowReport.netCashChange || 0) >= 0}
                  icon={Wallet}
                  data={
                    cashFlowReport.monthlyTrend && cashFlowReport.monthlyTrend.length > 0
                      ? cashFlowReport.monthlyTrend.map((m) => m.net)
                      : [0, 0, 0, 0]
                  }
                />
              </div>

              {/* Monthly Trend Chart */}
              <div className="afab-card p-6 space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <h3 className="afab-card-title">
                    {isAr ? "مسار التدفقات النقدية (آخر 6 أشهر)" : "6-Month Cash Flow Trend"}
                  </h3>
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2">
                      <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: chartSemantic.positive }} />
                      <span className="text-xs font-medium text-gray-600 dark:text-gray-300">{isAr ? "الداخل" : "Inflow"}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: chartSemantic.negative }} />
                      <span className="text-xs font-medium text-gray-600 dark:text-gray-300">{isAr ? "الخارج" : "Outflow"}</span>
                    </div>
                  </div>
                </div>

                <div className="h-72 w-full pt-4">
                  <ChartContainer className="h-full w-full">
                    <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0} initialDimension={{ width: 600, height: 272 }}>
                      <BarChart data={cashFlowReport.monthlyTrend || []}>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="currentColor" className="text-gray-200 dark:text-gray-800/50" />
                        <XAxis
                          dataKey="month"
                          axisLine={false}
                          tickLine={false}
                          tick={{ fontSize: 12 }}
                          stroke="currentColor"
                          className="text-gray-400 dark:text-gray-500"
                        />
                        <YAxis
                          axisLine={false}
                          tickLine={false}
                          tick={{ fontSize: 12 }}
                          stroke="currentColor"
                          className="text-gray-400 dark:text-gray-500"
                        />
                        <Tooltip {...chartTooltipStyle} />
                        <Bar dataKey="inflow" name={isAr ? "الداخل" : "Inflow"} fill={chartSemantic.positive} radius={[6, 6, 0, 0]} />
                        <Bar dataKey="outflow" name={isAr ? "الخارج" : "Outflow"} fill={chartSemantic.negative} radius={[6, 6, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  </ChartContainer>
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              TAB 3: PERIOD COMPARISON
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === "comparison" && comparisonReport && (
            <div className="space-y-6">
              <div className="afab-card p-6 space-y-6">
                <h3 className="afab-card-title">
                  {isAr ? "مقارنة النمو والأداء بين الفترات" : "Comparative Financial Variance"}
                </h3>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* Revenue Growth */}
                  <div className="afab-inset p-5 space-y-2">
                    <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">{isAr ? "نمو الإيرادات" : "Revenue Growth"}</span>
                    <div className="flex flex-wrap items-baseline gap-2">
                      <span className="text-xl sm:text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
                        {formatCurrency(comparisonReport.primaryRevenue, currency)}
                      </span>
                      <span className={`afab-badge ${
                        comparisonReport.revenueDifferencePct >= 0 
                          ? "afab-badge-success" 
                          : "afab-badge-danger"
                      }`}>
                        {comparisonReport.revenueDifferencePct >= 0 ? "+" : ""}
                        {comparisonReport.revenueDifferencePct?.toFixed(1)}%
                      </span>
                    </div>
                    <p className="text-xs text-gray-400 dark:text-gray-500">
                      {isAr ? "مقارنة بالفترة السابقة:" : "vs previous:"} {formatCurrency(comparisonReport.comparisonRevenue, currency)}
                    </p>
                  </div>

                  {/* Expenses Change */}
                  <div className="afab-inset p-5 space-y-2">
                    <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">{isAr ? "تغير المصروفات" : "Expense Change"}</span>
                    <div className="flex flex-wrap items-baseline gap-2">
                      <span className="text-xl sm:text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
                        {formatCurrency(comparisonReport.primaryExpenses, currency)}
                      </span>
                      <span className={`afab-badge ${
                        comparisonReport.expensesDifferencePct <= 0 
                          ? "afab-badge-success" 
                          : "afab-badge-danger"
                      }`}>
                        {comparisonReport.expensesDifferencePct >= 0 ? "+" : ""}
                        {comparisonReport.expensesDifferencePct?.toFixed(1)}%
                      </span>
                    </div>
                    <p className="text-xs text-gray-400 dark:text-gray-500">
                      {isAr ? "مقارنة بالفترة السابقة:" : "vs previous:"} {formatCurrency(comparisonReport.comparisonExpenses, currency)}
                    </p>
                  </div>

                  {/* Net Income Growth */}
                  <div className="afab-inset p-5 space-y-2">
                    <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">{isAr ? "تغير صافي الدخل" : "Net Income Change"}</span>
                    <div className="flex flex-wrap items-baseline gap-2">
                      <span className="text-xl sm:text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
                        {formatCurrency(comparisonReport.primaryNetIncome, currency)}
                      </span>
                      <span className={`afab-badge ${
                        comparisonReport.netIncomeDifferencePct >= 0 
                          ? "afab-badge-success" 
                          : "afab-badge-danger"
                      }`}>
                        {comparisonReport.netIncomeDifferencePct >= 0 ? "+" : ""}
                        {comparisonReport.netIncomeDifferencePct?.toFixed(1)}%
                      </span>
                    </div>
                    <p className="text-xs text-gray-400 dark:text-gray-500">
                      {isAr ? "مقارنة بالفترة السابقة:" : "vs previous:"} {formatCurrency(comparisonReport.comparisonNetIncome, currency)}
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
