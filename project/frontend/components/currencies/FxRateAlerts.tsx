"use client";

import React, { useState } from "react";
import { Bell, Plus, Trash2, CheckCircle2, AlertTriangle, ArrowRight } from "lucide-react";
import { CurrencyPair } from "@/lib/api/currencies";

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

export function FxRateAlerts({ pairs, baseCurrency = "QAR", isArabic = false }: FxRateAlertsProps) {
  const [alerts, setAlerts] = useState<FxRateAlert[]>([
    {
      id: "1",
      pair: `${baseCurrency}/USD`,
      targetRate: 0.28,
      direction: "above",
      createdAt: "Today",
      isActive: true,
    },
    {
      id: "2",
      pair: `${baseCurrency}/EUR`,
      targetRate: 0.25,
      direction: "above",
      createdAt: "Today",
      isActive: true,
    },
  ]);

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

    setAlerts((prev) => [alert, ...prev]);
    setNewTarget("");
    setShowAddForm(false);
  };

  const handleDeleteAlert = (id: string) => {
    setAlerts((prev) => prev.filter((a) => a.id !== id));
  };

  const handleToggleAlert = (id: string) => {
    setAlerts((prev) =>
      prev.map((a) => (a.id === id ? { ...a, isActive: !a.isActive } : a))
    );
  };

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-xs flex flex-col justify-between transition-all duration-200">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800/80">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400">
            <Bell className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {isArabic ? "تنبيهات أسعار الصرف المستهدفة" : "Target Rate Alerts"}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {isArabic ? "تلقي إشعارات فورية عند بلوغ سعر صرف مستهدف" : "Monitor FX thresholds and get notified automatically"}
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => setShowAddForm(!showAddForm)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-purple-500/10 hover:bg-purple-500/20 text-purple-600 dark:text-purple-400 text-xs font-bold transition-colors"
        >
          <Plus className="h-4 w-4" />
          <span>{showAddForm ? (isArabic ? "إلغاء" : "Cancel") : (isArabic ? "إضافة تنبيه" : "New Alert")}</span>
        </button>
      </div>

      {/* Add Alert Inline Form */}
      {showAddForm && (
        <form onSubmit={handleAddAlert} className="p-4 my-3 rounded-xl bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 space-y-3 animate-in fade-in">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="text-[11px] font-semibold text-gray-500 dark:text-gray-400 block mb-1">
                {isArabic ? "زوج العملات" : "Currency Pair"}
              </label>
              <select
                value={newPair}
                onChange={(e) => setNewPair(e.target.value)}
                className="w-full rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-2 text-xs font-bold text-gray-900 dark:text-white"
              >
                {pairs.map((p) => (
                  <option key={p.symbol} value={p.symbol}>
                    {p.symbol} (Now: {p.rate.toFixed(4)})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-[11px] font-semibold text-gray-500 dark:text-gray-400 block mb-1">
                {isArabic ? "الشرط" : "Condition"}
              </label>
              <select
                value={newDirection}
                onChange={(e) => setNewDirection(e.target.value as "above" | "below")}
                className="w-full rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-2 text-xs font-bold text-gray-900 dark:text-white"
              >
                <option value="above">{isArabic ? "يرتفع فوق" : "Rises above"}</option>
                <option value="below">{isArabic ? "ينخفض تحت" : "Drops below"}</option>
              </select>
            </div>

            <div>
              <label className="text-[11px] font-semibold text-gray-500 dark:text-gray-400 block mb-1">
                {isArabic ? "السعر المستهدف" : "Target Rate"}
              </label>
              <input
                type="number"
                step="any"
                required
                value={newTarget}
                onChange={(e) => setNewTarget(e.target.value)}
                placeholder="e.g. 0.2850"
                className="w-full rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-2 text-xs font-mono font-bold text-gray-900 dark:text-white outline-none focus:border-purple-500"
              />
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-1">
            <button
              type="submit"
              className="px-4 py-1.5 rounded-lg bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold shadow-xs transition-colors"
            >
              {isArabic ? "حفظ التنبيه" : "Save Alert"}
            </button>
          </div>
        </form>
      )}

      {/* Alerts List */}
      <div className="divide-y divide-gray-100 dark:divide-gray-800/80 py-2 space-y-1">
        {alerts.length === 0 ? (
          <div className="text-center py-6 text-xs text-gray-400">
            {isArabic ? "لا توجد تنبيهات أسعار نشطة حالياً." : "No target rate alerts created yet."}
          </div>
        ) : (
          alerts.map((a) => {
            const currentPair = pairs.find((p) => p.symbol === a.pair);
            const currentRate = currentPair?.rate || a.targetRate;
            const diffPct = ((a.targetRate - currentRate) / currentRate) * 100;

            return (
              <div
                key={a.id}
                className="flex items-center justify-between py-3 px-2 rounded-xl hover:bg-gray-50/80 dark:hover:bg-gray-800/40 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={a.isActive}
                    onChange={() => handleToggleAlert(a.id)}
                    className="h-4 w-4 rounded text-purple-600 focus:ring-purple-500"
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
                    <span className="text-[10px] text-gray-400 block mt-0.5">
                      Current: {currentRate.toFixed(4)} • {Math.abs(diffPct).toFixed(2)}% away
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      a.isActive
                        ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
                        : "bg-gray-100 dark:bg-gray-800 text-gray-400"
                    }`}
                  >
                    {a.isActive ? (isArabic ? "نشط" : "Active") : (isArabic ? "معطل" : "Paused")}
                  </span>

                  <button
                    type="button"
                    onClick={() => handleDeleteAlert(a.id)}
                    className="text-gray-400 hover:text-red-500 transition-colors p-1"
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
