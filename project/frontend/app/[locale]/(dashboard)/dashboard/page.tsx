"use client";

import { KpiCard } from "@/components/dashboard/KpiCard";
import { RevenueChart } from "@/components/dashboard/RevenueChart";
import { AIInsightsCard } from "@/components/dashboard/AIInsightsCard";
import { RecentTransactions } from "@/components/dashboard/RecentTransactions";
import { ExpenseCategories } from "@/components/dashboard/ExpenseCategories";
import { ReminderCard } from "@/components/dashboard/ReminderCard";
import { TopCustomers } from "@/components/dashboard/TopCustomers";
import { UpgradeBanner } from "@/components/dashboard/UpgradeBanner";
import { PeriodSelector } from "@/components/dashboard/PeriodSelector";
import { useState, useEffect, useCallback } from "react";
import { DashboardService, UserService, DashboardSummaryResponse } from "@/lib/api/dashboard";
import { AuthStore } from "@/lib/auth-store";
import { DollarSign, CreditCard, TrendingUp, Wallet, BarChart3 } from "lucide-react";
import { useTranslations } from "next-intl";
import { AfabLoader } from "@/components/ui/afab-loader";
import { formatCurrency } from "@/lib/currency";

export default function DashboardPage() {
  const tWelcome = useTranslations("Dashboard.welcome");
  const tKpi = useTranslations("Dashboard.kpi");
  
  const [data, setData] = useState<DashboardSummaryResponse | null>(null);
  const [userProfile, setUserProfile] = useState<{ firstName?: string; currency?: string } | null>(null);
  const [period, setPeriod] = useState<"WEEKLY" | "MONTHLY" | "YEARLY">("MONTHLY");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSummary = useCallback(async () => {
    setLoading(true);
    try {
      const periodParam = period === "MONTHLY" ? "month" : period === "WEEKLY" ? "weekly" : "year";
      const res = await DashboardService.getSummary(periodParam);
      setData(res);
      setError(null);
    } catch (err: unknown) {
      console.error("Dashboard fetch error:", err);
      const message = err instanceof Error ? err.message : "Failed to load dashboard data";
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [period]);

  useEffect(() => {
    fetchSummary();
  }, [fetchSummary]);

  useEffect(() => {
    UserService.getProfile()
      .then(setUserProfile)
      .catch(() => {
        const stored = AuthStore.getUser();
        if (stored) setUserProfile(stored);
      });
  }, []);

  if (loading && !data) {
    return (
      <div className="flex h-[50vh] items-center justify-center">
        <AfabLoader size="lg" text="Loading real-time financial stats..." />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div className="flex flex-col items-center justify-center text-center space-y-4">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-red-50 dark:bg-red-500/10">
            <BarChart3 className="h-8 w-8 text-red-500 dark:text-red-400" />
          </div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">Unable to load dashboard</h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 max-w-md">
            {error || "Something went wrong. Please try again later."}
          </p>
          <button
            onClick={() => fetchSummary()}
            className="mt-4 px-4 py-2 text-sm font-medium rounded-lg bg-[#8b5cf6] text-white hover:bg-[#7c3aed] transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  const currency = data.currency || userProfile?.currency || "USD";

  // Safe access to KPI data
  const kpi = data.kpiData || {};
  const revenue = kpi.revenue || { value: formatCurrency(0, currency), change: "0.0%", isPositive: true };
  const expenses = kpi.expenses || { value: formatCurrency(0, currency), change: "0.0%", isPositive: true };
  const profit = kpi.profit || { value: formatCurrency(0, currency), change: "0.0%", isPositive: true };
  const cashFlow = kpi.cashFlow || { value: formatCurrency(0, currency), change: "0.0%", isPositive: true };

  // Trailing monthly arrays for sparklines in KPI cards
  const revSparkline = data.revenueData?.map((d) => d.revenue) || [0, 0, 0, 0, 0, 0];
  const expSparkline = data.revenueData?.map((d) => d.expenses) || [0, 0, 0, 0, 0, 0];
  const profitSparkline = data.revenueData?.map((d) => d.revenue - d.expenses) || [0, 0, 0, 0, 0, 0];
  const cashFlowSparkline = profitSparkline;

  const firstName = userProfile?.firstName || AuthStore.getUser()?.firstName || "";

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-700">
      
      {/* ── Welcome Header & Period Selector ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white sm:text-3xl tracking-tight">
            {firstName ? tWelcome("title", { name: firstName }) : tWelcome("goodMorningGeneric")}
          </h1>
          <p className="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
            {tWelcome("subtitle")}
          </p>
        </div>

        <div className="flex items-center gap-3">
          <PeriodSelector value={period} onChange={setPeriod} />
        </div>
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard 
          title={tKpi("totalRevenue")} 
          value={revenue.rawValue != null ? formatCurrency(revenue.rawValue, currency) : revenue.value} 
          change={revenue.change} 
          isPositive={revenue.isPositive} 
          icon={DollarSign}
          data={revSparkline}
        />
        <KpiCard 
          title={tKpi("totalExpenses")} 
          value={expenses.rawValue != null ? formatCurrency(expenses.rawValue, currency) : expenses.value} 
          change={expenses.change} 
          isPositive={expenses.isPositive} 
          icon={CreditCard}
          data={expSparkline}
        />
        <KpiCard 
          title={tKpi("netProfit")} 
          value={profit.rawValue != null ? formatCurrency(profit.rawValue, currency) : profit.value} 
          change={profit.change} 
          isPositive={profit.isPositive} 
          icon={TrendingUp}
          data={profitSparkline}
        />
        <KpiCard 
          title={tKpi("cashFlow")} 
          value={cashFlow.rawValue != null ? formatCurrency(cashFlow.rawValue, currency) : cashFlow.value} 
          change={cashFlow.change} 
          isPositive={cashFlow.isPositive} 
          icon={Wallet}
          data={cashFlowSparkline}
        />
      </div>

      {/* ── Main Analytics Row ── */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {/* Chart takes up 2 columns on large screens */}
        <div className="lg:col-span-2">
          <RevenueChart data={data.revenueData || []} currency={currency} />
        </div>
        {/* AI Insights takes 1 column */}
        <div className="lg:col-span-1">
          <AIInsightsCard />
        </div>
      </div>

      {/* ── Secondary Data Row ── */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {/* Transactions take up 2 columns on large screens */}
        <div className="lg:col-span-2">
          <RecentTransactions transactions={data.transactions || []} currency={currency} />
        </div>
        {/* Expense Categories takes 1 column */}
        <div className="lg:col-span-1">
          <ExpenseCategories categories={data.expenseCategories || []} currency={currency} />
        </div>
      </div>

      {/* ── Tertiary Data Row ── */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ReminderCard reminders={data.reminders || []} />
        <TopCustomers customers={data.customers || []} currency={currency} />
      </div>

      {/* ── Upgrade Banner ── */}
      <div className="pt-4">
        <UpgradeBanner />
      </div>

    </div>
  );
}
