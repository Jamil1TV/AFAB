"use client";

import { useEffect, useState } from "react";
import {
  Sparkles,
  ArrowRight,
  TrendingUp,
  AlertCircle,
  AlertTriangle,
  PieChart,
  Info,
} from "lucide-react";
import { useTranslations, useLocale } from "next-intl";
import { Link } from "@/i18n/routing";
import { DashboardSummaryResponse } from "@/lib/api/dashboard";
import { AiPulseAlert, AiPulseResponse, AiService } from "@/lib/api/ai";
import { useCopilot } from "@/components/ai/CopilotContextProvider";
import { formatCurrency } from "@/lib/currency";

function alertBadgeClass(severity: string): string {
  switch (severity) {
    case "HIGH":
      return "border-rose-500/30 bg-rose-500/10 text-rose-600 dark:text-rose-400";
    case "MEDIUM":
      return "border-amber-500/30 bg-amber-500/10 text-amber-600 dark:text-amber-400";
    default:
      return "border-[var(--primary)]/30 bg-[var(--primary)]/10 text-[var(--primary)]";
  }
}

function AlertIcon({ severity }: { severity: string }) {
  if (severity === "HIGH") return <AlertCircle className="h-3.5 w-3.5 text-rose-500 shrink-0" />;
  if (severity === "MEDIUM") return <AlertTriangle className="h-3.5 w-3.5 text-amber-500 shrink-0" />;
  return <Info className="h-3.5 w-3.5 text-[var(--primary)] shrink-0" />;
}

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
  const { openCopilot } = useCopilot();

  const [pulse, setPulse] = useState<AiPulseResponse | null>(null);

  useEffect(() => {
    let active = true;
    AiService.getPulse(false)
      .then((res) => {
        if (active) setPulse(res);
      })
      .catch(() => {});
    return () => {
      active = false;
    };
  }, []);

  const rawRev = summary?.kpiData?.revenue?.rawValue ?? 0;
  const rawExp = summary?.kpiData?.expenses?.rawValue ?? 0;
  const rawProfit = summary?.kpiData?.profit?.rawValue ?? rawRev - rawExp;
  const txCount = summary?.transactions?.length ?? 0;
  const topCat = summary?.expenseCategories?.[0];
  const hasRealActivity = rawRev > 0 || rawExp > 0 || txCount > 0;
  const profitMarginPct = rawRev > 0 ? Math.round((rawProfit / rawRev) * 1000) / 10 : 0;

  const liveAlerts: AiPulseAlert[] = pulse?.alerts?.slice(0, 2) || [];

  return (
    <div className="relative flex h-full flex-col justify-between overflow-hidden rounded-2xl border border-[var(--primary)]/30 bg-gradient-to-br from-[var(--primary)]/[0.08] via-[var(--card)] to-[var(--card)] p-6 shadow-sm">
      <div>
        <div className="relative z-10 mb-4 flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-[var(--primary)] text-white shadow-sm shadow-[var(--primary)]/30">
              <Sparkles className="h-4 w-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-gray-900 dark:text-white leading-tight">
                {tAi("title")}
              </h3>
              {pulse && (pulse.highCount > 0 || pulse.mediumCount > 0) && (
                <p className="text-[10.5px] font-semibold text-amber-600 dark:text-amber-400">
                  {pulse.highCount + pulse.mediumCount} {isAr ? "تنبيهات نشطة" : "live pulse alerts"}
                </p>
              )}
            </div>
          </div>
          <span className="afab-badge afab-badge-primary rounded-full px-2.5 py-0.5">
            {tAi("premium")}
          </span>
        </div>

        {liveAlerts.length > 0 ? (
          <div className="relative z-10 space-y-2.5">
            {liveAlerts.map((al) => (
              <div
                key={al.id}
                className="rounded-xl border border-gray-200/80 dark:border-gray-800/80 bg-[var(--surface-inset)] p-3 space-y-1.5"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-1.5 min-w-0">
                    <AlertIcon severity={al.severity} />
                    <h4 className="text-xs font-bold text-gray-900 dark:text-white truncate">
                      {al.title}
                    </h4>
                  </div>
                  <span
                    className={`rounded-full border px-1.5 py-0.5 text-[9px] font-bold uppercase shrink-0 ${alertBadgeClass(
                      al.severity
                    )}`}
                  >
                    {al.severity}
                  </span>
                </div>
                <p className="text-[11.5px] leading-relaxed text-gray-600 dark:text-gray-400">
                  {al.description}
                </p>
                <div className="pt-0.5 flex items-center justify-end">
                  <button
                    type="button"
                    onClick={() =>
                      openCopilot({
                        prompt: al.copilotPrompt,
                        autoSend: true,
                        screenContext: { source: "AIInsightsCard", alertType: al.type },
                      })
                    }
                    className="inline-flex items-center gap-1 text-[11px] font-semibold text-[var(--primary)] hover:underline"
                  >
                    <Sparkles className="h-3 w-3" />
                    <span>{isAr ? "تحليل مع المساعد" : "Investigate in Copilot"}</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : !hasRealActivity ? (
          <div className="relative z-10 my-2 rounded-xl border border-gray-200/80 bg-[var(--surface-inset)] p-4 text-center">
            <div className="mx-auto mb-2.5 flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--primary)]/10 text-[var(--primary)]">
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
            <div className="rounded-xl border border-gray-200/80 bg-[var(--surface-inset)] p-3">
              <h4 className="flex items-center gap-1.5 text-xs font-semibold text-gray-900 dark:text-gray-200">
                <TrendingUp className="h-3.5 w-3.5 text-[var(--primary)]" />
                <span>{isAr ? "هامش صافي التدفق النقدي" : "Net Cash Flow & Margin"}</span>
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

            <div className="rounded-xl border border-gray-200/80 bg-[var(--surface-inset)] p-3">
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
