"use client";

import { useState, useEffect, useCallback, useRef, useMemo } from "react";
import { 
  Plus, 
  Search, 
  Download, 
  ArrowUpRight, 
  ArrowDownLeft, 
  Trash2, 
  Pencil,
  Eye,
  TrendingUp, 
  TrendingDown, 
  Wallet, 
  Layers,
  ChevronLeft,
  ChevronRight,
  CreditCard,
  FolderTree,
  AlertTriangle,
  ShieldCheck,
  Copy,
  ArrowUpDown,
  ArrowUp,
  ArrowDown
} from "lucide-react";
import { KpiCard } from "@/components/dashboard/KpiCard";
import { AddTransactionModal } from "@/components/dashboard/AddTransactionModal";
import { DeleteTransactionModal } from "@/components/dashboard/DeleteTransactionModal";
import { ManageCategoriesModal } from "@/components/dashboard/ManageCategoriesModal";
import { QuickAddBar } from "@/components/dashboard/QuickAddBar";
import { TransactionDetailDrawer } from "@/components/dashboard/TransactionDetailDrawer";
import { SplitTransactionModal } from "@/components/dashboard/SplitTransactionModal";
import { PeriodSelector } from "@/components/dashboard/PeriodSelector";
import { TransactionService, TransactionResponse, CategoryItem, TransactionItem } from "@/lib/api/transactions";
import { CategoryService } from "@/lib/api/categories";
import { UserService } from "@/lib/api/dashboard";
import { exportTransactionsToCSV } from "@/lib/csv-export";
import { useTranslations } from "next-intl";
import { AfabLoader } from "@/components/ui/afab-loader";
import { formatCurrency } from "@/lib/currency";

export default function TransactionsPage() {
  const t = useTranslations("Transactions");
  const tFilters = useTranslations("Transactions.filters");
  const tTable = useTranslations("Transactions.table");
  const tKpi = useTranslations("Transactions.kpi");

  const [data, setData] = useState<TransactionResponse | null>(null);
  const [userProfile, setUserProfile] = useState<{ currency?: string } | null>(null);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [taxDeductibleFilter, setTaxDeductibleFilter] = useState<boolean | undefined>(undefined);
  const [period, setPeriod] = useState<"WEEKLY" | "MONTHLY" | "YEARLY">("MONTHLY");
  const [page, setPage] = useState(0);

  // Sorting
  const [sortField, setSortField] = useState<"date" | "amount" | null>(null);
  const [sortOrder, setSortOrder] = useState<"asc" | "desc">("desc");

  // Modals & Drawers state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTx, setEditingTx] = useState<TransactionItem | null>(null);
  const [selectedTx, setSelectedTx] = useState<TransactionItem | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [isSplitModalOpen, setIsSplitModalOpen] = useState(false);
  const [txToDelete, setTxToDelete] = useState<TransactionItem | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

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
        status: statusFilter || undefined,
        taxDeductible: taxDeductibleFilter,
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
  }, [typeFilter, categoryFilter, statusFilter, taxDeductibleFilter, search, page]);

  const fetchCategories = useCallback(async () => {
    try {
      const cats = await CategoryService.getCategories();
      setCategories(cats);
    } catch (err) {
      console.error("Failed to load categories:", err);
    }
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchTransactions();
  }, [fetchTransactions]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchCategories();
    UserService.getProfile()
      .then(setUserProfile)
      .catch((err) => console.error("Failed to load user profile:", err));
  }, [fetchCategories]);

  // Handle row sorting
  const handleSort = (field: "date" | "amount") => {
    if (sortField === field) {
      setSortOrder(sortOrder === "asc" ? "desc" : "asc");
    } else {
      setSortField(field);
      setSortOrder("desc");
    }
  };

  const sortedTransactions = useMemo(() => {
    if (!data?.content) return [];
    const list = [...data.content];
    if (sortField === "date") {
      list.sort((a, b) => {
        const da = new Date(a.transactionDate).getTime();
        const db = new Date(b.transactionDate).getTime();
        return sortOrder === "asc" ? da - db : db - da;
      });
    } else if (sortField === "amount") {
      list.sort((a, b) => {
        return sortOrder === "asc" ? a.amount - b.amount : b.amount - a.amount;
      });
    }
    return list;
  }, [data?.content, sortField, sortOrder]);

  const handleOpenEdit = (tx: TransactionItem) => {
    setIsDrawerOpen(false);
    setEditingTx(tx);
    setIsModalOpen(true);
  };

  const handleDuplicate = (tx: TransactionItem) => {
    setIsDrawerOpen(false);
    setEditingTx({
      ...tx,
      id: "", // clear id so modal acts as a new creation pre-filled
      transactionDate: new Date().toISOString().split("T")[0],
    });
    setIsModalOpen(true);
  };

  const handleOpenDelete = (tx: TransactionItem) => {
    setIsDrawerOpen(false);
    setTxToDelete(tx);
    setIsDeleteModalOpen(true);
  };

  const handleRowClick = (tx: TransactionItem) => {
    setSelectedTx(tx);
    setIsDrawerOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!txToDelete) return;
    setDeleting(true);
    try {
      await TransactionService.deleteTransaction(txToDelete.id);
      setIsDeleteModalOpen(false);
      setTxToDelete(null);
      if (selectedTx?.id === txToDelete.id) {
        setSelectedTx(null);
        setIsDrawerOpen(false);
      }
      fetchTransactions();
    } catch (err) {
      console.error("Failed to delete transaction:", err);
    } finally {
      setDeleting(false);
    }
  };

  const currency = data?.currency || userProfile?.currency || "USD";

  const handleExportCSV = () => {
    if (!data?.content || data.content.length === 0) return;
    exportTransactionsToCSV(data.content, currency);
  };

  // Sparkline data generation (Smooth curves for single or multiple points)
  const inflowData = useMemo(() => {
    if (!data?.content || data.content.length === 0 || !data.totalInflow) {
      return [0, 0, 0, 0, 0];
    }
    const incomes = data.content
      .filter((t) => t.type === "INCOME")
      .map((t) => t.amount)
      .reverse();
    if (incomes.length === 0) return [0, 0, 0, 0];
    if (incomes.length === 1) return [0, incomes[0] * 0.4, incomes[0] * 0.85, incomes[0]];
    return [0, ...incomes];
  }, [data?.content, data?.totalInflow]);

  const outflowData = useMemo(() => {
    if (!data?.content || data.content.length === 0 || !data.totalOutflow) {
      return [0, 0, 0, 0, 0];
    }
    const expenses = data.content
      .filter((t) => t.type === "EXPENSE")
      .map((t) => t.amount)
      .reverse();
    if (expenses.length === 0) return [0, 0, 0, 0];
    if (expenses.length === 1) return [0, expenses[0] * 0.4, expenses[0] * 0.85, expenses[0]];
    return [0, ...expenses];
  }, [data?.content, data?.totalOutflow]);

  const netData = useMemo(() => {
    if (!data?.content || data.content.length === 0) {
      return [0, 0, 0, 0, 0];
    }
    const sorted = [...data.content].reverse();
    let running = 0;
    const trajectory = [0];
    for (const t of sorted) {
      running += t.type === "INCOME" ? t.amount : -t.amount;
      trajectory.push(running);
    }
    return trajectory.length === 2 ? [0, trajectory[1] * 0.5, trajectory[1]] : trajectory;
  }, [data?.content]);

  const countData = useMemo(() => {
    const total = data?.totalElements || 0;
    if (total === 0) return [0, 0, 0, 0];
    if (total === 1) return [0, 0.5, 1];
    return Array.from({ length: Math.min(total + 1, 6) }, (_, i) => i);
  }, [data?.totalElements]);

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-700">
      
      {/* ── Page Header ── */}
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white sm:text-3xl tracking-tight">
            {t("title")}
          </h1>
          <p className="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
            {t("subtitle")}
          </p>
        </div>

        {/* All Action Buttons Guaranteed On The Same Line */}
        <div className="flex items-center gap-2 sm:gap-2.5 flex-nowrap overflow-x-auto pb-1 sm:pb-0 scrollbar-none">
          {/* Period Toggle Tabs */}
          <PeriodSelector value={period} onChange={setPeriod} className="shrink-0" />

          {/* Manage Categories Button */}
          <button
            onClick={() => setIsCategoryModalOpen(true)}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/[0.05] transition-all shadow-sm shrink-0 whitespace-nowrap"
          >
            <FolderTree className="h-4 w-4 text-[#8b5cf6]" />
            <span>{t("manageCategories")}</span>
          </button>

          {/* Split Transaction Button */}
          <button
            onClick={() => setIsSplitModalOpen(true)}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border border-purple-500/30 bg-purple-500/10 text-xs font-semibold text-[#8b5cf6] hover:bg-purple-500/20 transition-all shadow-sm shrink-0 whitespace-nowrap"
          >
            <Layers className="h-4 w-4" />
            <span>{t("splitTransaction") || "Split Expense"}</span>
          </button>

          {/* Export CSV Button */}
          <button
            onClick={handleExportCSV}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/[0.05] transition-all shadow-sm shrink-0 whitespace-nowrap"
          >
            <Download className="h-4 w-4" />
            <span>{t("export")}</span>
          </button>

          {/* Add Transaction Button */}
          <button
            onClick={() => {
              setEditingTx(null);
              setIsModalOpen(true);
            }}
            className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-[#8b5cf6] text-white text-xs font-bold hover:bg-[#7c3aed] transition-all shadow-lg shadow-[#8b5cf6]/25 shrink-0 whitespace-nowrap"
          >
            <Plus className="h-4 w-4" />
            <span>{t("addTransaction")}</span>
          </button>
        </div>
      </div>

      {/* ── Magic Omni-Bar (Natural Language Quick-Add) ── */}
      <QuickAddBar
        categories={categories}
        currency={currency}
        onSuccess={fetchTransactions}
      />

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
          value={data?.totalElements?.toString() || "0"}
          change="Total items"
          isPositive={true}
          icon={Layers}
          data={countData}
        />
      </div>

      {/* ── Filter & Search Toolbar ── */}
      <div className="rounded-2xl border border-gray-200 dark:border-gray-800/80 bg-white/70 dark:bg-[#0c101c]/70 p-4 backdrop-blur-xl shadow-sm space-y-3">
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
          
          {/* Search with ⌘K */}
          <div className="relative flex-1">
            <Search className="absolute start-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              ref={searchInputRef}
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(0);
              }}
              placeholder={tFilters("searchPlaceholder")}
              className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] ps-10 pe-16 py-2 text-xs text-gray-900 dark:text-white placeholder-gray-400 focus:border-[#8b5cf6] focus:outline-none focus:ring-1 focus:ring-[#8b5cf6] transition-all"
            />
            <kbd className="absolute end-3 top-1/2 -translate-y-1/2 hidden sm:inline-flex items-center gap-1 rounded border border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-gray-800 px-1.5 py-0.5 text-[10px] font-medium text-gray-400">
              {tFilters("searchShortcut")}
            </kbd>
          </div>

          {/* Filter Dropdowns */}
          <div className="flex flex-wrap items-center gap-2">
            {/* Type Filter */}
            <select
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value);
                setPage(0);
              }}
              className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 focus:border-[#8b5cf6] focus:outline-none"
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
              className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 focus:border-[#8b5cf6] focus:outline-none max-w-[150px]"
            >
              <option value="">{tFilters("allCategories")}</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>

            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setPage(0);
              }}
              className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 focus:border-[#8b5cf6] focus:outline-none"
            >
              <option value="">{tFilters("allStatuses")}</option>
              <option value="COMPLETED">{tFilters("completed")}</option>
              <option value="PENDING">{tFilters("pending")}</option>
              <option value="CANCELLED">{tFilters("cancelled")}</option>
            </select>

            {/* Tax Deductible Toggle Pill */}
            <button
              onClick={() => {
                setTaxDeductibleFilter((prev) => (prev === true ? undefined : true));
                setPage(0);
              }}
              className={`flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold transition-all border ${
                taxDeductibleFilter === true
                  ? "bg-teal-500/15 text-teal-600 dark:text-teal-400 border-teal-500/30"
                  : "bg-gray-50/50 dark:bg-[#080c18] text-gray-600 dark:text-gray-400 border-gray-200 dark:border-gray-800 hover:text-gray-900 dark:hover:text-white"
              }`}
            >
              <ShieldCheck className="h-3.5 w-3.5" />
              <span>{t("taxFilter") || "Tax Write-offs"}</span>
            </button>
          </div>
        </div>
      </div>

      {/* ── Transactions Table Card ── */}
      <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm overflow-hidden">
        {loading ? (
          <div className="flex h-64 items-center justify-center">
            <AfabLoader size="md" text="Loading ledger..." />
          </div>
        ) : !data || sortedTransactions.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gray-100 dark:bg-white/5 text-gray-400 mb-4">
              <Layers className="h-6 w-6" />
            </div>
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">
              {tTable("noTransactions")}
            </h3>
            <p className="mt-1 text-xs text-gray-500 max-w-sm leading-relaxed">
              {tTable("noTransactionsSubtitle")}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-start text-xs">
              <thead className="border-b border-gray-100 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18] text-gray-400 uppercase tracking-wider font-semibold">
                <tr>
                  <th className="px-6 py-3.5 text-start">{tTable("description")}</th>
                  <th className="px-6 py-3.5 text-start">{tTable("category")}</th>
                  <th 
                    className="px-6 py-3.5 text-start cursor-pointer hover:text-gray-900 dark:hover:text-white select-none transition-colors"
                    onClick={() => handleSort("date")}
                  >
                    <div className="flex items-center gap-1.5">
                      <span>{tTable("date")}</span>
                      {sortField === "date" ? (
                        sortOrder === "asc" ? <ArrowUp className="h-3.5 w-3.5 text-[#8b5cf6]" /> : <ArrowDown className="h-3.5 w-3.5 text-[#8b5cf6]" />
                      ) : (
                        <ArrowUpDown className="h-3 w-3 opacity-40" />
                      )}
                    </div>
                  </th>
                  <th className="px-6 py-3.5 text-start">{tTable("method")}</th>
                  <th 
                    className="px-6 py-3.5 text-end cursor-pointer hover:text-gray-900 dark:hover:text-white select-none transition-colors"
                    onClick={() => handleSort("amount")}
                  >
                    <div className="flex items-center justify-end gap-1.5">
                      <span>{tTable("amount")}</span>
                      {sortField === "amount" ? (
                        sortOrder === "asc" ? <ArrowUp className="h-3.5 w-3.5 text-[#8b5cf6]" /> : <ArrowDown className="h-3.5 w-3.5 text-[#8b5cf6]" />
                      ) : (
                        <ArrowUpDown className="h-3 w-3 opacity-40" />
                      )}
                    </div>
                  </th>
                  <th className="px-6 py-3.5 text-center">{tTable("status")}</th>
                  <th className="px-6 py-3.5 text-end">{tTable("actions")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800/40 text-gray-700 dark:text-gray-300 font-medium">
                {sortedTransactions.map((tx) => {
                  const isIncome = tx.type === "INCOME";
                  return (
                    <tr 
                      key={tx.id} 
                      className="hover:bg-gray-50/80 dark:hover:bg-white/[0.02] transition-colors group cursor-pointer"
                      onClick={() => handleRowClick(tx)}
                    >
                      {/* Description & Badges */}
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div
                            className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-white font-bold text-xs shadow-sm ${
                              isIncome ? "bg-emerald-500" : "bg-purple-600"
                            }`}
                          >
                            {isIncome ? <ArrowUpRight className="h-4 w-4" /> : <ArrowDownLeft className="h-4 w-4" />}
                          </div>
                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <p className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-[#8b5cf6] transition-colors truncate">
                                {tx.description}
                              </p>

                              {/* Potential Duplicate Badge */}
                              {tx.potentialDuplicate && (
                                <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-md bg-amber-500/10 text-amber-500 text-[10px] font-bold border border-amber-500/20" title="Possible duplicate charge detected within 48h">
                                  <AlertTriangle className="h-3 w-3" /> Duplicate
                                </span>
                              )}

                              {/* Price Hike Badge */}
                              {tx.priceHikePercentage && tx.priceHikePercentage > 0 && (
                                <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-md bg-indigo-500/10 text-indigo-500 text-[10px] font-bold border border-indigo-500/20" title="Cost increase vs previous billing">
                                  <TrendingUp className="h-3 w-3" /> +{tx.priceHikePercentage}%
                                </span>
                              )}

                              {/* Tax Deductible Badge */}
                              {tx.taxDeductible && (
                                <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-md bg-teal-500/10 text-teal-600 dark:text-teal-400 text-[10px] font-bold border border-teal-500/20" title="Tax deductible business write-off">
                                  <ShieldCheck className="h-3 w-3" /> Tax
                                </span>
                              )}

                              {/* Split Transaction Badge */}
                              {tx.isSplit && (
                                <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-md bg-purple-500/10 text-purple-600 dark:text-purple-400 text-[10px] font-bold border border-purple-500/20" title="Split across multiple categories">
                                  <Layers className="h-3 w-3" /> Split
                                </span>
                              )}
                            </div>
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
                      <td className="px-6 py-4 text-gray-500 dark:text-gray-400 whitespace-nowrap">
                        {tx.transactionDate}
                      </td>

                      {/* Payment Method */}
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center gap-1.5 rounded-md bg-gray-100 dark:bg-white/5 px-2 py-0.5 text-[11px] font-medium text-gray-600 dark:text-gray-400">
                          <CreditCard className="h-3 w-3 text-gray-400" />
                          {tx.paymentMethod ? tx.paymentMethod.replace(/_/g, " ") : "BANK TRANSFER"}
                        </span>
                      </td>

                      {/* Amount */}
                      <td className="px-6 py-4 text-end whitespace-nowrap">
                        <span className={`text-sm font-bold ${isIncome ? "text-emerald-600 dark:text-emerald-400" : "text-gray-900 dark:text-white"}`}>
                          {isIncome ? "+" : "-"}{formatCurrency(tx.amount, tx.currency || currency)}
                        </span>
                      </td>

                      {/* Status Indicator */}
                      <td className="px-6 py-4 text-center whitespace-nowrap">
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
                      <td className="px-6 py-4 text-end whitespace-nowrap">
                        <div className="flex items-center justify-end gap-1" onClick={(e) => e.stopPropagation()}>
                          <button
                            onClick={() => handleRowClick(tx)}
                            title="View full details"
                            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => handleDuplicate(tx)}
                            title={t("duplicate") || "Duplicate"}
                            className="p-1.5 rounded-lg text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 transition-colors"
                          >
                            <Copy className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => handleOpenEdit(tx)}
                            title={tTable("edit") || "Edit"}
                            className="p-1.5 rounded-lg text-gray-400 hover:text-[#8b5cf6] hover:bg-[#8b5cf6]/10 transition-colors"
                          >
                            <Pencil className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => handleOpenDelete(tx)}
                            title={tTable("delete") || "Delete"}
                            className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
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
                <ChevronLeft className="h-4 w-4 rtl:rotate-180" />
              </button>
              <span className="text-xs font-semibold px-2 text-gray-600 dark:text-gray-300">
                {data.pageNumber + 1} / {data.totalPages}
              </span>
              <button
                disabled={data.pageNumber >= data.totalPages - 1}
                onClick={() => setPage(page + 1)}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-gray-200 dark:border-gray-800 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/5 disabled:opacity-40 transition-colors"
              >
                <ChevronRight className="h-4 w-4 rtl:rotate-180" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ── Slide-Over Detail Drawer ── */}
      <TransactionDetailDrawer
        transaction={selectedTx}
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        onEdit={handleOpenEdit}
        onDuplicate={handleDuplicate}
        onDelete={handleOpenDelete}
        currency={currency}
      />

      {/* ── Split Transaction Modal ── */}
      <SplitTransactionModal
        isOpen={isSplitModalOpen}
        onClose={() => setIsSplitModalOpen(false)}
        onSuccess={fetchTransactions}
        categories={categories}
        currency={currency}
      />

      {/* ── Add / Edit Transaction Modal ── */}
      <AddTransactionModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setEditingTx(null);
        }}
        onSuccess={() => {
          setEditingTx(null);
          fetchTransactions();
        }}
        categories={categories}
        currency={currency}
        transactionToEdit={editingTx}
      />

      {/* ── Delete Confirmation Modal ── */}
      <DeleteTransactionModal
        isOpen={isDeleteModalOpen}
        onClose={() => {
          setIsDeleteModalOpen(false);
          setTxToDelete(null);
        }}
        onConfirm={handleConfirmDelete}
        transaction={txToDelete}
        deleting={deleting}
        currency={currency}
      />

      {/* ── Manage Categories Modal ── */}
      <ManageCategoriesModal
        isOpen={isCategoryModalOpen}
        onClose={() => setIsCategoryModalOpen(false)}
        categories={categories}
        onCategoriesChanged={() => {
          fetchCategories();
          fetchTransactions();
        }}
      />
    </div>
  );
}
