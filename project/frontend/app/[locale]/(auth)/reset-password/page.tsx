"use client";

import { useState, useEffect, useCallback, Suspense } from "react";
import { Lock, Eye, EyeOff, ArrowRight, ArrowLeft, AlertTriangle, ShieldX, CheckCircle2 } from "lucide-react";
import { useTranslations } from "next-intl";
import { Link, useRouter } from "@/i18n/routing";
import { useSearchParams } from "next/navigation";
import { motion } from "framer-motion";
import { AuthService } from "@/lib/api/auth";
import { ApiError } from "@/lib/api/client";
import { AfabLoader } from "@/components/ui/afab-loader";
import { PasswordStrengthIndicator } from "@/components/auth/PasswordStrengthIndicator";
import { toast } from "sonner";

type TokenStatus = "loading" | "valid" | "expired" | "invalid";

function ResetPasswordContent() {
  const t = useTranslations("Auth");
  const router = useRouter();
  const searchParams = useSearchParams();

  // Sanitize token: remove quotes, trailing punctuation, or spaces from email client links
  const rawToken = searchParams.get("token") || "";
  const token = rawToken.replace(/[^a-zA-Z0-9-]/g, "").trim();

  const [tokenStatus, setTokenStatus] = useState<TokenStatus>("loading");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [confirmError, setConfirmError] = useState<string | null>(null);

  // Validate token on mount
  const validateToken = useCallback(async () => {
    if (!token) {
      setTokenStatus("invalid");
      return;
    }

    try {
      await AuthService.validateResetToken({ token });
      setTokenStatus("valid");
    } catch (err: unknown) {
      if (err instanceof ApiError) {
        if (err.code === "TOKEN_EXPIRED") {
          setTokenStatus("expired");
        } else {
          setTokenStatus("invalid");
        }
      } else {
        setTokenStatus("invalid");
      }
    }
  }, [token]);

  useEffect(() => {
    validateToken();
  }, [validateToken]);

  // Password validation
  const isPasswordStrong = (pw: string): boolean => {
    return (
      pw.length >= 8 &&
      /[A-Z]/.test(pw) &&
      /[a-z]/.test(pw) &&
      /[0-9]/.test(pw) &&
      /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?`~]/.test(pw)
    );
  };

  const validateForm = (): boolean => {
    let valid = true;

    if (!isPasswordStrong(password)) {
      setPasswordError(t("resetPasswordWeak"));
      valid = false;
    } else {
      setPasswordError(null);
    }

    if (password !== confirmPassword) {
      setConfirmError(t("resetPasswordMismatch"));
      valid = false;
    } else {
      setConfirmError(null);
    }

    return valid;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) return;

    setLoading(true);

    try {
      await AuthService.resetPasswordByToken({ token, password });
      setSuccess(true);
      toast.success(t("passwordResetSuccess"), { duration: 4000 });

      // Redirect to login after a moment
      setTimeout(() => {
        router.push("/login");
      }, 3000);
    } catch (err: unknown) {
      if (err instanceof ApiError) {
        if (err.code === "TOKEN_EXPIRED") {
          setTokenStatus("expired");
        } else if (err.code === "INVALID_TOKEN") {
          setTokenStatus("invalid");
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

  // Loading state
  if (tokenStatus === "loading") {
    return (
      <div className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]">
        <div className="flex flex-col items-center justify-center py-12">
          <AfabLoader size="md" />
          <p className="mt-4 text-[14px] text-gray-500 dark:text-gray-400">
            {t("resetPasswordValidating")}
          </p>
        </div>
      </div>
    );
  }

  // Expired token state
  if (tokenStatus === "expired") {
    return (
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]"
      >
        <div className="text-center py-8">
          <div className="mb-5 flex justify-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-amber-100 dark:bg-amber-500/15">
              <AlertTriangle className="h-8 w-8 text-amber-600 dark:text-amber-400" />
            </div>
          </div>
          <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white mb-2">
            {t("tokenExpiredTitle")}
          </h2>
          <p className="text-[14px] text-gray-500 dark:text-gray-400 mb-8">
            {t("tokenExpiredMessage")}
          </p>
          <Link
            href="/forgot-password"
            className="inline-flex items-center gap-2 rounded-[14px] bg-[#7c3aed] px-6 py-3 text-[14px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed]"
          >
            {t("requestNewLink")}
            <ArrowRight className="h-4 w-4 rtl:rotate-180" />
          </Link>
        </div>
      </motion.div>
    );
  }

  // Invalid token state
  if (tokenStatus === "invalid") {
    return (
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]"
      >
        <div className="text-center py-8">
          <div className="mb-5 flex justify-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-red-100 dark:bg-red-500/15">
              <ShieldX className="h-8 w-8 text-red-600 dark:text-red-400" />
            </div>
          </div>
          <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white mb-2">
            {t("tokenInvalidTitle")}
          </h2>
          <p className="text-[14px] text-gray-500 dark:text-gray-400 mb-8">
            {t("tokenInvalidMessage")}
          </p>
          <Link
            href="/forgot-password"
            className="inline-flex items-center gap-2 rounded-[14px] bg-[#7c3aed] px-6 py-3 text-[14px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed]"
          >
            {t("requestNewLink")}
            <ArrowRight className="h-4 w-4 rtl:rotate-180" />
          </Link>
        </div>
      </motion.div>
    );
  }

  // Success state
  if (success) {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.98 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.3 }}
        className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]"
      >
        <div className="text-center py-8">
          <div className="mb-5 flex justify-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-emerald-100 dark:bg-emerald-500/15">
              <CheckCircle2 className="h-8 w-8 text-emerald-600 dark:text-emerald-400" />
            </div>
          </div>
          <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white mb-2">
            {t("passwordResetSuccessTitle")}
          </h2>
          <p className="text-[14px] text-gray-500 dark:text-gray-400 mb-8">
            {t("passwordResetSuccessMessage")}
          </p>
          <Link
            href="/login"
            className="inline-flex items-center gap-2 text-[14px] font-semibold text-[#7c3aed] hover:underline dark:text-[#8b5cf6] transition-all"
          >
            <ArrowLeft className="h-4 w-4 rtl:rotate-180" />
            {t("backToLogin")}
          </Link>
        </div>
      </motion.div>
    );
  }

  // Valid token — show reset form
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]"
    >
      {/* Back to Login */}
      <div className="mb-6">
        <Link
          href="/login"
          className="inline-flex items-center gap-2 text-[13px] font-medium text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 transition-colors"
        >
          <ArrowLeft className="h-4 w-4 rtl:rotate-180" />
          {t("backToLogin")}
        </Link>
      </div>

      {/* Title */}
      <div className="mb-6">
        <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#7c3aed]/10 dark:bg-[#8b5cf6]/10">
          <Lock className="h-7 w-7 text-[#7c3aed] dark:text-[#8b5cf6]" />
        </div>
        <h2 className="text-[22px] font-bold text-gray-900 tracking-tight dark:text-white">
          {t("resetPasswordTitle")}
        </h2>
        <p className="mt-1 text-[14px] text-gray-500 dark:text-gray-400">
          {t("resetPasswordSubtitle")}
        </p>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        {/* New Password */}
        <div>
          <label
            htmlFor="reset-password"
            className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300"
          >
            {t("newPassword")}
          </label>
          <div className="relative group">
            <Lock className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
            <input
              id="reset-password"
              type={showPassword ? "text" : "password"}
              placeholder={t("newPasswordPlaceholder")}
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                if (passwordError) setPasswordError(null);
                if (confirmError && e.target.value === confirmPassword) setConfirmError(null);
              }}
              required
              disabled={loading}
              autoComplete="new-password"
              aria-invalid={!!passwordError}
              aria-describedby={passwordError ? "reset-password-error" : undefined}
              className={`w-full rounded-[14px] border bg-gray-50/50 py-[12px] pl-11 pr-[44px] text-[14px] text-gray-900 outline-none transition-all focus:bg-white focus:ring-4 dark:bg-[#111522]/50 dark:text-white rtl:pl-[44px] rtl:pr-11 disabled:opacity-60 ${
                passwordError
                  ? "border-red-400 focus:border-red-500 focus:ring-red-500/10 dark:border-red-500/50"
                  : "border-gray-200 focus:border-[#7c3aed] focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
              }`}
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              aria-label={showPassword ? "Hide password" : "Show password"}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors z-10 rtl:left-4 rtl:right-auto"
            >
              {showPassword ? <EyeOff className="h-[18px] w-[18px]" /> : <Eye className="h-[18px] w-[18px]" />}
            </button>
          </div>
          {passwordError && (
            <motion.p
              id="reset-password-error"
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              className="mt-1.5 text-[12px] text-red-500 dark:text-red-400"
              role="alert"
            >
              {passwordError}
            </motion.p>
          )}

          {/* Password Strength Indicator */}
          <PasswordStrengthIndicator password={password} />
        </div>

        {/* Confirm Password */}
        <div>
          <label
            htmlFor="reset-confirm-password"
            className="mb-2 block text-[13px] font-semibold text-gray-700 dark:text-gray-300"
          >
            {t("confirmPassword")}
          </label>
          <div className="relative group">
            <Lock className="absolute left-4 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-gray-400 group-focus-within:text-[#7c3aed] dark:group-focus-within:text-[#8b5cf6] transition-colors rtl:left-auto rtl:right-4 z-10" />
            <input
              id="reset-confirm-password"
              type={showConfirmPassword ? "text" : "password"}
              placeholder={t("confirmPasswordPlaceholder")}
              value={confirmPassword}
              onChange={(e) => {
                setConfirmPassword(e.target.value);
                if (confirmError && e.target.value === password) setConfirmError(null);
              }}
              required
              disabled={loading}
              autoComplete="new-password"
              aria-invalid={!!confirmError}
              aria-describedby={confirmError ? "reset-confirm-error" : undefined}
              className={`w-full rounded-[14px] border bg-gray-50/50 py-[12px] pl-11 pr-[44px] text-[14px] text-gray-900 outline-none transition-all focus:bg-white focus:ring-4 dark:bg-[#111522]/50 dark:text-white rtl:pl-[44px] rtl:pr-11 disabled:opacity-60 ${
                confirmError
                  ? "border-red-400 focus:border-red-500 focus:ring-red-500/10 dark:border-red-500/50"
                  : "border-gray-200 focus:border-[#7c3aed] focus:ring-[#7c3aed]/10 dark:border-[#2A3042] dark:focus:border-[#8b5cf6] dark:focus:ring-[#8b5cf6]/10"
              }`}
            />
            <button
              type="button"
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              aria-label={showConfirmPassword ? "Hide password" : "Show password"}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors z-10 rtl:left-4 rtl:right-auto"
            >
              {showConfirmPassword ? <EyeOff className="h-[18px] w-[18px]" /> : <Eye className="h-[18px] w-[18px]" />}
            </button>
          </div>
          {confirmError && (
            <motion.p
              id="reset-confirm-error"
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              className="mt-1.5 text-[12px] text-red-500 dark:text-red-400"
              role="alert"
            >
              {confirmError}
            </motion.p>
          )}
        </div>

        {/* Submit */}
        <div className="pt-2">
          <motion.button
            whileHover={{ scale: 1.015 }}
            whileTap={{ scale: 0.985 }}
            type="submit"
            disabled={loading || !password || !confirmPassword}
            id="reset-submit"
            className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[14px] bg-[#7c3aed] py-[12px] text-[15px] font-semibold text-white shadow-md shadow-[#7c3aed]/20 transition-all hover:bg-[#6d28d9] hover:shadow-[#7c3aed]/40 dark:bg-[#8b5cf6] dark:hover:bg-[#7c3aed] dark:shadow-[#8b5cf6]/10 dark:hover:shadow-[#8b5cf6]/30 disabled:opacity-70"
          >
            {loading ? (
              <AfabLoader size="xs" />
            ) : (
              <>
                <span>{t("resetButton")}</span>
                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1 rtl:rotate-180 rtl:group-hover:-translate-x-1" />
              </>
            )}
          </motion.button>
        </div>
      </form>
    </motion.div>
  );
}

export default function ResetPasswordPage() {
  return (
    <Suspense
      fallback={
        <div className="w-full max-w-[440px] rounded-[24px] bg-white/80 p-5 sm:p-8 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] backdrop-blur-xl dark:bg-[#161B2B]/80 dark:border dark:border-[#232A3E]/50 dark:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.3)]">
          <div className="flex flex-col items-center justify-center py-12">
            <AfabLoader size="md" />
          </div>
        </div>
      }
    >
      <ResetPasswordContent />
    </Suspense>
  );
}
