"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Brain, Check, Plus, Trash2, X, Sparkles, Loader2 } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { AiService, BusinessMemoryItem } from "@/lib/api/ai";
import { toast } from "sonner";

interface BusinessMemoryDrawerProps {
  open: boolean;
  onClose: () => void;
  memories: BusinessMemoryItem[];
  onRefresh: () => Promise<void>;
}

const MEMORY_TYPES: BusinessMemoryItem["memoryType"][] = [
  "BUSINESS_PROFILE",
  "SUPPLIER_PATTERN",
  "CATEGORIZATION_PREFERENCE",
  "TRANSACTION_CONTEXT",
  "DECISION_HISTORY",
  "OPERATIONAL_CONSTRAINT",
];

export function BusinessMemoryDrawer({
  open,
  onClose,
  memories,
  onRefresh,
}: BusinessMemoryDrawerProps) {
  const t = useTranslations("AI.memory");
  const isAr = useLocale() === "ar";
  const [memoryType, setMemoryType] = useState<BusinessMemoryItem["memoryType"]>("BUSINESS_PROFILE");
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [saving, setSaving] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim() || saving) return;
    setSaving(true);
    try {
      await AiService.createMemory({
        memoryType,
        title: title.trim(),
        content: content.trim(),
        status: "APPROVED",
      });
      setTitle("");
      setContent("");
      await onRefresh();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to save memory");
    } finally {
      setSaving(false);
    }
  };

  const handleApprove = async (id: string) => {
    setBusyId(id);
    try {
      await AiService.updateMemory(id, { status: "APPROVED" });
      await onRefresh();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to approve memory");
    } finally {
      setBusyId(null);
    }
  };

  const handleDelete = async (id: string) => {
    setBusyId(id);
    try {
      await AiService.deleteMemory(id);
      await onRefresh();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to delete memory");
    } finally {
      setBusyId(null);
    }
  };

  const slideOffset = isAr ? -440 : 440;

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          key="memory-drawer-backdrop"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          onClick={onClose}
          className="fixed inset-0 z-50 flex justify-end bg-black/50 backdrop-blur-xs"
        >
          <motion.div
            key="memory-drawer-panel"
            initial={{ x: slideOffset }}
            animate={{ x: 0 }}
            exit={{ x: slideOffset }}
            transition={{ type: "spring", stiffness: 360, damping: 34 }}
            onClick={(e) => e.stopPropagation()}
            className="relative flex h-full w-full max-w-lg flex-col bg-white dark:bg-[#0c101c] border-s border-gray-200 dark:border-gray-800 shadow-2xl"
          >
            <div className="flex items-start justify-between gap-3 border-b border-gray-200 dark:border-gray-800 p-5">
              <div className="flex items-start gap-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#8b5cf6]/15 to-[#10b981]/10 text-[#7c3aed] dark:text-[#c4b5fd] border border-[#8b5cf6]/25">
                  <Brain className="h-5 w-5" />
                </div>
                <div>
                  <h2 className="text-base font-bold text-gray-900 dark:text-white">{t("title")}</h2>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 leading-relaxed">
                    {t("subtitle")}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-white/10 dark:hover:text-white transition-colors"
                aria-label="Close"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-5 space-y-5 custom-scrollbar">
              <form
                onSubmit={handleCreate}
                className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-gray-50/75 dark:bg-[#080c18] p-4 space-y-3"
              >
                <div className="flex items-center gap-2 text-xs font-bold text-gray-900 dark:text-white">
                  <Plus className="h-3.5 w-3.5 text-[#7c3aed] dark:text-[#a78bfa]" />
                  <span>{t("addTitle")}</span>
                </div>

                <div>
                  <label className="afab-label text-[11px]">{t("typeLabel")}</label>
                  <select
                    value={memoryType}
                    onChange={(e) => setMemoryType(e.target.value as BusinessMemoryItem["memoryType"])}
                    className="afab-input text-xs py-2"
                  >
                    {MEMORY_TYPES.map((typeKey) => (
                      <option key={typeKey} value={typeKey}>
                        {t(`types.${typeKey}`)}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="afab-label text-[11px]">{t("titleLabel")}</label>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder={t("titlePlaceholder")}
                    required
                    maxLength={160}
                    className="afab-input text-xs py-2"
                  />
                </div>

                <div>
                  <label className="afab-label text-[11px]">{t("contentLabel")}</label>
                  <textarea
                    rows={3}
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    placeholder={t("contentPlaceholder")}
                    required
                    maxLength={2000}
                    className="afab-input text-xs py-2 resize-none"
                  />
                </div>

                <motion.button
                  whileTap={{ scale: 0.985 }}
                  type="submit"
                  disabled={saving || !title.trim() || !content.trim()}
                  className="afab-btn-primary w-full py-2 text-xs"
                >
                  {saving ? (
                    <>
                      <Loader2 className="h-3.5 w-3.5 animate-spin" />
                      <span>{t("saving")}</span>
                    </>
                  ) : (
                    <>
                      <Sparkles className="h-3.5 w-3.5" />
                      <span>{t("saveButton")}</span>
                    </>
                  )}
                </motion.button>
              </form>

              <div className="space-y-3">
                {memories.length === 0 ? (
                  <div className="rounded-2xl border border-dashed border-gray-200 dark:border-gray-800 p-6 text-center text-xs text-gray-500 dark:text-gray-400">
                    {t("empty")}
                  </div>
                ) : (
                  memories.map((mem, idx) => (
                    <motion.div
                      key={mem.id}
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.22, delay: Math.min(idx * 0.03, 0.24) }}
                      className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#080c18] p-3.5 space-y-2 hover:border-[#8b5cf6]/35 transition-colors"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="min-w-0 space-y-1">
                          <div className="flex flex-wrap items-center gap-1.5">
                            <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa]">
                              {t(`types.${mem.memoryType}`)}
                            </span>
                            <span
                              className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                                mem.hasVector
                                  ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400"
                                  : "bg-amber-500/10 text-amber-600 dark:text-amber-400"
                              }`}
                            >
                              {mem.hasVector && (
                                <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                              )}
                              {mem.hasVector ? t("vectorReady") : t("lexicalOnly")}
                            </span>
                          </div>
                          <h4 className="text-xs font-bold text-gray-900 dark:text-white truncate">
                            {mem.title}
                          </h4>
                        </div>

                        <div className="flex items-center gap-1 shrink-0">
                          {mem.status === "PROPOSED" && (
                            <button
                              type="button"
                              disabled={busyId === mem.id}
                              onClick={() => handleApprove(mem.id)}
                              className="rounded-lg p-1.5 text-emerald-600 hover:bg-emerald-50 dark:text-emerald-400 dark:hover:bg-emerald-500/10"
                              title={t("approve")}
                            >
                              <Check className="h-3.5 w-3.5" />
                            </button>
                          )}
                          <button
                            type="button"
                            disabled={busyId === mem.id}
                            onClick={() => handleDelete(mem.id)}
                            className="rounded-lg p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-500/10 dark:hover:text-red-400"
                            title={t("delete")}
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </button>
                        </div>
                      </div>
                      <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
                        {mem.content}
                      </p>
                    </motion.div>
                  ))
                )}
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
