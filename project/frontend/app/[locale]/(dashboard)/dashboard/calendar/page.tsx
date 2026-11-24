"use client";

import { useState, useEffect, useMemo } from "react";
import {
  CalendarDays,
  ChevronLeft,
  ChevronRight,
  ArrowUpRight,
  ArrowDownLeft,
  Plus,
  Clock,
  Receipt,
} from "lucide-react";
import { useLocale } from "next-intl";
import { Link } from "@/i18n/routing";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { StatCard } from "@/components/dashboard/StatCard";
import { EmptyState } from "@/components/dashboard/EmptyState";
import { AfabLoader } from "@/components/ui/afab-loader";
import { TransactionService, TransactionItem } from "@/lib/api/transactions";
import { UserService } from "@/lib/api/dashboard";
import { formatCurrency } from "@/lib/currency";

export default function CalendarPage() {
  const locale = useLocale();
  const isAr = locale === "ar";

  const [currentMonth, setCurrentMonth] = useState<Date>(() => {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
  });
  const [selectedDate, setSelectedDate] = useState<string>(
    () => new Date().toISOString().split("T")[0]
  );
  const [transactions, setTransactions] = useState<TransactionItem[]>([]);
  const [currency, setCurrency] = useState<string>("USD");
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    UserService.getProfile()
      .then((p) => {
        if (p?.currency) setCurrency(p.currency);
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    let active = true;
    TransactionService.getTransactions({ page: 0, size: 100 })
      .then((res) => {
        if (!active) return;
        setTransactions(res?.content || []);
        if (res?.currency) setCurrency(res.currency);
      })
      .catch(() => {
        if (active) setTransactions([]);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);

  const year = currentMonth.getFullYear();
  const month = currentMonth.getMonth();
  const monthPrefix = `${year}-${String(month + 1).padStart(2, "0")}`;

  const monthTransactions = useMemo(
    () => transactions.filter((t) => t.transactionDate?.startsWith(monthPrefix)),
    [transactions, monthPrefix]
  );

  const byDate = useMemo(() => {
    const map: Record<string, TransactionItem[]> = {};
    for (const tx of monthTransactions) {
      const d = tx.transactionDate;
      if (!d) continue;
      if (!map[d]) map[d] = [];
      map[d].push(tx);
    }
    return map;
  }, [monthTransactions]);

  const monthIncome = useMemo(
    () =>
      monthTransactions
        .filter((t) => t.type === "INCOME" && t.status === "COMPLETED")
        .reduce((s, t) => s + (Number(t.amount) || 0), 0),
    [monthTransactions]
  );

  const monthExpense = useMemo(
    () =>
      monthTransactions
        .filter((t) => t.type === "EXPENSE" && t.status === "COMPLETED")
        .reduce((s, t) => s + (Number(t.amount) || 0), 0),
    [monthTransactions]
  );

  const pendingItems = useMemo(
    () => monthTransactions.filter((t) => t.status === "PENDING"),
    [monthTransactions]
  );

  // Build calendar cells
  const calendarDays = useMemo(() => {
    const firstDayIndex = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const cells: Array<{ dateStr: string | null; dayNum: number | null }> = [];

    for (let i = 0; i < firstDayIndex; i++) {
      cells.push({ dateStr: null, dayNum: null });
    }
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${year}-${String(month + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
      cells.push({ dateStr, dayNum: d });
    }
    return cells;
  }, [year, month]);

  const selectedDayTransactions = byDate[selectedDate] || [];

  const monthLabel = currentMonth.toLocaleString(isAr ? "ar-EG" : "en-US", {
    month: "long",
    year: "numeric",
  });

  const weekDays = isAr
    ? ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
    : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  return (
    <div className="afab-page animate-in fade-in duration-700">
      <PageHeader
        title={isAr ? "التقويم المالي" : "Financial Calendar"}
        subtitle={
          isAr
            ? "تتبع المعاملات المسجلة، التدفقات النقدية اليومية، والمستحقات حسب التاريخ."
            : "Track recorded transactions, daily cash flows, and pending obligations by date."
        }
        actions={
          <div className="flex items-center gap-2">
            <div className="afab-card flex items-center gap-1 p-1">
              <button
                type="button"
                onClick={() => setCurrentMonth(new Date(year, month - 1, 1))}
                className="afab-page-btn border-0"
                aria-label="Previous month"
              >
                <ChevronLeft className="h-4 w-4 rtl:rotate-180" />
              </button>
              <span className="px-3 text-xs font-bold text-gray-900 dark:text-white min-w-[130px] text-center capitalize">
                {monthLabel}
              </span>
              <button
                type="button"
                onClick={() => setCurrentMonth(new Date(year, month + 1, 1))}
                className="afab-page-btn border-0"
                aria-label="Next month"
              >
                <ChevronRight className="h-4 w-4 rtl:rotate-180" />
              </button>
            </div>
            <Link href="/dashboard/transactions" className="afab-btn-primary">
              <Plus className="h-4 w-4" />
              <span>{isAr ? "إضافة معاملة" : "Add Transaction"}</span>
            </Link>
          </div>
        }
      />

      {/* KPI Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title={isAr ? "إيرادات الشهر" : "Monthly Inflow"}
          value={formatCurrency(monthIncome, currency)}
          icon={ArrowUpRight}
          tone="success"
          hint={monthLabel}
        />
        <StatCard
          title={isAr ? "مصروفات الشهر" : "Monthly Outflow"}
          value={formatCurrency(monthExpense, currency)}
          icon={ArrowDownLeft}
          tone="danger"
          hint={monthLabel}
        />
        <StatCard
          title={isAr ? "معاملات معلقة" : "Pending Items"}
          value={pendingItems.length}
          icon={Clock}
          tone="warning"
          hint={isAr ? "تنتظر التسوية" : "Awaiting settlement"}
        />
        <StatCard
          title={isAr ? "إجمالي الحركات" : "Recorded Entries"}
          value={monthTransactions.length}
          icon={CalendarDays}
          tone="primary"
          hint={monthLabel}
        />
      </div>

      {loading ? (
        <div className="afab-card py-20 flex items-center justify-center">
          <AfabLoader text={isAr ? "جاري تحميل التقويم المالي..." : "Loading financial calendar..."} />
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Calendar Grid (8 cols) */}
          <div className="lg:col-span-8 afab-card p-6">
            <div className="grid grid-cols-7 gap-2 mb-3 text-center">
              {weekDays.map((wd) => (
                <div
                  key={wd}
                  className="text-[11px] font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 py-1"
                >
                  {wd}
                </div>
              ))}
            </div>

            <div className="grid grid-cols-7 gap-2">
              {calendarDays.map((cell, idx) => {
                if (!cell.dateStr || !cell.dayNum) {
                  return <div key={`empty-${idx}`} className="h-20 sm:h-24 rounded-xl bg-transparent" />;
                }

                const dayTxs = byDate[cell.dateStr] || [];
                const dayIn = dayTxs
                  .filter((t) => t.type === "INCOME")
                  .reduce((s, t) => s + (Number(t.amount) || 0), 0);
                const dayOut = dayTxs
                  .filter((t) => t.type === "EXPENSE")
                  .reduce((s, t) => s + (Number(t.amount) || 0), 0);
                const isSelected = selectedDate === cell.dateStr;
                const isToday = cell.dateStr === new Date().toISOString().split("T")[0];

                return (
                  <button
                    key={cell.dateStr}
                    type="button"
                    onClick={() => setSelectedDate(cell.dateStr!)}
                    className={`h-20 sm:h-24 rounded-xl p-2 text-start flex flex-col justify-between border transition-all ${
                      isSelected
                        ? "border-[var(--primary)] bg-[var(--primary)]/10 dark:bg-[var(--primary)]/15 shadow-sm"
                        : "border-gray-100 dark:border-gray-800/60 bg-gray-50/40 dark:bg-[#080c18]/60 hover:border-gray-300 dark:hover:border-gray-700"
                    }`}
                  >
                    <div className="flex items-center justify-between w-full">
                      <span
                        className={`text-xs font-bold ${
                          isSelected
                            ? "text-[var(--primary-hover)] dark:text-[var(--primary)]"
                            : isToday
                            ? "text-[var(--primary)]"
                            : "text-gray-700 dark:text-gray-300"
                        }`}
                      >
                        {cell.dayNum}
                      </span>
                      {dayTxs.length > 0 && (
                        <span className="afab-badge afab-badge-primary px-1.5 py-0 text-[9px]">
                          {dayTxs.length}
                        </span>
                      )}
                    </div>

                    <div className="space-y-0.5 w-full overflow-hidden">
                      {dayIn > 0 && (
                        <div className="text-[10px] font-mono font-semibold text-emerald-600 dark:text-emerald-400 truncate">
                          +{formatCurrency(dayIn, currency)}
                        </div>
                      )}
                      {dayOut > 0 && (
                        <div className="text-[10px] font-mono font-semibold text-red-600 dark:text-red-400 truncate">
                          -{formatCurrency(dayOut, currency)}
                        </div>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Selected Date Ledger Panel (4 cols) */}
          <div className="lg:col-span-4 afab-card p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 pb-4">
              <div>
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                  {isAr ? "سجل اليوم المحدد" : "Selected Date Activity"}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 font-mono mt-0.5">
                  {selectedDate}
                </p>
              </div>
              <span className="afab-badge afab-badge-neutral">
                {selectedDayTransactions.length} {isAr ? "حركات" : "entries"}
              </span>
            </div>

            {selectedDayTransactions.length === 0 ? (
              <EmptyState
                icon={Receipt}
                title={isAr ? "لا توجد معاملات مسجلة في هذا التاريخ" : "No transactions on this date"}
                description={
                  isAr
                    ? "اختر يوماً آخر من التقويم أو أضف معاملة جديدة."
                    : "Select another date on the calendar or record a new transaction."
                }
                className="py-10"
              />
            ) : (
              <div className="space-y-2.5">
                {selectedDayTransactions.map((tx) => {
                  const isIncome = tx.type === "INCOME";
                  return (
                    <div
                      key={tx.id}
                      className="afab-inset p-3.5 flex items-center justify-between gap-3"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div
                          className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-white ${
                            isIncome ? "bg-emerald-500" : "bg-[var(--primary)]"
                          }`}
                        >
                          {isIncome ? (
                            <ArrowUpRight className="h-4 w-4" />
                          ) : (
                            <ArrowDownLeft className="h-4 w-4" />
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="text-xs font-semibold text-gray-900 dark:text-white truncate">
                            {tx.description}
                          </p>
                          <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-0.5">
                            {tx.categoryName || "Uncategorized"} • {tx.status}
                          </p>
                        </div>
                      </div>
                      <span
                        className={`text-xs font-bold font-mono shrink-0 ${
                          isIncome
                            ? "text-emerald-600 dark:text-emerald-400"
                            : "text-gray-900 dark:text-white"
                        }`}
                      >
                        {isIncome ? "+" : "-"}
                        {formatCurrency(tx.amount, tx.currency || currency)}
                      </span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
