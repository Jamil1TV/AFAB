"use client";

import { useState } from "react";
import { 
  X, 
  Plus, 
  Trash2, 
  Lock, 
  Tag, 
  DollarSign, 
  Briefcase, 
  TrendingUp, 
  Building, 
  Laptop, 
  Users, 
  Package, 
  Plane, 
  ShoppingBag,
  AlertCircle,
  CheckCircle2
} from "lucide-react";
import { CategoryItem, CategoryService } from "@/lib/api/categories";
import { useTranslations } from "next-intl";

interface ManageCategoriesModalProps {
  isOpen: boolean;
  onClose: () => void;
  categories: CategoryItem[];
  onCategoriesChanged: () => void;
}

const AVAILABLE_COLORS = [
  "#10b981", // Emerald
  "#06b6d4", // Cyan
  "#8b5cf6", // Purple
  "#3b82f6", // Blue
  "#f59e0b", // Amber
  "#ef4444", // Red
  "#ec4899", // Pink
  "#64748b", // Slate
];

const AVAILABLE_ICONS = [
  { name: "Tag", icon: Tag },
  { name: "DollarSign", icon: DollarSign },
  { name: "Briefcase", icon: Briefcase },
  { name: "TrendingUp", icon: TrendingUp },
  { name: "Building", icon: Building },
  { name: "Laptop", icon: Laptop },
  { name: "Users", icon: Users },
  { name: "Package", icon: Package },
  { name: "Plane", icon: Plane },
  { name: "ShoppingBag", icon: ShoppingBag },
];

export function ManageCategoriesModal({
  isOpen,
  onClose,
  categories,
  onCategoriesChanged,
}: ManageCategoriesModalProps) {
  const t = useTranslations("Transactions.categoriesModal");

  const [activeTab, setActiveTab] = useState<"INCOME" | "EXPENSE">("EXPENSE");
  const [isAdding, setIsAdding] = useState(false);
  const [newName, setNewName] = useState("");
  const [newColor, setNewColor] = useState(AVAILABLE_COLORS[2]);
  const [newIcon, setNewIcon] = useState(AVAILABLE_ICONS[0].name);
  const [submitting, setSubmitting] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  if (!isOpen) return null;

  const filteredCategories = categories.filter(
    (c) => c.type.toUpperCase() === activeTab.toUpperCase()
  );

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;

    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      await CategoryService.createCategory({
        name: newName.trim(),
        type: activeTab,
        color: newColor,
        icon: newIcon,
      });

      setNewName("");
      setIsAdding(false);
      setSuccess(t("createSuccess"));
      onCategoriesChanged();
    } catch (err: unknown) {
      const apiErr = err as { message?: string };
      setError(apiErr.message || "Failed to create category");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (cat: CategoryItem) => {
    if (cat.isSystemDefault) return;
    if (!confirm(t("deleteConfirm"))) return;

    setDeletingId(cat.id);
    setError(null);
    setSuccess(null);

    try {
      await CategoryService.deleteCategory(cat.id);
      setSuccess(t("deleteSuccess"));
      onCategoriesChanged();
    } catch (err: unknown) {
      const apiErr = err as { status?: number; message?: string };
      if (apiErr.status === 409 || apiErr.message?.includes("used by")) {
        setError(t("inUseError"));
      } else {
        setError(apiErr.message || "Failed to delete category");
      }
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div
        className="relative w-full max-w-xl max-h-[85vh] flex flex-col overflow-hidden rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] shadow-2xl transition-all"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 p-6">
          <div>
            <h2 className="text-xl font-bold tracking-tight text-gray-900 dark:text-white">
              {t("title")}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {t("subtitle")}
            </p>
          </div>
          <button
            onClick={onClose}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-white/[0.05] dark:hover:text-white transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Tab switcher */}
        <div className="px-6 pt-4 pb-2">
          <div className="grid grid-cols-2 gap-2 p-1.5 bg-gray-100 dark:bg-[#080c18] rounded-2xl border border-gray-200/50 dark:border-gray-800/60">
            <button
              type="button"
              onClick={() => {
                setActiveTab("EXPENSE");
                setError(null);
                setSuccess(null);
              }}
              className={`py-2 rounded-xl text-xs font-bold transition-all ${
                activeTab === "EXPENSE"
                  ? "bg-purple-600 text-white shadow-md shadow-purple-600/20"
                  : "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              }`}
            >
              {t("expenseTab")}
            </button>
            <button
              type="button"
              onClick={() => {
                setActiveTab("INCOME");
                setError(null);
                setSuccess(null);
              }}
              className={`py-2 rounded-xl text-xs font-bold transition-all ${
                activeTab === "INCOME"
                  ? "bg-emerald-500 text-white shadow-md shadow-emerald-500/20"
                  : "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              }`}
            >
              {t("incomeTab")}
            </button>
          </div>
        </div>

        {/* Alerts */}
        {error && (
          <div className="mx-6 my-2 flex items-center gap-2 rounded-xl bg-red-50 dark:bg-red-500/10 p-3 text-xs font-medium text-red-600 dark:text-red-400 border border-red-200 dark:border-red-500/20">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}
        {success && (
          <div className="mx-6 my-2 flex items-center gap-2 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 p-3 text-xs font-medium text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/20">
            <CheckCircle2 className="h-4 w-4 shrink-0" />
            <span>{success}</span>
          </div>
        )}

        {/* Body / List */}
        <div className="flex-1 overflow-y-auto px-6 py-3 space-y-2.5 custom-scrollbar">
          {/* Add Category Trigger / Form */}
          {!isAdding ? (
            <button
              type="button"
              onClick={() => {
                setIsAdding(true);
                setError(null);
              }}
              className="flex w-full items-center justify-center gap-2 py-3 rounded-2xl border-2 border-dashed border-gray-200 dark:border-gray-800 text-xs font-bold text-gray-600 dark:text-gray-300 hover:border-[#8b5cf6] hover:text-[#8b5cf6] dark:hover:border-[#8b5cf6] dark:hover:text-[#8b5cf6] transition-colors"
            >
              <Plus className="h-4 w-4" />
              {t("newCategory")}
            </button>
          ) : (
            <form onSubmit={handleCreate} className="rounded-2xl border border-[#8b5cf6]/40 bg-[#8b5cf6]/5 p-4 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-gray-900 dark:text-white">
                  {t("newCategory")} ({activeTab})
                </span>
                <button
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              <div>
                <label className="block text-[11px] font-medium text-gray-600 dark:text-gray-400 mb-1">
                  {t("nameLabel")} *
                </label>
                <input
                  type="text"
                  required
                  maxLength={100}
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder={t("namePlaceholder")}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#0c101c] px-3 py-2 text-xs text-gray-900 dark:text-white focus:border-[#8b5cf6] focus:outline-none"
                />
              </div>

              {/* Color selector */}
              <div>
                <label className="block text-[11px] font-medium text-gray-600 dark:text-gray-400 mb-1">
                  {t("colorLabel")}
                </label>
                <div className="flex items-center gap-2 flex-wrap">
                  {AVAILABLE_COLORS.map((color) => (
                    <button
                      key={color}
                      type="button"
                      onClick={() => setNewColor(color)}
                      style={{ backgroundColor: color }}
                      className={`h-6 w-6 rounded-full transition-transform ${
                        newColor === color ? "scale-125 ring-2 ring-white ring-offset-2 ring-offset-black" : "opacity-80 hover:opacity-100"
                      }`}
                    />
                  ))}
                </div>
              </div>

              {/* Icon selector */}
              <div>
                <label className="block text-[11px] font-medium text-gray-600 dark:text-gray-400 mb-1">
                  {t("iconLabel")}
                </label>
                <div className="flex items-center gap-2 flex-wrap">
                  {AVAILABLE_ICONS.map((item) => {
                    const IconComp = item.icon;
                    return (
                      <button
                        key={item.name}
                        type="button"
                        onClick={() => setNewIcon(item.name)}
                        className={`flex h-7 w-7 items-center justify-center rounded-lg border text-xs transition-all ${
                          newIcon === item.name
                            ? "border-[#8b5cf6] bg-[#8b5cf6] text-white"
                            : "border-gray-200 dark:border-gray-700 bg-white dark:bg-[#0c101c] text-gray-600 dark:text-gray-400"
                        }`}
                      >
                        <IconComp className="h-3.5 w-3.5" />
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold text-gray-500 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  {t("cancel")}
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-4 py-1.5 rounded-lg text-xs font-bold bg-[#8b5cf6] text-white hover:bg-[#7c3aed] disabled:opacity-50"
                >
                  {submitting ? "..." : t("createBtn")}
                </button>
              </div>
            </form>
          )}

          {/* Categories List */}
          {filteredCategories.map((cat) => (
            <div
              key={cat.id}
              className="flex items-center justify-between p-3 rounded-2xl border border-gray-100 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18] hover:border-gray-200 dark:hover:border-gray-700 transition-colors"
            >
              <div className="flex items-center gap-3">
                <div
                  className="flex h-9 w-9 items-center justify-center rounded-xl text-white shadow-sm"
                  style={{ backgroundColor: cat.color || "#8b5cf6" }}
                >
                  <Tag className="h-4 w-4" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-900 dark:text-white">
                    {cat.name}
                  </p>
                  <span className="text-[10px] text-gray-400">
                    {cat.type}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                {cat.isSystemDefault ? (
                  <span className="flex items-center gap-1 rounded-full bg-gray-200 dark:bg-gray-800 px-2 py-0.5 text-[10px] font-semibold text-gray-600 dark:text-gray-400">
                    <Lock className="h-3 w-3" />
                    {t("systemDefault")}
                  </span>
                ) : (
                  <>
                    <span className="rounded-full bg-purple-100 dark:bg-purple-950/40 px-2 py-0.5 text-[10px] font-semibold text-purple-600 dark:text-purple-400">
                      {t("custom")}
                    </span>
                    <button
                      type="button"
                      onClick={() => handleDelete(cat)}
                      disabled={deletingId === cat.id}
                      title={t("deleteTooltip")}
                      className="flex h-7 w-7 items-center justify-center rounded-lg text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end p-4 border-t border-gray-100 dark:border-gray-800/60">
          <button
            type="button"
            onClick={onClose}
            className="px-5 py-2 rounded-xl text-xs font-bold bg-gray-900 text-white dark:bg-white dark:text-gray-900 hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors"
          >
            {t("close")}
          </button>
        </div>
      </div>
    </div>
  );
}
