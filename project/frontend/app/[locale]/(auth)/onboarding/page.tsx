"use client";

import { useState } from "react";
import { 
  Building2, 
  Globe2, 
  Coins, 
  CheckCircle2, 
  ArrowRight, 
  ArrowLeft, 
  Sparkles, 
  AlertCircle,
  Briefcase,
  Clock,
  Calendar
} from "lucide-react";
import { useTranslations, useLocale } from "next-intl";
import { useRouter } from "@/i18n/routing";
import { motion, AnimatePresence } from "framer-motion";
import { BusinessService } from "@/lib/api/business";
import { AuthStore } from "@/lib/auth-store";
import { AfabLoader } from "@/components/ui/afab-loader";
import {
  COUNTRIES,
  INDUSTRIES,
  BUSINESS_TYPES,
  CURRENCIES,
  TIMEZONES,
  MONTHS,
  getLocalizedCountry,
  getLocalizedIndustry,
  getLocalizedBusinessType,
  getLocalizedCurrencyOption,
  getLocalizedTimezone,
  getLocalizedMonth,
} from "@/lib/constants/business-data";

export default function OnboardingPage() {
  const t = useTranslations("Auth");
  const locale = useLocale();
  const isArabic = locale === "ar";
  const router = useRouter();
  const user = AuthStore.getUser();

  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form State (stores standard backend values)
  const [country, setCountry] = useState("United Arab Emirates");
  const [industry, setIndustry] = useState("Technology & Software");
  const [businessType, setBusinessType] = useState("Limited Liability Company (LLC)");
  const [currency, setCurrency] = useState("USD");
  const [timezone, setTimezone] = useState("Asia/Dubai");
  const [fiscalYearStartMonth, setFiscalYearStartMonth] = useState(1);

  const handleNext = () => {
    setError(null);
    if (step === 1) {
      if (!country) return setError(isArabic ? "يرجى اختيار الدولة" : "Please select a country");
      setStep(2);
    } else if (step === 2) {
      if (!currency || !timezone) {
        return setError(
          isArabic ? "يرجى تحديد العملة والمنطقة الزمنية" : "Please configure currency and timezone"
        );
      }
      setStep(3);
    }
  };

  const handleBack = () => {
    setError(null);
    if (step > 1) setStep(step - 1);
  };

  const handleSubmit = async () => {
    if (!user?.businessId) {
      setError(
        isArabic
          ? "لم يتم العثور على ملف الشركة. يرجى تسجيل الدخول مرة أخرى."
          : "No business profile found. Please log in again."
      );
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await BusinessService.update(user.businessId, {
        country,
        currency,
        timezone,
        fiscalYearStartMonth,
        industry,
        businessType,
      });

      // Update cached user onboarding status
      AuthStore.updateUser({ onboardingComplete: true });

      // Redirect to Dashboard after brief success display
      setTimeout(() => {
        router.push("/dashboard");
      }, 1000);
    } catch (err: unknown) {
      const message =
        err instanceof Error
          ? err.message
          : isArabic
            ? "فشل حفظ إعدادات الشركة. يرجى المحاولة مرة أخرى."
            : "Failed to save business settings. Please try again.";

      setError(message);
      setLoading(false);
    }
  };

  const slideVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? (isArabic ? -50 : 50) : (isArabic ? 50 : -50),
      opacity: 0,
    }),
    center: {
      x: 0,
      opacity: 1,
    },
    exit: (direction: number) => ({
      x: direction < 0 ? (isArabic ? -50 : 50) : (isArabic ? 50 : -50),
      opacity: 0,
    }),
  };

  const stepTabText = step === 1 
    ? (t("onboardingStep1Tab") || "Business Info")
    : step === 2 
    ? (t("onboardingStep2Tab") || "Financial Setup")
    : (t("onboardingStep3Tab") || "Review & Complete");

  return (
    <div className="afab-card w-full max-w-[540px] p-5 sm:p-8">
      {/* Step Indicator Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between text-xs font-semibold uppercase tracking-wider text-[var(--primary-hover)] dark:text-[var(--primary)] mb-3">
          <span>{t("onboardingStep", { step }) || `Step ${step} of 3`}</span>
          <span>{stepTabText}</span>
        </div>

        {/* Progress Bar */}
        <div className="h-1.5 w-full rounded-full bg-gray-100 dark:bg-[#080c18] overflow-hidden">
          <motion.div
            className="h-full bg-[var(--primary)]"
            initial={{ width: "33%" }}
            animate={{ width: step === 1 ? "33%" : step === 2 ? "66%" : "100%" }}
            transition={{ duration: 0.3 }}
          />
        </div>
      </div>

      {/* Error Alert */}
      {error && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-6 flex items-center gap-2.5 rounded-xl bg-red-50 p-3.5 text-xs font-medium text-red-700 border border-red-200 dark:bg-red-500/10 dark:border-red-500/20 dark:text-red-400"
        >
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span>{error}</span>
        </motion.div>
      )}

      {/* Steps Container */}
      <div className="relative overflow-hidden min-h-[340px]">
        <AnimatePresence mode="wait" custom={step}>
          {/* STEP 1: Business Info */}
          {step === 1 && (
            <motion.div
              key="step1"
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.3, ease: "easeOut" }}
              className="space-y-5"
            >
              <div>
                <h2 className="text-xl sm:text-2xl font-bold text-gray-900 tracking-tight dark:text-white flex items-center gap-2">
                  <Building2 className="h-6 w-6 text-[var(--primary-hover)] dark:text-[var(--primary)]" />
                  <span>{t("onboardingStep1Title") || "Tell us about your business"}</span>
                </h2>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                  {t("onboardingStep1Subtitle") || "This helps us tailor financial reports and AI insights for you."}
                </p>
              </div>

              {/* Country */}
              <div>
                <label className="afab-label flex items-center gap-1.5">
                  <Globe2 className="h-4 w-4 text-gray-400" />
                  <span>{t("countryLabel") || "Country of Operation"}</span>
                </label>
                <select
                  value={country}
                  onChange={(e) => setCountry(e.target.value)}
                  className="afab-select w-full py-2.5 px-3.5 text-sm"
                >
                  {COUNTRIES.map((c) => (
                    <option key={c.code} value={c.nameEn}>
                      {isArabic ? c.nameAr : c.nameEn}
                    </option>
                  ))}
                </select>
              </div>

              {/* Industry */}
              <div>
                <label className="afab-label flex items-center gap-1.5">
                  <Briefcase className="h-4 w-4 text-gray-400" />
                  <span>{t("industryLabel") || "Industry"}</span>
                </label>
                <select
                  value={industry}
                  onChange={(e) => setIndustry(e.target.value)}
                  className="afab-select w-full py-2.5 px-3.5 text-sm"
                >
                  {INDUSTRIES.map((ind) => (
                    <option key={ind.id} value={ind.nameEn}>
                      {isArabic ? ind.nameAr : ind.nameEn}
                    </option>
                  ))}
                </select>
              </div>

              {/* Business Type */}
              <div>
                <label className="afab-label flex items-center gap-1.5">
                  <Building2 className="h-4 w-4 text-gray-400" />
                  <span>{t("businessTypeLabel") || "Entity Type"}</span>
                </label>
                <select
                  value={businessType}
                  onChange={(e) => setBusinessType(e.target.value)}
                  className="afab-select w-full py-2.5 px-3.5 text-sm"
                >
                  {BUSINESS_TYPES.map((bt) => (
                    <option key={bt.id} value={bt.nameEn}>
                      {isArabic ? bt.nameAr : bt.nameEn}
                    </option>
                  ))}
                </select>
              </div>
            </motion.div>
          )}

          {/* STEP 2: Financial Setup */}
          {step === 2 && (
            <motion.div
              key="step2"
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.3, ease: "easeOut" }}
              className="space-y-5"
            >
              <div>
                <h2 className="text-xl sm:text-2xl font-bold text-gray-900 tracking-tight dark:text-white flex items-center gap-2">
                  <Coins className="h-6 w-6 text-[var(--primary-hover)] dark:text-[var(--primary)]" />
                  <span>{t("onboardingStep2Title") || "Configure your financial preferences"}</span>
                </h2>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                  {t("onboardingStep2Subtitle") || "Set up your accounting currency, timezone, and fiscal calendar."}
                </p>
              </div>

              {/* Currency */}
              <div>
                <label className="afab-label flex items-center gap-1.5">
                  <Coins className="h-4 w-4 text-gray-400" />
                  <span>{t("currencyLabel") || "Main Currency"}</span>
                </label>
                <select
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="afab-select w-full py-2.5 px-3.5 text-sm"
                >
                  {CURRENCIES.map((curr) => (
                    <option key={curr.code} value={curr.code}>
                      {getLocalizedCurrencyOption(curr, locale)}
                    </option>
                  ))}
                </select>
              </div>

              {/* Timezone */}
              <div>
                <label className="afab-label flex items-center gap-1.5">
                  <Clock className="h-4 w-4 text-gray-400" />
                  <span>{t("timezoneLabel") || "Timezone"}</span>
                </label>
                <select
                  value={timezone}
                  onChange={(e) => setTimezone(e.target.value)}
                  className="afab-select w-full py-2.5 px-3.5 text-sm"
                >
                  {TIMEZONES.map((tz) => (
                    <option key={tz.value} value={tz.value}>
                      {isArabic ? tz.labelAr : tz.labelEn}
                    </option>
                  ))}
                </select>
              </div>

              {/* Fiscal Year Start */}
              <div>
                <label className="afab-label flex items-center gap-1.5">
                  <Calendar className="h-4 w-4 text-gray-400" />
                  <span>{t("fiscalYearLabel") || "Fiscal Year Starts In"}</span>
                </label>
                <select
                  value={fiscalYearStartMonth}
                  onChange={(e) => setFiscalYearStartMonth(Number(e.target.value))}
                  className="afab-select w-full py-2.5 px-3.5 text-sm"
                >
                  {MONTHS.map((m) => (
                    <option key={m.value} value={m.value}>
                      {isArabic ? m.nameAr : m.nameEn}
                    </option>
                  ))}
                </select>
              </div>
            </motion.div>
          )}

          {/* STEP 3: Review & Launch */}
          {step === 3 && (
            <motion.div
              key="step3"
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.3, ease: "easeOut" }}
              className="space-y-6 text-center"
            >
              <div>
                <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/25">
                  <Sparkles className="h-7 w-7" />
                </div>
                <h2 className="text-xl sm:text-2xl font-bold text-gray-900 tracking-tight dark:text-white">
                  {t("onboardingStep3Title") || "You're all set to launch!"}
                </h2>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                  {t("onboardingStep3Subtitle") || "Review your business configuration below."}
                </p>
              </div>

              {/* Summary Card */}
              <div className="afab-inset p-5 text-start space-y-3 text-sm">
                <div className="flex justify-between gap-2 py-1 border-b border-gray-200/60 dark:border-gray-800/60">
                  <span className="text-gray-500 dark:text-gray-400">{t("summaryCountry") || "Country"}</span>
                  <span className="font-semibold text-gray-900 dark:text-white text-end">
                    {getLocalizedCountry(country, locale)}
                  </span>
                </div>
                <div className="flex justify-between gap-2 py-1 border-b border-gray-200/60 dark:border-gray-800/60">
                  <span className="text-gray-500 dark:text-gray-400">{t("summaryIndustry") || "Industry"}</span>
                  <span className="font-semibold text-gray-900 dark:text-white text-end">
                    {getLocalizedIndustry(industry, locale)}
                  </span>
                </div>
                <div className="flex justify-between gap-2 py-1 border-b border-gray-200/60 dark:border-gray-800/60">
                  <span className="text-gray-500 dark:text-gray-400">{t("summaryBusinessType") || "Entity Type"}</span>
                  <span className="font-semibold text-gray-900 dark:text-white text-end">
                    {getLocalizedBusinessType(businessType, locale)}
                  </span>
                </div>
                <div className="flex justify-between gap-2 py-1 border-b border-gray-200/60 dark:border-gray-800/60">
                  <span className="text-gray-500 dark:text-gray-400">{t("summaryCurrency") || "Base Currency"}</span>
                  <span className="font-semibold text-gray-900 dark:text-white text-end">{currency}</span>
                </div>
                <div className="flex justify-between gap-2 py-1 border-b border-gray-200/60 dark:border-gray-800/60">
                  <span className="text-gray-500 dark:text-gray-400">{t("summaryTimezone") || "Timezone"}</span>
                  <span className="font-semibold text-gray-900 dark:text-white text-end">
                    {getLocalizedTimezone(timezone, locale)}
                  </span>
                </div>
                <div className="flex justify-between gap-2 py-1">
                  <span className="text-gray-500 dark:text-gray-400">{t("summaryFiscalYear") || "Fiscal Year"}</span>
                  <span className="font-semibold text-gray-900 dark:text-white text-end">
                    {getLocalizedMonth(fiscalYearStartMonth, locale)}
                  </span>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Navigation Controls */}
      <div className="mt-8 flex items-center justify-between gap-4 pt-4 border-t border-gray-100 dark:border-gray-800/60">
        {step > 1 ? (
          <button
            type="button"
            onClick={handleBack}
            disabled={loading}
            className="afab-btn-secondary py-2.5 px-4 text-sm"
          >
            <ArrowLeft className="h-4 w-4 rtl:rotate-180" />
            <span>{t("back") || "Back"}</span>
          </button>
        ) : (
          <div />
        )}

        {step < 3 ? (
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            type="button"
            onClick={handleNext}
            className="afab-btn-primary py-2.5 px-6 text-sm"
          >
            <span>{t("next") || "Continue"}</span>
            <ArrowRight className="h-4 w-4 rtl:rotate-180" />
          </motion.button>
        ) : (
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            type="button"
            onClick={handleSubmit}
            disabled={loading}
            className="afab-btn-primary flex-1 py-3 px-6 text-sm"
          >
            {loading ? (
              <AfabLoader size="xs" />
            ) : (
              <>
                <CheckCircle2 className="h-5 w-5" />
                <span>{t("launchDashboard") || "Launch Dashboard"}</span>
              </>
            )}
          </motion.button>
        )}
      </div>
    </div>
  );
}
