"use client";

import { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { useLocale, useTranslations } from "next-intl";
import { AnimatePresence, motion } from "framer-motion";
import { Link } from "@/i18n/routing";
import {
  AlertTriangle,
  ArrowDown,
  ArrowUp,
  Brain,
  ExternalLink,
  Loader2,
  Menu,
  MessageSquare,
  PanelLeftClose,
  PanelLeftOpen,
  Paperclip,
  Plus,
  RefreshCw,
  Search,
  Sparkles,
  Square,
  Trash2,
  Upload,
  X,
  Zap,
} from "lucide-react";
import {
  AiActionDraft,
  AiAttachmentItem,
  AiService,
  AiStatusResponse,
  AiHealthResponse,
  AiConversationSummary,
  AiMessageItem,
  AiReasoningMode,
  BusinessMemoryItem,
} from "@/lib/api/ai";
import { ApiError } from "@/lib/api/client";
import { compressImageFile } from "@/lib/image-compress";
import { CopilotWelcome } from "@/components/ai/CopilotWelcome";
import {
  CopilotThinkingCard,
  CompletedToolInfo,
} from "@/components/ai/CopilotThinkingCard";
import { CopilotMessageBubble } from "@/components/ai/CopilotMessageBubble";
import { BusinessMemoryDrawer } from "@/components/ai/BusinessMemoryDrawer";
import { AiModelStatusBadge } from "@/components/ai/AiModelStatusBadge";
import { AttachmentPreviewChip } from "@/components/ai/AttachmentPreviewChip";
import { VoiceDictationButton } from "@/components/ai/VoiceDictationButton";
import { AfabLoader } from "@/components/ui/afab-loader";
import { toast } from "sonner";

interface StagedChip {
  attachment: AiAttachmentItem;
  localPreviewUrl?: string;
}

const ACCEPTED_FILE_TYPES =
  "image/jpeg,image/png,image/webp,application/pdf,.xlsx,.csv,.txt,.json,.md";

function formatNumber(n: number, locale: string): string {
  try {
    return new Intl.NumberFormat(locale === "ar" ? "ar-TN" : "en-US").format(n);
  } catch {
    return String(n);
  }
}

type DateGroupKey = "today" | "yesterday" | "week" | "earlier";

function groupConversationsByDate(
  items: AiConversationSummary[],
  todayStartMs: number | null
): Record<DateGroupKey, AiConversationSummary[]> {
  const groups: Record<DateGroupKey, AiConversationSummary[]> = {
    today: [],
    yesterday: [],
    week: [],
    earlier: [],
  };

  if (todayStartMs == null) {
    groups.today = items;
    return groups;
  }

  const yesterdayStart = todayStartMs - 86_400_000;
  const weekStart = todayStartMs - 7 * 86_400_000;

  for (const conv of items) {
    const ts = new Date(conv.updatedAt || conv.createdAt).getTime();
    if (Number.isNaN(ts) || ts >= todayStartMs) {
      groups.today.push(conv);
    } else if (ts >= yesterdayStart) {
      groups.yesterday.push(conv);
    } else if (ts >= weekStart) {
      groups.week.push(conv);
    } else {
      groups.earlier.push(conv);
    }
  }
  return groups;
}

export default function AfabCopilotPage() {
  const t = useTranslations("AI");
  const locale = useLocale();
  const isAr = locale === "ar";

  const [status, setStatus] = useState<AiStatusResponse | null>(null);
  const [health, setHealth] = useState<AiHealthResponse | null>(null);
  const [backendConnected, setBackendConnected] = useState(true);
  const [checkingHealth, setCheckingHealth] = useState(false);
  const [streamPhase, setStreamPhase] = useState<string | null>(null);
  const [conversations, setConversations] = useState<AiConversationSummary[]>([]);
  const [memories, setMemories] = useState<BusinessMemoryItem[]>([]);
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null);
  const [activeLanguage, setActiveLanguage] = useState<string | null>(null);
  const [messages, setMessages] = useState<AiMessageItem[]>([]);
  const [suggestedFollowUps, setSuggestedFollowUps] = useState<string[]>([]);
  const [todayStartMs, setTodayStartMs] = useState<number | null>(null);

  const [input, setInput] = useState("");
  const [interimVoice, setInterimVoice] = useState("");
  const [reasoningMode, setReasoningMode] = useState<AiReasoningMode>("fast");
  const [stagedAttachments, setStagedAttachments] = useState<StagedChip[]>([]);
  const [uploadingFile, setUploadingFile] = useState(false);
  const [dragActive, setDragActive] = useState(false);

  const [searchQuery, setSearchQuery] = useState("");
  const [sending, setSending] = useState(false);
  const [streamingText, setStreamingText] = useState("");
  const [thinkingText, setThinkingText] = useState("");
  const [activeTools, setActiveTools] = useState<string[]>([]);
  const [completedTools, setCompletedTools] = useState<CompletedToolInfo[]>([]);
  const [quotaExhaustedMsg, setQuotaExhaustedMsg] = useState<string | null>(null);
  const [chatError, setChatError] = useState<string | null>(null);

  const [loadingPage, setLoadingPage] = useState(true);
  const [syncingIndex, setSyncingIndex] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [memoryDrawerOpen, setMemoryDrawerOpen] = useState(false);
  const [mobileHistoryOpen, setMobileHistoryOpen] = useState(false);
  const [showScrollToBottom, setShowScrollToBottom] = useState(false);

  const abortRef = useRef<AbortController | null>(null);
  const scrollContainerRef = useRef<HTMLDivElement | null>(null);
  const bottomRef = useRef<HTMLDivElement | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    let active = true;
    Promise.all([
      AiService.getStatus(),
      AiService.listConversations().catch(() => []),
      AiService.listMemory("ALL").catch(() => []),
    ])
      .then(([statusRes, convsRes, memRes]) => {
        if (!active) return;
        const todayMidnight = new Date();
        todayMidnight.setHours(0, 0, 0, 0);
        setTodayStartMs(todayMidnight.getTime());
        setStatus(statusRes);
        setConversations(convsRes || []);
        setMemories(memRes || []);
      })
      .catch(() => {})
      .finally(() => {
        if (active) setLoadingPage(false);
      });
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    const unsub = AiService.subscribeHealth({
      onHealth: (liveHealth) => {
        setHealth(liveHealth);
        setBackendConnected(true);
        setStatus((prev) =>
          prev
            ? {
                ...prev,
                ollamaReachable: liveHealth.ollamaReachable,
                chatModelReady: liveHealth.chatModelReady,
                embedModelReady: liveHealth.embedModelReady,
                chatModelLoaded: liveHealth.chatModelLoaded,
                busy: liveHealth.busy,
                latencyMs: liveHealth.latencyMs,
              }
            : prev
        );
      },
      onConnectionChange: (connected) => {
        setBackendConnected(connected);
      },
    });

    return () => {
      unsub();
    };
  }, []);

  const handleManualHealthCheck = useCallback(async () => {
    if (checkingHealth) return;
    setCheckingHealth(true);
    try {
      const freshHealth = await AiService.getHealth(true);
      setHealth(freshHealth);
      setBackendConnected(true);
      setStatus((prev) =>
        prev
          ? {
              ...prev,
              ollamaReachable: freshHealth.ollamaReachable,
              chatModelReady: freshHealth.chatModelReady,
              embedModelReady: freshHealth.embedModelReady,
              chatModelLoaded: freshHealth.chatModelLoaded,
              busy: freshHealth.busy,
              latencyMs: freshHealth.latencyMs,
            }
          : prev
      );
      toast.success(t("liveStatus.badgeTitle"));
    } catch (err: unknown) {
      setBackendConnected(false);
      toast.error(err instanceof Error ? err.message : t("liveStatus.backendOffline"));
    } finally {
      setCheckingHealth(false);
    }
  }, [checkingHealth, t]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, streamingText, thinkingText, activeTools, completedTools]);

  useEffect(() => {
    const el = textareaRef.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${Math.min(el.scrollHeight, 160)}px`;
  }, [input]);

  const refreshMemoryAndStatus = useCallback(async () => {
    const [statusRes, memRes] = await Promise.all([
      AiService.getStatus(),
      AiService.listMemory("ALL"),
    ]);
    setStatus(statusRes);
    setMemories(memRes);
  }, []);

  const stageFiles = useCallback(
    async (files: FileList | File[]) => {
      const list = Array.from(files);
      if (list.length === 0) return;
      setUploadingFile(true);
      try {
        for (const raw of list.slice(0, 3)) {
          const prepared = await compressImageFile(raw);
          const uploaded = await AiService.stageAttachment(prepared);
          const localUrl =
            uploaded.kind === "IMAGE" ? URL.createObjectURL(prepared) : undefined;
          setStagedAttachments((prev) => [
            ...prev.slice(0, 2),
            { attachment: uploaded, localPreviewUrl: localUrl },
          ]);
        }
      } catch (err: unknown) {
        toast.error(err instanceof Error ? err.message : t("attachments.uploadFailed"));
      } finally {
        setUploadingFile(false);
      }
    },
    [t]
  );

  const handleMessagesScroll = () => {
    const el = scrollContainerRef.current;
    if (!el) return;
    const distanceFromBottom = el.scrollHeight - el.scrollTop - el.clientHeight;
    setShowScrollToBottom(distanceFromBottom > 140);
  };

  const scrollToBottom = () => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  const handleSelectConversation = async (id: string) => {
    setMobileHistoryOpen(false);
    setQuotaExhaustedMsg(null);
    setChatError(null);
    setActiveConversationId(id);
    try {
      const detail = await AiService.getConversation(id);
      setMessages(detail.messages || []);
      setActiveLanguage(detail.activeLanguage || null);
      setSuggestedFollowUps([]);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Unable to load conversation");
    }
  };

  const handleNewChat = () => {
    setActiveConversationId(null);
    setActiveLanguage(null);
    setMessages([]);
    setStreamingText("");
    setThinkingText("");
    setActiveTools([]);
    setCompletedTools([]);
    setSuggestedFollowUps([]);
    setQuotaExhaustedMsg(null);
    setChatError(null);
    setMobileHistoryOpen(false);
  };

  const handleDeleteConversation = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      await AiService.deleteConversation(id);
      setConversations((prev) => prev.filter((c) => c.id !== id));
      if (activeConversationId === id) {
        handleNewChat();
      }
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to delete conversation");
    }
  };

  const handleSyncIndex = async () => {
    if (syncingIndex) return;
    setSyncingIndex(true);
    try {
      const res = await AiService.syncIndex();
      toast.success(t("syncSuccess", { indexed: res.indexedCount, embeddings: res.embeddingsGenerated }));
      const nextStatus = await AiService.getStatus();
      setStatus(nextStatus);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : t("syncError"));
    } finally {
      setSyncingIndex(false);
    }
  };

  const handleStopStream = () => {
    abortRef.current?.abort();
    abortRef.current = null;
    setSending(false);
    setStreamPhase(null);
    setThinkingText("");
    setActiveTools([]);
    setCompletedTools([]);
  };

  const handleSend = async (promptOverride?: string) => {
    const text = (promptOverride ?? input).trim();
    const attached = stagedAttachments;
    if ((!text && attached.length === 0) || sending) return;

    setQuotaExhaustedMsg(null);
    setChatError(null);
    setInput("");
    setInterimVoice("");
    setStagedAttachments([]);
    setSending(true);
    setStreamPhase("retrieving");
    setStreamingText("");
    setThinkingText("");
    setActiveTools([]);
    setCompletedTools([]);
    setSuggestedFollowUps([]);

    const optimisticUserMsg: AiMessageItem = {
      id: `local-user-${new Date().getTime()}`,
      role: "user",
      content: text || `[Attached ${attached.map((a) => a.attachment.originalFilename).join(", ")}]`,
      evidence: [],
      toolsUsed: [],
      attachments: attached.map((a) => a.attachment),
      promptTokens: 0,
      completionTokens: 0,
      totalTokens: 0,
      createdAt: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, optimisticUserMsg]);

    const controller = new AbortController();
    abortRef.current = controller;
    let accumulated = "";
    let accumulatedThought = "";

    try {
      const donePayload = await AiService.streamChat(
        {
          message: text,
          conversationId: activeConversationId,
          locale,
          reasoningMode,
          attachmentIds: attached.map((a) => a.attachment.id),
        },
        {
          signal: controller.signal,
          onStatus: (phase, meta) => {
            setStreamPhase(phase);
            if (typeof meta?.activeLanguage === "string") {
              setActiveLanguage(meta.activeLanguage);
            }
          },
          onThought: (thoughtDelta) => {
            accumulatedThought += thoughtDelta;
            setThinkingText(accumulatedThought);
          },
          onToolStart: (tool) => {
            setActiveTools((prev) => (prev.includes(tool) ? prev : [...prev, tool]));
          },
          onToolDone: (tool, evidenceCount) => {
            setActiveTools((prev) => prev.filter((x) => x !== tool));
            setCompletedTools((prev) => [...prev, { tool, evidenceCount }]);
          },
          onDelta: (delta) => {
            accumulated += delta;
            setStreamingText(accumulated);
          },
          onReplace: (replacedText) => {
            accumulated = replacedText;
            setStreamingText(replacedText);
          },
        }
      );

      if (donePayload) {
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
        setStreamingText("");
        setThinkingText("");
        setActiveTools([]);
        setCompletedTools([]);
        setSuggestedFollowUps(donePayload.suggestedFollowUps || []);
        setActiveConversationId(donePayload.conversationId);
        if (donePayload.responseLanguage) {
          setActiveLanguage(donePayload.responseLanguage);
        }
        setStatus((prev) =>
          prev ? { ...prev, quota: donePayload.tokenUsage } : prev
        );
        AiService.getStatus()
          .then((nextStatus) => setStatus(nextStatus))
          .catch(() => {});
        AiService.listConversations()
          .then((convs) => setConversations(convs || []))
          .catch(() => {});
      }
    } catch (err: unknown) {
      if ((err as { name?: string })?.name === "AbortError") {
        setStreamingText("");
        setThinkingText("");
        return;
      }
      setMessages((prev) => prev.filter((m) => m.id !== optimisticUserMsg.id));
      setStreamingText("");
      setThinkingText("");
      setInput(text);

      if (err instanceof ApiError && err.code === "PLAN_LIMIT_REACHED") {
        setQuotaExhaustedMsg(err.message);
        if (reasoningMode === "deep") {
          setReasoningMode("fast");
        }
      } else {
        const msg = err instanceof Error ? err.message : "Failed to get Copilot response.";
        setChatError(msg);
        toast.error(msg);
      }
      AiService.getStatus()
        .then((nextStatus) => setStatus(nextStatus))
        .catch(() => {});
      AiService.listConversations()
        .then((convs) => setConversations(convs || []))
        .catch(() => {});
    } finally {
      abortRef.current = null;
      setSending(false);
      setStreamPhase(null);
      setActiveTools([]);
      setCompletedTools([]);
    }
  };

  const handleDraftUpdated = (messageId: string, updatedDraft: AiActionDraft) => {
    setMessages((prev) =>
      prev.map((m) =>
        m.id !== messageId
          ? m
          : {
              ...m,
              actionDrafts: (m.actionDrafts || []).map((d) =>
                d.draftId === updatedDraft.draftId ? updatedDraft : d
              ),
            }
      )
    );
  };

  const handleRegenerateFromIndex = (assistantIdx: number) => {
    if (sending) return;
    for (let idx = assistantIdx - 1; idx >= 0; idx--) {
      if (messages[idx]?.role === "user" && messages[idx].content.trim()) {
        handleSend(messages[idx].content);
        return;
      }
    }
  };

  const filteredConversations = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return conversations;
    return conversations.filter((c) => c.title.toLowerCase().includes(q));
  }, [conversations, searchQuery]);

  const groupedConversations = useMemo(
    () => groupConversationsByDate(filteredConversations, todayStartMs),
    [filteredConversations, todayStartMs]
  );

  let latestAssistantIdx = -1;
  for (let i = messages.length - 1; i >= 0; i--) {
    if (messages[i].role === "assistant") {
      latestAssistantIdx = i;
      break;
    }
  }

  const activeConversation = conversations.find((c) => c.id === activeConversationId);
  const quota = status?.quota;
  const tokensUsed = quota?.monthlyTokensUsed ?? 0;
  const tokensLimit = quota?.monthlyTokensLimit ?? 15000;
  const tokenPct = tokensLimit > 0 ? Math.min(100, Math.round((tokensUsed / tokensLimit) * 100)) : 0;
  const queriesUsed = quota?.monthlyQueriesUsed ?? 0;
  const queriesLimit = quota?.monthlyQueriesLimit ?? 10;

  const groupLabels: Record<DateGroupKey, string> = {
    today: t("groupToday"),
    yesterday: t("groupYesterday"),
    week: t("groupWeek"),
    earlier: t("groupEarlier"),
  };

  const renderConversationList = (isMobile = false) => {
    const groupOrder: DateGroupKey[] = ["today", "yesterday", "week", "earlier"];
    if (filteredConversations.length === 0) {
      return (
        <p className="text-xs text-gray-400 dark:text-gray-500 text-center py-8 px-2">
          {t("noConversations")}
        </p>
      );
    }

    return (
      <div className="space-y-4">
        {groupOrder.map((gKey) => {
          const groupItems = groupedConversations[gKey];
          if (groupItems.length === 0) return null;
          return (
            <div key={gKey} className="space-y-1">
              <div className="px-2 text-[10px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
                {groupLabels[gKey]}
              </div>
              {groupItems.map((c) => {
                const isActive = activeConversationId === c.id;
                return (
                  <div
                    key={c.id}
                    onClick={() => handleSelectConversation(c.id)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        handleSelectConversation(c.id);
                      }
                    }}
                    role="button"
                    tabIndex={0}
                    className={`group relative flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 text-xs cursor-pointer transition-colors ${
                      isActive
                        ? "bg-[var(--primary)]/10 text-[var(--primary)] font-semibold"
                        : "text-gray-700 dark:text-gray-300 hover:bg-gray-100/90 dark:hover:bg-white/[0.04]"
                    }`}
                  >
                    <div className="flex items-center gap-2 min-w-0">
                      {!isMobile && isActive ? (
                        <motion.span
                          layoutId="copilot-active-conv"
                          className="h-4 w-1 rounded-full bg-[var(--primary)] shrink-0"
                        />
                      ) : (
                        <MessageSquare className="h-3.5 w-3.5 shrink-0 opacity-65" />
                      )}
                      <span className="truncate">{c.title}</span>
                    </div>
                    <button
                      type="button"
                      onClick={(e) => handleDeleteConversation(c.id, e)}
                      className="opacity-0 group-hover:opacity-100 focus:opacity-100 text-gray-400 hover:text-red-500 p-1 rounded-md shrink-0 transition-opacity"
                      title={t("deleteConversation")}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                );
              })}
            </div>
          );
        })}
      </div>
    );
  };

  return (
    <div className="mx-auto w-full max-w-[1440px] px-3 sm:px-5 py-2.5 sm:py-3.5">
      <div className="flex h-[calc(100vh-5rem)] min-h-[580px] gap-3.5 relative">
        {/* Mobile Conversation Sidebar Overlay */}
        <AnimatePresence>
          {mobileHistoryOpen && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setMobileHistoryOpen(false)}
              className="fixed inset-0 z-40 lg:hidden flex bg-black/50 backdrop-blur-xs"
            >
              <motion.div
                initial={{ x: isAr ? 300 : -300 }}
                animate={{ x: 0 }}
                exit={{ x: isAr ? 300 : -300 }}
                transition={{ type: "spring", stiffness: 360, damping: 34 }}
                onClick={(e) => e.stopPropagation()}
                className="w-76 h-full bg-[var(--card)] border-e border-[var(--border)] p-4 flex flex-col shadow-2xl"
              >
                <div className="flex items-center justify-between mb-3">
                  <span className="text-sm font-bold text-gray-900 dark:text-white">
                    {t("historyTitle")}
                  </span>
                  <button
                    type="button"
                    onClick={() => setMobileHistoryOpen(false)}
                    className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-white"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>

                <button
                  type="button"
                  onClick={handleNewChat}
                  className="w-full flex items-center justify-between gap-2 rounded-xl border border-[var(--primary)]/30 bg-[var(--primary)]/[0.09] hover:bg-[var(--primary)] hover:text-white px-3 py-2 text-xs font-semibold text-[var(--primary)] transition-all group mb-3"
                >
                  <span className="flex items-center gap-2">
                    <Plus className="h-3.5 w-3.5" />
                    <span>{t("newChat")}</span>
                  </span>
                  <Sparkles className="h-3 w-3 opacity-65 group-hover:opacity-100" />
                </button>

                <div className="relative mb-3">
                  <Search className="pointer-events-none absolute start-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={t("searchConversations")}
                    className="w-full rounded-xl border border-[var(--border)] bg-[var(--surface-inset)] ps-8 pe-3 py-1.5 text-xs text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:border-[var(--primary)]/60 focus:outline-none"
                  />
                </div>

                <div className="flex-1 overflow-y-auto custom-scrollbar">
                  {renderConversationList(true)}
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Desktop Collapsible Conversation History Sidebar */}
        {sidebarOpen && (
          <aside className="hidden lg:flex w-[264px] shrink-0 flex-col rounded-2xl border border-[var(--border)] bg-[var(--card)]/95 p-3.5 shadow-sm backdrop-blur-xl">
            <motion.button
              whileTap={{ scale: 0.985 }}
              type="button"
              onClick={handleNewChat}
              className="w-full flex items-center justify-between gap-2 rounded-xl border border-[var(--primary)]/30 bg-[var(--primary)]/[0.09] hover:bg-[var(--primary)] hover:text-white px-3 py-2 text-xs font-semibold text-[var(--primary)] transition-all group mb-3"
            >
              <span className="flex items-center gap-2">
                <Plus className="h-3.5 w-3.5" />
                <span>{t("newChat")}</span>
              </span>
              <Sparkles className="h-3 w-3 opacity-65 group-hover:opacity-100" />
            </motion.button>

            <div className="relative mb-3">
              <Search className="pointer-events-none absolute start-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder={t("searchConversations")}
                className="w-full rounded-xl border border-[var(--border)] bg-[var(--surface-inset)] ps-8 pe-3 py-1.5 text-xs text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:border-[var(--primary)]/60 focus:outline-none"
              />
            </div>

            <div className="flex items-center justify-between px-2 mb-2">
              <span className="text-[10.5px] font-bold uppercase tracking-wider text-gray-400">
                {t("historyTitle")}
              </span>
              <span className="rounded-full bg-gray-100 dark:bg-white/[0.06] px-1.5 py-0.5 text-[10px] font-semibold tabular-nums text-gray-500 dark:text-gray-400">
                {conversations.length}
              </span>
            </div>

            <div className="flex-1 overflow-y-auto custom-scrollbar pe-0.5">
              {renderConversationList(false)}
            </div>

            {quota && (
              <div className="mt-3 rounded-xl border border-[var(--border)] bg-[var(--surface-inset)] p-3 space-y-2">
                <div className="flex items-center justify-between text-[11px]">
                  <span className="font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                    <Zap className="h-3.5 w-3.5 text-[var(--primary)]" />
                    <span>{t("tokensLabel")}</span>
                  </span>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-[var(--primary)]/10 text-[var(--primary)]">
                    {quota.planName}
                  </span>
                </div>

                <div className="h-1.5 w-full rounded-full bg-gray-200/80 dark:bg-gray-800 overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${tokenPct}%` }}
                    transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] as const }}
                    className={`h-full rounded-full ${
                      tokenPct >= 90
                        ? "bg-red-500"
                        : tokenPct >= 75
                        ? "bg-amber-500"
                        : "bg-gradient-to-r from-[var(--primary)] to-[var(--primary-hover)]"
                    }`}
                  />
                </div>

                <div className="flex items-center justify-between text-[11px] tabular-nums text-gray-500 dark:text-gray-400">
                  <span>
                    {formatNumber(tokensUsed, locale)} /{" "}
                    {tokensLimit < 0 ? t("unlimited") : formatNumber(tokensLimit, locale)}
                  </span>
                  <span>
                    {queriesUsed}/{queriesLimit < 0 ? "∞" : queriesLimit} {t("queriesLabel")}
                  </span>
                </div>

                {tokenPct >= 75 && (
                  <Link
                    href="/dashboard/settings/subscription"
                    className="afab-btn-premium w-full py-1.5 text-[11px] justify-center"
                  >
                    <span>{t("upgradeCta")}</span>
                    <ExternalLink className="h-3 w-3" />
                  </Link>
                )}
              </div>
            )}
          </aside>
        )}

        {/* Main Copilot Studio Workspace */}
        <section
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
          className="relative flex-1 flex flex-col rounded-2xl border border-[var(--border)] bg-[var(--card)] shadow-sm overflow-hidden"
        >
          {dragActive && (
            <div className="pointer-events-none absolute inset-3 z-30 flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-[var(--primary)] bg-[var(--card)]/90 backdrop-blur-md text-center p-6">
              <Upload className="h-10 w-10 text-[var(--primary)] mb-2" />
              <p className="text-base font-bold text-gray-900 dark:text-white">
                {t("attachments.dropHere")}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {t("attachments.supportedHint")}
              </p>
            </div>
          )}

          {/* Clean Single-Row Studio Header */}
          <header className="h-14 flex items-center justify-between gap-3 border-b border-[var(--border)] bg-[var(--card)]/90 backdrop-blur-xl px-4 sm:px-5 shrink-0">
            <div className="flex items-center gap-2.5 min-w-0">
              <button
                type="button"
                onClick={() => setMobileHistoryOpen(true)}
                className="lg:hidden rounded-xl p-1.5 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/5"
                aria-label={t("historyTitle")}
              >
                <Menu className="h-4 w-4" />
              </button>

              <button
                type="button"
                onClick={() => setSidebarOpen((prev) => !prev)}
                className="hidden lg:inline-flex rounded-xl p-1.5 text-gray-500 hover:bg-gray-100 hover:text-gray-900 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-white transition-colors"
                title={t("toggleSidebar")}
                aria-label={t("toggleSidebar")}
              >
                {sidebarOpen ? (
                  <PanelLeftClose className="h-4 w-4" />
                ) : (
                  <PanelLeftOpen className="h-4 w-4" />
                )}
              </button>

              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-[var(--primary)]/12 border border-[var(--primary)]/25 text-[var(--primary)] shadow-2xs">
                <Sparkles className="h-4 w-4" />
              </div>

              <h1 className="text-sm font-bold text-gray-900 dark:text-white truncate max-w-[200px] sm:max-w-[300px]">
                {activeConversation ? activeConversation.title : t("title")}
              </h1>

              <AiModelStatusBadge
                health={health}
                backendConnected={backendConnected}
                checking={checkingHealth}
                onManualCheck={handleManualHealthCheck}
                locale={locale}
              />

              {activeLanguage && (
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[var(--surface-inset)] text-gray-700 dark:text-gray-300 border border-[var(--border)] shrink-0">
                  {t(`languageLabel.${activeLanguage}`)}
                </span>
              )}
            </div>

            <div className="flex items-center gap-1.5 shrink-0">
              {(!sidebarOpen || messages.length > 0) && (
                <button
                  type="button"
                  onClick={handleNewChat}
                  className="inline-flex h-8 items-center gap-1.5 rounded-xl border border-[var(--border)] bg-[var(--surface-inset)] px-2.5 text-xs font-medium text-gray-600 dark:text-gray-300 hover:border-[var(--primary)]/45 hover:text-[var(--primary)] transition-colors"
                  title={t("newChat")}
                >
                  <Plus className="h-3.5 w-3.5" />
                  <span className="hidden md:inline">{t("newChat")}</span>
                </button>
              )}

              <button
                type="button"
                onClick={handleSyncIndex}
                disabled={syncingIndex}
                className="inline-flex h-8 items-center gap-1.5 rounded-xl border border-[var(--border)] bg-[var(--surface-inset)] px-2.5 text-xs font-medium text-gray-600 dark:text-gray-300 hover:border-[var(--primary)]/45 hover:text-[var(--primary)] disabled:opacity-50 transition-colors"
                title={t("syncIndexButton")}
              >
                <RefreshCw className={`h-3.5 w-3.5 ${syncingIndex ? "animate-spin" : ""}`} />
                <span className="hidden sm:inline">
                  {syncingIndex ? t("syncing") : t("syncIndexButton")}
                </span>
                {status && (
                  <span className="text-[10px] tabular-nums opacity-70">
                    ({status.indexedChunks})
                  </span>
                )}
              </button>

              <button
                type="button"
                onClick={() => setMemoryDrawerOpen(true)}
                className="inline-flex h-8 items-center gap-1.5 rounded-xl border border-[var(--border)] bg-[var(--surface-inset)] px-2.5 text-xs font-medium text-gray-600 dark:text-gray-300 hover:border-[var(--primary)]/45 hover:text-[var(--primary)] transition-colors"
                title={t("memoryButton")}
              >
                <Brain className="h-3.5 w-3.5 text-[var(--primary)]" />
                <span className="hidden sm:inline">{t("memoryButton")}</span>
                <span className="px-1.5 py-0.2 rounded-full bg-[var(--primary)]/12 text-[var(--primary)] text-[10px] font-bold tabular-nums">
                  {memories.length}
                </span>
              </button>
            </div>
          </header>

          {/* Local Ollama Offline Notice */}
          {((health && (!health.ollamaReachable || !health.chatModelReady)) ||
            (status && (!status.ollamaReachable || !status.chatModelReady))) && (
            <div className="mx-4 sm:mx-6 mt-3 rounded-2xl border border-amber-500/30 bg-amber-50/80 dark:bg-amber-500/10 p-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs shrink-0">
              <div className="flex items-start gap-2.5">
                <AlertTriangle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                <div>
                  <p className="font-bold text-amber-900 dark:text-amber-200">{t("offlineTitle")}</p>
                  <p className="text-amber-800/90 dark:text-amber-300/90 mt-0.5">
                    {t("offlineDescription")}
                  </p>
                  <code
                    dir="ltr"
                    className="inline-block mt-1.5 px-2 py-1 rounded-lg bg-black/5 dark:bg-black/30 font-mono text-[11px]"
                  >
                    ollama pull {health?.chatModel || status?.chatModel || "gemma4:e4b"} && ollama pull {health?.embedModel || status?.embedModel || "embeddinggemma-2:270m"}
                  </code>
                </div>
              </div>
            </div>
          )}

          {/* Plan Quota Exhausted Banner */}
          {quotaExhaustedMsg && (
            <div className="mx-4 sm:mx-6 mt-3 rounded-2xl border border-red-500/30 bg-red-50/80 dark:bg-red-500/10 p-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs shrink-0">
              <div className="flex items-start gap-2.5">
                <Zap className="h-4 w-4 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
                <div>
                  <p className="font-bold text-red-800 dark:text-red-300">{t("quotaExhaustedTitle")}</p>
                  <p className="text-red-700/90 dark:text-red-300/90 mt-0.5">{quotaExhaustedMsg}</p>
                </div>
              </div>
              <Link
                href="/dashboard/settings/subscription"
                className="afab-btn-premium px-3.5 py-2 text-xs shrink-0"
              >
                {t("upgradeCta")}
              </Link>
            </div>
          )}

          {/* Inline Error Banner */}
          {chatError && (
            <div
              role="alert"
              className="mx-4 sm:mx-6 mt-3 rounded-2xl border border-red-500/30 bg-red-50/80 dark:bg-red-500/10 p-3.5 flex items-start justify-between gap-3 text-xs shrink-0"
            >
              <div className="flex items-start gap-2.5">
                <AlertTriangle className="h-4 w-4 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
                <p className="font-medium text-red-800 dark:text-red-300">{chatError}</p>
              </div>
              <button
                type="button"
                onClick={() => setChatError(null)}
                className="p-1 rounded-lg text-red-500 hover:bg-red-500/10 shrink-0"
                aria-label="Dismiss error"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          )}

          {/* Conversation Canvas */}
          <div
            ref={scrollContainerRef}
            onScroll={handleMessagesScroll}
            className="flex-1 overflow-y-auto px-4 sm:px-6 py-5 custom-scrollbar relative"
          >
            {loadingPage ? (
              <div className="flex h-full items-center justify-center">
                <AfabLoader size="md" text={t("loading")} />
              </div>
            ) : messages.length === 0 && !sending ? (
              <CopilotWelcome
                onSelectPrompt={(text) => handleSend(text)}
                onPrefillPrompt={(text) => {
                  setInput(text);
                  requestAnimationFrame(() => textareaRef.current?.focus());
                }}
                onAttachClick={() => fileInputRef.current?.click()}
                disabled={sending}
              />
            ) : (
              <div className="max-w-3xl mx-auto space-y-5 pb-4">
                {messages.map((msg, idx) => (
                  <CopilotMessageBubble
                    key={msg.id}
                    message={msg}
                    locale={locale}
                    isLatestAssistant={idx === latestAssistantIdx}
                    canRegenerate={!sending}
                    onRegenerate={() => handleRegenerateFromIndex(idx)}
                    onDraftUpdated={handleDraftUpdated}
                  />
                ))}

                {sending && (
                  <CopilotThinkingCard
                    activeTools={activeTools}
                    completedTools={completedTools}
                    streamingText={streamingText}
                    thinkingText={thinkingText}
                    streamPhase={streamPhase}
                  />
                )}

                {!sending && suggestedFollowUps.length > 0 && (
                  <motion.div
                    initial={{ opacity: 0, y: 6 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.25 }}
                    className="ps-11 space-y-2 pt-1"
                  >
                    <p className="text-[10.5px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
                      {t("followUpsLabel")}
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {suggestedFollowUps.map((q) => (
                        <motion.button
                          key={q}
                          whileHover={{ y: -1 }}
                          whileTap={{ scale: 0.98 }}
                          type="button"
                          onClick={() => handleSend(q)}
                          className="inline-flex items-center gap-1.5 rounded-full border border-[var(--primary)]/25 bg-[var(--primary)]/[0.06] hover:bg-[var(--primary)]/15 hover:border-[var(--primary)]/45 px-3.5 py-1.5 text-xs font-medium text-[var(--primary)] transition-colors cursor-pointer"
                        >
                          <Sparkles className="h-3 w-3 opacity-80 shrink-0" />
                          <span>{q}</span>
                        </motion.button>
                      ))}
                    </div>
                  </motion.div>
                )}

                <div ref={bottomRef} />
              </div>
            )}
          </div>

          {/* Floating Scroll-to-Bottom Pill */}
          <AnimatePresence>
            {showScrollToBottom && messages.length > 0 && (
              <motion.button
                initial={{ opacity: 0, y: 8, scale: 0.92 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 8, scale: 0.92 }}
                type="button"
                onClick={scrollToBottom}
                title={t("scrollToBottom")}
                aria-label={t("scrollToBottom")}
                className="absolute bottom-32 end-6 z-20 flex h-9 w-9 items-center justify-center rounded-full border border-gray-200 dark:border-gray-700 bg-[var(--surface-inset)]/95 text-gray-700 dark:text-gray-200 shadow-lg hover:border-[var(--primary)]/50 hover:text-[var(--primary)] backdrop-blur-md transition-colors"
              >
                <ArrowDown className="h-4 w-4" />
              </motion.button>
            )}
          </AnimatePresence>

          {/* Flagship Two-Zone Command Composer */}
          <div className="px-4 sm:px-6 pb-3.5 pt-1.5 bg-gradient-to-t from-[var(--card)] via-[var(--card)]/95 to-transparent shrink-0">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleSend();
              }}
              className="max-w-3xl mx-auto rounded-2xl border border-[var(--border)] bg-[var(--surface-inset)] shadow-lg shadow-black/[0.04] dark:shadow-black/30 focus-within:border-[var(--primary)]/70 focus-within:ring-2 focus-within:ring-[var(--primary)]/15 transition-all"
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

              {stagedAttachments.length > 0 && (
                <div className="flex flex-wrap gap-2 px-3 pt-2.5">
                  {stagedAttachments.map((chip) => (
                    <AttachmentPreviewChip
                      key={chip.attachment.id}
                      attachment={chip.attachment}
                      localPreviewUrl={chip.localPreviewUrl}
                      onRemove={() => {
                        if (chip.localPreviewUrl) URL.revokeObjectURL(chip.localPreviewUrl);
                        setStagedAttachments((prev) =>
                          prev.filter((item) => item.attachment.id !== chip.attachment.id)
                        );
                      }}
                    />
                  ))}
                </div>
              )}

              {interimVoice && (
                <div className="px-3.5 pt-2.5">
                  <div className="inline-flex items-center gap-2 rounded-full border border-red-500/25 bg-red-500/10 px-2.5 py-1 text-[11px] font-medium text-red-500 max-w-full">
                    <span className="h-1.5 w-1.5 rounded-full bg-red-500 animate-ping shrink-0" />
                    <span className="font-bold shrink-0">{t("listeningLabel")}:</span>
                    <span className="truncate">{interimVoice}</span>
                  </div>
                </div>
              )}

              {/* Zone 1: Full-width non-clipping textarea */}
              <div className="px-3.5 pt-2.5 pb-1">
                <textarea
                  ref={textareaRef}
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
                  maxLength={4000}
                  className="w-full min-h-[38px] max-h-40 bg-transparent py-1 text-[14px] leading-6 text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none resize-none"
                  dir={isAr ? "rtl" : "auto"}
                />
              </div>

              {/* Zone 2: Unified Bottom Action Bar */}
              <div className="px-2.5 pb-2.5 pt-1 flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5">
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={sending || uploadingFile}
                    title={t("attachments.attachTitle")}
                    aria-label={t("attachments.attachTitle")}
                    className="h-8 px-2.5 rounded-xl border border-[var(--border)] bg-[var(--card)] text-xs font-medium inline-flex items-center gap-1.5 text-gray-600 dark:text-gray-300 hover:border-[var(--primary)]/45 hover:text-[var(--primary)] disabled:opacity-50 transition-colors"
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
                      className={`inline-flex h-7 items-center gap-1 rounded-lg px-2.5 text-[11px] transition-colors ${
                        reasoningMode === "fast"
                          ? "bg-[var(--primary)]/15 text-[var(--primary)] ring-1 ring-[var(--primary)]/25 font-semibold"
                          : "font-medium text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
                      }`}
                    >
                      <Zap className="h-3 w-3" />
                      <span>{t("fastMode")}</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setReasoningMode("deep")}
                      className={`inline-flex h-7 items-center gap-1 rounded-lg px-2.5 text-[11px] transition-colors ${
                        reasoningMode === "deep"
                          ? "bg-[var(--primary)]/15 text-[var(--primary)] ring-1 ring-[var(--primary)]/25 font-semibold"
                          : "font-medium text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
                      }`}
                    >
                      <Brain className="h-3 w-3" />
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
                    <motion.button
                      whileTap={{ scale: 0.96 }}
                      type="button"
                      onClick={handleStopStream}
                      className="h-8 px-3 rounded-xl bg-red-500/15 border border-red-500/30 text-red-500 hover:bg-red-500 hover:text-white text-xs font-semibold inline-flex items-center gap-1.5 shrink-0 transition-colors"
                    >
                      <Square className="h-3 w-3 fill-current" />
                      <span>{t("stop")}</span>
                    </motion.button>
                  ) : (
                    <motion.button
                      whileTap={input.trim() || stagedAttachments.length > 0 ? { scale: 0.96 } : undefined}
                      type="submit"
                      disabled={!input.trim() && stagedAttachments.length === 0}
                      className={
                        input.trim() || stagedAttachments.length > 0
                          ? "h-8 px-3.5 rounded-xl bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white text-xs font-semibold shadow-sm shadow-[var(--glow-color)] inline-flex items-center gap-1.5 shrink-0 transition-all"
                          : "h-8 px-3.5 rounded-xl bg-gray-200/80 dark:bg-white/[0.06] text-gray-400 dark:text-gray-500 text-xs font-semibold inline-flex items-center gap-1.5 shrink-0 cursor-not-allowed"
                      }
                    >
                      <ArrowUp className="h-3.5 w-3.5" />
                      <span>{t("send")}</span>
                    </motion.button>
                  )}
                </div>
              </div>
            </form>

            <div className="max-w-3xl mx-auto mt-1.5 px-1 flex items-center justify-between gap-2 text-[10.5px] text-gray-400 dark:text-gray-500">
              <span className="inline-flex items-center gap-1.5 truncate">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-500/80 shrink-0" />
                <span className="truncate">{t("composerFooter")}</span>
              </span>
              <span className="hidden sm:inline shrink-0">{t("composerHint")}</span>
            </div>
          </div>
        </section>
      </div>

      <BusinessMemoryDrawer
        open={memoryDrawerOpen}
        onClose={() => setMemoryDrawerOpen(false)}
        memories={memories}
        onRefresh={refreshMemoryAndStatus}
      />
    </div>
  );
}
