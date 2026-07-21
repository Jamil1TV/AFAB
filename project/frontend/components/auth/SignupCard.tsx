"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Link, useRouter } from "@/i18n/routing";
import { AuthTabs } from "./AuthTabs";
import { PasswordInput } from "./PasswordInput";
import { Divider } from "./Divider";
import { SocialButton } from "./SocialButton";
import { AuthService } from "@/lib/api/auth";

export function SignupCard() {
  const t = useTranslations("Auth.signup");
  const router = useRouter();
  
  const [fullName, setFullName] = useState("");
  const [businessName, setBusinessName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [agreeTerms, setAgreeTerms] = useState(false);
  
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (password !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    if (!agreeTerms) {
      setError("You must agree to the terms");
      return;
    }

    setIsLoading(true);

    try {
      const names = fullName.trim().split(" ");
      const firstName = names[0];
      const lastName = names.slice(1).join(" ") || "Doe";

      const response = await AuthService.register({
        firstName,
        lastName,
        email,
        password,
        businessName,
      });

      // Save token
      if (response.accessToken) {
        localStorage.setItem("afab_token", response.accessToken);
        router.push("/dashboard"); // We'll build the dashboard in step 3
      }
    } catch (err: any) {
      setError(err.message || "Something went wrong during registration.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full max-w-[440px] animate-in fade-in slide-in-from-bottom-4 duration-700">
      {/* Card */}
      <div className="rounded-2xl border border-gray-200/80 dark:border-gray-700/40 bg-white dark:bg-[#131825] p-8 sm:p-10 shadow-xl shadow-black/[0.03] dark:shadow-[0_0_60px_rgba(139,92,246,0.06)]">
        {/* Tabs */}
        <AuthTabs activeTab="signup" />

        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            {t("title")}
          </h1>
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
            {t("subtitle")}
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="p-3 text-sm text-red-500 bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 rounded-xl">
              {error}
            </div>
          )}

          {/* Full Name */}
          <div>
            <label
              htmlFor="signup-name"
              className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
            >
              {t("fullNameLabel")}
            </label>
            <input
              id="signup-name"
              type="text"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder={t("fullNamePlaceholder")}
              required
              autoComplete="name"
              className="w-full rounded-xl border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-[#0d1120] px-4 py-3 text-sm text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 transition-all duration-200 focus:border-[#8b5cf6] focus:ring-2 focus:ring-[#8b5cf6]/20 focus:outline-none"
            />
          </div>

          {/* Business Name */}
          <div>
            <label
              htmlFor="signup-business"
              className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
            >
              Business Name
            </label>
            <input
              id="signup-business"
              type="text"
              value={businessName}
              onChange={(e) => setBusinessName(e.target.value)}
              placeholder="e.g. Acme Corp"
              required
              className="w-full rounded-xl border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-[#0d1120] px-4 py-3 text-sm text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 transition-all duration-200 focus:border-[#8b5cf6] focus:ring-2 focus:ring-[#8b5cf6]/20 focus:outline-none"
            />
          </div>

          {/* Email */}
          <div>
            <label
              htmlFor="signup-email"
              className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
            >
              {t("emailLabel")}
            </label>
            <input
              id="signup-email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder={t("emailPlaceholder")}
              required
              autoComplete="email"
              className="w-full rounded-xl border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-[#0d1120] px-4 py-3 text-sm text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 transition-all duration-200 focus:border-[#8b5cf6] focus:ring-2 focus:ring-[#8b5cf6]/20 focus:outline-none"
            />
          </div>

          {/* Password */}
          <div>
            <label
              htmlFor="signup-password"
              className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
            >
              {t("passwordLabel")}
            </label>
            <PasswordInput
              id="signup-password"
              value={password}
              onChange={setPassword}
              placeholder={t("passwordPlaceholder")}
            />
          </div>

          {/* Confirm Password */}
          <div>
            <label
              htmlFor="signup-confirm-password"
              className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
            >
              {t("confirmPasswordLabel")}
            </label>
            <PasswordInput
              id="signup-confirm-password"
              value={confirmPassword}
              onChange={setConfirmPassword}
              placeholder={t("confirmPasswordPlaceholder")}
            />
          </div>

          {/* Terms Agreement */}
          <div className="flex items-start gap-2.5">
            <div className="relative flex items-center justify-center pt-0.5">
              <input
                id="signup-terms"
                type="checkbox"
                checked={agreeTerms}
                onChange={(e) => setAgreeTerms(e.target.checked)}
                required
                className="peer h-4.5 w-4.5 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-[#0d1120] text-[#8b5cf6] transition-colors focus:ring-2 focus:ring-[#8b5cf6]/20 focus:ring-offset-0 checked:bg-[#8b5cf6] checked:border-[#8b5cf6] cursor-pointer"
              />
            </div>
            <label
              htmlFor="signup-terms"
              className="text-sm text-gray-600 dark:text-gray-400 leading-snug cursor-pointer select-none"
            >
              {t("agreeTerms")}{" "}
              <Link
                href="/terms"
                className="font-medium text-[#8b5cf6] hover:text-[#7c3aed] transition-colors"
              >
                {t("termsLink")}
              </Link>{" "}
              {t("andText")}{" "}
              <Link
                href="/privacy"
                className="font-medium text-[#8b5cf6] hover:text-[#7c3aed] transition-colors"
              >
                {t("privacyLink")}
              </Link>
            </label>
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={isLoading}
            className="w-full flex justify-center items-center rounded-xl bg-[#7c3aed] dark:bg-[#8b5cf6] px-6 py-3.5 text-sm font-bold text-white transition-all duration-200 hover:bg-[#6d28d9] dark:hover:bg-[#7c3aed] shadow-lg shadow-[#7c3aed]/25 dark:shadow-[#8b5cf6]/25 hover:shadow-xl hover:shadow-[#7c3aed]/30 dark:hover:shadow-[#8b5cf6]/30 hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]/50 focus:ring-offset-2 dark:focus:ring-offset-[#131825] active:translate-y-0 active:shadow-md disabled:opacity-70 disabled:pointer-events-none"
          >
            {isLoading ? (
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : null}
            {isLoading ? "Creating Account..." : t("signupButton")}
          </button>
        </form>

        {/* Divider */}
        <Divider text={t("dividerText")} />

        {/* Social Login */}
        <div className="space-y-3">
          <SocialButton
            icon={
              <svg viewBox="0 0 24 24" className="h-5 w-5">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"
                  fill="#4285F4"
                />
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"
                />
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"
                />
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"
                />
              </svg>
            }
            label={t("googleButton")}
          />
          <SocialButton
            icon={
              <svg viewBox="0 0 24 24" className="h-5 w-5 text-gray-900 dark:text-white" fill="currentColor">
                <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
              </svg>
            }
            label={t("appleButton")}
          />
        </div>

        {/* Login link */}
        <p className="mt-8 text-center text-sm text-gray-500 dark:text-gray-400">
          {t("hasAccount")}{" "}
          <Link
            href="/login"
            className="font-semibold text-[#8b5cf6] hover:text-[#7c3aed] transition-colors"
          >
            {t("loginLink")}
          </Link>
        </p>
      </div>
    </div>
  );
}
