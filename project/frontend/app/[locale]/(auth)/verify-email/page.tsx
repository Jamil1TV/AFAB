"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import { useSearchParams } from "next/navigation";
import { 
  MailCheck, 
  ArrowRight, 
  AlertCircle, 
  RotateCw, 
  CheckCircle2, 
  XCircle, 
  Sparkles,
  Zap
} from "lucide-react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/routing";
import { motion, AnimatePresence } from "framer-motion";
import { AuthService } from "@/lib/api/auth";
import { AuthStore } from "@/lib/auth-store";
import { AfabLoader } from "@/components/ui/afab-loader";

export default function VerifyEmailPage() {
  const t = useTranslations("Auth");
  const router = useRouter();
  const searchParams = useSearchParams();

  const [devOtp, setDevOtp] = useState<string | null>(searchParams.get("devOtp"));
  const [otp, setOtp] = useState<string[]>(["", "", "", "", "", ""]);
  const [focusedIndex, setFocusedIndex] = useState<number | null>(0);
  const [status, setStatus] = useState<"idle" | "loading" | "error" | "success">("idle");
  const [resending, setResending] = useState(false);
  const [countdown, setCountdown] = useState(60);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [shakeKey, setShakeKey] = useState(0);

  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
  const user = AuthStore.getUser();

  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (countdown > 0) {
      timer = setTimeout(() => setCountdown(countdown - 1), 1000);
    }
    return () => clearTimeout(timer);
  }, [countdown]);

  // Focus the first empty input on mount
  useEffect(() => {
    inputRefs.current[0]?.focus();
  }, []);

  const executeVerification = useCallback(async (code: string) => {
    if (code.length < 6 || status === "loading" || status === "success") return;

    if (!user?.email) {
      setError(t("noEmailFound") || "Session invalid. Please sign up or log in again.");
      return;
    }

    setError(null);
    setStatus("loading");

    try {
      await AuthService.verifyEmail(user.email, code);
      setStatus("success");
      setSuccessMsg(t("verifySuccess") || "Email verified successfully! Redirecting...");
      setTimeout(() => {
        router.push("/onboarding");
      }, 1500);
    } catch (err: any) {
      if (err.message && err.message.toLowerCase().includes("already verified")) {
        AuthStore.updateUser({ emailVerified: true });
        setStatus("success");
        setSuccessMsg(t("verifySuccess") || "Email verified! Redirecting...");
        setTimeout(() => {
          router.push("/onboarding");
        }, 1200);
      } else {
        setStatus("error");
        setError(err.message || t("verifyFailed") || "Invalid verification code.");
        setShakeKey((prev) => prev + 1);
        setTimeout(() => {
          setStatus("idle");
        }, 2200);
      }
    }
  }, [status, user?.email, router, t]);

  const handleChange = (index: number, value: string) => {
    if (!/^\d*$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value.slice(-1);
    setOtp(newOtp);
    setError(null);
    if (status === "error") setStatus("idle");

    // Auto-advance to next input
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
      setFocusedIndex(index + 1);
    }

    // Auto-submit when all 6 digits entered
    const completeCode = newOtp.join("");
    if (completeCode.length === 6 && !newOtp.includes("")) {
      executeVerification(completeCode);
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
      setFocusedIndex(index - 1);
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData("text").trim().slice(0, 6);
    if (/^\d{6}$/.test(pastedData)) {
      const digits = pastedData.split("");
      setOtp(digits);
      inputRefs.current[5]?.focus();
      executeVerification(pastedData);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const code = otp.join("");
    if (code.length < 6) {
      setError(t("verifyCodeIncomplete") || "Please enter the full 6-digit code.");
      setShakeKey((prev) => prev + 1);
      return;
    }
    executeVerification(code);
  };

  // Staggered animated auto-fill
  const handleAutoFill = (code: string) => {
    const digits = code.split("").slice(0, 6);
    digits.forEach((digit, idx) => {
      setTimeout(() => {
        setOtp((prev) => {
          const next = [...prev];
          next[idx] = digit;
          return next;
        });
        inputRefs.current[idx]?.focus();
        setFocusedIndex(idx);

        if (idx === digits.length - 1) {
          executeVerification(code);
        }
      }, idx * 70);
    });
  };

  const handleResend = async () => {
    if (countdown > 0 || !user?.email || resending) return;
    setResending(true);
    setError(null);
    setSuccessMsg(null);

    try {
      const res = await AuthService.resendVerification(user.email);
      setSuccessMsg(t("codeResent") || "Verification code sent! Check your inbox.");
      if (res?.devOtp) {
        setDevOtp(res.devOtp);
      }
      setCountdown(60);
    } catch (err: any) {
      setError(err.message || t("resendFailed") || "Failed to resend code.");
    } finally {
      setResending(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.45, ease: "easeOut" }}
      className="relative w-full max-w-[440px] overflow-hidden rounded-[26px] bg-white/80 p-6 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.06)] backdrop-blur-xl dark:bg-[#161B2B]/85 dark:border dark:border-[#232A3E]/60 dark:shadow-[0_25px_65px_-15px_rgba(0,0,0,0.4)] text-center"
    >
      {/* ── Celebration Confetti Particles on Success ── */}
      {status === "success" && (
        <div className="pointer-events-none absolute inset-0 z-50 overflow-hidden">
          {Array.from({ length: 28 }).map((_, i) => {
            const angle = (i / 28) * 360;
            const distance = 90 + (i % 5) * 28;
            const colors = ["#8b5cf6", "#10b981", "#06b6d4", "#f59e0b", "#ec4899", "#3b82f6"];
            return (
              <motion.div
                key={i}
                initial={{ opacity: 1, scale: 0, x: 0, y: 0 }}
                animate={{
                  opacity: [1, 1, 0],
                  scale: [0, 1.3, 0.3],
                  x: Math.cos((angle * Math.PI) / 180) * distance,
                  y: Math.sin((angle * Math.PI) / 180) * distance,
                }}
                transition={{
                  duration: 1.1,
                  ease: [0.22, 1, 0.36, 1],
                  delay: (i % 7) * 0.02,
                }}
                className="absolute top-1/3 left-1/2 -ml-1 -mt-1 h-2 w-2 rounded-full"
                style={{ backgroundColor: colors[i % colors.length] }}
              />
            );
          })}
        </div>
      )}

      {/* ── Top Icon Badge (Animated morphing between States) ── */}
      <motion.div
        animate={
          status === "success"
            ? { scale: [0.85, 1.22, 1], rotate: [0, 10, 0] }
            : status === "error"
            ? { x: [0, -7, 7, -5, 5, 0], scale: [1, 1.05, 1] }
            : { scale: 1 }
        }
        transition={{ duration: 0.5, ease: "easeOut" }}
        className={`relative mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-full transition-colors duration-500 ${
          status === "success"
            ? "bg-emerald-500/15 text-emerald-500 shadow-[0_0_35px_rgba(16,185,129,0.35)] dark:bg-emerald-500/20 dark:text-emerald-400"
            : status === "error"
            ? "bg-red-500/15 text-red-500 shadow-[0_0_30px_rgba(239,68,68,0.25)] dark:bg-red-500/20 dark:text-red-400"
            : "bg-[#7c3aed]/10 text-[#7c3aed] shadow-[0_0_25px_rgba(124,58,237,0.15)] dark:bg-[#8b5cf6]/20 dark:text-[#8b5cf6]"
        }`}
      >
        <AnimatePresence mode="wait">
          {status === "success" ? (
            <motion.div
              key="success-icon"
              initial={{ scale: 0, rotate: -45 }}
              animate={{ scale: 1, rotate: 0 }}
              exit={{ scale: 0 }}
              transition={{ type: "spring", stiffness: 400, damping: 20 }}
            >
              <CheckCircle2 className="h-8 w-8 text-emerald-500 dark:text-emerald-400" />
            </motion.div>
          ) : status === "error" ? (
            <motion.div
              key="error-icon"
              initial={{ scale: 0, rotate: 45 }}
              animate={{ scale: 1, rotate: 0 }}
              exit={{ scale: 0 }}
              transition={{ type: "spring", stiffness: 400, damping: 20 }}
            >
              <XCircle className="h-8 w-8 text-red-500 dark:text-red-400" />
            </motion.div>
          ) : (
            <motion.div
              key="mail-icon"
              initial={{ scale: 0.8 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0 }}
            >
              <MailCheck className="h-8 w-8" />
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>

      {/* ── Title & Subtitle ── */}
      <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white">
        {status === "success"
          ? "Email Verified!"
          : t("verifyEmailTitle") || "Verify your email"}
      </h2>
      <p className="mt-2 text-[14px] text-gray-500 dark:text-gray-400 leading-relaxed">
        {status === "success" ? (
          <span className="text-emerald-600 dark:text-emerald-400 font-medium">
            Your account is verified! Preparing your workspace...
          </span>
        ) : (
          <>
            {t("verifyEmailSubtitle") || "We sent a 6-digit code to"}{" "}
            <span className="font-semibold text-gray-800 dark:text-gray-200">
              {user?.email || "your email"}
            </span>
          </>
        )}
      </p>

      {/* ── Dev OTP Helper Banner ── */}
      {devOtp && status !== "success" && (
        <motion.div
          initial={{ opacity: 0, y: -6, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.3 }}
          className="mt-4 flex flex-col items-center gap-1.5 rounded-[14px] bg-violet-500/10 border border-violet-500/30 p-3 text-xs text-violet-700 dark:text-violet-300"
        >
          <div className="flex items-center gap-1.5 font-medium">
            <Sparkles className="h-3.5 w-3.5 text-violet-500 animate-pulse" />
            <span>Development Verification Code:</span>
            <span className="font-mono text-sm font-bold tracking-wider text-violet-900 dark:text-violet-100 bg-violet-500/25 px-2 py-0.5 rounded shadow-sm">
              {devOtp}
            </span>
          </div>
          <button
            type="button"
            onClick={() => handleAutoFill(devOtp)}
            className="group flex items-center gap-1 text-[11px] font-semibold text-violet-600 dark:text-violet-400 hover:text-violet-800 dark:hover:text-violet-200 hover:underline cursor-pointer transition-colors"
          >
            <Zap className="h-3 w-3 text-amber-500 transition-transform group-hover:scale-125" />
            <span>Click here to auto-fill code</span>
          </button>
        </motion.div>
      )}

      {/* ── Error Banner (Smooth slide & shake) ── */}
      <AnimatePresence>
        {error && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.96 }}
            transition={{ type: "spring", stiffness: 450, damping: 25 }}
            className="mt-4 flex items-center justify-center gap-2 rounded-[12px] bg-red-50 p-3 text-[13px] font-medium text-red-600 border border-red-200/70 shadow-sm dark:bg-red-950/35 dark:border-red-800/40 dark:text-red-400"
          >
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ── Success Banner ── */}
      <AnimatePresence>
        {successMsg && !error && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10 }}
            className="mt-4 flex items-center justify-center gap-2 rounded-[12px] bg-emerald-50 p-3 text-[13px] font-medium text-emerald-600 border border-emerald-200/70 shadow-sm dark:bg-emerald-950/35 dark:border-emerald-800/40 dark:text-emerald-400"
          >
            <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-500" />
            <span>{successMsg}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ── Form with OTP Inputs ── */}
      <form onSubmit={handleSubmit} className="mt-6 space-y-6">
        {/* OTP Input Slots with Horizontal Shake on Error */}
        <motion.div
          key={shakeKey}
          animate={
            shakeKey > 0
              ? { x: [0, -14, 14, -10, 10, -5, 5, 0] }
              : undefined
          }
          transition={{ duration: 0.48, ease: "easeInOut" }}
          className="flex justify-center gap-2.5 sm:gap-3"
          onPaste={handlePaste}
        >
          {otp.map((digit, index) => {
            const isFilled = digit !== "";
            const isFocused = focusedIndex === index;
            const isError = status === "error";
            const isSuccess = status === "success";

            return (
              <motion.div
                key={index}
                animate={
                  isSuccess
                    ? { scale: [1, 1.1, 1], y: [0, -4, 0] }
                    : isFilled
                    ? { scale: [1, 1.08, 1] }
                    : { scale: 1 }
                }
                transition={{ duration: 0.25, delay: isSuccess ? index * 0.05 : 0 }}
                className="relative"
              >
                <input
                  ref={(el) => {
                    inputRefs.current[index] = el;
                  }}
                  type="text"
                  inputMode="numeric"
                  maxLength={1}
                  value={digit}
                  disabled={status === "loading" || status === "success"}
                  onFocus={() => setFocusedIndex(index)}
                  onBlur={() => setFocusedIndex(null)}
                  onChange={(e) => handleChange(index, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(index, e)}
                  className={`h-12 w-11 sm:h-14 sm:w-12 rounded-[14px] text-center text-xl font-bold outline-none transition-all duration-200 ${
                    isSuccess
                      ? "border-2 border-emerald-500 bg-emerald-500/10 text-emerald-600 shadow-[0_0_18px_rgba(16,185,129,0.3)] dark:bg-emerald-500/15 dark:text-emerald-400"
                      : isError
                      ? "border-2 border-red-500 bg-red-500/10 text-red-600 shadow-[0_0_18px_rgba(239,68,68,0.25)] dark:bg-red-500/15 dark:text-red-400"
                      : isFocused
                      ? "border-2 border-[#7c3aed] bg-white text-gray-900 shadow-[0_0_20px_rgba(124,58,237,0.25)] ring-4 ring-[#7c3aed]/15 dark:border-[#8b5cf6] dark:bg-[#161B2B] dark:text-white dark:shadow-[0_0_20px_rgba(139,92,246,0.25)] dark:ring-[#8b5cf6]/20"
                      : isFilled
                      ? "border-2 border-gray-300 bg-white text-gray-900 shadow-sm dark:border-[#384360] dark:bg-[#121624] dark:text-white"
                      : "border border-gray-200 bg-gray-50/60 text-gray-900 dark:border-[#2A3042] dark:bg-[#111522]/50 dark:text-white"
                  }`}
                />

                {/* Subtle active pulse dot underneath active input */}
                {isFocused && !isSuccess && !isError && (
                  <motion.div
                    layoutId="active-indicator"
                    className="absolute -bottom-1.5 left-1/2 -ml-1 h-1 w-2 rounded-full bg-[#7c3aed] dark:bg-[#8b5cf6]"
                  />
                )}
              </motion.div>
            );
          })}
        </motion.div>

        {/* ── Submit Button with Loading & Success Transformation ── */}
        <motion.button
          whileHover={status !== "loading" && status !== "success" ? { scale: 1.015 } : undefined}
          whileTap={status !== "loading" && status !== "success" ? { scale: 0.985 } : undefined}
          type="submit"
          disabled={status === "loading" || status === "success" || otp.join("").length < 6}
          className={`group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[14px] py-[13px] text-[15px] font-semibold text-white shadow-md transition-all duration-300 disabled:opacity-50 cursor-pointer ${
            status === "success"
              ? "bg-emerald-600 shadow-emerald-500/30 hover:bg-emerald-600"
              : status === "error"
              ? "bg-red-600 shadow-red-500/30 hover:bg-red-700"
              : "bg-[#7c3aed] shadow-[#7c3aed]/25 hover:bg-[#6d28d9] dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed]"
          }`}
        >
          {status === "loading" ? (
            <div className="flex items-center gap-2">
              <AfabLoader size="xs" />
              <span>Verifying code...</span>
            </div>
          ) : status === "success" ? (
            <motion.div
              initial={{ scale: 0.8 }}
              animate={{ scale: 1 }}
              className="flex items-center gap-2"
            >
              <CheckCircle2 className="h-5 w-5" />
              <span>Success! Redirecting...</span>
            </motion.div>
          ) : (
            <>
              <span>{t("verifyButton") || "Verify Email"}</span>
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1 rtl:rotate-180 rtl:group-hover:-translate-x-1" />
            </>
          )}
        </motion.button>
      </form>

      {/* ── Resend Code Footer ── */}
      {status !== "success" && (
        <div className="mt-6 text-[13px] text-gray-500 dark:text-gray-400">
          <span>{t("didntReceiveCode") || "Didn't receive the code?"} </span>
          <button
            onClick={handleResend}
            disabled={countdown > 0 || resending}
            className="font-semibold text-[#7c3aed] hover:underline dark:text-[#8b5cf6] disabled:opacity-50 disabled:no-underline cursor-pointer inline-flex items-center gap-1.5 transition-colors"
          >
            {resending && <RotateCw className="h-3.5 w-3.5 animate-spin" />}
            {countdown > 0
              ? `${t("resendIn") || "Resend in"} ${countdown}s`
              : t("resendCode") || "Resend Code"}
          </button>
        </div>
      )}
    </motion.div>
  );
}
