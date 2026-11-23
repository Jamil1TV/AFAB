"use client";

import { useCallback, useEffect, useState } from "react";
import {
  Repeat,
  Plus,
  Play,
  Pause,
  Trash2,
  Pencil,
  Calendar,
  AlertCircle,
  X,
  RefreshCw,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { toast } from "sonner";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { EmptyState } from "@/components/dashboard/EmptyState";
import { AfabLoader } from "@/components/ui/afab-loader";
import {
  RecurringTransactionApi,
  RecurringTransactionItem,
  RecurrenceFrequency,
} from "@/lib/api/recurring";
import { TransactionService, CategoryItem } from "@/lib/api/transactions";
import { UserService } from "@/lib/api/dashboard";
import { formatCurrency } from "@/lib/currency";

const FREQUENCIES: RecurrenceFrequency[] = ["WEEKLY", "MONTHLY", "QUARTERLY", "YEARLY"];
const PAYMENT_METHODS = ["BANK_TRANSFER", "CARD", "CREDIT_CARD", "CASH", "OTHER"] as const;
const CURRENCIES = ["USD", "EUR", "GBP", "TND", "CAD", "MAD", "AED", "SAR"];

export default function RecurringTransactionsPage() {
  const t = useTranslations("Recurring");
  const tTable = useTranslations("Recurring.table");
  const tTypes = useTranslations("Recurring.types");
  const tFreq = useTranslations("Recurring.frequencies");
  const tMethods = useTranslations("Recurring.paymentMethods");
  const tActions = useTranslations("Recurring.actions");
  const tModal = useTranslations("Recurring.modal");
  const tToasts = useTranslations("Recurring.toasts");

  const [rules, setRules] = useState<RecurringTransactionItem[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [baseCurrency, setBaseCurrency] = useState("USD");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingRule, setEditingRule] = useState<RecurringTransactionItem | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [runningId, setRunningId] = useState<string | null>(null);

  const [form, setForm] = useState({
    type: "EXPENSE" as "INCOME" | "EXPENSE",
    description: "",
    amount: "",
    currency: "USD",
    categoryId: "",
    paymentMethod: "BANK_TRANSFER",
    frequency: "MONTHLY" as RecurrenceFrequency,
    startDate: new Date().toISOString().split("T")[0],
    endDate: "",
    notes: "",
  });

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [ruleList, catList, profile] = await Promise.all([
        RecurringTransactionApi.list(),
        TransactionService.getCategories(),
        UserService.getProfile().catch(() => null),
      ]);
      setRules(ruleList);
      setCategories(catList);
      if (profile?.currency) {
        setBaseCurrency(profile.currency);
      }
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
        const [ruleList, catList, profile] = await Promise.all([
          RecurringTransactionApi.list(),
          TransactionService.getCategories(),
          UserService.getProfile().catch(() => null),
        ]);
        if (!active) return;
        setRules(ruleList);
        setCategories(catList);
        if (profile?.currency) {
          setBaseCurrency(profile.currency);
        }
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
    setEditingRule(null);
    setForm({
      type: "EXPENSE",
      description: "",
      amount: "",
      currency: baseCurrency,
      categoryId: "",
      paymentMethod: "BANK_TRANSFER",
      frequency: "MONTHLY",
      startDate: new Date().toISOString().split("T")[0],
      endDate: "",
      notes: "",
    });
    setIsModalOpen(true);
  };

  const openEditModal = (rule: RecurringTransactionItem) => {
    setEditingRule(rule);
    setForm({
      type: rule.type,
      description: rule.description,
      amount: String(rule.amount),
      currency: rule.currency,
      categoryId: rule.categoryId || "",
      paymentMethod: rule.paymentMethod || "BANK_TRANSFER",
      frequency: rule.frequency,
      startDate: rule.startDate,
      endDate: rule.endDate || "",
      notes: rule.notes || "",
    });
    setIsModalOpen(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    const numericAmount = parseFloat(form.amount);
    if (!form.description.trim() || isNaN(numericAmount) || numericAmount <= 0) {
      toast.error(tToasts("validationError"));
      return;
    }

    setSubmitting(true);
    try {
      const payload = {
        type: form.type,
        description: form.description.trim(),
        amount: numericAmount,
        currency: form.currency,
        categoryId: form.categoryId || null,
        paymentMethod: form.paymentMethod,
        frequency: form.frequency,
        startDate: form.startDate,
        endDate: form.endDate || null,
        notes: form.notes.trim() || null,
      };
      if (editingRule) {
        await RecurringTransactionApi.update(editingRule.id, payload);
        toast.success(tToasts("updated"));
      } else {
        await RecurringTransactionApi.create(payload);
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

  const handleToggleActive = async (rule: RecurringTransactionItem) => {
    try {
      await RecurringTransactionApi.setActive(rule.id, !rule.active);
      toast.success(rule.active ? tToasts("paused") : tToasts("resumed"));
      await loadData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : tToasts("statusError"));
    }
  };

  const handleRunDue = async (rule: RecurringTransactionItem) => {
    setRunningId(rule.id);
    try {
      const result = await RecurringTransactionApi.runDue(rule.id);
      if (result.generatedCount > 0) {
        toast.success(tToasts("generated", { count: result.generatedCount }));
      } else {
        toast.info(tToasts("noneDue"));
      }
      await loadData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : tToasts("runError"));
    } finally {
      setRunningId(null);
    }
  };

  const handleDelete = async (rule: RecurringTransactionItem) => {
    try {
      await RecurringTransactionApi.delete(rule.id);
      toast.success(tToasts("deleted"));
      await loadData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : tToasts("deleteError"));
    }
  };

  const filteredCategories = categories.filter((c) => c.type === form.type);

  const formatPaymentMethod = (method: string) => {
    if ((PAYMENT_METHODS as readonly string[]).includes(method)) {
      return tMethods(method as (typeof PAYMENT_METHODS)[number]);
    }
    return method.replace("_", " ");
  };

  return (
    <div className="afab-page animate-in fade-in duration-500">
      <PageHeader
        title={t("title")}
        subtitle={t("subtitle")}
        actions={
          <button type="button" onClick={openCreateModal} className="afab-btn-primary">
            <Plus className="h-4 w-4" />
            <span>{t("newSchedule")}</span>
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

      <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm overflow-hidden">
        {loading ? (
          <div className="py-16 flex justify-center">
            <AfabLoader text={t("loading")} />
          </div>
        ) : rules.length === 0 ? (
          <EmptyState
            icon={Repeat}
            title={t("emptyTitle")}
            description={t("emptyDescription")}
            action={
              <button type="button" onClick={openCreateModal} className="afab-btn-primary">
                <Plus className="h-4 w-4" />
                <span>{t("createFirst")}</span>
              </button>
            }
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="afab-table min-w-[680px]">
              <thead className="afab-thead">
                <tr>
                  <th className="afab-th px-4 text-start">{tTable("description")}</th>
                  <th className="afab-th px-4 text-start">{tTable("type")}</th>
                  <th className="afab-th px-4 text-start">{tTable("amount")}</th>
                  <th className="afab-th px-4 text-start">{tTable("frequency")}</th>
                  <th className="afab-th px-4 text-start">{tTable("nextRun")}</th>
                  <th className="afab-th px-4 text-start">{tTable("status")}</th>
                  <th className="afab-th px-4 text-end">{tTable("actions")}</th>
                </tr>
              </thead>
              <tbody className="afab-tbody">
                {rules.map((rule) => (
                  <tr key={rule.id} className="afab-tr">
                    <td className="afab-td px-4">
                      <p className="font-semibold text-gray-900 dark:text-white">{rule.description}</p>
                      <p className="text-[11px] text-gray-500 dark:text-gray-400">
                        {rule.categoryName || tTable("uncategorized")} • {formatPaymentMethod(rule.paymentMethod)}
                      </p>
                    </td>
                    <td className="afab-td px-4">
                      <span
                        className={`afab-badge ${
                          rule.type === "INCOME" ? "afab-badge-success" : "afab-badge-danger"
                        }`}
                      >
                        {tTypes(rule.type)}
                      </span>
                    </td>
                    <td className="afab-td px-4 font-bold text-gray-900 dark:text-white whitespace-nowrap">
                      {formatCurrency(rule.amount, rule.currency)}
                    </td>
                    <td className="afab-td px-4 text-xs font-medium text-gray-600 dark:text-gray-300">
                      {tFreq(rule.frequency)}
                    </td>
                    <td className="afab-td px-4 text-xs text-gray-600 dark:text-gray-300 whitespace-nowrap">
                      <span className="inline-flex items-center gap-1.5">
                        <Calendar className="h-3.5 w-3.5 text-gray-400" />
                        {rule.nextExecutionDate}
                      </span>
                    </td>
                    <td className="afab-td px-4">
                      <span className={`afab-badge ${rule.active ? "afab-badge-success" : "afab-badge-neutral"}`}>
                        {rule.active ? tTable("active") : tTable("paused")}
                      </span>
                    </td>
                    <td className="afab-td px-4">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          disabled={!rule.active || runningId === rule.id}
                          onClick={() => handleRunDue(rule)}
                          title={tActions("runDue")}
                          className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-indigo-500/10 disabled:opacity-40 transition-colors"
                        >
                          <RefreshCw className={`h-4 w-4 ${runningId === rule.id ? "animate-spin" : ""}`} />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleToggleActive(rule)}
                          title={rule.active ? tActions("pause") : tActions("resume")}
                          className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-amber-600 dark:hover:text-amber-400 hover:bg-amber-500/10 transition-colors"
                        >
                          {rule.active ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                        </button>
                        <button
                          type="button"
                          onClick={() => openEditModal(rule)}
                          title={tActions("edit")}
                          className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-[#7c3aed] dark:hover:text-[#a78bfa] hover:bg-purple-500/10 transition-colors"
                        >
                          <Pencil className="h-4 w-4" />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDelete(rule)}
                          title={tActions("delete")}
                          className="p-1.5 rounded-lg text-gray-500 dark:text-gray-400 hover:text-rose-600 dark:hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create / Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="w-full max-w-lg max-h-[90vh] flex flex-col rounded-2xl bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 shadow-2xl overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200/80 dark:border-gray-800 flex items-center justify-between shrink-0">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">
                {editingRule ? tModal("editTitle") : tModal("createTitle")}
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
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("typeLabel")}
                  </label>
                  <select
                    value={form.type}
                    onChange={(e) => setForm({ ...form, type: e.target.value as "INCOME" | "EXPENSE", categoryId: "" })}
                    className="afab-select w-full"
                  >
                    <option value="EXPENSE">{tTypes("EXPENSE")}</option>
                    <option value="INCOME">{tTypes("INCOME")}</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("frequencyLabel")}
                  </label>
                  <select
                    value={form.frequency}
                    onChange={(e) => setForm({ ...form, frequency: e.target.value as RecurrenceFrequency })}
                    className="afab-select w-full"
                  >
                    {FREQUENCIES.map((f) => (
                      <option key={f} value={f}>{tFreq(f)}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  {tModal("descriptionLabel")}
                </label>
                <input
                  type="text"
                  required
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  placeholder={tModal("descriptionPlaceholder")}
                  className="afab-input w-full"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="sm:col-span-2">
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("amountLabel")}
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
                    {tModal("currencyLabel")}
                  </label>
                  <select
                    value={form.currency}
                    onChange={(e) => setForm({ ...form, currency: e.target.value })}
                    className="afab-select w-full"
                  >
                    {Array.from(new Set([baseCurrency, ...CURRENCIES])).map((c) => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
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
                    <option value="">{tTable("uncategorized")}</option>
                    {filteredCategories.map((cat) => (
                      <option key={cat.id} value={cat.id}>{cat.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("paymentMethodLabel")}
                  </label>
                  <select
                    value={form.paymentMethod}
                    onChange={(e) => setForm({ ...form, paymentMethod: e.target.value })}
                    className="afab-select w-full"
                  >
                    {PAYMENT_METHODS.map((pm) => (
                      <option key={pm} value={pm}>{tMethods(pm)}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("startDateLabel")}
                  </label>
                  <input
                    type="date"
                    required
                    value={form.startDate}
                    onChange={(e) => setForm({ ...form, startDate: e.target.value })}
                    className="afab-input w-full"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    {tModal("endDateLabel")}
                  </label>
                  <input
                    type="date"
                    value={form.endDate}
                    onChange={(e) => setForm({ ...form, endDate: e.target.value })}
                    className="afab-input w-full"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  {tModal("notesLabel")}
                </label>
                <textarea
                  rows={2}
                  value={form.notes}
                  onChange={(e) => setForm({ ...form, notes: e.target.value })}
                  className="afab-input w-full"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100 dark:border-gray-800/80">
                <button type="button" onClick={() => setIsModalOpen(false)} className="afab-btn-secondary">
                  {tModal("cancel")}
                </button>
                <button type="submit" disabled={submitting} className="afab-btn-primary">
                  {submitting ? tModal("saving") : editingRule ? tModal("saveChanges") : tModal("createSubmit")}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
