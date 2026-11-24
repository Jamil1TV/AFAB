"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import {
  Brain,
  ExternalLink,
  Loader2,
  Paperclip,
  Send,
  Sparkles,
  Square,
  Upload,
  X,
  Zap,
} from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import {
  AiActionDraft,
  AiAttachmentItem,
  AiMessageItem,
  AiReasoningMode,
  AiService,
} from "@/lib/api/ai";
import { ApiError } from "@/lib/api/client";
import { compressImageFile } from "@/lib/image-compress";
import { useCopilot } from "@/components/ai/CopilotContextProvider";
import { CopilotMessageBubble } from "@/components/ai/CopilotMessageBubble";
import { CopilotThinkingCard, CompletedToolInfo } from "@/components/ai/CopilotThinkingCard";
import { AttachmentPreviewChip } from "@/components/ai/AttachmentPreviewChip";
import { VoiceDictationButton } from "@/components/ai/VoiceDictationButton";
import { toast } from "sonner";

interface StagedChip {
  attachment: AiAttachmentItem;
  localPreviewUrl?: string;
}

const ACCEPTED_FILE_TYPES =
  "image/jpeg,image/png,image/webp,application/pdf,.xlsx,.csv,.txt,.json,.md";

export function GlobalCopilotDrawer() {
  const { isOpen, closeCopilot, launchRequest, clearLaunchRequest } = useCopilot();
  const t = useTranslations("AI");
  const locale = useLocale();
  const isAr = locale === "ar";

  const [conversationId, setConversationId] = useState<string | null>(null);
  const [messages, setMessages] = useState<AiMessageItem[]>([]);
  const [input, setInput] = useState("");
  const [interimVoice, setInterimVoice] = useState("");
  const [reasoningMode, setReasoningMode] = useState<AiReasoningMode>("fast");
  const [staged, setStaged] = useState<StagedChip[]>([]);
  const [uploadingFile, setUploadingFile] = useState(false);
  const [dragActive, setDragActive] = useState(false);

  const [sending, setSending] = useState(false);
  const [streamingText, setStreamingText] = useState("");
  const [thinkingText, setThinkingText] = useState("");
  const [streamPhase, setStreamPhase] = useState<string | null>(null);
  const [activeTools, setActiveTools] = useState<string[]>([]);
  const [completedTools, setCompletedTools] = useState<CompletedToolInfo[]>([]);
  const [followUps, setFollowUps] = useState<string[]>([]);

  const abortRef = useRef<AbortController | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const bottomRef = useRef<HTMLDivElement | null>(null);
  const pendingScreenContextRef = useRef<Record<string, string> | undefined>(undefined);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, streamingText, thinkingText, activeTools, isOpen]);

  const stageFiles = useCallback(async (files: FileList | File[]) => {
    const arr = Array.from(files);
    if (arr.length === 0) return;
    setUploadingFile(true);
    try {
      for (const rawFile of arr.slice(0, 3)) {
        const prepared = await compressImageFile(rawFile);
        const uploaded = await AiService.stageAttachment(prepared);
        const localUrl = uploaded.kind === "IMAGE" ? URL.createObjectURL(prepared) : undefined;
        setStaged((prev) => [...prev.slice(0, 2), { attachment: uploaded, localPreviewUrl: localUrl }]);
      }
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : t("attachments.uploadFailed"));
    } finally {
      setUploadingFile(false);
    }
  }, [t]);

  const handleSend = useCallback(
    async (promptOverride?: string, modeOverride?: AiReasoningMode, screenContextOverride?: Record<string, string>) => {
      const text = (promptOverride ?? input).trim();
      const currentStaged = staged;
      if ((!text && currentStaged.length === 0) || sending) return;

      const activeMode = modeOverride ?? reasoningMode;
      const usedContext = screenContextOverride ?? pendingScreenContextRef.current;
      pendingScreenContextRef.current = undefined;

      setInput("");
      setInterimVoice("");
      setStaged([]);
      setSending(true);
      setStreamingText("");
      setThinkingText("");
      setStreamPhase("retrieving");
      setActiveTools([]);
      setCompletedTools([]);
      setFollowUps([]);

      const optimisticUser: AiMessageItem = {
        id: `drawer-user-${Date.now()}`,
        role: "user",
        content: text || `[${currentStaged.map((s) => s.attachment.originalFilename).join(", ")}]`,
        evidence: [],
        toolsUsed: [],
        attachments: currentStaged.map((s) => s.attachment),
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
        createdAt: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, optimisticUser]);

      const controller = new AbortController();
      abortRef.current = controller;
      let accDelta = "";
      let accThought = "";

      try {
        const donePayload = await AiService.streamChat(
          {
            message: text,
            conversationId,
            locale,
            reasoningMode: activeMode,
            attachmentIds: currentStaged.map((s) => s.attachment.id),
            screenContext: usedContext,
          },
          {
            signal: controller.signal,
            onStatus: (phase) => setStreamPhase(phase),
            onThought: (th) => {
              accThought += th;
              setThinkingText(accThought);
            },
            onToolStart: (tool) =>
              setActiveTools((prev) => (prev.includes(tool) ? prev : [...prev, tool])),
            onToolDone: (tool, evidenceCount) => {
              setActiveTools((prev) => prev.filter((x) => x !== tool));
              setCompletedTools((prev) => [...prev, { tool, evidenceCount }]);
            },
            onDelta: (delta) => {
              accDelta += delta;
              setStreamingText(accDelta);
            },
            onReplace: (replaced) => {
              accDelta = replaced;
              setStreamingText(replaced);
            },
          }
        );

        if (donePayload) {
          setConversationId(donePayload.conversationId);
          const assistantMsg: AiMessageItem = {
            id: donePayload.messageId,
            role: "assistant",
            content: donePayload.content,
            thinkingContent: donePayload.thinkingContent,
            evidence: donePayload.evidence || [],
            toolsUsed: donePayload.toolsUsed || [],
            charts: donePayload.charts || [],
            actionDrafts: donePayload.actionDrafts || [],
            dataCoverage: donePayload.dataCoverage,
            modelId: donePayload.modelId,
            reasoningMode: donePayload.reasoningMode,
            responseLanguage: donePayload.responseLanguage,
            promptTokens: donePayload.tokenUsage.promptTokens,
            completionTokens: donePayload.tokenUsage.completionTokens,
            totalTokens: donePayload.tokenUsage.totalTokens,
            latencyMs: donePayload.latencyMs,
            createdAt: donePayload.createdAt,
          };
          setMessages((prev) => [...prev, assistantMsg]);
          setFollowUps(donePayload.suggestedFollowUps || []);
        }
      } catch (err: unknown) {
        if ((err as { name?: string })?.name !== "AbortError") {
          setMessages((prev) => prev.filter((m) => m.id !== optimisticUser.id));
          setInput(text);
          if (err instanceof ApiError && err.code === "PLAN_LIMIT_REACHED" && activeMode === "deep") {
            setReasoningMode("fast");
          }
          toast.error(err instanceof Error ? err.message : "Failed to reach Copilot");
        }
      } finally {
        abortRef.current = null;
        setSending(false);
        setStreamingText("");
        setThinkingText("");
        setStreamPhase(null);
        setActiveTools([]);
        setCompletedTools([]);
      }
    },
    [input, staged, sending, reasoningMode, conversationId, locale]
  );

  useEffect(() => {
    if (!isOpen || !launchRequest) return;
    if (launchRequest.reasoningMode) {
      setReasoningMode(launchRequest.reasoningMode);
    }
    if (launchRequest.screenContext) {
      pendingScreenContextRef.current = launchRequest.screenContext;
    }
    if (launchRequest.prompt) {
      if (launchRequest.autoSend) {
        handleSend(launchRequest.prompt, launchRequest.reasoningMode, launchRequest.screenContext);
      } else {
        setInput(launchRequest.prompt);
      }
    }
    clearLaunchRequest();
  }, [isOpen, launchRequest, clearLaunchRequest, handleSend]);

  const handleDraftUpdated = (messageId: string, updated: AiActionDraft) => {
    setMessages((prev) =>
      prev.map((m) =>
        m.id !== messageId
          ? m
          : {
              ...m,
              actionDrafts: (m.actionDrafts || []).map((d) =>
                d.draftId === updated.draftId ? updated : d
              ),
            }
      )
    );
  };

  const slideOffset = isAr ? -520 : 520;

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          key="global-copilot-backdrop"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={closeCopilot}
          className="fixed inset-0 z-50 flex justify-end bg-black/50 backdrop-blur-xs"
        >
          <motion.div
            key="global-copilot-panel"
            initial={{ x: slideOffset }}
            animate={{ x: 0 }}
            exit={{ x: slideOffset }}
            transition={{ type: "spring", stiffness: 360, damping: 34 }}
            onClick={(e) => e.stopPropagation()}
            onDragOver={(e) => {
              e.preventDefault();
              setDragActive(true);
            }}
            onDragLeave={() => setDragActive(false)}
            onDrop={(e) => {
              e.preventDefault();
              setDragActive(false);
              if (e.dataTransfer.files?.length) {
                stageFiles(e.dataTransfer.files);
              }
            }}
            className="relative flex h-full w-full max-w-xl flex-col bg-[var(--card)] border-s border-gray-200 dark:border-gray-800 shadow-2xl"
          >
            {dragActive && (
              <div className="pointer-events-none absolute inset-3 z-30 flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-[var(--primary)] bg-[var(--card)]/90 backdrop-blur-md text-center p-6">
                <Upload className="h-8 w-8 text-[var(--primary)] mb-2" />
                <p className="text-sm font-bold text-gray-900 dark:text-white">
                  {t("attachments.dropHere")}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  {t("attachments.supportedHint")}
                </p>
              </div>
            )}

            {/* Header */}
            <div className="flex items-center justify-between gap-2 border-b border-gray-200 dark:border-gray-800 px-4 py-3">
              <div className="flex items-center gap-2.5 min-w-0">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-[var(--primary)]/15 text-[var(--primary)] border border-[var(--primary)]/25">
                  <Sparkles className="h-4 w-4" />
                </div>
                <div className="min-w-0">
                  <h2 className="text-sm font-bold text-gray-900 dark:text-white truncate">
                    {t("drawerTitle")}
                  </h2>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate">
                    {t("drawerSubtitle")}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-1.5 shrink-0">
                <Link
                  href="/dashboard/ai"
                  onClick={closeCopilot}
                  className="inline-flex items-center gap-1 rounded-lg border border-gray-200 dark:border-gray-800 px-2.5 py-1.5 text-[11px] font-semibold text-gray-600 dark:text-gray-300 hover:text-[var(--primary)] hover:border-[var(--primary)]/40"
                >
                  <span>{t("openWorkspace")}</span>
                  <ExternalLink className="h-3 w-3" />
                </Link>
                <button
                  type="button"
                  onClick={closeCopilot}
                  className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-white/10 dark:hover:text-white"
                  aria-label="Close"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
              {messages.length === 0 && !sending ? (
                <div className="rounded-2xl border border-dashed border-gray-200 dark:border-gray-800 bg-[var(--surface-inset)] p-6 text-center space-y-3 my-4">
                  <Sparkles className="h-7 w-7 text-[var(--primary)] mx-auto" />
                  <p className="text-sm font-bold text-gray-900 dark:text-white">
                    {t("drawerEmptyTitle")}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
                    {t("drawerEmptyDesc")}
                  </p>
                  <div className="flex flex-wrap justify-center gap-2 pt-1">
                    <button
                      type="button"
                      onClick={() => handleSend(t("morningBriefPrompt"))}
                      className="rounded-full border border-[var(--primary)]/30 bg-[var(--primary)]/10 px-3 py-1.5 text-xs font-semibold text-[var(--primary)] hover:bg-[var(--primary)]/20"
                    >
                      {t("morningBriefButton")}
                    </button>
                    <button
                      type="button"
                      onClick={() => handleSend(t("prompts.invoicesText"))}
                      className="rounded-full border border-gray-200 dark:border-gray-800 bg-[var(--card)] px-3 py-1.5 text-xs font-medium text-gray-700 dark:text-gray-300 hover:border-[var(--primary)]/40"
                    >
                      {t("prompts.invoicesTitle")}
                    </button>
                  </div>
                </div>
              ) : (
                messages.map((msg) => (
                  <CopilotMessageBubble
                    key={msg.id}
                    message={msg}
                    locale={locale}
                    onDraftUpdated={handleDraftUpdated}
                  />
                ))
              )}

              {sending && (
                <CopilotThinkingCard
                  activeTools={activeTools}
                  completedTools={completedTools}
                  streamingText={streamingText}
                  thinkingText={thinkingText}
                  streamPhase={streamPhase}
                />
              )}

              {!sending && followUps.length > 0 && (
                <div className="flex flex-wrap gap-1.5 pt-1">
                  {followUps.map((q) => (
                    <button
                      key={q}
                      type="button"
                      onClick={() => handleSend(q)}
                      className="inline-flex items-center gap-1 rounded-full border border-[var(--primary)]/25 bg-[var(--primary)]/[0.06] px-3 py-1 text-[11px] font-medium text-[var(--primary)] hover:bg-[var(--primary)]/15"
                    >
                      <Sparkles className="h-3 w-3 shrink-0" />
                      <span>{q}</span>
                    </button>
                  ))}
                </div>
              )}

              <div ref={bottomRef} />
            </div>

            {/* Composer */}
            <div className="border-t border-gray-200 dark:border-gray-800 p-3 bg-[var(--card)] space-y-2">
              {staged.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {staged.map((s) => (
                    <AttachmentPreviewChip
                      key={s.attachment.id}
                      attachment={s.attachment}
                      localPreviewUrl={s.localPreviewUrl}
                      compact
                      onRemove={() => {
                        if (s.localPreviewUrl) URL.revokeObjectURL(s.localPreviewUrl);
                        setStaged((prev) =>
                          prev.filter((item) => item.attachment.id !== s.attachment.id)
                        );
                      }}
                    />
                  ))}
                </div>
              )}

              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  handleSend();
                }}
                className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-[var(--surface-inset)] p-2 space-y-2"
              >
                <div className="flex items-end gap-1.5">
                  <input
                    ref={fileInputRef}
                    type="file"
                    multiple
                    accept={ACCEPTED_FILE_TYPES}
                    onChange={(e) => {
                      if (e.target.files?.length) stageFiles(e.target.files);
                      e.target.value = "";
                    }}
                    className="hidden"
                  />
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={sending || uploadingFile}
                    title={t("attachments.attachTitle")}
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-gray-500 hover:bg-[var(--primary)]/10 hover:text-[var(--primary)] disabled:opacity-50"
                  >
                    {uploadingFile ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Paperclip className="h-4 w-4" />
                    )}
                  </button>

                  <textarea
                    rows={1}
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onPaste={(e) => {
                      const files = e.clipboardData?.files;
                      if (files && files.length > 0) {
                        e.preventDefault();
                        stageFiles(files);
                      }
                    }}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" && !e.shiftKey) {
                        e.preventDefault();
                        handleSend();
                      }
                    }}
                    placeholder={interimVoice || t("placeholder")}
                    disabled={sending}
                    className="flex-1 min-h-[36px] max-h-28 bg-transparent px-1 py-1.5 text-xs text-gray-900 dark:text-white placeholder:text-gray-400 focus:outline-none resize-none"
                    dir={isAr ? "rtl" : "auto"}
                  />

                  <VoiceDictationButton
                    defaultLocale={locale}
                    disabled={sending}
                    onInterimChange={setInterimVoice}
                    onTranscript={(spoken) =>
                      setInput((prev) => (prev.trim() ? `${prev.trim()} ${spoken}` : spoken))
                    }
                  />

                  {sending ? (
                    <button
                      type="button"
                      onClick={() => abortRef.current?.abort()}
                      className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-red-600 text-white"
                      aria-label={t("stop")}
                    >
                      <Square className="h-3.5 w-3.5 fill-current" />
                    </button>
                  ) : (
                    <button
                      type="submit"
                      disabled={!input.trim() && staged.length === 0}
                      className="afab-btn-primary h-9 px-3 text-xs shrink-0"
                    >
                      <Send className="h-3.5 w-3.5 rtl:rotate-180" />
                    </button>
                  )}
                </div>

                <div className="flex items-center justify-between gap-2 px-1 text-[10.5px] text-gray-400">
                  <div className="inline-flex items-center gap-1 rounded-lg bg-[var(--card)] border border-gray-200 dark:border-gray-800 p-0.5">
                    <button
                      type="button"
                      onClick={() => setReasoningMode("fast")}
                      className={`inline-flex items-center gap-1 rounded-md px-2 py-0.5 font-semibold transition-colors ${
                        reasoningMode === "fast"
                          ? "bg-[var(--primary)] text-white"
                          : "text-gray-500"
                      }`}
                    >
                      <Zap className="h-2.5 w-2.5" />
                      <span>{t("fastMode")}</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setReasoningMode("deep")}
                      className={`inline-flex items-center gap-1 rounded-md px-2 py-0.5 font-semibold transition-colors ${
                        reasoningMode === "deep"
                          ? "bg-[var(--primary)] text-white"
                          : "text-gray-500"
                      }`}
                    >
                      <Brain className="h-2.5 w-2.5" />
                      <span>{t("deepMode")}</span>
                    </button>
                  </div>
                  <span className="truncate">{t("attachments.supportedHint")}</span>
                </div>
              </form>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
