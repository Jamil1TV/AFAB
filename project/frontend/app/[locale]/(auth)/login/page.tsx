"use client";

import { useState } from "react";
import { Mail, Lock, Eye, EyeOff, ArrowRight, Loader2, AlertCircle } from "lucide-react";
import { useTranslations } from "next-intl";
import { Link, useRouter } from "@/i18n/routing";
import { motion } from "framer-motion";
import { AuthService } from "@/lib/api/auth";
import { AfabLoader } from "@/components/ui/afab-loader";

export default function LoginPage() {
  const t = useTranslations("Auth");
  const router = useRouter();

  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const res = await AuthService.login({ email, password });
      
      if (!res.user.emailVerified) {
        router.push("/verify-email");
      } else if (res.user.onboardingComplete) {
        router.push("/dashboard");
      } else {
        router.push("/onboarding");
      }
    } catch (err: any) {
      setError(err.message || t("loginFailed") || "Invalid credentials");
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
      transition: { type: "spring" as const, stiffness: 300, damping: 24 } 
    },
  };

  return (
    <motion.div 
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]"
    >
      {/* Tab Switcher */}
      <motion.div variants={itemVariants} className="mb-8 relative flex justify-center">
        <div className="absolute bottom-0 w-full h-[1px] bg-gray-200 dark:bg-[#2A3042]"></div>
        <div className="flex w-full max-w-[280px]">
          <div className="relative w-1/2 pb-3 text-center text-[15px] font-semibold text-[#7c3aed] dark:text-[#8b5cf6]">
            {t("loginTab")}
            <motion.div 
              layoutId="activeTab" 
              className="absolute bottom-0 left-0 w-full h-[2px] bg-[#7c3aed] dark:bg-[#8b5cf6] z-10" 
            />
          </div>
          <Link
            href="/signup"
            className="w-1/2 pb-3 text-center text-[15px] font-medium text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 transition-colors relative z-10"
          >
            {t("signupTab")}
          </Link>
        </div>
      </motion.div>

      {/* Title */}
      <motion.div variants={itemVariants} className="mb-6">
        <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white">{t("loginTitle")}</h2>
        <p className="mt-1 text-[14px] text-gray-500 dark:text-gray-400">{t("loginSubtitle")}</p>
      </motion.div>

      {/* Error Alert */}
      {error && (
        <motion.div 
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-5 flex items-center gap-2.5 rounded-[12px] bg-red-50 p-3.5 text-[13px] font-medium text-red-600 border border-red-200/60 dark:bg-red-950/30 dark:border-red-800/40 dark:text-red-400"
        >
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span>{error}</span>
        </motion.div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-4">
        <motion.div variants={itemVariants}>
          <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300">
            {t("email")}
          </label>
          <div className="relative group">
            <Mail className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
            <input
              type="email"
              placeholder={t("emailPlaceholder")}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
              className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] pl-11 pr-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10 rtl:pl-4 rtl:pr-11 disabled:opacity-60"
            />
          </div>
        </motion.div>

        <motion.div variants={itemVariants}>
          <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300">
            {t("password")}
          </label>
          <div className="relative group">
            <Lock className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
            <input
              type={showPassword ? "text" : "password"}
              placeholder={t("passwordPlaceholder")}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={loading}
              className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] pl-11 pr-[44px] text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10 rtl:pl-[44px] rtl:pr-11 disabled:opacity-60"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors z-10 rtl:left-4 rtl:right-auto"
            >
              {showPassword ? <EyeOff className="h-[18px] w-[18px]" /> : <Eye className="h-[18px] w-[18px]" />}
            </button>
          </div>
        </motion.div>

        <motion.div variants={itemVariants} className="flex items-center justify-between pt-1">
          <label className="flex items-center gap-2.5 cursor-pointer">
            <div className="relative flex items-center justify-center">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="peer h-[18px] w-[18px] cursor-pointer appearance-none rounded-[4px] border border-gray-300 checked:border-[#7c3aed] checked:bg-[#7c3aed] transition-all dark:border-[#303850] dark:bg-[#111522] dark:checked:border-[#8b5cf6] dark:checked:bg-[#8b5cf6]"
              />
              <svg className="absolute h-3 w-3 text-white opacity-0 peer-checked:opacity-100 pointer-events-none transition-opacity duration-200" viewBox="0 0 14 10" fill="none">
                <path d="M1 5L4.5 8.5L13 1" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
            <span className="text-[13px] font-medium text-gray-600 dark:text-gray-400 select-none transition-colors hover:text-gray-900 dark:hover:text-gray-200">
              {t("rememberMe")}
            </span>
          </label>
          <Link href="/forgot-password" className="text-[13px] font-medium text-[#7c3aed] hover:underline dark:text-[#8b5cf6] transition-all">
            {t("forgotPassword")}
          </Link>
        </motion.div>

        <motion.div variants={itemVariants}>
          <motion.button
            whileHover={{ scale: 1.015 }}
            whileTap={{ scale: 0.985 }}
            type="submit"
            disabled={loading}
            className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[14px] bg-[#7c3aed] py-[12px] text-[15px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] hover:shadow-[#7c3aed]/40 dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed] dark:shadow-[#8b5cf6]/10 dark:hover:shadow-[#8b5cf6]/30 disabled:opacity-70"
          >
            {loading ? (
              <AfabLoader size="xs" />
            ) : (
              <>
                <span>{t("loginButton")}</span>
                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1 rtl:rotate-180 rtl:group-hover:-translate-x-1" />
              </>
            )}
          </motion.button>
        </motion.div>
      </form>

      {/* Divider */}
      <motion.div variants={itemVariants} className="relative my-8">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-gray-200 dark:border-[#2A3042]"></div>
        </div>
        <div className="relative flex justify-center text-[12px]">
          <span className="bg-white/80 backdrop-blur-sm px-4 text-gray-400 dark:bg-[#161B2B]/80 dark:text-gray-500 rounded-full">
            {t("orContinueWith")}
          </span>
        </div>
      </motion.div>

      {/* Social Buttons */}
      <motion.div variants={itemVariants} className="space-y-3.5">
        <motion.button 
          whileHover={{ scale: 1.015 }}
          whileTap={{ scale: 0.985 }}
          type="button"
          className="flex w-full items-center justify-center gap-3 rounded-[14px] border border-gray-200 bg-white py-[12px] text-[14px] font-semibold text-gray-700 shadow-sm transition-all hover:bg-gray-50 hover:shadow dark:border-[#2A3042] dark:bg-[#111522]/80 dark:text-gray-300 dark:hover:bg-[#1A2035] dark:hover:shadow-none"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M22.56 12.25C22.56 11.47 22.49 10.72 22.36 10H12V14.26H17.92C17.66 15.63 16.88 16.79 15.7 17.58V20.34H19.26C21.34 18.42 22.56 15.6 22.56 12.25Z" fill="#4285F4"/>
            <path d="M12 23C14.97 23 17.46 22.02 19.26 20.34L15.7 17.58C14.73 18.23 13.46 18.63 12 18.63C9.18 18.63 6.79 16.73 5.92 14.18H2.25V17.03C4.05 20.61 7.72 23 12 23Z" fill="#34A853"/>
            <path d="M5.92 14.18C5.7 13.52 5.57 12.78 5.57 12C5.57 11.22 5.7 10.48 5.92 9.82V6.97H2.25C1.51 8.44 1.08 10.15 1.08 12C1.08 13.85 1.51 15.56 2.25 17.03L5.92 14.18Z" fill="#FBBC05"/>
            <path d="M12 5.38C13.62 5.38 15.06 5.94 16.2 7.03L19.34 3.9C17.45 2.14 14.97 1.08 12 1.08C7.72 1.08 4.05 3.39 2.25 6.97L5.92 9.82C6.79 7.27 9.18 5.38 12 5.38Z" fill="#EA4335"/>
          </svg>
          {t("continueGoogle")}
        </motion.button>
      </motion.div>

      {/* Bottom Link */}
      <motion.p variants={itemVariants} className="mt-8 text-center text-[14px] text-gray-500 dark:text-gray-400">
        {t("noAccount")} <Link href="/signup" className="font-semibold text-[#7c3aed] hover:underline dark:text-[#8b5cf6] transition-all">{t("signupTab")}</Link>
      </motion.p>
    </motion.div>
  );
}
