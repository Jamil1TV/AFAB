"use client";

import { useState, useEffect, useMemo } from "react";
import { useTranslations, useLocale } from "next-intl";
import { 
  Download, 
  FileSpreadsheet, 
  FileText, 
  Printer, 
  Calendar, 
  Building2, 
  Receipt, 
  Users, 
  Coins, 
  TrendingUp, 
  ShieldCheck, 
  Loader2, 
  Sparkles,
  ArrowDownToLine,
  RefreshCw,
  Clock,
  Layers,
  Database,
  Filter,
  CalendarDays,
  Image as ImageIcon
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { toast } from "sonner";
import { TransactionService, TransactionItem } from "@/lib/api/transactions";
import { CustomerService, Customer } from "@/lib/api/customers";
import { InvoiceService, InvoiceDTO } from "@/lib/api/invoices";
import { ReportService } from "@/lib/api/reports";
import { 
  exportMasterToExcel, 
  exportMasterToPdf, 
  exportDatasetToExcel, 
  openPrintableReportWindow,
  calculateDateRange,
  formatBusinessAddress,
  PERIOD_PRESETS,
  MasterExportData 
} from "@/lib/export-utils";
import { formatCurrency } from "@/lib/currency";
import { ExportPeriodModal, ExportActionType } from "./ExportPeriodModal";

export function DataExportSettings({
  profile,
  business,
}: {
  profile: any;
  business: any;
}) {
  const t = useTranslations("settings");
  const locale = useLocale();
  const isAr = locale === "ar";

  // ── Period & Currency Filter States ──
  const [selectedPeriod, setSelectedPeriod] = useState<string>("all");
  const [customStartDate, setCustomStartDate] = useState<string>("");
  const [customEndDate, setCustomEndDate] = useState<string>("");
  const [selectedCurrency, setSelectedCurrency] = useState<string>(
    business?.currency || "USD"
  );

  // ── Raw Data States ──
  const [loadingData, setLoadingData] = useState<boolean>(true);
  const [transactions, setTransactions] = useState<TransactionItem[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [invoices, setInvoices] = useState<InvoiceDTO[]>([]);

  // ── Export Loading States ──
  const [exportingMasterExcel, setExportingMasterExcel] = useState(false);
  const [exportingMasterPdf, setExportingMasterPdf] = useState(false);
  const [exportingModule, setExportingModule] = useState<string | null>(null);

  // ── Pre-Download Confirmation Modal State ──
  const [modalAction, setModalAction] = useState<ExportActionType | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const openExportModal = (action: ExportActionType) => {
    setModalAction(action);
    setIsModalOpen(true);
  };

  // Fetch all records from backend on mount
  const fetchAllData = async () => {
    setLoadingData(true);
    try {
      const [txRes, custRes, invRes] = await Promise.allSettled([
        TransactionService.getTransactions({ page: 0, size: 1000 }),
        CustomerService.getCustomers({ page: 0, size: 1000 }),
        InvoiceService.getInvoices({ page: 0, size: 1000 })
      ]);

      const txList: TransactionItem[] = txRes.status === "fulfilled" ? (txRes.value?.content || txRes.value || []) : [];
      const custList: Customer[] = custRes.status === "fulfilled" ? (custRes.value?.content || custRes.value || []) : [];
      const invList: InvoiceDTO[] = invRes.status === "fulfilled" ? (invRes.value?.content || invRes.value || []) : [];

      setTransactions(txList);
      setCustomers(custList);
      setInvoices(invList);
    } catch (err) {
      console.error("Failed to load export datasets:", err);
      toast.error(isAr ? "تعذر تحميل بعض مجموعات البيانات" : "Could not fetch data sets");
    } finally {
      setLoadingData(false);
    }
  };

  useEffect(() => {
    fetchAllData();
  }, []);

  // ── Active Date Range Resolution ──
  const activeDateRange = useMemo(() => {
    return calculateDateRange(selectedPeriod, customStartDate, customEndDate, isAr);
  }, [selectedPeriod, customStartDate, customEndDate, isAr]);

  // ── Filtered Records Based on Period ──
  const filteredTransactions = useMemo(() => {
    const { startDate, endDate } = activeDateRange;
    if (!startDate && !endDate) return transactions;

    return transactions.filter((t) => {
      if (!t.transactionDate) return false;
      const d = new Date(t.transactionDate);
      if (isNaN(d.getTime())) return true;
      if (startDate && d < startDate) return false;
      if (endDate && d > endDate) return false;
      return true;
    });
  }, [transactions, activeDateRange]);

  const filteredInvoices = useMemo(() => {
    const { startDate, endDate } = activeDateRange;
    if (!startDate && !endDate) return invoices;

    return invoices.filter((inv) => {
      if (!inv.issueDate) return false;
      const d = new Date(inv.issueDate);
      if (isNaN(d.getTime())) return true;
      if (startDate && d < startDate) return false;
      if (endDate && d > endDate) return false;
      return true;
    });
  }, [invoices, activeDateRange]);

  // Dynamic Financial Metrics for the Filtered Period
  const filteredSummary = useMemo(() => {
    let revenue = 0;
    let expenses = 0;

    filteredTransactions.forEach((tx) => {
      const amt = Number(tx.amount || 0);
      if (tx.type === "INCOME") revenue += amt;
      else if (tx.type === "EXPENSE") expenses += amt;
    });

    return {
      revenue,
      expenses,
      netBalance: revenue - expenses
    };
  }, [filteredTransactions]);

  // Customer Registry with period spending
  const filteredCustomers = useMemo(() => {
    return customers.map((c) => {
      // Calculate customer-specific spent inside filtered period if any
      const customerTxs = filteredTransactions.filter(
        (t) => (t as any).customerId === c.id || t.description?.toLowerCase().includes(c.name.toLowerCase())
      );
      const periodSpend = customerTxs.reduce((sum, t) => sum + (t.type === "INCOME" ? Number(t.amount || 0) : 0), 0);

      return {
        id: c.customerCode || c.id,
        orderNumber:
          c.orders && c.orders.length > 0
            ? c.orders.map((o) => o.orderNumber).join(", ")
            : c.ordersCount
            ? `${c.ordersCount} orders`
            : "-",
        name: c.name,
        email: c.email || "-",
        phone: c.phone || "-",
        totalSpent: periodSpend > 0 ? periodSpend : Number(c.totalRevenue || 0),
        invoicesCount: c.ordersCount || 0,
        status: c.status || "ACTIVE",
        group: c.group || "Standard"
      };
    });
  }, [customers, filteredTransactions]);

  // ── Dataset Generator with Period & Currency Scoping ──
  const getExportDataForPeriod = (
    targetPeriod?: string,
    targetStart?: string,
    targetEnd?: string,
    targetCurrency?: string
  ): MasterExportData => {
    const periodToUse = targetPeriod ?? selectedPeriod;
    const startToUse = targetStart ?? customStartDate;
    const endToUse = targetEnd ?? customEndDate;
    const currencyToUse = targetCurrency ?? selectedCurrency;

    const range = calculateDateRange(periodToUse, startToUse, endToUse, isAr);
    const { startDate, endDate } = range;

    // Filter transactions by resolved date range
    const txs = transactions.filter((t) => {
      if (!t.transactionDate) return false;
      const d = new Date(t.transactionDate);
      if (isNaN(d.getTime())) return true;
      if (startDate && d < startDate) return false;
      if (endDate && d > endDate) return false;
      return true;
    });

    // Filter invoices by resolved date range
    const invs = invoices.filter((inv) => {
      if (!inv.issueDate) return false;
      const d = new Date(inv.issueDate);
      if (isNaN(d.getTime())) return true;
      if (startDate && d < startDate) return false;
      if (endDate && d > endDate) return false;
      return true;
    });

    // Period Financial Aggregations
    let revenue = 0;
    let expenses = 0;
    txs.forEach((tx) => {
      const amt = Number(tx.amount || 0);
      if (tx.type === "INCOME") revenue += amt;
      else if (tx.type === "EXPENSE") expenses += amt;
    });

    // Scoped Customer Registry
    const custs = customers.map((c) => {
      const customerTxs = txs.filter(
        (t) => (t as any).customerId === c.id || t.description?.toLowerCase().includes(c.name.toLowerCase())
      );
      const periodSpend = customerTxs.reduce((sum, t) => sum + (t.type === "INCOME" ? Number(t.amount || 0) : 0), 0);

      return {
        id: c.customerCode || c.id,
        orderNumber:
          c.orders && c.orders.length > 0
            ? c.orders.map((o) => o.orderNumber).join(", ")
            : c.ordersCount
            ? `${c.ordersCount} orders`
            : "-",
        name: c.name,
        email: c.email || "-",
        phone: c.phone || "-",
        totalSpent: periodSpend > 0 ? periodSpend : Number(c.totalRevenue || 0),
        invoicesCount: c.ordersCount || 0,
        status: c.status || "ACTIVE",
        group: c.group || "Standard"
      };
    });

    const mf = (typeof window !== "undefined" ? localStorage.getItem("afab_fiscal_matricule") || "" : "") || business?.taxId;
    const addr = (typeof window !== "undefined" ? localStorage.getItem("afab_business_address") || "" : "") || formatBusinessAddress(business);
    const logo = (typeof window !== "undefined" ? localStorage.getItem("afab_business_logo") || "" : "") || business?.logoUrl || "/assets/afab-logo-light.png";
    const purpose = (typeof window !== "undefined" ? localStorage.getItem("afab_business_purpose") || "" : "") || business?.description || business?.industry || "";

    return {
      businessName: business?.name || profile?.companyName || "AFAB Business",
      fiscalMatricule: mf,
      businessAddress: addr,
      businessLogoUrl: logo,
      businessPurpose: purpose,
      currency: currencyToUse,
      generatedAt: new Date().toLocaleString(isAr ? "ar-EG" : "en-US"),
      dateRange: range.label,
      transactions: txs.map((t) => ({
        id: t.id,
        date: t.transactionDate,
        description: t.description || "-",
        type: t.type,
        category: t.categoryName || "-",
        amount: Number(t.amount || 0),
        currency: t.currency || currencyToUse,
        paymentMethod: t.paymentMethod || "CARD",
        status: t.status || "COMPLETED",
        notes: t.notes
      })),
      customers: custs,
      invoices: invs.map((inv) => ({
        invoiceNumber: inv.invoiceNumber || inv.id,
        customerName: inv.customerName || "-",
        issueDate: inv.issueDate || "-",
        dueDate: inv.dueDate || "-",
        totalAmount: Number(inv.totalAmount || 0),
        currency: inv.currency || currencyToUse,
        status: inv.status
      })),
      summary: {
        totalRevenue: revenue,
        totalExpenses: expenses,
        netBalance: revenue - expenses,
        totalCustomersCount: custs.length,
        totalInvoicesCount: invs.length,
        totalTransactionsCount: txs.length
      }
    };
  };

  const getMasterData = (): MasterExportData => getExportDataForPeriod();

  // ── Pre-Download Confirmation Handler ──
  const handleConfirmModal = async (config: {
    period: string;
    customStart?: string;
    customEnd?: string;
    currency: string;
    includeLogo: boolean;
    includeSignature: boolean;
    fiscalMatricule?: string;
    businessAddress?: string;
    businessLogoUrl?: string;
    businessPurpose?: string;
  }) => {
    if (!modalAction) return;

    try {
      const data = getExportDataForPeriod(config.period, config.customStart, config.customEnd, config.currency);
      if (config.fiscalMatricule) {
        data.fiscalMatricule = config.fiscalMatricule;
      }
      if (config.businessAddress) {
        data.businessAddress = config.businessAddress;
      }
      if (config.businessLogoUrl) {
        data.businessLogoUrl = config.businessLogoUrl;
      }
      if (config.businessPurpose) {
        data.businessPurpose = config.businessPurpose;
      }

      if (modalAction === "master-excel") {
        setExportingMasterExcel(true);
        toast.info(isAr ? "جاري إنشاء ملف إكسل مع الشعار والبيانات المحددة..." : "Generating Excel archive with logo & period data...");
        exportMasterToExcel(data, `AFAB_Complete_Data_${business?.name || "Business"}`, config.includeLogo, config.includeSignature);
        toast.success(isAr ? "تم تحميل ملف إكسل بنجاح!" : "Excel archive exported successfully!");
      } else if (modalAction === "master-pdf") {
        setExportingMasterPdf(true);
        toast.info(isAr ? "جاري إنشاء تقرير PDF مع الشعار والبيانات المحددة..." : "Generating enterprise PDF with logo & period records...");
        await exportMasterToPdf(data, `AFAB_Financial_Report_${business?.name || "Business"}`, config.includeLogo, config.includeSignature);
        toast.success(isAr ? "تم تحميل تقرير PDF بنجاح!" : "Enterprise PDF report exported successfully!");
      } else if (modalAction === "print") {
        openPrintableReportWindow({
          title: isAr ? "الأرشيف المالي الشامل — AFAB" : "AFAB Enterprise — Financial & Data Archive",
          subtitle: isAr ? "سجل المعاملات والعملاء والفواتير المعتمد" : "Certified Financial Records & Business Registry",
          businessName: data.businessName,
          fiscalMatricule: data.fiscalMatricule,
          businessAddress: data.businessAddress,
          businessLogoUrl: data.businessLogoUrl,
          businessPurpose: data.businessPurpose,
          currency: data.currency,
          dateRange: data.dateRange,
          isAr,
          includeLogo: config.includeLogo,
          includeSignature: config.includeSignature,
          kpis: [
            { label: isAr ? "إيرادات الفترة" : "Period Revenue", value: `${formatCurrency(data.summary.totalRevenue, data.currency)}` },
            { label: isAr ? "مصروفات الفترة" : "Period Expenses", value: `${formatCurrency(data.summary.totalExpenses, data.currency)}` },
            { label: isAr ? "صافي التدفق" : "Net Cash Flow", value: `${formatCurrency(data.summary.netBalance, data.currency)}` },
            { label: isAr ? "العملاء المسجلين" : "Registered Clients", value: `${data.summary.totalCustomersCount}` }
          ],
          sections: [
            {
              title: isAr ? `1. سجل المعاملات المالية (${data.transactions.length} معاملة)` : `1. Transaction Ledger (${data.transactions.length} records)`,
              headers: [
                isAr ? "التاريخ" : "Date",
                isAr ? "الوصف" : "Description",
                isAr ? "النوع" : "Type",
                isAr ? "الفئة" : "Category",
                isAr ? "المبلغ" : "Amount",
                isAr ? "الحالة" : "Status"
              ],
              rows: data.transactions.slice(0, 50).map((t) => [
                t.date,
                t.description,
                t.type,
                t.category,
                `${t.amount.toFixed(2)} ${t.currency}`,
                t.status
              ])
            },
            {
              title: isAr ? `2. دليل العملاء والطلبات (${data.customers.length} عميل)` : `2. Customer & Client Directory (${data.customers.length} clients)`,
              headers: [
                isAr ? "رمز العميل" : "Customer Code",
                isAr ? "رقم الطلب / المرجع" : "Order / Ref #",
                isAr ? "الاسم" : "Name",
                isAr ? "البريد الإلكتروني" : "Email",
                isAr ? "إجمالي الإنفاق" : "Total Spent",
                isAr ? "الطلبات" : "Orders"
              ],
              rows: data.customers.slice(0, 50).map((c) => [
                c.id,
                c.orderNumber || "-",
                c.name,
                c.email,
                `${c.totalSpent.toFixed(2)} ${data.currency}`,
                c.invoicesCount
              ])
            },
            {
              title: isAr ? `3. الفواتير والفوترة (${data.invoices.length} فاتورة)` : `3. Invoices & Billing Register (${data.invoices.length} invoices)`,
              headers: [
                isAr ? "رقم الفاتورة" : "Invoice #",
                isAr ? "العميل" : "Customer",
                isAr ? "تاريخ الإصدار" : "Issue Date",
                isAr ? "تاريخ الاستحقاق" : "Due Date",
                isAr ? "المبلغ" : "Amount",
                isAr ? "الحالة" : "Status"
              ],
              rows: data.invoices.slice(0, 50).map((inv) => [
                inv.invoiceNumber,
                inv.customerName,
                inv.issueDate,
                inv.dueDate,
                `${inv.totalAmount.toFixed(2)} ${inv.currency}`,
                inv.status
              ])
            }
          ]
        });
      } else if (modalAction === "transactions-excel") {
        const headers = ["ID", "Date", "Description", "Type", "Category", "Amount", "Currency", "Payment Method", "Status", "Notes"];
        const rows = data.transactions.map((t) => [t.id, t.date, t.description, t.type, t.category, t.amount, t.currency, t.paymentMethod, t.status, t.notes]);
        exportDatasetToExcel("Transactions", headers, rows, "AFAB_Transactions", data.dateRange, {
          businessName: data.businessName,
          fiscalMatricule: data.fiscalMatricule,
          businessAddress: data.businessAddress
        });
        toast.success(isAr ? "تم تحميل معاملات إكسل بنجاح!" : "Transactions Excel downloaded!");
      } else if (modalAction === "transactions-pdf") {
        openPrintableReportWindow({
          title: isAr ? "سجل المعاملات — AFAB" : "AFAB — Transactions Ledger",
          businessName: data.businessName,
          fiscalMatricule: data.fiscalMatricule,
          businessAddress: data.businessAddress,
          businessLogoUrl: data.businessLogoUrl,
          businessPurpose: data.businessPurpose,
          currency: data.currency,
          dateRange: data.dateRange,
          isAr,
          includeLogo: config.includeLogo,
          includeSignature: config.includeSignature,
          sections: [{
            title: isAr ? `المعاملات المالية (${data.transactions.length})` : `Financial Transactions (${data.transactions.length})`,
            headers: ["Date", "Description", "Type", "Category", "Amount", "Status"],
            rows: data.transactions.map((t) => [t.date, t.description, t.type, t.category, `${t.amount} ${t.currency}`, t.status])
          }]
        });
      } else if (modalAction === "customers-excel") {
        const headers = ["Customer ID / Code", "Order / Ref #", "Name", "Email", "Phone", "Total Spent in Period", "Orders Count", "Status", "Group"];
        const rows = data.customers.map((c) => [c.id, c.orderNumber, c.name, c.email, c.phone, c.totalSpent, c.invoicesCount, c.status, c.group]);
        exportDatasetToExcel("Customers", headers, rows, "AFAB_Customers_Registry", data.dateRange, {
          businessName: data.businessName,
          fiscalMatricule: data.fiscalMatricule,
          businessAddress: data.businessAddress
        });
        toast.success(isAr ? "تم تحميل دليل العملاء بنجاح!" : "Customers directory Excel downloaded!");
      } else if (modalAction === "customers-pdf") {
        openPrintableReportWindow({
          title: isAr ? "سجل العملاء — AFAB" : "AFAB — Customer Directory",
          businessName: data.businessName,
          fiscalMatricule: data.fiscalMatricule,
          businessAddress: data.businessAddress,
          businessLogoUrl: data.businessLogoUrl,
          businessPurpose: data.businessPurpose,
          currency: data.currency,
          dateRange: data.dateRange,
          isAr,
          includeLogo: config.includeLogo,
          includeSignature: config.includeSignature,
          sections: [{
            title: isAr ? `قائمة العملاء (${data.customers.length})` : `Customer Directory (${data.customers.length})`,
            headers: ["Code", "Order / Ref #", "Name", "Email", "Total Spent", "Status"],
            rows: data.customers.map((c) => [c.id, c.orderNumber || "-", c.name, c.email, `${c.totalSpent} ${data.currency}`, c.status])
          }]
        });
      } else if (modalAction === "invoices-excel") {
        const headers = ["Invoice #", "Customer", "Issue Date", "Due Date", "Total", "Currency", "Status"];
        const rows = data.invoices.map((i) => [i.invoiceNumber, i.customerName, i.issueDate, i.dueDate, i.totalAmount, i.currency, i.status]);
        exportDatasetToExcel("Invoices", headers, rows, "AFAB_Invoices_Billing", data.dateRange, {
          businessName: data.businessName,
          fiscalMatricule: data.fiscalMatricule,
          businessAddress: data.businessAddress
        });
        toast.success(isAr ? "تم تحميل الفواتير بنجاح!" : "Invoices Excel downloaded!");
      } else if (modalAction === "invoices-pdf") {
        openPrintableReportWindow({
          title: isAr ? "سجل الفواتير — AFAB" : "AFAB — Invoices Registry",
          businessName: data.businessName,
          fiscalMatricule: data.fiscalMatricule,
          businessAddress: data.businessAddress,
          businessLogoUrl: data.businessLogoUrl,
          businessPurpose: data.businessPurpose,
          currency: data.currency,
          dateRange: data.dateRange,
          isAr,
          includeLogo: config.includeLogo,
          includeSignature: config.includeSignature,
          sections: [{
            title: isAr ? `الفواتير المسجلة (${data.invoices.length})` : `Invoices Register (${data.invoices.length})`,
            headers: ["Invoice #", "Customer", "Issue Date", "Due Date", "Amount", "Status"],
            rows: data.invoices.map((i) => [i.invoiceNumber, i.customerName, i.issueDate, i.dueDate, `${i.totalAmount} ${i.currency}`, i.status])
          }]
        });
      } else if (modalAction === "reports-excel") {
        const periodParam = config.period === "all" ? "this_year" : config.period;
        await ReportService.downloadCsv(periodParam, config.customStart, config.customEnd);
        toast.success(isAr ? "تم تحميل التقرير بنجاح!" : "Financial report downloaded!");
      } else if (modalAction === "reports-pdf") {
        const periodParam = config.period === "all" ? "this_year" : config.period;
        await ReportService.downloadPdf(periodParam, config.customStart, config.customEnd);
        toast.success(isAr ? "تم تحميل تقرير PDF بنجاح!" : "Financial statement PDF downloaded!");
      }
    } catch (err) {
      console.error("Export execution error:", err);
      toast.error(isAr ? "فشل إنشاء الملف" : "Failed to generate export file");
    } finally {
      setExportingMasterExcel(false);
      setExportingMasterPdf(false);
      setExportingModule(null);
    }
  };

  return (
    <div className="space-y-8 pb-12">
      {/* ── Top Header with Brand Logo Badge ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2">
        <div className="flex items-center gap-3.5">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#070a14] shadow-sm p-1.5">
            <img 
              src="/assets/afab-logo-light.png" 
              alt="AFAB Logo" 
              className="h-full w-full object-contain dark:hidden"
            />
            <img 
              src="/assets/afab-logo-dark.png" 
              alt="AFAB Logo Dark" 
              className="h-full w-full object-contain hidden dark:block"
            />
          </div>
          <div>
            <h1 className="text-xl sm:text-2xl font-extrabold text-gray-900 dark:text-white">
              {t("dataExport.title")}
            </h1>
            <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 mt-0.5">
              {t("dataExport.description")}
            </p>
          </div>
        </div>

        <Button
          variant="outline"
          size="sm"
          onClick={fetchAllData}
          disabled={loadingData}
          className="self-start sm:self-auto rounded-xl border-gray-200 dark:border-gray-800 text-xs text-gray-600 dark:text-gray-300 gap-1.5 h-9"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loadingData ? "animate-spin" : ""}`} />
          <span>{t("dataExport.refresh")}</span>
        </Button>
      </div>

      {/* ── PERIOD FILTER & CONTROLS BAR ── */}
      <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-4 sm:p-5 shadow-xs space-y-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-2 text-sm font-bold text-gray-900 dark:text-white">
            <Filter className="w-4 h-4 text-[var(--primary)]" />
            <span>{t("dataExport.periodFilter")}</span>
            <span className="rounded-full bg-purple-500/10 px-2.5 py-0.5 text-[11px] font-semibold text-[var(--primary)]">
              {activeDateRange.label}
            </span>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Period Preset Dropdown */}
            <div className="relative min-w-[160px]">
              <select
                id="period-select-filter"
                value={selectedPeriod}
                onChange={(e) => setSelectedPeriod(e.target.value)}
                className="w-full appearance-none rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.03] px-3.5 py-2 text-xs font-medium text-gray-800 dark:text-gray-200 hover:border-gray-300 dark:hover:border-gray-700 focus:outline-hidden focus:ring-2 focus:ring-[var(--primary)] cursor-pointer"
              >
                {PERIOD_PRESETS.map((p) => (
                  <option key={p.id} value={p.id} className="dark:bg-[#0c101c]">
                    {isAr ? p.labelAr : p.labelEn}
                  </option>
                ))}
              </select>
            </div>

            {/* Currency Selector */}
            <div className="relative min-w-[110px]">
              <select
                id="currency-select-filter"
                value={selectedCurrency}
                onChange={(e) => setSelectedCurrency(e.target.value)}
                className="w-full appearance-none rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.03] px-3 py-2 text-xs font-medium text-gray-800 dark:text-gray-200 hover:border-gray-300 dark:hover:border-gray-700 focus:outline-hidden focus:ring-2 focus:ring-[var(--primary)] cursor-pointer"
              >
                {["USD", "EUR", "SAR", "AED", "TND", "GBP", "CAD", "KWD"].map((curr) => (
                  <option key={curr} value={curr} className="dark:bg-[#0c101c]">
                    {curr}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Custom Date Range Pickers (shown only when custom is selected) */}
        {selectedPeriod === "custom" && (
          <div className="pt-3 border-t border-gray-100 dark:border-gray-800/60 flex flex-col sm:flex-row items-center gap-3">
            <div className="w-full sm:w-auto flex-1 flex items-center gap-2">
              <label htmlFor="custom-start-date" className="text-xs text-gray-500 whitespace-nowrap">
                {t("dataExport.startDate")}:
              </label>
              <Input
                id="custom-start-date"
                type="date"
                value={customStartDate}
                onChange={(e) => setCustomStartDate(e.target.value)}
                className="h-9 text-xs rounded-xl"
              />
            </div>
            <div className="w-full sm:w-auto flex-1 flex items-center gap-2">
              <label htmlFor="custom-end-date" className="text-xs text-gray-500 whitespace-nowrap">
                {t("dataExport.endDate")}:
              </label>
              <Input
                id="custom-end-date"
                type="date"
                value={customEndDate}
                onChange={(e) => setCustomEndDate(e.target.value)}
                className="h-9 text-xs rounded-xl"
              />
            </div>
          </div>
        )}
      </div>

      {/* ── Live Data Counters for the Selected Period ── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-4 shadow-xs">
          <div className="flex items-center justify-between text-xs font-medium text-gray-500 dark:text-gray-400">
            <span>{isAr ? "معاملات الفترة" : "Period Transactions"}</span>
            <Receipt className="w-4 h-4 text-[var(--primary)]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
            {loadingData ? <Loader2 className="w-5 h-5 animate-spin text-gray-400" /> : filteredTransactions.length}
          </div>
          <div className="mt-1 text-[11px] text-gray-400 truncate">
            {activeDateRange.label}
          </div>
        </div>

        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-4 shadow-xs">
          <div className="flex items-center justify-between text-xs font-medium text-gray-500 dark:text-gray-400">
            <span>{isAr ? "دليل العملاء" : "Clients Directory"}</span>
            <Users className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
            {loadingData ? <Loader2 className="w-5 h-5 animate-spin text-gray-400" /> : filteredCustomers.length}
          </div>
          <div className="mt-1 text-[11px] text-gray-400">
            {isAr ? "معرفات وطلبات" : "IDs & order records"}
          </div>
        </div>

        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-4 shadow-xs">
          <div className="flex items-center justify-between text-xs font-medium text-gray-500 dark:text-gray-400">
            <span>{isAr ? "فواتير الفترة" : "Period Invoices"}</span>
            <FileText className="w-4 h-4 text-sky-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
            {loadingData ? <Loader2 className="w-5 h-5 animate-spin text-gray-400" /> : filteredInvoices.length}
          </div>
          <div className="mt-1 text-[11px] text-gray-400 truncate">
            {activeDateRange.label}
          </div>
        </div>

        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-4 shadow-xs">
          <div className="flex items-center justify-between text-xs font-medium text-gray-500 dark:text-gray-400">
            <span>{isAr ? "صافي التدفق للفترة" : "Net Flow (Period)"}</span>
            <Coins className="w-4 h-4 text-amber-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-gray-900 dark:text-white truncate">
            {loadingData ? (
              <Loader2 className="w-5 h-5 animate-spin text-gray-400" />
            ) : (
              formatCurrency(filteredSummary.netBalance, selectedCurrency)
            )}
          </div>
          <div className="mt-1 text-[11px] text-gray-400 truncate">
            {activeDateRange.label}
          </div>
        </div>
      </div>

      {/* ── MASTER COMPLETE ARCHIVE CARD ── */}
      <div className="relative overflow-hidden rounded-3xl border border-purple-200 dark:border-purple-900/40 bg-gradient-to-br from-purple-50/80 via-white to-indigo-50/50 dark:from-[#131127] dark:via-[#0c101c] dark:to-[#171333] p-6 sm:p-8 shadow-sm">
        <div className="absolute top-0 end-0 -mt-8 -me-8 w-48 h-48 bg-purple-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="relative z-10 flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          <div className="space-y-2 max-w-xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-100 dark:bg-purple-950/60 border border-purple-200 dark:border-purple-800/50 text-xs font-semibold text-purple-700 dark:text-purple-300">
              <Database className="w-3.5 h-3.5" />
              <span>{t("dataExport.completeArchive")}</span>
              <span className="text-[10px] opacity-75">({activeDateRange.label})</span>
            </div>
            <h2 className="text-xl sm:text-2xl font-extrabold text-gray-900 dark:text-white">
              {t("dataExport.completeArchiveTitle")}
            </h2>
            <p className="text-sm text-gray-600 dark:text-gray-300 leading-relaxed">
              {t("dataExport.completeArchiveDesc")}
            </p>
          </div>

          <div className="flex flex-col sm:flex-row gap-3 shrink-0">
            {/* Download Complete Excel */}
            <Button
              onClick={() => openExportModal("master-excel")}
              disabled={loadingData || exportingMasterExcel}
              size="lg"
              className="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold shadow-md shadow-emerald-500/20 rounded-xl flex items-center justify-center gap-2.5 h-12 px-6"
            >
              {exportingMasterExcel ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <FileSpreadsheet className="w-5 h-5" />
              )}
              <span>{t("dataExport.downloadAllExcel")}</span>
            </Button>

            {/* Download Complete PDF */}
            <Button
              onClick={() => openExportModal("master-pdf")}
              disabled={loadingData || exportingMasterPdf}
              size="lg"
              className="bg-[var(--primary)] hover:bg-[var(--primary-hover,#7c3aed)] text-white font-semibold shadow-md shadow-purple-500/25 rounded-xl flex items-center justify-center gap-2.5 h-12 px-6"
            >
              {exportingMasterPdf ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <FileText className="w-5 h-5" />
              )}
              <span>{t("dataExport.downloadAllPdf")}</span>
            </Button>

            {/* Print / Save Preview */}
            <Button
              onClick={() => openExportModal("print")}
              disabled={loadingData}
              variant="outline"
              size="lg"
              className="border-gray-200 dark:border-gray-800 bg-white/80 dark:bg-gray-900/60 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-200 rounded-xl flex items-center justify-center gap-2 h-12 px-4"
              title={t("dataExport.printView")}
            >
              <Printer className="w-4 h-4 text-gray-500" />
              <span className="hidden sm:inline">{t("dataExport.printView")}</span>
            </Button>
          </div>
        </div>
      </div>

      {/* ── MODULAR DATASETS (2x2 GRID) ── */}
      <div>
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h3 className="text-base font-bold text-gray-900 dark:text-white">
              {t("dataExport.modularExports")}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {t("dataExport.modularExportsDesc")} — <span className="font-semibold text-[var(--primary)]">{activeDateRange.label}</span>
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {/* 1. Transactions */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-xs flex flex-col justify-between hover:border-[var(--primary)]/40 transition-colors">
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-500/10 text-[var(--primary)]">
                    <Receipt className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900 dark:text-white text-sm">
                      {t("dataExport.transactions")}
                    </h4>
                    <span className="text-xs text-gray-400">
                      {filteredTransactions.length} {t("dataExport.transactionsRecords")}
                    </span>
                  </div>
                </div>
              </div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-5 leading-relaxed">
                {t("dataExport.transactionsDesc")}
              </p>
            </div>

            <div className="flex items-center gap-2 pt-3 border-t border-gray-100 dark:border-gray-800/60">
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("transactions-excel")}
                disabled={exportingModule === "transactions-excel"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-emerald-50 dark:hover:bg-emerald-950/20 hover:text-emerald-600 text-xs gap-1.5 h-9"
              >
                {exportingModule === "transactions-excel" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileSpreadsheet className="w-3.5 h-3.5 text-emerald-600" />
                )}
                <span>Excel (.xlsx)</span>
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("transactions-pdf")}
                disabled={exportingModule === "transactions-pdf"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-purple-50 dark:hover:bg-purple-950/20 hover:text-[var(--primary)] text-xs gap-1.5 h-9"
              >
                {exportingModule === "transactions-pdf" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileText className="w-3.5 h-3.5 text-[var(--primary)]" />
                )}
                <span>PDF (.pdf)</span>
              </Button>
            </div>
          </div>

          {/* 2. Customers Registry */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-xs flex flex-col justify-between hover:border-emerald-500/40 transition-colors">
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                    <Users className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900 dark:text-white text-sm">
                      {t("dataExport.customers")}
                    </h4>
                    <span className="text-xs text-gray-400">
                      {filteredCustomers.length} {t("dataExport.customersRecords")}
                    </span>
                  </div>
                </div>
              </div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-5 leading-relaxed">
                {t("dataExport.customersDesc")}
              </p>
            </div>

            <div className="flex items-center gap-2 pt-3 border-t border-gray-100 dark:border-gray-800/60">
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("customers-excel")}
                disabled={exportingModule === "customers-excel"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-emerald-50 dark:hover:bg-emerald-950/20 hover:text-emerald-600 text-xs gap-1.5 h-9"
              >
                {exportingModule === "customers-excel" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileSpreadsheet className="w-3.5 h-3.5 text-emerald-600" />
                )}
                <span>Excel (.xlsx)</span>
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("customers-pdf")}
                disabled={exportingModule === "customers-pdf"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-purple-50 dark:hover:bg-purple-950/20 hover:text-[var(--primary)] text-xs gap-1.5 h-9"
              >
                {exportingModule === "customers-pdf" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileText className="w-3.5 h-3.5 text-[var(--primary)]" />
                )}
                <span>PDF (.pdf)</span>
              </Button>
            </div>
          </div>

          {/* 3. Invoices & Billing */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-xs flex flex-col justify-between hover:border-sky-500/40 transition-colors">
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-sky-500/10 text-sky-600 dark:text-sky-400">
                    <FileText className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900 dark:text-white text-sm">
                      {t("dataExport.invoices")}
                    </h4>
                    <span className="text-xs text-gray-400">
                      {filteredInvoices.length} {t("dataExport.invoicesRecords")}
                    </span>
                  </div>
                </div>
              </div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-5 leading-relaxed">
                {t("dataExport.invoicesDesc")}
              </p>
            </div>

            <div className="flex items-center gap-2 pt-3 border-t border-gray-100 dark:border-gray-800/60">
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("invoices-excel")}
                disabled={exportingModule === "invoices-excel"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-emerald-50 dark:hover:bg-emerald-950/20 hover:text-emerald-600 text-xs gap-1.5 h-9"
              >
                {exportingModule === "invoices-excel" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileSpreadsheet className="w-3.5 h-3.5 text-emerald-600" />
                )}
                <span>Excel (.xlsx)</span>
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("invoices-pdf")}
                disabled={exportingModule === "invoices-pdf"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-purple-50 dark:hover:bg-purple-950/20 hover:text-[var(--primary)] text-xs gap-1.5 h-9"
              >
                {exportingModule === "invoices-pdf" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileText className="w-3.5 h-3.5 text-[var(--primary)]" />
                )}
                <span>PDF (.pdf)</span>
              </Button>
            </div>
          </div>

          {/* 4. Financial Statements (P&L) */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-5 shadow-xs flex flex-col justify-between hover:border-amber-500/40 transition-colors">
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400">
                    <TrendingUp className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900 dark:text-white text-sm">
                      {t("dataExport.reports")}
                    </h4>
                    <span className="text-xs text-gray-400">
                      {activeDateRange.label}
                    </span>
                  </div>
                </div>
              </div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-5 leading-relaxed">
                {t("dataExport.reportsDesc")}
              </p>
            </div>

            <div className="flex items-center gap-2 pt-3 border-t border-gray-100 dark:border-gray-800/60">
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("reports-excel")}
                disabled={exportingModule === "reports-excel"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-emerald-50 dark:hover:bg-emerald-950/20 hover:text-emerald-600 text-xs gap-1.5 h-9"
              >
                {exportingModule === "reports-excel" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileSpreadsheet className="w-3.5 h-3.5 text-emerald-600" />
                )}
                <span>Excel / CSV</span>
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => openExportModal("reports-pdf")}
                disabled={exportingModule === "reports-pdf"}
                className="flex-1 border-gray-200 dark:border-gray-800 hover:bg-purple-50 dark:hover:bg-purple-950/20 hover:text-[var(--primary)] text-xs gap-1.5 h-9"
              >
                {exportingModule === "reports-pdf" ? (
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <FileText className="w-3.5 h-3.5 text-[var(--primary)]" />
                )}
                <span>Official PDF</span>
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* ── SECURITY & COMPLIANCE BADGE ── */}
      <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-gray-50/70 dark:bg-white/[0.02] p-5 flex items-start gap-4">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
          <ShieldCheck className="w-5 h-5" />
        </div>
        <div className="space-y-1">
          <h4 className="text-sm font-semibold text-gray-900 dark:text-white">
            {t("dataExport.securityTitle")}
          </h4>
          <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
            {t("dataExport.securityDesc")}
          </p>
        </div>
      </div>

      {/* ── Pre-Download Confirmation Dialog ── */}
      <ExportPeriodModal
        open={isModalOpen}
        onOpenChange={setIsModalOpen}
        actionType={modalAction}
        defaultPeriod={selectedPeriod}
        defaultCurrency={selectedCurrency}
        defaultFiscalMatricule={business?.taxId || (typeof window !== "undefined" ? localStorage.getItem("afab_fiscal_matricule") || "" : "")}
        defaultBusinessAddress={formatBusinessAddress(business) || (typeof window !== "undefined" ? localStorage.getItem("afab_business_address") || "" : "")}
        defaultBusinessLogo={business?.logoUrl || (typeof window !== "undefined" ? localStorage.getItem("afab_business_logo") || "" : "")}
        defaultBusinessPurpose={business?.description || business?.industry || (typeof window !== "undefined" ? localStorage.getItem("afab_business_purpose") || "" : "")}
        onConfirm={handleConfirmModal}
      />
    </div>
  );
}
