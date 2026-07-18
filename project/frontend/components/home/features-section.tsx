import { useTranslations } from "next-intl";
import {
  Sparkles,
  PiggyBank,
  Receipt,
  FileText,
  TrendingUp,
  BarChart3,
} from "lucide-react";

const featureIcons = [Sparkles, PiggyBank, Receipt, FileText, TrendingUp, BarChart3];

const featureKeys = [
  { title: "aiInsights", desc: "aiInsightsDesc" },
  { title: "smartBudget", desc: "smartBudgetDesc" },
  { title: "expenseTracking", desc: "expenseTrackingDesc" },
  { title: "invoiceGenerator", desc: "invoiceGeneratorDesc" },
  { title: "profitPrediction", desc: "profitPredictionDesc" },
  { title: "cashFlow", desc: "cashFlowDesc" },
];

const iconColors = [
  "text-[#8b5cf6] bg-[#8b5cf6]/10", // Purple
  "text-[#60a5fa] bg-[#60a5fa]/10", // Blue
  "text-[#fb923c] bg-[#fb923c]/10", // Orange
  "text-[#60a5fa] bg-[#60a5fa]/10", // Blue
  "text-[#34d399] bg-[#34d399]/10", // Green
  "text-[#8b5cf6] bg-[#8b5cf6]/10", // Purple
];

export function FeaturesSection() {
  const t = useTranslations("Home.features");

  return (
    <section id="features" className="py-12 lg:py-16">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between mb-12">
          <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            {t("title")}{" "}
            <span className="text-[#8b5cf6]">{t("titleHighlight")}</span>
          </h2>
          <button className="rounded-full border border-border px-5 py-2.5 text-sm font-medium transition-colors hover:bg-muted">
            {t("viewAll")}
          </button>
        </div>

        {/* Features Grid */}
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {featureKeys.map((feature, i) => {
            const Icon = featureIcons[i];
            return (
              <div
                key={feature.title}
                className="group rounded-[20px] border border-gray-200/80 dark:border-gray-700/50 bg-white dark:bg-[#0d1225] p-8 transition-all hover:shadow-xl dark:hover:shadow-[0_0_40px_rgba(139,92,246,0.06)] hover:-translate-y-1"
              >
                <div
                  className={`mb-6 inline-flex h-12 w-12 items-center justify-center rounded-xl ${iconColors[i]}`}
                >
                  <Icon className="h-6 w-6" />
                </div>
                <h3 className="mb-2 text-base font-bold text-gray-900 dark:text-white">
                  {t(feature.title)}
                </h3>
                <p className="text-[14px] leading-relaxed text-gray-500 dark:text-gray-400">
                  {t(feature.desc)}
                </p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
