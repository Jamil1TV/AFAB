"use client";

import { useState, useEffect } from "react";
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
  ChevronRight,
  Loader2
} from "lucide-react";
import { useLocale } from "next-intl";
import { motion, AnimatePresence } from "framer-motion";
import { Link } from "@/i18n/routing";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { SubscriptionService, SubscriptionSnapshot } from "@/lib/api/subscription";
import { AuthStore } from "@/lib/auth-store";
import { toast } from "sonner";

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

export function PlansScreen({ embedded = false }: { embedded?: boolean } = {}) {
  const locale = useLocale();
  const isAr = locale === "ar";

  const [billingPeriod, setBillingPeriod] = useState<"monthly" | "yearly">("monthly");
  const [activePlan, setActivePlan] = useState<"free" | "plus" | "pro">("free");
  const [subscription, setSubscription] = useState<SubscriptionSnapshot | null>(null);
  const [selectedPlanForTrial, setSelectedPlanForTrial] = useState<"plus" | "pro" | null>(null);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [checkoutStep, setCheckoutStep] = useState<"form" | "success">("form");
  const [activeTooltip, setActiveTooltip] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    async function loadSubscription() {
      setIsLoading(true);
      try {
        const sub = await SubscriptionService.getMySubscription();
        setSubscription(sub);
        if (sub?.planSlug) {
          setActivePlan(sub.planSlug);
        }
      } catch (err) {
        console.warn("Could not load subscription details", err);
      } finally {
        setIsLoading(false);
      }
    }
    loadSubscription();
  }, []);

  const hasUsedTrial = Boolean(subscription?.trialEnd);

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
    setErrorMessage(null);
    setCheckoutStep("form");
    setIsCheckoutOpen(true);
  };

  const handleConfirmCheckout = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPlanForTrial) return;
    setIsSubmitting(true);
    setErrorMessage(null);
    try {
      const updated = await SubscriptionService.activateTrial(selectedPlanForTrial);
      setSubscription(updated);
      setActivePlan(selectedPlanForTrial);
      const user = AuthStore.getUser();
      if (user) {
        AuthStore.updateUser({ planTier: selectedPlanForTrial.toUpperCase() });
      }
      toast.success(isAr ? "تم تفعيل الفترة التجريبية بنجاح!" : "Trial activated successfully!");
      setCheckoutStep("success");
    } catch (err: any) {
      const msg = err?.message || (isAr ? "فشل تفعيل الفترة التجريبية" : "Failed to activate trial");
      setErrorMessage(msg);
      toast.error(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSwitchPlan = async (planId: "free" | "plus" | "pro") => {
    if (planId === activePlan) return;
    setIsSubmitting(true);
    try {
      const updated = await SubscriptionService.switchPlan(planId);
      setSubscription(updated);
      setActivePlan(planId);
      const user = AuthStore.getUser();
      if (user) {
        AuthStore.updateUser({ planTier: planId.toUpperCase() });
      }
      toast.success(isAr ? "تم تحديث خطتك بنجاح!" : `Switched to ${planId.toUpperCase()} plan!`);
    } catch (err: any) {
      toast.error(err?.message || (isAr ? "فشل تغيير الخطة" : "Failed to switch plan"));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className={`${embedded ? "w-full space-y-8" : "afab-page"} animate-in fade-in duration-700`}>
      {/* ── Header & Banner Section ── */}
      <PageHeader
        title={
          <span className="inline-flex flex-wrap items-center gap-2">
            <span>{isAr ? "اختر" : "Choose Your"}</span>
            <span className="bg-gradient-to-r from-[#8b5cf6] via-indigo-500 to-[#7c3aed] dark:from-[#a78bfa] dark:via-indigo-400 dark:to-[#8b5cf6] bg-clip-text text-transparent">
              {isAr ? "خطتك" : "Plan"}
            </span>
          </span>
        }
        subtitle={
          isAr
            ? "احصل على الأدوات المدعومة بالذكاء الاصطناعي التي تحتاجها لإدارة وتنمية أعمالك."
            : "Get the AI-powered tools you need to manage and grow your business."
        }
        actions={
          <div className="afab-card flex items-center gap-3 p-3 px-4 max-w-sm">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]">
              <Building2 className="w-5 h-5" />
            </div>
            <div>
              <h5 className="text-xs font-bold text-gray-900 dark:text-white leading-snug">
                {isAr ? "إدارة شركات متعددة" : "Manage Multiple Businesses"}
              </h5>
              <p className="text-[11px] text-gray-500 dark:text-gray-400 leading-tight mt-0.5">
                {isAr
                  ? "أضف وتنقل بين الشركات بسهولة، مع بيانات ورؤى مستقلة لكل شركة."
                  : "Add and switch between businesses easily, with separate data and insights."}
              </p>
            </div>
          </div>
        }
      />

      {/* ── Billing Toggle & Free Trial Alert ── */}
      <div className="flex flex-col items-center justify-center space-y-4">
        {/* Monthly / Yearly Segmented Switcher */}
        <div className="afab-segmented">
          <button
            type="button"
            onClick={() => setBillingPeriod("monthly")}
            className={`afab-segment px-5 py-2 ${
              billingPeriod === "monthly" ? "afab-segment-active" : ""
            }`}
          >
            {isAr ? "شهري" : "Monthly"}
          </button>
          <button
            type="button"
            onClick={() => setBillingPeriod("yearly")}
            className={`afab-segment px-5 py-2 ${
              billingPeriod === "yearly" ? "afab-segment-active" : ""
            }`}
          >
            <span>{isAr ? "سنوي" : "Yearly"}</span>
            <span
              className={`afab-badge rounded-full px-2 py-0.5 border ${
                billingPeriod === "yearly"
                  ? "bg-white/20 text-white border-white/30"
                  : "afab-badge-success border-emerald-500/20"
              }`}
            >
              {isAr ? "وفر 20%" : "Save 20%"}
            </span>
          </button>
        </div>

        {/* 7-day free trial banner or active countdown */}
        {subscription?.isTrial ? (
          <div className="flex flex-wrap items-center justify-center gap-2.5 text-xs text-white bg-gradient-to-r from-purple-600 to-indigo-600 border border-purple-400/40 px-5 py-2.5 rounded-2xl shadow-md shadow-purple-600/20">
            <Clock className="w-4 h-4 text-amber-300 animate-pulse shrink-0" />
            <span>
              <strong>
                {isAr
                  ? `أنت حالياً في فترة تجريبية مجانية لباقة ${subscription.planName}.`
                  : `You are currently on a 7-day free trial of ${subscription.planName}.`}
              </strong>{" "}
              <span className="bg-white/20 px-2 py-0.5 rounded-full font-bold">
                {isAr
                  ? `متبقي ${subscription.trialDaysRemaining ?? 7} أيام`
                  : `${subscription.trialDaysRemaining ?? 7} days remaining`}
              </span>
            </span>
          </div>
        ) : (
          <div className="flex flex-wrap items-center justify-center gap-2 text-xs text-gray-700 dark:text-gray-300 bg-purple-50 dark:bg-purple-500/10 border border-purple-200 dark:border-purple-500/20 px-4 py-2 rounded-xl shadow-sm">
            <Gift className="w-4 h-4 text-[#7c3aed] dark:text-[#a78bfa] shrink-0" />
            <span>
              <strong className="text-[#7c3aed] dark:text-[#a78bfa] font-semibold underline underline-offset-2">
                {isAr ? "تجربة مجانية لمدة 7 أيام على باقتي Plus و Pro." : "7-day free trial on Plus & Pro plans."}
              </strong>{" "}
              {isAr ? "يمكنك الإلغاء في أي وقت." : "Cancel anytime."}
            </span>
          </div>
        )}
      </div>

      {/* ── Pricing Cards Grid ── */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-stretch pt-2">
        {plans.map((plan) => {
          const isPlus = plan.id === "plus";
          const isPro = plan.id === "pro";
          const isCurrent = activePlan === plan.id;
          const price = billingPeriod === "monthly" ? plan.priceMonthly : plan.priceYearly;

          return (
            <div
              key={plan.id}
              className={`rounded-2xl p-6 flex flex-col justify-between relative transition-all duration-300 ${
                isPlus
                  ? "bg-gradient-to-b from-purple-50/80 via-white to-white dark:from-[#8b5cf6]/10 dark:via-[#0c101c] dark:to-[#0c101c] border-2 border-[#8b5cf6] dark:border-[#8b5cf6]/80 shadow-lg shadow-[#8b5cf6]/10 lg:scale-[1.02] z-20"
                  : isPro
                  ? "bg-gradient-to-b from-amber-50/60 via-white to-white dark:from-amber-500/[0.07] dark:via-[#0c101c] dark:to-[#0c101c] border border-amber-500/40 dark:border-amber-500/30 hover:border-amber-500/60 dark:hover:border-amber-500/50 shadow-sm afab-card-hover group"
                  : "afab-card afab-card-hover group"
              }`}
            >
              {/* Most Popular Badge on Plus */}
              {isPlus && (
                <div className="absolute -top-3.5 inset-x-0 mx-auto w-fit bg-gradient-to-r from-purple-600 to-indigo-600 text-white font-bold text-[10px] px-3.5 py-1 rounded-full border border-purple-400/40 flex items-center gap-1 shadow-md shadow-purple-600/30 whitespace-nowrap">
                  <Sparkles className="w-3 h-3 text-amber-300" />
                  <span>{plan.badge || (isAr ? "الأكثر شيوعاً" : "Most Popular")}</span>
                </div>
              )}

              <div className="relative z-10">
                {/* Icon Badge */}
                <div className="flex items-center justify-between mb-5">
                  <div
                    className={`w-12 h-12 rounded-2xl flex items-center justify-center border shadow-sm ${
                      plan.id === "free"
                        ? "bg-emerald-50 dark:bg-emerald-500/10 border-emerald-200 dark:border-emerald-500/20 text-emerald-600 dark:text-emerald-400"
                        : plan.id === "plus"
                        ? "bg-[#8b5cf6]/10 border-purple-200 dark:border-purple-500/30 text-[#7c3aed] dark:text-[#a78bfa]"
                        : "bg-amber-50 dark:bg-amber-500/10 border-amber-200 dark:border-amber-500/30 text-amber-600 dark:text-amber-400"
                    }`}
                  >
                    {plan.id === "free" && <Globe2 className="w-6 h-6 stroke-[2]" />}
                    {plan.id === "plus" && <Zap className="w-6 h-6 fill-current" />}
                    {plan.id === "pro" && <Crown className="w-6 h-6 fill-current text-amber-500 dark:text-amber-400" />}
                  </div>

                  {isCurrent && (
                    <span className="afab-badge afab-badge-success px-2.5 py-1 rounded-full uppercase tracking-wider border border-emerald-500/20">
                      {isAr ? "نشط" : "Active"}
                    </span>
                  )}
                </div>

                {/* Title & Description */}
                <h3 className="text-xl font-bold text-gray-900 dark:text-white tracking-tight flex items-center gap-2">
                  <span>{plan.name}</span>
                  {isPro && (
                    <span className="afab-badge afab-badge-warning px-2 py-0.5 rounded-full uppercase tracking-wider border border-amber-500/20">
                      VIP
                    </span>
                  )}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mt-0.5">
                  {plan.subtitle}
                </p>

                {/* Price */}
                <div className="mt-4 mb-3 flex items-baseline gap-1.5 flex-wrap">
                  <span className="text-3xl sm:text-4xl font-bold tracking-tight text-gray-900 dark:text-white">
                    ${price === 0 ? "0" : price.toFixed(2)}
                  </span>
                  <span className="text-xs text-gray-500 dark:text-gray-400 font-medium">
                    {isAr ? "/ شهر" : "/ month"}
                  </span>
                  {billingPeriod === "yearly" && price > 0 && (
                    <span className="text-[11px] text-[#7c3aed] dark:text-[#a78bfa] font-semibold ms-1">
                      {isAr ? "(تدفع سنوياً)" : "(billed annually)"}
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-600 dark:text-gray-400 leading-relaxed min-h-[36px]">
                  {plan.description}
                </p>

                {/* CTA Button */}
                <div>
                  {isCurrent ? (
                    <button
                      type="button"
                      disabled
                      className="afab-btn-secondary w-full mt-5 py-2.5 cursor-default disabled:opacity-80"
                    >
                      <Check className="w-3.5 h-3.5 text-emerald-500" />
                      <span>{isAr ? "الخطة الحالية" : "Current Plan"}</span>
                    </button>
                  ) : plan.id === "free" ? (
                    <button
                      type="button"
                      disabled={isSubmitting}
                      onClick={() => handleSwitchPlan("free")}
                      className="afab-btn-secondary w-full mt-5 py-2.5"
                    >
                      {isSubmitting ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <span>{isAr ? "الرجوع للخطة المجانية" : "Downgrade to Free"}</span>
                      )}
                    </button>
                  ) : !hasUsedTrial ? (
                    <button
                      type="button"
                      disabled={isSubmitting}
                      onClick={() => handleStartTrial(plan.id as "plus" | "pro")}
                      className="afab-btn-premium w-full mt-5 py-2.5"
                    >
                      <span>{isAr ? "ابدأ التجربة المجانية (7 أيام)" : "Start 7-Day Free Trial"}</span>
                      <ArrowRight className="w-3.5 h-3.5 rtl:rotate-180" />
                    </button>
                  ) : (
                    <button
                      type="button"
                      disabled={isSubmitting}
                      onClick={() => handleSwitchPlan(plan.id as "plus" | "pro")}
                      className="afab-btn-premium w-full mt-5 py-2.5"
                    >
                      {isSubmitting ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <>
                          <span>{isAr ? `الترقية إلى ${plan.name}` : `Upgrade to ${plan.name}`}</span>
                          <ArrowRight className="w-3.5 h-3.5 rtl:rotate-180" />
                        </>
                      )}
                    </button>
                  )}
                </div>

                {/* Feature List */}
                <div
                  className={`mt-6 pt-6 border-t ${
                    isPro
                      ? "border-amber-200/60 dark:border-amber-500/20"
                      : "border-gray-200 dark:border-gray-800/60"
                  } space-y-3`}
                >
                  <p
                    className={`text-xs font-semibold tracking-wide uppercase ${
                      isPro ? "text-amber-700 dark:text-amber-400" : "text-gray-900 dark:text-white"
                    }`}
                  >
                    {plan.featuresHeader}
                  </p>

                  <ul className="space-y-2.5 text-xs text-gray-700 dark:text-gray-300">
                    {plan.features.map((feature, idx) => (
                      <li
                        key={idx}
                        className={`flex items-center gap-2.5 ${
                          feature.included ? "" : "text-gray-400 dark:text-gray-600"
                        }`}
                      >
                        {feature.included ? (
                          <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 shrink-0 stroke-[2.5]" />
                        ) : (
                          <X className="w-4 h-4 text-gray-400 dark:text-gray-600 shrink-0 stroke-[2]" />
                        )}

                        <span className="flex-1">{feature.name}</span>

                        {feature.tooltip && (
                          <div className="relative">
                            <button
                              type="button"
                              onMouseEnter={() => setActiveTooltip(feature.name)}
                              onMouseLeave={() => setActiveTooltip(null)}
                              onClick={() =>
                                setActiveTooltip(activeTooltip === feature.name ? null : feature.name)
                              }
                              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 focus:outline-none"
                            >
                              <Info className="w-3.5 h-3.5" />
                            </button>
                            {activeTooltip === feature.name && (
                              <div className="afab-popover absolute z-30 bottom-full end-0 mb-2 w-52 text-[11px] font-normal text-gray-700 dark:text-gray-300">
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

              {/* Bottom decorative bar graphics for Plus & Pro */}
              {plan.id === "plus" && (
                <div className="mt-6 flex justify-end items-end gap-1.5 opacity-70 pointer-events-none">
                  <div className="w-3 h-4 bg-indigo-400/40 dark:bg-indigo-500/40 rounded-t" />
                  <div className="w-3 h-7 bg-indigo-500/60 dark:bg-indigo-500/60 rounded-t" />
                  <div className="w-3 h-10 bg-purple-500/70 dark:bg-purple-500/70 rounded-t" />
                  <div className="w-3 h-14 bg-gradient-to-t from-purple-500 to-indigo-400 rounded-t shadow-sm" />
                </div>
              )}

              {plan.id === "pro" && (
                <div className="mt-6 flex justify-end items-end gap-2 opacity-90 pointer-events-none">
                  <div className="w-7 h-7 rounded-lg bg-amber-500/15 border border-amber-500/30 flex items-center justify-center text-amber-500 dark:text-amber-400">
                    <Crown className="w-4 h-4 fill-current text-amber-500 dark:text-amber-400" />
                  </div>
                  <div className="w-3 h-8 bg-amber-500/30 rounded-t" />
                  <div className="w-3 h-12 bg-amber-500/60 rounded-t" />
                  <div className="w-3.5 h-16 bg-gradient-to-t from-amber-500 via-amber-400 to-yellow-300 rounded-t shadow-sm" />
                </div>
              )}
            </div>
          );
        })}
      </section>

      {/* ── Compare Plans Table ── */}
      <section className="afab-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="afab-table border-collapse">
            <thead className="afab-thead normal-case tracking-normal">
              <tr>
                <th className="afab-th py-4 font-bold text-gray-900 dark:text-white text-base w-2/5">
                  {isAr ? "مقارنة الخطط" : "Compare Plans"}
                </th>
                {/* Free Column */}
                <th className="afab-th py-4 text-center w-1/5">
                  <div className="inline-flex items-center gap-1.5 font-bold text-gray-900 dark:text-white text-sm">
                    <span className="w-5 h-5 rounded-md bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                      <Globe2 className="w-3.5 h-3.5 stroke-[2.5]" />
                    </span>
                    <span>{isAr ? "مجاني" : "Free"}</span>
                  </div>
                </th>
                {/* Plus Column */}
                <th className="afab-th py-4 text-center w-1/5 bg-purple-50/50 dark:bg-[#8b5cf6]/[0.06] border-x border-purple-100 dark:border-purple-500/20 relative">
                  <span className="text-[9px] uppercase tracking-wider font-bold text-[#7c3aed] dark:text-[#a78bfa] block mb-0.5">
                    {isAr ? "☆ الأكثر شيوعاً" : "☆ Most Popular"}
                  </span>
                  <div className="inline-flex items-center gap-1.5 font-bold text-gray-900 dark:text-white text-sm">
                    <span className="w-5 h-5 rounded-md bg-[#8b5cf6]/10 border border-purple-200 dark:border-purple-500/30 flex items-center justify-center text-[#7c3aed] dark:text-[#a78bfa]">
                      <Zap className="w-3 h-3 fill-current" />
                    </span>
                    <span>Plus</span>
                  </div>
                </th>
                {/* Pro Column */}
                <th className="afab-th py-4 text-center w-1/5">
                  <div className="inline-flex items-center gap-1.5 font-bold text-gray-900 dark:text-white text-sm">
                    <span className="w-5 h-5 rounded-md bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/30 flex items-center justify-center text-amber-600 dark:text-amber-400">
                      <Crown className="w-3.5 h-3.5 fill-current" />
                    </span>
                    <span>Pro</span>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody className="afab-tbody">
              {comparisonRows.map((row, index) => (
                <tr key={index} className="afab-tr">
                  <td className="afab-td font-medium flex items-center gap-1.5 text-start text-gray-900 dark:text-white">
                    <span>{row.name}</span>
                    {row.hasInfo && (
                      <div className="relative inline-block">
                        <button
                          type="button"
                          onMouseEnter={() => setActiveTooltip(`comp-${row.name}`)}
                          onMouseLeave={() => setActiveTooltip(null)}
                          className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                        >
                          <Info className="w-3.5 h-3.5" />
                        </button>
                        {activeTooltip === `comp-${row.name}` && (
                          <div className="afab-popover absolute z-30 bottom-full start-0 mb-2 w-56 text-[11px] font-normal text-gray-700 dark:text-gray-300">
                            {row.tooltip}
                          </div>
                        )}
                      </div>
                    )}
                  </td>

                  {/* Free Column */}
                  <td className="afab-td text-center text-gray-500 dark:text-gray-400">
                    {typeof row.free === "boolean" ? (
                      row.free ? (
                        <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 mx-auto stroke-[2.5]" />
                      ) : (
                        <span className="text-gray-400 dark:text-gray-600">✕</span>
                      )
                    ) : (
                      <span>{row.free}</span>
                    )}
                  </td>

                  {/* Plus Column */}
                  <td className="afab-td text-center bg-purple-50/40 dark:bg-[#8b5cf6]/[0.04] border-x border-purple-100 dark:border-purple-500/20">
                    {typeof row.plus === "boolean" ? (
                      row.plus ? (
                        <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 mx-auto stroke-[2.5]" />
                      ) : (
                        <span className="text-gray-400 dark:text-gray-600">✕</span>
                      )
                    ) : (
                      <span
                        className={`font-semibold ${
                          row.highlight
                            ? "text-emerald-600 dark:text-emerald-400"
                            : "text-gray-900 dark:text-white"
                        }`}
                      >
                        {row.plus}
                      </span>
                    )}
                  </td>

                  {/* Pro Column */}
                  <td className="afab-td text-center">
                    {typeof row.pro === "boolean" ? (
                      row.pro ? (
                        <Check className="w-4 h-4 text-emerald-500 dark:text-emerald-400 mx-auto stroke-[2.5]" />
                      ) : (
                        <span className="text-gray-400 dark:text-gray-600">✕</span>
                      )
                    ) : (
                      <span
                        className={`font-semibold ${
                          row.highlight
                            ? "text-emerald-600 dark:text-emerald-400"
                            : "text-gray-900 dark:text-white"
                        }`}
                      >
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
      <section className="space-y-4">
        <h3 className="afab-card-title">
          {isAr ? "لماذا الترقية؟" : "Why Upgrade?"}
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Card 1: Save Time */}
          <div className="afab-card afab-card-hover p-5 flex items-center gap-3.5">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]">
              <Clock className="w-5 h-5" />
            </div>
            <div>
              <h5 className="text-xs font-bold text-gray-900 dark:text-white leading-tight">
                {isAr ? "توفير الوقت" : "Save Time"}
              </h5>
              <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug">
                {isAr ? "دع الذكاء الاصطناعي يتولى الأرقام نيابة عنك." : "Let AI handle the numbers for you."}
              </p>
            </div>
          </div>

          {/* Card 2: Make Better Decisions */}
          <div className="afab-card afab-card-hover p-5 flex items-center gap-3.5">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-sky-500/10 text-sky-600 dark:text-sky-400">
              <BarChart3 className="w-5 h-5" />
            </div>
            <div>
              <h5 className="text-xs font-bold text-gray-900 dark:text-white leading-tight">
                {isAr ? "قرارات أكثر ذكاءً" : "Make Better Decisions"}
              </h5>
              <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug">
                {isAr ? "احصل على رؤى فورية تساعدك على النمو والازدهار." : "Get insights that help you grow."}
              </p>
            </div>
          </div>

          {/* Card 3: Manage More Businesses */}
          <div className="afab-card afab-card-hover p-5 flex items-center gap-3.5">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400">
              <TrendingUp className="w-5 h-5" />
            </div>
            <div>
              <h5 className="text-xs font-bold text-gray-900 dark:text-white leading-tight">
                {isAr ? "إدارة شركات متعددة" : "Manage More Businesses"}
              </h5>
              <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug">
                {isAr ? "أدر أعمالك المتعددة في مكان واحد بسهولة." : "Handle multiple businesses in one place."}
              </p>
            </div>
          </div>

          {/* Card 4: Secure & Private */}
          <div className="afab-card afab-card-hover p-5 flex items-center gap-3.5">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h5 className="text-xs font-bold text-gray-900 dark:text-white leading-tight">
                {isAr ? "أمان وخصوصية تامة" : "Secure & Private"}
              </h5>
              <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug">
                {isAr ? "بياناتك مشفرة ولا تتم مشاركتها أبدًا." : "Your data is encrypted and never shared."}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ── Bottom Free Trial Banner ── */}
      <section className="afab-card bg-gradient-to-r from-purple-50 via-indigo-50/60 to-purple-50 dark:from-[#8b5cf6]/15 dark:via-[#0c101c] dark:to-[#0c101c] border-purple-200 dark:border-purple-500/30 p-6 md:p-8 flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-[#8b5cf6]/10 border border-purple-500/20 flex items-center justify-center shrink-0 text-[#7c3aed] dark:text-[#a78bfa]">
            <Sparkles className="w-6 h-6" />
          </div>
          <div>
            <h4 className="text-base md:text-lg font-bold text-gray-900 dark:text-white">
              {isAr ? "جرب Plus أو Pro مجاناً لمدة 7 أيام" : "Try Plus or Pro free for 7 days"}
            </h4>
            <p className="text-xs text-gray-600 dark:text-gray-300 mt-0.5">
              {isAr
                ? "افتح أدوات الذكاء الاصطناعي المتقدمة وأدر شركاتك المتعددة بكل سهولة."
                : "Unlock powerful AI tools and manage multiple businesses with ease."}
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => handleStartTrial("plus")}
          className="afab-btn-premium px-6 py-3"
        >
          <span>{isAr ? "ابدأ التجربة المجانية" : "Start Free Trial"}</span>
          <ArrowRight className="w-4 h-4 rtl:rotate-180" />
        </button>
      </section>

      {/* ── 7-Day Free Trial Checkout Modal ── */}
      <AnimatePresence>
        {isCheckoutOpen && selectedPlanForTrial && (
          <div className="afab-overlay">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="afab-modal max-w-lg text-gray-900 dark:text-white"
            >
              <button
                type="button"
                onClick={() => setIsCheckoutOpen(false)}
                className="afab-icon-btn absolute top-4 end-4 flex h-9 w-9 items-center justify-center rounded-xl"
              >
                <X className="w-4 h-4" />
              </button>

              {checkoutStep === "form" ? (
                <form onSubmit={handleConfirmCheckout} className="space-y-6">
                  {/* Modal Header */}
                  <div className="space-y-1">
                    <div className="afab-badge afab-badge-primary px-3 py-1 rounded-full text-xs font-semibold border border-purple-500/20">
                      <Gift className="w-3.5 h-3.5" />
                      <span>{isAr ? "تجربة مجانية 7 أيام" : "7-Day Free Trial"}</span>
                    </div>
                    <h3 className="text-xl sm:text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
                      {isAr
                        ? `ابدأ تجربتك المجانية لباقة ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}`
                        : `Start your trial on ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}`}
                    </h3>
                    <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400">
                      {isAr
                        ? "بدون أي خصم اليوم. وصول كامل لمدة 7 أيام. يمكنك الإلغاء في أي وقت بنقرة واحدة."
                        : "Zero charge today. Full access for 7 days. Cancel anytime with 1-click."}
                    </p>
                  </div>

                  {/* Summary Box */}
                  <div className="afab-inset p-4 space-y-3">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-600 dark:text-gray-300 font-medium">
                        {isAr ? "المستحق اليوم (فترة تجريبية):" : "Due Today (Trial):"}
                      </span>
                      <span className="text-emerald-600 dark:text-emerald-400 font-bold">$0.00</span>
                    </div>
                    <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 border-t border-gray-200 dark:border-gray-800/60 pt-2">
                      <span>
                        {isAr
                          ? `بعد 7 أيام (${billingPeriod === "monthly" ? "شهري" : "سنوي"}):`
                          : `After 7 days (${billingPeriod}):`}
                      </span>
                      <span className="font-semibold text-gray-900 dark:text-white">
                        {selectedPlanForTrial === "plus"
                          ? billingPeriod === "monthly"
                            ? "$9.99 / mo"
                            : "$95.88 / yr ($7.99/mo)"
                          : billingPeriod === "monthly"
                          ? "$19.99 / mo"
                          : "$191.88 / yr ($15.99/mo)"}
                      </span>
                    </div>
                  </div>

                  {/* Payment Inputs */}
                  <div className="space-y-4">
                    <div>
                      <label className="afab-label">
                        {isAr ? "اسم حامل البطاقة" : "Cardholder Name"}
                      </label>
                      <input
                        type="text"
                        defaultValue="Ahmed Al-Kindi"
                        placeholder="Ahmed Al-Kindi"
                        className="afab-input"
                      />
                    </div>

                    <div>
                      <label className="afab-label">
                        {isAr ? "رقم البطاقة" : "Card Number"}
                      </label>
                      <div className="relative">
                        <input
                          type="text"
                          defaultValue="4242 •••• •••• 4242"
                          placeholder="•••• •••• •••• 4242"
                          className="afab-input ps-10"
                        />
                        <CreditCard className="w-4 h-4 text-gray-400 absolute start-3 top-1/2 -translate-y-1/2" />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="afab-label">
                          {isAr ? "تاريخ الانتهاء" : "Expires"}
                        </label>
                        <input
                          type="text"
                          defaultValue="12/28"
                          placeholder="MM/YY"
                          className="afab-input"
                        />
                      </div>
                      <div>
                        <label className="afab-label">
                          {isAr ? "رمز التحقق (CVC)" : "CVC"}
                        </label>
                        <input
                          type="text"
                          defaultValue="123"
                          placeholder="123"
                          className="afab-input"
                        />
                      </div>
                    </div>
                  </div>

                  {errorMessage && (
                    <div className="rounded-xl bg-red-50 dark:bg-red-500/10 p-3 text-xs font-medium text-red-600 dark:text-red-400 border border-red-200 dark:border-red-500/20">
                      {errorMessage}
                    </div>
                  )}

                  {/* Submit Button */}
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="afab-btn-premium w-full py-3 px-4 text-sm font-bold"
                  >
                    {isSubmitting ? (
                      <>
                        <Loader2 className="w-4 h-4 animate-spin" />
                        <span>{isAr ? "جاري المعالجة والتفعيل..." : "Processing & Activating..."}</span>
                      </>
                    ) : (
                      <>
                        <Lock className="w-4 h-4" />
                        <span>{isAr ? "تأكيد وبدء التجربة المجانية" : "Confirm & Start Free Trial"}</span>
                      </>
                    )}
                  </button>

                  <p className="text-[11px] text-center text-gray-400 dark:text-gray-500 flex items-center justify-center gap-1">
                    <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
                    <span>{isAr ? "مشفر وآمن 100%. بدون مخاطر." : "256-bit encrypted. Cancel in 1-click from dashboard."}</span>
                  </p>
                </form>
              ) : (
                <div className="py-8 text-center space-y-4">
                  <div className="w-16 h-16 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 flex items-center justify-center mx-auto">
                    <CheckCircle2 className="w-8 h-8" />
                  </div>
                  <h3 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
                    {isAr
                      ? `أهلاً بك في ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}! 🎉`
                      : `Welcome to ${selectedPlanForTrial === "plus" ? "Plus" : "Pro"}! 🎉`}
                  </h3>
                  <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 max-w-sm mx-auto">
                    {isAr
                      ? "تم تفعيل تجربتك المجانية لمدة 7 أيام بنجاح. استمتع بكامل ميزات الذكاء الاصطناعي وإدارة الشركات."
                      : "Your 7-day free trial has been activated. Enjoy advanced AI insights, forecasting, and multi-business tools."}
                  </p>
                  <div className="pt-4">
                    <button
                      type="button"
                      onClick={() => setIsCheckoutOpen(false)}
                      className="afab-btn-primary px-6 py-2.5"
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
