"use client";

import { useTranslations } from "next-intl";

export type PeriodType = "WEEKLY" | "MONTHLY" | "YEARLY";

interface PeriodSelectorProps {
  value: PeriodType;
  onChange: (period: PeriodType) => void;
  className?: string;
}

const PERIOD_KEYS: PeriodType[] = ["WEEKLY", "MONTHLY", "YEARLY"];

export function PeriodSelector({ value, onChange, className = "" }: PeriodSelectorProps) {
  const t = useTranslations("Common.periods");

  return (
    <div
      className={`flex items-center rounded-xl bg-gray-100 dark:bg-[#080c18] border border-gray-200 dark:border-gray-800/60 p-1 text-xs font-semibold ${className}`}
    >
      {PERIOD_KEYS.map((p) => {
        const isSelected = value === p;
        const label = t(p.toLowerCase() as "weekly" | "monthly" | "yearly");

        return (
          <button
            key={p}
            type="button"
            onClick={() => onChange(p)}
            className={`px-3 py-1.5 rounded-lg transition-all ${
              isSelected
                ? "bg-[#8b5cf6] text-white shadow-sm"
                : "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
            }`}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}
