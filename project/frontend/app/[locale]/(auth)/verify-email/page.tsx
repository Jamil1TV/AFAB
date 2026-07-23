"use client";

import { useState, useRef, useEffect } from "react";
import { MailCheck, ArrowRight, Loader2, AlertCircle, RotateCw } from "lucide-react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/routing";
import { motion } from "framer-motion";
import { AuthService } from "@/lib/api/auth";
import { AuthStore } from "@/lib/auth-store";
import { AfabLoader } from "@/components/ui/afab-loader";

export default function VerifyEmailPage() {
  const t = useTranslations("Auth");
  const router = useRouter();

  const [otp, setOtp] = useState<string[]>(["", "", "", "", "", ""]);
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [countdown, setCountdown] = useState(60);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
  const user = AuthStore.getUser();

  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (countdown > 0) {
      timer = setTimeout(() => setCountdown(countdown - 1), 1000);
    }
    return () => clearTimeout(timer);
  }, [countdown]);

  const handleChange = (index: number, value: string) => {
    if (!/^\d*$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value.slice(-1);
    setOtp(newOtp);
    setError(null);

    // Auto-advance to next input
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData("text").trim().slice(0, 6);
    if (/^\d{6}$/.test(pastedData)) {
      const digits = pastedData.split("");
      setOtp(digits);
      inputRefs.current[5]?.focus();
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const code = otp.join("");
    if (code.length < 6) {
      setError(t("verifyCodeIncomplete") || "Please enter the full 6-digit code.");
      return;
    }

    if (!user?.email) {
      setError(t("noEmailFound") || "Session invalid. Please sign up or log in again.");
      return;
    }

    setError(null);
    setLoading(true);

    try {
      await AuthService.verifyEmail(user.email, code);
      // Redirect to onboarding
      router.push("/onboarding");
    } catch (err: any) {
      if (err.message && err.message.toLowerCase().includes("already verified")) {
        AuthStore.updateUser({ emailVerified: true });
        router.push("/onboarding");
      } else {
        setError(err.message || t("verifyFailed") || "Invalid verification code.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    if (countdown > 0 || !user?.email) return;
    setResending(true);
    setError(null);
    setSuccessMsg(null);

    try {
      await AuthService.resendVerification(user.email);
      setSuccessMsg(t("codeResent") || "Verification code sent! Check your inbox.");
      setCountdown(60);
    } catch (err: any) {
      setError(err.message || t("resendFailed") || "Failed to resend code.");
    } finally {
      setResending(false);
    }
  };

  // Animation Variants
  const containerVariants = {
    hidden: { opacity: 0, scale: 0.98 },
    visible: {
      opacity: 1,
      scale: 1,
      transition: { duration: 0.4, ease: "easeOut" as const },
    },
  };

  return (
    <motion.div 
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-6 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)] text-center"
    >
      {/* Icon */}
      <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-full bg-[#7c3aed]/10 text-[#7c3aed] dark:bg-[#8b5cf6]/20 dark:text-[#8b5cf6]">
        <MailCheck className="h-8 w-8" />
      </div>

      {/* Header */}
      <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white">
        {t("verifyEmailTitle") || "Verify your email"}
      </h2>
      <p className="mt-2 text-[14px] text-gray-500 dark:text-gray-400 leading-relaxed">
        {t("verifyEmailSubtitle") || "We sent a 6-digit code to"}{" "}
        <span className="font-semibold text-gray-800 dark:text-gray-200">{user?.email || "your email"}</span>
      </p>

      {/* Error & Success Alerts */}
      {error && (
        <motion.div 
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-4 flex items-center justify-center gap-2 rounded-[12px] bg-red-50 p-3 text-[13px] font-medium text-red-600 border border-red-200/60 dark:bg-red-950/30 dark:border-red-800/40 dark:text-red-400"
        >
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span>{error}</span>
        </motion.div>
      )}

      {successMsg && (
        <motion.div 
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-4 rounded-[12px] bg-green-50 p-3 text-[13px] font-medium text-green-600 border border-green-200/60 dark:bg-green-950/30 dark:border-green-800/40 dark:text-green-400"
        >
          {successMsg}
        </motion.div>
      )}

      {/* OTP Inputs */}
      <form onSubmit={handleSubmit} className="mt-6 space-y-6">
        <div className="flex justify-center gap-2.5 sm:gap-3" onPaste={handlePaste}>
          {otp.map((digit, index) => (
            <input
              key={index}
              ref={(el) => { inputRefs.current[index] = el; }}
              type="text"
              inputMode="numeric"
              maxLength={1}
              value={digit}
              onChange={(e) => handleChange(index, e.target.value)}
              onKeyDown={(e) => handleKeyDown(index, e)}
              className="h-12 w-11 sm:h-14 sm:w-12 rounded-[14px] border border-gray-200 bg-gray-50/50 text-center text-xl font-bold text-gray-900 outline-none transition-all focus:border-[#7c3aed] focus:bg-white focus:ring-4 focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
            />
          ))}
        </div>

        {/* Submit Button */}
        <motion.button
          whileHover={{ scale: 1.015 }}
          whileTap={{ scale: 0.985 }}
          type="submit"
          disabled={loading || otp.join("").length < 6}
          className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[14px] bg-[#7c3aed] py-[12px] text-[15px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed] disabled:opacity-50"
        >
          {loading ? (
            <AfabLoader size="xs" />
          ) : (
            <>
              <span>{t("verifyButton") || "Verify Email"}</span>
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1 rtl:rotate-180 rtl:group-hover:-translate-x-1" />
            </>
          )}
        </motion.button>
      </form>

      {/* Resend Code */}
      <div className="mt-6 text-[13px] text-gray-500 dark:text-gray-400">
        <span>{t("didntReceiveCode") || "Didn't receive the code?"} </span>
        <button
          onClick={handleResend}
          disabled={countdown > 0 || resending}
          className="font-semibold text-[#7c3aed] hover:underline dark:text-[#8b5cf6] disabled:opacity-50 disabled:no-underline cursor-pointer inline-flex items-center gap-1"
        >
          {resending && <RotateCw className="h-3.5 w-3.5 animate-spin" />}
          {countdown > 0
            ? `${t("resendIn") || "Resend in"} ${countdown}s`
            : t("resendCode") || "Resend Code"}
        </button>
      </div>
    </motion.div>
  );
}
