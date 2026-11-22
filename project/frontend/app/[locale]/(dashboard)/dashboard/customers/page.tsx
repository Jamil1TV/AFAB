"use client";

import { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { useTranslations, useLocale } from "next-intl";
import { 
  Users, 
  UserPlus, 
  Search, 
  Download, 
  ChevronLeft, 
  ChevronRight, 
  MoreVertical, 
  Plus, 
  Eye, 
  Pencil, 
  Trash2, 
  X, 
  Phone, 
  Mail, 
  MapPin, 
  Calendar, 
  CreditCard, 
  FileText,
  Copy,
  Wallet,
  TrendingUp,
  Repeat,
  Receipt
} from "lucide-react";
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip } from "recharts";
import { toast } from "sonner";

import { AfabLoader } from "@/components/ui/afab-loader";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { KpiCard } from "@/components/dashboard/KpiCard";
import { EmptyState } from "@/components/dashboard/EmptyState";
import { CHART_PALETTE, chartSemantic, chartTooltipStyle } from "@/lib/design-tokens";
import { 
  CustomerService, 
  Customer, 
  CustomerOrder,
  CustomerSummaryDTO, 
  CustomerGroup, 
  CustomerStatus, 
  OrderStatus,
  CreateCustomerRequest 
} from "@/lib/api/customers";
import { UserService } from "@/lib/api/dashboard";
import { formatCurrency } from "@/lib/currency";

export default function CustomersPage() {
  const t = useTranslations("Customers");
  const tKpi = useTranslations("Customers.kpi");
  const tTable = useTranslations("Customers.table");
  const tGroups = useTranslations("Customers.groups");
  const tStatuses = useTranslations("Customers.statuses");
  const tOrderStatuses = useTranslations("Customers.orderStatuses");
  const tPaymentMethods = useTranslations("Customers.paymentMethods");
  const tWidgets = useTranslations("Customers.widgets");
  const tModal = useTranslations("Customers.modal");
  const tOrderModal = useTranslations("Customers.orderModal");
  const tDrawer = useTranslations("Customers.drawer");
  const tDelete = useTranslations("Customers.deleteConfirm");
  const tToasts = useTranslations("Customers.toasts");
  const locale = useLocale();
  const isRtl = locale === "ar";

  // State
  const [loading, setLoading] = useState(true);
  const [summary, setSummary] = useState<CustomerSummaryDTO | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [totalElements, setTotalElements] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [userProfile, setUserProfile] = useState<{ currency?: string } | null>(null);

  // Filters & Pagination
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [groupFilter, setGroupFilter] = useState("ALL");
  const [period, setPeriod] = useState<"week" | "month" | "quarter" | "year">("week");
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  // Modals & Drawers
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [customerToEdit, setCustomerToEdit] = useState<Customer | null>(null);
  const [customerToDelete, setCustomerToDelete] = useState<Customer | null>(null);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [activeRowMenuId, setActiveRowMenuId] = useState<string | null>(null);

  // Order Modal State
  const [isAddOrderModalOpen, setIsAddOrderModalOpen] = useState(false);
  const [orderTargetCustomer, setOrderTargetCustomer] = useState<Customer | null>(null);
  const [orderFormData, setOrderFormData] = useState<{
    orderNumber: string;
    amount: string;
    status: OrderStatus;
    orderDate: string;
    description: string;
    paymentMethod: string;
    invoiceNumber: string;
  }>({
    orderNumber: "",
    amount: "",
    status: "COMPLETED",
    orderDate: new Date().toISOString().split("T")[0],
    description: "",
    paymentMethod: "BANK_TRANSFER",
    invoiceNumber: "",
  });
  const [orderSubmitting, setOrderSubmitting] = useState(false);

  // Form State for Customer
  const [formData, setFormData] = useState<CreateCustomerRequest>({
    customerCode: "",
    name: "",
    email: "",
    phone: "",
    group: "Standard",
    status: "Active",
    address: "",
    notes: "",
  });
  const [formSubmitting, setFormSubmitting] = useState(false);

  const searchInputRef = useRef<HTMLInputElement>(null);

  // Keyboard shortcut listener (⌘K)
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

  // Fetch initial profile
  useEffect(() => {
    UserService.getProfile()
      .then(setUserProfile)
      .catch((err) => console.error("Failed to load user profile:", err));
  }, []);

  const currency = userProfile?.currency || "USD";

  // Data loader
  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [sumRes, pageRes] = await Promise.all([
        CustomerService.getSummary(period, currency),
        CustomerService.getCustomers({
          search,
          status: statusFilter,
          group: groupFilter,
          page,
          size: pageSize,
        }),
      ]);

      setSummary(sumRes);
      setCustomers(pageRes.content);
      setTotalElements(pageRes.totalElements);
      setTotalPages(pageRes.totalPages);
    } catch (err) {
      console.error("Failed to load customers data:", err);
      toast.error(tToasts("error"));
    } finally {
      setLoading(false);
    }
  }, [period, currency, search, statusFilter, groupFilter, page, pageSize, tToasts]);

  useEffect(() => {
    let ignore = false;
    async function execute() {
      try {
        const [sumRes, pageRes] = await Promise.all([
          CustomerService.getSummary(period, currency),
          CustomerService.getCustomers({
            search,
            status: statusFilter,
            group: groupFilter,
            page,
            size: pageSize,
          }),
        ]);
        if (!ignore) {
          setSummary(sumRes);
          setCustomers(pageRes.content);
          setTotalElements(pageRes.totalElements);
          setTotalPages(pageRes.totalPages);
          setLoading(false);
        }
      } catch (err) {
        if (!ignore) {
          console.error("Failed to load customers data:", err);
          toast.error(tToasts("error"));
          setLoading(false);
        }
      }
    }
    execute();
    return () => {
      ignore = true;
    };
  }, [period, currency, search, statusFilter, groupFilter, page, pageSize, tToasts]);

  // Click outside listener for row menus
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && !target.closest("[data-row-menu]")) {
        setActiveRowMenuId(null);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // Form submit (Create or Update Customer)
  const handleSaveCustomer = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      toast.error(tModal("requiredName"));
      return;
    }
    if (!formData.email.trim() || !formData.email.includes("@")) {
      toast.error(tModal("requiredEmail"));
      return;
    }

    setFormSubmitting(true);
    try {
      if (customerToEdit) {
        await CustomerService.updateCustomer(customerToEdit.id, formData);
        toast.success(tToasts("updated"));
      } else {
        await CustomerService.createCustomer(formData);
        toast.success(tToasts("created"));
      }
      setIsAddModalOpen(false);
      setCustomerToEdit(null);
      resetForm();
      loadData();
    } catch (err) {
      console.error("Save customer failed:", err);
      toast.error(tToasts("error"));
    } finally {
      setFormSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      customerCode: "",
      name: "",
      email: "",
      phone: "",
      group: "Standard",
      status: "Active",
      address: "",
      notes: "",
    });
  };

  const openAddModal = () => {
    setCustomerToEdit(null);
    const nextSeq = 1000 + customers.length + 1;
    setFormData({
      customerCode: `CST-${nextSeq}`,
      name: "",
      email: "",
      phone: "",
      group: "Standard",
      status: "Active",
      address: "",
      notes: "",
    });
    setIsAddModalOpen(true);
  };

  const openEditModal = (cust: Customer) => {
    setCustomerToEdit(cust);
    setFormData({
      customerCode: cust.customerCode || `CST-${cust.id.slice(-4).toUpperCase()}`,
      name: cust.name,
      email: cust.email,
      phone: cust.phone || "",
      group: cust.group,
      status: cust.status,
      address: cust.address || "",
      notes: cust.notes || "",
    });
    setIsAddModalOpen(true);
    setActiveRowMenuId(null);
  };

  // Order Management Actions
  const openAddOrderModal = (cust?: Customer) => {
    const target = cust || selectedCustomer || customers[0];
    if (!target) {
      toast.error(tTable("noCustomersYet"));
      return;
    }
    const year = new Date().getFullYear();
    const nextSeq = String((target.ordersCount || 0) + 1).padStart(3, "0");
    setOrderTargetCustomer(target);
    setOrderFormData({
      orderNumber: `ORD-${year}-${nextSeq}`,
      amount: "",
      status: "COMPLETED",
      orderDate: new Date().toISOString().split("T")[0],
      description: "",
      paymentMethod: "BANK_TRANSFER",
      invoiceNumber: `INV-${year}-${nextSeq}`,
    });
    setIsAddOrderModalOpen(true);
    setActiveRowMenuId(null);
  };

  const handleSaveOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!orderTargetCustomer) return;
    const numAmount = parseFloat(orderFormData.amount);
    if (isNaN(numAmount) || numAmount <= 0) {
      toast.error(tOrderModal("requiredAmount"));
      return;
    }
    if (!orderFormData.description.trim()) {
      toast.error(tOrderModal("requiredDesc"));
      return;
    }

    setOrderSubmitting(true);
    try {
      const createdOrder = await CustomerService.addOrder({
        customerId: orderTargetCustomer.id,
        orderNumber: orderFormData.orderNumber.trim(),
        amount: numAmount,
        status: orderFormData.status,
        orderDate: orderFormData.orderDate,
        description: orderFormData.description.trim(),
        paymentMethod: orderFormData.paymentMethod,
        invoiceNumber: orderFormData.invoiceNumber.trim() || undefined,
      });

      toast.success(tToasts("orderCreated", { orderNumber: createdOrder.orderNumber }));
      setIsAddOrderModalOpen(false);

      // Refresh customers list and active selected customer
      await loadData();
      if (selectedCustomer && selectedCustomer.id === orderTargetCustomer.id) {
        const refreshed = await CustomerService.getCustomerById(orderTargetCustomer.id);
        setSelectedCustomer(refreshed);
      }
    } catch (err) {
      console.error("Failed to add order:", err);
      toast.error(tToasts("error"));
    } finally {
      setOrderSubmitting(false);
    }
  };

  const handleDeleteConfirm = async () => {
    if (!customerToDelete) return;
    try {
      await CustomerService.deleteCustomer(customerToDelete.id);
      toast.success(tToasts("deleted"));
      if (selectedCustomer?.id === customerToDelete.id) {
        setSelectedCustomer(null);
      }
      setCustomerToDelete(null);
      loadData();
    } catch (err) {
      console.error("Delete customer failed:", err);
      toast.error(tToasts("error"));
    }
  };

  const handleExportCsv = () => {
    CustomerService.exportCsv(customers, `AFAB-Customers-${new Date().toISOString().split("T")[0]}.csv`);
    toast.success(tToasts("exported"));
  };

  // Checkbox Selection
  const toggleSelectAll = () => {
    if (selectedIds.length === customers.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(customers.map((c) => c.id));
    }
  };

  const toggleSelectOne = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  // Group & Status badge colors
  const getGroupBadge = (group: CustomerGroup) => {
    switch (group) {
      case "Premium":
        return "afab-badge afab-badge-primary";
      case "Business":
        return "afab-badge afab-badge-info";
      case "Enterprise":
        return "afab-badge afab-badge-success";
      case "Standard":
      default:
        return "afab-badge afab-badge-neutral";
    }
  };

  const getStatusBadge = (status: CustomerStatus) => {
    switch (status) {
      case "Active":
        return "afab-badge afab-badge-success";
      case "Inactive":
        return "afab-badge afab-badge-neutral";
      case "New":
        return "afab-badge afab-badge-primary";
      case "Lead":
        return "afab-badge afab-badge-warning";
      default:
        return "afab-badge afab-badge-neutral";
    }
  };

  // Sparkline Trends Data derived from actual customer records
  const sparklineData = useMemo(() => {
    const total = summary?.totalCustomers || 0;
    const newC = summary?.newCustomers || 0;
    const rev = summary?.totalRevenue || 0;
    const avg = summary?.avgRevenuePerCustomer || 0;
    const rep = summary?.repeatCustomersPct || 0;

    const revSeries = customers.length > 0
      ? [...customers].reverse().map((c) => c.totalRevenue || 0)
      : [0, 0, 0, 0, 0];

    return {
      total: total > 0 ? [0, Math.max(1, Math.floor(total * 0.5)), total] : [0, 0, 0, 0, 0],
      newCust: newC > 0 ? [0, Math.max(1, Math.floor(newC * 0.5)), newC] : [0, 0, 0, 0, 0],
      revenue: rev > 0 ? [0, ...revSeries] : [0, 0, 0, 0, 0],
      avgRev: avg > 0 ? [0, avg * 0.6, avg] : [0, 0, 0, 0, 0],
      repeat: rep > 0 ? [0, rep * 0.6, rep] : [0, 0, 0, 0, 0],
    };
  }, [summary, customers]);

  // Overview Donut Chart Data — aligned with AFAB reference palette (Emerald, Purple, Sky)
  const donutData = useMemo(() => {
    if (!summary || summary.totalCustomers === 0) {
      return [{ name: tWidgets("total"), value: 1, color: "#374151" }];
    }
    return [
      { name: tStatuses("active"), value: summary.overviewDonut.activeCount, color: chartSemantic.positive },
      { name: tStatuses("inactive"), value: summary.overviewDonut.inactiveCount, color: CHART_PALETTE[0] },
      { name: tStatuses("new"), value: summary.overviewDonut.newCount, color: CHART_PALETTE[1] },
    ];
  }, [summary, tStatuses, tWidgets]);

  return (
    <div className="afab-page animate-in fade-in duration-700">
      
      {/* ── Page Header ── */}
      <PageHeader
        title={t("title")}
        subtitle={t("subtitle")}
        actions={
          <>
            {/* Header Search Input with ⌘K badge */}
            <div className="relative w-full sm:w-64">
              <Search className="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                ref={searchInputRef}
                type="text"
                placeholder={t("searchPlaceholder")}
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(0);
                }}
                className="afab-input ps-9 pe-12 py-2 text-xs font-medium"
              />
              <kbd className="pointer-events-none absolute end-2.5 top-1/2 -translate-y-1/2 hidden sm:inline-flex items-center px-1.5 py-0.5 text-[10px] font-mono text-gray-400 bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md">
                ⌘K
              </kbd>
            </div>

            {/* Period Selector Tabs */}
            <div className="afab-segmented">
              {(["week", "month", "quarter", "year"] as const).map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setPeriod(p)}
                  className={`afab-segment capitalize ${
                    period === p ? "afab-segment-active" : ""
                  }`}
                >
                  {t(`period.${p}`)}
                </button>
              ))}
            </div>

            {/* Add Customer Button */}
            <button
              onClick={openAddModal}
              className="afab-btn-primary"
            >
              <Plus className="h-4 w-4" />
              <span>{t("addCustomer")}</span>
            </button>
          </>
        }
      />

      {/* ── 5 Top KPI Cards (identical KpiCard component as Dashboard, Expenses, Revenue, Invoices) ── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <KpiCard
          title={tKpi("totalCustomers")}
          value={(summary?.totalCustomers ?? 0).toString()}
          change={`${(summary?.totalCustomersChangePct ?? 0) > 0 ? "+" : ""}${summary?.totalCustomersChangePct ?? 0}%`}
          isPositive={(summary?.totalCustomersChangePct ?? 0) >= 0}
          icon={Users}
          data={sparklineData.total}
        />

        <KpiCard
          title={tKpi("newCustomers")}
          value={(summary?.newCustomers ?? 0).toString()}
          change={`${(summary?.newCustomersChangePct ?? 0) > 0 ? "+" : ""}${summary?.newCustomersChangePct ?? 0}%`}
          isPositive={(summary?.newCustomersChangePct ?? 0) >= 0}
          icon={UserPlus}
          data={sparklineData.newCust}
        />

        <KpiCard
          title={tKpi("totalRevenue")}
          value={formatCurrency(summary?.totalRevenue || 0, currency)}
          change={`${(summary?.totalRevenueChangePct ?? 0) > 0 ? "+" : ""}${summary?.totalRevenueChangePct ?? 0}%`}
          isPositive={(summary?.totalRevenueChangePct ?? 0) >= 0}
          icon={Wallet}
          data={sparklineData.revenue}
        />

        <KpiCard
          title={tKpi("avgRevenue")}
          value={formatCurrency(summary?.avgRevenuePerCustomer || 0, currency)}
          change={`${(summary?.avgRevenueChangePct ?? 0) > 0 ? "+" : ""}${summary?.avgRevenueChangePct ?? 0}%`}
          isPositive={(summary?.avgRevenueChangePct ?? 0) >= 0}
          icon={TrendingUp}
          data={sparklineData.avgRev}
        />

        <KpiCard
          title={tKpi("repeatCustomers")}
          value={`${summary?.repeatCustomersPct ?? 0}%`}
          change={`${(summary?.repeatCustomersChangePct ?? 0) > 0 ? "+" : ""}${summary?.repeatCustomersChangePct ?? 0}%`}
          isPositive={(summary?.repeatCustomersChangePct ?? 0) >= 0}
          icon={Repeat}
          data={sparklineData.repeat}
        />
      </div>

      {/* ── Main Layout: 2/3 Directory Table & 1/3 Analytics Widgets ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Left Column: Customer Directory Table (8 Cols) */}
        <div className="lg:col-span-8 afab-card overflow-hidden">
          
          {/* Table Controls (Search, Filters, CSV Export) */}
          <div className="p-5 border-b border-gray-100 dark:border-gray-800/60 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            
            {/* Table inline search */}
            <div className="relative flex-1 max-w-sm">
              <Search className="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder={tTable("search")}
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(0);
                }}
                className="afab-input ps-9 pe-3 py-2 text-xs font-medium"
              />
            </div>

            <div className="flex flex-wrap items-center gap-2">
              {/* Group Filter */}
              <select
                value={groupFilter}
                onChange={(e) => {
                  setGroupFilter(e.target.value);
                  setPage(0);
                }}
                className="afab-select"
              >
                <option value="ALL">{tGroups("all")}</option>
                <option value="Standard">{tGroups("standard")}</option>
                <option value="Business">{tGroups("business")}</option>
                <option value="Premium">{tGroups("premium")}</option>
                <option value="Enterprise">{tGroups("enterprise")}</option>
              </select>

              {/* Status Filter */}
              <select
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value);
                  setPage(0);
                }}
                className="afab-select"
              >
                <option value="ALL">{tStatuses("all")}</option>
                <option value="Active">{tStatuses("active")}</option>
                <option value="Inactive">{tStatuses("inactive")}</option>
                <option value="New">{tStatuses("new")}</option>
                <option value="Lead">{tStatuses("lead")}</option>
              </select>

              {/* Export CSV Button */}
              <button
                onClick={handleExportCsv}
                className="afab-btn-secondary"
              >
                <Download className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">{tTable("export")}</span>
              </button>
            </div>
          </div>

          {/* Active selection banner */}
          {selectedIds.length > 0 && (
            <div className="px-6 py-2.5 bg-purple-500/10 border-b border-purple-500/20 flex items-center justify-between text-xs text-[#7c3aed] dark:text-[#a78bfa] font-medium">
              <span>{tTable("selected", { count: selectedIds.length })}</span>
              <button
                onClick={() => setSelectedIds([])}
                className="hover:underline text-[11px]"
              >
                Clear selection
              </button>
            </div>
          )}

          {/* Customers Data Table */}
          <div className="overflow-x-auto">
            <table className="afab-table border-collapse">
              <thead className="afab-thead">
                <tr>
                  <th className="afab-th px-4 w-10 text-center">
                    <input
                      type="checkbox"
                      checked={customers.length > 0 && selectedIds.length === customers.length}
                      onChange={toggleSelectAll}
                      className="rounded border-gray-300 dark:border-gray-700 text-[#8b5cf6] focus:ring-[#8b5cf6]"
                    />
                  </th>
                  <th className="afab-th px-4">{tTable("customer")}</th>
                  <th className="afab-th px-4">{tTable("contact")}</th>
                  <th className="afab-th px-4">{tTable("group")}</th>
                  <th className="afab-th px-4">{tTable("totalRevenue")}</th>
                  <th className="afab-th px-4 text-center">{tTable("orders")}</th>
                  <th className="afab-th px-4 text-center">{tTable("status")}</th>
                  <th className="afab-th px-4">{tTable("lastActivity")}</th>
                  <th className="afab-th px-4 text-center w-12">{tTable("actions")}</th>
                </tr>
              </thead>
              <tbody className="afab-tbody">
                {loading && customers.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="py-12 text-center">
                      <AfabLoader text="Loading customer directory..." />
                    </td>
                  </tr>
                ) : customers.length === 0 ? (
                  <tr>
                    <td colSpan={9}>
                      <EmptyState
                        icon={Users}
                        title={search || statusFilter !== "ALL" || groupFilter !== "ALL" ? tTable("noResults") : "No customers yet."}
                        description={tTable("noCustomersYet")}
                        action={
                          <button
                            type="button"
                            onClick={openAddModal}
                            className="afab-btn-primary"
                          >
                            <Plus className="h-4 w-4" />
                            <span>{t("addCustomer")}</span>
                          </button>
                        }
                      />
                    </td>
                  </tr>
                ) : (
                  customers.map((cust) => {
                    const isSelected = selectedIds.includes(cust.id);
                    const initialLetter = cust.name.trim().charAt(0).toUpperCase();
                    const code = cust.customerCode || `CST-${cust.id.slice(-4).toUpperCase()}`;

                    return (
                      <tr
                        key={cust.id}
                        onClick={() => setSelectedCustomer(cust)}
                        className={`afab-tr group cursor-pointer ${
                          isSelected ? "bg-[#8b5cf6]/5 dark:bg-[#8b5cf6]/10" : ""
                        }`}
                      >
                        {/* Checkbox */}
                        <td
                          className="afab-td px-4 text-center"
                          onClick={(e) => e.stopPropagation()}
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleSelectOne(cust.id)}
                            className="rounded border-gray-300 dark:border-gray-700 text-[#8b5cf6] focus:ring-[#8b5cf6]"
                          />
                        </td>

                        {/* Customer Avatar, Name & Customer ID Badge */}
                        <td className="afab-td px-4">
                          <div className="flex items-center gap-3">
                            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#8b5cf6]/10 text-[#8b5cf6] font-bold text-xs">
                              {initialLetter}
                            </div>
                            <div className="min-w-0">
                              <div className="flex items-center gap-1.5 flex-wrap">
                                <span className="font-semibold text-gray-900 dark:text-white truncate group-hover:text-[#8b5cf6] transition-colors">
                                  {cust.name}
                                </span>
                                <span 
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    navigator.clipboard.writeText(code);
                                    toast.success(tDrawer("idCopied", { code }));
                                  }}
                                  title={tDrawer("copyId")}
                                  className="afab-badge afab-badge-primary font-mono hover:bg-purple-500/20 transition-colors"
                                >
                                  {code}
                                  <Copy className="h-2.5 w-2.5 opacity-60" />
                                </span>
                              </div>
                              <p className="text-[11px] text-gray-400 dark:text-gray-500 truncate mt-0.5">
                                {cust.email}
                              </p>
                            </div>
                          </div>
                        </td>

                        {/* Contact */}
                        <td className="afab-td px-4 text-gray-600 dark:text-gray-400 whitespace-nowrap">
                          {cust.phone || "—"}
                        </td>

                        {/* Group */}
                        <td className="afab-td px-4 whitespace-nowrap">
                          <span className={getGroupBadge(cust.group)}>
                            {tGroups(cust.group.toLowerCase()) || cust.group}
                          </span>
                        </td>

                        {/* Total Revenue */}
                        <td className="afab-td px-4 font-bold text-gray-900 dark:text-white whitespace-nowrap">
                          {formatCurrency(cust.totalRevenue, currency)}
                        </td>

                        {/* Orders count badge with quick Add Order on hover */}
                        <td className="afab-td px-4 text-center">
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedCustomer(cust);
                            }}
                            className="inline-flex items-center gap-1 font-semibold text-gray-700 dark:text-gray-300 hover:text-[#7c3aed] dark:hover:text-[#a78bfa] px-2 py-0.5 rounded-md hover:bg-purple-500/10 transition-colors"
                          >
                            <Receipt className="h-3 w-3 text-gray-400" />
                            <span>{cust.ordersCount}</span>
                          </button>
                        </td>

                        {/* Status */}
                        <td className="afab-td px-4 text-center whitespace-nowrap">
                          <span className={getStatusBadge(cust.status)}>
                            {tStatuses(cust.status.toLowerCase()) || cust.status}
                          </span>
                        </td>

                        {/* Last Activity */}
                        <td className="afab-td px-4 text-gray-500 dark:text-gray-400 whitespace-nowrap">
                          {cust.lastActivityDate}
                        </td>

                        {/* Actions Menu */}
                        <td
                          className="afab-td px-4 text-center relative"
                          onClick={(e) => e.stopPropagation()}
                          data-row-menu
                        >
                          <button
                            onClick={() => setActiveRowMenuId(activeRowMenuId === cust.id ? null : cust.id)}
                            className="afab-icon-btn"
                          >
                            <MoreVertical className="h-4 w-4" />
                          </button>

                          {activeRowMenuId === cust.id && (
                            <div className="afab-popover absolute top-9 end-4 z-30 w-44 p-1.5 text-xs text-start animate-in fade-in zoom-in-95">
                              <button
                                onClick={() => {
                                  setSelectedCustomer(cust);
                                  setActiveRowMenuId(null);
                                }}
                                className="flex items-center gap-2 w-full rounded-xl px-3 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                              >
                                <Eye className="h-3.5 w-3.5" />
                                <span>{tTable("viewDetails")}</span>
                              </button>
                              <button
                                onClick={() => openAddOrderModal(cust)}
                                className="flex items-center gap-2 w-full rounded-xl px-3 py-2 text-[#7c3aed] dark:text-[#a78bfa] hover:bg-purple-50 dark:hover:bg-purple-500/10 transition-colors font-semibold"
                              >
                                <Receipt className="h-3.5 w-3.5" />
                                <span>{tTable("addOrder")}</span>
                              </button>
                              <button
                                onClick={() => openEditModal(cust)}
                                className="flex items-center gap-2 w-full rounded-xl px-3 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                              >
                                <Pencil className="h-3.5 w-3.5" />
                                <span>{tTable("edit")}</span>
                              </button>
                              <div className="my-1 border-t border-gray-100 dark:border-gray-800/60" />
                              <button
                                onClick={() => {
                                  setCustomerToDelete(cust);
                                  setActiveRowMenuId(null);
                                }}
                                className="flex items-center gap-2 w-full rounded-xl px-3 py-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
                              >
                                <Trash2 className="h-3.5 w-3.5" />
                                <span>{tTable("delete")}</span>
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Table Pagination Footer */}
          <div className="afab-pagination flex-col sm:flex-row gap-3 text-xs text-gray-500 dark:text-gray-400">
            <div>
              {tTable("showing", {
                from: totalElements > 0 ? page * pageSize + 1 : 0,
                to: Math.min((page + 1) * pageSize, totalElements),
                total: totalElements,
              })}
            </div>

            <div className="flex flex-wrap items-center gap-4">
              {/* Rows Per Page */}
              <div className="flex items-center gap-1.5">
                <span>{tTable("rowsPerPage")}</span>
                <select
                  value={pageSize}
                  onChange={(e) => {
                    setPageSize(Number(e.target.value));
                    setPage(0);
                  }}
                  className="afab-select py-1 px-2.5 text-xs"
                >
                  <option value={10}>10</option>
                  <option value={25}>25</option>
                  <option value={50}>50</option>
                </select>
              </div>

              {/* Page Buttons */}
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  disabled={page === 0}
                  className="afab-page-btn"
                >
                  <ChevronLeft className="h-3.5 w-3.5 rtl:rotate-180" />
                </button>
                <span className="px-3 py-1 font-semibold text-gray-900 dark:text-white bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 rounded-lg">
                  {page + 1} / {totalPages}
                </span>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                  disabled={page >= totalPages - 1}
                  className="afab-page-btn"
                >
                  <ChevronRight className="h-3.5 w-3.5 rtl:rotate-180" />
                </button>
              </div>
            </div>
          </div>

        </div>

        {/* Right Column: 3 Analytics & Insight Widgets (4 Cols) */}
        <div className="lg:col-span-4 space-y-6">
          
          {/* Widget 1: Customer Overview Donut Chart */}
          <div className="afab-card p-6">
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">
              {tWidgets("overviewTitle")}
            </h3>

            <div className="flex items-center gap-4 mt-4">
              {/* Donut with Total in Center */}
              <div className="relative w-36 h-36 shrink-0">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Tooltip
                      formatter={(val) => [`${val} customers`, ""]}
                      {...chartTooltipStyle}
                    />
                    <Pie
                      data={donutData}
                      dataKey="value"
                      cx="50%"
                      cy="50%"
                      innerRadius={45}
                      outerRadius={62}
                      paddingAngle={3}
                    >
                      {donutData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                
                {/* Center metric */}
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <span className="text-[10px] uppercase font-semibold text-gray-400">
                    {tWidgets("total")}
                  </span>
                  <span className="text-base font-bold text-gray-900 dark:text-white">
                    {summary?.totalCustomers ?? 0}
                  </span>
                </div>
              </div>

              {/* Legend & Breakdown */}
              <div className="flex-1 space-y-2.5 text-xs">
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-2 font-medium text-gray-600 dark:text-gray-300">
                    <span className="h-2.5 w-2.5 rounded-full bg-emerald-500" />
                    <span>{tStatuses("active")}</span>
                  </span>
                  <span className="font-bold text-gray-900 dark:text-white">
                    {summary?.overviewDonut.activePct ?? 0}%
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-2 font-medium text-gray-600 dark:text-gray-300">
                    <span className="h-2.5 w-2.5 rounded-full bg-[#8b5cf6]" />
                    <span>{tStatuses("inactive")}</span>
                  </span>
                  <span className="font-bold text-gray-900 dark:text-white">
                    {summary?.overviewDonut.inactivePct ?? 0}%
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-2 font-medium text-gray-600 dark:text-gray-300">
                    <span className="h-2.5 w-2.5 rounded-full bg-[#0ea5e9]" />
                    <span>{tStatuses("new")}</span>
                  </span>
                  <span className="font-bold text-gray-900 dark:text-white">
                    {summary?.overviewDonut.newPct ?? 0}%
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Widget 2: Top Customers by Revenue */}
          <div className="afab-card p-6">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                {tWidgets("topCustomersTitle")}
              </h3>
              <button
                onClick={() => {
                  setGroupFilter("Premium");
                  setPage(0);
                }}
                className="text-xs font-semibold text-[#7c3aed] dark:text-[#a78bfa] hover:underline"
              >
                {tWidgets("viewAll")}
              </button>
            </div>

            <div className="mt-4 space-y-3">
              {(!summary?.topCustomers || summary.topCustomers.length === 0) ? (
                <p className="text-xs text-gray-400 py-3 text-center">No customer data yet</p>
              ) : (
                summary.topCustomers.map((top) => (
                  <div
                    key={top.id}
                    onClick={() => {
                      const fullCust = customers.find((c) => c.id === top.id);
                      if (fullCust) setSelectedCustomer(fullCust);
                    }}
                    className="flex items-center justify-between p-2 rounded-xl hover:bg-gray-50/80 dark:hover:bg-white/[0.02] transition-colors cursor-pointer"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#8b5cf6]/10 text-[#8b5cf6] font-bold text-xs">
                        {top.name.charAt(0).toUpperCase()}
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5">
                          <p className="text-xs font-semibold text-gray-900 dark:text-white truncate">
                            {top.name}
                          </p>
                          <span className="font-mono text-[9px] text-gray-400">
                            {top.customerCode}
                          </span>
                        </div>
                        <p className="text-[11px] text-gray-400 dark:text-gray-500 truncate">
                          {top.ordersCount} orders
                        </p>
                      </div>
                    </div>
                    <span className="text-xs font-bold text-gray-900 dark:text-white shrink-0">
                      {formatCurrency(top.revenue, currency)}
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Widget 3: Recent Activity Log */}
          <div className="afab-card p-6">
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">
              {tWidgets("activityTitle")}
            </h3>

            <div className="mt-4 space-y-3">
              {(!summary?.recentActivity || summary.recentActivity.length === 0) ? (
                <p className="text-xs text-gray-400 py-3 text-center">{tWidgets("noActivity")}</p>
              ) : (
                summary.recentActivity.map((act) => {
                  let iconColor = "bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa] border-[#8b5cf6]/20";
                  let IconComponent = UserPlus;
                  let actionText = tWidgets("newCustomerActivity");

                  if (act.type === "INVOICE_PAID") {
                    iconColor = "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20";
                    IconComponent = FileText;
                    actionText = tWidgets("invoicePaidActivity");
                  } else if (act.type === "PAYMENT_RECEIVED") {
                    iconColor = "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/20";
                    IconComponent = CreditCard;
                    actionText = tWidgets("paymentReceivedActivity");
                  } else if (act.type === "NEW_ORDER") {
                    iconColor = "bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa] border-[#8b5cf6]/20";
                    IconComponent = Receipt;
                    actionText = tWidgets("newOrderActivity");
                  }

                  return (
                    <div key={act.id} className="flex items-start gap-3 p-2 rounded-xl hover:bg-gray-50/80 dark:hover:bg-white/[0.02] transition-colors">
                      <div className={`h-8 w-8 rounded-lg flex items-center justify-center shrink-0 border ${iconColor} mt-0.5`}>
                        <IconComponent className="h-4 w-4" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-gray-900 dark:text-white truncate">
                          {actionText}
                        </p>
                        <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-0.5">
                          {act.customerName} {act.amount ? `• ${formatCurrency(act.amount, currency)}` : ""}
                        </p>
                      </div>
                      <span className="text-[10px] text-gray-400 whitespace-nowrap mt-0.5">
                        {new Date(act.timestamp).toLocaleDateString(locale === "ar" ? "ar-EG" : "en-US", {
                          month: "short",
                          day: "numeric",
                        })}
                      </span>
                    </div>
                  );
                })
              )}
            </div>
          </div>

        </div>

      </div>

      {/* ── Slide-Over Customer Details Drawer ── */}
      {selectedCustomer && (
        <div className="fixed inset-0 z-50 flex justify-end bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className={`w-full max-w-md bg-white dark:bg-[#0c101c] h-full shadow-2xl border-s border-gray-200 dark:border-gray-800/80 p-6 overflow-y-auto animate-in ${isRtl ? "slide-in-from-left" : "slide-in-from-right"} duration-200 flex flex-col justify-between`}>
            <div>
              {/* Header */}
              <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800/60">
                <div className="flex items-center gap-3">
                  <div className="h-12 w-12 rounded-2xl flex items-center justify-center font-bold text-sm bg-[#8b5cf6]/10 text-[#8b5cf6] border border-[#8b5cf6]/20">
                    {selectedCustomer.name.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <h2 className="text-base font-bold text-gray-900 dark:text-white">
                      {selectedCustomer.name}
                    </h2>
                    <div className="flex items-center gap-1.5 mt-1 flex-wrap">
                      <span className="afab-badge afab-badge-primary font-mono">
                        {selectedCustomer.customerCode || `CST-${selectedCustomer.id.slice(-4).toUpperCase()}`}
                      </span>
                      <button
                        type="button"
                        onClick={() => {
                          const code = selectedCustomer.customerCode || "";
                          navigator.clipboard.writeText(code);
                          toast.success(tDrawer("idCopied", { code }));
                        }}
                        title={tDrawer("copyId")}
                        className="afab-icon-btn p-1"
                      >
                        <Copy className="h-3 w-3" />
                      </button>
                      <span className={getStatusBadge(selectedCustomer.status)}>
                        {selectedCustomer.status}
                      </span>
                    </div>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedCustomer(null)}
                  className="afab-icon-btn"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              {/* Financial Stats Cards */}
              {(() => {
                const pendingBalance = (selectedCustomer.orders || [])
                  .filter((o) => o.status === "PENDING" || o.status === "PROCESSING")
                  .reduce((sum, o) => sum + (Number(o.amount) || 0), 0);
                return (
                  <div className="grid grid-cols-3 gap-2.5 my-5">
                    <div className="afab-inset p-3">
                      <span className="text-[10px] text-gray-400 font-medium block truncate">{tDrawer("totalSpent")}</span>
                      <div className="text-sm font-bold text-gray-900 dark:text-white mt-1 truncate">
                        {formatCurrency(selectedCustomer.totalRevenue, currency)}
                      </div>
                    </div>
                    <div className="afab-inset p-3">
                      <span className="text-[10px] text-gray-400 font-medium block truncate">Outstanding</span>
                      <div className={`text-sm font-bold mt-1 truncate ${pendingBalance > 0 ? "text-amber-600 dark:text-amber-400" : "text-gray-900 dark:text-white"}`}>
                        {formatCurrency(pendingBalance, currency)}
                      </div>
                    </div>
                    <div className="afab-inset p-3">
                      <span className="text-[10px] text-gray-400 font-medium block truncate">{tDrawer("completedOrders")}</span>
                      <div className="text-sm font-bold text-gray-900 dark:text-white mt-1 truncate">
                        {selectedCustomer.ordersCount}
                      </div>
                    </div>
                  </div>
                );
              })()}

              {/* Contact Information */}
              <div className="space-y-4">
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400">
                  {tDrawer("contactInfo")}
                </h4>
                
                <div className="space-y-2.5 text-xs">
                  <div className="flex items-center gap-3 text-gray-600 dark:text-gray-300">
                    <Mail className="h-4 w-4 text-gray-400 shrink-0" />
                    <span>{selectedCustomer.email}</span>
                  </div>
                  <div className="flex items-center gap-3 text-gray-600 dark:text-gray-300">
                    <Phone className="h-4 w-4 text-gray-400 shrink-0" />
                    <span>{selectedCustomer.phone || "No phone provided"}</span>
                  </div>
                  <div className="flex items-center gap-3 text-gray-600 dark:text-gray-300">
                    <MapPin className="h-4 w-4 text-gray-400 shrink-0" />
                    <span>{selectedCustomer.address || "No address on file"}</span>
                  </div>
                  <div className="flex items-center gap-3 text-gray-600 dark:text-gray-300">
                    <Calendar className="h-4 w-4 text-gray-400 shrink-0" />
                    <span>{tDrawer("registered")}: {selectedCustomer.createdAt}</span>
                  </div>
                </div>
              </div>

              {/* ── Order History & Details Section ── */}
              <div className="mt-6 pt-5 border-t border-gray-100 dark:border-gray-800/60">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <Receipt className="h-4 w-4 text-[#8b5cf6]" />
                    <h4 className="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                      {tDrawer("invoicesAndOrders")}
                    </h4>
                    <span className="afab-badge afab-badge-neutral">
                      {selectedCustomer.orders?.length || selectedCustomer.ordersCount || 0}
                    </span>
                  </div>
                  <button
                    onClick={() => openAddOrderModal(selectedCustomer)}
                    className="afab-btn-soft px-2.5 py-1 text-xs"
                  >
                    <Plus className="h-3 w-3" />
                    <span>{tDrawer("addOrderBtn")}</span>
                  </button>
                </div>

                {(!selectedCustomer.orders || selectedCustomer.orders.length === 0) ? (
                  <div className="afab-inset p-4 border-dashed text-center">
                    <Receipt className="h-6 w-6 mx-auto mb-1 text-gray-400 opacity-50" />
                    <p className="text-xs text-gray-500 dark:text-gray-400">{tDrawer("noOrders")}</p>
                    <button
                      onClick={() => openAddOrderModal(selectedCustomer)}
                      className="mt-2 text-xs font-semibold text-[#7c3aed] dark:text-[#a78bfa] hover:underline"
                    >
                      {tDrawer("addOrderBtn")}
                    </button>
                  </div>
                ) : (
                  <div className="space-y-2.5 max-h-72 overflow-y-auto pe-1 custom-scrollbar">
                    {selectedCustomer.orders.map((ord: CustomerOrder) => (
                      <div
                        key={ord.id}
                        className="afab-inset p-3.5 hover:border-[#8b5cf6]/40 transition-all text-xs"
                      >
                        <div className="flex items-center justify-between">
                          <span className="afab-badge afab-badge-neutral font-mono">
                            {ord.orderNumber}
                          </span>
                          <span className={`afab-badge ${
                            ord.status === "COMPLETED"
                              ? "afab-badge-success"
                              : ord.status === "PENDING"
                              ? "afab-badge-warning"
                              : ord.status === "PROCESSING"
                              ? "afab-badge-info"
                              : "afab-badge-danger"
                          }`}>
                            {tOrderStatuses(ord.status.toLowerCase()) || ord.status}
                          </span>
                        </div>

                        <div className="flex items-center justify-between mt-1.5 font-semibold">
                          <span className="text-gray-800 dark:text-gray-200 truncate pe-2">
                            {ord.description}
                          </span>
                          <span className="text-gray-900 dark:text-white shrink-0">
                            {formatCurrency(ord.amount, currency)}
                          </span>
                        </div>

                        <div className="flex items-center justify-between mt-2 pt-1.5 border-t border-gray-200/60 dark:border-gray-800/40 text-[10px] text-gray-400">
                          <div className="flex items-center gap-1.5">
                            <CreditCard className="h-3 w-3" />
                            <span>{tPaymentMethods(
                              ord.paymentMethod === "CREDIT_CARD" ? "creditCard" :
                              ord.paymentMethod === "CASH" ? "cash" :
                              ord.paymentMethod === "STRIPE" ? "stripe" : "bankTransfer"
                            )}</span>
                          </div>
                          {ord.invoiceNumber && (
                            <span className="font-mono text-gray-500">
                              {ord.invoiceNumber}
                            </span>
                          )}
                          <span>{ord.orderDate}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Internal Notes */}
              {selectedCustomer.notes && (
                <div className="mt-6">
                  <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">
                    {tDrawer("notes")}
                  </h4>
                  <div className="afab-inset p-3.5 text-xs text-gray-600 dark:text-gray-300">
                    {selectedCustomer.notes}
                  </div>
                </div>
              )}
            </div>

            {/* Bottom Actions */}
            <div className="pt-4 border-t border-gray-100 dark:border-gray-800/60 flex items-center justify-between gap-3 mt-4">
              <button
                onClick={() => {
                  const toDelete = selectedCustomer;
                  setSelectedCustomer(null);
                  setCustomerToDelete(toDelete);
                }}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
              >
                {tTable("delete")}
              </button>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => openAddOrderModal(selectedCustomer)}
                  className="afab-btn-soft"
                >
                  {tDrawer("addOrderBtn")}
                </button>
                <button
                  onClick={() => {
                    const toEdit = selectedCustomer;
                    setSelectedCustomer(null);
                    openEditModal(toEdit);
                  }}
                  className="afab-btn-primary"
                >
                  {tTable("edit")}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Add / Edit Customer Modal ── */}
      {isAddModalOpen && (
        <div className="afab-overlay animate-in fade-in duration-200">
          <div className="afab-modal max-w-lg animate-in zoom-in-95">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800/60">
              <div>
                <h3 className="text-xl font-bold tracking-tight text-gray-900 dark:text-white">
                  {customerToEdit ? tModal("editTitle") : tModal("addTitle")}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  {tModal("subtitle")}
                </p>
              </div>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="afab-icon-btn"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSaveCustomer} className="mt-6 space-y-4">
              
              {/* Customer ID & Name in 2 columns */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="sm:col-span-1">
                  <label className="afab-label">
                    {tModal("customerCode")}
                  </label>
                  <input
                    type="text"
                    placeholder={tModal("customerCodePlaceholder")}
                    value={formData.customerCode || ""}
                    onChange={(e) => setFormData({ ...formData, customerCode: e.target.value })}
                    className="afab-input font-mono text-xs"
                  />
                </div>
                <div className="sm:col-span-2">
                  <label className="afab-label">
                    {tModal("name")} *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder={tModal("namePlaceholder")}
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="afab-input text-xs"
                  />
                </div>
              </div>

              {/* Email & Phone Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="afab-label">
                    {tModal("email")} *
                  </label>
                  <input
                    type="email"
                    required
                    placeholder={tModal("emailPlaceholder")}
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="afab-input text-xs"
                  />
                </div>
                <div>
                  <label className="afab-label">
                    {tModal("phone")}
                  </label>
                  <input
                    type="tel"
                    placeholder={tModal("phonePlaceholder")}
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="afab-input text-xs"
                  />
                </div>
              </div>

              {/* Group & Status Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="afab-label">
                    {tModal("group")}
                  </label>
                  <select
                    value={formData.group}
                    onChange={(e) => setFormData({ ...formData, group: e.target.value as CustomerGroup })}
                    className="afab-select w-full py-2 text-xs"
                  >
                    <option value="Standard">{tGroups("standard")}</option>
                    <option value="Business">{tGroups("business")}</option>
                    <option value="Premium">{tGroups("premium")}</option>
                    <option value="Enterprise">{tGroups("enterprise")}</option>
                  </select>
                </div>
                <div>
                  <label className="afab-label">
                    {tModal("status")}
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value as CustomerStatus })}
                    className="afab-select w-full py-2 text-xs"
                  >
                    <option value="Active">{tStatuses("active")}</option>
                    <option value="Inactive">{tStatuses("inactive")}</option>
                    <option value="New">{tStatuses("new")}</option>
                    <option value="Lead">{tStatuses("lead")}</option>
                  </select>
                </div>
              </div>

              {/* Address */}
              <div>
                <label className="afab-label">
                  {tModal("address")}
                </label>
                <input
                  type="text"
                  placeholder={tModal("addressPlaceholder")}
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="afab-input text-xs"
                />
              </div>

              {/* Internal Notes */}
              <div>
                <label className="afab-label">
                  {tModal("notes")}
                </label>
                <textarea
                  rows={2}
                  placeholder={tModal("notesPlaceholder")}
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  className="afab-input text-xs resize-none"
                />
              </div>

              {/* Modal Actions */}
              <div className="pt-4 border-t border-gray-100 dark:border-gray-800/60 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="afab-btn-secondary"
                >
                  {tModal("cancel")}
                </button>
                <button
                  type="submit"
                  disabled={formSubmitting}
                  className="afab-btn-primary"
                >
                  {formSubmitting
                    ? "Saving..."
                    : customerToEdit
                    ? tModal("update")
                    : tModal("save")}
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

      {/* ── Add Order Modal ── */}
      {isAddOrderModalOpen && orderTargetCustomer && (
        <div className="afab-overlay animate-in fade-in duration-200">
          <div className="afab-modal max-w-lg animate-in zoom-in-95">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800/60">
              <div>
                <h3 className="text-xl font-bold tracking-tight text-gray-900 dark:text-white flex items-center gap-2">
                  <Receipt className="h-5 w-5 text-[#8b5cf6]" />
                  <span>{tOrderModal("title")}</span>
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  {orderTargetCustomer.name} • <span className="font-mono text-[#7c3aed] dark:text-[#a78bfa]">{orderTargetCustomer.customerCode}</span>
                </p>
              </div>
              <button
                onClick={() => setIsAddOrderModalOpen(false)}
                className="afab-icon-btn"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSaveOrder} className="mt-6 space-y-4">
              {/* Order Number & Date */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="afab-label">
                    {tOrderModal("orderNumber")} *
                  </label>
                  <input
                    type="text"
                    required
                    value={orderFormData.orderNumber}
                    onChange={(e) => setOrderFormData({ ...orderFormData, orderNumber: e.target.value })}
                    className="afab-input font-mono text-xs"
                  />
                </div>
                <div>
                  <label className="afab-label">
                    {tOrderModal("orderDate")} *
                  </label>
                  <input
                    type="date"
                    required
                    value={orderFormData.orderDate}
                    onChange={(e) => setOrderFormData({ ...orderFormData, orderDate: e.target.value })}
                    className="afab-input text-xs"
                  />
                </div>
              </div>

              {/* Amount & Status */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="afab-label">
                    {tOrderModal("amount")} ({currency}) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    required
                    placeholder="0.00"
                    value={orderFormData.amount}
                    onChange={(e) => setOrderFormData({ ...orderFormData, amount: e.target.value })}
                    className="afab-input text-xs"
                  />
                </div>
                <div>
                  <label className="afab-label">
                    {tOrderModal("status")}
                  </label>
                  <select
                    value={orderFormData.status}
                    onChange={(e) => setOrderFormData({ ...orderFormData, status: e.target.value as OrderStatus })}
                    className="afab-select w-full py-2 text-xs"
                  >
                    <option value="COMPLETED">{tOrderStatuses("completed")}</option>
                    <option value="PENDING">{tOrderStatuses("pending")}</option>
                    <option value="PROCESSING">{tOrderStatuses("processing")}</option>
                    <option value="CANCELLED">{tOrderStatuses("cancelled")}</option>
                  </select>
                </div>
              </div>

              {/* Description */}
              <div>
                <label className="afab-label">
                  {tOrderModal("description")} *
                </label>
                <input
                  type="text"
                  required
                  placeholder={tOrderModal("descriptionPlaceholder")}
                  value={orderFormData.description}
                  onChange={(e) => setOrderFormData({ ...orderFormData, description: e.target.value })}
                  className="afab-input text-xs"
                />
              </div>

              {/* Payment Method & Linked Invoice */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="afab-label">
                    {tOrderModal("paymentMethod")}
                  </label>
                  <select
                    value={orderFormData.paymentMethod}
                    onChange={(e) => setOrderFormData({ ...orderFormData, paymentMethod: e.target.value })}
                    className="afab-select w-full py-2 text-xs"
                  >
                    <option value="BANK_TRANSFER">{tPaymentMethods("bankTransfer")}</option>
                    <option value="CREDIT_CARD">{tPaymentMethods("creditCard")}</option>
                    <option value="CASH">{tPaymentMethods("cash")}</option>
                    <option value="STRIPE">{tPaymentMethods("stripe")}</option>
                  </select>
                </div>
                <div>
                  <label className="afab-label">
                    {tOrderModal("invoiceNumber")}
                  </label>
                  <input
                    type="text"
                    placeholder={tOrderModal("invoiceNumberPlaceholder")}
                    value={orderFormData.invoiceNumber}
                    onChange={(e) => setOrderFormData({ ...orderFormData, invoiceNumber: e.target.value })}
                    className="afab-input font-mono text-xs"
                  />
                </div>
              </div>

              {/* Form Actions */}
              <div className="pt-4 border-t border-gray-100 dark:border-gray-800/60 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsAddOrderModalOpen(false)}
                  className="afab-btn-secondary"
                >
                  {tOrderModal("cancel")}
                </button>
                <button
                  type="submit"
                  disabled={orderSubmitting}
                  className="afab-btn-primary"
                >
                  {orderSubmitting ? tOrderModal("submitting") : tOrderModal("submit")}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Delete Confirmation Modal ── */}
      {customerToDelete && (
        <div className="afab-overlay animate-in fade-in duration-200">
          <div className="afab-modal max-w-sm animate-in zoom-in-95">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {tDelete("title")}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
              {tDelete("message", { name: customerToDelete.name })}
            </p>
            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                onClick={() => setCustomerToDelete(null)}
                className="afab-btn-secondary"
              >
                {tDelete("cancel")}
              </button>
              <button
                onClick={handleDeleteConfirm}
                className="afab-btn-danger"
              >
                {tDelete("confirm")}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
