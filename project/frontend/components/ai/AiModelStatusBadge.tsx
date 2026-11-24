"use client";

import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Activity,
  CheckCircle2,
  Cpu,
  Flame,
  RefreshCw,
  Server,
  WifiOff,
  AlertTriangle,
  ChevronDown,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { AiHealthResponse } from "@/lib/api/ai";

interface AiModelStatusBadgeProps {
  health: AiHealthResponse | null;
  backendConnected: boolean;
  checking: boolean;
  onManualCheck: () => void;
  locale: string;
}

export function AiModelStatusBadge({
  health,
  backendConnected,
  checking,
  onManualCheck,
  locale,
}: AiModelStatusBadgeProps) {
  const t = useTranslations("AI");
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!open) return;
    const onOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onOutside);
    return () => document.removeEventListener("mousedown", onOutside);
  }, [open]);

  const isBackendDown = !backendConnected;
  const isOllamaOnline = Boolean(health?.ollamaReachable);
  const isChatReady = Boolean(health?.chatModelReady);
  const isHotInGpu = Boolean(health?.chatModelLoaded);
  const isBusy = Boolean(health?.busy);
  const isEmbedReady = Boolean(health?.embedModelReady);

  let pillClass =
    "border-emerald-500/25 bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 hover:bg-emerald-500/15";
  let dotClass = "bg-emerald-500";
  let pingClass = "bg-emerald-500";
  let showPing = true;
  let pillLabel = health
    ? isBusy
      ? `${health.chatModel} · ${t("liveStatus.busy")}`
      : isHotInGpu
      ? `${health.chatModel} · ${t("liveStatus.hotShort")}`
      : `${health.chatModel} · ${t("liveStatus.readyShort")}`
    : t("liveStatus.checking");

  if (isBackendDown) {
    pillClass =
      "border-red-500/30 bg-red-500/10 text-red-700 dark:text-red-400 hover:bg-red-500/15";
    dotClass = "bg-red-500";
    pingClass = "bg-red-500";
    showPing = true;
    pillLabel = t("liveStatus.backendOffline");
  } else if (!health) {
    pillClass =
      "border-gray-300 dark:border-gray-700 bg-gray-100/80 dark:bg-white/[0.05] text-gray-600 dark:text-gray-300";
    dotClass = "bg-gray-400";
    showPing = false;
    pillLabel = t("liveStatus.checking");
  } else if (!isOllamaOnline) {
    pillClass =
      "border-amber-500/30 bg-amber-500/10 text-amber-700 dark:text-amber-400 hover:bg-amber-500/15";
    dotClass = "bg-amber-500";
    showPing = false;
    pillLabel = t("modelOffline");
  } else if (!isChatReady) {
    pillClass =
      "border-amber-500/30 bg-amber-500/10 text-amber-700 dark:text-amber-400 hover:bg-amber-500/15";
    dotClass = "bg-amber-500";
    showPing = false;
    pillLabel = t("modelMissing");
  } else if (isBusy) {
    pillClass =
      "border-[var(--primary)]/30 bg-[var(--primary)]/10 text-[var(--primary)] hover:bg-[var(--primary)]/15";
    dotClass = "bg-[var(--primary)]";
    pingClass = "bg-[var(--primary)]";
    showPing = true;
  }

  const formattedCheckedAt = (() => {
    if (!health?.checkedAt) return "—";
    try {
      return new Intl.DateTimeFormat(locale === "ar" ? "ar-TN" : "en-US", {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
      }).format(new Date(health.checkedAt));
    } catch {
      return "—";
    }
  })();

  return (
    <div ref={containerRef} className="relative inline-flex">
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10.5px] font-semibold border transition-colors cursor-pointer ${pillClass}`}
        title={t("liveStatus.title")}
      >
        <span className="relative flex h-1.5 w-1.5 shrink-0">
          {showPing && (
            <span
              className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${pingClass}`}
            />
          )}
          <span className={`relative inline-flex h-1.5 w-1.5 rounded-full ${dotClass}`} />
        </span>

        <span className="truncate max-w-[210px]">{pillLabel}</span>

        {!isBackendDown && isOllamaOnline && isChatReady && health && health.latencyMs > 0 && (
          <span className="hidden sm:inline text-[9.5px] opacity-75 tabular-nums font-mono">
            {health.latencyMs}ms
          </span>
        )}

        <ChevronDown
          className={`h-3 w-3 opacity-70 transition-transform ${open ? "rotate-180" : ""}`}
        />
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: 6, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 4, scale: 0.98 }}
            transition={{ duration: 0.16 }}
            className="absolute start-0 top-full mt-2 z-50 w-76 rounded-2xl border border-[var(--border)] bg-[var(--card)] p-3.5 shadow-2xl shadow-black/25 space-y-3 text-xs"
          >
            {/* Header */}
            <div className="flex items-center justify-between gap-2 pb-2 border-b border-gray-100 dark:border-gray-800/80">
              <div className="flex items-center gap-1.5 font-bold text-gray-900 dark:text-white">
                <Activity className="h-3.5 w-3.5 text-emerald-500" />
                <span>{t("liveStatus.title")}</span>
              </div>
              <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-2 py-0.5 text-[9.5px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                {t("liveStatus.realtimeBadge")}
              </span>
            </div>

            {/* Diagnostic Rows */}
            <div className="space-y-2">
              {/* AFAB Backend */}
              <div className="flex items-center justify-between gap-2">
                <span className="flex items-center gap-1.5 text-gray-500 dark:text-gray-400">
                  <Server className="h-3.5 w-3.5" />
                  <span>{t("liveStatus.backendLabel")}</span>
                </span>
                {backendConnected ? (
                  <span className="inline-flex items-center gap-1 font-semibold text-emerald-600 dark:text-emerald-400">
                    <CheckCircle2 className="h-3.5 w-3.5" />
                    {t("liveStatus.connected")}
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 font-semibold text-red-600 dark:text-red-400">
                    <WifiOff className="h-3.5 w-3.5" />
                    {t("liveStatus.reconnecting")}
                  </span>
                )}
              </div>

              {/* Ollama Runtime */}
              <div className="flex items-center justify-between gap-2">
                <span className="flex items-center gap-1.5 text-gray-500 dark:text-gray-400">
                  <Cpu className="h-3.5 w-3.5" />
                  <span>{t("liveStatus.ollamaLabel")}</span>
                </span>
                {!backendConnected ? (
                  <span className="text-gray-400">—</span>
                ) : isOllamaOnline ? (
                  <span className="inline-flex items-center gap-1 font-semibold text-emerald-600 dark:text-emerald-400 tabular-nums">
                    <CheckCircle2 className="h-3.5 w-3.5" />
                    {t("liveStatus.online")} ({health?.latencyMs ?? 0}ms)
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 font-semibold text-amber-600 dark:text-amber-400">
                    <AlertTriangle className="h-3.5 w-3.5" />
                    {t("liveStatus.offline")}
                  </span>
                )}
              </div>

              {/* Chat Model */}
              <div className="flex items-center justify-between gap-2">
                <span className="text-gray-500 dark:text-gray-400 truncate">
                  {t("liveStatus.chatModelLabel")}
                </span>
                {!backendConnected || !isOllamaOnline ? (
                  <span className="text-gray-400 font-mono text-[11px]">
                    {health?.chatModel || "gemma4:e4b"}
                  </span>
                ) : isChatReady ? (
                  <span className="inline-flex items-center gap-1 font-semibold text-emerald-600 dark:text-emerald-400">
                    {isHotInGpu && <Flame className="h-3 w-3 text-amber-500" />}
                    <span className="font-mono text-[11px]">{health?.chatModel}</span>
                    <span className="text-[10px] opacity-80">
                      ({isHotInGpu ? t("liveStatus.hotShort") : t("liveStatus.coldShort")})
                    </span>
                  </span>
                ) : (
                  <span className="font-semibold text-amber-600 dark:text-amber-400">
                    {t("liveStatus.missing")}
                  </span>
                )}
              </div>

              {/* Embedding Model */}
              <div className="flex items-center justify-between gap-2">
                <span className="text-gray-500 dark:text-gray-400 truncate">
                  {t("liveStatus.embedModelLabel")}
                </span>
                {!backendConnected || !isOllamaOnline ? (
                  <span className="text-gray-400 font-mono text-[11px]">
                    {health?.embedModel || "embeddinggemma-2:270m"}
                  </span>
                ) : isEmbedReady ? (
                  <span className="inline-flex items-center gap-1 font-semibold text-emerald-600 dark:text-emerald-400 font-mono text-[11px]">
                    <CheckCircle2 className="h-3 w-3" />
                    {t("liveStatus.readyShort")}
                  </span>
                ) : (
                  <span className="font-semibold text-amber-600 dark:text-amber-400">
                    {t("liveStatus.missing")}
                  </span>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-between gap-2 pt-2 border-t border-gray-100 dark:border-gray-800/80 text-[10.5px] text-gray-400">
              <span className="tabular-nums">
                {t("liveStatus.lastChecked")}: {formattedCheckedAt}
              </span>
              <button
                type="button"
                onClick={onManualCheck}
                disabled={checking}
                className="inline-flex items-center gap-1 rounded-lg border border-gray-200 dark:border-gray-800 px-2 py-1 text-[10.5px] font-semibold text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-white/[0.06] disabled:opacity-50 transition-colors cursor-pointer"
              >
                <RefreshCw className={`h-3 w-3 ${checking ? "animate-spin" : ""}`} />
                <span>{checking ? t("liveStatus.checking") : t("liveStatus.checkNow")}</span>
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
