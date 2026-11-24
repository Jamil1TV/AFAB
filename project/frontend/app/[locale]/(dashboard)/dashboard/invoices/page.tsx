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
  CheckCircle,
  Clock,
  AlertTriangle,
  Wallet,
  Receipt,
  Send,
  Ban,
  DollarSign,
  Pencil,
  Trash2,
  AlertCircle,
  Printer,
  FileSignature,
  CheckCircle2,
  Sparkles,
} from "lucide-react";
import { useTranslations, useLocale } from "next-intl";
import { Link } from "@/i18n/routing";
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip } from "recharts";
import { toast } from "sonner";
import { ChartContainer } from "@/components/ui/chart-container";
import { AfabLoader } from "@/components/ui/afab-loader";
import { KpiCard } from "@/components/dashboard/KpiCard";
import { PeriodSelector } from "@/components/dashboard/PeriodSelector";
import { useCopilot } from "@/components/ai/CopilotContextProvider";
import {
  InvoiceService,
  InvoiceSummaryResponse,
  InvoicePageResponse,
  InvoiceDTO,
  InvoiceStatusType,
} from "@/lib/api/invoices";
import { CustomerService, Customer } from "@/lib/api/customers";
import { UserService } from "@/lib/api/dashboard";
import { BusinessService, BusinessData } from "@/lib/api/business";
import { formatCurrency } from "@/lib/currency";
import { getWetSignature, WetSignatureData } from "@/lib/signature-utils";
import { openPrintableInvoiceWindow, formatBusinessAddress } from "@/lib/export-utils";

interface DraftLineItem {
  description: string;
  quantity: string;
  unitPrice: string;
  taxRate: string;
}

const CURRENCIES = ["USD", "EUR", "TND", "GBP", "AED", "SAR", "CAD", "CHF", "QAR", "KWD"];

function statusBadgeStyle(status: InvoiceStatusType): string {
  switch (status) {
    case "PAID":
      return "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/25";
    case "PARTIALLY_PAID":
      return "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/25";
    case "OVERDUE":
      return "bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/25";
    case "UNPAID":
    case "SENT":
      return "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/25";
    case "CANCELLED":
      return "bg-gray-500/10 text-gray-500 dark:text-gray-400 border-gray-500/25";
    default:
      return "bg-[var(--primary)]/10 text-[var(--primary-hover)] dark:text-[var(--primary)] border-[var(--primary)]/25";
  }
}

export default function InvoicesPage() {
  const { openCopilot } = useCopilot();
  const t = useTranslations("Invoices");
  const tKpi = useTranslations("Invoices.kpi");
  const locale = useLocale();
  const isAr = locale === "ar";

  const [wetSignature, setWetSignature] = useState<WetSignatureData | null>(null);

  useEffect(() => {
    setWetSignature(getWetSignature());
    const handler = (e: any) => {
      setWetSignature(e.detail || getWetSignature());
    };
    window.addEventListener("afab-signature-updated", handler);
    return () => window.removeEventListener("afab-signature-updated", handler);
  }, []);

  const [summary, setSummary] = useState<InvoiceSummaryResponse | null>(null);
  const [invoicesData, setInvoicesData] = useState<InvoicePageResponse | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [userProfile, setUserProfile] = useState<{ currency?: string } | null>(null);
  const [currentBusiness, setCurrentBusiness] = useState<BusinessData | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [period, setPeriod] = useState<"WEEKLY" | "MONTHLY" | "YEARLY">("MONTHLY");
  const [page, setPage] = useState(0);

  // Create / Edit Draft Invoice Modal
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingInvoice, setEditingInvoice] = useState<InvoiceDTO | null>(null);
  const [formCustomerId, setFormCustomerId] = useState("");
  const [formIssueDate, setFormIssueDate] = useState(() => new Date().toISOString().split("T")[0]);
  const [formDueDate, setFormDueDate] = useState(() =>
    new Date(Date.now() + 30 * 86400000).toISOString().split("T")[0]
  );
  const [formCurrency, setFormCurrency] = useState("USD");
  const [formDiscount, setFormDiscount] = useState("0");
  const [formNotes, setFormNotes] = useState("");
  const [formItems, setFormItems] = useState<DraftLineItem[]>([
    { description: "", quantity: "1", unitPrice: "", taxRate: "0" },
  ]);
  const [formSubmitting, setFormSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Detail Drawer & Payment Modal
  const [selectedInvoice, setSelectedInvoice] = useState<InvoiceDTO | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [actionBusy, setActionBusy] = useState(false);

  const [isPaymentOpen, setIsPaymentOpen] = useState(false);
  const [payAmount, setPayAmount] = useState("");
  const [payDate, setPayDate] = useState(new Date().toISOString().split("T")[0]);
  const [payMethod, setPayMethod] = useState("BANK_TRANSFER");
  const [payReference, setPayReference] = useState("");
  const [payNotes, setPayNotes] = useState("");
  const [paySubmitting, setPaySubmitting] = useState(false);
  const [payIdempotencyKey, setPayIdempotencyKey] = useState("");

  const searchInputRef = useRef<HTMLInputElement>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      const [sumRes, listRes] = await Promise.all([
        InvoiceService.getSummary(period.toLowerCase()),
        InvoiceService.getInvoices({
          status: statusFilter,
          search: search || undefined,
          page,
          size: 15,
        }),
      ]);
      setSummary(sumRes);
      setInvoicesData(listRes);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load invoices.";
      setLoadError(msg);
    } finally {
      setLoading(false);
    }
  }, [search, statusFilter, page, period]);

  useEffect(() => {
    let active = true;
    Promise.all([
      InvoiceService.getSummary(period.toLowerCase()),
      InvoiceService.getInvoices({
        status: statusFilter,
        search: search || undefined,
        page,
        size: 15,
      }),
    ])
      .then(([sumRes, listRes]) => {
        if (!active) return;
        setSummary(sumRes);
        setInvoicesData(listRes);
        setLoadError(null);
      })
      .catch((err: unknown) => {
        if (!active) return;
        const msg = err instanceof Error ? err.message : "Failed to load invoices.";
        setLoadError(msg);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [search, statusFilter, page, period]);

  useEffect(() => {
    UserService.getProfile()
      .then((prof) => {
        setUserProfile(prof);
        if (prof?.currency) setFormCurrency(prof.currency);
      })
      .catch(() => {});
    BusinessService.getMine()
      .then((b) => setCurrentBusiness(b))
      .catch(() => {});
    CustomerService.getCustomers({ page: 0, size: 100 })
      .then((res) => setCustomers(res.content || []))
      .catch(() => {});
  }, []);

  const openCreateModal = () => {
    setEditingInvoice(null);
    setFormCustomerId("");
    const today = new Date().toISOString().split("T")[0];
    const in30Days = new Date(Date.now() + 30 * 86400000).toISOString().split("T")[0];
    setFormIssueDate(today);
    setFormDueDate(in30Days);
    setFormCurrency(summary?.currency || userProfile?.currency || "USD");
    setFormDiscount("0");
    setFormNotes("");
    setFormItems([{ description: "", quantity: "1", unitPrice: "", taxRate: "0" }]);
    setFormError(null);
    setIsFormOpen(true);
  };

  const openEditDraftModal = (inv: InvoiceDTO) => {
    setEditingInvoice(inv);
    setFormCustomerId(inv.customerId || "");
    setFormIssueDate(inv.issueDate);
    setFormDueDate(inv.dueDate);
    setFormCurrency(inv.currency);
    setFormDiscount(String(inv.discountAmount ?? 0));
    setFormNotes(inv.notes || "");
    setFormItems(
      inv.items && inv.items.length > 0
        ? inv.items.map((it) => ({
            description: it.description,
            quantity: String(it.quantity),
            unitPrice: String(it.unitPrice),
            taxRate: String(it.taxRate ?? 0),
          }))
        : [{ description: "", quantity: "1", unitPrice: "", taxRate: "0" }]
    );
    setFormError(null);
    setIsFormOpen(true);
  };

  const openInvoiceDetail = async (id: string) => {
    setDetailLoading(true);
    try {
      const full = await InvoiceService.getInvoiceById(id);
      setSelectedInvoice(full);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to load invoice details.");
    } finally {
      setDetailLoading(false);
    }
  };

  const handleSaveInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    const parsedItems = formItems
      .filter((it) => it.description.trim() && Number(it.unitPrice) >= 0 && Number(it.quantity) > 0)
      .map((it) => ({
        description: it.description.trim(),
        quantity: Number(it.quantity),
        unitPrice: Number(it.unitPrice),
        taxRate: Number(it.taxRate) || 0,
      }));

    if (parsedItems.length === 0) {
      setFormError("Please enter at least one valid line item.");
      return;
    }

    setFormSubmitting(true);
    try {
      const payload = {
        customerId: formCustomerId || undefined,
        issueDate: formIssueDate,
        dueDate: formDueDate,
        currency: formCurrency,
        discountAmount: Number(formDiscount) || 0,
        notes: formNotes.trim() || undefined,
        items: parsedItems,
      };

      const saved = editingInvoice
        ? await InvoiceService.updateDraftInvoice(editingInvoice.id, payload)
        : await InvoiceService.createInvoice(payload);

      toast.success(
        editingInvoice
          ? `Draft ${saved.invoiceNumber} updated`
          : `Invoice ${saved.invoiceNumber} created as DRAFT`
      );
      setIsFormOpen(false);
      await fetchData();
      if (selectedInvoice && selectedInvoice.id === saved.id) {
        setSelectedInvoice(saved);
      }
    } catch (err: unknown) {
      setFormError(err instanceof Error ? err.message : "Failed to save invoice.");
    } finally {
      setFormSubmitting(false);
    }
  };

  const handleIssueInvoice = async (inv: InvoiceDTO, sent: boolean) => {
    setActionBusy(true);
    try {
      const updated = await InvoiceService.issueInvoice(inv.id, sent);
      toast.success(`Invoice ${updated.invoiceNumber} marked as ${updated.status}`);
      setSelectedInvoice(updated);
      await fetchData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to issue invoice.");
    } finally {
      setActionBusy(false);
    }
  };

  const handleCancelInvoice = async (inv: InvoiceDTO) => {
    setActionBusy(true);
    try {
      const updated = await InvoiceService.cancelInvoice(inv.id);
      toast.success(`Invoice ${updated.invoiceNumber} cancelled`);
      setSelectedInvoice(updated);
      await fetchData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to cancel invoice.");
    } finally {
      setActionBusy(false);
    }
  };

  const openPaymentModal = (inv: InvoiceDTO) => {
    setPayAmount(String(inv.outstandingBalance));
    setPayDate(new Date().toISOString().split("T")[0]);
    setPayMethod("BANK_TRANSFER");
    setPayReference("");
    setPayNotes("");
    // Fresh idempotency key per user-initiated payment dialog so retries are deduplicated cleanly
    setPayIdempotencyKey(`pay-${inv.id}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`);
    setIsPaymentOpen(true);
  };

  const handleRecordPayment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedInvoice) return;
    const numericAmt = Number(payAmount);
    if (!numericAmt || numericAmt <= 0) {
      toast.error("Enter a positive payment amount.");
      return;
    }

    setPaySubmitting(true);
    try {
      await InvoiceService.recordPayment(
        selectedInvoice.id,
        {
          amount: numericAmt,
          currency: selectedInvoice.currency,
          paymentDate: payDate,
          paymentMethod: payMethod,
          reference: payReference.trim() || undefined,
          notes: payNotes.trim() || undefined,
        },
        payIdempotencyKey
      );
      toast.success("Payment recorded and income transaction created.");
      setIsPaymentOpen(false);
      await openInvoiceDetail(selectedInvoice.id);
      await fetchData();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Failed to record payment.");
    } finally {
      setPaySubmitting(false);
    }
  };

  const handleExportCSV = () => {
    if (!invoicesData || !invoicesData.content.length) return;
    const headers = ["Invoice Number,Customer,Issue Date,Due Date,Currency,Total,Paid,Outstanding,Status"];
    const rows = invoicesData.content.map((inv) =>
      `"${inv.invoiceNumber}","${(inv.customerName || "Walk-in").replace(/"/g, '""')}","${inv.issueDate}","${inv.dueDate}","${inv.currency}",${inv.totalAmount},${inv.paidAmount},${inv.outstandingBalance},"${inv.status}"`
    );
    const blob = new Blob(["\uFEFF" + [headers, ...rows].join("\r\n")], {
      type: "text/csv;charset=utf-8;",
    });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `afab-invoices-${new Date().toISOString().split("T")[0]}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const currency = summary?.currency || userProfile?.currency || "USD";
  const statusPieData =
    summary?.statusBreakdown && summary.statusBreakdown.some((st) => st.amount > 0)
      ? summary.statusBreakdown.map((st) => ({
          name: st.name,
          value: st.amount,
          percentage: st.percentage,
          color: st.color,
        }))
      : [{ name: "No Invoices", value: 1, percentage: 0, color: "#1E293B" }];

  // Live form total preview
  const draftPreview = formItems.reduce(
    (acc, it) => {
      const q = Number(it.quantity) || 0;
      const u = Number(it.unitPrice) || 0;
      const tr = Number(it.taxRate) || 0;
      const sub = q * u;
      const tax = (sub * tr) / 100;
      return { subtotal: acc.subtotal + sub, tax: acc.tax + tax };
    },
    { subtotal: 0, tax: 0 }
  );
  const draftTotal = Math.max(0, draftPreview.subtotal + draftPreview.tax - (Number(formDiscount) || 0));

  if (loading && !invoicesData) {
    return (
      <div className="flex h-[75vh] items-center justify-center">
        <AfabLoader text="Loading Invoices..." />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-500">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white sm:text-3xl tracking-tight">
            {t("title")}
          </h1>
          <p className="mt-1.5 text-sm text-gray-500 dark:text-gray-400">{t("subtitle")}</p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <PeriodSelector value={period} onChange={setPeriod} />
          <button
            onClick={handleExportCSV}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/[0.05] transition-all shadow-sm"
          >
            <Download className="h-4 w-4" />
            {t("export")}
          </button>
          <button
            onClick={openCreateModal}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[var(--primary)] text-white text-xs font-bold hover:bg-[var(--primary-hover)] transition-all shadow-lg shadow-[var(--primary)]/25"
          >
            <Plus className="h-4 w-4" />
            {t("createInvoice")}
          </button>
        </div>
      </div>

      {loadError && (
        <div className="rounded-xl border border-red-500/30 bg-red-50 dark:bg-red-500/10 p-4 flex items-center justify-between gap-3 text-sm text-red-600 dark:text-red-400">
          <div className="flex items-center gap-2">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{loadError}</span>
          </div>
          <button
            onClick={fetchData}
            className="px-3 py-1 rounded-lg bg-red-600 text-white text-xs font-semibold hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <KpiCard
          title={tKpi("totalInvoices")}
          value={String(summary?.totalInvoices || 0)}
          change={`${summary?.totalInvoices || 0} active`}
          isPositive={true}
          icon={Receipt}
          data={[0, 0, 0, summary?.totalInvoices || 0]}
        />
        <KpiCard
          title={tKpi("paidInvoices")}
          value={String(summary?.paidInvoices || 0)}
          change={formatCurrency(summary?.paidAmount || 0, currency)}
          isPositive={true}
          icon={CheckCircle}
          data={[0, 0, 0, summary?.paidInvoices || 0]}
        />
        <KpiCard
          title={tKpi("pendingInvoices")}
          value={String(summary?.pendingInvoices || 0)}
          change={formatCurrency(summary?.pendingAmount || 0, currency)}
          isPositive={(summary?.pendingInvoices || 0) === 0}
          icon={Clock}
          data={[0, 0, 0, summary?.pendingInvoices || 0]}
        />
        <KpiCard
          title={tKpi("overdueInvoices")}
          value={String(summary?.overdueInvoices || 0)}
          change={formatCurrency(summary?.overdueAmount || 0, currency)}
          isPositive={(summary?.overdueInvoices || 0) === 0}
          icon={AlertTriangle}
          data={[0, 0, 0, summary?.overdueInvoices || 0]}
        />
        <KpiCard
          title={tKpi("totalInvoiceAmount")}
          value={formatCurrency(summary?.totalInvoiceAmount || 0, currency)}
          change={`Due: ${formatCurrency(invoicesData?.totalOutstanding || 0, currency)}`}
          isPositive={true}
          icon={Wallet}
          data={[0, 0, 0, summary?.totalInvoiceAmount || 0]}
        />
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <div className="lg:col-span-9 rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm overflow-hidden">
          <div className="p-5 border-b border-gray-100 dark:border-gray-800/60 flex flex-col sm:flex-row gap-3 items-center justify-between">
            <div className="relative w-full sm:max-w-xs">
              <Search className="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                ref={searchInputRef}
                type="text"
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(0);
                }}
                placeholder="Search invoice # or customer..."
                className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] ps-9 pe-3 py-2 text-xs text-gray-900 dark:text-white focus:border-[var(--primary)] focus:outline-none"
              />
            </div>

            <div className="flex flex-wrap items-center gap-1.5">
              {["ALL", "DRAFT", "UNPAID", "PARTIALLY_PAID", "PAID", "OVERDUE", "CANCELLED"].map((st) => (
                <button
                  key={st}
                  onClick={() => {
                    setStatusFilter(st);
                    setPage(0);
                  }}
                  className={`px-2.5 py-1.5 rounded-lg text-[11px] font-semibold transition-colors ${
                    statusFilter === st
                      ? "bg-[var(--primary)] text-white"
                      : "bg-gray-100 dark:bg-white/[0.04] text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                  }`}
                >
                  {st.replace("_", " ")}
                </button>
              ))}
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-start text-sm">
              <thead className="bg-gray-50/70 dark:bg-[#080c18] text-[11px] uppercase tracking-wider text-gray-500 dark:text-gray-400">
                <tr>
                  <th className="px-5 py-3.5 text-start">Invoice #</th>
                  <th className="px-5 py-3.5 text-start">Customer</th>
                  <th className="px-5 py-3.5 text-start">Due Date</th>
                  <th className="px-5 py-3.5 text-end">Total</th>
                  <th className="px-5 py-3.5 text-end">Balance</th>
                  <th className="px-5 py-3.5 text-start">Status</th>
                  <th className="px-5 py-3.5 text-end">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800/60">
                {!invoicesData || invoicesData.content.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-5 py-12 text-center text-sm text-gray-500 dark:text-gray-400">
                      No invoices found. Click &quot;{t("createInvoice")}&quot; to issue your first invoice.
                    </td>
                  </tr>
                ) : (
                  invoicesData.content.map((inv) => (
                    <tr
                      key={inv.id}
                      onClick={() => openInvoiceDetail(inv.id)}
                      className="hover:bg-gray-50/70 dark:hover:bg-white/[0.02] cursor-pointer transition-colors"
                    >
                      <td className="px-5 py-4 font-mono text-xs font-bold text-gray-900 dark:text-white">
                        {inv.invoiceNumber}
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-xs font-semibold text-gray-900 dark:text-white">
                          {inv.customerName || "Walk-in / General"}
                        </p>
                        {inv.customerEmail && (
                          <p className="text-[11px] text-gray-400">{inv.customerEmail}</p>
                        )}
                      </td>
                      <td className="px-5 py-4 text-xs text-gray-600 dark:text-gray-300">
                        {inv.dueDate}
                      </td>
                      <td className="px-5 py-4 text-end font-semibold text-xs text-gray-900 dark:text-white">
                        {formatCurrency(inv.totalAmount, inv.currency)}
                      </td>
                      <td className="px-5 py-4 text-end font-semibold text-xs text-gray-700 dark:text-gray-300">
                        {formatCurrency(inv.outstandingBalance, inv.currency)}
                      </td>
                      <td className="px-5 py-4">
                        <span
                          className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-[10px] font-bold ${statusBadgeStyle(inv.status)}`}
                        >
                          {inv.status.replace("_", " ")}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-end">
                        <div className="inline-flex items-center gap-1">
                          {(inv.status === "OVERDUE" || inv.status === "UNPAID" || inv.status === "PARTIALLY_PAID") && (
                            <button
                              type="button"
                              onClick={(e) => {
                                e.stopPropagation();
                                openCopilot({
                                  prompt: `Draft an Email & WhatsApp payment reminder for invoice ${inv.invoiceNumber} (${inv.customerName || "Client"}, balance ${inv.outstandingBalance} ${inv.currency}, due ${inv.dueDate}).`,
                                  autoSend: true,
                                  screenContext: { page: "invoices", invoiceNumber: inv.invoiceNumber },
                                });
                              }}
                              className="p-1.5 rounded-lg text-[var(--primary)] hover:bg-[var(--primary)]/10"
                              title="Draft AI Reminder"
                            >
                              <Sparkles className="h-4 w-4" />
                            </button>
                          )}
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              openInvoiceDetail(inv.id);
                            }}
                            className="p-1.5 rounded-lg text-gray-400 hover:text-[var(--primary)] hover:bg-[var(--primary)]/10"
                            title="Inspect invoice"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {invoicesData && invoicesData.totalPages > 1 && (
            <div className="px-5 py-3.5 border-t border-gray-100 dark:border-gray-800/60 flex items-center justify-between text-xs text-gray-500">
              <span>
                Page {invoicesData.pageNumber + 1} of {invoicesData.totalPages} ({invoicesData.totalElements} total)
              </span>
              <div className="flex items-center gap-2">
                <button
                  disabled={page === 0}
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 disabled:opacity-40"
                >
                  <ChevronLeft className="h-4 w-4 rtl:rotate-180" />
                </button>
                <button
                  disabled={page + 1 >= invoicesData.totalPages}
                  onClick={() => setPage((p) => p + 1)}
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 disabled:opacity-40"
                >
                  <ChevronRight className="h-4 w-4 rtl:rotate-180" />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Side Widgets */}
        <div className="lg:col-span-3 space-y-6">
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm">
            <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-4">Receivables Breakdown</h3>
            <ChartContainer className="h-44 w-full">
              <ResponsiveContainer width="100%" height="100%" minWidth={1} minHeight={1} initialDimension={{ width: 220, height: 176 }}>
                <PieChart>
                  <Pie data={statusPieData} dataKey="value" innerRadius={48} outerRadius={70} paddingAngle={3}>
                    {statusPieData.map((entry, idx) => (
                      <Cell key={idx} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "rgba(12, 16, 28, 0.92)",
                      borderColor: "rgba(139, 92, 246, 0.25)",
                      borderRadius: "10px",
                      color: "#fff",
                      fontSize: "12px",
                    }}
                    itemStyle={{ color: "#fff" }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </ChartContainer>
            <div className="mt-3 space-y-2">
              {(summary?.statusBreakdown || []).map((st) => (
                <div key={st.name} className="flex items-center justify-between text-xs">
                  <span className="flex items-center gap-2 text-gray-600 dark:text-gray-300">
                    <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: st.color }} />
                    {st.name}
                  </span>
                  <span className="font-semibold text-gray-900 dark:text-white">
                    {formatCurrency(st.amount, currency)} ({st.percentage}%)
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-sm">
            <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-3">Upcoming / Overdue Due</h3>
            {!summary?.upcomingDueList?.length ? (
              <p className="text-xs text-gray-500 dark:text-gray-400">No unpaid invoices due.</p>
            ) : (
              <div className="space-y-2.5">
                {summary.upcomingDueList.map((item) => (
                  <div
                    key={item.invoiceId}
                    className="rounded-xl border border-gray-100 dark:border-gray-800/80 p-3 flex items-center justify-between gap-2"
                  >
                    <div className="min-w-0">
                      <p className="text-xs font-bold text-gray-900 dark:text-white truncate">{item.invoiceId}</p>
                      <p className="text-[11px] text-gray-500 truncate">{item.customerName}</p>
                      <p className="text-[10px] text-amber-600 dark:text-amber-400">Due {item.dueDate}</p>
                    </div>
                    <span className="text-xs font-bold text-gray-900 dark:text-white shrink-0">
                      {formatCurrency(item.amount, currency)}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Create / Edit Draft Invoice Modal */}
      {isFormOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-3xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] p-6 shadow-2xl">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800">
              <h2 className="text-lg font-bold text-gray-900 dark:text-white">
                {editingInvoice ? `Edit Draft ${editingInvoice.invoiceNumber}` : "Create Invoice (Draft)"}
              </h2>
              <button onClick={() => setIsFormOpen(false)} className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSaveInvoice} className="mt-5 space-y-5">
              {formError && (
                <div className="rounded-xl bg-red-50 dark:bg-red-500/10 border border-red-500/20 p-3 text-xs text-red-600 dark:text-red-400">
                  {formError}
                </div>
              )}

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Customer (Optional)</label>
                  <select
                    value={formCustomerId}
                    onChange={(e) => setFormCustomerId(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-sm text-gray-900 dark:text-white"
                  >
                    <option value="">Walk-in / No Customer</option>
                    {customers.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name} ({c.customerCode})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Invoice Currency</label>
                  <select
                    value={formCurrency}
                    onChange={(e) => setFormCurrency(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-sm text-gray-900 dark:text-white"
                  >
                    {Array.from(new Set([currency, ...CURRENCIES])).map((c) => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Issue Date *</label>
                  <input
                    type="date"
                    required
                    value={formIssueDate}
                    onChange={(e) => setFormIssueDate(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-sm text-gray-900 dark:text-white"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Due Date *</label>
                  <input
                    type="date"
                    required
                    value={formDueDate}
                    onChange={(e) => setFormDueDate(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-sm text-gray-900 dark:text-white"
                  />
                </div>
              </div>

              {/* Line Items */}
              <div className="space-y-2.5">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-bold text-gray-700 dark:text-gray-300">Line Items</label>
                  <button
                    type="button"
                    onClick={() =>
                      setFormItems((prev) => [...prev, { description: "", quantity: "1", unitPrice: "", taxRate: "0" }])
                    }
                    className="text-xs font-semibold text-[var(--primary-hover)] hover:underline flex items-center gap-1"
                  >
                    <Plus className="h-3.5 w-3.5" /> Add Line
                  </button>
                </div>

                {formItems.map((it, idx) => (
                  <div key={idx} className="grid grid-cols-12 gap-2 items-center">
                    <input
                      type="text"
                      required
                      placeholder="Item description"
                      value={it.description}
                      onChange={(e) =>
                        setFormItems((prev) =>
                          prev.map((row, i) => (i === idx ? { ...row, description: e.target.value } : row))
                        )
                      }
                      className="col-span-5 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs text-gray-900 dark:text-white"
                    />
                    <input
                      type="number"
                      step="any"
                      min="0.01"
                      required
                      placeholder="Qty"
                      value={it.quantity}
                      onChange={(e) =>
                        setFormItems((prev) =>
                          prev.map((row, i) => (i === idx ? { ...row, quantity: e.target.value } : row))
                        )
                      }
                      className="col-span-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-2.5 py-2 text-xs text-gray-900 dark:text-white"
                    />
                    <input
                      type="number"
                      step="any"
                      min="0"
                      required
                      placeholder="Unit Price"
                      value={it.unitPrice}
                      onChange={(e) =>
                        setFormItems((prev) =>
                          prev.map((row, i) => (i === idx ? { ...row, unitPrice: e.target.value } : row))
                        )
                      }
                      className="col-span-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-2.5 py-2 text-xs text-gray-900 dark:text-white"
                    />
                    <input
                      type="number"
                      step="0.1"
                      min="0"
                      max="100"
                      placeholder="Tax %"
                      value={it.taxRate}
                      onChange={(e) =>
                        setFormItems((prev) =>
                          prev.map((row, i) => (i === idx ? { ...row, taxRate: e.target.value } : row))
                        )
                      }
                      className="col-span-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-2.5 py-2 text-xs text-gray-900 dark:text-white"
                    />
                    <button
                      type="button"
                      disabled={formItems.length === 1}
                      onClick={() => setFormItems((prev) => prev.filter((_, i) => i !== idx))}
                      className="col-span-1 flex justify-center text-gray-400 hover:text-red-500 disabled:opacity-30"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-end">
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Discount ({formCurrency})</label>
                  <input
                    type="number"
                    step="any"
                    min="0"
                    value={formDiscount}
                    onChange={(e) => setFormDiscount(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-sm text-gray-900 dark:text-white"
                  />
                </div>
                <div className="rounded-xl bg-gray-50 dark:bg-white/[0.03] border border-gray-200 dark:border-gray-800 p-3 text-xs space-y-1">
                  <div className="flex justify-between">
                    <span className="text-gray-500">Subtotal</span>
                    <span>{formatCurrency(draftPreview.subtotal, formCurrency)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Tax</span>
                    <span>{formatCurrency(draftPreview.tax, formCurrency)}</span>
                  </div>
                  <div className="flex justify-between font-bold text-sm text-gray-900 dark:text-white pt-1 border-t border-gray-200 dark:border-gray-800">
                    <span>Total</span>
                    <span>{formatCurrency(draftTotal, formCurrency)}</span>
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Notes</label>
                <textarea
                  rows={2}
                  value={formNotes}
                  onChange={(e) => setFormNotes(e.target.value)}
                  placeholder="Payment terms, bank details, or reference notes..."
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-sm text-gray-900 dark:text-white"
                />
              </div>

              <div className="flex justify-end gap-3 pt-3 border-t border-gray-100 dark:border-gray-800">
                <button
                  type="button"
                  onClick={() => setIsFormOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05]"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={formSubmitting}
                  className="px-5 py-2 rounded-xl text-xs font-bold bg-[var(--primary)] text-white hover:bg-[var(--primary-hover)] disabled:opacity-50"
                >
                  {formSubmitting ? "Saving..." : editingInvoice ? "Update Draft" : "Save Draft Invoice"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Invoice Detail Drawer */}
      {(selectedInvoice || detailLoading) && (
        <div className="fixed inset-0 z-50 flex justify-end bg-black/50 backdrop-blur-sm">
          <div className="w-full max-w-xl bg-white dark:bg-[#0c101c] h-full overflow-y-auto border-s border-gray-200 dark:border-gray-800 p-6 shadow-2xl space-y-6">
            {detailLoading || !selectedInvoice ? (
              <div className="flex h-full items-center justify-center">
                <AfabLoader text="Loading invoice..." />
              </div>
            ) : (
              <>
                <div className="flex items-start justify-between gap-4 pb-4 border-b border-gray-100 dark:border-gray-800">
                  {/* LEFT: Business Brand, Name & Matricule Fiscale */}
                  <div className="flex items-start gap-3">
                    <div className="h-12 w-12 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-black/30 p-1 flex items-center justify-center shrink-0 overflow-hidden shadow-xs">
                      <img
                        src={
                          currentBusiness?.logoUrl ||
                          (typeof window !== "undefined" ? localStorage.getItem("afab_business_logo") || "" : "") ||
                          "/assets/afab-logo-light.png"
                        }
                        alt={currentBusiness?.name || "Business Logo"}
                        className="max-h-full max-w-full object-contain"
                      />
                    </div>
                    <div>
                      <span className="text-[10px] font-bold text-[var(--primary)] uppercase tracking-wider block">
                        {isAr ? "الشركة المُصدرة" : "Issuer"}
                      </span>
                      <h3 className="text-sm font-bold text-gray-900 dark:text-white leading-tight">
                        {currentBusiness?.name || "AFAB Enterprise"}
                      </h3>
                      <div className="flex items-center gap-1.5 mt-1">
                        <span className="text-[10px] font-semibold text-gray-500 dark:text-gray-400">
                          {isAr ? "المعرف الجبائي (MF):" : "MF:"}
                        </span>
                        {currentBusiness?.taxId ? (
                          <span className="text-[10px] font-mono font-bold text-[var(--primary)] bg-purple-500/10 px-1.5 py-0.5 rounded border border-purple-500/20">
                            {currentBusiness.taxId}
                          </span>
                        ) : (
                          <Link
                            href="/dashboard/settings/business-profile"
                            className="text-[10px] font-semibold text-[var(--primary)] hover:underline inline-flex items-center gap-0.5"
                          >
                            {isAr ? "إضافة +" : "Set +"}
                          </Link>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* RIGHT: Client Name, Invoice Number & Close */}
                  <div className="flex items-start gap-3 text-end">
                    <div>
                      <span className="text-[10px] font-bold text-[var(--primary)] uppercase tracking-wider block">
                        {isAr ? "العميل" : "Client / Billed To"}
                      </span>
                      <h2 className="text-sm font-extrabold text-gray-900 dark:text-white leading-tight">
                        {selectedInvoice.customerName || (isAr ? "عميل عام" : "General Client")}
                      </h2>
                      <div className="flex items-center justify-end gap-1.5 mt-1">
                        <span className="text-xs font-mono font-bold text-gray-600 dark:text-gray-300">
                          {selectedInvoice.invoiceNumber}
                        </span>
                        <span
                          className={`rounded-full border px-2 py-0.5 text-[9px] font-bold ${statusBadgeStyle(selectedInvoice.status)}`}
                        >
                          {selectedInvoice.status.replace("_", " ")}
                        </span>
                      </div>
                      <p className="text-[10px] text-gray-400 mt-0.5">
                        {selectedInvoice.issueDate}
                      </p>
                    </div>
                    <button
                      onClick={() => setSelectedInvoice(null)}
                      className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-white -mr-1"
                    >
                      <X className="h-5 w-5" />
                    </button>
                  </div>
                </div>

                {/* Lifecycle Actions */}
                <div className="flex flex-wrap gap-2">
                  <button
                    disabled={actionBusy}
                    onClick={() =>
                      openPrintableInvoiceWindow({
                        invoice: selectedInvoice,
                        business: currentBusiness,
                        fiscalMatricule: currentBusiness?.taxId || (typeof window !== "undefined" ? localStorage.getItem("afab_fiscal_matricule") || "" : ""),
                        businessAddress: formatBusinessAddress(currentBusiness) || (typeof window !== "undefined" ? localStorage.getItem("afab_business_address") || "" : ""),
                        businessLogoUrl: currentBusiness?.logoUrl || (typeof window !== "undefined" ? localStorage.getItem("afab_business_logo") || "" : ""),
                        isAr,
                      })
                    }
                    className="flex items-center gap-1.5 px-3 py-2 rounded-xl border border-purple-200 dark:border-purple-800/80 bg-purple-50/60 dark:bg-purple-950/20 text-[var(--primary)] text-xs font-semibold hover:bg-purple-100 dark:hover:bg-purple-900/40 transition-colors"
                  >
                    <Printer className="h-3.5 w-3.5" /> {isAr ? "طباعة / PDF الفاتورة" : "Print / PDF Invoice"}
                  </button>
                  {selectedInvoice.status === "DRAFT" && (
                    <>
                      <button
                        disabled={actionBusy}
                        onClick={() => openEditDraftModal(selectedInvoice)}
                        className="flex items-center gap-1.5 px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-800 text-xs font-semibold hover:bg-gray-50 dark:hover:bg-white/[0.05]"
                      >
                        <Pencil className="h-3.5 w-3.5" /> Edit Draft
                      </button>
                      <button
                        disabled={actionBusy}
                        onClick={() => handleIssueInvoice(selectedInvoice, true)}
                        className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[var(--primary)] text-white text-xs font-bold hover:bg-[var(--primary-hover)]"
                      >
                        <Send className="h-3.5 w-3.5" /> Issue / Send Invoice
                      </button>
                    </>
                  )}
                  {(selectedInvoice.status === "UNPAID" ||
                    selectedInvoice.status === "SENT" ||
                    selectedInvoice.status === "PARTIALLY_PAID" ||
                    selectedInvoice.status === "OVERDUE") && (
                    <button
                      disabled={actionBusy}
                      onClick={() => openPaymentModal(selectedInvoice)}
                      className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700"
                    >
                      <DollarSign className="h-3.5 w-3.5" /> Record Payment
                    </button>
                  )}
                  {selectedInvoice.status !== "PAID" &&
                    selectedInvoice.status !== "CANCELLED" &&
                    selectedInvoice.paidAmount === 0 && (
                      <button
                        disabled={actionBusy}
                        onClick={() => handleCancelInvoice(selectedInvoice)}
                        className="flex items-center gap-1.5 px-3 py-2 rounded-xl border border-red-500/30 text-red-600 dark:text-red-400 text-xs font-semibold hover:bg-red-50 dark:hover:bg-red-500/10"
                      >
                        <Ban className="h-3.5 w-3.5" /> Cancel Invoice
                      </button>
                    )}
                </div>

                {/* Financial Totals */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div className="rounded-xl border border-gray-100 dark:border-gray-800 p-3">
                    <p className="text-[11px] text-gray-500">Total</p>
                    <p className="text-sm font-bold text-gray-900 dark:text-white mt-0.5">
                      {formatCurrency(selectedInvoice.totalAmount, selectedInvoice.currency)}
                    </p>
                  </div>
                  <div className="rounded-xl border border-emerald-500/20 bg-emerald-500/5 p-3">
                    <p className="text-[11px] text-emerald-600 dark:text-emerald-400">Paid</p>
                    <p className="text-sm font-bold text-emerald-700 dark:text-emerald-300 mt-0.5">
                      {formatCurrency(selectedInvoice.paidAmount, selectedInvoice.currency)}
                    </p>
                  </div>
                  <div className="rounded-xl border border-amber-500/20 bg-amber-500/5 p-3">
                    <p className="text-[11px] text-amber-600 dark:text-amber-400">Outstanding</p>
                    <p className="text-sm font-bold text-amber-700 dark:text-amber-300 mt-0.5">
                      {formatCurrency(selectedInvoice.outstandingBalance, selectedInvoice.currency)}
                    </p>
                  </div>
                </div>

                {/* Line Items */}
                <div>
                  <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">Line Items</h3>
                  <div className="rounded-xl border border-gray-100 dark:border-gray-800 divide-y divide-gray-100 dark:divide-gray-800">
                    {selectedInvoice.items.map((it, idx) => (
                      <div key={it.id || idx} className="p-3 flex items-center justify-between text-xs">
                        <div>
                          <p className="font-semibold text-gray-900 dark:text-white">{it.description}</p>
                          <p className="text-gray-500">
                            {it.quantity} × {formatCurrency(it.unitPrice, selectedInvoice.currency)}
                            {it.taxRate > 0 ? ` (+${it.taxRate}% tax)` : ""}
                          </p>
                        </div>
                        <span className="font-bold text-gray-900 dark:text-white">
                          {formatCurrency(it.lineTotal ?? it.quantity * it.unitPrice, selectedInvoice.currency)}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Payment History */}
                <div>
                  <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">
                    Payment History ({selectedInvoice.payments?.length || 0})
                  </h3>
                  {!selectedInvoice.payments?.length ? (
                    <p className="text-xs text-gray-500 dark:text-gray-400 rounded-xl border border-dashed border-gray-200 dark:border-gray-800 p-4 text-center">
                      No payments recorded yet. Unpaid invoices do not record income until paid.
                    </p>
                  ) : (
                    <div className="space-y-2">
                      {selectedInvoice.payments.map((p) => (
                        <div
                          key={p.id}
                          className="rounded-xl border border-gray-100 dark:border-gray-800 p-3 flex items-center justify-between text-xs"
                        >
                          <div>
                            <p className="font-bold text-emerald-600 dark:text-emerald-400">
                              +{formatCurrency(p.amount, p.currency)}
                              {p.currency !== p.baseCurrency && (
                                <span className="text-gray-500 font-normal ms-1.5">
                                  ({formatCurrency(p.convertedBaseAmount, p.baseCurrency)} @ {p.exchangeRate})
                                </span>
                              )}
                            </p>
                            <p className="text-[11px] text-gray-500">
                              {p.paymentDate} · {p.paymentMethod}
                              {p.reference ? ` · Ref: ${p.reference}` : ""}
                            </p>
                          </div>
                          <span className="text-[10px] font-mono text-gray-400">
                            TX {p.incomeTransactionId?.slice(0, 8)}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Wet Signature & Signatory Seal */}
                <div className="pt-4 border-t border-gray-100 dark:border-gray-800 space-y-2">
                  <div className="flex items-center justify-between">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400 flex items-center gap-1.5">
                      <FileSignature className="w-3.5 h-3.5 text-[var(--primary)]" />
                      <span>{isAr ? "التوقيع الحي والاعتماد الرسمي" : "Authorized Signature & Seal"}</span>
                    </h3>
                  </div>
                  {wetSignature?.dataUrl && wetSignature.enabled ? (
                    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-gray-50/60 dark:bg-white/[0.02] p-4 flex items-center justify-between">
                      <div>
                        <p className="text-xs font-bold text-gray-900 dark:text-white">
                          {wetSignature.signatoryName}
                        </p>
                        <p className="text-[11px] text-gray-500 dark:text-gray-400">
                          {wetSignature.signatoryTitle}
                        </p>
                        {currentBusiness?.taxId && (
                          <p className="text-[10px] font-mono font-semibold text-[var(--primary)] mt-0.5">
                            {isAr ? "المعرف الجبائي:" : "MF:"} {currentBusiness.taxId}
                          </p>
                        )}
                        <span className="inline-flex items-center gap-1 mt-1 text-[10px] font-semibold text-emerald-600 dark:text-emerald-400">
                          <CheckCircle2 className="w-3 h-3" /> {isAr ? "معتمد وموثق رقمياً" : "Digitally Certified"}
                        </span>
                      </div>
                      <div className="h-14 w-36 flex items-center justify-end">
                        <img
                          src={wetSignature.dataUrl}
                          alt="Wet Signature"
                          className="max-h-full max-w-full object-contain filter contrast-125"
                        />
                      </div>
                    </div>
                  ) : (
                    <div className="rounded-2xl border border-dashed border-gray-200 dark:border-gray-800 p-4 text-center">
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {isAr ? "لم يتم إضافة توقيع حي بعد." : "No wet signature configured yet."}
                      </p>
                      <Link
                        href="/dashboard/settings/signature"
                        className="text-xs font-semibold text-[var(--primary)] hover:underline mt-1 inline-block"
                      >
                        {isAr ? "إضافة توقيعك الحي من الإعدادات ←" : "Configure your wet signature in Settings →"}
                      </Link>
                    </div>
                  )}
                </div>
              </>
            )}
          </div>
        </div>
      )}

      {/* Record Payment Modal */}
      {isPaymentOpen && selectedInvoice && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] p-6 shadow-2xl">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100 dark:border-gray-800">
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-white">Record Payment</h3>
                <p className="text-xs text-gray-500">
                  {selectedInvoice.invoiceNumber} · Remaining: {formatCurrency(selectedInvoice.outstandingBalance, selectedInvoice.currency)}
                </p>
              </div>
              <button onClick={() => setIsPaymentOpen(false)} className="p-1 text-gray-400 hover:text-gray-700">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleRecordPayment} className="mt-4 space-y-4">
              <div>
                <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Amount ({selectedInvoice.currency}) *
                </label>
                <input
                  type="number"
                  step="any"
                  min="0.0001"
                  max={selectedInvoice.outstandingBalance}
                  required
                  value={payAmount}
                  onChange={(e) => setPayAmount(e.target.value)}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-sm font-semibold text-gray-900 dark:text-white"
                />
                <p className="text-[11px] text-gray-400 mt-1">
                  Supports full or partial payment up to {formatCurrency(selectedInvoice.outstandingBalance, selectedInvoice.currency)}.
                </p>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Payment Date *</label>
                  <input
                    type="date"
                    required
                    value={payDate}
                    onChange={(e) => setPayDate(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs text-gray-900 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Method</label>
                  <select
                    value={payMethod}
                    onChange={(e) => setPayMethod(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs text-gray-900 dark:text-white"
                  >
                    <option value="BANK_TRANSFER">Bank Transfer</option>
                    <option value="CARD">Card</option>
                    <option value="CASH">Cash</option>
                    <option value="OTHER">Other</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Reference</label>
                <input
                  type="text"
                  value={payReference}
                  onChange={(e) => setPayReference(e.target.value)}
                  placeholder="Wire transfer # or receipt reference"
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs text-gray-900 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Notes</label>
                <input
                  type="text"
                  value={payNotes}
                  onChange={(e) => setPayNotes(e.target.value)}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs text-gray-900 dark:text-white"
                />
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t border-gray-100 dark:border-gray-800">
                <button
                  type="button"
                  onClick={() => setIsPaymentOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-gray-600 dark:text-gray-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={paySubmitting}
                  className="px-5 py-2 rounded-xl text-xs font-bold bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-50"
                >
                  {paySubmitting ? "Recording..." : "Confirm Payment"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
