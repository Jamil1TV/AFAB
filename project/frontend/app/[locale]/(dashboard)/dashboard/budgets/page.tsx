"use client";

import { useCallback, useEffect, useState } from "react";
import {
  PiggyBank,
  Plus,
  Pencil,
  Trash2,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  AlertCircle,
  X,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { toast } from "sonner";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { EmptyState } from "@/components/dashboard/EmptyState";
import { AfabLoader } from "@/components/ui/afab-loader";
import { BudgetApi, BudgetItem, BudgetPeriodType, BudgetSummary } from "@/lib/api/budgets";
import { TransactionService, CategoryItem } from "@/lib/api/transactions";
import { formatCurrency } from "@/lib/currency";

export default function BudgetsPage() {
  const t = useTranslations("Budgets");
  const tSum = useTranslations("Budgets.summary");
  const tStatus = useTranslations("Budgets.status");
  const tCard = useTranslations("Budgets.card");
  const tPeriods = useTranslations("Budgets.periods");
  const tModal = useTranslations("Budgets.modal");
  const tToasts = useTranslations("Budgets.toasts");

  const [summary, setSummary] = useState<BudgetSummary | null>(null);
  const [budgets, setBudgets] = useState<BudgetItem[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<BudgetItem | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const [form, setForm] = useState({
    name: "",
    amount: "",
    categoryId: "",
    periodType: "MONTHLY" as BudgetPeriodType,
    startDate: "",
    endDate: "",
    alertThresholdPercent: "80",
    description: "",
  });

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [sumRes, listRes, catRes] = await Promise.all([
        BudgetApi.getSummary(),
        BudgetApi.list(false),
        TransactionService.getCategories(),
      ]);
      setSummary(sumRes);
      setBudgets(listRes);
      setCategories(catRes.filter((c) => c.type === "EXPENSE"));
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : tToasts("loadError");
      setError(msg);
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  }, [tToasts]);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const [sumRes, listRes, catRes] = await Promise.all([
          BudgetApi.getSummary(),
          BudgetApi.list(false),
          TransactionService.getCategories(),
        ]);
        if (!active) return;
        setSummary(sumRes);
        setBudgets(listRes);
        setCategories(catRes.filter((c) => c.type === "EXPENSE"));
        setError(null);
      } catch (err: unknown) {
        if (!active) return;
        const msg = err instanceof Error ? err.message : tToasts("loadError");
        setError(msg);
        toast.error(msg);
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, [tToasts]);

  const openCreateModal = () => {
    setEditing(null);
    setForm({
      name: "",
      amount: "",
      categoryId: "",
      periodType: "MONTHLY",
      startDate: "",
      endDate: "",
      alertThresholdPercent: "80",
      description: "",
    });
    setIsModalOpen(true);
  };

  const openEditModal = (b: BudgetItem) => {
    setEditing(b);
    setForm({
      name: b.name,
      amount: String(b.budgetAmount),
      categoryId: b.categoryId || "",
      periodType: b.periodType,
      startDate: b.startDate,
      endDate: b.endDate,
      alertThresholdPercent: String(b.alertThresholdPercent),
      description: b.description || "",
    });
    setIsModalOpen(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    const numericAmount = parseFloat(form.amount);
    if (!form.name.trim() || isNaN(numericAmount) || numericAmount <= 0) {
      toast.error(tToasts("validationError"));
      return;
    }
    if (form.periodType === "CUSTOM" && (!form.startDate || !form.endDate)) {
      toast.error(tToasts("customDateError"));
      return;
    }

    setSubmitting(true);
    try {
      const payload = {
        name: form.name.trim(),
        amount: numericAmount,
        categoryId: form.categoryId || null,
        periodType: form.periodType,
        startDate: form.startDate || null,
        endDate: form.endDate || null,
        alertThresholdPercent: parseInt(form.alertThresholdPercent, 10) || 80,
        description: form.description.trim() || null,
      };
      if (editing) {
        await BudgetApi.update(editing.id, payload);
        toast.success(tToasts("updated"));
      } else {
        await BudgetApi.create(payload);
        toast.success(tToasts("created"));
      }
      setIsModalOpen(false);
      await loadData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : tToasts("saveError"));
    } finally {
      setSubmitting(false);
    }
  };

  const handleArchive = async (b: BudgetItem) => {
    try {
      await BudgetApi.archive(b.id);
      toast.success(tToasts("archived"));
      await loadData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : tToasts("archiveError"));
    }
  };

  const currency = summary?.currency || "USD";

  return (
    <div className="afab-page animate-in fade-in duration-500">
      <PageHeader
        title={t("title")}
        subtitle={t("subtitle")}
        actions={
          <button type="button" onClick={openCreateModal} className="afab-btn-primary">
            <Plus className="h-4 w-4" />
            <span>{t("newBudget")}</span>
          </button>
        }
      />

      {error && (
        <div className="rounded-2xl border border-rose-500/30 bg-rose-500/10 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-sm text-rose-700 dark:text-rose-400">
          <div className="flex items-center gap-2">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
          <button
            type="button"
            onClick={loadData}
            className="px-3 py-1.5 rounded-lg bg-rose-500/20 hover:bg-rose-500/30 text-xs font-semibold self-start sm:self-auto"
          >
            {t("retry")}
          </button>
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm">
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400">{tSum("activeBudgets")}</p>
          <p className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
            {summary?.activeBudgetCount ?? 0}
          </p>
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
            {tSum("totalLimit")}: {formatCurrency(summary?.totalBudgeted ?? 0, currency)}
          </p>
        </div>
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm">
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400">{tSum("actualSpending")}</p>
          <p className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
            {formatCurrency(summary?.totalSpent ?? 0, currency)}
          </p>
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
            {tSum("remaining")}: {formatCurrency(summary?.totalRemaining ?? 0, currency)}
          </p>
        </div>
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm">
          <p className="text-xs font-semibold text-amber-600 dark:text-amber-400">{tSum("approaching")}</p>
          <p className="mt-2 text-2xl font-bold text-amber-600 dark:text-amber-400">
            {summary?.approachingCount ?? 0}
          </p>
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">{tSum("approachingHint")}</p>
        </div>
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm">
          <p className="text-xs font-semibold text-rose-600 dark:text-rose-400">{tSum("overBudget")}</p>
          <p className="mt-2 text-2xl font-bold text-rose-600 dark:text-rose-400">
            {summary?.overBudgetCount ?? 0}
          </p>
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">{tSum("overBudgetHint")}</p>
        </div>
      </div>

      {/* Budget Cards Grid */}
      {loading ? (
        <div className="py-16 flex justify-center">
          <AfabLoader text={t("loading")} />
        </div>
      ) : budgets.length === 0 ? (
        <div className="afab-card">
          <EmptyState
            icon={PiggyBank}
            title={t("emptyTitle")}
            description={t("emptyDescription")}
            action={
              <button type="button" onClick={openCreateModal} className="afab-btn-primary">
                <Plus className="h-4 w-4" />
                <span>{t("createFirst")}</span>
              </button>
            }
          />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {budgets.map((b) => {
            const clampedPct = Math.min(100, Math.max(0, b.percentageConsumed));
            const barColor =
              b.alertLevel === "OVER_BUDGET"
                ? "bg-rose-500"
                : b.alertLevel === "APPROACHING"
                ? "bg-amber-500"
                : "bg-emerald-500";
            const categoryLabel = b.categoryId ? b.categoryName : tCard("allExpenses");

            return (
              <div
                key={b.id}
                className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm space-y-4 min-w-0"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-bold text-gray-900 dark:text-white truncate">{b.name}</h3>
                      {b.alertLevel === "OVER_BUDGET" ? (
                        <span className="afab-badge afab-badge-danger inline-flex items-center gap-1">
                          <XCircle className="h-3 w-3" /> {tStatus("overBudget")}
                        </span>
                      ) : b.alertLevel === "APPROACHING" ? (
                        <span className="afab-badge afab-badge-warning inline-flex items-center gap-1">
                          <AlertTriangle className="h-3 w-3" /> {tStatus("approaching")}
                        </span>
                      ) : (
                        <span className="afab-badge afab-badge-success inline-flex items-center gap-1">
                          <CheckCircle2 className="h-3 w-3" /> {tStatus("onTrack")}
                        </span>
                      )}
                    </div>
                    <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                      {categoryLabel} • {tPeriods(b.periodType)} ({b.startDate} → {b.endDate})
                    </p>
                  </div>

                  <div className="flex items-center gap-1 shrink-0">
                    <button
                      type="button"
                      onClick={() => openEditModal(b)}
                      className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-[var(--primary-hover)] dark:hover:text-[var(--primary)] hover:bg-[var(--primary)]/10 transition-colors"
                      title={tCard("editTooltip")}
                    >
                      <Pencil className="h-4 w-4" />
                    </button>
                    <button
                      type="button"
                      onClick={() => handleArchive(b)}
                      className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-rose-600 dark:hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
                      title={tCard("archiveTooltip")}
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>

                {/* Progress Bar */}
                <div>
                  <div className="flex items-baseline justify-between gap-2 text-xs mb-1.5">
                    <span className="font-bold text-gray-900 dark:text-white">
                      {formatCurrency(b.actualSpending, b.currency)}{" "}
                      <span className="font-normal text-gray-500 dark:text-gray-400">
                        {tCard("of")} {formatCurrency(b.budgetAmount, b.currency)}
                      </span>
                    </span>
                    <span
                      className={`font-bold shrink-0 ${
                        b.alertLevel === "OVER_BUDGET"
                          ? "text-rose-600 dark:text-rose-400"
                          : b.alertLevel === "APPROACHING"
                          ? "text-amber-600 dark:text-amber-400"
                          : "text-emerald-600 dark:text-emerald-400"
                      }`}
                    >
                      {b.percentageConsumed.toFixed(1)}%
                    </span>
                  </div>
                  <div className="h-2.5 w-full rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all duration-500 ${barColor}`}
                      style={{ width: `${clampedPct}%` }}
                    />
                  </div>
                </div>

                {/* Bottom Metrics */}
                <div className="flex items-center justify-between gap-2 text-xs pt-2 border-t border-gray-100 dark:border-gray-800/60">
                  {b.overBudgetAmount > 0 ? (
                    <span className="font-semibold text-rose-600 dark:text-rose-400">
                      {tCard("overBy")} {formatCurrency(b.overBudgetAmount, b.currency)}
                    </span>
                  ) : (
                    <span className="text-gray-500 dark:text-gray-400">
                      {tCard("remaining")}:{" "}
                      <strong className="text-gray-900 dark:text-white">
                        {formatCurrency(b.remainingAmount, b.currency)}
                      </strong>
                    </span>
                  )}
                  <span className="text-[11px] text-gray-500 dark:text-gray-400">
                    {tCard("alertAt", { percent: b.alertThresholdPercent })}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Create / Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="w-full max-w-lg max-h-[90vh] flex flex-col rounded-2xl bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200/80 dark:border-gray-800 flex items-center justify-between shrink-0">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">
                {editing ? tModal("editTitle") : tModal("createTitle")}
              </h3>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05]"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSave} className="p-6 space-y-4 overflow-y-auto">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  {tModal("nameLabel")}
                </label>
                <input
                  type="text"
                  required
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder={tModal("namePlaceholder")}
                  className="afab-input w-full"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("limitLabel", { currency })}
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    required
                    value={form.amount}
                    onChange={(e) => setForm({ ...form, amount: e.target.value })}
                    className="afab-input w-full"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("thresholdLabel")}
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="100"
                    value={form.alertThresholdPercent}
                    onChange={(e) => setForm({ ...form, alertThresholdPercent: e.target.value })}
                    className="afab-input w-full"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("categoryLabel")}
                  </label>
                  <select
                    value={form.categoryId}
                    onChange={(e) => setForm({ ...form, categoryId: e.target.value })}
                    className="afab-select w-full"
                  >
                    <option value="">{tModal("allCategories")}</option>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("periodLabel")}
                  </label>
                  <select
                    value={form.periodType}
                    onChange={(e) => setForm({ ...form, periodType: e.target.value as BudgetPeriodType })}
                    className="afab-select w-full"
                  >
                    <option value="MONTHLY">{tModal("periodMonthly")}</option>
                    <option value="QUARTERLY">{tModal("periodQuarterly")}</option>
                    <option value="YEARLY">{tModal("periodYearly")}</option>
                    <option value="CUSTOM">{tModal("periodCustom")}</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("startDate")} {form.periodType !== "CUSTOM" ? tModal("optional") : ""}
                  </label>
                  <input
                    type="date"
                    required={form.periodType === "CUSTOM"}
                    value={form.startDate}
                    onChange={(e) => setForm({ ...form, startDate: e.target.value })}
                    className="afab-input w-full"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("endDate")} {form.periodType !== "CUSTOM" ? tModal("optional") : ""}
                  </label>
                  <input
                    type="date"
                    required={form.periodType === "CUSTOM"}
                    value={form.endDate}
                    onChange={(e) => setForm({ ...form, endDate: e.target.value })}
                    className="afab-input w-full"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  {tModal("descriptionLabel")}
                </label>
                <textarea
                  rows={2}
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="afab-input w-full"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100 dark:border-gray-800/80">
                <button type="button" onClick={() => setIsModalOpen(false)} className="afab-btn-secondary">
                  {tModal("cancel")}
                </button>
                <button type="submit" disabled={submitting} className="afab-btn-primary">
                  {submitting ? tModal("saving") : editing ? tModal("saveChanges") : tModal("createSubmit")}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
