"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import {
  ArrowUp,
  Brain,
  ExternalLink,
  Loader2,
  Paperclip,
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
            className="relative flex h-full w-full max-w-xl flex-col bg-[var(--card)] border-s border-[var(--border)] shadow-2xl"
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
            <div className="flex items-center justify-between gap-2 border-b border-[var(--border)] px-4 py-3">
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

            {/* Two-Zone Composer */}
            <div className="border-t border-[var(--border)] p-3 bg-[var(--card)] space-y-1.5">
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  handleSend();
                }}
                className="rounded-2xl border border-[var(--border)] bg-[var(--surface-inset)] shadow-sm focus-within:border-[var(--primary)]/70 focus-within:ring-2 focus-within:ring-[var(--primary)]/15 transition-all"
              >
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

                {staged.length > 0 && (
                  <div className="flex flex-wrap gap-1.5 px-2.5 pt-2.5">
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

                {interimVoice && (
                  <div className="px-3 pt-2">
                    <div className="inline-flex items-center gap-1.5 rounded-full border border-red-500/25 bg-red-500/10 px-2 py-0.5 text-[10.5px] font-medium text-red-500 max-w-full">
                      <span className="h-1.5 w-1.5 rounded-full bg-red-500 animate-ping shrink-0" />
                      <span className="font-bold shrink-0">{t("listeningLabel")}:</span>
                      <span className="truncate">{interimVoice}</span>
                    </div>
                  </div>
                )}

                {/* Zone 1: Full-width non-clipping textarea */}
                <div className="px-3 pt-2 pb-1">
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
                    placeholder={t("placeholder")}
                    disabled={sending}
                    className="w-full min-h-[36px] max-h-28 bg-transparent py-1 text-xs leading-5 text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none resize-none"
                    dir={isAr ? "rtl" : "auto"}
                  />
                </div>

                {/* Zone 2: Unified Bottom Action Bar */}
                <div className="px-2 pb-2 pt-0.5 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={sending || uploadingFile}
                      title={t("attachments.attachTitle")}
                      aria-label={t("attachments.attachTitle")}
                      className="h-8 px-2 rounded-xl border border-[var(--border)] bg-[var(--card)] text-[11px] font-medium inline-flex items-center gap-1 text-gray-600 dark:text-gray-300 hover:border-[var(--primary)]/45 hover:text-[var(--primary)] disabled:opacity-50 transition-colors"
                    >
                      {uploadingFile ? (
                        <Loader2 className="h-3.5 w-3.5 animate-spin text-[var(--primary)]" />
                      ) : (
                        <Paperclip className="h-3.5 w-3.5" />
                      )}
                      <span className="hidden sm:inline">{t("attachLabel")}</span>
                    </button>

                    <div className="h-8 inline-flex items-center rounded-xl border border-[var(--border)] bg-[var(--card)] p-0.5">
                      <button
                        type="button"
                        onClick={() => setReasoningMode("fast")}
                        className={`inline-flex h-7 items-center gap-1 rounded-lg px-2 text-[10.5px] transition-colors ${
                          reasoningMode === "fast"
                            ? "bg-[var(--primary)]/15 text-[var(--primary)] ring-1 ring-[var(--primary)]/25 font-semibold"
                            : "font-medium text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
                        }`}
                      >
                        <Zap className="h-2.5 w-2.5" />
                        <span>{t("fastMode")}</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setReasoningMode("deep")}
                        className={`inline-flex h-7 items-center gap-1 rounded-lg px-2 text-[10.5px] transition-colors ${
                          reasoningMode === "deep"
                            ? "bg-[var(--primary)]/15 text-[var(--primary)] ring-1 ring-[var(--primary)]/25 font-semibold"
                            : "font-medium text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
                        }`}
                      >
                        <Brain className="h-2.5 w-2.5" />
                        <span>{t("deepMode")}</span>
                      </button>
                    </div>
                  </div>

                  <div className="flex items-center gap-1.5">
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
                        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-red-500/15 border border-red-500/30 text-red-500 hover:bg-red-500 hover:text-white transition-colors"
                        aria-label={t("stop")}
                      >
                        <Square className="h-3 w-3 fill-current" />
                      </button>
                    ) : (
                      <button
                        type="submit"
                        disabled={!input.trim() && staged.length === 0}
                        className={
                          input.trim() || staged.length > 0
                            ? "h-8 px-3 rounded-xl bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white text-xs font-semibold shadow-sm shadow-[var(--glow-color)] inline-flex items-center gap-1 shrink-0 transition-all"
                            : "h-8 px-3 rounded-xl bg-gray-200/80 dark:bg-white/[0.06] text-gray-400 dark:text-gray-500 text-xs font-semibold inline-flex items-center gap-1 shrink-0 cursor-not-allowed"
                        }
                        aria-label={t("send")}
                      >
                        <ArrowUp className="h-3.5 w-3.5" />
                      </button>
                    )}
                  </div>
                </div>
              </form>

              <p className="px-1 text-[10px] text-gray-400 dark:text-gray-500 truncate">
                {t("attachments.supportedHint")}
              </p>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
