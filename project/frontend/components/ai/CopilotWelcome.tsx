"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import {
  ArrowUpRight,
  Calculator,
  FileUp,
  Globe2,
  Languages,
  LineChart,
  Lock,
  Sparkles,
  Sunrise,
  TrendingUp,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { AiPulseResponse, AiService } from "@/lib/api/ai";
import { formatCurrency } from "@/lib/currency";

interface CopilotWelcomeProps {
  onSelectPrompt: (text: string) => void;
  onPrefillPrompt: (text: string) => void;
  onAttachClick: () => void;
  disabled?: boolean;
}

const CONTAINER_VARIANTS = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
      delayChildren: 0.04,
    },
  },
};

const CARD_VARIANTS = {
  hidden: { opacity: 0, y: 10 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.28, ease: [0.22, 1, 0.36, 1] as const },
  },
};

export function CopilotWelcome({
  onSelectPrompt,
  onPrefillPrompt,
  onAttachClick,
  disabled = false,
}: CopilotWelcomeProps) {
  const t = useTranslations("AI");
  const [pulse, setPulse] = useState<AiPulseResponse | null>(null);

  useEffect(() => {
    let active = true;
    AiService.getPulse(false)
      .then((res) => {
        if (active) setPulse(res);
      })
      .catch(() => {});
    return () => {
      active = false;
    };
  }, []);

  const bentoCards = [
    {
      key: "pnl",
      title: t("prompts.pnlTitle"),
      desc: t("prompts.pnlShortDesc"),
      icon: TrendingUp,
      tileClass:
        "bg-[var(--primary)]/12 text-[var(--primary)] border-[var(--primary)]/25",
      onClick: () => onSelectPrompt(t("prompts.pnlText")),
    },
    {
      key: "forecast",
      title: t("prompts.forecastTitle"),
      desc: t("prompts.forecastShortDesc"),
      icon: LineChart,
      tileClass:
        "bg-emerald-500/12 text-emerald-600 dark:text-emerald-400 border-emerald-500/25",
      onClick: () => onSelectPrompt(t("prompts.forecastText")),
    },
    {
      key: "scan",
      title: t("prompts.scanTitle"),
      desc: t("prompts.scanShortDesc"),
      badge: t("prompts.scanBadge"),
      icon: FileUp,
      tileClass:
        "bg-sky-500/12 text-sky-600 dark:text-sky-400 border-sky-500/25",
      onClick: () => onAttachClick(),
    },
    {
      key: "derja",
      title: t("prompts.derjaTitle"),
      desc: t("prompts.derjaShortDesc"),
      icon: Languages,
      tileClass:
        "bg-amber-500/12 text-amber-600 dark:text-amber-400 border-amber-500/25",
      onClick: () => onSelectPrompt(t("prompts.derjaText")),
    },
  ];

  const capabilities = [
    { icon: Lock, label: t("capPrivate") },
    { icon: Calculator, label: t("capMath") },
    { icon: Globe2, label: t("capMultilingual") },
  ];

  const quickPills = [
    {
      key: "invoices",
      label: t("prompts.invoicesTitle"),
      onClick: () => onSelectPrompt(t("prompts.invoicesText")),
    },
    {
      key: "budgets",
      label: t("prompts.budgetsTitle"),
      onClick: () => onSelectPrompt(t("prompts.budgetsText")),
    },
    {
      key: "capture",
      label: t("prompts.quickCaptureChip"),
      onClick: () => onPrefillPrompt(t("prompts.quickCapturePrefill")),
    },
  ];

  const alertTotal = pulse ? pulse.highCount + pulse.mediumCount : 0;

  return (
    <div className="relative min-h-full flex flex-col justify-center max-w-3xl mx-auto py-2 sm:py-4 gap-4 sm:gap-5">
      {/* Theme-Synced Atmospheric Top Aura */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -top-4 left-1/2 -translate-x-1/2 h-44 w-80 rounded-full bg-[var(--primary)]/[0.14] blur-3xl"
      />

      {/* Compact Executive Hero */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] as const }}
        className="relative text-center space-y-2.5"
      >
        <div className="flex justify-center">
          <div className="relative flex h-11 w-11 items-center justify-center">
            <div
              aria-hidden="true"
              className="pointer-events-none absolute -inset-1.5 rounded-2xl bg-[var(--primary)]/20 blur-md"
            />
            <div className="relative z-10 flex h-11 w-11 items-center justify-center rounded-2xl border border-[var(--primary)]/30 bg-[var(--surface-inset)] shadow-md shadow-[var(--primary)]/10">
              <div className="flex h-7 w-7 items-center justify-center rounded-xl bg-gradient-to-br from-[var(--primary)] to-[var(--primary-hover)] text-white shadow-sm">
                <Sparkles className="h-4 w-4" />
              </div>
            </div>
          </div>
        </div>

        <h2 className="font-heading text-2xl sm:text-[28px] font-bold tracking-tight text-gray-900 dark:text-white leading-tight">
          <span>{t("heroTitleStart")}</span>
          <span className="ai-accent-gradient">{t("heroTitleHighlight")}</span>
        </h2>

        <p className="text-xs sm:text-[13px] text-gray-500 dark:text-gray-400 max-w-xl mx-auto leading-relaxed">
          {t("welcomeSubtitle")}
        </p>
      </motion.div>

      {/* Live Financial Pulse Strip */}
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.28, delay: 0.04, ease: [0.22, 1, 0.36, 1] as const }}
        className="relative rounded-2xl border border-[var(--border)] bg-[var(--surface-inset)]/90 px-3.5 py-2.5 flex flex-wrap items-center justify-between gap-3 backdrop-blur-md"
      >
        {pulse ? (
          <div className="flex flex-wrap items-center gap-3 text-xs">
            <div className="flex items-center gap-1.5">
              <span className="text-[11px] font-medium text-gray-500 dark:text-gray-400">
                {t("pulse.monthNet")}
              </span>
              <span
                className={`font-bold tabular-nums ${
                  pulse.monthNetProfit >= 0
                    ? "text-emerald-600 dark:text-emerald-400"
                    : "text-rose-600 dark:text-rose-400"
                }`}
              >
                {formatCurrency(pulse.monthNetProfit, pulse.currency || "USD")}
              </span>
            </div>

            <span className="h-4 w-px bg-[var(--border)] hidden sm:block" aria-hidden="true" />

            <div className="flex items-center gap-1.5">
              <span
                className={`h-1.5 w-1.5 rounded-full ${
                  pulse.overdueCount > 0 ? "bg-rose-500" : "bg-emerald-500"
                }`}
              />
              <span className="text-[11px] font-medium text-gray-500 dark:text-gray-400">
                {t("pulse.overdue")}
              </span>
              <span
                className={`font-bold tabular-nums ${
                  pulse.overdueCount > 0
                    ? "text-rose-600 dark:text-rose-400"
                    : "text-emerald-600 dark:text-emerald-400"
                }`}
              >
                {pulse.overdueCount > 0 ? pulse.overdueCount : t("pulse.allClear")}
              </span>
            </div>

            <span className="h-4 w-px bg-[var(--border)] hidden sm:block" aria-hidden="true" />

            <div className="flex items-center gap-1.5">
              <span
                className={`h-1.5 w-1.5 rounded-full ${
                  alertTotal > 0 ? "bg-amber-500" : "bg-emerald-500"
                }`}
              />
              <span className="text-[11px] font-medium text-gray-500 dark:text-gray-400">
                {t("pulse.alerts")}
              </span>
              <span
                className={`font-bold tabular-nums ${
                  alertTotal > 0
                    ? "text-amber-600 dark:text-amber-400"
                    : "text-emerald-600 dark:text-emerald-400"
                }`}
              >
                {alertTotal > 0 ? alertTotal : t("pulse.healthy")}
              </span>
            </div>
          </div>
        ) : (
          <div className="flex flex-wrap items-center gap-2">
            {capabilities.map((cap) => {
              const Icon = cap.icon;
              return (
                <span
                  key={cap.label}
                  className="inline-flex items-center gap-1.5 rounded-full border border-[var(--border)] bg-[var(--card)]/90 px-2.5 py-1 text-[11px] font-medium text-gray-600 dark:text-gray-300"
                >
                  <Icon className="h-3 w-3 text-[var(--primary)]" />
                  <span>{cap.label}</span>
                </span>
              );
            })}
          </div>
        )}

        <button
          type="button"
          disabled={disabled}
          onClick={() => onSelectPrompt(t("morningBriefPrompt"))}
          className="inline-flex items-center gap-1.5 rounded-xl bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white px-3.5 py-1.5 text-xs font-semibold shadow-sm shadow-[var(--glow-color)] transition-all disabled:opacity-50 ms-auto"
        >
          <Sunrise className="h-3.5 w-3.5" />
          <span>{t("morningBriefButton")}</span>
        </button>
      </motion.div>

      {/* Creative 2x2 Action Bento Grid */}
      <motion.div
        variants={CONTAINER_VARIANTS}
        initial="hidden"
        animate="visible"
        className="grid grid-cols-1 sm:grid-cols-2 gap-2.5"
      >
        {bentoCards.map((card) => {
          const Icon = card.icon;
          return (
            <motion.button
              key={card.key}
              variants={CARD_VARIANTS}
              whileHover={{ y: -2 }}
              whileTap={{ scale: 0.99 }}
              type="button"
              disabled={disabled}
              onClick={card.onClick}
              className="group relative flex items-start gap-3 text-start p-3.5 rounded-2xl border border-[var(--border)] bg-[var(--surface-inset)]/75 hover:bg-[var(--surface-inset)] hover:border-[var(--primary)]/45 hover:shadow-md hover:shadow-[var(--primary)]/[0.06] transition-all disabled:opacity-50"
            >
              <span
                className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border mt-0.5 ${card.tileClass}`}
              >
                <Icon className="h-4 w-4" />
              </span>

              <div className="min-w-0 flex-1 space-y-0.5">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5 min-w-0">
                    <h3 className="text-[13px] font-bold text-gray-900 dark:text-white group-hover:text-[var(--primary)] transition-colors truncate">
                      {card.title}
                    </h3>
                    {card.badge && (
                      <span className="rounded-md bg-sky-500/12 border border-sky-500/25 px-1.5 py-0.5 text-[9.5px] font-bold uppercase tracking-wider text-sky-600 dark:text-sky-400 shrink-0">
                        {card.badge}
                      </span>
                    )}
                  </div>
                  <ArrowUpRight className="h-3.5 w-3.5 text-gray-400 dark:text-gray-500 group-hover:text-[var(--primary)] group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform rtl:rotate-180 shrink-0" />
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400 leading-snug line-clamp-2">
                  {card.desc}
                </p>
              </div>
            </motion.button>
          );
        })}
      </motion.div>

      {/* Compact Quick Suggestion Pills */}
      <div className="flex flex-wrap items-center justify-center gap-1.5 pt-0.5">
        {quickPills.map((pill) => (
          <button
            key={pill.key}
            type="button"
            disabled={disabled}
            onClick={pill.onClick}
            className="rounded-full border border-[var(--border)] bg-[var(--card)] hover:border-[var(--primary)]/45 hover:text-[var(--primary)] px-3 py-1 text-[11.5px] font-medium text-gray-600 dark:text-gray-300 transition-colors disabled:opacity-50"
          >
            {pill.label}
          </button>
        ))}
      </div>
    </div>
  );
}
