"use client";

import { useLocale } from "next-intl";
import { Sparkles, Bot, TrendingUp, FileSearch, Clock } from "lucide-react";
import { PageHeader } from "@/components/dashboard/PageHeader";

export default function AIAssistantComingSoonPage() {
  const locale = useLocale();
  const isAr = locale === "ar";

  const upcomingCapabilities = [
    {
      icon: Bot,
      title: isAr ? "محادثة مالية ذكية" : "Interactive AI Financial Chat",
      description: isAr
        ? "اسأل مساعد AFAB الذكي مباشرة عن تدفقاتك النقدية، ومصروفاتك، وأرباحك بلغة طبيعية."
        : "Ask questions about your cash flow, expenses, and profitability in natural language.",
    },
    {
      icon: TrendingUp,
      title: isAr ? "توقعات وتوصيات فورية" : "Smart Forecasting & Insights",
      description: isAr
        ? "احصل على تنبؤات مالية ذكية وتنبيهات مبكرة لتحسين الأداء المالي لشركاتك."
        : "Get proactive financial recommendations and anomaly alerts tailored to your business.",
    },
    {
      icon: FileSearch,
      title: isAr ? "تحليل الفواتير والتقارير" : "Automated Report & Invoice Analysis",
      description: isAr
        ? "لخّص التقارير المالية المعقدة واستخرج أهم المؤشرات بضغطة زر."
        : "Summarize complex financial statements and extract key metrics in seconds.",
    },
  ];

  return (
    <div className="afab-page animate-in fade-in duration-500">
      <PageHeader
        title={
          <span className="inline-flex items-center gap-2">
            <span>{isAr ? "مساعد الذكاء الاصطناعي" : "AI Assistant"}</span>
            <span className="afab-badge afab-badge-primary px-2.5 py-0.5 rounded-full text-xs">
              {isAr ? "قريباً" : "Coming Soon"}
            </span>
          </span>
        }
        subtitle={
          isAr
            ? "نعمل حالياً على بناء تجربة محادثة مالية متكاملة بالذكاء الاصطناعي لمساعدتك في إدارة أعمالك."
            : "We are building your dedicated AI Financial Chat workspace to help you analyze and grow your business."
        }
      />

      <div className="afab-card p-8 sm:p-12 text-center max-w-3xl mx-auto space-y-6 relative overflow-hidden">
        <div className="absolute -top-12 -end-12 h-40 w-40 rounded-full bg-[#8b5cf6]/10 blur-3xl pointer-events-none" />
        <div className="absolute -bottom-12 -start-12 h-40 w-40 rounded-full bg-indigo-500/10 blur-3xl pointer-events-none" />

        <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-[#8b5cf6]/10 border border-[#8b5cf6]/25 text-[#7c3aed] dark:text-[#a78bfa] shadow-sm">
          <Sparkles className="w-8 h-8" />
        </div>

        <div className="space-y-2 max-w-xl mx-auto">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-purple-500/10 text-[#7c3aed] dark:text-[#a78bfa] border border-purple-500/20">
            <Clock className="w-3.5 h-3.5" />
            <span>{isAr ? "قيد التطوير — يتوفر قريباً" : "In Development — Coming Soon"}</span>
          </div>

          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white pt-1">
            {isAr
              ? "مساعد AFAB الذكي للمحادثة المالية"
              : "AFAB AI Financial Chat Assistant"}
          </h2>

          <p className="text-xs sm:text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
            {isAr
              ? "ستكون هذه الصفحة مخصصة بالكامل للمحادثة الذكية مع بياناتك المالية، وتحليل الإيرادات والمصروفات، وتقديم النصائح المالية الفورية."
              : "This workspace will be dedicated exclusively to chatting with your AI Finance Assistant, analyzing live business metrics, and generating instant financial insights."}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-4 text-start">
          {upcomingCapabilities.map((item, idx) => (
            <div
              key={idx}
              className="p-4 rounded-2xl bg-gray-50/80 dark:bg-[#080c18] border border-gray-200/80 dark:border-gray-800/80 space-y-2"
            >
              <div className="h-9 w-9 rounded-xl bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa] flex items-center justify-center">
                <item.icon className="w-4 h-4" />
              </div>
              <h4 className="text-xs font-bold text-gray-900 dark:text-white">
                {item.title}
              </h4>
              <p className="text-[11px] text-gray-500 dark:text-gray-400 leading-snug">
                {item.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
