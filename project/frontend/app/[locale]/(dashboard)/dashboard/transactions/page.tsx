"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { 
  Plus, 
  Search, 
  Download, 
  Filter, 
  ArrowUpRight, 
  ArrowDownLeft, 
  Trash2, 
  Eye,
  TrendingUp, 
  TrendingDown, 
  Wallet, 
  Layers,
  ChevronLeft,
  ChevronRight,
  Calendar,
  X,
  CreditCard,
  Building,
  Tag
} from "lucide-react";
import { KpiCard } from "@/components/dashboard/KpiCard";
import { AddTransactionModal } from "@/components/dashboard/AddTransactionModal";
import { TransactionService, TransactionResponse, CategoryItem, TransactionItem } from "@/lib/api/transactions";
import { UserService } from "@/lib/api/dashboard";
import { useTranslations } from "next-intl";
import { AfabLoader } from "@/components/ui/afab-loader";

import { formatCurrency } from "@/lib/currency";

export default function TransactionsPage() {
  const t = useTranslations("Transactions");
  const tPeriods = useTranslations("Transactions.periods");
  const tFilters = useTranslations("Transactions.filters");
  const tTable = useTranslations("Transactions.table");
  const tKpi = useTranslations("Transactions.kpi");

  const [data, setData] = useState<TransactionResponse | null>(null);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [period, setPeriod] = useState<"WEEKLY" | "MONTHLY" | "YEARLY">("MONTHLY");
  const [page, setPage] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedTx, setSelectedTx] = useState<TransactionItem | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const searchInputRef = useRef<HTMLInputElement>(null);

  // Keyboard shortcut ⌘K / Ctrl+K listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        searchInputRef.current?.focus();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const fetchTransactions = useCallback(async () => {
    setLoading(true);
    try {
      const res = await TransactionService.getTransactions({
        type: typeFilter || undefined,
        categoryId: categoryFilter || undefined,
        search: search || undefined,
        page,
        size: 15,
      });
      setData(res);
    } catch (err) {
      console.error("Failed to load transactions:", err);
    } finally {
      setLoading(false);
    }
  }, [typeFilter, categoryFilter, search, page]);

  useEffect(() => {
    fetchTransactions();
  }, [fetchTransactions]);

  useEffect(() => {
    TransactionService.getCategories()
      .then(setCategories)
      .catch((err) => console.error("Failed to load categories:", err));
    UserService.getProfile()
      .then(setUserProfile)
      .catch((err) => console.error("Failed to load user profile:", err));
  }, []);

  const handleDelete = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this transaction?")) return;
    setDeletingId(id);
    try {
      await TransactionService.deleteTransaction(id);
      if (selectedTx?.id === id) setSelectedTx(null);
      fetchTransactions();
    } catch (err) {
      console.error("Failed to delete transaction:", err);
    } finally {
      setDeletingId(null);
    }
  };

  const handleExportCSV = () => {
    if (!data || !data.content || data.content.length === 0) return;
    const headers = ["ID,Type,Description,Amount,Currency,Category,Date,Payment Method,Status"];
    const rows = data.content.map((tx) =>
      `"${tx.id}","${tx.type}","${tx.description.replace(/"/g, '""')}",${tx.amount},"${tx.currency}","${tx.categoryName}","${tx.transactionDate}","${tx.paymentMethod}","${tx.status}"`
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `afab_transactions_${new Date().toISOString().split("T")[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const currency = data?.currency || userProfile?.currency || "USD";

  const hasTx = Boolean(data?.content && data.content.length > 0);
  const inflowData = (data?.totalInflow && hasTx) 
    ? data.content.filter(t => t.type === 'INCOME').map(t => t.amount)
    : [0, 0, 0, 0, 0, 0, 0];
  const outflowData = (data?.totalOutflow && hasTx)
    ? data.content.filter(t => t.type === 'EXPENSE').map(t => t.amount)
    : [0, 0, 0, 0, 0, 0, 0];
  const netData = (data?.netBalance && hasTx)
    ? data.content.map(t => t.type === 'INCOME' ? t.amount : -t.amount)
    : [0, 0, 0, 0, 0, 0, 0];
  const countData = (data?.totalElements && hasTx)
    ? data.content.map((_, i) => i + 1)
    : [0, 0, 0, 0, 0, 0, 0];

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-700">
      
      {/* ── Page Header ── */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white sm:text-3xl tracking-tight">
            {t("title")}
          </h1>
          <p className="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
            {t("subtitle")}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Period Toggle Tabs */}
          <div className="flex items-center rounded-xl bg-gray-100 dark:bg-[#080c18] border border-gray-200 dark:border-gray-800/60 p-1 text-xs font-semibold">
            {(["WEEKLY", "MONTHLY", "YEARLY"] as const).map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  period === p
                    ? "bg-[#8b5cf6] text-white shadow-sm"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                }`}
              >
                {tPeriods(p.toLowerCase())}
              </button>
            ))}
          </div>

          <button
            onClick={handleExportCSV}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/[0.05] transition-all shadow-sm"
          >
            <Download className="h-4 w-4" />
            {t("export")}
          </button>
          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#8b5cf6] text-white text-xs font-bold hover:bg-[#7c3aed] transition-all shadow-lg shadow-[#8b5cf6]/25"
          >
            <Plus className="h-4 w-4" />
            {t("addTransaction")}
          </button>
        </div>
      </div>

      {/* ── KPI Summary Cards ── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          title={tKpi("totalInflow")}
          value={formatCurrency(data?.totalInflow || 0, currency)}
          change={(data?.totalInflow || 0) === 0 ? "0.0%" : "Real-time"}
          isPositive={true}
          icon={TrendingUp}
          data={inflowData}
        />
        <KpiCard
          title={tKpi("totalOutflow")}
          value={formatCurrency(data?.totalOutflow || 0, currency)}
          change={(data?.totalOutflow || 0) === 0 ? "0.0%" : "Real-time"}
          isPositive={false}
          icon={TrendingDown}
          data={outflowData}
        />
        <KpiCard
          title={tKpi("netBalance")}
          value={formatCurrency(data?.netBalance || 0, currency)}
          change={(data?.netBalance || 0) === 0 ? "0.0%" : "Real-time"}
          isPositive={(data?.netBalance || 0) >= 0}
          icon={Wallet}
          data={netData}
        />
        <KpiCard
          title={tKpi("totalCount")}
          value={(data?.totalElements || 0).toString()}
          change={(data?.totalElements || 0) === 0 ? "0 entries" : "Entries"}
          isPositive={true}
          icon={Layers}
          data={countData}
        />
      </div>

      {/* ── Search & Filter Controls ── */}
      <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-4 shadow-sm space-y-4">
        <div className="flex flex-col md:flex-row gap-3 items-center justify-between">
          
          {/* Search Input with ⌘K Badge */}
          <div className="relative w-full md:max-w-md">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400">
              <Search className="h-4 w-4" />
            </div>
            <input
              ref={searchInputRef}
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(0);
              }}
              placeholder={tFilters("searchPlaceholder")}
              className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] pl-9 pr-14 py-2.5 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
            />
            <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
              <span className="px-1.5 py-0.5 rounded bg-gray-200 dark:bg-white/10 text-[10px] font-mono font-medium text-gray-500 dark:text-gray-400 border border-gray-300 dark:border-gray-700">
                ⌘K
              </span>
            </div>
          </div>

          {/* Filter Dropdowns */}
          <div className="flex flex-wrap items-center gap-2.5 w-full md:w-auto">
            {/* Type Filter */}
            <select
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value);
                setPage(0);
              }}
              className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-semibold text-gray-700 dark:text-gray-300 focus:border-[#8b5cf6] focus:outline-none"
            >
              <option value="">{tFilters("allTypes")}</option>
              <option value="INCOME">{tFilters("income")}</option>
              <option value="EXPENSE">{tFilters("expense")}</option>
            </select>

            {/* Category Filter */}
            <select
              value={categoryFilter}
              onChange={(e) => {
                setCategoryFilter(e.target.value);
                setPage(0);
              }}
              className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-semibold text-gray-700 dark:text-gray-300 focus:border-[#8b5cf6] focus:outline-none"
            >
              <option value="">{tFilters("allCategories")}</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>

            {/* Reset Filters */}
            {(typeFilter || categoryFilter || search) && (
              <button
                onClick={() => {
                  setTypeFilter("");
                  setCategoryFilter("");
                  setSearch("");
                  setPage(0);
                }}
                className="flex items-center gap-1.5 px-3 py-2 text-xs font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors"
              >
                <X className="h-3.5 w-3.5" />
                Reset
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ── Transactions Table ── */}
      <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] overflow-hidden shadow-sm">
        {loading ? (
          <div className="py-20 flex justify-center items-center">
            <AfabLoader size="md" text="Fetching transactions..." />
          </div>
        ) : !data || data.content.length === 0 ? (
          <div className="py-20 text-center space-y-4">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-gray-100 dark:bg-white/[0.03] text-gray-400">
              <Filter className="h-8 w-8" />
            </div>
            <h3 className="text-base font-bold text-gray-900 dark:text-white">
              {tTable("noTransactions")}
            </h3>
            <p className="text-xs text-gray-500 max-w-sm mx-auto">
              {tTable("noTransactionsSubtitle")}
            </p>
            <button
              onClick={() => setIsModalOpen(true)}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#8b5cf6] text-white text-xs font-bold hover:bg-[#7c3aed] transition-all shadow-md shadow-[#8b5cf6]/20"
            >
              <Plus className="h-3.5 w-3.5" />
              {t("addTransaction")}
            </button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-gray-100 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18] text-gray-400 uppercase tracking-wider font-semibold">
                <tr>
                  <th className="px-6 py-3.5">{tTable("description")}</th>
                  <th className="px-6 py-3.5">{tTable("category")}</th>
                  <th className="px-6 py-3.5">{tTable("date")}</th>
                  <th className="px-6 py-3.5">{tTable("method")}</th>
                  <th className="px-6 py-3.5 text-right">{tTable("amount")}</th>
                  <th className="px-6 py-3.5 text-center">{tTable("status")}</th>
                  <th className="px-6 py-3.5 text-right">{tTable("actions")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800/40 text-gray-700 dark:text-gray-300 font-medium">
                {data.content.map((tx) => {
                  const isIncome = tx.type === "INCOME";
                  return (
                    <tr 
                      key={tx.id} 
                      className="hover:bg-gray-50/80 dark:hover:bg-white/[0.02] transition-colors group cursor-pointer"
                      onClick={() => setSelectedTx(tx)}
                    >
                      {/* Description & Icon */}
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div
                            className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-white font-bold text-xs shadow-sm ${
                              isIncome ? "bg-emerald-500" : "bg-purple-600"
                            }`}
                          >
                            {isIncome ? <ArrowUpRight className="h-4 w-4" /> : <ArrowDownLeft className="h-4 w-4" />}
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-[#8b5cf6] transition-colors">
                              {tx.description}
                            </p>
                            <p className="text-[10px] text-gray-400 font-normal">
                              Ref: #{tx.id.substring(0, 8)}
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Category Badge */}
                      <td className="px-6 py-4">
                        <span 
                          className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-[11px] font-semibold border border-current/20"
                          style={{ 
                            backgroundColor: `${tx.categoryColor}15`, 
                            color: tx.categoryColor 
                          }}
                        >
                          <span 
                            className="h-1.5 w-1.5 rounded-full" 
                            style={{ backgroundColor: tx.categoryColor }} 
                          />
                          {tx.categoryName}
                        </span>
                      </td>

                      {/* Date */}
                      <td className="px-6 py-4 text-gray-500 dark:text-gray-400">
                        {tx.transactionDate}
                      </td>

                      {/* Payment Method */}
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center gap-1.5 rounded-md bg-gray-100 dark:bg-white/5 px-2 py-0.5 text-[11px] font-medium text-gray-600 dark:text-gray-400">
                          <CreditCard className="h-3 w-3 text-gray-400" />
                          {tx.paymentMethod.replace(/_/g, " ")}
                        </span>
                      </td>

                      {/* Amount */}
                      <td className="px-6 py-4 text-right">
                        <span className={`text-sm font-bold ${isIncome ? "text-emerald-600 dark:text-emerald-400" : "text-gray-900 dark:text-white"}`}>
                          {isIncome ? "+" : "-"}{formatCurrency(tx.amount, tx.currency || currency)}
                        </span>
                      </td>

                      {/* Status Indicator */}
                      <td className="px-6 py-4 text-center">
                        <span className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[10px] font-bold bg-gray-100 dark:bg-white/5">
                          <span className={`h-1.5 w-1.5 rounded-full ${
                            tx.status === "COMPLETED" 
                              ? "bg-emerald-500" 
                              : tx.status === "PENDING"
                              ? "bg-amber-500"
                              : "bg-red-500"
                          }`} />
                          <span className={
                            tx.status === "COMPLETED" 
                              ? "text-emerald-600 dark:text-emerald-400" 
                              : tx.status === "PENDING"
                              ? "text-amber-600 dark:text-amber-400"
                              : "text-red-600 dark:text-red-400"
                          }>
                            {tx.status}
                          </span>
                        </span>
                      </td>

                      {/* Actions */}
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-1" onClick={(e) => e.stopPropagation()}>
                          <button
                            onClick={() => setSelectedTx(tx)}
                            title="View details"
                            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(tx.id)}
                            disabled={deletingId === tx.id}
                            title="Delete transaction"
                            className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors disabled:opacity-50"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Footer */}
        {data && data.totalPages > 1 && (
          <div className="flex items-center justify-between border-t border-gray-100 dark:border-gray-800/60 px-6 py-3.5 bg-gray-50/50 dark:bg-[#080c18]">
            <p className="text-xs text-gray-500">
              Showing <span className="font-semibold text-gray-900 dark:text-white">{data.pageNumber * data.pageSize + 1} to {Math.min((data.pageNumber + 1) * data.pageSize, data.totalElements)}</span> of <span className="font-semibold text-gray-900 dark:text-white">{data.totalElements}</span> results
            </p>
            <div className="flex items-center gap-2">
              <button
                disabled={data.pageNumber === 0}
                onClick={() => setPage(page - 1)}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-gray-200 dark:border-gray-800 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/5 disabled:opacity-40 transition-colors"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <span className="text-xs font-semibold px-2 text-gray-600 dark:text-gray-300">
                {data.pageNumber + 1} / {data.totalPages}
              </span>
              <button
                disabled={data.pageNumber >= data.totalPages - 1}
                onClick={() => setPage(page + 1)}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-gray-200 dark:border-gray-800 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/5 disabled:opacity-40 transition-colors"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Detail Modal */}
      {selectedTx && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="relative w-full max-w-md overflow-hidden rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 pb-4">
              <div className="flex items-center gap-3">
                <div className={`flex h-10 w-10 items-center justify-center rounded-xl text-white font-bold text-xs ${
                  selectedTx.type === "INCOME" ? "bg-emerald-500" : "bg-purple-600"
                }`}>
                  {selectedTx.type === "INCOME" ? <ArrowUpRight className="h-5 w-5" /> : <ArrowDownLeft className="h-5 w-5" />}
                </div>
                <div>
                  <h3 className="text-base font-bold text-gray-900 dark:text-white">{selectedTx.description}</h3>
                  <p className="text-xs text-gray-400">Ref: #{selectedTx.id}</p>
                </div>
              </div>
              <button onClick={() => setSelectedTx(null)} className="text-gray-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-5 space-y-4 text-xs">
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Amount</span>
                <span className={`text-base font-bold ${selectedTx.type === "INCOME" ? "text-emerald-500" : "text-white"}`}>
                  {selectedTx.type === "INCOME" ? "+" : "-"}{formatCurrency(selectedTx.amount, selectedTx.currency || currency)}
                </span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Category</span>
                <span className="font-semibold text-white">{selectedTx.categoryName}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Date</span>
                <span className="font-semibold text-white">{selectedTx.transactionDate}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Payment Method</span>
                <span className="font-semibold text-white">{selectedTx.paymentMethod.replace(/_/g, " ")}</span>
              </div>
              <div className="flex justify-between items-center py-2">
                <span className="text-gray-400">Status</span>
                <span className="font-bold text-emerald-400">{selectedTx.status}</span>
              </div>
            </div>

            <div className="mt-6 flex justify-end">
              <button
                onClick={() => setSelectedTx(null)}
                className="px-5 py-2 rounded-xl text-xs font-bold bg-[#8b5cf6] text-white hover:bg-[#7c3aed] transition-all"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Transaction Modal */}
      <AddTransactionModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={() => fetchTransactions()}
        categories={categories}
        currency={currency}
      />
    </div>
  );
}
