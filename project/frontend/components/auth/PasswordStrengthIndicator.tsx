"use client";

import { useMemo } from "react";
import { useTranslations } from "next-intl";
import { Check, X } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

interface PasswordStrengthIndicatorProps {
  password: string;
}

interface Requirement {
  key: string;
  label: string;
  test: (pw: string) => boolean;
}

export function PasswordStrengthIndicator({ password }: PasswordStrengthIndicatorProps) {
  const t = useTranslations("Auth");

  const requirements: Requirement[] = useMemo(
    () => [
      {
        key: "length",
        label: t("pwReqLength"),
        test: (pw: string) => pw.length >= 8,
      },
      {
        key: "uppercase",
        label: t("pwReqUppercase"),
        test: (pw: string) => /[A-Z]/.test(pw),
      },
      {
        key: "lowercase",
        label: t("pwReqLowercase"),
        test: (pw: string) => /[a-z]/.test(pw),
      },
      {
        key: "number",
        label: t("pwReqNumber"),
        test: (pw: string) => /[0-9]/.test(pw),
      },
      {
        key: "special",
        label: t("pwReqSpecial"),
        test: (pw: string) => /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?`~]/.test(pw),
      },
    ],
    [t]
  );

  const passed = requirements.filter((req) => req.test(password)).length;
  const total = requirements.length;

  // Strength level: 0-1 = weak, 2-3 = fair, 4 = good, 5 = strong
  const getStrengthInfo = () => {
    if (password.length === 0) return { level: 0, label: "", color: "bg-gray-200 dark:bg-gray-700" };
    if (passed <= 1) return { level: 1, label: t("pwStrengthWeak"), color: "bg-red-500" };
    if (passed <= 2) return { level: 2, label: t("pwStrengthFair"), color: "bg-orange-500" };
    if (passed <= 3) return { level: 3, label: t("pwStrengthGood"), color: "bg-yellow-500" };
    if (passed === 4) return { level: 4, label: t("pwStrengthStrong"), color: "bg-emerald-500" };
    return { level: 5, label: t("pwStrengthVeryStrong"), color: "bg-emerald-500" };
  };

  const strength = getStrengthInfo();
  const progressWidth = password.length === 0 ? 0 : (passed / total) * 100;

  if (password.length === 0) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, height: 0 }}
        animate={{ opacity: 1, height: "auto" }}
        exit={{ opacity: 0, height: 0 }}
        transition={{ duration: 0.25 }}
        className="mt-3 space-y-3"
      >
        {/* Strength Bar */}
        <div className="space-y-1.5">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              {t("pwStrengthLabel")}
            </span>
            {strength.label && (
              <motion.span
                key={strength.label}
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className={`text-[11px] font-semibold ${
                  strength.level <= 1
                    ? "text-red-500"
                    : strength.level <= 2
                    ? "text-orange-500"
                    : strength.level <= 3
                    ? "text-yellow-600 dark:text-yellow-400"
                    : "text-emerald-600 dark:text-emerald-400"
                }`}
              >
                {strength.label}
              </motion.span>
            )}
          </div>
          <div className="h-1.5 w-full overflow-hidden rounded-full bg-gray-200 dark:bg-gray-700">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${progressWidth}%` }}
              transition={{ duration: 0.35, ease: "easeOut" }}
              className={`h-full rounded-full transition-colors duration-300 ${strength.color}`}
            />
          </div>
        </div>

        {/* Requirements Checklist */}
        <ul className="grid grid-cols-1 gap-1" role="list" aria-label={t("pwRequirementsLabel")}>
          {requirements.map((req) => {
            const met = req.test(password);
            return (
              <motion.li
                key={req.key}
                initial={{ opacity: 0, x: -8 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.2 }}
                className="flex items-center gap-2"
              >
                <motion.div
                  initial={false}
                  animate={{
                    scale: met ? [1, 1.2, 1] : 1,
                    backgroundColor: met ? "rgb(16, 185, 129)" : "transparent",
                    borderColor: met ? "rgb(16, 185, 129)" : "rgb(209, 213, 219)",
                  }}
                  transition={{ duration: 0.2 }}
                  className={`flex h-4 w-4 shrink-0 items-center justify-center rounded-full border ${
                    met
                      ? "border-emerald-500 bg-emerald-500"
                      : "border-gray-300 dark:border-gray-600"
                  }`}
                >
                  {met ? (
                    <Check className="h-2.5 w-2.5 text-white" strokeWidth={3} />
                  ) : (
                    <X className="h-2.5 w-2.5 text-gray-400 dark:text-gray-500" strokeWidth={3} />
                  )}
                </motion.div>
                <span
                  className={`text-[12px] transition-colors ${
                    met
                      ? "text-emerald-600 dark:text-emerald-400 font-medium"
                      : "text-gray-500 dark:text-gray-400"
                  }`}
                >
                  {req.label}
                </span>
              </motion.li>
            );
          })}
        </ul>
      </motion.div>
    </AnimatePresence>
  );
}
