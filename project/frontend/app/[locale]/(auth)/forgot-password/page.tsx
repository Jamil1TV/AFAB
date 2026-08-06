"use client";

import { useState } from "react";
import { Mail, ArrowLeft, ArrowRight, CheckCircle2 } from "lucide-react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { motion, AnimatePresence } from "framer-motion";
import { AuthService } from "@/lib/api/auth";
import { ApiError } from "@/lib/api/client";
import { AfabLoader } from "@/components/ui/afab-loader";
import { toast } from "sonner";

export default function ForgotPasswordPage() {
  const t = useTranslations("Auth");

  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [emailError, setEmailError] = useState<string | null>(null);

  const validateEmail = (value: string): boolean => {
    if (!value.trim()) {
      setEmailError(t("forgotPasswordEmailRequired"));
      return false;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value)) {
      setEmailError(t("forgotPasswordEmailInvalid"));
      return false;
    }
    setEmailError(null);
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateEmail(email)) return;

    setLoading(true);

    try {
      await AuthService.forgotPassword({ email });
      setSent(true);
    } catch (err: unknown) {
      if (err instanceof ApiError) {
        if (err.code === "RATE_LIMITED") {
          toast.error(t("errorRateLimited"), { duration: 4000 });
        } else if (err.code === "NETWORK_ERROR") {
          toast.error(t("errorNetworkFailure"), { duration: 4000 });
        } else {
          toast.error(err.message, { duration: 4000 });
        }
      } else {
        toast.error(t("errorServerFailure"), { duration: 4000 });
      }
    } finally {
      setLoading(false);
    }
  };

  // Animation Variants
  const containerVariants = {
    hidden: { opacity: 0, scale: 0.98 },
    visible: {
      opacity: 1,
      scale: 1,
      transition: {
        duration: 0.4,
        ease: "easeOut" as const,
        staggerChildren: 0.08,
        delayChildren: 0.1,
      },
    },
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 15 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { type: "spring" as const, stiffness: 300, damping: 24 },
    },
  };

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]"
    >
      {/* Back to Login */}
      <motion.div variants={itemVariants} className="mb-6">
        <Link
          href="/login"
          className="inline-flex items-center gap-2 text-[13px] font-medium text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 transition-colors"
        >
          <ArrowLeft className="h-4 w-4 rtl:rotate-180" />
          {t("backToLogin")}
        </Link>
      </motion.div>

      <AnimatePresence mode="wait">
        {!sent ? (
          <motion.div
            key="form"
            initial={{ opacity: 0, x: 0 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
          >
            {/* Title */}
            <motion.div variants={itemVariants} className="mb-6">
              <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#7c3aed]/10 dark:bg-[#8b5cf6]/10">
                <Mail className="h-7 w-7 text-[#7c3aed] dark:text-[#8b5cf6]" />
              </div>
              <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white">
                {t("forgotPasswordTitle")}
              </h2>
              <p className="mt-1 text-[14px] text-gray-500 dark:text-gray-400">
                {t("forgotPasswordSubtitle")}
              </p>
            </motion.div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4" noValidate>
              <motion.div variants={itemVariants}>
                <label
                  htmlFor="forgot-email"
                  className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300"
                >
                  {t("email")}
                </label>
                <div className="relative group">
                  <Mail className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
                  <input
                    id="forgot-email"
                    type="email"
                    placeholder={t("emailPlaceholder")}
                    value={email}
                    onChange={(e) => {
                      setEmail(e.target.value);
                      if (emailError) validateEmail(e.target.value);
                    }}
                    onBlur={() => {
                      if (email) validateEmail(email);
                    }}
                    required
                    disabled={loading}
                    autoComplete="email"
                    aria-invalid={!!emailError}
                    aria-describedby={emailError ? "forgot-email-error" : undefined}
                    className={`w-full rounded-[14px] border bg-gray-50/50 py-[12px] pl-11 pr-4 text-[14px] text-gray-900 outline-none transition-all focus:bg-white focus:ring-4 dark:bg-[#111522]/50 dark:text-white rtl:pl-4 rtl:pr-11 disabled:opacity-60 ${
                      emailError
                        ? "border-red-400 focus:border-red-500 focus:ring-red-500/10 dark:border-red-500/50 dark:focus:border-red-500 dark:focus:ring-red-500/10"
                        : "border-gray-200 focus:border-[#7c3aed] focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                    }`}
                  />
                </div>
                {emailError && (
                  <motion.p
                    id="forgot-email-error"
                    initial={{ opacity: 0, y: -4 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="mt-1.5 text-[12px] text-red-500 dark:text-red-400"
                    role="alert"
                  >
                    {emailError}
                  </motion.p>
                )}
              </motion.div>

              <motion.div variants={itemVariants} className="pt-1">
                <motion.button
                  whileHover={{ scale: 1.015 }}
                  whileTap={{ scale: 0.985 }}
                  type="submit"
                  disabled={loading}
                  id="forgot-submit"
                  className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[14px] bg-[#7c3aed] py-[12px] text-[15px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] hover:shadow-[#7c3aed]/40 dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed] dark:shadow-[#8b5cf6]/10 dark:hover:shadow-[#8b5cf6]/30 disabled:opacity-70"
                >
                  {loading ? (
                    <AfabLoader size="xs" />
                  ) : (
                    <>
                      <span>{t("sendResetLink")}</span>
                      <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1 rtl:rotate-180 rtl:group-hover:-translate-x-1" />
                    </>
                  )}
                </motion.button>
              </motion.div>
            </form>
          </motion.div>
        ) : (
          <motion.div
            key="success"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4, ease: "easeOut" }}
            className="text-center"
          >
            {/* Success State */}
            <div className="mb-5 flex justify-center">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", stiffness: 200, damping: 15, delay: 0.1 }}
                className="flex h-16 w-16 items-center justify-center rounded-full bg-emerald-100 dark:bg-emerald-500/15"
              >
                <CheckCircle2 className="h-8 w-8 text-emerald-600 dark:text-emerald-400" />
              </motion.div>
            </div>

            <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white mb-2">
              {t("resetEmailSent")}
            </h2>
            <p className="text-[14px] text-gray-500 dark:text-gray-400 mb-1">
              {t("resetEmailSentSubtitle")}
            </p>
            <p className="text-[14px] font-medium text-gray-700 dark:text-gray-300 mb-8">
              {email}
            </p>

            <Link
              href="/login"
              className="inline-flex items-center gap-2 text-[14px] font-semibold text-[#7c3aed] hover:underline dark:text-[#8b5cf6] transition-all"
            >
              <ArrowLeft className="h-4 w-4 rtl:rotate-180" />
              {t("backToLogin")}
            </Link>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
