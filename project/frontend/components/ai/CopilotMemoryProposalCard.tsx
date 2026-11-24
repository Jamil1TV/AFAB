"use client";

import { useState } from "react";
import { Brain, Check, Loader2, X } from "lucide-react";
import { useTranslations } from "next-intl";
import { AiActionDraft, AiService } from "@/lib/api/ai";
import { toast } from "sonner";

interface CopilotMemoryProposalCardProps {
  messageId: string;
  draft: AiActionDraft;
  onUpdated: (updated: AiActionDraft) => void;
}

export function CopilotMemoryProposalCard({
  messageId,
  draft,
  onUpdated,
}: CopilotMemoryProposalCardProps) {
  const t = useTranslations("AI.memoryProposal");
  const p = draft.payload || {};
  const [title, setTitle] = useState(String(p.title || draft.summary || ""));
  const [content, setContent] = useState(String(p.content || ""));
  const [busy, setBusy] = useState(false);

  if (draft.status === "APPROVED") {
    return (
      <div className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 px-3 py-2 text-xs text-emerald-700 dark:text-emerald-300 flex items-center gap-2">
        <Check className="h-3.5 w-3.5 text-emerald-500 shrink-0" />
        <span className="font-semibold truncate">{t("saved")}: {title}</span>
      </div>
    );
  }
  if (draft.status === "DISMISSED") {
    return null;
  }

  const handleSave = async () => {
    if (busy || !title.trim() || !content.trim()) return;
    setBusy(true);
    try {
      const updated = await AiService.approveMemoryDraft({
        messageId,
        draftId: draft.draftId,
        memoryType: String(p.memoryType || "TRANSACTION_CONTEXT"),
        title: title.trim(),
        content: content.trim(),
      });
      toast.success(t("saved"));
      onUpdated(updated);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : t("saveFailed"));
    } finally {
      setBusy(false);
    }
  };

  const handleDismiss = async () => {
    if (busy) return;
    setBusy(true);
    try {
      const updated = await AiService.dismissDraft(messageId, draft.draftId);
      onUpdated(updated);
    } catch {
      // ignore
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="rounded-2xl border border-indigo-500/30 bg-[var(--surface-inset)] p-3.5 space-y-2 text-xs">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-1.5 font-bold text-indigo-600 dark:text-indigo-400">
          <Brain className="h-3.5 w-3.5" />
          <span>{t("heading")}</span>
        </div>
        <button
          type="button"
          onClick={handleDismiss}
          disabled={busy}
          className="p-1 rounded-lg text-gray-400 hover:text-red-500"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </div>
      <input
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        className="afab-input py-1 text-xs font-semibold"
      />
      <textarea
        rows={2}
        value={content}
        onChange={(e) => setContent(e.target.value)}
        className="afab-input py-1.5 text-xs resize-none"
      />
      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={handleDismiss}
          disabled={busy}
          className="afab-btn-secondary px-2.5 py-1 text-[11px]"
        >
          {t("ignore")}
        </button>
        <button
          type="button"
          onClick={handleSave}
          disabled={busy}
          className="afab-btn-primary px-3 py-1 text-[11px]"
        >
          {busy ? <Loader2 className="h-3 w-3 animate-spin" /> : <Check className="h-3 w-3" />}
          <span>{t("remember")}</span>
        </button>
      </div>
    </div>
  );
}
