"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { 
  Plus, 
  Search, 
  Download, 
  ChevronLeft, 
  ChevronRight, 
  Eye, 
  X,
  CreditCard,
  Building2,
  Calendar as CalendarIcon,
  CheckCircle,
  Clock,
  AlertTriangle,
  Wallet,
  Receipt,
  ArrowUpRight,
  PieChart as PieChartIcon
} from "lucide-react";
import { useTranslations } from "next-intl";
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip } from "recharts";
import { ChartContainer } from "@/components/ui/chart-container";
import { AfabLoader } from "@/components/ui/afab-loader";

import { KpiCard } from "@/components/dashboard/KpiCard";
import { AddTransactionModal } from "@/components/dashboard/AddTransactionModal";
import { InvoiceService, InvoiceSummaryResponse } from "@/lib/api/invoices";
import { TransactionService, TransactionResponse, CategoryItem, TransactionItem } from "@/lib/api/transactions";
import { UserService } from "@/lib/api/dashboard";
import { formatCurrency } from "@/lib/currency";

export default function InvoicesPage() {
  const t = useTranslations("Invoices");
  const tKpi = useTranslations("Invoices.kpi");
  const tFilters = useTranslations("Invoices.filters");
  const tWidgets = useTranslations("Invoices.widgets");
  const tTable = useTranslations("Invoices.table");

  const [summary, setSummary] = useState<InvoiceSummaryResponse | null>(null);
  const [invoicesData, setInvoicesData] = useState<TransactionResponse | null>(null);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [period, setPeriod] = useState<"WEEKLY" | "MONTHLY" | "YEARLY">("MONTHLY");
  const [page, setPage] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedTx, setSelectedTx] = useState<TransactionItem | null>(null);

  const searchInputRef = useRef<HTMLInputElement>(null);

  // Keyboard shortcut ⌘K listener
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

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [sumRes, listRes] = await Promise.all([
        InvoiceService.getSummary(),
        InvoiceService.getInvoices({
          search: search || undefined,
          page,
          size: 15,
        })
      ]);
      setSummary(sumRes);
      setInvoicesData(listRes);
    } catch (err) {
      console.error("Failed to load invoices data:", err);
    } finally {
      setLoading(false);
    }
  }, [search, page]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    TransactionService.getCategories()
      .then(setCategories)
      .catch((err) => console.error("Failed to load categories:", err));
    UserService.getProfile()
      .then(setUserProfile)
      .catch((err) => console.error("Failed to load user profile:", err));
  }, []);

  const handleExportCSV = () => {
    if (!invoicesData || !invoicesData.content || invoicesData.content.length === 0) return;
    const headers = ["Invoice ID,Customer,Amount,Currency,Issue Date,Status"];
    const rows = invoicesData.content.map((tx, i) =>
      `"INV-${1245 - i}","${tx.description.replace(/"/g, '""')}",${tx.amount},"${tx.currency}","${tx.transactionDate}","${tx.status}"`
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `afab_invoices_${new Date().toISOString().split("T")[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const currency = summary?.currency || userProfile?.currency || "USD";

  // Dynamic KPI Sparklines
  const hasInvoices = Boolean(invoicesData?.content && invoicesData.content.length > 0);
  const totalCountData = (summary?.totalInvoices && hasInvoices)
    ? [2, 4, 3, 6, 4, summary.totalInvoices]
    : [0, 0, 0, 0, 0, 0, 0];
  const paidData = (summary?.paidInvoices && hasInvoices)
    ? [1, 2, 4, 3, summary.paidInvoices]
    : [0, 0, 0, 0, 0, 0, 0];
  const pendingData = (summary?.pendingInvoices && hasInvoices)
    ? [3, 2, 4, summary.pendingInvoices]
    : [0, 0, 0, 0, 0, 0, 0];
  const overdueData = (summary?.overdueInvoices && hasInvoices)
    ? [1, 2, summary.overdueInvoices]
    : [0, 0, 0, 0, 0, 0, 0];
  const totalAmountData = (summary?.totalInvoiceAmount && hasInvoices)
    ? invoicesData!.content.map(t => t.amount)
    : [0, 0, 0, 0, 0, 0, 0];

  // Donut chart status breakdown data
  const statusPieData = (summary?.statusBreakdown && summary.statusBreakdown.length > 0)
    ? summary.statusBreakdown.map((st) => ({
        name: st.name,
        value: st.amount,
        percentage: st.percentage,
        color: st.color
      }))
    : [
        { name: "Paid", value: 13420, percentage: 54, color: "#4edea3" },
        { name: "Pending", value: 6230, percentage: 25, color: "#ffb95f" },
        { name: "Overdue", value: 5200, percentage: 21, color: "#ffb4ab" }
      ];

  if (loading && !invoicesData) {
    return (
      <div className="flex h-[75vh] items-center justify-center">
        <AfabLoader text="Loading Invoices Dashboard..." />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-700">
      
      {/* ── Page Header & Controls ── */}
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
                {p}
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
            {t("createInvoice")}
          </button>
        </div>
      </div>

      {/* ── 5 KPI Summary Cards ── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <KpiCard
          title={tKpi("totalInvoices")}
          value={(summary?.totalInvoices || 0).toString()}
          change={(summary?.totalInvoices || 0) === 0 ? "0.0%" : "+12.5%"}
          isPositive={true}
          icon={Receipt}
          data={totalCountData}
        />
        <KpiCard
          title={tKpi("paidInvoices")}
          value={(summary?.paidInvoices || 0).toString()}
          change={(summary?.paidInvoices || 0) === 0 ? "0.0%" : "+20.8%"}
          isPositive={true}
          icon={CheckCircle}
          data={paidData}
        />
        <KpiCard
          title={tKpi("pendingInvoices")}
          value={(summary?.pendingInvoices || 0).toString()}
          change={(summary?.pendingInvoices || 0) === 0 ? "0.0%" : "-10.3%"}
          isPositive={true}
          icon={Clock}
          data={pendingData}
        />
        <KpiCard
          title={tKpi("overdueInvoices")}
          value={(summary?.overdueInvoices || 0).toString()}
          change={(summary?.overdueInvoices || 0) === 0 ? "0.0%" : "+16.7%"}
          isPositive={false}
          icon={AlertTriangle}
          data={overdueData}
        />
        <KpiCard
          title={tKpi("totalInvoiceAmount")}
          value={formatCurrency(summary?.totalInvoiceAmount || 0, currency)}
          change={(summary?.totalInvoiceAmount || 0) === 0 ? "0.0%" : "+18.2%"}
          isPositive={true}
          icon={Wallet}
          data={totalAmountData}
        />
      </div>

      {/* ── Main Layout Grid: Table (9 cols) & Side Stack (3 cols) ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Invoices Table & Actions Bar (9 cols) */}
        <div className="lg:col-span-9 rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm overflow-hidden flex flex-col justify-between">
          <div>
            {/* Table Header Controls */}
            <div className="p-5 border-b border-gray-100 dark:border-gray-800/60 flex flex-col sm:flex-row gap-3 items-center justify-between">
              <div className="relative w-full sm:max-w-xs">
                <Search className="pointer-events-none absolute inset-y-0 left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  ref={searchInputRef}
                  type="text"
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(0);
                  }}
                  placeholder={tFilters("searchPlaceholder")}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] pl-9 pr-12 py-2 text-xs font-semibold text-gray-900 dark:text-white placeholder-gray-400 focus:border-[#8b5cf6] focus:outline-none"
                />
                <span className="absolute inset-y-0 right-3 top-1/2 -translate-y-1/2 text-[10px] font-mono text-gray-400">
                  ⌘K
                </span>
              </div>

              <div className="flex items-center gap-2.5 w-full sm:w-auto">
                <select
                  value={statusFilter}
                  onChange={(e) => {
                    setStatusFilter(e.target.value);
                    setPage(0);
                  }}
                  className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-semibold text-gray-700 dark:text-gray-300 focus:border-[#8b5cf6] focus:outline-none"
                >
                  <option value="">{tFilters("allStatus")}</option>
                  <option value="PAID">Paid</option>
                  <option value="PENDING">Pending</option>
                  <option value="OVERDUE">Overdue</option>
                </select>
              </div>
            </div>

            {/* Table View */}
            {!invoicesData || invoicesData.content.length === 0 ? (
              <div className="py-16 text-center">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-gray-100 dark:bg-white/5 text-gray-400 mb-3">
                  <Receipt className="h-6 w-6" />
                </div>
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tTable("noInvoices")}</h3>
                <p className="text-xs text-gray-400 mt-1 max-w-sm mx-auto">{tTable("noInvoicesSubtitle")}</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-gray-100 dark:border-gray-800/60 bg-gray-50/50 dark:bg-[#080c18]/50 text-gray-400 font-bold uppercase tracking-wider">
                      <th className="px-6 py-3.5">{tTable("invoiceId")}</th>
                      <th className="px-6 py-3.5">{tTable("customer")}</th>
                      <th className="px-6 py-3.5">{tTable("date")}</th>
                      <th className="px-6 py-3.5">{tTable("dueDate")}</th>
                      <th className="px-6 py-3.5 text-right">{tTable("amount")}</th>
                      <th className="px-6 py-3.5 text-center">{tTable("status")}</th>
                      <th className="px-6 py-3.5 text-right">{tTable("balance")}</th>
                      <th className="px-6 py-3.5 text-right">{tTable("actions")}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800/40 text-gray-700 dark:text-gray-300 font-medium">
                    {invoicesData.content.map((tx, idx) => {
                      const isPaid = tx.status === "COMPLETED" || tx.status === "PAID";
                      const isPending = tx.status === "PENDING";
                      const invoiceNum = `INV-${1245 - idx}`;
                      const balance = isPaid ? 0 : tx.amount;

                      return (
                        <tr
                          key={tx.id}
                          className="hover:bg-gray-50/80 dark:hover:bg-white/[0.02] transition-colors group cursor-pointer"
                          onClick={() => setSelectedTx(tx)}
                        >
                          <td className="px-6 py-4 font-mono font-bold text-[#8b5cf6]">{invoiceNum}</td>
                          <td className="px-6 py-4">
                            <div className="flex items-center gap-3">
                              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#8b5cf6]/10 text-[#8b5cf6] font-bold text-xs">
                                {tx.description.charAt(0).toUpperCase()}
                              </div>
                              <div>
                                <p className="text-xs font-semibold text-gray-900 dark:text-white group-hover:text-[#8b5cf6] transition-colors">
                                  {tx.description}
                                </p>
                                <p className="text-[10px] text-gray-400">client@business.com</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 text-gray-500 dark:text-gray-400">{tx.transactionDate}</td>
                          <td className="px-6 py-4 text-gray-500 dark:text-gray-400">{tx.transactionDate}</td>
                          <td className="px-6 py-4 text-right font-bold text-gray-900 dark:text-white font-mono">
                            {formatCurrency(tx.amount, tx.currency || currency)}
                          </td>
                          <td className="px-6 py-4 text-center">
                            <span
                              className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[10px] font-bold ${
                                isPaid
                                  ? "bg-emerald-500/10 text-emerald-500 border border-emerald-500/20"
                                  : isPending
                                  ? "bg-amber-500/10 text-amber-500 border border-amber-500/20"
                                  : "bg-red-500/10 text-red-500 border border-red-500/20"
                              }`}
                            >
                              <span
                                className={`h-1.5 w-1.5 rounded-full ${
                                  isPaid ? "bg-emerald-500" : isPending ? "bg-amber-500" : "bg-red-500"
                                }`}
                              />
                              {isPaid ? "Paid" : isPending ? "Pending" : "Overdue"}
                            </span>
                          </td>
                          <td className={`px-6 py-4 text-right font-mono font-semibold ${isPaid ? "text-emerald-500" : "text-amber-500"}`}>
                            {formatCurrency(balance, tx.currency || currency)}
                          </td>
                          <td className="px-6 py-4 text-right">
                            <button
                              onClick={() => setSelectedTx(tx)}
                              className="p-1.5 rounded-lg text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05]"
                            >
                              <Eye className="h-4 w-4" />
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Pagination Controls */}
          {invoicesData && invoicesData.totalPages > 1 && (
            <div className="p-4 border-t border-gray-100 dark:border-gray-800/60 flex items-center justify-between text-xs text-gray-500">
              <span>
                Showing {page * 15 + 1} to {Math.min((page + 1) * 15, invoicesData.totalElements)} of {invoicesData.totalElements}
              </span>
              <div className="flex items-center gap-1">
                <button
                  disabled={page === 0}
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 disabled:opacity-30 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
                <span className="px-3 font-semibold text-gray-900 dark:text-white">{page + 1}</span>
                <button
                  disabled={page >= invoicesData.totalPages - 1}
                  onClick={() => setPage((p) => p + 1)}
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 disabled:opacity-30 hover:bg-gray-100 dark:hover:bg-white/5"
                >
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Right Sidebar Stack (3 cols) */}
        <div className="lg:col-span-3 space-y-6">
          
          {/* Invoice Summary Donut Card */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm space-y-4">
            <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
              {tWidgets("summaryTitle")}
            </h4>

            <div className="relative h-44 w-full flex items-center justify-center my-2">
              <ChartContainer className="h-full w-full">
                <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0}>
                  <PieChart>
                    <Pie
                      data={statusPieData}
                      innerRadius={50}
                      outerRadius={70}
                      paddingAngle={5}
                      dataKey="value"
                      stroke="none"
                    >
                      {statusPieData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip
                      formatter={(val: any) => [formatCurrency(val, currency), ""]}
                      contentStyle={{
                        backgroundColor: "rgba(12, 16, 28, 0.95)",
                        borderColor: "rgba(255, 255, 255, 0.1)",
                        borderRadius: "10px",
                        color: "#fff",
                        fontSize: "12px",
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </ChartContainer>

              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-xs text-gray-400">Total</span>
                <span className="text-base font-extrabold text-gray-900 dark:text-white font-mono">
                  {formatCurrency(summary?.totalInvoiceAmount || 0, currency)}
                </span>
              </div>
            </div>

            <div className="space-y-2.5 text-xs font-semibold">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="h-2 w-2 rounded-full bg-emerald-400" />
                  <span className="text-gray-700 dark:text-gray-300">{tWidgets("paid")}</span>
                </div>
                <span className="font-mono text-gray-900 dark:text-white">
                  {formatCurrency(summary?.paidAmount || 0, currency)}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="h-2 w-2 rounded-full bg-amber-400" />
                  <span className="text-gray-700 dark:text-gray-300">{tWidgets("pending")}</span>
                </div>
                <span className="font-mono text-gray-900 dark:text-white">
                  {formatCurrency(summary?.pendingAmount || 0, currency)}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="h-2 w-2 rounded-full bg-red-400" />
                  <span className="text-gray-700 dark:text-gray-300">{tWidgets("overdue")}</span>
                </div>
                <span className="font-mono text-gray-900 dark:text-white">
                  {formatCurrency(summary?.overdueAmount || 0, currency)}
                </span>
              </div>
            </div>
          </div>

          {/* Upcoming Due Invoices Widget */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
                {tWidgets("upcomingDue")}
              </h4>
            </div>

            <div className="space-y-3">
              {(summary?.upcomingDueList || []).map((item) => (
                <div key={item.invoiceId} className="flex items-center justify-between p-2 rounded-xl hover:bg-gray-50 dark:hover:bg-white/[0.02] transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#8b5cf6]/10 text-[#8b5cf6] font-bold text-xs border border-[#8b5cf6]/20">
                      {item.customerName.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <p className="text-xs font-bold text-gray-900 dark:text-white truncate max-w-[120px]">
                        {item.customerName}
                      </p>
                      <p className="text-[10px] text-gray-400 font-mono">
                        {item.invoiceId} • {item.dueDate}
                      </p>
                    </div>
                  </div>
                  <span className="text-xs font-bold text-gray-900 dark:text-white font-mono">
                    {formatCurrency(item.amount, currency)}
                  </span>
                </div>
              ))}
            </div>
          </div>

        </div>

      </div>

      {/* Transaction Detail Drawer Modal */}
      {selectedTx && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="relative w-full max-w-md overflow-hidden rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/60 pb-4">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-500 text-white font-bold text-xs">
                  <ArrowUpRight className="h-5 w-5" />
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
                <span className="text-gray-400">Invoice Amount</span>
                <span className="text-base font-bold text-emerald-400 font-mono">
                  {formatCurrency(selectedTx.amount, selectedTx.currency || currency)}
                </span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Customer</span>
                <span className="font-semibold text-white">{selectedTx.description}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Issue Date</span>
                <span className="font-semibold text-white">{selectedTx.transactionDate}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-800/40">
                <span className="text-gray-400">Payment Status</span>
                <span className="font-semibold text-emerald-400">{selectedTx.status}</span>
              </div>
            </div>

            <div className="mt-6 flex justify-end">
              <button
                onClick={() => setSelectedTx(null)}
                className="px-4 py-2 rounded-xl bg-gray-100 dark:bg-white/10 text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Invoice Entry Modal */}
      <AddTransactionModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={() => fetchData()}
        categories={categories}
        currency={currency}
      />

    </div>
  );
}
