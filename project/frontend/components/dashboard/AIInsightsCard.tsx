"use client";

import { Sparkles, ArrowRight, TrendingUp, AlertCircle, PieChart } from "lucide-react";
import { useTranslations, useLocale } from "next-intl";
import { Link } from "@/i18n/routing";
import { DashboardSummaryResponse } from "@/lib/api/dashboard";
import { formatCurrency } from "@/lib/currency";

export function AIInsightsCard({
  summary,
  currency = "USD",
}: {
  summary?: DashboardSummaryResponse | null;
  currency?: string;
}) {
  const tAi = useTranslations("Dashboard.ai");
  const locale = useLocale();
  const isAr = locale === "ar";

  const rawRev = summary?.kpiData?.revenue?.rawValue ?? 0;
  const rawExp = summary?.kpiData?.expenses?.rawValue ?? 0;
  const rawProfit = summary?.kpiData?.profit?.rawValue ?? rawRev - rawExp;
  const txCount = summary?.transactions?.length ?? 0;
  const topCat = summary?.expenseCategories?.[0];
  const hasRealActivity = rawRev > 0 || rawExp > 0 || txCount > 0;

  const profitMarginPct = rawRev > 0 ? Math.round((rawProfit / rawRev) * 1000) / 10 : 0;

  return (
    <div className="relative flex h-full flex-col justify-between overflow-hidden rounded-2xl border border-[var(--primary)]/30 bg-gradient-to-br from-[#f5f3ff] to-white p-6 shadow-sm dark:from-[#131128] dark:to-[#0c101c]">
      <div>
        <div className="relative z-10 mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-[var(--primary)] text-white shadow-sm shadow-[var(--primary)]/30">
              <Sparkles className="h-4 w-4" />
            </div>
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tAi("title")}</h3>
          </div>
          <span className="afab-badge afab-badge-primary rounded-full px-2.5 py-0.5">
            {tAi("premium")}
          </span>
        </div>

        {!hasRealActivity ? (
          <div className="relative z-10 my-2 rounded-xl border border-gray-200/80 bg-white/80 p-4 text-center backdrop-blur-sm dark:border-gray-800/80 dark:bg-[#080c18]/80">
            <div className="mx-auto mb-2.5 flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--primary)]/10 text-[var(--primary-hover)] dark:text-[var(--primary)]">
              <AlertCircle className="h-5 w-5" />
            </div>
            <h4 className="text-xs font-bold text-gray-900 dark:text-white">
              {isAr ? "في انتظار النشاط المالي" : "Awaiting Financial Activity"}
            </h4>
            <p className="mt-1 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
              {isAr
                ? "يلزم تسجيل المزيد من المعاملات المالية الفعلية قبل إنشاء رؤى وتوصيات ذكية دقيقة."
                : "More financial activity is required before generating meaningful AI insights from your ledger."}
            </p>
          </div>
        ) : (
          <div className="relative z-10 space-y-3">
            <div className="rounded-xl border border-gray-200/80 bg-white/80 p-3 backdrop-blur-sm dark:border-gray-800/80 dark:bg-[#080c18]/80">
              <h4 className="flex items-center gap-1.5 text-xs font-semibold text-gray-900 dark:text-gray-200">
                <TrendingUp className="h-3.5 w-3.5 text-[var(--primary)]" />
                <span>
                  {isAr ? "هامش صافي التدفق النقدي" : "Net Cash Flow & Margin"}
                </span>
              </h4>
              <p className="mt-1 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                {rawRev > 0
                  ? isAr
                    ? `صافي الربح الحالي هو ${formatCurrency(rawProfit, currency)} بهامش تشغيلي قدره ${profitMarginPct}% من إجمالي الإيرادات (${formatCurrency(rawRev, currency)}).`
                    : `Net operating profit stands at ${formatCurrency(rawProfit, currency)} (${profitMarginPct}% margin on ${formatCurrency(rawRev, currency)} revenue).`
                  : isAr
                  ? `تم تسجيل مصروفات بقيمة ${formatCurrency(rawExp, currency)} دون إيرادات مكتملة في هذه الفترة.`
                  : `Recorded ${formatCurrency(rawExp, currency)} in expenses with no completed revenue in this period.`}
              </p>
            </div>

            <div className="rounded-xl border border-gray-200/80 bg-white/80 p-3 backdrop-blur-sm dark:border-gray-800/80 dark:bg-[#080c18]/80">
              <h4 className="flex items-center gap-1.5 text-xs font-semibold text-gray-900 dark:text-gray-200">
                <PieChart className="h-3.5 w-3.5 text-[var(--primary)]" />
                <span>
                  {topCat
                    ? isAr
                      ? `أعلى فئة إنفاق: ${topCat.name}`
                      : `Top Spend Driver: ${topCat.name}`
                    : isAr
                    ? "توزيع المصروفات"
                    : "Expense Distribution"}
                </span>
              </h4>
              <p className="mt-1 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                {topCat
                  ? isAr
                    ? `تمثل فئة "${topCat.name}" ما نسبته ${topCat.percentage}% (${formatCurrency(topCat.value, currency)}) من إجمالي المصروفات المسجلة.`
                    : `${topCat.name} accounts for ${topCat.percentage}% (${formatCurrency(topCat.value, currency)}) of your recorded expenses.`
                  : isAr
                  ? "لا توجد مصروفات مصنفة في هذه الفترة الزمنية."
                  : "No categorized expenses recorded for the selected period."}
              </p>
            </div>
          </div>
        )}
      </div>

      <Link
        href="/dashboard/ai"
        className="afab-btn-primary relative z-10 mt-5 w-full py-2.5 text-xs"
      >
        <span>{tAi("askBtn")}</span>
        <ArrowRight className="h-4 w-4 rtl:rotate-180" />
      </Link>
    </div>
  );
}
