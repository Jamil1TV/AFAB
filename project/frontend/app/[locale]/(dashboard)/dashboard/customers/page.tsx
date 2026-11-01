"use client";

import { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { useTranslations, useLocale } from "next-intl";
import { 
  Users, 
  UserPlus, 
  DollarSign, 
  ShoppingBag, 
  Search, 
  Download, 
  ChevronLeft, 
  ChevronRight, 
  MoreVertical, 
  Plus, 
  Eye, 
  Edit3, 
  Trash2, 
  X, 
  Phone, 
  Mail, 
  MapPin, 
  Calendar, 
  CreditCard, 
  FileText,
  Copy,
  Check
} from "lucide-react";
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip } from "recharts";
import { toast } from "sonner";

import { AfabLoader } from "@/components/ui/afab-loader";
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

// SVG Sparkline Generator matching the Stitch design
function Sparkline({ data, color }: { data: number[]; color: string }) {
  const points = data.length > 0 ? data : [10, 25, 18, 30, 22, 40, 35];
  const min = Math.min(...points);
  const max = Math.max(...points);
  const range = max - min || 1;
  const width = 120;
  const height = 36;
  const padding = 4;

  const coords = points.map((val, idx) => {
    const x = padding + (idx / (points.length - 1)) * (width - padding * 2);
    const y = height - padding - ((val - min) / range) * (height - padding * 2);
    return `${x},${y}`;
  });

  return (
    <svg width={width} height={height} className="overflow-visible">
      <polyline
        fill="none"
        stroke={color}
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        points={coords.join(" ")}
      />
    </svg>
  );
}

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
        return "bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20";
      case "Business":
        return "bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20";
      case "Enterprise":
        return "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20";
      case "Standard":
      default:
        return "bg-gray-500/10 text-gray-600 dark:text-gray-400 border border-gray-500/20";
    }
  };

  const getStatusBadge = (status: CustomerStatus) => {
    switch (status) {
      case "Active":
        return "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20";
      case "Inactive":
        return "bg-gray-500/10 text-gray-500 dark:text-gray-400 border border-gray-500/20";
      case "New":
        return "bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20";
      case "Lead":
        return "bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20";
      default:
        return "bg-gray-500/10 text-gray-500";
    }
  };

  // Sparkline Trends Data
  const sparklineData = useMemo(() => ({
    total: [190, 205, 215, 228, 235, 242, 248],
    newCust: [14, 18, 16, 20, 22, 19, 24],
    revenue: [52000, 58000, 61000, 67000, 71000, 69000, 74850],
    avgRev: [270, 282, 290, 285, 295, 298, 302],
    repeat: [58, 60, 62, 61, 65, 66, 68],
  }), []);

  // Overview Donut Chart Data
  const donutData = useMemo(() => {
    if (!summary) return [];
    return [
      { name: tStatuses("active"), value: summary.overviewDonut.activeCount, color: "#10b981" },
      { name: tStatuses("inactive"), value: summary.overviewDonut.inactiveCount, color: "#8b5cf6" },
      { name: tStatuses("new"), value: summary.overviewDonut.newCount, color: "#f43f5e" },
    ];
  }, [summary, tStatuses]);

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-16">
      
      {/* ── Page Header matching Stitch Mockup ── */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            {t("title")}
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {t("subtitle")}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Header Search Input with ⌘K badge */}
          <div className="relative w-full sm:w-64">
            <Search className={`absolute top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 ${isRtl ? "right-3" : "left-3"}`} />
            <input
              ref={searchInputRef}
              type="text"
              placeholder={t("searchPlaceholder")}
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(0);
              }}
              className={`w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0f1422] py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6] transition-all shadow-sm ${
                isRtl ? "pr-9 pl-9" : "pl-9 pr-9"
              }`}
            />
            <kbd className={`absolute top-1/2 -translate-y-1/2 hidden sm:inline-flex items-center px-1.5 py-0.5 text-[10px] font-mono text-gray-400 bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md ${
              isRtl ? "left-2.5" : "right-2.5"
            }`}>
              ⌘K
            </kbd>
          </div>

          {/* Period Selector Dropdown */}
          <div className="flex items-center rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0f1422] p-1 shadow-sm">
            {(["week", "month", "quarter", "year"] as const).map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all ${
                  period === p
                    ? "bg-[#8b5cf6] text-white shadow-sm"
                    : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                }`}
              >
                {t(`period.${p}`)}
              </button>
            ))}
          </div>

          {/* Add Customer Button (Purple Gradient CTA) */}
          <button
            onClick={openAddModal}
            className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white font-semibold px-4 py-2 text-xs shadow-lg shadow-purple-600/25 active:scale-95 transition-all"
          >
            <Plus className="h-4 w-4" />
            <span>{t("addCustomer")}</span>
          </button>
        </div>
      </div>

      {/* ── 5 Top KPI Cards with Sparklines ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        
        {/* Total Customers */}
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm transition-all hover:border-[#8b5cf6]/40">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
              {tKpi("totalCustomers")}
            </span>
            <div className="h-8 w-8 rounded-xl bg-purple-500/10 border border-purple-500/20 text-[#8b5cf6] flex items-center justify-center">
              <Users className="h-4 w-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white mt-2">
            {summary ? summary.totalCustomers : "—"}
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-xs font-semibold text-emerald-500 flex items-center gap-0.5">
              ↑ {summary?.totalCustomersChangePct ?? 12.5}%
              <span className="text-[11px] font-normal text-gray-400 ms-1">
                {tKpi("vsLastWeek")}
              </span>
            </span>
          </div>
          <div className="mt-2 pt-1 border-t border-gray-100 dark:border-gray-800/40">
            <Sparkline data={sparklineData.total} color="#8b5cf6" />
          </div>
        </div>

        {/* New Customers */}
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm transition-all hover:border-emerald-500/40">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
              {tKpi("newCustomers")}
            </span>
            <div className="h-8 w-8 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 flex items-center justify-center">
              <UserPlus className="h-4 w-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white mt-2">
            {summary ? summary.newCustomers : "—"}
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-xs font-semibold text-emerald-500 flex items-center gap-0.5">
              ↑ {summary?.newCustomersChangePct ?? 8.4}%
              <span className="text-[11px] font-normal text-gray-400 ms-1">
                {tKpi("vsLastWeek")}
              </span>
            </span>
          </div>
          <div className="mt-2 pt-1 border-t border-gray-100 dark:border-gray-800/40">
            <Sparkline data={sparklineData.newCust} color="#10b981" />
          </div>
        </div>

        {/* Total Revenue */}
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm transition-all hover:border-amber-500/40">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
              {tKpi("totalRevenue")}
            </span>
            <div className="h-8 w-8 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-500 flex items-center justify-center">
              <DollarSign className="h-4 w-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white mt-2 truncate">
            {summary ? formatCurrency(summary.totalRevenue, currency) : "—"}
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-xs font-semibold text-emerald-500 flex items-center gap-0.5">
              ↑ {summary?.totalRevenueChangePct ?? 15.2}%
              <span className="text-[11px] font-normal text-gray-400 ms-1">
                {tKpi("vsLastWeek")}
              </span>
            </span>
          </div>
          <div className="mt-2 pt-1 border-t border-gray-100 dark:border-gray-800/40">
            <Sparkline data={sparklineData.revenue} color="#f59e0b" />
          </div>
        </div>

        {/* Avg. Revenue Per Customer */}
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm transition-all hover:border-blue-500/40">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
              {tKpi("avgRevenue")}
            </span>
            <div className="h-8 w-8 rounded-xl bg-blue-500/10 border border-blue-500/20 text-blue-500 flex items-center justify-center">
              <ShoppingBag className="h-4 w-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white mt-2 truncate">
            {summary ? formatCurrency(summary.avgRevenuePerCustomer, currency) : "—"}
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-xs font-semibold text-rose-500 flex items-center gap-0.5">
              ↓ {summary?.avgRevenueChangePct ?? -2.1}%
              <span className="text-[11px] font-normal text-gray-400 ms-1">
                {tKpi("vsLastWeek")}
              </span>
            </span>
          </div>
          <div className="mt-2 pt-1 border-t border-gray-100 dark:border-gray-800/40">
            <Sparkline data={sparklineData.avgRev} color="#3b82f6" />
          </div>
        </div>

        {/* Repeat Customers */}
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm transition-all hover:border-purple-500/40">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
              {tKpi("repeatCustomers")}
            </span>
            <div className="h-8 w-8 rounded-xl bg-purple-500/10 border border-purple-500/20 text-[#8b5cf6] flex items-center justify-center">
              <Users className="h-4 w-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white mt-2">
            {summary ? `${summary.repeatCustomersPct}%` : "—"}
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-xs font-semibold text-emerald-500 flex items-center gap-0.5">
              ↑ {summary?.repeatCustomersChangePct ?? 4.0}%
              <span className="text-[11px] font-normal text-gray-400 ms-1">
                {tKpi("vsLastWeek")}
              </span>
            </span>
          </div>
          <div className="mt-2 pt-1 border-t border-gray-100 dark:border-gray-800/40">
            <Sparkline data={sparklineData.repeat} color="#a855f7" />
          </div>
        </div>

      </div>

      {/* ── Main Layout: 2/3 Directory Table & 1/3 Analytics Widgets ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Left Column: Customer Directory Table (8 Cols) */}
        <div className="lg:col-span-8 rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] shadow-sm overflow-hidden">
          
          {/* Table Controls (Search, Filters, CSV Export) */}
          <div className="p-4 border-b border-gray-200 dark:border-gray-800/60 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            
            {/* Table inline search */}
            <div className="relative flex-1 max-w-sm">
              <Search className={`absolute top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 ${isRtl ? "right-3" : "left-3"}`} />
              <input
                type="text"
                placeholder={tTable("search")}
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(0);
                }}
                className={`w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6] transition-all ${
                  isRtl ? "pr-9 pl-3" : "pl-9 pr-3"
                }`}
              />
            </div>

            <div className="flex items-center gap-2">
              {/* Group Filter */}
              <select
                value={groupFilter}
                onChange={(e) => {
                  setGroupFilter(e.target.value);
                  setPage(0);
                }}
                className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
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
                className="rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
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
                className="flex items-center gap-1.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
              >
                <Download className="h-3.5 w-3.5 text-gray-500" />
                <span className="hidden sm:inline">{tTable("export")}</span>
              </button>
            </div>
          </div>

          {/* Active selection banner */}
          {selectedIds.length > 0 && (
            <div className="px-4 py-2 bg-purple-500/10 border-b border-purple-500/20 flex items-center justify-between text-xs text-purple-600 dark:text-purple-400 font-medium">
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
            <table className="w-full text-start border-collapse">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-800/60 bg-gray-50/40 dark:bg-[#0a0e1a]/40 text-[11px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  <th className="py-3 px-4 w-10 text-center">
                    <input
                      type="checkbox"
                      checked={customers.length > 0 && selectedIds.length === customers.length}
                      onChange={toggleSelectAll}
                      className="rounded border-gray-300 dark:border-gray-700 text-[#8b5cf6] focus:ring-[#8b5cf6]"
                    />
                  </th>
                  <th className={`py-3 px-4 ${isRtl ? "text-right" : "text-left"}`}>{tTable("customer")}</th>
                  <th className={`py-3 px-4 ${isRtl ? "text-right" : "text-left"}`}>{tTable("contact")}</th>
                  <th className={`py-3 px-4 ${isRtl ? "text-right" : "text-left"}`}>{tTable("group")}</th>
                  <th className={`py-3 px-4 ${isRtl ? "text-right" : "text-left"}`}>{tTable("totalRevenue")}</th>
                  <th className="py-3 px-4 text-center">{tTable("orders")}</th>
                  <th className="py-3 px-4 text-center">{tTable("status")}</th>
                  <th className={`py-3 px-4 ${isRtl ? "text-right" : "text-left"}`}>{tTable("lastActivity")}</th>
                  <th className="py-3 px-4 text-center w-12">{tTable("actions")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800/40 text-xs font-medium text-gray-700 dark:text-gray-300">
                {loading && customers.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="py-12 text-center">
                      <AfabLoader text="Loading customer directory..." />
                    </td>
                  </tr>
                ) : customers.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="py-12 text-center text-gray-400">
                      <Users className="h-8 w-8 mx-auto mb-2 opacity-40" />
                      <p className="font-semibold">{tTable("noResults")}</p>
                      <p className="text-xs mt-1 text-gray-500">{tTable("noCustomersYet")}</p>
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
                        className={`group transition-colors cursor-pointer ${
                          isSelected
                            ? "bg-purple-500/5 dark:bg-purple-900/10"
                            : "hover:bg-gray-50/70 dark:hover:bg-white/[0.02]"
                        }`}
                      >
                        {/* Checkbox */}
                        <td
                          className="py-3.5 px-4 text-center"
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
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-3">
                            <div className={`h-9 w-9 rounded-xl flex items-center justify-center font-bold text-xs shrink-0 border ${cust.avatarColor || "bg-purple-500/20 text-purple-400 border-purple-500/30"}`}>
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
                                  className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded font-mono text-[10px] font-semibold bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20 hover:bg-purple-500/20 transition-colors"
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
                        <td className="py-3.5 px-4 text-gray-600 dark:text-gray-400 whitespace-nowrap">
                          {cust.phone || "—"}
                        </td>

                        {/* Group */}
                        <td className="py-3.5 px-4 whitespace-nowrap">
                          <span className={`inline-flex items-center px-2 py-0.5 rounded-lg text-[11px] font-semibold ${getGroupBadge(cust.group)}`}>
                            {tGroups(cust.group.toLowerCase()) || cust.group}
                          </span>
                        </td>

                        {/* Total Revenue */}
                        <td className="py-3.5 px-4 font-bold text-gray-900 dark:text-white whitespace-nowrap">
                          {formatCurrency(cust.totalRevenue, currency)}
                        </td>

                        {/* Orders count badge with quick Add Order on hover */}
                        <td className="py-3.5 px-4 text-center">
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedCustomer(cust);
                            }}
                            className="inline-flex items-center gap-1 font-semibold text-gray-700 dark:text-gray-300 hover:text-[#8b5cf6] dark:hover:text-[#8b5cf6] px-2 py-0.5 rounded-md hover:bg-purple-500/10 transition-colors"
                          >
                            <ShoppingBag className="h-3 w-3 text-gray-400" />
                            <span>{cust.ordersCount}</span>
                          </button>
                        </td>

                        {/* Status */}
                        <td className="py-3.5 px-4 text-center whitespace-nowrap">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold ${getStatusBadge(cust.status)}`}>
                            {tStatuses(cust.status.toLowerCase()) || cust.status}
                          </span>
                        </td>

                        {/* Last Activity */}
                        <td className="py-3.5 px-4 text-gray-500 dark:text-gray-400 whitespace-nowrap">
                          {cust.lastActivityDate}
                        </td>

                        {/* Actions Menu */}
                        <td
                          className="py-3.5 px-4 text-center relative"
                          onClick={(e) => e.stopPropagation()}
                          data-row-menu
                        >
                          <button
                            onClick={() => setActiveRowMenuId(activeRowMenuId === cust.id ? null : cust.id)}
                            className="p-1 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                          >
                            <MoreVertical className="h-4 w-4" />
                          </button>

                          {activeRowMenuId === cust.id && (
                            <div className={`absolute top-8 ${isRtl ? "left-4" : "right-4"} z-30 w-40 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#131825] shadow-xl py-1 text-xs text-start animate-in fade-in zoom-in-95`}>
                              <button
                                onClick={() => {
                                  setSelectedCustomer(cust);
                                  setActiveRowMenuId(null);
                                }}
                                className="flex items-center gap-2 w-full px-3 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                              >
                                <Eye className="h-3.5 w-3.5" />
                                <span>{tTable("viewDetails")}</span>
                              </button>
                              <button
                                onClick={() => openAddOrderModal(cust)}
                                className="flex items-center gap-2 w-full px-3 py-2 text-purple-600 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-500/10 transition-colors font-semibold"
                              >
                                <ShoppingBag className="h-3.5 w-3.5" />
                                <span>{tTable("addOrder")}</span>
                              </button>
                              <button
                                onClick={() => openEditModal(cust)}
                                className="flex items-center gap-2 w-full px-3 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                              >
                                <Edit3 className="h-3.5 w-3.5" />
                                <span>{tTable("edit")}</span>
                              </button>
                              <div className="my-1 border-t border-gray-100 dark:border-gray-800" />
                              <button
                                onClick={() => {
                                  setCustomerToDelete(cust);
                                  setActiveRowMenuId(null);
                                }}
                                className="flex items-center gap-2 w-full px-3 py-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
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
          <div className="p-4 border-t border-gray-200 dark:border-gray-800/60 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs text-gray-500 dark:text-gray-400">
            <div>
              {tTable("showing", {
                from: totalElements > 0 ? page * pageSize + 1 : 0,
                to: Math.min((page + 1) * pageSize, totalElements),
                total: totalElements,
              })}
            </div>

            <div className="flex items-center gap-4">
              {/* Rows Per Page */}
              <div className="flex items-center gap-1.5">
                <span>{tTable("rowsPerPage")}</span>
                <select
                  value={pageSize}
                  onChange={(e) => {
                    setPageSize(Number(e.target.value));
                    setPage(0);
                  }}
                  className="rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-[#080c18] px-2 py-1 text-xs font-medium text-gray-700 dark:text-gray-300 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
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
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 hover:bg-gray-100 dark:hover:bg-white/[0.05] disabled:opacity-40 transition-colors"
                >
                  <ChevronLeft className="h-3.5 w-3.5" />
                </button>
                <span className="px-3 py-1 font-semibold text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-800 rounded-lg">
                  {page + 1} / {totalPages}
                </span>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                  disabled={page >= totalPages - 1}
                  className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-800 hover:bg-gray-100 dark:hover:bg-white/[0.05] disabled:opacity-40 transition-colors"
                >
                  <ChevronRight className="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
          </div>

        </div>

        {/* Right Column: 3 Analytics & Insight Widgets (4 Cols) */}
        <div className="lg:col-span-4 space-y-6">
          
          {/* Widget 1: Customer Overview Donut Chart */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm">
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
                      contentStyle={{
                        backgroundColor: "#131825",
                        border: "1px solid #1e293b",
                        borderRadius: "12px",
                        fontSize: "12px",
                      }}
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
              <div className="flex-1 space-y-2 text-xs">
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-gray-600 dark:text-gray-300">
                    <span className="h-2 w-2 rounded-full bg-emerald-500" />
                    <span>{tStatuses("active")}</span>
                  </span>
                  <span className="font-bold text-gray-900 dark:text-white">
                    {summary?.overviewDonut.activePct ?? 65}%
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-gray-600 dark:text-gray-300">
                    <span className="h-2 w-2 rounded-full bg-[#8b5cf6]" />
                    <span>{tStatuses("inactive")}</span>
                  </span>
                  <span className="font-bold text-gray-900 dark:text-white">
                    {summary?.overviewDonut.inactivePct ?? 22}%
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-gray-600 dark:text-gray-300">
                    <span className="h-2 w-2 rounded-full bg-rose-500" />
                    <span>{tStatuses("new")}</span>
                  </span>
                  <span className="font-bold text-gray-900 dark:text-white">
                    {summary?.overviewDonut.newPct ?? 13}%
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Widget 2: Top Customers by Revenue */}
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                {tWidgets("topCustomersTitle")}
              </h3>
              <button
                onClick={() => {
                  setGroupFilter("Premium");
                  setPage(0);
                }}
                className="text-xs font-semibold text-[#8b5cf6] hover:underline"
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
                    className="flex items-center justify-between p-2 rounded-xl hover:bg-gray-50/70 dark:hover:bg-white/[0.03] transition-colors cursor-pointer"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className={`h-8 w-8 rounded-xl flex items-center justify-center font-bold text-xs shrink-0 border ${top.avatarColor}`}>
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
          <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0f1422] p-5 shadow-sm">
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">
              {tWidgets("activityTitle")}
            </h3>

            <div className="mt-4 space-y-3">
              {(!summary?.recentActivity || summary.recentActivity.length === 0) ? (
                <p className="text-xs text-gray-400 py-3 text-center">{tWidgets("noActivity")}</p>
              ) : (
                summary.recentActivity.map((act) => {
                  let iconColor = "bg-purple-500/10 text-[#8b5cf6] border-purple-500/20";
                  let IconComponent = UserPlus;
                  let actionText = tWidgets("newCustomerActivity");

                  if (act.type === "INVOICE_PAID") {
                    iconColor = "bg-emerald-500/10 text-emerald-500 border-emerald-500/20";
                    IconComponent = FileText;
                    actionText = tWidgets("invoicePaidActivity");
                  } else if (act.type === "PAYMENT_RECEIVED") {
                    iconColor = "bg-blue-500/10 text-blue-500 border-blue-500/20";
                    IconComponent = CreditCard;
                    actionText = tWidgets("paymentReceivedActivity");
                  } else if (act.type === "NEW_ORDER") {
                    iconColor = "bg-indigo-500/10 text-indigo-500 border-indigo-500/20";
                    IconComponent = ShoppingBag;
                    actionText = tWidgets("newOrderActivity");
                  }

                  return (
                    <div key={act.id} className="flex items-start gap-3 p-2 rounded-xl hover:bg-gray-50/70 dark:hover:bg-white/[0.03] transition-colors">
                      <div className={`h-8 w-8 rounded-xl flex items-center justify-center shrink-0 border ${iconColor} mt-0.5`}>
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
        <div className="fixed inset-0 z-50 flex justify-end bg-black/50 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md bg-white dark:bg-[#101422] h-full shadow-2xl border-s border-gray-200 dark:border-gray-800/80 p-6 overflow-y-auto animate-in slide-in-from-right duration-200 flex flex-col justify-between">
            <div>
              {/* Header */}
              <div className="flex items-center justify-between pb-4 border-b border-gray-200 dark:border-gray-800">
                <div className="flex items-center gap-3">
                  <div className={`h-12 w-12 rounded-2xl flex items-center justify-center font-bold text-sm border ${selectedCustomer.avatarColor || "bg-purple-500/20 text-purple-400 border-purple-500/30"}`}>
                    {selectedCustomer.name.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <h2 className="text-base font-bold text-gray-900 dark:text-white">
                      {selectedCustomer.name}
                    </h2>
                    <div className="flex items-center gap-1.5 mt-1 flex-wrap">
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded font-mono text-[11px] font-semibold bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20">
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
                        className="p-1 rounded text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                      >
                        <Copy className="h-3 w-3" />
                      </button>
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold ${getStatusBadge(selectedCustomer.status)}`}>
                        {selectedCustomer.status}
                      </span>
                    </div>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedCustomer(null)}
                  className="p-1.5 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              {/* Financial Stats Cards */}
              <div className="grid grid-cols-2 gap-3 my-5">
                <div className="p-3.5 rounded-xl bg-gray-50 dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800/60">
                  <span className="text-[11px] text-gray-400 font-medium">{tDrawer("totalSpent")}</span>
                  <div className="text-lg font-bold text-gray-900 dark:text-white mt-1">
                    {formatCurrency(selectedCustomer.totalRevenue, currency)}
                  </div>
                </div>
                <div className="p-3.5 rounded-xl bg-gray-50 dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800/60">
                  <span className="text-[11px] text-gray-400 font-medium">{tDrawer("completedOrders")}</span>
                  <div className="text-lg font-bold text-gray-900 dark:text-white mt-1">
                    {selectedCustomer.ordersCount} orders
                  </div>
                </div>
              </div>

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
              <div className="mt-6 pt-5 border-t border-gray-200 dark:border-gray-800">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <ShoppingBag className="h-4 w-4 text-[#8b5cf6]" />
                    <h4 className="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                      {tDrawer("invoicesAndOrders")}
                    </h4>
                    <span className="px-1.5 py-0.5 rounded-full text-[10px] font-semibold bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
                      {selectedCustomer.orders?.length || selectedCustomer.ordersCount || 0}
                    </span>
                  </div>
                  <button
                    onClick={() => openAddOrderModal(selectedCustomer)}
                    className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-[#8b5cf6]/10 text-[#8b5cf6] hover:bg-[#8b5cf6]/20 transition-colors"
                  >
                    <Plus className="h-3 w-3" />
                    <span>{tDrawer("addOrderBtn")}</span>
                  </button>
                </div>

                {(!selectedCustomer.orders || selectedCustomer.orders.length === 0) ? (
                  <div className="p-4 rounded-xl border border-dashed border-gray-200 dark:border-gray-800 text-center">
                    <ShoppingBag className="h-6 w-6 mx-auto mb-1 text-gray-400 opacity-50" />
                    <p className="text-xs text-gray-500 dark:text-gray-400">{tDrawer("noOrders")}</p>
                    <button
                      onClick={() => openAddOrderModal(selectedCustomer)}
                      className="mt-2 text-xs font-semibold text-[#8b5cf6] hover:underline"
                    >
                      {tDrawer("addOrderBtn")}
                    </button>
                  </div>
                ) : (
                  <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1 custom-scrollbar">
                    {selectedCustomer.orders.map((ord: CustomerOrder) => (
                      <div
                        key={ord.id}
                        className="p-3 rounded-xl bg-gray-50/70 dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800/60 hover:border-[#8b5cf6]/40 transition-all text-xs"
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-mono font-bold text-gray-900 dark:text-white text-[11px] bg-gray-200/60 dark:bg-gray-800 px-1.5 py-0.5 rounded">
                            {ord.orderNumber}
                          </span>
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                            ord.status === "COMPLETED"
                              ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400"
                              : ord.status === "PENDING"
                              ? "bg-amber-500/10 text-amber-600 dark:text-amber-400"
                              : ord.status === "PROCESSING"
                              ? "bg-blue-500/10 text-blue-600 dark:text-blue-400"
                              : "bg-red-500/10 text-red-600 dark:text-red-400"
                          }`}>
                            {tOrderStatuses(ord.status.toLowerCase()) || ord.status}
                          </span>
                        </div>

                        <div className="flex items-center justify-between mt-1.5 font-semibold">
                          <span className="text-gray-800 dark:text-gray-200 truncate pr-2">
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
                  <div className="p-3 rounded-xl bg-gray-50 dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800 text-xs text-gray-600 dark:text-gray-300">
                    {selectedCustomer.notes}
                  </div>
                </div>
              )}
            </div>

            {/* Bottom Actions */}
            <div className="pt-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between gap-3 mt-4">
              <button
                onClick={() => {
                  const toDelete = selectedCustomer;
                  setSelectedCustomer(null);
                  setCustomerToDelete(toDelete);
                }}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
              >
                {tTable("delete")}
              </button>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => openAddOrderModal(selectedCustomer)}
                  className="px-3.5 py-2 rounded-xl text-xs font-semibold bg-[#8b5cf6]/10 text-[#8b5cf6] hover:bg-[#8b5cf6]/20 transition-colors"
                >
                  {tDrawer("addOrderBtn")}
                </button>
                <button
                  onClick={() => {
                    const toEdit = selectedCustomer;
                    setSelectedCustomer(null);
                    openEditModal(toEdit);
                  }}
                  className="px-4 py-2 rounded-xl text-xs font-semibold bg-[#8b5cf6] text-white hover:bg-[#7c3aed] transition-colors shadow-sm"
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
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-lg rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#101422] p-6 shadow-2xl animate-in zoom-in-95">
            <div className="flex items-center justify-between pb-4 border-b border-gray-200 dark:border-gray-800">
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-white">
                  {customerToEdit ? tModal("editTitle") : tModal("addTitle")}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {tModal("subtitle")}
                </p>
              </div>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="p-1.5 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSaveCustomer} className="mt-5 space-y-4">
              
              {/* Customer ID & Name in 2 columns */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="sm:col-span-1">
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tModal("customerCode")}
                  </label>
                  <input
                    type="text"
                    placeholder={tModal("customerCodePlaceholder")}
                    value={formData.customerCode || ""}
                    onChange={(e) => setFormData({ ...formData, customerCode: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 font-mono text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
                <div className="sm:col-span-2">
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tModal("name")} *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder={tModal("namePlaceholder")}
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
              </div>

              {/* Email & Phone Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tModal("email")} *
                  </label>
                  <input
                    type="email"
                    required
                    placeholder={tModal("emailPlaceholder")}
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tModal("phone")}
                  </label>
                  <input
                    type="tel"
                    placeholder={tModal("phonePlaceholder")}
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
              </div>

              {/* Group & Status Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tModal("group")}
                  </label>
                  <select
                    value={formData.group}
                    onChange={(e) => setFormData({ ...formData, group: e.target.value as CustomerGroup })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  >
                    <option value="Standard">{tGroups("standard")}</option>
                    <option value="Business">{tGroups("business")}</option>
                    <option value="Premium">{tGroups("premium")}</option>
                    <option value="Enterprise">{tGroups("enterprise")}</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tModal("status")}
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value as CustomerStatus })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
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
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                  {tModal("address")}
                </label>
                <input
                  type="text"
                  placeholder={tModal("addressPlaceholder")}
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                />
              </div>

              {/* Internal Notes */}
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                  {tModal("notes")}
                </label>
                <textarea
                  rows={2}
                  placeholder={tModal("notesPlaceholder")}
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6] resize-none"
                />
              </div>

              {/* Modal Actions */}
              <div className="pt-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                >
                  {tModal("cancel")}
                </button>
                <button
                  type="submit"
                  disabled={formSubmitting}
                  className="px-4 py-2 rounded-xl text-xs font-semibold bg-[#8b5cf6] text-white hover:bg-[#7c3aed] transition-colors shadow-sm disabled:opacity-50"
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
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-lg rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#101422] p-6 shadow-2xl animate-in zoom-in-95">
            <div className="flex items-center justify-between pb-4 border-b border-gray-200 dark:border-gray-800">
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                  <ShoppingBag className="h-5 w-5 text-[#8b5cf6]" />
                  <span>{tOrderModal("title")}</span>
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {orderTargetCustomer.name} • <span className="font-mono text-purple-600 dark:text-purple-400">{orderTargetCustomer.customerCode}</span>
                </p>
              </div>
              <button
                onClick={() => setIsAddOrderModalOpen(false)}
                className="p-1.5 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSaveOrder} className="mt-5 space-y-4">
              {/* Order Number & Date */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tOrderModal("orderNumber")} *
                  </label>
                  <input
                    type="text"
                    required
                    value={orderFormData.orderNumber}
                    onChange={(e) => setOrderFormData({ ...orderFormData, orderNumber: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 font-mono text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tOrderModal("orderDate")} *
                  </label>
                  <input
                    type="date"
                    required
                    value={orderFormData.orderDate}
                    onChange={(e) => setOrderFormData({ ...orderFormData, orderDate: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
              </div>

              {/* Amount & Status */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
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
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tOrderModal("status")}
                  </label>
                  <select
                    value={orderFormData.status}
                    onChange={(e) => setOrderFormData({ ...orderFormData, status: e.target.value as OrderStatus })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
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
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                  {tOrderModal("description")} *
                </label>
                <input
                  type="text"
                  required
                  placeholder={tOrderModal("descriptionPlaceholder")}
                  value={orderFormData.description}
                  onChange={(e) => setOrderFormData({ ...orderFormData, description: e.target.value })}
                  className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                />
              </div>

              {/* Payment Method & Linked Invoice */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tOrderModal("paymentMethod")}
                  </label>
                  <select
                    value={orderFormData.paymentMethod}
                    onChange={(e) => setOrderFormData({ ...orderFormData, paymentMethod: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 text-xs font-medium text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  >
                    <option value="BANK_TRANSFER">{tPaymentMethods("bankTransfer")}</option>
                    <option value="CREDIT_CARD">{tPaymentMethods("creditCard")}</option>
                    <option value="CASH">{tPaymentMethods("cash")}</option>
                    <option value="STRIPE">{tPaymentMethods("stripe")}</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {tOrderModal("invoiceNumber")}
                  </label>
                  <input
                    type="text"
                    placeholder={tOrderModal("invoiceNumberPlaceholder")}
                    value={orderFormData.invoiceNumber}
                    onChange={(e) => setOrderFormData({ ...orderFormData, invoiceNumber: e.target.value })}
                    className="w-full rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] px-3.5 py-2 font-mono text-xs font-medium text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]"
                  />
                </div>
              </div>

              {/* Form Actions */}
              <div className="pt-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsAddOrderModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
                >
                  {tOrderModal("cancel")}
                </button>
                <button
                  type="submit"
                  disabled={orderSubmitting}
                  className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white shadow-md shadow-purple-600/20 disabled:opacity-50 transition-all"
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
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-sm rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#101422] p-6 shadow-2xl animate-in zoom-in-95">
            <h3 className="text-base font-bold text-gray-900 dark:text-white">
              {tDelete("title")}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
              {tDelete("message", { name: customerToDelete.name })}
            </p>
            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                onClick={() => setCustomerToDelete(null)}
                className="px-4 py-2 rounded-xl text-xs font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/[0.05] transition-colors"
              >
                {tDelete("cancel")}
              </button>
              <button
                onClick={handleDeleteConfirm}
                className="px-4 py-2 rounded-xl text-xs font-semibold bg-red-600 text-white hover:bg-red-700 transition-colors shadow-sm"
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
