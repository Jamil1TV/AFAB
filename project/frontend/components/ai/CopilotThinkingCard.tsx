"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { CheckCircle2, Sparkles, Clock } from "lucide-react";
import { useTranslations } from "next-intl";
import { CopilotMarkdown } from "@/components/ai/CopilotMarkdown";

export interface CompletedToolInfo {
  tool: string;
  evidenceCount: number;
}

interface CopilotThinkingCardProps {
  activeTools: string[];
  completedTools: CompletedToolInfo[];
  streamingText: string;
  streamPhase?: string | null;
}

const KNOWN_TOOLS = new Set([
  "get_business_summary",
  "compare_periods",
  "get_category_breakdown",
  "search_transactions",
  "get_invoices_overview",
  "get_customers_overview",
  "get_budgets_status",
  "get_recurring_commitments",
  "get_data_coverage",
]);

const PHASE_KEYS = ["memory", "ledger", "synthesis"] as const;

export function CopilotThinkingCard({
  activeTools,
  completedTools,
  streamingText,
  streamPhase = null,
}: CopilotThinkingCardProps) {
  const t = useTranslations("AI");
  const [elapsedMs, setElapsedMs] = useState(0);
  const [phaseIdx, setPhaseIdx] = useState(0);

  useEffect(() => {
    const startedAt = Date.now();
    const timer = window.setInterval(() => {
      const delta = Date.now() - startedAt;
      setElapsedMs(delta);
      setPhaseIdx(Math.floor(delta / 1800) % PHASE_KEYS.length);
    }, 200);
    return () => window.clearInterval(timer);
  }, []);

  const getToolLabel = (toolName: string) =>
    KNOWN_TOOLS.has(toolName) ? t(`tools.${toolName}`) : t("tools.fallback");

  const activeHeadline =
    activeTools.length > 0
      ? getToolLabel(activeTools[activeTools.length - 1])
      : streamPhase === "warming_model"
      ? t("thinkingPhases.warmingModel")
      : t(`thinkingPhases.${PHASE_KEYS[phaseIdx]}`);

  const elapsedSeconds = (elapsedMs / 1000).toFixed(1);

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] as const }}
      className="flex items-start gap-3"
    >
      {/* Refined Copilot Indicator */}
      <div className="relative flex h-9 w-9 shrink-0 items-center justify-center mt-0.5">
        <span
          aria-hidden="true"
          className="absolute inset-0 rounded-xl bg-[var(--primary)]/20 blur-sm animate-pulse"
        />
        <span className="relative z-10 flex h-8 w-8 items-center justify-center rounded-xl border border-[var(--primary)]/30 bg-gradient-to-br from-[var(--primary)]/20 to-[var(--primary-hover)]/10 text-[var(--primary)] shadow-sm">
          <Sparkles className="h-4 w-4" />
        </span>
      </div>

      {/* Elevated Thinking / Live Stream Card */}
      <div className="flex-1 min-w-0">
        {!streamingText ? (
          <div className="relative overflow-hidden rounded-2xl rounded-ss-md border border-[var(--primary)]/30 bg-white/95 dark:bg-[#0b1020]/95 p-4 shadow-lg shadow-[var(--glow-color)] backdrop-blur-md space-y-3.5">
            {/* Subtle top animated shimmer line */}
            <div
              aria-hidden="true"
              className="absolute inset-x-0 top-0 h-[2px] bg-gradient-to-r from-transparent via-[var(--primary)] to-transparent opacity-80"
            />

            {/* Phase Shimmer Header + Live Elapsed Timer */}
            <div className="flex items-center justify-between gap-3">
              <div className="min-w-0 flex-1">
                <AnimatePresence mode="wait">
                  <motion.p
                    key={activeHeadline}
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -4 }}
                    transition={{ duration: 0.22 }}
                    className="ai-shimmer-text text-xs sm:text-[13px] font-semibold truncate"
                  >
                    {activeHeadline}
                  </motion.p>
                </AnimatePresence>
              </div>
              <span className="inline-flex items-center gap-1 rounded-full border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.04] px-2 py-0.5 text-[11px] font-medium tabular-nums text-gray-500 dark:text-gray-400 shrink-0">
                <Clock className="h-3 w-3 text-[var(--primary)]" />
                {t("elapsedSeconds", { seconds: elapsedSeconds })}
              </span>
            </div>

            {/* Live Tool Pipeline Chips */}
            {(activeTools.length > 0 || completedTools.length > 0) && (
              <div className="flex flex-wrap gap-1.5">
                {completedTools.map((item, idx) => (
                  <motion.span
                    key={`done-${item.tool}-${idx}`}
                    initial={{ opacity: 0, scale: 0.92 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="inline-flex items-center gap-1.5 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-2.5 py-1 text-[11px] font-medium text-emerald-700 dark:text-emerald-300"
                  >
                    <CheckCircle2 className="h-3 w-3 shrink-0 text-emerald-500" />
                    <span>{getToolLabel(item.tool)}</span>
                    {item.evidenceCount > 0 && (
                      <span className="rounded-full bg-emerald-500/20 px-1.5 text-[10px] font-bold tabular-nums">
                        {item.evidenceCount}
                      </span>
                    )}
                  </motion.span>
                ))}

                {activeTools.map((tool) => (
                  <motion.span
                    key={`active-${tool}`}
                    initial={{ opacity: 0, scale: 0.92 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="inline-flex items-center gap-2 rounded-full border border-[var(--primary)]/35 bg-[var(--primary)]/10 px-2.5 py-1 text-[11px] font-semibold text-[var(--primary)]"
                  >
                    <span className="inline-flex items-end gap-0.5 h-3" aria-hidden="true">
                      <span className="ai-wave-bar-1 w-0.5 h-full rounded-full bg-[var(--primary)]" />
                      <span className="ai-wave-bar-2 w-0.5 h-full rounded-full bg-[var(--primary)]" />
                      <span className="ai-wave-bar-3 w-0.5 h-full rounded-full bg-[var(--primary)]" />
                    </span>
                    <span>{getToolLabel(tool)}</span>
                  </motion.span>
                ))}
              </div>
            )}

            {/* Tapered Skeleton Lines */}
            <div className="space-y-2 pt-0.5" aria-hidden="true">
              <div className="h-2.5 w-[92%] rounded-full bg-gray-200/80 dark:bg-white/[0.06] animate-pulse" />
              <div className="h-2.5 w-[76%] rounded-full bg-gray-200/70 dark:bg-white/[0.05] animate-pulse [animation-delay:120ms]" />
              <div className="h-2.5 w-[52%] rounded-full bg-gray-200/60 dark:bg-white/[0.04] animate-pulse [animation-delay:240ms]" />
            </div>
          </div>
        ) : (
          <motion.div
            initial={{ opacity: 0.92 }}
            animate={{ opacity: 1 }}
            className="rounded-2xl rounded-ss-md border border-[var(--primary)]/30 bg-white dark:bg-[#0b1020] p-4 sm:p-5 shadow-md shadow-[var(--glow-color)] space-y-3"
          >
            {/* Compact Streaming Meta Header */}
            <div className="flex flex-wrap items-center justify-between gap-2 pb-2 border-b border-gray-100 dark:border-gray-800/80">
              <div className="flex items-center gap-2">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[var(--primary)] opacity-75" />
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-[var(--primary)]" />
                </span>
                <span className="text-[11px] font-bold uppercase tracking-wider text-[var(--primary)]">
                  {t("streamingLabel")}
                </span>
              </div>
              {completedTools.length > 0 && (
                <div className="flex flex-wrap items-center gap-1.5">
                  {completedTools.map((item, idx) => (
                    <span
                      key={`live-done-${item.tool}-${idx}`}
                      className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-2 py-0.5 text-[10px] font-semibold text-emerald-700 dark:text-emerald-300"
                    >
                      <CheckCircle2 className="h-2.5 w-2.5 text-emerald-500" />
                      {getToolLabel(item.tool)}
                    </span>
                  ))}
                </div>
              )}
            </div>

            <CopilotMarkdown content={streamingText} isStreaming />
          </motion.div>
        )}
      </div>
    </motion.div>
  );
}

