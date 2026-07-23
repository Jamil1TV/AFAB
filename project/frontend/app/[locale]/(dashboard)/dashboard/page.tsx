"use client";

import { KpiCard } from "@/components/dashboard/KpiCard";
import { RevenueChart } from "@/components/dashboard/RevenueChart";
import { AIInsightsCard } from "@/components/dashboard/AIInsightsCard";
import { RecentTransactions } from "@/components/dashboard/RecentTransactions";
import { ExpenseCategories } from "@/components/dashboard/ExpenseCategories";
import { ReminderCard } from "@/components/dashboard/ReminderCard";
import { TopCustomers } from "@/components/dashboard/TopCustomers";
import { UpgradeBanner } from "@/components/dashboard/UpgradeBanner";
import { useState, useEffect } from "react";
import { DashboardService } from "@/lib/api/dashboard";
import { DollarSign, CreditCard, TrendingUp, Wallet } from "lucide-react";
import { useTranslations } from "next-intl";
import { AfabLoader } from "@/components/ui/afab-loader";

export default function DashboardPage() {
  const tWelcome = useTranslations("Dashboard.welcome");
  const tKpi = useTranslations("Dashboard.kpi");
  
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    DashboardService.getSummary()
      .then(setData)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading || !data) {
    return (
      <div className="flex h-[50vh] items-center justify-center">
        <AfabLoader size="lg" text="Loading dashboard data..." />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-700">
      
      {/* ── Welcome Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white sm:text-3xl tracking-tight">
            {tWelcome("title")}
          </h1>
          <p className="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
            {tWelcome("subtitle")}
          </p>
        </div>
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard 
          title={tKpi("totalRevenue")} 
          value={data.kpiData?.revenue?.value} 
          change={data.kpiData?.revenue?.change} 
          isPositive={data.kpiData?.revenue?.isPositive} 
          icon={DollarSign}
          data={[10, 20, 15, 30, 25, 45, 40]}
        />
        <KpiCard 
          title={tKpi("totalExpenses")} 
          value={data.kpiData?.expenses?.value} 
          change={data.kpiData?.expenses?.change} 
          isPositive={data.kpiData?.expenses?.isPositive} 
          icon={CreditCard}
          data={[40, 35, 45, 30, 35, 20, 25]}
        />
        <KpiCard 
          title={tKpi("netProfit")} 
          value={data.kpiData?.profit?.value} 
          change={data.kpiData?.profit?.change} 
          isPositive={data.kpiData?.profit?.isPositive} 
          icon={TrendingUp}
          data={[5, 10, 8, 20, 15, 30, 35]}
        />
        <KpiCard 
          title={tKpi("cashFlow")} 
          value={data.kpiData?.cashFlow?.value} 
          change={data.kpiData?.cashFlow?.change} 
          isPositive={data.kpiData?.cashFlow?.isPositive} 
          icon={Wallet}
          data={[20, 15, 25, 20, 30, 25, 35]}
        />
      </div>

      {/* ── Main Analytics Row ── */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {/* Chart takes up 2 columns on large screens */}
        <div className="lg:col-span-2">
          <RevenueChart data={data.revenueData} />
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
          <RecentTransactions transactions={data.transactions} />
        </div>
        {/* Expense Categories takes 1 column */}
        <div className="lg:col-span-1">
          <ExpenseCategories categories={data.expenseCategories} />
        </div>
      </div>

      {/* ── Tertiary Data Row ── */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ReminderCard reminders={data.reminders} />
        <TopCustomers customers={data.customers} />
      </div>

      {/* ── Upgrade Banner ── */}
      <div className="pt-4">
        <UpgradeBanner />
      </div>

    </div>
  );
}
