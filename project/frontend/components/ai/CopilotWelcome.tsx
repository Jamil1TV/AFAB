"use client";

import { motion } from "framer-motion";
import {
  ArrowUpRight,
  Calculator,
  FileWarning,
  Flame,
  Globe2,
  Languages,
  Lock,
  ShieldCheck,
  Sparkles,
  Target,
  TrendingUp,
} from "lucide-react";
import { useTranslations } from "next-intl";

interface CopilotWelcomeProps {
  onSelectPrompt: (text: string) => void;
  disabled?: boolean;
}

const CONTAINER_VARIANTS = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.055,
      delayChildren: 0.05,
    },
  },
};

const CARD_VARIANTS = {
  hidden: { opacity: 0, y: 14 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.32, ease: [0.22, 1, 0.36, 1] as const },
  },
};

export function CopilotWelcome({ onSelectPrompt, disabled = false }: CopilotWelcomeProps) {
  const t = useTranslations("AI");

  const starterCards = [
    {
      key: "pnl",
      tag: t("prompts.pnlTag"),
      title: t("prompts.pnlTitle"),
      text: t("prompts.pnlText"),
      icon: TrendingUp,
      tileClass: "bg-[var(--primary)]/10 text-[var(--primary)] border-[var(--primary)]/20",
    },
    {
      key: "expenses",
      tag: t("prompts.expensesTag"),
      title: t("prompts.expensesTitle"),
      text: t("prompts.expensesText"),
      icon: Flame,
      tileClass: "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20",
    },
    {
      key: "invoices",
      tag: t("prompts.invoicesTag"),
      title: t("prompts.invoicesTitle"),
      text: t("prompts.invoicesText"),
      icon: FileWarning,
      tileClass: "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20",
    },
    {
      key: "budgets",
      tag: t("prompts.budgetsTag"),
      title: t("prompts.budgetsTitle"),
      text: t("prompts.budgetsText"),
      icon: Target,
      tileClass: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20",
    },
    {
      key: "derja",
      tag: t("prompts.derjaTag"),
      title: t("prompts.derjaTitle"),
      text: t("prompts.derjaText"),
      icon: Languages,
      tileClass: "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/20",
    },
    {
      key: "coverage",
      tag: t("prompts.coverageTag"),
      title: t("prompts.coverageTitle"),
      text: t("prompts.coverageText"),
      icon: ShieldCheck,
      tileClass: "bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border-indigo-500/20",
    },
  ];

  const capabilities = [
    { icon: Lock, label: t("capPrivate") },
    { icon: Calculator, label: t("capMath") },
    { icon: Globe2, label: t("capMultilingual") },
  ];

  return (
    <div className="relative max-w-4xl mx-auto py-4 sm:py-8 space-y-8">
      {/* Ambient Radial Halo */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -top-6 left-1/2 -translate-x-1/2 h-52 w-80 rounded-full bg-gradient-to-tr from-[var(--primary)]/18 via-[#6366f1]/10 to-[#10b981]/12 blur-3xl dark:from-[var(--primary)]/20 dark:via-[#6366f1]/12 dark:to-[#10b981]/10"
      />

      {/* Hero Core */}
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] as const }}
        className="relative text-center space-y-4"
      >
        <div className="flex flex-col items-center gap-3">
          {/* Refined Static Brand Emblem */}
          <div className="relative flex h-16 w-16 items-center justify-center">
            {/* Soft ambient static glow */}
            <div
              aria-hidden="true"
              className="pointer-events-none absolute -inset-2 rounded-3xl bg-[var(--primary)]/20 blur-xl"
            />
            <div className="relative z-10 flex h-14 w-14 items-center justify-center rounded-2xl border border-[var(--primary)]/30 bg-gradient-to-b from-[var(--primary)]/15 via-[var(--primary)]/5 to-transparent dark:to-[#080c18] shadow-lg shadow-[var(--primary)]/10 backdrop-blur-md">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-[var(--primary)] to-[var(--accent)] text-white shadow-md shadow-[var(--primary)]/25">
                <Sparkles className="h-5 w-5" />
              </div>
            </div>
          </div>

          <span className="inline-flex items-center gap-1.5 rounded-full border border-[var(--primary)]/25 bg-[var(--primary)]/10 px-3 py-1 text-[11px] font-semibold text-[var(--primary)]">
            <ShieldCheck className="h-3.5 w-3.5 text-emerald-500" />
            {t("heroBadge")}
          </span>
        </div>

        <h2 className="font-heading text-2xl sm:text-3xl font-bold tracking-tight text-gray-900 dark:text-white">
          <span>{t("heroTitleStart")}</span>
          <span className="bg-gradient-to-r from-[var(--primary)] via-[var(--accent)] to-emerald-500 bg-clip-text text-transparent dark:from-[var(--primary)] dark:via-[var(--accent)] dark:to-emerald-400">
            {t("heroTitleHighlight")}
          </span>
        </h2>

        <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 max-w-2xl mx-auto leading-relaxed">
          {t("welcomeSubtitle")}
        </p>

        {/* Capability Strip */}
        <div className="flex flex-wrap items-center justify-center gap-2 pt-1">
          {capabilities.map((cap) => {
            const Icon = cap.icon;
            return (
              <span
                key={cap.label}
                className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-gray-800/80 bg-white/80 dark:bg-[#080c18]/80 px-3 py-1 text-[11px] font-medium text-gray-600 dark:text-gray-300 shadow-2xs"
              >
                <Icon className="h-3 w-3 text-[var(--primary)]" />
                {cap.label}
              </span>
            );
          })}
        </div>
      </motion.div>

      {/* Staggered Starter Prompt Grid */}
      <motion.div
        variants={CONTAINER_VARIANTS}
        initial="hidden"
        animate="visible"
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5"
      >
        {starterCards.map((card) => {
          const Icon = card.icon;
          return (
            <motion.button
              key={card.key}
              variants={CARD_VARIANTS}
              whileHover={{ y: -3 }}
              whileTap={{ scale: 0.985 }}
              type="button"
              disabled={disabled}
              onClick={() => onSelectPrompt(card.text)}
              className="group relative flex flex-col justify-between text-start p-4 rounded-2xl border border-gray-200/90 dark:border-gray-800/80 bg-white/90 dark:bg-[#080c18]/90 hover:border-[var(--primary)]/50 hover:shadow-lg hover:shadow-[var(--primary)]/[0.07] dark:hover:bg-[#0e1326] transition-all min-h-[148px] gap-3 disabled:opacity-50"
            >
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2 min-w-0">
                  <span
                    className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border ${card.tileClass}`}
                  >
                    <Icon className="h-4 w-4" />
                  </span>
                  <span className="text-[10px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
                    {card.tag}
                  </span>
                </div>
                <ArrowUpRight className="h-4 w-4 text-gray-300 dark:text-gray-600 group-hover:text-[var(--primary)] group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform rtl:rotate-180 shrink-0" />
              </div>

              <div className="space-y-1.5 flex-1">
                <h3 className="text-[13px] font-bold text-gray-900 dark:text-white group-hover:text-[var(--primary)] transition-colors leading-snug">
                  {card.title}
                </h3>
                <p className="text-xs text-gray-600 dark:text-gray-400 leading-relaxed">
                  {card.text}
                </p>
              </div>
            </motion.button>
          );
        })}
      </motion.div>
    </div>
  );
}

