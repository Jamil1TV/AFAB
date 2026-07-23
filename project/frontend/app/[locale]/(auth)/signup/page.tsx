"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Mail, Lock, Eye, EyeOff, ArrowRight, User, Building } from "lucide-react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { motion } from "framer-motion";

export default function SignupPage() {
  const t = useTranslations("Auth");
  const router = useRouter();

  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [businessName, setBusinessName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    // auth logic
    setTimeout(() => {
      setLoading(false);
      router.push("/dashboard");
    }, 1000);
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
      <motion.div variants={itemVariants} className="mb-6 relative flex justify-center">
        <div className="absolute bottom-0 w-full h-[1px] bg-gray-200 dark:bg-[#2A3042]"></div>
        <div className="flex w-full max-w-[280px]">
          <Link
            href="/login"
            className="w-1/2 pb-3 text-center text-[15px] font-medium text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 transition-colors relative z-10"
          >
            {t("loginTab")}
          </Link>
          <div className="relative w-1/2 pb-3 text-center text-[15px] font-semibold text-[#7c3aed] dark:text-[#8b5cf6]">
            {t("signupTab")}
            <motion.div 
              layoutId="activeTab" 
              className="absolute bottom-0 left-0 w-full h-[2px] bg-[#7c3aed] dark:bg-[#8b5cf6] z-10" 
            />
          </div>
        </div>
      </motion.div>

      {/* Title */}
      <motion.div variants={itemVariants} className="mb-6">
        <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white">{t("signupTitle")}</h2>
        <p className="mt-1 text-[14px] text-gray-500 dark:text-gray-400">{t("signupSubtitle")}</p>
      </motion.div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-4">
        <motion.div variants={itemVariants} className="flex flex-col sm:flex-row gap-4">
          <div className="w-full sm:w-1/2">
            <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300">
              {t("firstName")}
            </label>
            <div className="relative group">
              <User className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
              <input
                type="text"
                placeholder={t("firstNamePlaceholder")}
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] pl-11 pr-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10 rtl:pl-4 rtl:pr-11"
                required
              />
            </div>
          </div>
          <div className="w-full sm:w-1/2">
            <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300">
              {t("lastName")}
            </label>
            <div className="relative group">
              <input
                type="text"
                placeholder={t("lastNamePlaceholder")}
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] px-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
                required
              />
            </div>
          </div>
        </motion.div>

        <motion.div variants={itemVariants}>
          <label className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300">
            {t("businessName")}
          </label>
          <div className="relative group">
            <Building className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
            <input
              type="text"
              placeholder={t("businessNamePlaceholder")}
              value={businessName}
              onChange={(e) => setBusinessName(e.target.value)}
              className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] pl-11 pr-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10 rtl:pl-4 rtl:pr-11"
              required
            />
          </div>
        </motion.div>

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
              className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] pl-11 pr-4 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10 rtl:pl-4 rtl:pr-11"
              required
            />
          </div>
        </motion.div>

        <motion.div variants={itemVariants}>
          <div className="mb-2 flex items-center justify-between">
            <label className="block text-[13px] font-semibold text-gray-700 dark:text-gray-300">
              {t("password")}
            </label>
          </div>
          <div className="relative group">
            <Lock className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
            <input
              type={showPassword ? "text" : "password"}
              placeholder={t("passwordSignupPlaceholder")}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-[14px] border border-gray-200 bg-gray-50/50 py-[12px] pl-11 pr-11 text-[14px] text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10 rtl:pl-11 rtl:pr-11"
              required
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors z-10 rtl:left-4 rtl:right-auto"
            >
              {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
            </button>
          </div>
        </motion.div>

        <motion.div variants={itemVariants}>
          <motion.button
            whileHover={{ scale: 1.015 }}
            whileTap={{ scale: 0.985 }}
            type="submit"
            className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[14px] bg-[#7c3aed] py-[12px] text-[15px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] hover:shadow-[#7c3aed]/40 dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed] dark:shadow-[#8b5cf6]/10 dark:hover:shadow-[#8b5cf6]/30"
          >
            <span>{t("signupButton")}</span>
            <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1 rtl:rotate-180 rtl:group-hover:-translate-x-1" />
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
        {t("hasAccount")} <Link href="/login" className="font-semibold text-[#7c3aed] hover:underline dark:text-[#8b5cf6] transition-all">{t("loginTab")}</Link>
      </motion.p>
    </motion.div>
  );
}
