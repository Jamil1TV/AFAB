"use client";

import { Suspense, useState, useEffect, useCallback, useRef } from "react";
import { useSearchParams } from "next/navigation";
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
  Globe2,
  Loader2,
  ExternalLink,
  AlertTriangle,
  Lock,
  RotateCcw,
  History,
  FileText,
  SlidersHorizontal,
} from "lucide-react";
import { useLocale } from "next-intl";
import { usePathname } from "@/i18n/routing";
import { PageHeader } from "@/components/dashboard/PageHeader";
import {
  SubscriptionService,
  SubscriptionSnapshot,
  BillingHistoryResponse,
} from "@/lib/api/subscription";
import {
  BusinessService,
  BusinessAllocationSummary,
} from "@/lib/api/business";
import { AuthStore } from "@/lib/auth-store";
import { toast } from "sonner";
import { CancelSubscriptionModal } from "./CancelSubscriptionModal";
import { BusinessAllocationModal } from "./BusinessAllocationModal";

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
  return (
    <Suspense
      fallback={
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-6 w-6 animate-spin text-[#7c3aed]" />
        </div>
      }
    >
      <PlansScreenInner embedded={embedded} />
    </Suspense>
  );
}

function PlansScreenInner({ embedded = false }: { embedded?: boolean }) {
  const locale = useLocale();
  const isAr = locale === "ar";
  const searchParams = useSearchParams();
  const rawPathname = usePathname();
  const returnPath = rawPathname?.startsWith("/dashboard")
    ? rawPathname
    : "/dashboard/settings/subscription";

  const [billingPeriod, setBillingPeriod] = useState<"monthly" | "yearly">("monthly");
  const [activePlan, setActivePlan] = useState<"free" | "plus" | "pro">("free");
  const [subscription, setSubscription] = useState<SubscriptionSnapshot | null>(null);
  const [allocation, setAllocation] = useState<BusinessAllocationSummary | null>(null);
  const [history, setHistory] = useState<BillingHistoryResponse | null>(null);
  const [activeTooltip, setActiveTooltip] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [submittingAction, setSubmittingAction] = useState<string | null>(null);

  // Modals & Plan Cards Visibility Toggle
  const [showPlanCardsOverride, setShowPlanCardsOverride] = useState(false);
  const planCardsSectionRef = useRef<HTMLDivElement>(null);
  const [cancelModalOpen, setCancelModalOpen] = useState(false);
  const [allocationModalOpen, setAllocationModalOpen] = useState(false);
  const [allocationModalMode, setAllocationModalMode] = useState<
    "DOWNGRADE" | "MANAGE" | "PENDING_EDIT"
  >("MANAGE");
  const [targetDowngradePlan, setTargetDowngradePlan] = useState<"free" | "plus">("plus");

  const refreshAllBillingData = useCallback(async () => {
    const [sub, alloc, hist] = await Promise.all([
      SubscriptionService.getMySubscription(),
      BusinessService.getAllocations().catch(() => null),
      SubscriptionService.getBillingHistory().catch(() => null),
    ]);
    if (sub) {
      setSubscription(sub);
      if (sub.planSlug) {
        setActivePlan(sub.planSlug);
        AuthStore.updateUser({ planTier: sub.planSlug.toUpperCase() });
      }
      if (sub.billingInterval === "YEARLY") {
        setBillingPeriod("yearly");
      } else if (sub.billingInterval === "MONTHLY") {
        setBillingPeriod("monthly");
      }
    }
    if (alloc) setAllocation(alloc);
    if (hist) setHistory(hist);
    if (typeof window !== "undefined") {
      window.dispatchEvent(new Event("afab:subscription-updated"));
    }
  }, []);

  useEffect(() => {
    let active = true;

    async function initBillingState() {
      setIsLoading(true);
      try {
        const checkoutStatus = searchParams.get("checkout");
        const sessionId = searchParams.get("session_id");
        const wantsChangePlan = searchParams.get("changePlan") === "true";
        if (wantsChangePlan) {
          setShowPlanCardsOverride(true);
        }

        if (checkoutStatus === "success" && sessionId) {
          const verified = await SubscriptionService.verifyCheckoutSession(sessionId);
          if (!active) return;
          setSubscription(verified);
          setShowPlanCardsOverride(false);
          if (verified?.planSlug) {
            setActivePlan(verified.planSlug);
            AuthStore.updateUser({ planTier: verified.planSlug.toUpperCase() });
          }
          if (verified?.billingInterval === "YEARLY") {
            setBillingPeriod("yearly");
          }
          await refreshAllBillingData();
          toast.success(
            isAr
              ? "تم تفعيل اشتراكك عبر Stripe بنجاح!"
              : "Your Stripe subscription has been activated!"
          );
          if (typeof window !== "undefined") {
            window.history.replaceState({}, "", window.location.pathname);
          }
          return;
        }

        if (checkoutStatus === "canceled") {
          toast.info(
            isAr ? "تم إلغاء عملية الدفع." : "Checkout was canceled. No charges were made."
          );
          if (typeof window !== "undefined") {
            window.history.replaceState({}, "", window.location.pathname);
          }
        }

        await refreshAllBillingData();
      } catch (err: unknown) {
        console.warn("Could not load subscription details", err);
        const message = err instanceof Error ? err.message : null;
        if (searchParams.get("checkout") === "success" && message) {
          toast.error(message);
        }
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    initBillingState();
    return () => {
      active = false;
    };
  }, [isAr, searchParams, refreshAllBillingData]);

  const isTrialActive = Boolean(subscription?.trial ?? subscription?.isTrial);
  const hasUsedTrial = Boolean(subscription?.trialUsed || subscription?.trialEnd);
  const isPlusTrialEligible =
    subscription?.trialEligible !== undefined
      ? subscription.trialEligible
      : !hasUsedTrial && !subscription?.hasActiveStripeSubscription;
  const hasStripeSubscription = Boolean(subscription?.hasActiveStripeSubscription);
  const hasStripeCustomer = Boolean(subscription?.hasStripeCustomer);
  const isPastDue = subscription?.status === "PAST_DUE";
  const hasPendingChange = Boolean(
    subscription?.cancelAtPeriodEnd || subscription?.pendingPlanSlug
  );
  const isSubmitting = Boolean(submittingAction) || isLoading;

  const formatDate = (iso?: string | null) => {
    if (!iso) return null;
    try {
      return new Date(iso).toLocaleDateString(isAr ? "ar" : "en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      });
    } catch {
      return null;
    }
  };

  const tierRank = (slug: "free" | "plus" | "pro") =>
    slug === "pro" ? 2 : slug === "plus" ? 1 : 0;

  const plans: PlanData[] = [
    {
      id: "free",
      name: isAr ? "مجاني" : "Free",
      subtitle: isAr ? "للبدء واستكشاف المنصة" : "For getting started",
      priceMonthly: 0,
      priceYearly: 0,
      description: isAr
        ? "استكشف AFAB وقم بإدارة عملك الأول باستخدام الأدوات المالية والذكية الأساسية."
        : "Explore AFAB and manage 1 editable business with unlimited read-only historical businesses.",
      featuresHeader: isAr ? "تشمل الخطة:" : "INCLUDES:",
      features: [
        {
          name: isAr
            ? "محادثة ورؤى الذكاء الاصطناعي (10 استفسارات/شهر)"
            : "AI Chat & Insights (10 queries/month)",
          included: true,
        },
        {
          name: isAr ? "تقارير مالية أساسية" : "Basic Financial Reports",
          included: true,
        },
        {
          name: isAr ? "تتبع الإيرادات والمصروفات" : "Income & Expense Tracking",
          included: true,
        },
        {
          name: isAr ? "حتى 5 فواتير / شهر" : "Up to 5 Invoices / month",
          included: true,
        },
        {
          name: isAr ? "مستخدم واحد (1)" : "1 User",
          included: true,
        },
        {
          name: isAr
            ? "شركة واحدة نشطة ومفتوحة (والباقي مقفل مع حفظ البيانات)"
            : "1 Active Business (Additional Businesses Locked)",
          included: true,
          tooltip: isAr
            ? "إدارة شركة نشطة واحدة، وتبقى جميع الشركات الأخرى مقفلة مع حفظ بياناتها بأمان حتى الترقية أو التبديل."
            : "Actively manage 1 business while additional businesses remain safely locked in your navbar until you upgrade or swap.",
        },
        {
          name: isAr
            ? "تصدير البيانات (5 عمليات تصدير/شهر)"
            : "Export Data (5 exports/month)",
          included: true,
        },
        {
          name: isAr ? "توصيات الذكاء الاصطناعي" : "AI Recommendations",
          included: false,
        },
        {
          name: isAr ? "التنبؤ بالتدفقات النقدية" : "Cash Flow Forecasting",
          included: false,
        },
        {
          name: isAr ? "تقارير متقدمة" : "Advanced Reports",
          included: false,
        },
        {
          name: isAr ? "دعم ذو أولوية" : "Priority Support",
          included: false,
        },
      ],
    },
    {
      id: "plus",
      name: "Plus",
      badge: isAr ? "الأكثر شيوعاً • تجربة 7 أيام" : "Most Popular • 7-Day Trial",
      subtitle: isAr ? "للأعمال والشركات النامية" : "For growing businesses",
      priceMonthly: 9.99,
      priceYearly: 7.99,
      description: isAr
        ? "المزيد من قوة الذكاء الاصطناعي والمرونة لإدارة حتى 3 شركات قابلة للتعديل مع تجربة مجانية 7 أيام."
        : "Manage up to 3 editable businesses with AI forecasting and an exclusive 7-day free trial.",
      featuresHeader: isAr
        ? "كل ما في الخطة المجانية، بالإضافة إلى:"
        : "EVERYTHING IN FREE, PLUS:",
      features: [
        {
          name: isAr
            ? "محادثة ورؤى الذكاء الاصطناعي (100 استفسار/شهر)"
            : "AI Chat & Insights (100 queries/month)",
          included: true,
        },
        {
          name: isAr ? "توصيات الذكاء الاصطناعي الذكية" : "AI Recommendations",
          included: true,
        },
        {
          name: isAr
            ? "التنبؤ المستقبلي بالتدفقات النقدية"
            : "Cash Flow Forecasting",
          included: true,
        },
        {
          name: isAr ? "تقارير مالية وتحليلية متقدمة" : "Advanced Reports",
          included: true,
        },
        {
          name: isAr ? "حتى 50 فاتورة / شهر" : "Up to 50 Invoices / month",
          included: true,
        },
        {
          name: isAr ? "حتى 3 مستخدمين" : "Up to 3 Users",
          included: true,
        },
        {
          name: isAr
            ? "حتى 3 شركات نشطة ومفتوحة (والباقي مقفل مع حفظ البيانات)"
            : "Up to 3 Active Businesses (Additional Locked)",
          included: true,
          tooltip: isAr
            ? "إدارة والتبديل بين حتى 3 شركات مفتوحة في نفس الوقت."
            : "Actively manage and switch between up to 3 unlocked business entities.",
        },
        {
          name: isAr
            ? "تصدير البيانات (15 عملية تصدير/شهر)"
            : "Export Data (15 exports/month)",
          included: true,
        },
        {
          name: isAr ? "دعم فني عبر البريد الإلكتروني" : "Email Support",
          included: true,
        },
        {
          name: isAr ? "دعم ذو أولوية" : "Priority Support",
          included: false,
        },
      ],
    },
    {
      id: "pro",
      name: "Pro",
      subtitle: isAr ? "للأعمال المتوسعة والشركات الكبرى" : "For scaling businesses",
      priceMonthly: 19.99,
      priceYearly: 15.99,
      description: isAr
        ? "قوة غير محدودة ومرونة تامة لإدارة حتى 5 شركات قابلة للتعديل مع فواتير وتصدير غير محدود."
        : "Full power and flexibility to manage up to 5 editable businesses with unlimited invoices & exports.",
      featuresHeader: isAr ? "كل ما في Plus، بالإضافة إلى:" : "EVERYTHING IN PLUS, PLUS:",
      features: [
        {
          name: isAr
            ? "محادثة ورؤى الذكاء الاصطناعي (300 استفسار/شهر)"
            : "AI Chat & Insights (300 queries/month)",
          included: true,
        },
        {
          name: isAr
            ? "توصيات متقدمة بالذكاء الاصطناعي المالي"
            : "Advanced AI Recommendations",
          included: true,
        },
        {
          name: isAr
            ? "تنبؤ متقدم وشامل بالتدفقات النقدية"
            : "Advanced Cash Flow Forecasting",
          included: true,
        },
        {
          name: isAr ? "تقارير مالية مخصصة وتصدير معمق" : "Custom Reports",
          included: true,
        },
        {
          name: isAr ? "فواتير غير محدودة" : "Unlimited Invoices",
          included: true,
        },
        {
          name: isAr
            ? "مستخدمون متعددون (حتى 5 مستخدمين)"
            : "Multiple Users (up to 5)",
          included: true,
        },
        {
          name: isAr
            ? "حتى 5 شركات نشطة ومفتوحة (والباقي مقفل مع حفظ البيانات)"
            : "Up to 5 Active Businesses (Additional Locked)",
          included: true,
          tooltip: isAr
            ? "إدارة حتى 5 كيانات تجارية مستقلة مفتوحة بالكامل."
            : "Manage up to 5 independent corporate entities with full access.",
        },
        {
          name: isAr ? "تصدير غير محدود للبيانات" : "Export Data (Unlimited)",
          included: true,
        },
        {
          name: isAr ? "دعم متميز ذو أولوية قصوى" : "Priority Support",
          included: true,
        },
      ],
    },
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
      name: isAr ? "الشركات النشطة المفتوحة" : "Active (Unlocked) Businesses",
      hasInfo: true,
      tooltip: isAr
        ? "عدد الشركات التي يمكنك فتحها وإدارتها بنشاط. جميع الشركات الإضافية تبقى مقفلة مع حفظ بياناتها بأمان."
        : "Number of businesses you can actively open and manage. Additional businesses remain safely locked with all data preserved.",
      free: "1",
      plus: isAr ? "حتى 3" : "Up to 3",
      pro: isAr ? "حتى 5" : "Up to 5",
      highlight: true,
    },
    {
      name: isAr ? "الشركات المقفلة (البيانات محفوظة)" : "Locked Vaulted Businesses",
      free: isAr ? "غير محدود" : "Unlimited",
      plus: isAr ? "غير محدود" : "Unlimited",
      pro: isAr ? "غير محدود" : "Unlimited",
      highlight: false,
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
      name: isAr ? "تجربة مجانية 7 أيام (حصرياً لـ Plus)" : "7-Day Free Trial (Plus Exclusive)",
      free: "—",
      plus: true,
      pro: "—",
      highlight: true,
    },
  ];

  const handleUpgradeOrCheckout = async (planId: "plus" | "pro") => {
    if (submittingAction) return;
    setSubmittingAction(planId);
    try {
      if (hasStripeSubscription) {
        const res = await SubscriptionService.upgradeSubscription(
          planId,
          billingPeriod,
          locale,
          returnPath
        );
        if (res.mode === "CHECKOUT" || res.mode === "PORTAL") {
          if (res.url) {
            window.location.assign(res.url);
            return;
          }
        }
        await refreshAllBillingData();
        setShowPlanCardsOverride(false);
        toast.success(
          isAr
            ? `تمت الترقية إلى باقة ${planId.toUpperCase()} واستعادة صلاحيات التعديل لشركاتك!`
            : `Upgraded to ${planId.toUpperCase()} and restored editable access to your businesses!`
        );
        setSubmittingAction(null);
        return;
      }

      const res = await SubscriptionService.createCheckoutSession(
        planId,
        billingPeriod,
        locale,
        returnPath
      );
      if (res?.url) {
        window.location.assign(res.url);
        return;
      }
      throw new Error(
        isAr ? "تعذر إنشاء جلسة الدفع." : "Could not start Stripe Checkout session."
      );
    } catch (err: unknown) {
      const msg =
        err instanceof Error
          ? err.message
          : isAr
          ? "فشل الاتصال ببوابة الدفع Stripe"
          : "Failed to process subscription upgrade";
      toast.error(msg);
      setSubmittingAction(null);
    }
  };

  const handleOpenPortal = async () => {
    if (submittingAction) return;
    setSubmittingAction("portal");
    try {
      const res = await SubscriptionService.createPortalSession(locale, returnPath);
      if (res?.url) {
        window.location.assign(res.url);
        return;
      }
      throw new Error(isAr ? "تعذر فتح بوابة الفواتير." : "Could not open Billing Portal.");
    } catch (err: unknown) {
      const msg =
        err instanceof Error
          ? err.message
          : isAr
          ? "فشل فتح بوابة إدارة الفواتير"
          : "Failed to open Stripe Billing Portal";
      toast.error(msg);
      setSubmittingAction(null);
    }
  };

  const handleInitiateDowngrade = (targetSlug: "free" | "plus") => {
    if (targetSlug === "free") {
      setCancelModalOpen(true);
      return;
    }
    setTargetDowngradePlan("plus");
    setAllocationModalMode("DOWNGRADE");
    setAllocationModalOpen(true);
  };

  const handleConfirmCancel = async (selectedBusinessIds: string[]) => {
    if (submittingAction) return;
    setSubmittingAction("cancel");
    try {
      await SubscriptionService.cancelSubscription(selectedBusinessIds);
      await refreshAllBillingData();
      setCancelModalOpen(false);
      toast.success(
        isTrialActive
          ? isAr
            ? "تم جدولة إلغاء الفترة التجريبية. لن يتم تحصيل أي مبالغ وستحتفظ بمزايا Plus حتى نهاية الفترة."
            : "Trial cancellation scheduled. You will not be charged and you keep Plus access until your trial ends."
          : isAr
          ? "تم جدولة إلغاء الاشتراك بنهاية دورة الفوترة الحالية."
          : "Subscription cancellation scheduled for the end of your current billing period."
      );
    } catch (err: unknown) {
      toast.error(
        err instanceof Error
          ? err.message
          : isAr
          ? "فشل إلغاء الاشتراك"
          : "Failed to schedule cancellation"
      );
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleResumeSubscription = async () => {
    if (submittingAction) return;
    setSubmittingAction("resume");
    try {
      await SubscriptionService.resumeSubscription();
      await refreshAllBillingData();
      toast.success(
        isAr
          ? "تم استئناف اشتراكك وإلغاء التغيير المجدول بنجاح!"
          : "Your subscription renewal has been restored and the scheduled downgrade was canceled!"
      );
    } catch (err: unknown) {
      toast.error(
        err instanceof Error
          ? err.message
          : isAr
          ? "تعذر استئناف الاشتراك"
          : "Could not reverse scheduled cancellation"
      );
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleAllocationModalSubmit = async (selectedIds: string[]) => {
    if (submittingAction) return;
    setSubmittingAction("allocation");
    try {
      if (allocationModalMode === "DOWNGRADE") {
        const updatedSub = await SubscriptionService.scheduleDowngrade(
          targetDowngradePlan,
          selectedIds,
          billingPeriod
        );
        const appliedImmediately = updatedSub?.planSlug === targetDowngradePlan;
        if (appliedImmediately && selectedIds.length > 0) {
          const currentActive = AuthStore.getActiveBusinessId();
          if (!currentActive || !selectedIds.includes(currentActive)) {
            AuthStore.setActiveBusinessId(selectedIds[0]);
          }
        }
        toast.success(
          appliedImmediately
            ? isAr
              ? `تم تخفيض الباقة إلى ${targetDowngradePlan.toUpperCase()} وقفل الشركات غير المختارة مع حفظ بياناتها!`
              : `Downgraded to ${targetDowngradePlan.toUpperCase()}! Your ${selectedIds.length} selected business(es) remain active and the rest are now locked with data saved.`
            : isAr
            ? "تم جدولة تخفيض الباقة وحفظ اختيار الشركات النشطة!"
            : `Downgrade to ${targetDowngradePlan.toUpperCase()} scheduled for the end of your billing period, and your future active business selection has been saved!`
        );
      } else if (allocationModalMode === "PENDING_EDIT") {
        const pendingSlug =
          (subscription?.pendingPlanSlug as "free" | "plus") || "free";
        await BusinessService.savePendingAllocations(pendingSlug, selectedIds);
        toast.success(
          isAr
            ? "تم تحديث اختيار الشركات للخطة القادمة!"
            : "Updated your scheduled business allocation!"
        );
      } else {
        await BusinessService.updateAllocations(selectedIds);
        if (selectedIds.length > 0) {
          const currentActive = AuthStore.getActiveBusinessId();
          if (!currentActive || !selectedIds.includes(currentActive)) {
            AuthStore.setActiveBusinessId(selectedIds[0]);
          }
        }
        toast.success(
          isAr
            ? "تم تحديث الشركات النشطة والمقفلة بنجاح!"
            : "Active & locked business allocation updated!"
        );
      }
      await refreshAllBillingData();
      setShowPlanCardsOverride(false);
      setAllocationModalOpen(false);
    } catch (err: unknown) {
      toast.error(
        err instanceof Error
          ? err.message
          : isAr
          ? "تعذر حفظ تخصيص الشركات"
          : "Failed to save business allocation"
      );
    } finally {
      setSubmittingAction(null);
    }
  };

  const ownedBusinesses = allocation?.businesses ?? [];
  const confirmedPlanSlug = (subscription?.planSlug || activePlan || "free").toLowerCase();
  const confirmedStatus = (subscription?.status || "ACTIVE").toUpperCase();
  const hasActivePaidSubscription =
    (confirmedPlanSlug === "plus" || confirmedPlanSlug === "pro") &&
    ["ACTIVE", "TRIALING", "PAST_DUE"].includes(confirmedStatus);
  const shouldShowPlanCards = !hasActivePaidSubscription || showPlanCardsOverride;

  const handleTogglePlanCards = () => {
    const next = !showPlanCardsOverride;
    setShowPlanCardsOverride(next);
    if (next) {
      setTimeout(() => {
        planCardsSectionRef.current?.scrollIntoView({
          behavior: "smooth",
          block: "start",
        });
      }, 60);
    }
  };

  const effectiveEndDateFormatted = formatDate(
    subscription?.effectiveCancelAt ||
      subscription?.pendingChangeEffectiveAt ||
      subscription?.trialEnd ||
      subscription?.periodEnd
  );

  return (
    <div
      className={`${
        embedded ? "w-full space-y-8" : "afab-page"
      } animate-in fade-in duration-700`}
    >
      {/* ── Header & Banner Section ── */}
      <PageHeader
        title={
          <span className="inline-flex flex-wrap items-center gap-2">
            <span>{isAr ? "إدارة" : "Manage"}</span>
            <span className="bg-gradient-to-r from-[#8b5cf6] via-indigo-500 to-[#7c3aed] dark:from-[#a78bfa] dark:via-indigo-400 dark:to-[#8b5cf6] bg-clip-text text-transparent">
              {isAr ? "اشتراكك وباقتك" : "Subscription & Plans"}
            </span>
          </span>
        }
        subtitle={
          isAr
            ? "تحكم كامل في خطتك، وتجديد الاشتراك، وتخصيص الشركات القابلة للتعديل، وسجل المدفوعات."
            : "Manage your subscription lifecycle, billing period, editable business allocations, and payment history."
        }
        actions={
          <div className="afab-card flex items-center gap-3 p-3 px-4 max-w-sm">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]">
              <Building2 className="w-5 h-5" />
            </div>
            <div>
              <h5 className="text-xs font-bold text-gray-900 dark:text-white leading-snug">
                {isAr
                  ? `الشركات النشطة: ${
                      allocation?.editableCount ?? subscription?.editableBusinessCount ?? 1
                    } / ${allocation?.editableLimit ?? subscription?.editableBusinessLimit ?? 1}`
                  : `Active Businesses: ${
                      allocation?.editableCount ?? subscription?.editableBusinessCount ?? 1
                    } / ${allocation?.editableLimit ?? subscription?.editableBusinessLimit ?? 1}`}
              </h5>
              <p className="text-[11px] text-gray-500 dark:text-gray-400 leading-tight mt-0.5">
                {isAr
                  ? "الشركات الإضافية تبقى مقفلة مع حفظ بياناتها وتعود للفتح عند الترقية أو التبديل."
                  : "Additional businesses stay safely locked until you upgrade or swap."}
              </p>
            </div>
          </div>
        }
      />

      {/* ── Complete Subscription Management Overview Card ── */}
      {subscription && (
        <section className="afab-card p-6 border border-[#8b5cf6]/25 space-y-5">
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
            <div className="flex items-start gap-3.5">
              <div className="w-11 h-11 rounded-2xl bg-[#8b5cf6]/10 border border-[#8b5cf6]/25 text-[#7c3aed] dark:text-[#a78bfa] flex items-center justify-center shrink-0">
                <CreditCard className="w-5 h-5" />
              </div>
              <div className="space-y-1">
                <div className="flex flex-wrap items-center gap-2">
                  <h3 className="text-base font-bold text-gray-900 dark:text-white">
                    {isAr
                      ? `الخطة الحالية: ${subscription.planName}`
                      : `Current Plan: ${subscription.planName}`}
                  </h3>

                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider border ${
                      isPastDue
                        ? "bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/25"
                        : isTrialActive
                        ? "bg-purple-500/10 text-[#7c3aed] dark:text-[#a78bfa] border-purple-500/25"
                        : "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/25"
                    }`}
                  >
                    {subscription.status}
                  </span>

                  {subscription.billingInterval && (
                    <span className="afab-badge afab-badge-primary px-2 py-0.5 rounded-full text-[10px]">
                      {subscription.billingInterval === "YEARLY"
                        ? isAr
                          ? "فوترة سنوية"
                          : "Yearly Billing"
                        : isAr
                        ? "فوترة شهرية"
                        : "Monthly Billing"}
                    </span>
                  )}

                  {subscription.cancelAtPeriodEnd && (
                    <span className="afab-badge afab-badge-warning px-2.5 py-0.5 rounded-full text-[10px]">
                      {isAr
                        ? "مجدول للإلغاء بنهاية الفترة"
                        : "Scheduled to Cancel at Period End"}
                    </span>
                  )}

                  {subscription.pendingPlanSlug &&
                    subscription.pendingPlanSlug !== "free" && (
                      <span className="afab-badge afab-badge-warning px-2.5 py-0.5 rounded-full text-[10px]">
                        {isAr
                          ? `ينتقل إلى ${subscription.pendingPlanName} بنهاية الفترة`
                          : `Downgrades to ${subscription.pendingPlanName} at Period End`}
                      </span>
                    )}
                </div>

                {/* Dates & Trial Countdown */}
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-600 dark:text-gray-400">
                  {isTrialActive && (
                    <span className="font-semibold text-[#7c3aed] dark:text-[#a78bfa]">
                      {isAr
                        ? `فترة تجريبية لمدة 7 أيام: متبقي ${
                            subscription.trialDaysRemaining ?? 7
                          } يوم (تنتهي في ${
                            formatDate(subscription.trialEnd) || "—"
                          })`
                        : `7-Day Plus Trial: ${
                            subscription.trialDaysRemaining ?? 7
                          } day(s) remaining (expires ${
                            formatDate(subscription.trialEnd) || "—"
                          })`}
                    </span>
                  )}

                  {subscription.periodEnd && (
                    <span>
                      {subscription.cancelAtPeriodEnd
                        ? isAr
                          ? `ينتهي الوصول المدفوع في: ${formatDate(
                              subscription.effectiveCancelAt || subscription.periodEnd
                            )} (لن يتم التجديد)`
                          : `Paid access ends on: ${formatDate(
                              subscription.effectiveCancelAt || subscription.periodEnd
                            )} (will not renew)`
                        : subscription.pendingPlanSlug
                        ? isAr
                          ? `يدخل التغيير إلى ${subscription.pendingPlanName} حيز التنفيذ في: ${formatDate(
                              subscription.pendingChangeEffectiveAt || subscription.periodEnd
                            )}`
                          : `Transition to ${subscription.pendingPlanName} takes effect on: ${formatDate(
                              subscription.pendingChangeEffectiveAt || subscription.periodEnd
                            )}`
                        : isAr
                        ? `تاريخ الفوترة / التجديد القادم: ${formatDate(subscription.periodEnd)}`
                        : `Next billing / renewal date: ${formatDate(subscription.periodEnd)}`}
                    </span>
                  )}
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-wrap items-center gap-2.5">
              {hasActivePaidSubscription && confirmedPlanSlug === "plus" && (
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={handleTogglePlanCards}
                  className="afab-btn-premium px-4 py-2 text-xs inline-flex items-center gap-1.5"
                >
                  <Crown className="w-3.5 h-3.5" />
                  <span>
                    {shouldShowPlanCards
                      ? isAr
                        ? "إخفاء خطط الاشتراك"
                        : "Hide Plan Options"
                      : isAr
                      ? "الترقية إلى Pro أو تغيير الخطة"
                      : "Upgrade to Pro"}
                  </span>
                </button>
              )}

              {hasActivePaidSubscription && confirmedPlanSlug === "pro" && (
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={handleTogglePlanCards}
                  className="afab-btn-secondary px-4 py-2 text-xs inline-flex items-center gap-1.5"
                >
                  <SlidersHorizontal className="w-3.5 h-3.5" />
                  <span>
                    {shouldShowPlanCards
                      ? isAr
                        ? "إخفاء خطط الاشتراك"
                        : "Hide Plan Options"
                      : isAr
                      ? "تغيير أو تخفيض الخطة"
                      : "Change / Downgrade Plan"}
                  </span>
                </button>
              )}

              {hasPendingChange && (
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={handleResumeSubscription}
                  className="afab-btn-primary px-4 py-2 text-xs inline-flex items-center gap-1.5"
                >
                  {submittingAction === "resume" ? (
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    <RotateCcw className="w-3.5 h-3.5" />
                  )}
                  <span>
                    {subscription.cancelAtPeriodEnd
                      ? isAr
                        ? "استئناف الاشتراك وإلغاء الإيقاف"
                        : "Keep / Resume Subscription"
                      : isAr
                      ? "إلغاء التخفيض المجدول"
                      : "Cancel Scheduled Downgrade"}
                  </span>
                </button>
              )}

              {hasStripeCustomer && (
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={handleOpenPortal}
                  className="afab-btn-secondary px-4 py-2 text-xs inline-flex items-center gap-1.5"
                >
                  {submittingAction === "portal" ? (
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    <ExternalLink className="w-3.5 h-3.5" />
                  )}
                  <span>
                    {isAr
                      ? "بوابة الدفع والفواتير (Stripe)"
                      : "Manage Billing & Payment Methods"}
                  </span>
                </button>
              )}

              {hasStripeSubscription && !subscription.cancelAtPeriodEnd && (
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => setCancelModalOpen(true)}
                  className="px-3.5 py-2 rounded-xl text-xs font-semibold border border-red-500/25 bg-red-500/10 hover:bg-red-500/20 text-red-600 dark:text-red-400 transition-all"
                >
                  {isTrialActive
                    ? isAr
                      ? "إلغاء الفترة التجريبية"
                      : "Cancel Free Trial"
                    : isAr
                    ? "إلغاء الاشتراك"
                    : "Cancel Subscription"}
                </button>
              )}
            </div>
          </div>

          {/* Pending Downgrade / Cancellation Details Box */}
          {hasPendingChange && (
            <div className="rounded-2xl bg-amber-50/70 dark:bg-amber-500/10 border border-amber-500/25 p-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs">
              <div className="space-y-0.5">
                <p className="font-bold text-amber-800 dark:text-amber-300">
                  {subscription.cancelAtPeriodEnd
                    ? isAr
                      ? `اشتراكك مجدول للانتهاء في ${effectiveEndDateFormatted || "نهاية الفترة"}`
                      : `Your subscription is scheduled to end on ${
                          effectiveEndDateFormatted || "your period end date"
                        }`
                    : isAr
                    ? `تخفيض مجدول إلى باقة ${subscription.pendingPlanName} في ${
                        effectiveEndDateFormatted || "نهاية الفترة"
                      }`
                    : `Scheduled downgrade to ${subscription.pendingPlanName} on ${
                        effectiveEndDateFormatted || "your period end date"
                      }`}
                </p>
                <p className="text-gray-700 dark:text-gray-300">
                  {isAr
                    ? "تحتفظ بكامل مزايا باقتك الحالية حتى تاريخ الانتهاء، ويمكنك تعديل اختيار الشركات التي ستبقى قابلة للتعديل مسبقاً."
                    : "You retain all current plan entitlements until the effective date. You can configure or update your future editable business selection in advance."}
                </p>
              </div>

              {ownedBusinesses.length >
                (allocation?.pendingEditableLimit ?? 1) && (
                <button
                  type="button"
                  onClick={() => {
                    setTargetDowngradePlan(
                      (subscription.pendingPlanSlug as "free" | "plus") || "free"
                    );
                    setAllocationModalMode("PENDING_EDIT");
                    setAllocationModalOpen(true);
                  }}
                  className="afab-btn-secondary px-3.5 py-2 text-xs shrink-0 inline-flex items-center gap-1.5"
                >
                  <SlidersHorizontal className="w-3.5 h-3.5" />
                  <span>
                    {isAr
                      ? "تعديل اختيار الشركات القادمة"
                      : "Configure Future Businesses"}
                  </span>
                </button>
              )}
            </div>
          )}

          {/* Payment Failure / 3-Day Grace Period Interface */}
          {isPastDue && (
            <div className="rounded-2xl bg-red-50/80 dark:bg-red-500/10 border border-red-500/30 p-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs">
              <div className="flex items-start gap-3">
                <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
                <div className="space-y-1">
                  <p className="font-bold text-red-700 dark:text-red-300">
                    {isAr
                      ? `فشل تحصيل الدفعة — فترة سماح لمدة 3 أيام (متبقي ${
                          subscription.gracePeriodHoursRemaining ?? 72
                        } ساعة)`
                      : `Payment Failed — 3-Day Grace Period (${
                          subscription.gracePeriodHoursRemaining ?? 72
                        } hours remaining)`}
                  </p>
                  <p className="text-gray-700 dark:text-gray-300">
                    {isAr
                      ? "تستمر صلاحياتك المدفوعة وشركاتك القابلة للتعديل خلال فترة السماح. يرجى تحديث بطاقتك البنكية لتفادي التحول التلقائي للخطة المجانية (شركة واحدة قابلة للتعديل وباقي الشركات قراءة فقط)."
                      : "Your paid features and editable businesses remain unlocked during the 3-day grace period. Please update your payment method now; if payment remains unsuccessful after 3 days, your account downgrades to Free (1 editable business, remaining businesses preserved read-only)."}
                  </p>
                </div>
              </div>
              <button
                type="button"
                disabled={isSubmitting}
                onClick={handleOpenPortal}
                className="px-4 py-2 rounded-xl text-xs font-bold bg-red-600 hover:bg-red-500 text-white shrink-0 inline-flex items-center gap-1.5"
              >
                <CreditCard className="w-3.5 h-3.5" />
                <span>{isAr ? "تحديث وسيلة الدفع" : "Update Payment Method"}</span>
              </button>
            </div>
          )}
        </section>
      )}

      {/* ── Business Allocation Management Section ── */}
      {allocation && ownedBusinesses.length > 0 && (
        <section className="afab-card p-6 space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa] flex items-center justify-center shrink-0">
                <Building2 className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                  {isAr
                    ? "تخصيص الشركات (المفتوحة مقابل المقفلة)"
                    : "Business Allocation (Active vs. Locked)"}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {isAr
                    ? `باقتك الحالية (${allocation.currentPlanName}) تتيح فتح حتى ${allocation.editableLimit} شركات نشطة. لديك حالياً ${allocation.editableCount} مفتوحة و ${allocation.readOnlyCount} مقفلة (بياناتها محفوظة).`
                    : `Your ${allocation.currentPlanName} plan unlocks up to ${allocation.editableLimit} active business(es). Currently ${allocation.editableCount} unlocked and ${allocation.readOnlyCount} locked (data safely saved).`}
                </p>
              </div>
            </div>

            {ownedBusinesses.length > 1 && (
              <button
                type="button"
                onClick={() => {
                  setAllocationModalMode("MANAGE");
                  setAllocationModalOpen(true);
                }}
                className="afab-btn-secondary px-4 py-2 text-xs inline-flex items-center gap-1.5 shrink-0"
              >
                <SlidersHorizontal className="w-3.5 h-3.5" />
                <span>
                  {isAr
                    ? "تغيير الشركات القابلة للتعديل"
                    : "Change Editable Businesses"}
                </span>
              </button>
            )}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {ownedBusinesses.map((biz) => (
              <div
                key={biz.id}
                className={`p-3.5 rounded-2xl border flex items-center justify-between gap-3 ${
                  biz.editable
                    ? "bg-white dark:bg-[#080c18] border-gray-200 dark:border-gray-800"
                    : "bg-amber-50/40 dark:bg-amber-500/[0.04] border-amber-500/25"
                }`}
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <div className="h-9 w-9 rounded-xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center shrink-0 overflow-hidden">
                    {biz.logoUrl ? (
                      <img
                        src={biz.logoUrl}
                        alt={biz.name}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <Building2 className="w-4 h-4 text-[#7c3aed] dark:text-[#a78bfa]" />
                    )}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-1.5">
                      <p className="text-xs font-bold text-gray-900 dark:text-white truncate">
                        {biz.name}
                      </p>
                      {biz.primary && (
                        <span className="px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-purple-500/10 text-[#7c3aed] dark:text-[#a78bfa]">
                          {isAr ? "رئيسية" : "Primary"}
                        </span>
                      )}
                    </div>
                    <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate">
                      {biz.currency}
                      {biz.industry ? ` • ${biz.industry}` : ""}
                    </p>
                  </div>
                </div>

                {biz.editable ? (
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shrink-0">
                    <Check className="w-3 h-3" />
                    {isAr ? "نشطة ومفتوحة" : "Active"}
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-semibold bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20 shrink-0">
                    <Lock className="w-2.5 h-2.5" />
                    {isAr ? "مقفلة (محفوظة)" : "Locked"}
                  </span>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ── Billing Toggle, Plus Trial Alert & Plan Cards (shown on Free plan or when toggled) ── */}
      {shouldShowPlanCards && (
        <div ref={planCardsSectionRef} className="space-y-6">
          <div className="flex flex-col items-center justify-center space-y-4">
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

        {/* 7-day free trial banner (EXCLUSIVELY for Plus) */}
        {isTrialActive ? (
          <div className="flex flex-wrap items-center justify-center gap-2.5 text-xs text-white bg-gradient-to-r from-purple-600 to-indigo-600 border border-purple-400/40 px-5 py-2.5 rounded-2xl shadow-md shadow-purple-600/20">
            <Clock className="w-4 h-4 text-amber-300 animate-pulse shrink-0" />
            <span>
              <strong>
                {isAr
                  ? `أنت حالياً في الفترة التجريبية المجانية (7 أيام) لباقة ${subscription?.planName}.`
                  : `You are currently on a 7-day free trial of ${subscription?.planName}.`}
              </strong>{" "}
              <span className="bg-white/20 px-2 py-0.5 rounded-full font-bold">
                {isAr
                  ? `متبقي ${subscription?.trialDaysRemaining ?? 7} أيام`
                  : `${subscription?.trialDaysRemaining ?? 7} days remaining`}
              </span>
            </span>
          </div>
        ) : isPlusTrialEligible ? (
          <div className="flex flex-wrap items-center justify-center gap-2 text-xs text-gray-700 dark:text-gray-300 bg-purple-50 dark:bg-purple-500/10 border border-purple-200 dark:border-purple-500/20 px-4 py-2 rounded-xl shadow-sm">
            <Gift className="w-4 h-4 text-[#7c3aed] dark:text-[#a78bfa] shrink-0" />
            <span>
              <strong className="text-[#7c3aed] dark:text-[#a78bfa] font-semibold underline underline-offset-2">
                {isAr
                  ? "تجربة مجانية لمدة 7 أيام متاحة حصرياً على باقة Plus."
                  : "7-day free trial available exclusively on the Plus plan."}
              </strong>{" "}
              {isAr
                ? "يمكنك الإلغاء في أي وقت قبل انتهاء التجربة دون أي رسوم."
                : "Cancel anytime during the trial with zero charge."}
            </span>
          </div>
        ) : null}
      </div>

      {/* ── Pricing Cards Grid ── */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-stretch pt-2">
        {plans.map((plan) => {
          const isPlus = plan.id === "plus";
          const isPro = plan.id === "pro";
          const isCurrent = activePlan === plan.id;
          const price =
            billingPeriod === "monthly" ? plan.priceMonthly : plan.priceYearly;
          const currentRank = tierRank(activePlan);
          const planRank = tierRank(plan.id);
          const isDowngrade = planRank < currentRank;
          const isUpgrade = planRank > currentRank;

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
              {isPlus && (
                <div className="absolute -top-3.5 inset-x-0 mx-auto w-fit bg-gradient-to-r from-purple-600 to-indigo-600 text-white font-bold text-[10px] px-3.5 py-1 rounded-full border border-purple-400/40 flex items-center gap-1 shadow-md shadow-purple-600/30 whitespace-nowrap">
                  <Sparkles className="w-3 h-3 text-amber-300" />
                  <span>
                    {plan.badge || (isAr ? "الأكثر شيوعاً" : "Most Popular")}
                  </span>
                </div>
              )}

              <div className="relative z-10">
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
                    {plan.id === "pro" && (
                      <Crown className="w-6 h-6 fill-current text-amber-500 dark:text-amber-400" />
                    )}
                  </div>

                  {isCurrent && (
                    <span className="afab-badge afab-badge-success px-2.5 py-1 rounded-full uppercase tracking-wider border border-emerald-500/20">
                      {isAr ? "الخطة الحالية" : "Active"}
                    </span>
                  )}
                </div>

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
                  ) : isDowngrade ? (
                    <button
                      type="button"
                      disabled={isSubmitting}
                      onClick={() =>
                        handleInitiateDowngrade(plan.id as "free" | "plus")
                      }
                      className="afab-btn-secondary w-full mt-5 py-2.5"
                    >
                      {submittingAction === plan.id ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <span>
                          {plan.id === "free"
                            ? isAr
                              ? "التخفيض إلى المجانية (إلغاء التجديد)"
                              : "Downgrade to Free"
                            : isAr
                            ? "التخفيض إلى Plus (اختيار 3 شركات)"
                            : "Downgrade to Plus"}
                        </span>
                      )}
                    </button>
                  ) : isUpgrade && plan.id === "plus" && isPlusTrialEligible ? (
                    <button
                      type="button"
                      disabled={isSubmitting}
                      onClick={() => handleUpgradeOrCheckout("plus")}
                      className="afab-btn-premium w-full mt-5 py-2.5"
                    >
                      {submittingAction === "plus" ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <>
                          <span>
                            {isAr
                              ? "ابدأ التجربة المجانية 7 أيام (Plus)"
                              : "Start 7-Day Free Trial"}
                          </span>
                          <ArrowRight className="w-3.5 h-3.5 rtl:rotate-180" />
                        </>
                      )}
                    </button>
                  ) : (
                    <button
                      type="button"
                      disabled={isSubmitting}
                      onClick={() =>
                        handleUpgradeOrCheckout(plan.id as "plus" | "pro")
                      }
                      className="afab-btn-premium w-full mt-5 py-2.5"
                    >
                      {submittingAction === plan.id ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <>
                          <span>
                            {isAr
                              ? `الترقية إلى ${plan.name}`
                              : `Upgrade to ${plan.name}`}
                          </span>
                          <ArrowRight className="w-3.5 h-3.5 rtl:rotate-180" />
                        </>
                      )}
                    </button>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </section>
        </div>
      )}

      {/* ── Compare Plans Table ── */}
      <section className="afab-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="afab-table border-collapse">
            <thead className="afab-thead normal-case tracking-normal">
              <tr>
                <th className="afab-th py-4 font-bold text-gray-900 dark:text-white text-base w-2/5">
                  {isAr ? "مقارنة الخطط" : "Compare Plans"}
                </th>
                <th className="afab-th py-4 text-center w-1/5">
                  <div className="inline-flex items-center gap-1.5 font-bold text-gray-900 dark:text-white text-sm">
                    <span className="w-5 h-5 rounded-md bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                      <Globe2 className="w-3.5 h-3.5 stroke-[2.5]" />
                    </span>
                    <span>{isAr ? "مجاني" : "Free"}</span>
                  </div>
                </th>
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
                          onMouseEnter={() =>
                            setActiveTooltip(`comp-${row.name}`)
                          }
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

      {/* ── Subscription & Payment History Section ── */}
      {history &&
        (history.subscriptionHistory.length > 0 ||
          history.paymentHistory.length > 0) && (
          <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Subscription Lifecycle History */}
            <div className="afab-card p-6 space-y-4">
              <div className="flex items-center gap-2.5">
                <History className="w-5 h-5 text-[#7c3aed] dark:text-[#a78bfa]" />
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                  {isAr ? "سجل تغييرات الاشتراك" : "Subscription Change History"}
                </h3>
              </div>

              <div className="space-y-2.5 max-h-72 overflow-y-auto custom-scrollbar">
                {history.subscriptionHistory.map((item) => (
                  <div
                    key={item.id}
                    className="p-3 rounded-xl bg-gray-50 dark:bg-[#080c18] border border-gray-200/70 dark:border-gray-800 text-xs space-y-1"
                  >
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-bold text-gray-900 dark:text-white">
                        {item.eventType.replace(/_/g, " ")}
                      </span>
                      <span className="text-[10px] text-gray-400">
                        {formatDate(item.createdAt)}
                      </span>
                    </div>
                    {item.details && (
                      <p className="text-gray-600 dark:text-gray-400">
                        {item.details}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Payment & Invoice History */}
            <div className="afab-card p-6 space-y-4">
              <div className="flex items-center gap-2.5">
                <FileText className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                  {isAr ? "سجل المدفوعات والفواتير" : "Payment & Invoice History"}
                </h3>
              </div>

              {history.paymentHistory.length === 0 ? (
                <p className="text-xs text-gray-500 dark:text-gray-400 py-6 text-center">
                  {isAr
                    ? "لا توجد فواتير مسجلة بعد."
                    : "No invoice payments recorded yet."}
                </p>
              ) : (
                <div className="space-y-2.5 max-h-72 overflow-y-auto custom-scrollbar">
                  {history.paymentHistory.map((pay) => (
                    <div
                      key={pay.id}
                      className="p-3 rounded-xl bg-gray-50 dark:bg-[#080c18] border border-gray-200/70 dark:border-gray-800 text-xs flex items-center justify-between gap-3"
                    >
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-gray-900 dark:text-white">
                            ${(pay.amountCents / 100).toFixed(2)}{" "}
                            {pay.currency}
                          </span>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                              pay.status === "PAID"
                                ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400"
                                : "bg-red-500/10 text-red-600 dark:text-red-400"
                            }`}
                          >
                            {pay.status}
                          </span>
                        </div>
                        <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5">
                          {formatDate(pay.paidAt || pay.failedAt || pay.createdAt)}
                          {pay.failureReason ? ` • ${pay.failureReason}` : ""}
                        </p>
                      </div>

                      {pay.hostedInvoiceUrl && (
                        <a
                          href={pay.hostedInvoiceUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="text-[#7c3aed] dark:text-[#a78bfa] hover:underline inline-flex items-center gap-1 font-semibold"
                        >
                          <span>{isAr ? "الفاتورة" : "Invoice"}</span>
                          <ExternalLink className="w-3 h-3" />
                        </a>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>
        )}

      {/* ── Modals ── */}
      <CancelSubscriptionModal
        open={cancelModalOpen}
        onOpenChange={setCancelModalOpen}
        planName={subscription?.planName || "Plus"}
        isTrial={isTrialActive}
        effectiveEndDate={effectiveEndDateFormatted}
        businesses={ownedBusinesses}
        isSubmitting={submittingAction === "cancel"}
        isAr={isAr}
        onConfirmCancel={handleConfirmCancel}
      />

      <BusinessAllocationModal
        open={allocationModalOpen}
        onOpenChange={setAllocationModalOpen}
        mode={allocationModalMode}
        targetPlanName={
          allocationModalMode === "MANAGE"
            ? allocation?.currentPlanName || subscription?.planName || "Plus"
            : targetDowngradePlan === "plus"
            ? "Plus"
            : isAr
            ? "المجانية"
            : "Free"
        }
        targetPlanSlug={
          allocationModalMode === "MANAGE"
            ? activePlan
            : targetDowngradePlan
        }
        maxAllowed={
          allocationModalMode === "MANAGE"
            ? allocation?.editableLimit ?? subscription?.editableBusinessLimit ?? 1
            : targetDowngradePlan === "plus"
            ? 3
            : 1
        }
        businesses={ownedBusinesses}
        initialSelectedIds={
          allocationModalMode === "PENDING_EDIT"
            ? allocation?.pendingBusinessIds
            : undefined
        }
        isSubmitting={submittingAction === "allocation"}
        isAr={isAr}
        onSubmit={handleAllocationModalSubmit}
      />
    </div>
  );
}
