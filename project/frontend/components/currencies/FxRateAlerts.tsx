"use client";

import React, { useState } from "react";
import { Bell, Plus, Trash2 } from "lucide-react";
import { CurrencyPair } from "@/lib/api/currencies";
import { EmptyState } from "@/components/dashboard/EmptyState";

interface FxRateAlert {
  id: string;
  pair: string;
  targetRate: number;
  direction: "above" | "below";
  createdAt: string;
  isActive: boolean;
}

interface FxRateAlertsProps {
  pairs: CurrencyPair[];
  baseCurrency?: string;
  isArabic?: boolean;
}

const ALERTS_STORAGE_KEY = "afab_fx_rate_alerts";

export function FxRateAlerts({ pairs, baseCurrency = "QAR", isArabic = false }: FxRateAlertsProps) {
  const [alerts, setAlerts] = useState<FxRateAlert[]>(() => {
    if (typeof window === "undefined") return [];
    try {
      const saved = localStorage.getItem(ALERTS_STORAGE_KEY);
      return saved ? (JSON.parse(saved) as FxRateAlert[]) : [];
    } catch {
      return [];
    }
  });

  const persistAlerts = (updater: (prev: FxRateAlert[]) => FxRateAlert[]) => {
    setAlerts((prev) => {
      const next = updater(prev);
      if (typeof window !== "undefined") {
        localStorage.setItem(ALERTS_STORAGE_KEY, JSON.stringify(next));
      }
      return next;
    });
  };

  const [newPair, setNewPair] = useState<string>(pairs[0]?.symbol || `${baseCurrency}/USD`);
  const [newTarget, setNewTarget] = useState<string>("");
  const [newDirection, setNewDirection] = useState<"above" | "below">("above");
  const [showAddForm, setShowAddForm] = useState<boolean>(false);

  const handleAddAlert = (e: React.FormEvent) => {
    e.preventDefault();
    const val = parseFloat(newTarget);
    if (!val || val <= 0) return;

    const alert: FxRateAlert = {
      id: Date.now().toString(),
      pair: newPair,
      targetRate: val,
      direction: newDirection,
      createdAt: "Just now",
      isActive: true,
    };

    persistAlerts((prev) => [alert, ...prev]);
    setNewTarget("");
    setShowAddForm(false);
  };

  const handleDeleteAlert = (id: string) => {
    persistAlerts((prev) => prev.filter((a) => a.id !== id));
  };

  const handleToggleAlert = (id: string) => {
    persistAlerts((prev) =>
      prev.map((a) => (a.id === id ? { ...a, isActive: !a.isActive } : a))
    );
  };

  return (
    <div className="afab-card p-6 flex flex-col justify-between transition-all duration-200">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800/60">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400">
            <Bell className="h-5 w-5" />
          </div>
          <div>
            <h3 className="afab-card-title">
              {isArabic ? "تنبيهات أسعار الصرف المستهدفة" : "Target Rate Alerts"}
            </h3>
            <p className="afab-card-subtitle text-xs mt-0.5">
              {isArabic ? "تلقي إشعارات فورية عند بلوغ سعر صرف مستهدف" : "Monitor FX thresholds and get notified automatically"}
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => setShowAddForm(!showAddForm)}
          className="afab-btn-soft"
        >
          <Plus className="h-4 w-4" />
          <span>{showAddForm ? (isArabic ? "إلغاء" : "Cancel") : (isArabic ? "إضافة تنبيه" : "New Alert")}</span>
        </button>
      </div>

      {/* Add Alert Inline Form */}
      {showAddForm && (
        <form onSubmit={handleAddAlert} className="afab-inset p-4 my-3 space-y-3 animate-in fade-in">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="afab-label">
                {isArabic ? "زوج العملات" : "Currency Pair"}
              </label>
              <select
                value={newPair}
                onChange={(e) => setNewPair(e.target.value)}
                className="afab-select w-full font-bold text-gray-900 dark:text-white"
              >
                {pairs.map((p) => (
                  <option key={p.symbol} value={p.symbol}>
                    {p.symbol} (Now: {p.rate.toFixed(4)})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="afab-label">
                {isArabic ? "الشرط" : "Condition"}
              </label>
              <select
                value={newDirection}
                onChange={(e) => setNewDirection(e.target.value as "above" | "below")}
                className="afab-select w-full font-bold text-gray-900 dark:text-white"
              >
                <option value="above">{isArabic ? "يرتفع فوق" : "Rises above"}</option>
                <option value="below">{isArabic ? "ينخفض تحت" : "Drops below"}</option>
              </select>
            </div>

            <div>
              <label className="afab-label">
                {isArabic ? "السعر المستهدف" : "Target Rate"}
              </label>
              <input
                type="number"
                step="any"
                required
                value={newTarget}
                onChange={(e) => setNewTarget(e.target.value)}
                placeholder="e.g. 0.2850"
                className="afab-input font-mono font-bold text-xs"
              />
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-1">
            <button
              type="submit"
              className="afab-btn-primary"
            >
              {isArabic ? "حفظ التنبيه" : "Save Alert"}
            </button>
          </div>
        </form>
      )}

      {/* Alerts List */}
      <div className="divide-y divide-gray-100 dark:divide-gray-800/40 py-2 space-y-1">
        {alerts.length === 0 ? (
          <EmptyState
            icon={Bell}
            title={isArabic ? "لا توجد تنبيهات أسعار نشطة حالياً." : "No target rate alerts created yet."}
            className="py-8"
          />
        ) : (
          alerts.map((a) => {
            const currentPair = pairs.find((p) => p.symbol === a.pair);
            const currentRate = currentPair?.rate || a.targetRate;
            const diffPct = ((a.targetRate - currentRate) / currentRate) * 100;

            return (
              <div
                key={a.id}
                className="flex items-center justify-between py-3 px-3 rounded-xl hover:bg-gray-50/80 dark:hover:bg-white/[0.02] transition-colors"
              >
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={a.isActive}
                    onChange={() => handleToggleAlert(a.id)}
                    className="h-4 w-4 rounded border-gray-300 dark:border-gray-700 accent-[var(--primary)] focus:ring-[var(--primary)]"
                  />
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-gray-900 dark:text-white font-mono">
                        {a.pair}
                      </span>
                      <span className="text-[11px] font-semibold text-gray-500 dark:text-gray-400">
                        {a.direction === "above" ? "≥" : "≤"} {a.targetRate.toFixed(4)}
                      </span>
                    </div>
                    <span className="text-[10px] text-gray-400 dark:text-gray-500 block mt-0.5">
                      Current: {currentRate.toFixed(4)} • {Math.abs(diffPct).toFixed(2)}% away
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <span
                    className={`afab-badge ${
                      a.isActive
                        ? "afab-badge-success"
                        : "afab-badge-neutral"
                    }`}
                  >
                    {a.isActive ? (isArabic ? "نشط" : "Active") : (isArabic ? "معطل" : "Paused")}
                  </span>

                  <button
                    type="button"
                    onClick={() => handleDeleteAlert(a.id)}
                    className="afab-icon-btn hover:text-red-600 dark:hover:text-red-400"
                    title="Delete alert"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
