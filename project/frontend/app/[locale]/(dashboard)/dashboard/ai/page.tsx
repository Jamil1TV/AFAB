"use client";

import { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { useLocale, useTranslations } from "next-intl";
import { AnimatePresence, motion } from "framer-motion";
import { Link } from "@/i18n/routing";
import {
  AlertTriangle,
  ArrowDown,
  Brain,
  ExternalLink,
  Loader2,
  Menu,
  MessageSquare,
  PanelLeftClose,
  PanelLeftOpen,
  Plus,
  RefreshCw,
  Search,
  Send,
  Sparkles,
  Square,
  Trash2,
  X,
  Zap,
} from "lucide-react";
import {
  AiService,
  AiStatusResponse,
  AiConversationSummary,
  AiMessageItem,
  BusinessMemoryItem,
} from "@/lib/api/ai";
import { ApiError } from "@/lib/api/client";
import { CopilotWelcome } from "@/components/ai/CopilotWelcome";
import {
  CopilotThinkingCard,
  CompletedToolInfo,
} from "@/components/ai/CopilotThinkingCard";
import { CopilotMessageBubble } from "@/components/ai/CopilotMessageBubble";
import { BusinessMemoryDrawer } from "@/components/ai/BusinessMemoryDrawer";
import { toast } from "sonner";

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
  const [conversations, setConversations] = useState<AiConversationSummary[]>([]);
  const [memories, setMemories] = useState<BusinessMemoryItem[]>([]);
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null);
  const [messages, setMessages] = useState<AiMessageItem[]>([]);
  const [suggestedFollowUps, setSuggestedFollowUps] = useState<string[]>([]);
  const [todayStartMs, setTodayStartMs] = useState<number | null>(null);

  const [input, setInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [sending, setSending] = useState(false);
  const [streamingText, setStreamingText] = useState("");
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
      .catch((err) => {
        if (!active) return;
        console.error("Failed to load Copilot workspace:", err);
      })
      .finally(() => {
        if (active) setLoadingPage(false);
      });
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, streamingText, activeTools, completedTools]);

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
      setSuggestedFollowUps([]);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Unable to load conversation");
    }
  };

  const handleNewChat = () => {
    setActiveConversationId(null);
    setMessages([]);
    setStreamingText("");
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
    setActiveTools([]);
    setCompletedTools([]);
  };

  const handleSend = async (promptOverride?: string) => {
    const text = (promptOverride ?? input).trim();
    if (!text || sending) return;

    setQuotaExhaustedMsg(null);
    setChatError(null);
    setInput("");
    setSending(true);
    setStreamingText("");
    setActiveTools([]);
    setCompletedTools([]);
    setSuggestedFollowUps([]);

    const optimisticUserMsg: AiMessageItem = {
      id: `local-user-${messages.length + 1}`,
      role: "user",
      content: text,
      evidence: [],
      toolsUsed: [],
      promptTokens: 0,
      completionTokens: 0,
      totalTokens: 0,
      createdAt: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, optimisticUserMsg]);

    const controller = new AbortController();
    abortRef.current = controller;
    let accumulated = "";

    try {
      const donePayload = await AiService.streamChat(
        {
          message: text,
          conversationId: activeConversationId,
          locale,
        },
        {
          signal: controller.signal,
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
        }
      );

      if (donePayload) {
        const assistantMsg: AiMessageItem = {
          id: donePayload.messageId,
          role: "assistant",
          content: donePayload.content,
          evidence: donePayload.evidence || [],
          toolsUsed: donePayload.toolsUsed || [],
          dataCoverage: donePayload.dataCoverage,
          modelId: donePayload.modelId,
          promptTokens: donePayload.tokenUsage.promptTokens,
          completionTokens: donePayload.tokenUsage.completionTokens,
          totalTokens: donePayload.tokenUsage.totalTokens,
          latencyMs: donePayload.latencyMs,
          createdAt: donePayload.createdAt,
        };
        setMessages((prev) => [...prev, assistantMsg]);
        setStreamingText("");
        setActiveTools([]);
        setCompletedTools([]);
        setSuggestedFollowUps(donePayload.suggestedFollowUps || []);
        setActiveConversationId(donePayload.conversationId);
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
        return;
      }
      setMessages((prev) => prev.filter((m) => m.id !== optimisticUserMsg.id));
      setStreamingText("");
      setInput(text);

      if (err instanceof ApiError && err.code === "PLAN_LIMIT_REACHED") {
        setQuotaExhaustedMsg(err.message);
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
      setActiveTools([]);
      setCompletedTools([]);
    }
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
                        ? "bg-[#8b5cf6]/12 text-[#7c3aed] dark:text-[#c4b5fd] font-semibold"
                        : "text-gray-700 dark:text-gray-300 hover:bg-gray-100/90 dark:hover:bg-white/[0.04]"
                    }`}
                  >
                    <div className="flex items-center gap-2 min-w-0">
                      {!isMobile && isActive ? (
                        <motion.span
                          layoutId="copilot-active-conv"
                          className="h-4 w-1 rounded-full bg-[#8b5cf6] shrink-0"
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
    <div className="mx-auto w-full max-w-[1440px] px-3 sm:px-5 py-3 sm:py-4">
      <div className="flex h-[calc(100vh-5.75rem)] min-h-[580px] gap-4 relative">
        {/* ── Mobile Conversation Sidebar Overlay ── */}
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
                className="w-76 h-full bg-white dark:bg-[#0c101c] border-e border-gray-200 dark:border-gray-800 p-4 flex flex-col shadow-2xl"
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
                  className="afab-btn-primary w-full py-2.5 text-xs mb-3"
                >
                  <Plus className="h-3.5 w-3.5" />
                  <span>{t("newChat")}</span>
                </button>

                <div className="relative mb-3">
                  <Search className="pointer-events-none absolute start-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={t("searchConversations")}
                    className="afab-input ps-8 py-1.5 text-xs"
                  />
                </div>

                <div className="flex-1 overflow-y-auto custom-scrollbar">
                  {renderConversationList(true)}
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* ── Desktop Collapsible Conversation History Sidebar ── */}
        {sidebarOpen && (
          <aside className="hidden lg:flex w-72 shrink-0 flex-col afab-card p-3.5 bg-white/90 dark:bg-[#0c101c]/95 backdrop-blur-xl">
            <motion.button
              whileTap={{ scale: 0.985 }}
              type="button"
              onClick={handleNewChat}
              className="afab-btn-primary w-full py-2.5 text-xs mb-3"
            >
              <Plus className="h-3.5 w-3.5" />
              <span>{t("newChat")}</span>
            </motion.button>

            <div className="relative mb-3">
              <Search className="pointer-events-none absolute start-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder={t("searchConversations")}
                className="afab-input ps-8 py-1.5 text-xs"
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

            {/* ── Token Quota Fuel Card ── */}
            {quota && (
              <div className="mt-3 rounded-2xl border border-gray-200/80 dark:border-gray-800/80 bg-gray-50/75 dark:bg-[#080c18] p-3 space-y-2.5">
                <div className="flex items-center justify-between text-[11px]">
                  <span className="font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                    <Zap className="h-3.5 w-3.5 text-[#7c3aed] dark:text-[#a78bfa]" />
                    <span>{t("tokensLabel")}</span>
                  </span>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-[#8b5cf6]/12 text-[#7c3aed] dark:text-[#c4b5fd]">
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
                        : "bg-gradient-to-r from-[#8b5cf6] to-[#6366f1]"
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

        {/* ── Main Copilot Studio Workspace ── */}
        <section className="relative flex-1 flex flex-col afab-card overflow-hidden bg-white dark:bg-[#0c101c]">
          {/* Single-Row Glass Header */}
          <header className="flex items-center justify-between gap-3 border-b border-gray-200/80 dark:border-gray-800/80 bg-white/80 dark:bg-[#0c101c]/85 backdrop-blur-xl px-4 sm:px-6 py-3 shrink-0">
            <div className="flex items-center gap-2.5 min-w-0">
              <button
                type="button"
                onClick={() => setMobileHistoryOpen(true)}
                className="lg:hidden rounded-xl p-2 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/5"
                aria-label={t("historyTitle")}
              >
                <Menu className="h-4 w-4" />
              </button>

              <button
                type="button"
                onClick={() => setSidebarOpen((prev) => !prev)}
                className="hidden lg:inline-flex rounded-xl p-2 text-gray-500 hover:bg-gray-100 hover:text-gray-900 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-white transition-colors"
                title={t("toggleSidebar")}
                aria-label={t("toggleSidebar")}
              >
                {sidebarOpen ? (
                  <PanelLeftClose className="h-4 w-4" />
                ) : (
                  <PanelLeftOpen className="h-4 w-4" />
                )}
              </button>

              <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#8b5cf6]/15 to-[#10b981]/10 border border-[#8b5cf6]/25 text-[#7c3aed] dark:text-[#c4b5fd]">
                <Sparkles className="h-4 w-4" />
              </div>

              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap min-w-0">
                  <h1 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white truncate max-w-[280px]">
                    {activeConversation ? activeConversation.title : t("title")}
                  </h1>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#c4b5fd] border border-[#8b5cf6]/20 shrink-0">
                    {t("badge")}
                  </span>
                  {status && (
                    <span
                      className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10.5px] font-semibold border ${
                        status.ollamaReachable && status.chatModelReady
                          ? "border-emerald-500/20 bg-emerald-500/10 text-emerald-700 dark:text-emerald-400"
                          : "border-amber-500/20 bg-amber-500/10 text-amber-700 dark:text-amber-400"
                      }`}
                    >
                      <span className="relative flex h-1.5 w-1.5">
                        {status.ollamaReachable && status.chatModelReady && (
                          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-75" />
                        )}
                        <span
                          className={`relative inline-flex h-1.5 w-1.5 rounded-full ${
                            status.ollamaReachable && status.chatModelReady
                              ? "bg-emerald-500"
                              : "bg-amber-500"
                          }`}
                        />
                      </span>
                      {status.ollamaReachable
                        ? status.chatModelReady
                          ? `${status.chatModel} • ${t("modelReady")}`
                          : t("modelMissing")
                        : t("modelOffline")}
                    </span>
                  )}
                </div>
                <p className="text-[11px] text-gray-500 dark:text-gray-400 hidden sm:block whitespace-normal">
                  {t("subtitle")}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 shrink-0">
              {quota && (
                <span className="lg:hidden inline-flex items-center gap-1 rounded-xl border border-gray-200 dark:border-gray-800 px-2.5 py-1.5 text-[11px] font-semibold tabular-nums text-gray-700 dark:text-gray-300">
                  <Zap className="h-3 w-3 text-[#7c3aed]" />
                  {formatNumber(Math.max(0, quota.monthlyTokensRemaining), locale)} {t("remaining")}
                </span>
              )}

              <button
                type="button"
                onClick={handleSyncIndex}
                disabled={syncingIndex}
                className="afab-btn-secondary px-3 py-1.5 text-xs"
                title={t("syncIndexButton")}
              >
                <RefreshCw className={`h-3.5 w-3.5 ${syncingIndex ? "animate-spin" : ""}`} />
                <span className="hidden sm:inline">
                  {syncingIndex ? t("syncing") : t("syncIndexButton")}
                </span>
                {status && (
                  <span className="text-[10px] tabular-nums opacity-75">
                    ({status.indexedChunks})
                  </span>
                )}
              </button>

              <button
                type="button"
                onClick={() => setMemoryDrawerOpen(true)}
                className="afab-btn-secondary px-3 py-1.5 text-xs"
              >
                <Brain className="h-3.5 w-3.5 text-[#7c3aed] dark:text-[#a78bfa]" />
                <span className="hidden sm:inline">{t("memoryButton")}</span>
                <span className="px-1.5 py-0.2 rounded-full bg-[#8b5cf6]/12 text-[#7c3aed] dark:text-[#c4b5fd] text-[10px] font-bold tabular-nums">
                  {memories.length}
                </span>
              </button>
            </div>
          </header>

          {/* Local Ollama Offline Notice (honest status, never fakes AI) */}
          {status && (!status.ollamaReachable || !status.chatModelReady) && (
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
                    ollama pull {status.chatModel} && ollama pull {status.embedModel}
                  </code>
                </div>
              </div>
            </div>
          )}

          {/* Plan Token / Query Quota Exhausted Banner */}
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

          {/* Inline Copilot Error Banner */}
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
                <Loader2 className="h-6 w-6 animate-spin text-[#7c3aed]" />
              </div>
            ) : messages.length === 0 && !sending ? (
              <CopilotWelcome onSelectPrompt={(text) => handleSend(text)} disabled={sending} />
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
                  />
                ))}

                {/* Active Animated Thinking / Streaming Card */}
                {sending && (
                  <CopilotThinkingCard
                    activeTools={activeTools}
                    completedTools={completedTools}
                    streamingText={streamingText}
                  />
                )}

                {/* Animated Follow-Up Suggestions */}
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
                          className="inline-flex items-center gap-1.5 rounded-full border border-[#8b5cf6]/25 bg-[#8b5cf6]/[0.06] hover:bg-[#8b5cf6]/15 hover:border-[#8b5cf6]/45 px-3.5 py-1.5 text-xs font-medium text-[#7c3aed] dark:text-[#c4b5fd] transition-colors cursor-pointer"
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
                className="absolute bottom-28 end-6 z-20 flex h-9 w-9 items-center justify-center rounded-full border border-gray-200 dark:border-gray-700 bg-white/95 dark:bg-[#11172a]/95 text-gray-700 dark:text-gray-200 shadow-lg hover:border-[#8b5cf6]/50 hover:text-[#7c3aed] dark:hover:text-[#c4b5fd] backdrop-blur-md transition-colors"
              >
                <ArrowDown className="h-4 w-4" />
              </motion.button>
            )}
          </AnimatePresence>

          {/* Floating Glass Command Composer */}
          <div className="px-4 sm:px-6 pb-4 pt-2 bg-gradient-to-t from-white via-white/95 to-transparent dark:from-[#0c101c] dark:via-[#0c101c]/95 dark:to-transparent shrink-0">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleSend();
              }}
              className="max-w-3xl mx-auto rounded-2xl border border-gray-200 dark:border-gray-800 bg-gray-50/80 dark:bg-[#080c18]/90 shadow-sm focus-within:border-[#8b5cf6] focus-within:ring-2 focus-within:ring-[#8b5cf6]/15 transition-all p-2.5 sm:p-3"
            >
              <div className="flex items-end gap-2.5">
                <textarea
                  ref={textareaRef}
                  rows={1}
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      handleSend();
                    }
                  }}
                  placeholder={t("placeholder")}
                  disabled={sending}
                  maxLength={4000}
                  className="flex-1 min-h-[38px] max-h-40 bg-transparent px-1.5 py-1.5 text-sm text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none resize-none leading-relaxed"
                  dir={isAr ? "rtl" : "auto"}
                />

                {sending ? (
                  <motion.button
                    whileTap={{ scale: 0.96 }}
                    type="button"
                    onClick={handleStopStream}
                    className="h-10 px-4 rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs font-bold inline-flex items-center gap-1.5 shrink-0 shadow-md shadow-red-600/20"
                  >
                    <Square className="h-3.5 w-3.5 fill-current" />
                    <span>{t("stop")}</span>
                  </motion.button>
                ) : (
                  <motion.button
                    whileTap={{ scale: 0.96 }}
                    type="submit"
                    disabled={!input.trim()}
                    className="afab-btn-primary h-10 px-4 text-xs shrink-0"
                  >
                    <Send className="h-3.5 w-3.5 rtl:rotate-180" />
                    <span>{t("send")}</span>
                  </motion.button>
                )}
              </div>

              <div className="mt-2 pt-2 border-t border-gray-200/70 dark:border-gray-800/70 flex items-center justify-between gap-2 px-1 text-[10.5px] text-gray-400 dark:text-gray-500">
                <span className="inline-flex items-center gap-1.5">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-500/80" />
                  <span>{t("composerLanguages")}</span>
                </span>
                <span className="hidden sm:inline">{t("composerHint")}</span>
              </div>
            </form>
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
