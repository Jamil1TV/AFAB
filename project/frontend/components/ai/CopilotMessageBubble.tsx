"use client";

import { useState } from "react";
import { Brain, ChevronDown, ChevronRight } from "lucide-react";
import { motion } from "framer-motion";
import {
  ArrowUpRight,
  Check,
  CheckCircle2,
  Copy,
  Database,
  RotateCcw,
  Sparkles,
  Wrench,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { AiActionDraft, AiEvidenceItem, AiMessageItem } from "@/lib/api/ai";
import { CopilotMarkdown } from "@/components/ai/CopilotMarkdown";
import { CopilotChartCard } from "@/components/ai/CopilotChartCard";
import { CopilotActionDraftCard } from "@/components/ai/CopilotActionDraftCard";
import { CopilotReminderCard } from "@/components/ai/CopilotReminderCard";
import { CopilotMemoryProposalCard } from "@/components/ai/CopilotMemoryProposalCard";
import { AttachmentPreviewChip } from "@/components/ai/AttachmentPreviewChip";
import { formatCurrency } from "@/lib/currency";
import { toast } from "sonner";

interface CopilotMessageBubbleProps {
  message: AiMessageItem;
  locale: string;
  isLatestAssistant?: boolean;
  canRegenerate?: boolean;
  onRegenerate?: () => void;
  onDraftUpdated?: (messageId: string, updatedDraft: AiActionDraft) => void;
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
  "simulate_cashflow_forecast",
  "get_financial_pulse",
  "propose_transaction_draft",
  "propose_invoice_draft",
  "propose_budget_draft",
  "propose_payment_reminder",
  "propose_business_memory",
]);

function formatTimestamp(iso: string, locale: string): string {
  try {
    return new Intl.DateTimeFormat(locale === "ar" ? "ar-TN" : "en-US", {
      hour: "2-digit",
      minute: "2-digit",
    }).format(new Date(iso));
  } catch {
    return "";
  }
}

function formatCompactNumber(n: number, locale: string): string {
  try {
    return new Intl.NumberFormat(locale === "ar" ? "ar-TN" : "en-US").format(n);
  } catch {
    return String(n);
  }
}

function getEvidenceBadgeClass(type: string): string {
  switch (type.toUpperCase()) {
    case "INVOICE":
      return "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20";
    case "TRANSACTION":
      return "bg-[var(--primary)]/10 text-[var(--primary)] border-[var(--primary)]/20";
    case "BUDGET":
      return "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20";
    case "MEMORY":
      return "bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border-indigo-500/20";
    case "CUSTOMER":
      return "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/20";
    default:
      return "bg-[var(--primary)]/10 text-[var(--primary)] border-[var(--primary)]/20";
  }
}

export function CopilotMessageBubble({
  message,
  locale,
  isLatestAssistant = false,
  canRegenerate = false,
  onRegenerate,
  onDraftUpdated,
}: CopilotMessageBubbleProps) {
  const t = useTranslations("AI");
  const [copied, setCopied] = useState(false);
  const [thoughtExpanded, setThoughtExpanded] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(message.content || "");
      setCopied(true);
      toast.success(t("copied"));
      window.setTimeout(() => setCopied(false), 1800);
    } catch {
      // Clipboard unavailable
    }
  };

  const getToolLabel = (toolName: string) =>
    KNOWN_TOOLS.has(toolName) ? t(`tools.${toolName}`) : t("tools.fallback");

  const timeStr = message.createdAt ? formatTimestamp(message.createdAt, locale) : "";

  if (message.role === "user") {
    return (
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] as const }}
        className="group flex flex-col items-end gap-1.5"
      >
        {message.attachments && message.attachments.length > 0 && (
          <div className="flex flex-wrap justify-end gap-1.5 max-w-[88%] sm:max-w-[74%]">
            {message.attachments.map((att) => (
              <AttachmentPreviewChip key={att.id} attachment={att} compact />
            ))}
          </div>
        )}
        <div className="max-w-[88%] sm:max-w-[74%] rounded-2xl rounded-ee-md bg-gradient-to-br from-[var(--primary)] to-[var(--primary-hover)] text-white px-4 py-3 text-[14.5px] leading-relaxed shadow-md shadow-[var(--glow-color)] whitespace-pre-wrap">
          {message.content}
        </div>
        <div className="flex items-center gap-2 px-1 text-[10px] text-gray-400 dark:text-gray-500">
          {timeStr && <span>{timeStr}</span>}
          <button
            type="button"
            onClick={handleCopy}
            className="opacity-0 group-hover:opacity-100 focus:opacity-100 inline-flex items-center gap-1 rounded px-1.5 py-0.5 hover:bg-gray-100 dark:hover:bg-white/5 hover:text-gray-700 dark:hover:text-gray-200 transition-all"
            title={t("copy")}
          >
            {copied ? (
              <Check className="h-3 w-3 text-emerald-500" />
            ) : (
              <Copy className="h-3 w-3" />
            )}
            <span>{copied ? t("copied") : t("copy")}</span>
          </button>
        </div>
      </motion.div>
    );
  }

  const renderEvidenceChip = (ev: AiEvidenceItem, idx: number) => {
    const href = ev.href || "/dashboard";
    const formattedAmount =
      ev.amount != null && ev.currency ? formatCurrency(Number(ev.amount), ev.currency) : null;

    return (
      <Link
        key={`${ev.type}-${ev.id}-${idx}`}
        href={href}
        className="group flex items-center justify-between gap-2.5 rounded-xl border border-gray-200/80 dark:border-gray-800/90 bg-[var(--surface-inset)] hover:border-[var(--primary)]/50 hover:bg-[var(--primary)]/5 px-3 py-2.5 text-xs transition-all"
      >
        <div className="min-w-0">
          <div className="flex items-center gap-1.5">
            <span
              className={`px-1.5 py-0.5 rounded-md border text-[9px] font-bold uppercase ${getEvidenceBadgeClass(
                ev.type
              )}`}
            >
              {ev.type}
            </span>
            <span className="font-semibold text-gray-900 dark:text-white truncate">{ev.title}</span>
          </div>
          {ev.subtitle && (
            <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-1">
              {ev.subtitle}
              {ev.date ? ` • ${ev.date}` : ""}
            </p>
          )}
        </div>
        <div className="flex items-center gap-1.5 shrink-0">
          {formattedAmount && (
            <span className="font-bold tabular-nums text-gray-900 dark:text-white text-[11px]">
              {formattedAmount}
            </span>
          )}
          <ArrowUpRight className="h-3.5 w-3.5 text-gray-400 group-hover:text-[var(--primary)] group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform rtl:rotate-180" />
        </div>
      </Link>
    );
  };

  const latencySec =
    message.latencyMs != null && message.latencyMs > 0
      ? (message.latencyMs / 1000).toFixed(1)
      : null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] as const }}
      className="flex items-start gap-3"
    >
      {/* Copilot Avatar Badge */}
      <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[var(--primary)]/15 to-[#10b981]/10 border border-[var(--primary)]/25 text-[var(--primary)] mt-0.5 shadow-2xs">
        <Sparkles className="h-4 w-4" />
      </div>

      {/* Assistant Card */}
      <div className="flex-1 min-w-0 space-y-3 rounded-2xl rounded-ss-md border border-gray-200/90 dark:border-gray-800/80 bg-[var(--card)] p-4 sm:p-5 shadow-xs">
        {/* Meta Header */}
        <div className="flex flex-wrap items-center justify-between gap-2 pb-2 border-b border-gray-100 dark:border-gray-800/70">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs font-bold text-gray-900 dark:text-white">
              {t("copilotName")}
            </span>
            {message.modelId && (
              <span className="rounded-md bg-gray-100 dark:bg-white/[0.06] px-1.5 py-0.5 font-mono text-[10px] font-medium text-gray-500 dark:text-gray-400">
                {message.modelId}
              </span>
            )}
            {message.reasoningMode === "deep" && (
              <span className="inline-flex items-center gap-1 rounded-md bg-[var(--primary)]/10 px-1.5 py-0.5 text-[10px] font-bold text-[var(--primary)]">
                <Brain className="h-2.5 w-2.5" />
                {t("deepModeBadge")}
              </span>
            )}
            {latencySec && (
              <span className="text-[10px] font-medium tabular-nums text-gray-400 dark:text-gray-500">
                {t("elapsedSeconds", { seconds: latencySec })}
              </span>
            )}
          </div>
          {timeStr && (
            <span className="text-[10px] text-gray-400 dark:text-gray-500">{timeStr}</span>
          )}
        </div>

        {/* Collapsible Deep Reasoning Trace */}
        {message.thinkingContent && (
          <div className="rounded-xl border border-gray-200/80 dark:border-gray-800 bg-[var(--surface-inset)]">
            <button
              type="button"
              onClick={() => setThoughtExpanded((v) => !v)}
              className="w-full flex items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold text-gray-600 dark:text-gray-300 hover:text-[var(--primary)] transition-colors"
            >
              <span className="inline-flex items-center gap-1.5">
                <Brain className="h-3.5 w-3.5 text-[var(--primary)]" />
                <span>{t("reasoningTrace")}</span>
              </span>
              {thoughtExpanded ? (
                <ChevronDown className="h-3.5 w-3.5" />
              ) : (
                <ChevronRight className="h-3.5 w-3.5" />
              )}
            </button>
            {thoughtExpanded && (
              <div className="px-3 pb-3 pt-1 text-[11.5px] text-gray-600 dark:text-gray-400 whitespace-pre-wrap leading-relaxed border-t border-gray-200/60 dark:border-gray-800/60 max-h-60 overflow-y-auto custom-scrollbar">
                {message.thinkingContent}
              </div>
            )}
          </div>
        )}

        {/* Tools Used Pill Strip */}
        {message.toolsUsed && message.toolsUsed.length > 0 && (
          <div className="flex flex-wrap items-center gap-1.5">
            {message.toolsUsed.map((tool) => (
              <span
                key={tool}
                className="inline-flex items-center gap-1 rounded-full border border-emerald-500/25 bg-emerald-500/[0.08] px-2.5 py-0.5 text-[10.5px] font-semibold text-emerald-700 dark:text-emerald-300"
              >
                <Wrench className="h-2.5 w-2.5 text-emerald-500" />
                {getToolLabel(tool)}
              </span>
            ))}
          </div>
        )}

        {/* Executive Markdown Body */}
        <CopilotMarkdown content={message.content} />

        {/* Interactive Recharts Visualizations */}
        {message.charts && message.charts.length > 0 && (
          <div className="space-y-3 pt-1">
            {message.charts.map((chart) => (
              <CopilotChartCard key={chart.id} chart={chart} />
            ))}
          </div>
        )}

        {/* Human-in-the-Loop Action Drafts, Payment Reminders & Memory Proposals */}
        {message.actionDrafts && message.actionDrafts.length > 0 && (
          <div className="space-y-2.5 pt-1">
            {message.actionDrafts.map((draft) => {
              const handleDraftUpdate = (updated: AiActionDraft) => {
                onDraftUpdated?.(message.id, updated);
              };
              if (draft.actionType === "PAYMENT_REMINDER") {
                return <CopilotReminderCard key={draft.draftId} draft={draft} />;
              }
              if (draft.actionType === "SAVE_MEMORY") {
                return (
                  <CopilotMemoryProposalCard
                    key={draft.draftId}
                    messageId={message.id}
                    draft={draft}
                    onUpdated={handleDraftUpdate}
                  />
                );
              }
              return (
                <CopilotActionDraftCard
                  key={draft.draftId}
                  messageId={message.id}
                  draft={draft}
                  onUpdated={handleDraftUpdate}
                />
              );
            })}
          </div>
        )}

        {/* Verified Evidence Cards Grid */}
        {message.evidence && message.evidence.length > 0 && (
          <div className="pt-3 border-t border-gray-100 dark:border-gray-800/80 space-y-2">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-1.5 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                <Database className="h-3.5 w-3.5 text-[var(--primary)]" />
                <span>{t("evidenceTitle")}</span>
              </div>
              <span className="text-[10px] font-semibold text-[var(--primary)]">
                {t("sourcesCount", { count: message.evidence.length })}
              </span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {message.evidence.map((ev, idx) => renderEvidenceChip(ev, idx))}
            </div>
          </div>
        )}

        {/* Footer Actions & Telemetry */}
        <div className="flex flex-wrap items-center justify-between gap-2 pt-2.5 border-t border-gray-100 dark:border-gray-800/70 text-[11px] text-gray-400">
          <span className="inline-flex items-center gap-1.5 min-w-0">
            <CheckCircle2 className="h-3.5 w-3.5 text-emerald-500 shrink-0" />
            <span className="truncate">
              {message.dataCoverage === "rag_context_only"
                ? t("coverageRag")
                : t("coveragePartial")}
            </span>
          </span>

          <div className="flex items-center gap-1.5 shrink-0">
            <button
              type="button"
              onClick={handleCopy}
              className="inline-flex items-center gap-1 rounded-lg border border-gray-200/80 dark:border-gray-800 px-2 py-1 text-[11px] font-medium text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/[0.05] hover:text-gray-800 dark:hover:text-white transition-colors"
              title={t("copy")}
            >
              {copied ? (
                <>
                  <Check className="h-3 w-3 text-emerald-500" />
                  <span className="text-emerald-600 dark:text-emerald-400">{t("copied")}</span>
                </>
              ) : (
                <>
                  <Copy className="h-3 w-3" />
                  <span>{t("copy")}</span>
                </>
              )}
            </button>

            {isLatestAssistant && canRegenerate && onRegenerate && (
              <button
                type="button"
                onClick={onRegenerate}
                className="inline-flex items-center gap-1 rounded-lg border border-gray-200/80 dark:border-gray-800 px-2 py-1 text-[11px] font-medium text-gray-500 dark:text-gray-400 hover:border-[var(--primary)]/40 hover:bg-[var(--primary)]/5 hover:text-[var(--primary)] transition-colors"
                title={t("regenerate")}
              >
                <RotateCcw className="h-3 w-3" />
                <span>{t("regenerate")}</span>
              </button>
            )}

            {message.totalTokens > 0 && (
              <span className="px-2 py-0.5 rounded-lg bg-gray-100 dark:bg-white/[0.05] font-semibold tabular-nums text-gray-500 dark:text-gray-400">
                {t("tokensUsedBadge", { tokens: formatCompactNumber(message.totalTokens, locale) })}
              </span>
            )}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
