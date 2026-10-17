"use client";

import { useState } from "react";
import { 
  Check, 
  X, 
  Sparkles, 
  Gift, 
  Zap, 
  Crown, 
  Clock, 
  BarChart3, 
  TrendingUp, 
  ShieldCheck, 
  ArrowRight, 
  Info,
  CreditCard,
  Building2,
  CheckCircle2,
  Lock,
  Globe2,
  ChevronRight
} from "lucide-react";
import { useLocale } from "next-intl";
import { motion, AnimatePresence } from "framer-motion";
import { Link } from "@/i18n/routing";

interface PlanFeature {
  name: string;
  included: boolean;
  tooltip?: string;
}

interface PlanData {
  id: "free" | "plus" | "pro";
  name: string;
  badge?: string;
  subtitle: string;
  priceMonthly: number;
  priceYearly: number;
  description: string;
  featuresHeader: string;
  features: PlanFeature[];
}

export function PlansScreen() {
  const locale = useLocale();
  const isAr = locale === "ar";

  const [billingPeriod, setBillingPeriod] = useState<"monthly" | "yearly">("monthly");
  const [activePlan, setActivePlan] = useState<"free" | "plus" | "pro">("free");
  const [selectedPlanForTrial, setSelectedPlanForTrial] = useState<"plus" | "pro" | null>(null);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [checkoutStep, setCheckoutStep] = useState<"form" | "success">("form");
  const [activeTooltip, setActiveTooltip] = useState<string | null>(null);

  const plans: PlanData[] = [
    {
      id: "free",
      name: isAr ? "مجاني" : "Free",
      subtitle: isAr ? "للبدء واستكشاف المنصة" : "For getting started",
      priceMonthly: 0,
      priceYearly: 0,
      description: isAr 
        ? "استكشف AFAB وقم بإدارة عملك الأول باستخدام الأدوات المالية والذكية الأساسية."
        : "Explore AFAB and manage your first business with essential tools.",
      featuresHeader: isAr ? "تشمل الخطة:" : "INCLUDES:",
      features: [
        { 
          name: isAr ? "محادثة ورؤى الذكاء الاصطناعي (10 استفسارات/شهر)" : "AI Chat & Insights (10 queries/month)", 
          included: true 
        },
        { 
          name: isAr ? "تقارير مالية أساسية" : "Basic Financial Reports", 
          included: true 
        },
        { 
          name: isAr ? "تتبع الإيرادات والمصروفات" : "Income & Expense Tracking", 
          included: true 
        },
        { 
          name: isAr ? "حتى 5 فواتير / شهر" : "Up to 5 Invoices / month", 
          included: true 
        },
        { 
          name: isAr ? "مستخدم واحد (1)" : "1 User", 
          included: true 
        },
        { 
          name: isAr ? "دعم شركة واحدة" : "1 Business Support", 
          included: true, 
          tooltip: isAr 
            ? "إدارة وتحليل البيانات لشركة مسجلة رئيسية واحدة."
            : "Manage and analyze data for one primary registered business." 
        },
        { 
          name: isAr ? "تصدير البيانات (5 عمليات تصدير/شهر)" : "Export Data (5 exports/month)", 
          included: true 
        },
        { 
          name: isAr ? "توصيات الذكاء الاصطناعي" : "AI Recommendations", 
          included: false 
        },
        { 
          name: isAr ? "التنبؤ بالتدفقات النقدية" : "Cash Flow Forecasting", 
          included: false 
        },
        { 
          name: isAr ? "تقارير متقدمة" : "Advanced Reports", 
          included: false 
        },
        { 
          name: isAr ? "دعم ذو أولوية" : "Priority Support", 
          included: false 
        },
      ]
    },
    {
      id: "plus",
      name: "Plus",
      badge: isAr ? "الأكثر شيوعاً" : "Most Popular",
      subtitle: isAr ? "للأعمال والشركات النامية" : "For growing businesses",
      priceMonthly: 9.99,
      priceYearly: 7.99,
      description: isAr 
        ? "المزيد من قوة الذكاء الاصطناعي والمرونة لإدارة وتتبع شركات متعددة بكفاءة."
        : "More AI power and flexibility to manage multiple businesses.",
      featuresHeader: isAr ? "كل ما في الخطة المجانية، بالإضافة إلى:" : "EVERYTHING IN FREE, PLUS:",
      features: [
        { 
          name: isAr ? "محادثة ورؤى الذكاء الاصطناعي (100 استفسار/شهر)" : "AI Chat & Insights (100 queries/month)", 
          included: true 
        },
        { 
          name: isAr ? "توصيات الذكاء الاصطناعي الذكية" : "AI Recommendations", 
          included: true 
        },
        { 
          name: isAr ? "التنبؤ المستقبلي بالتدفقات النقدية" : "Cash Flow Forecasting", 
          included: true 
        },
        { 
          name: isAr ? "تقارير مالية وتحليلية متقدمة" : "Advanced Reports", 
          included: true 
        },
        { 
          name: isAr ? "حتى 50 فاتورة / شهر" : "Up to 50 Invoices / month", 
          included: true 
        },
        { 
          name: isAr ? "حتى 3 مستخدمين" : "Up to 3 Users", 
          included: true 
        },
        { 
          name: isAr ? "دعم حتى 3 شركات" : "Up to 3 Business Support", 
          included: true, 
          tooltip: isAr 
            ? "إضافة والتنقل بسلاسة بين حتى 3 كيانات تجارية مستقلة."
            : "Seamlessly add and toggle between up to 3 separate business entities." 
        },
        { 
          name: isAr ? "تصدير البيانات (15 عملية تصدير/شهر)" : "Export Data (15 exports/month)", 
          included: true 
        },
        { 
          name: isAr ? "دعم فني عبر البريد الإلكتروني" : "Email Support", 
          included: true 
        },
        { 
          name: isAr ? "دعم ذو أولوية" : "Priority Support", 
          included: false 
        },
      ]
    },
    {
      id: "pro",
      name: "Pro",
      subtitle: isAr ? "للأعمال المتوسعة والشركات الكبرى" : "For scaling businesses",
      priceMonthly: 19.99,
      priceYearly: 15.99,
      description: isAr 
        ? "قوة غير محدودة ومرونة تامة للشركات ذات العمليات الكبيرة وتعدد الأنشطة."
        : "Unlimited power and full flexibility for businesses with greater needs.",
      featuresHeader: isAr ? "كل ما في Plus، بالإضافة إلى:" : "EVERYTHING IN PLUS, PLUS:",
      features: [
        { 
          name: isAr ? "محادثة ورؤى الذكاء الاصطناعي (300 استفسار/شهر)" : "AI Chat & Insights (300 queries/month)", 
          included: true 
        },
        { 
          name: isAr ? "توصيات متقدمة بالذكاء الاصطناعي المالي" : "Advanced AI Recommendations", 
          included: true 
        },
        { 
          name: isAr ? "تنبؤ متقدم وشامل بالتدفقات النقدية" : "Advanced Cash Flow Forecasting", 
          included: true 
        },
        { 
          name: isAr ? "تقارير مالية مخصصة وتصدير معمق" : "Custom Reports", 
          included: true 
        },
        { 
          name: isAr ? "فواتير غير محدودة" : "Unlimited Invoices", 
          included: true 
        },
        { 
          name: isAr ? "مستخدمون متعددون (حتى 5 مستخدمين)" : "Multiple Users (up to 5)", 
          included: true 
        },
        { 
          name: isAr ? "دعم حتى 5 شركات" : "Up to 5 Business Support", 
          included: true, 
          tooltip: isAr 
            ? "إدارة حتى 5 كيانات تجارية مستقلة مع دفاتر محاسبية منفصلة."
            : "Manage up to 5 individual corporate entities with independent ledger and tax filing." 
        },
        { 
          name: isAr ? "تصدير غير محدود للبيانات" : "Export Data (Unlimited)", 
          included: true 
        },
        { 
          name: isAr ? "دعم متميز ذو أولوية قصوى" : "Priority Support", 
          included: true 
        },
      ]
    }
  ];

  const comparisonRows = [
    {
      name: isAr ? "محادثة ورؤى الذكاء الاصطناعي" : "AI Chat & Insights",
      free: isAr ? "10 استفسارات / شهر" : "10 queries / month",
      plus: isAr ? "100 استفسار / شهر" : "100 queries / month",
      pro: isAr ? "300 استفسار / شهر" : "300 queries / month",
      highlight: false,
    },
    {
      name: isAr ? "توصيات الذكاء الاصطناعي" : "AI Recommendations",
      free: false,
      plus: true,
      pro: true,
      highlight: false,
    },
    {
      name: isAr ? "التنبؤ بالتدفقات النقدية" : "Cash Flow Forecasting",
      free: false,
      plus: true,
      pro: true,
      highlight: false,
    },
    {
      name: isAr ? "التقارير المالية" : "Financial Reports",
      free: isAr ? "أساسية" : "Basic",
      plus: isAr ? "متقدمة" : "Advanced",
      pro: isAr ? "متقدمة + مخصصة" : "Advanced + Custom",
      highlight: true,
    },
    {
      name: isAr ? "الفواتير" : "Invoices",
      free: isAr ? "حتى 5 / شهر" : "Up to 5 / month",
      plus: isAr ? "حتى 50 / شهر" : "Up to 50 / month",
      pro: isAr ? "غير محدودة" : "Unlimited",
      highlight: true,
    },
    {
      name: isAr ? "المستخدمون" : "Users",
      free: isAr ? "1" : "1",
      plus: isAr ? "حتى 3" : "Up to 3",
      pro: isAr ? "حتى 5" : "Up to 5",
      highlight: true,
    },
    {
      name: isAr ? "دعم الشركات" : "Businesses Support",
      hasInfo: true,
      tooltip: isAr 
        ? "عدد الشركات المستقلة التي يمكنك إدارتها مع مقاييس ومخططات ومحاسبة ذكاء اصطناعي مخصصة."
        : "Number of independent companies you can manage with dedicated metrics, charts, and AI accounting.",
      free: "1",
      plus: isAr ? "حتى 3" : "Up to 3",
      pro: isAr ? "حتى 5" : "Up to 5",
      highlight: true,
    },
    {
      name: isAr ? "تصدير البيانات" : "Export Data",
      free: isAr ? "5 عمليات / شهر" : "5 exports / month",
      plus: isAr ? "15 عملية / شهر" : "15 exports / month",
      pro: isAr ? "غير محدود" : "Unlimited",
      highlight: true,
    },
    {
      name: isAr ? "دعم البريد الإلكتروني" : "Email Support",
      free: false,
      plus: true,
      pro: true,
      highlight: false,
    },
    {
      name: isAr ? "دعم ذو أولوية" : "Priority Support",
      free: false,
      plus: false,
      pro: true,
      highlight: false,
    },
    {
      name: isAr ? "تجربة مجانية 7 أيام" : "7-Day Free Trial",
      free: "—",
      plus: true,
      pro: true,
      highlight: false,
    },
  ];

  const handleStartTrial = (planId: "plus" | "pro") => {
    setSelectedPlanForTrial(planId);
    setCheckoutStep("form");
    setIsCheckoutOpen(true);
  };

  const handleConfirmCheckout = (e: React.FormEvent) => {
    e.preventDefault();
    setCheckoutStep("success");
    if (selectedPlanForTrial) {
      setActivePlan(selectedPlanForTrial);
    }
  };

  return (
    <div className="relative min-h-screen bg-[#f8f9fb] dark:bg-[#070913] text-slate-800 dark:text-slate-200 antialiased selection:bg-purple-600 selection:text-white transition-colors duration-200 pb-16">
      {/* Background ambient lighting glows in dark mode */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 w-[1000px] h-[550px] bg-purple-600/5 dark:bg-gradient-to-b dark:from-purple-900/20 dark:via-indigo-900/10 dark:to-transparent blur-[140px] -z-10" />
      <div className="pointer-events-none absolute top-[30%] -right-40 w-[600px] h-[600px] bg-purple-600/5 dark:bg-purple-600/10 blur-[150px] -z-10" />

      <div className="px-4 sm:px-6 lg:px-12 py-8 max-w-7xl w-full mx-auto space-y-10">
        
        {/* ── Header & Banner Section ── */}
        <section className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <h1 className="text-3xl md:text-4xl font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2 flex-wrap">
              <span>{isAr ? "اختر" : "Choose Your"}</span>
              <span className="bg-gradient-to-r from-purple-500 via-indigo-500 to-purple-600 dark:from-purple-400 dark:via-indigo-400 dark:to-purple-500 bg-clip-text text-transparent">
                {isAr ? "خطتك" : "Plan"}
              </span>
            </h1>
            <p className="text-slate-500 dark:text-slate-400 text-sm mt-1.5 font-medium">
              {isAr 
                ? "احصل على الأدوات المدعومة بالذكاء الاصطناعي التي تحتاجها لإدارة وتنمية أعمالك."
                : "Get the AI-powered tools you need to manage and grow your business."}
            </p>
          </div>

          {/* Manage Multiple Businesses mini banner */}
          <div className="flex items-center gap-3 bg-white dark:bg-[#0F142A] border border-slate-200 dark:border-indigo-900/40 p-3 px-4 rounded-2xl max-w-sm shadow-sm dark:shadow-none">
            <div className="w-10 h-10 rounded-xl bg-purple-50 dark:bg-indigo-950/80 border border-purple-200 dark:border-indigo-700/50 flex items-center justify-center shrink-0 text-purple-600 dark:text-indigo-400">
              <Building2 className="w-5 h-5" />
            </div>
            <div>
              <h5 className="text-xs font-bold text-slate-900 dark:text-white leading-snug">
                {isAr ? "إدارة شركات متعددة" : "Manage Multiple Businesses"}
              </h5>
              <p className="text-[11px] text-slate-500 dark:text-slate-400 leading-tight mt-0.5">
                {isAr 
                  ? "أضف وتنقل بين الشركات بسهولة، مع بيانات ورؤى مستقلة لكل شركة."
                  : "Add and switch between businesses easily, with separate data and insights."}
              </p>
            </div>
          </div>
        </section>

        {/* ── Billing Toggle & Free Trial Alert ── */}
        <div className="flex flex-col items-center justify-center space-y-4">
          {/* Monthly / Yearly Pill Switcher */}
          <div className="bg-slate-100 dark:bg-[#0B0F21] p-1.5 rounded-full border border-slate-200 dark:border-slate-800/80 flex items-center gap-1 shadow-inner">
            <button
              type="button"
              onClick={() => setBillingPeriod("monthly")}
              className={`px-6 py-2 rounded-full text-xs font-semibold transition-all duration-200 cursor-pointer ${
                billingPeriod === "monthly"
                  ? "bg-purple-600 text-white shadow-md shadow-purple-900/40"
                  : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              {isAr ? "شهري" : "Monthly"}
            </button>
            <button
              type="button"
              onClick={() => setBillingPeriod("yearly")}
              className={`px-6 py-2 rounded-full text-xs font-medium transition-all duration-200 cursor-pointer flex items-center gap-2 ${
                billingPeriod === "yearly"
                  ? "bg-purple-600 text-white shadow-md shadow-purple-900/40 font-semibold"
                  : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              <span>{isAr ? "سنوي" : "Yearly"}</span>
              <span className="bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 text-[10px] font-bold px-2 py-0.5 rounded-full border border-emerald-500/30">
                {isAr ? "وفر 20%" : "Save 20%"}
              </span>
            </button>
          </div>

          {/* 7-day free trial ribbon */}
          <div className="flex items-center gap-2 text-xs text-slate-700 dark:text-slate-300 bg-purple-50 dark:bg-purple-950/20 border border-purple-200 dark:border-purple-900/40 px-4 py-2 rounded-xl shadow-sm dark:shadow-none">
            <Gift className="w-4 h-4 text-purple-600 dark:text-purple-400 shrink-0" />
            <span>
              <strong className="text-purple-600 dark:text-purple-300 font-semibold underline underline-offset-2">
                {isAr ? "تجربة مجانية لمدة 7 أيام على باقتي Plus و Pro." : "7-day free trial on Plus & Pro plans."}
              </strong>{" "}
              {isAr ? "يمكنك الإلغاء في أي وقت." : "Cancel anytime."}
            </span>
          </div>
        </div>

        {/* ── Pricing Cards Grid ── */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-6 items-stretch pt-2">
          {plans.map((plan) => {
            const isPlus = plan.id === "plus";
            const isPro = plan.id === "pro";
            const isCurrent = activePlan === plan.id;
            const price = billingPeriod === "monthly" ? plan.priceMonthly : plan.priceYearly;

            return (
              <div
                key={plan.id}
                className={`rounded-3xl p-6 flex flex-col justify-between relative transition-all duration-300 ${
                  isPlus
                    ? "bg-gradient-to-b from-purple-50/90 via-indigo-50/30 to-white dark:from-[#0F142D] dark:via-[#0C1024] dark:to-[#0A0D1E] border-2 border-purple-500 dark:border-purple-500/80 shadow-2xl shadow-purple-500/10 dark:shadow-[0_0_35px_-8px_rgba(124,58,237,0.4)] scale-102 z-20"
                    : isPro
                    ? "bg-gradient-to-b from-amber-50/70 via-amber-50/20 to-white dark:from-[#131124] dark:via-[#0E0D1C] dark:to-[#090A16] border-2 border-amber-500/40 dark:border-amber-500/30 hover:border-amber-500/70 dark:hover:border-amber-500/60 shadow-xl shadow-amber-500/10 dark:shadow-[0_0_35px_-10px_rgba(245,158,11,0.25)] group relative overflow-hidden"
                    : "bg-white dark:bg-[#0A0D1D]/90 border border-slate-200 dark:border-[#171D38] hover:border-slate-300 dark:hover:border-slate-700 shadow-sm dark:shadow-xl group relative overflow-hidden"
                }`}
              >
                {/* Corner ambient glow for Pro */}
                {isPro && (
                  <div className="absolute -top-12 -right-12 w-36 h-36 bg-amber-500/10 dark:bg-amber-500/15 rounded-full blur-2xl pointer-events-none" />
                )}

                {/* Most Popular Badge on Plus */}
                {isPlus && (
                  <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-gradient-to-r from-purple-600 via-indigo-600 to-purple-600 text-white font-bold text-[11px] px-3.5 py-1 rounded-full border border-purple-400 flex items-center gap-1 shadow-lg shadow-purple-900/50">
                    <Sparkles className="w-3 h-3 text-yellow-300" />
                    <span>{plan.badge || (isAr ? "الأكثر شيوعاً" : "Most Popular")}</span>
                  </div>
                )}

                <div className="relative z-10">
                  {/* Icon Badge */}
                  <div className="flex items-center justify-between mb-5">
                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center border shadow-sm ${
                      plan.id === "free"
                        ? "bg-emerald-50 dark:bg-emerald-950/60 border-emerald-200 dark:border-emerald-500/30 text-emerald-600 dark:text-emerald-400"
                        : plan.id === "plus"
                        ? "bg-indigo-50 dark:bg-indigo-950/80 border-indigo-200 dark:border-indigo-500/40 text-indigo-600 dark:text-indigo-400 shadow-indigo-900/30"
                        : "bg-amber-100/80 dark:bg-amber-950/60 border-amber-300 dark:border-amber-500/40 text-amber-600 dark:text-amber-400 shadow-amber-500/10 dark:shadow-amber-900/40"
                    }`}>
                      {plan.id === "free" && <Globe2 className="w-6 h-6 stroke-[2]" />}
                      {plan.id === "plus" && <Zap className="w-6 h-6 fill-current" />}
                      {plan.id === "pro" && <Crown className="w-6 h-6 fill-current text-amber-500 dark:text-amber-400" />}
                    </div>

                    {isCurrent && (
                      <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-500/15 border border-emerald-200 dark:border-emerald-500/30 px-2.5 py-1 rounded-full">
                        {isAr ? "نشط" : "Active"}
                      </span>
                    )}
                  </div>

                  {/* Title & Description */}
                  <h3 className="text-xl font-bold text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
                    <span>{plan.name}</span>
                    {isPro && (
                      <span className="text-[10px] font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400 bg-amber-100 dark:bg-amber-500/15 border border-amber-300 dark:border-amber-500/30 px-2 py-0.5 rounded-full">
                        VIP
                      </span>
                    )}
                  </h3>
                  <p className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-0.5">
                    {plan.subtitle}
                  </p>

                  {/* Price */}
                  <div className="mt-4 mb-3 flex items-baseline gap-1.5">
                    <span className={`text-4xl font-extrabold tracking-tight ${
                      isPro ? "text-slate-900 dark:text-white" : "text-slate-900 dark:text-white"
                    }`}>
                      ${price === 0 ? "0" : price.toFixed(2)}
                    </span>
                    <span className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                      {isAr ? "/ شهر" : "/ month"}
                    </span>
                    {billingPeriod === "yearly" && price > 0 && (
                      <span className="text-[11px] text-purple-600 dark:text-purple-400 font-semibold ms-1">
                        {isAr ? "(تدفع سنوياً)" : "(billed annually)"}
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed min-h-[36px]">
                    {plan.description}
                  </p>

                  {/* CTA Button */}
                  <div>
                    {plan.id === "free" ? (
                      <button
                        type="button"
                        disabled
                        className="w-full mt-5 py-2.5 px-4 bg-slate-100 dark:bg-[#11172E] text-slate-500 dark:text-slate-300 font-semibold text-xs rounded-xl border border-slate-200 dark:border-slate-700/60 cursor-default transition-colors text-center"
                      >
                        {isAr ? "الخطة الحالية" : "Current Plan"}
                      </button>
                    ) : isPlus ? (
                      <button
                        type="button"
                        onClick={() => handleStartTrial("plus")}
                        className="w-full mt-5 py-2.5 px-4 bg-gradient-to-r from-purple-600 via-indigo-600 to-purple-600 hover:from-purple-500 hover:to-indigo-500 text-white font-semibold text-xs rounded-xl shadow-lg shadow-purple-900/50 flex items-center justify-center gap-1.5 transition-all cursor-pointer hover:scale-[1.01] active:scale-[0.99]"
                      >
                        <span>{isAr ? "ابدأ التجربة المجانية" : "Start Free Trial"}</span>
                        <ArrowRight className="w-3.5 h-3.5 rtl:rotate-180" />
                      </button>
                    ) : (
                      <button
                        type="button"
                        onClick={() => handleStartTrial("pro")}
                        className="w-full mt-5 py-2.5 px-4 bg-gradient-to-r from-amber-500 via-amber-400 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-bold text-xs sm:text-sm rounded-xl shadow-lg shadow-amber-900/40 flex items-center justify-center gap-1.5 transition-all cursor-pointer hover:scale-[1.01] active:scale-[0.99]"
                      >
                        <span>{isAr ? "ابدأ التجربة المجانية" : "Start Free Trial"}</span>
                        <ArrowRight className="w-3.5 h-3.5 rtl:rotate-180" />
                      </button>
                    )}
                  </div>

                  {/* Feature List */}
                  <div className={`mt-6 pt-6 border-t ${
                    isPro ? "border-amber-200/60 dark:border-amber-500/20" : "border-slate-200 dark:border-slate-800/80"
                  } space-y-3`}>
                    <p className={`text-xs font-semibold tracking-wide uppercase ${
                      isPro ? "text-amber-700 dark:text-amber-400" : "text-slate-900 dark:text-white"
                    }`}>
                      {plan.featuresHeader}
                    </p>

                    <ul className="space-y-2.5 text-xs text-slate-700 dark:text-slate-300">
                      {plan.features.map((feature, idx) => (
                        <li 
                          key={idx} 
                          className={`flex items-center gap-2.5 ${
                            feature.included ? "" : "text-slate-400 dark:text-slate-600"
                          }`}
                        >
                          {feature.included ? (
                            <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 shrink-0 stroke-[2.5]" />
                          ) : (
                            <X className="w-4 h-4 text-slate-400 dark:text-slate-600 shrink-0 stroke-[2]" />
                          )}

                          <span className="flex-1">
                            {feature.name}
                          </span>

                          {feature.tooltip && (
                            <div className="relative">
                              <button
                                type="button"
                                onMouseEnter={() => setActiveTooltip(feature.name)}
                                onMouseLeave={() => setActiveTooltip(null)}
                                onClick={() => setActiveTooltip(activeTooltip === feature.name ? null : feature.name)}
                                className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 focus:outline-none"
                              >
                                <Info className="w-3.5 h-3.5" />
                              </button>
                              {activeTooltip === feature.name && (
                                <div className="absolute z-30 bottom-full end-0 mb-2 w-52 p-2 rounded-lg bg-white dark:bg-gray-900 border border-purple-500/40 text-[11px] text-slate-700 dark:text-gray-300 shadow-xl backdrop-blur-md">
                                  {feature.tooltip}
                                </div>
                              )}
                            </div>
                          )}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>

                {/* Bottom decorative graphics matching mockupstitch */}
                {plan.id === "free" && (
                  <div className="absolute -bottom-8 -right-8 w-44 h-44 bg-cyan-500/5 dark:bg-cyan-950/20 rounded-full blur-2xl pointer-events-none" />
                )}

                {plan.id === "plus" && (
                  <div className="mt-6 flex justify-end items-end gap-1.5 opacity-70 pointer-events-none">
                    <div className="w-3 h-4 bg-indigo-400/40 dark:bg-indigo-500/40 rounded-t" />
                    <div className="w-3 h-7 bg-indigo-500/60 dark:bg-indigo-500/60 rounded-t" />
                    <div className="w-3 h-10 bg-purple-500/70 dark:bg-purple-500/70 rounded-t" />
                    <div className="w-3 h-14 bg-gradient-to-t from-purple-500 to-indigo-400 rounded-t shadow-md" />
                  </div>
                )}

                {plan.id === "pro" && (
                  <div className="mt-6 flex justify-end items-end gap-2 opacity-90 pointer-events-none">
                    <div className="w-7 h-7 rounded-lg bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-amber-500 dark:text-amber-400 shadow-sm shadow-amber-500/20">
                      <Crown className="w-4 h-4 fill-current text-amber-500 dark:text-amber-400" />
                    </div>
                    <div className="w-3 h-8 bg-amber-500/30 rounded-t" />
                    <div className="w-3 h-12 bg-amber-500/60 rounded-t" />
                    <div className="w-3.5 h-16 bg-gradient-to-t from-amber-500 via-amber-400 to-yellow-300 rounded-t shadow-md shadow-amber-500/30" />
                  </div>
                )}
              </div>
            );
          })}
        </section>

        {/* ── Compare Plans Table ── */}
        <section className="bg-white dark:bg-[#0A0D1F] border border-slate-200 dark:border-[#171D38] rounded-3xl overflow-hidden mt-12 shadow-sm dark:shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-start text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-200 dark:border-[#1A213D] bg-slate-50 dark:bg-[#0C1026]">
                  <th className="py-5 px-6 font-bold text-slate-900 dark:text-white text-base w-2/5 text-start">
                    {isAr ? "مقارنة الخطط" : "Compare Plans"}
                  </th>
                  {/* Free Column */}
                  <th className="py-5 px-6 text-center w-1/5">
                    <div className="inline-flex items-center gap-1.5 font-bold text-slate-900 dark:text-white text-sm">
                      <span className="w-5 h-5 rounded-md bg-emerald-100 dark:bg-emerald-950 border border-emerald-300 dark:border-emerald-500/30 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                        <Globe2 className="w-3.5 h-3.5 stroke-[2.5]" />
                      </span>
                      <span>{isAr ? "مجاني" : "Free"}</span>
                    </div>
                  </th>
                  {/* Plus Column */}
                  <th className="py-5 px-6 text-center w-1/5 bg-purple-50 dark:bg-purple-950/20 border-x border-purple-100 dark:border-purple-900/30 relative">
                    <span className="text-[9px] uppercase tracking-wider font-bold text-purple-600 dark:text-purple-300 block mb-0.5">
                      {isAr ? "☆ الأكثر شيوعاً" : "☆ Most Popular"}
                    </span>
                    <div className="inline-flex items-center gap-1.5 font-bold text-slate-900 dark:text-white text-sm">
                      <span className="w-5 h-5 rounded-md bg-indigo-100 dark:bg-indigo-950 border border-indigo-300 dark:border-indigo-500/40 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
                        <Zap className="w-3 h-3 fill-current" />
                      </span>
                      <span>Plus</span>
                    </div>
                  </th>
                  {/* Pro Column */}
                  <th className="py-5 px-6 text-center w-1/5">
                    <div className="inline-flex items-center gap-1.5 font-bold text-slate-900 dark:text-white text-sm">
                      <span className="w-5 h-5 rounded-md bg-amber-100 dark:bg-amber-950 border border-amber-300 dark:border-amber-500/40 flex items-center justify-center text-amber-600 dark:text-amber-400">
                        <Crown className="w-3.5 h-3.5 fill-current" />
                      </span>
                      <span>Pro</span>
                    </div>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-[#151B33] text-slate-700 dark:text-slate-300">
                {comparisonRows.map((row, index) => (
                  <tr key={index} className="hover:bg-slate-50/50 dark:hover:bg-white/[0.02] transition-colors">
                    <td className="py-3.5 px-6 font-medium flex items-center gap-1.5 text-start">
                      <span>{row.name}</span>
                      {row.hasInfo && (
                        <div className="relative inline-block">
                          <button
                            type="button"
                            onMouseEnter={() => setActiveTooltip(`comp-${row.name}`)}
                            onMouseLeave={() => setActiveTooltip(null)}
                            className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
                          >
                            <Info className="w-3.5 h-3.5" />
                          </button>
                          {activeTooltip === `comp-${row.name}` && (
                            <div className="absolute z-30 bottom-full start-0 mb-2 w-56 p-2 rounded-lg bg-white dark:bg-gray-900 border border-purple-500/40 text-[11px] text-slate-700 dark:text-gray-300 shadow-xl">
                              {row.tooltip}
                            </div>
                          )}
                        </div>
                      )}
                    </td>

                    {/* Free Column */}
                    <td className="py-3.5 px-6 text-center text-slate-500 dark:text-slate-400">
                      {typeof row.free === "boolean" ? (
                        row.free ? (
                          <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 mx-auto stroke-[2.5]" />
                        ) : (
                          <span className="text-slate-400 dark:text-slate-600">✕</span>
                        )
                      ) : (
                        <span>{row.free}</span>
                      )}
                    </td>

                    {/* Plus Column */}
                    <td className="py-3.5 px-6 text-center bg-purple-50/60 dark:bg-purple-950/20 border-x border-purple-100 dark:border-purple-900/30">
                      {typeof row.plus === "boolean" ? (
                        row.plus ? (
                          <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 mx-auto stroke-[2.5]" />
                        ) : (
                          <span className="text-slate-400 dark:text-slate-600">✕</span>
                        )
                      ) : (
                        <span className={`font-semibold ${
                          row.highlight ? "text-emerald-600 dark:text-emerald-400" : "text-slate-800 dark:text-slate-200"
                        }`}>
                          {row.plus}
                        </span>
                      )}
                    </td>

                    {/* Pro Column */}
                    <td className="py-3.5 px-6 text-center">
                      {typeof row.pro === "boolean" ? (
                        row.pro ? (
                          <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 mx-auto stroke-[2.5]" />
                        ) : (
                          <span className="text-slate-400 dark:text-slate-600">✕</span>
                        )
                      ) : (
                        <span className={`font-semibold ${
                          row.highlight ? "text-emerald-600 dark:text-emerald-400" : "text-slate-800 dark:text-slate-200"
                        }`}>
                          {row.pro}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {/* ── Why Upgrade Section ── */}
        <section className="pt-4">
          <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-4">
            {isAr ? "لماذا الترقية؟" : "Why Upgrade?"}
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {/* Card 1: Save Time */}
            <div className="bg-white dark:bg-[#0A0E21] border border-slate-200 dark:border-[#161D38] p-4 rounded-2xl flex items-center gap-3.5 shadow-sm dark:shadow-none">
              <div className="w-11 h-11 rounded-xl bg-purple-50 dark:bg-purple-950/70 border border-purple-200 dark:border-purple-700/50 flex items-center justify-center shrink-0 text-purple-600 dark:text-purple-400">
                <Clock className="w-5 h-5" />
              </div>
              <div>
                <h5 className="text-xs font-bold text-slate-900 dark:text-white leading-tight">
                  {isAr ? "توفير الوقت" : "Save Time"}
                </h5>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5 leading-snug">
                  {isAr ? "دع الذكاء الاصطناعي يتولى الأرقام نيابة عنك." : "Let AI handle the numbers for you."}
                </p>
              </div>
            </div>

            {/* Card 2: Make Better Decisions */}
            <div className="bg-white dark:bg-[#0A0E21] border border-slate-200 dark:border-[#161D38] p-4 rounded-2xl flex items-center gap-3.5 shadow-sm dark:shadow-none">
              <div className="w-11 h-11 rounded-xl bg-sky-50 dark:bg-sky-950/70 border border-sky-200 dark:border-sky-700/50 flex items-center justify-center shrink-0 text-sky-600 dark:text-sky-400">
                <BarChart3 className="w-5 h-5" />
              </div>
              <div>
                <h5 className="text-xs font-bold text-slate-900 dark:text-white leading-tight">
                  {isAr ? "قرارات أكثر ذكاءً" : "Make Better Decisions"}
                </h5>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5 leading-snug">
                  {isAr ? "احصل على رؤى فورية تساعدك على النمو والازدهار." : "Get insights that help you grow."}
                </p>
              </div>
            </div>

            {/* Card 3: Manage More Businesses */}
            <div className="bg-white dark:bg-[#0A0E21] border border-slate-200 dark:border-[#161D38] p-4 rounded-2xl flex items-center gap-3.5 shadow-sm dark:shadow-none">
              <div className="w-11 h-11 rounded-xl bg-amber-50 dark:bg-amber-950/70 border border-amber-200 dark:border-amber-700/50 flex items-center justify-center shrink-0 text-amber-600 dark:text-amber-400">
                <TrendingUp className="w-5 h-5" />
              </div>
              <div>
                <h5 className="text-xs font-bold text-slate-900 dark:text-white leading-tight">
                  {isAr ? "إدارة شركات متعددة" : "Manage More Businesses"}
                </h5>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5 leading-snug">
                  {isAr ? "أدر أعمالك المتعددة في مكان واحد بسهولة." : "Handle multiple businesses in one place."}
                </p>
              </div>
            </div>

            {/* Card 4: Secure & Private */}
            <div className="bg-white dark:bg-[#0A0E21] border border-slate-200 dark:border-[#161D38] p-4 rounded-2xl flex items-center gap-3.5 shadow-sm dark:shadow-none">
              <div className="w-11 h-11 rounded-xl bg-emerald-50 dark:bg-emerald-950/70 border border-emerald-200 dark:border-emerald-700/50 flex items-center justify-center shrink-0 text-emerald-600 dark:text-emerald-400">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <div>
                <h5 className="text-xs font-bold text-slate-900 dark:text-white leading-tight">
                  {isAr ? "أمان وخصوصية تامة" : "Secure & Private"}
                </h5>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5 leading-snug">
                  {isAr ? "بياناتك مشفرة ولا تتم مشاركتها أبدًا." : "Your data is encrypted and never shared."}
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ── Bottom Free Trial Banner ── */}
        <section className="rounded-3xl bg-gradient-to-r from-purple-900 via-indigo-900 to-violet-950 dark:from-[#171336] dark:via-[#1E1949] dark:to-[#120F2E] border border-purple-500/30 dark:border-purple-600/30 p-6 md:p-8 flex flex-col md:flex-row items-center justify-between gap-6 shadow-xl relative overflow-hidden">
          <div className="absolute -left-12 -bottom-12 w-48 h-48 bg-purple-600/20 rounded-full blur-3xl pointer-events-none" />
          
          <div className="flex items-center gap-4 relative z-10">
            <div className="w-12 h-12 rounded-2xl bg-white/10 dark:bg-purple-800/40 border border-white/20 dark:border-purple-400/40 flex items-center justify-center shrink-0 text-purple-200 dark:text-purple-300">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <h4 className="text-base md:text-lg font-bold text-white">
                {isAr ? "جرب Plus أو Pro مجاناً لمدة 7 أيام" : "Try Plus or Pro free for 7 days"}
              </h4>
              <p className="text-xs text-purple-200 dark:text-slate-300 mt-0.5">
                {isAr 
                  ? "افتح أدوات الذكاء الاصطناعي المتقدمة وأدر شركاتك المتعددة بكل سهولة."
                  : "Unlock powerful AI tools and manage multiple businesses with ease."}
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => handleStartTrial("plus")}
            className="relative z-10 shrink-0 px-6 py-3 bg-gradient-to-r from-purple-500 to-indigo-500 hover:from-purple-400 hover:to-indigo-400 text-white font-bold text-xs rounded-xl shadow-lg shadow-purple-900/50 flex items-center gap-2 transition-all cursor-pointer hover:scale-[1.02] active:scale-[0.98]"
          >
            <span>{isAr ? "ابدأ التجربة المجانية" : "Start Free Trial"}</span>
            <ArrowRight className="w-4 h-4 rtl:rotate-180" />
          </button>
        </section>

      </div>

      {/* ── 7-Day Free Trial Checkout Modal ── */}
      <AnimatePresence>
        {isCheckoutOpen && selectedPlanForTrial && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 dark:bg-black/75 backdrop-blur-md">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="relative w-full max-w-lg rounded-3xl bg-white dark:bg-[#0f1428] border border-slate-200 dark:border-purple-500/40 p-6 sm:p-8 text-slate-900 dark:text-white shadow-2xl overflow-hidden"
            >
              <button
                type="button"
                onClick={() => setIsCheckoutOpen(false)}
                className="absolute top-4 end-4 w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 dark:bg-white/10 dark:hover:bg-white/20 flex items-center justify-center text-slate-500 dark:text-gray-300 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>

              {checkoutStep === "form" ? (
                <form onSubmit={handleConfirmCheckout} className="space-y-6">
                  {/* Modal Header */}
                  <div className="space-y-1">
                    <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-purple-50 dark:bg-purple-500/15 border border-purple-200 dark:border-purple-500/30 text-purple-700 dark:text-purple-300 text-xs font-semibold">
                      <Gift className="w-3.5 h-3.5" />
                      <span>{isAr ? "تجربة مجانية 7 أيام" : "7-Day Free Trial"}</span>
                    </div>
                    <h3 className="text-xl sm:text-2xl font-extrabold text-slate-900 dark:text-white">
                      {isAr 
                        ? `ابدأ تجربتك المجانية لباقة ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}`
                        : `Start your trial on ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}`}
                    </h3>
                    <p className="text-xs sm:text-sm text-slate-500 dark:text-gray-400">
                      {isAr 
                        ? "بدون أي خصم اليوم. وصول كامل لمدة 7 أيام. يمكنك الإلغاء في أي وقت بنقرة واحدة."
                        : "Zero charge today. Full access for 7 days. Cancel anytime with 1-click."}
                    </p>
                  </div>

                  {/* Summary Box */}
                  <div className="p-4 rounded-2xl bg-slate-50 dark:bg-purple-950/30 border border-slate-200 dark:border-purple-500/30 space-y-3">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-slate-600 dark:text-gray-300 font-medium">
                        {isAr ? "المستحق اليوم (فترة تجريبية):" : "Due Today (Trial):"}
                      </span>
                      <span className="text-emerald-600 dark:text-emerald-400 font-bold">$0.00</span>
                    </div>
                    <div className="flex items-center justify-between text-xs text-slate-500 dark:text-gray-400 border-t border-slate-200 dark:border-white/10 pt-2">
                      <span>
                        {isAr 
                          ? `بعد 7 أيام (${billingPeriod === "monthly" ? "شهري" : "سنوي"}):`
                          : `After 7 days (${billingPeriod}):`}
                      </span>
                      <span className="font-semibold text-slate-900 dark:text-white">
                        {selectedPlanForTrial === "plus"
                          ? billingPeriod === "monthly" ? "$9.99 / mo" : "$95.88 / yr ($7.99/mo)"
                          : billingPeriod === "monthly" ? "$19.99 / mo" : "$191.88 / yr ($15.99/mo)"}
                      </span>
                    </div>
                  </div>

                  {/* Payment Inputs */}
                  <div className="space-y-4">
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 dark:text-gray-300 mb-1">
                        {isAr ? "اسم حامل البطاقة" : "Cardholder Name"}
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="Ahmed Al-Kindi"
                        className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-gray-700 bg-white dark:bg-[#12162b] text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-semibold text-slate-700 dark:text-gray-300 mb-1">
                        {isAr ? "رقم البطاقة" : "Card Number"}
                      </label>
                      <div className="relative">
                        <input
                          type="text"
                          required
                          placeholder="•••• •••• •••• 4242"
                          className="w-full px-3.5 py-2.5 ps-10 rounded-xl border border-slate-200 dark:border-gray-700 bg-white dark:bg-[#12162b] text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500"
                        />
                        <CreditCard className="w-4 h-4 text-slate-400 absolute start-3 top-3" />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block text-xs font-semibold text-slate-700 dark:text-gray-300 mb-1">
                          {isAr ? "تاريخ الانتهاء" : "Expires"}
                        </label>
                        <input
                          type="text"
                          required
                          placeholder="MM/YY"
                          className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-gray-700 bg-white dark:bg-[#12162b] text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-semibold text-slate-700 dark:text-gray-300 mb-1">
                          {isAr ? "رمز التحقق (CVC)" : "CVC"}
                        </label>
                        <input
                          type="text"
                          required
                          placeholder="123"
                          className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-gray-700 bg-white dark:bg-[#12162b] text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Submit Button */}
                  <button
                    type="submit"
                    className="w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-purple-600 via-indigo-600 to-purple-600 hover:from-purple-500 hover:to-indigo-500 text-white font-bold text-sm shadow-xl shadow-purple-900/40 transition-all hover:scale-[1.01] active:scale-[0.99] cursor-pointer flex items-center justify-center gap-2"
                  >
                    <Lock className="w-4 h-4" />
                    <span>{isAr ? "تأكيد وبدء التجربة المجانية" : "Confirm & Start Free Trial"}</span>
                  </button>

                  <p className="text-[11px] text-center text-slate-400 flex items-center justify-center gap-1">
                    <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
                    <span>{isAr ? "مشفر وآمن 100%. بدون مخاطر." : "256-bit encrypted. Cancel in 1-click from dashboard."}</span>
                  </p>
                </form>
              ) : (
                <div className="py-8 text-center space-y-4">
                  <div className="w-16 h-16 rounded-full bg-emerald-500/20 text-emerald-500 border border-emerald-500/40 flex items-center justify-center mx-auto">
                    <CheckCircle2 className="w-8 h-8" />
                  </div>
                  <h3 className="text-2xl font-extrabold text-slate-900 dark:text-white">
                    {isAr 
                      ? `أهلاً بك في ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}! 🎉`
                      : `Welcome to ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}! 🎉`}
                  </h3>
                  <p className="text-xs sm:text-sm text-slate-500 dark:text-gray-400 max-w-sm mx-auto">
                    {isAr 
                      ? "تم تفعيل تجربتك المجانية لمدة 7 أيام بنجاح. استمتع بكامل ميزات الذكاء الاصطناعي وإدارة الشركات."
                      : "Your 7-day free trial has been activated. Enjoy advanced AI insights, forecasting, and multi-business tools."}
                  </p>
                  <div className="pt-4">
                    <button
                      type="button"
                      onClick={() => setIsCheckoutOpen(false)}
                      className="px-6 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-semibold text-xs transition-colors"
                    >
                      {isAr ? "الانتقال إلى لوحة التحكم" : "Go to Dashboard"}
                    </button>
                  </div>
                </div>
              )}
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
