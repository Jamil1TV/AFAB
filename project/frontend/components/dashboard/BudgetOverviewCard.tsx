"use client";

import { PiggyBank, AlertTriangle, XCircle, ArrowRight } from "lucide-react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import type { BudgetSummary } from "@/lib/api/budgets";
import { formatCurrency } from "@/lib/currency";

interface BudgetOverviewCardProps {
  budgets?: BudgetSummary | null;
  currency: string;
}

export function BudgetOverviewCard({ budgets, currency }: BudgetOverviewCardProps) {
  const t = useTranslations("Dashboard.budgets");
  const items = budgets?.budgets || [];

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 sm:p-6 shadow-sm">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="h-9 w-9 shrink-0 rounded-xl bg-[var(--primary)]/10 text-[var(--primary)] flex items-center justify-center">
            <PiggyBank className="h-4.5 w-4.5" />
          </div>
          <div className="min-w-0">
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">{t("title")}</h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {items.length > 0
                ? t("subtitleActive", {
                    active: budgets?.activeBudgetCount ?? items.length,
                    over: budgets?.overBudgetCount ?? 0,
                    approaching: budgets?.approachingCount ?? 0,
                  })
                : t("subtitleEmpty")}
            </p>
          </div>
        </div>
        <Link
          href="/dashboard/budgets"
          className="inline-flex items-center gap-1 text-xs font-semibold text-[var(--primary)] hover:underline shrink-0 self-start sm:self-auto"
        >
          <span>{t("manageLink")}</span>
          <ArrowRight className="h-3.5 w-3.5 rtl:rotate-180" />
        </Link>
      </div>

      {items.length === 0 ? (
        <div className="rounded-xl border border-dashed border-gray-200 dark:border-gray-800 bg-gray-50/60 dark:bg-white/[0.02] p-4 text-center text-xs text-gray-500 dark:text-gray-400">
          {t("emptyNotice")}{" "}
          <Link href="/dashboard/budgets" className="text-[var(--primary)] font-semibold hover:underline">
            {t("createNow")}
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {items.slice(0, 6).map((b) => {
            const pct = Math.min(100, Math.max(0, b.percentageConsumed));
            const barColor =
              b.alertLevel === "OVER_BUDGET"
                ? "bg-rose-500"
                : b.alertLevel === "APPROACHING"
                ? "bg-amber-500"
                : "bg-emerald-500";

            return (
              <div
                key={b.id}
                className="rounded-xl border border-gray-200/80 dark:border-gray-800/80 bg-gray-50/70 dark:bg-white/[0.02] p-3.5 space-y-2 min-w-0"
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="text-xs font-bold text-gray-900 dark:text-white truncate">{b.name}</span>
                  {b.alertLevel === "OVER_BUDGET" ? (
                    <XCircle className="h-3.5 w-3.5 text-rose-500 shrink-0" />
                  ) : b.alertLevel === "APPROACHING" ? (
                    <AlertTriangle className="h-3.5 w-3.5 text-amber-500 shrink-0" />
                  ) : null}
                </div>
                <div className="flex items-baseline justify-between gap-2 text-[11px]">
                  <span className="text-gray-600 dark:text-gray-300 font-medium truncate">
                    {formatCurrency(b.actualSpending, b.currency || currency)} /{" "}
                    {formatCurrency(b.budgetAmount, b.currency || currency)}
                  </span>
                  <span
                    className={`font-bold shrink-0 ${
                      b.alertLevel === "OVER_BUDGET"
                        ? "text-rose-600 dark:text-rose-400"
                        : b.alertLevel === "APPROACHING"
                        ? "text-amber-600 dark:text-amber-400"
                        : "text-emerald-600 dark:text-emerald-400"
                    }`}
                  >
                    {b.percentageConsumed.toFixed(0)}%
                  </span>
                </div>
                <div className="h-1.5 w-full rounded-full bg-gray-200 dark:bg-gray-800 overflow-hidden">
                  <div className={`h-full rounded-full ${barColor}`} style={{ width: `${pct}%` }} />
                </div>
                <div className="text-[11px] text-gray-500 dark:text-gray-400">
                  {b.overBudgetAmount > 0 ? (
                    <span className="text-rose-600 dark:text-rose-400 font-medium">
                      {t("overBy")} {formatCurrency(b.overBudgetAmount, b.currency || currency)}
                    </span>
                  ) : (
                    <span>
                      {t("remaining")}: {formatCurrency(b.remainingAmount, b.currency || currency)}
                    </span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
