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
  Loader2, 
  AlertCircle,
  Briefcase,
  Clock,
  Calendar
} from "lucide-react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/routing";
import { motion, AnimatePresence } from "framer-motion";
import { BusinessService } from "@/lib/api/business";
import { AuthStore } from "@/lib/auth-store";
import { AfabLoader } from "@/components/ui/afab-loader";

// Currencies
const CURRENCIES = [
  { code: "USD", symbol: "$", name: "US Dollar" },
  { code: "EUR", symbol: "€", name: "Euro" },
  { code: "AED", symbol: "د.إ", name: "UAE Dirham" },
  { code: "SAR", symbol: "﷼", name: "Saudi Riyal" },
  { code: "GBP", symbol: "£", name: "British Pound" },
  { code: "CAD", symbol: "$", name: "Canadian Dollar" },
  { code: "EGP", symbol: "ج.م", name: "Egyptian Pound" },
  { code: "DZD", symbol: "د.ج", name: "Algerian Dinar" },
  { code: "MAD", symbol: "د.م", name: "Moroccan Dirham" },
  { code: "KWD", symbol: "د.ك", name: "Kuwaiti Dinar" },
  { code: "QAR", symbol: "﷼", name: "Qatari Riyal" },
];

// Countries
const COUNTRIES = [
  { code: "US", name: "United States" },
  { code: "AE", name: "United Arab Emirates" },
  { code: "SA", name: "Saudi Arabia" },
  { code: "GB", name: "United Kingdom" },
  { code: "CA", name: "Canada" },
  { code: "EG", name: "Egypt" },
  { code: "DZ", name: "Algeria" },
  { code: "MA", name: "Morocco" },
  { code: "QA", name: "Qatar" },
  { code: "KW", name: "Kuwait" },
  { code: "BH", name: "Bahrain" },
  { code: "OM", name: "Oman" },
  { code: "JO", name: "Jordan" },
  { code: "LB", name: "Lebanon" },
  { code: "DE", name: "Germany" },
  { code: "FR", name: "France" },
];

// Industries
const INDUSTRIES = [
  "Technology & Software",
  "E-commerce & Retail",
  "Professional Services & Consulting",
  "Financial Services & Fintech",
  "Healthcare & Life Sciences",
  "Real Estate & Construction",
  "Media & Entertainment",
  "Food & Beverage",
  "Manufacturing & Logistics",
  "Education & Non-profit",
  "Other"
];

// Business Types
const BUSINESS_TYPES = [
  "Sole Proprietorship",
  "Limited Liability Company (LLC)",
  "Corporation",
  "Partnership",
  "Freelancer / Individual",
  "Non-Profit"
];

// Timezones
const TIMEZONES = [
  "UTC",
  "Asia/Dubai (GMT+4)",
  "Asia/Riyadh (GMT+3)",
  "Africa/Cairo (GMT+3)",
  "Africa/Algiers (GMT+1)",
  "Europe/London (GMT+0)",
  "Europe/Paris (GMT+1)",
  "America/New_York (GMT-5)",
  "America/Los_Angeles (GMT-8)",
];

const MONTHS = [
  { value: 1, name: "January" },
  { value: 2, name: "February" },
  { value: 3, name: "March" },
  { value: 4, name: "April" },
  { value: 5, name: "May" },
  { value: 6, name: "June" },
  { value: 7, name: "July" },
  { value: 8, name: "August" },
  { value: 9, name: "September" },
  { value: 10, name: "October" },
  { value: 11, name: "November" },
  { value: 12, name: "December" },
];

export default function OnboardingPage() {
  const t = useTranslations("Auth");
  const router = useRouter();
  const user = AuthStore.getUser();

  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form State
  const [country, setCountry] = useState("United Arab Emirates");
  const [industry, setIndustry] = useState("Technology & Software");
  const [businessType, setBusinessType] = useState("Limited Liability Company (LLC)");
  const [currency, setCurrency] = useState("USD");
  const [timezone, setTimezone] = useState("Asia/Dubai (GMT+4)");
  const [fiscalYearStartMonth, setFiscalYearStartMonth] = useState(1);

  const handleNext = () => {
    setError(null);
    if (step === 1) {
      if (!country) return setError("Please select a country");
      setStep(2);
    } else if (step === 2) {
      if (!currency || !timezone) return setError("Please configure currency and timezone");
      setStep(3);
    }
  };

  const handleBack = () => {
    setError(null);
    if (step > 1) setStep(step - 1);
  };

  const handleSubmit = async () => {
    if (!user?.businessId) {
      setError("No business profile found. Please log in again.");
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

      // Redirect to Dashboard after brief success display
      setTimeout(() => {
        router.push("/dashboard");
      }, 1000);
    } catch (err: any) {
      setError(err.message || "Failed to save business settings. Please try again.");
      setLoading(false);
    }
  };

  const slideVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 50 : -50,
      opacity: 0,
    }),
    center: {
      x: 0,
      opacity: 1,
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 50 : -50,
      opacity: 0,
    }),
  };

  return (
    <div className="w-full max-w-[540px] rounded-[28px] bg-white/80 p-6 sm:p-9 shadow-[0_25px_70px_-15px_rgba(0,0,0,0.06)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_25px_70px_-15px_rgba(0,0,0,0.4)]">
      {/* Step Indicator Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between text-xs font-semibold uppercase tracking-wider text-[#7c3aed] dark:text-[#8b5cf6] mb-3">
          <span>{t("onboardingStep") || `Step ${step} of 3`}</span>
          <span>{step === 1 ? "Business Info" : step === 2 ? "Financial Setup" : "Review & Complete"}</span>
        </div>

        {/* Progress Bar */}
        <div className="h-1.5 w-full rounded-full bg-gray-100 dark:bg-[#232A3E] overflow-hidden">
          <motion.div
            className="h-full bg-gradient-to-r from-[#7c3aed] to-[#8b5cf6]"
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
          className="mb-6 flex items-center gap-2.5 rounded-[14px] bg-red-50 p-4 text-[13px] font-medium text-red-600 border border-red-200/60 dark:bg-red-950/30 dark:border-red-800/40 dark:text-red-400"
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
                <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white flex items-center gap-2">
                  <Building2 className="h-6 w-6 text-[#7c3aed] dark:text-[#8b5cf6]" />
                  <span>{t("onboardingStep1Title") || "Tell us about your business"}</span>
                </h2>
                <p className="mt-1 text-[14px] text-gray-500 dark:text-gray-400">
                  {t("onboardingStep1Subtitle") || "This helps us tailor financial reports and AI insights for you."}
                </p>
              </div>

              {/* Country */}
              <div>
                <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                  <Globe2 className="h-4 w-4 text-gray-400" />
                  <span>{t("countryLabel") || "Country of Operation"}</span>
                </label>
                <select
                  value={country}
                  onChange={(e) => setCountry(e.target.value)}
                  className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] px-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                >
                  {COUNTRIES.map((c) => (
                    <option key={c.code} value={c.name} className="dark:bg-[#161B2B]">
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Industry */}
              <div>
                <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                  <Briefcase className="h-4 w-4 text-gray-400" />
                  <span>{t("industryLabel") || "Industry"}</span>
                </label>
                <select
                  value={industry}
                  onChange={(e) => setIndustry(e.target.value)}
                  className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] px-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                >
                  {INDUSTRIES.map((ind) => (
                    <option key={ind} value={ind} className="dark:bg-[#161B2B]">
                      {ind}
                    </option>
                  ))}
                </select>
              </div>

              {/* Business Type */}
              <div>
                <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                  <Building2 className="h-4 w-4 text-gray-400" />
                  <span>{t("businessTypeLabel") || "Entity Type"}</span>
                </label>
                <select
                  value={businessType}
                  onChange={(e) => setBusinessType(e.target.value)}
                  className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] px-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                >
                  {BUSINESS_TYPES.map((bt) => (
                    <option key={bt} value={bt} className="dark:bg-[#161B2B]">
                      {bt}
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
                <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white flex items-center gap-2">
                  <Coins className="h-6 w-6 text-[#7c3aed] dark:text-[#8b5cf6]" />
                  <span>{t("onboardingStep2Title") || "Configure your financial preferences"}</span>
                </h2>
                <p className="mt-1 text-[14px] text-gray-500 dark:text-gray-400">
                  {t("onboardingStep2Subtitle") || "Set up your accounting currency, timezone, and fiscal calendar."}
                </p>
              </div>

              {/* Currency */}
              <div>
                <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                  <Coins className="h-4 w-4 text-gray-400" />
                  <span>{t("currencyLabel") || "Main Currency"}</span>
                </label>
                <select
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] px-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                >
                  {CURRENCIES.map((curr) => (
                    <option key={curr.code} value={curr.code} className="dark:bg-[#161B2B]">
                      {curr.code} ({curr.symbol}) — {curr.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Timezone */}
              <div>
                <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                  <Clock className="h-4 w-4 text-gray-400" />
                  <span>{t("timezoneLabel") || "Timezone"}</span>
                </label>
                <select
                  value={timezone}
                  onChange={(e) => setTimezone(e.target.value)}
                  className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] px-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                >
                  {TIMEZONES.map((tz) => (
                    <option key={tz} value={tz} className="dark:bg-[#161B2B]">
                      {tz}
                    </option>
                  ))}
                </select>
              </div>

              {/* Fiscal Year Start */}
              <div>
                <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                  <Calendar className="h-4 w-4 text-gray-400" />
                  <span>{t("fiscalYearLabel") || "Fiscal Year Starts In"}</span>
                </label>
                <select
                  value={fiscalYearStartMonth}
                  onChange={(e) => setFiscalYearStartMonth(Number(e.target.value))}
                  className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] px-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                >
                  {MONTHS.map((m) => (
                    <option key={m.value} value={m.value} className="dark:bg-[#161B2B]">
                      {m.name}
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
                <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-tr from-[#7c3aed] to-[#8b5cf6] text-white shadow-lg shadow-[#7c3aed]/25">
                  <Sparkles className="h-7 w-7" />
                </div>
                <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white">
                  {t("onboardingStep3Title") || "You're all set to launch!"}
                </h2>
                <p className="mt-1 text-[14px] text-gray-500 dark:text-gray-400">
                  {t("onboardingStep3Subtitle") || "Review your business configuration below."}
                </p>
              </div>

              {/* Summary Card */}
              <div className="rounded-[18px] border border-gray-200/80 bg-gray-50/60 p-5 text-left dark:border-[#232A3E] dark:bg-[#111522]/60 space-y-3 text-[14px]">
                <div className="flex justify-between py-1 border-b border-gray-200/60 dark:border-[#232A3E]">
                  <span className="text-gray-500 dark:text-gray-400">Country</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{country}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-gray-200/60 dark:border-[#232A3E]">
                  <span className="text-gray-500 dark:text-gray-400">Industry</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{industry}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-gray-200/60 dark:border-[#232A3E]">
                  <span className="text-gray-500 dark:text-gray-400">Entity Type</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{businessType}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-gray-200/60 dark:border-[#232A3E]">
                  <span className="text-gray-500 dark:text-gray-400">Base Currency</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{currency}</span>
                </div>
                <div className="flex justify-between py-1">
                  <span className="text-gray-500 dark:text-gray-400">Timezone</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{timezone}</span>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Navigation Controls */}
      <div className="mt-8 flex items-center justify-between gap-4 pt-4 border-t border-gray-100 dark:border-[#232A3E]">
        {step > 1 ? (
          <button
            type="button"
            onClick={handleBack}
            disabled={loading}
            className="flex items-center gap-2 rounded-[14px] border border-gray-200 bg-white py-2.5 px-4 text-[14px] font-semibold text-gray-700 transition-all hover:bg-gray-50 dark:border-[#2A3042] dark:bg-[#111522] dark:text-gray-300 dark:hover:bg-[#1A2035]"
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
            className="flex items-center gap-2 rounded-[14px] bg-[#7c3aed] py-2.5 px-6 text-[14px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed]"
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
            className="flex flex-1 items-center justify-center gap-2 rounded-[14px] bg-gradient-to-r from-[#7c3aed] to-[#8b5cf6] py-3 px-6 text-[15px] font-bold text-white shadow-lg shadow-[#7c3aed]/25 transition-all hover:shadow-[#7c3aed]/40 disabled:opacity-70"
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
