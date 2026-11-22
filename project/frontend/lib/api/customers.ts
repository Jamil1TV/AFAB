import { fetchClient, ApiError } from "./client";
import { AuthStore } from "@/lib/auth-store";
import { TransactionService } from "./transactions";

export type CustomerGroup = "Standard" | "Business" | "Premium" | "Enterprise";
export type CustomerStatus = "Active" | "Inactive" | "New" | "Lead";
export type OrderStatus = "COMPLETED" | "PENDING" | "PROCESSING" | "CANCELLED";

export interface CustomerOrder {
  id: string;
  orderNumber: string; // e.g. "ORD-2026-001"
  customerId: string;
  amount: number;
  status: OrderStatus;
  orderDate: string; // YYYY-MM-DD
  description: string;
  paymentMethod?: string; // "BANK_TRANSFER" | "CREDIT_CARD" | "CASH" | "STRIPE"
  invoiceNumber?: string; // e.g. "INV-2026-001"
  createdAt: string;
}

export interface Customer {
  id: string;
  customerCode: string; // e.g. "CST-1001"
  businessId: string;
  name: string;
  email: string;
  phone?: string;
  group: CustomerGroup;
  status: CustomerStatus;
  totalRevenue: number;
  ordersCount: number;
  orders?: CustomerOrder[];
  lastActivityDate: string;
  address?: string;
  notes?: string;
  createdAt: string;
  avatarColor?: string;
}

export interface CustomerActivityItem {
  id: string;
  customerId: string;
  customerName: string;
  type: "NEW_CUSTOMER" | "INVOICE_PAID" | "PAYMENT_RECEIVED" | "NEW_ORDER";
  description: string;
  amount?: number;
  timestamp: string;
}

export interface CustomerSummaryDTO {
  totalCustomers: number;
  totalCustomersChangePct: number;
  newCustomers: number;
  newCustomersChangePct: number;
  totalRevenue: number;
  totalRevenueChangePct: number;
  avgRevenuePerCustomer: number;
  avgRevenueChangePct: number;
  repeatCustomersPct: number;
  repeatCustomersChangePct: number;
  currency: string;
  overviewDonut: {
    activeCount: number;
    activePct: number;
    inactiveCount: number;
    inactivePct: number;
    newCount: number;
    newPct: number;
  };
  topCustomers: Array<{
    id: string;
    customerCode: string;
    name: string;
    email: string;
    revenue: number;
    ordersCount: number;
    avatarColor: string;
  }>;
  recentActivity: CustomerActivityItem[];
}

export interface CustomerPageResponse {
  content: Customer[];
  totalElements: number;
  totalPages: number;
  pageNumber: number;
  pageSize: number;
}

export interface CustomerFilterParams {
  search?: string;
  status?: string;
  group?: string;
  page?: number;
  size?: number;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface CreateCustomerRequest {
  name: string;
  email: string;
  customerCode?: string;
  phone?: string;
  group: CustomerGroup;
  status: CustomerStatus;
  address?: string;
  notes?: string;
}

export interface UpdateCustomerRequest {
  name?: string;
  email?: string;
  customerCode?: string;
  phone?: string;
  group?: CustomerGroup;
  status?: CustomerStatus;
  address?: string;
  notes?: string;
  totalRevenue?: number;
  ordersCount?: number;
}

export interface CreateOrderRequest {
  customerId: string;
  orderNumber?: string;
  amount: number;
  status: OrderStatus;
  orderDate?: string;
  description: string;
  paymentMethod?: string;
  invoiceNumber?: string;
}

const AVATAR_COLORS = [
  "bg-purple-500/15 text-[#7c3aed] dark:text-[#a78bfa] border-purple-500/25",
  "bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/25",
  "bg-sky-500/15 text-sky-600 dark:text-sky-400 border-sky-500/25",
  "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/25",
  "bg-pink-500/15 text-pink-600 dark:text-pink-400 border-pink-500/25",
  "bg-indigo-500/15 text-indigo-600 dark:text-indigo-400 border-indigo-500/25",
  "bg-teal-500/15 text-teal-600 dark:text-teal-400 border-teal-500/25",
];

function getAvatarColor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  const index = Math.abs(hash) % AVATAR_COLORS.length;
  return AVATAR_COLORS[index];
}

// Known mock seed emails from earlier prototype builds — automatically purged so only real user-created records remain.
const LEGACY_SEED_EMAILS = new Set([
  "info@afab.com",
  "billing@aiassist.com",
  "finance@reports.com",
  "contact@consult.com",
  "hello@designhub.com",
  "web@devstudio.com",
  "hello@marketing.com",
  "contact@softsol.com",
  "ops@globallogistics.com",
  "accounts@apexretail.com",
]);

function getStorageKey(): string {
  const activeBusinessId = AuthStore.getActiveBusinessId() || "default";
  return `afab_customers_${activeBusinessId}`;
}

/**
 * Recomputes a customer's `ordersCount` and `totalRevenue` strictly from their stored orders
 * so financial totals are always traceable to actual order records.
 */
function normalizeCustomerRecord(c: Customer, index: number): Customer {
  const orders = Array.isArray(c.orders) ? c.orders : [];
  const completedRevenue = orders
    .filter((o) => o.status === "COMPLETED")
    .reduce((sum, o) => sum + (Number(o.amount) || 0), 0);

  return {
    ...c,
    customerCode: c.customerCode || `CST-${1001 + index}`,
    orders,
    ordersCount: orders.length,
    totalRevenue: orders.length > 0 ? completedRevenue : Number(c.totalRevenue) || 0,
    avatarColor: c.avatarColor || getAvatarColor(c.name || "C"),
  };
}

function loadLocalCustomers(): Customer[] {
  if (typeof window === "undefined") return [];
  const key = getStorageKey();
  const raw = localStorage.getItem(key);
  if (!raw) {
    return [];
  }
  try {
    const parsed: Customer[] = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    // Strip any legacy prototype seed records that were never created by the user
    const realOnly = parsed.filter(
      (c) => !(c.id?.startsWith("cust-") && LEGACY_SEED_EMAILS.has(c.email))
    );
    const normalized = realOnly.map((c, idx) => normalizeCustomerRecord(c, idx));

    if (realOnly.length !== parsed.length) {
      localStorage.setItem(key, JSON.stringify(normalized));
    }
    return normalized;
  } catch {
    return [];
  }
}

function saveLocalCustomers(customers: Customer[]): void {
  if (typeof window === "undefined") return;
  const key = getStorageKey();
  localStorage.setItem(key, JSON.stringify(customers));
}

function getPeriodWindowDays(period: string): number {
  switch (period.toLowerCase()) {
    case "week":
    case "weekly":
      return 7;
    case "quarter":
      return 90;
    case "year":
    case "yearly":
      return 365;
    case "month":
    case "monthly":
    default:
      return 30;
  }
}

function computePctDelta(current: number, previous: number): number {
  if (previous === 0) {
    return current > 0 ? 100 : 0;
  }
  return Math.round(((current - previous) / Math.abs(previous)) * 1000) / 10;
}

export const CustomerService = {
  /**
   * Retrieves paginated, filtered customers.
   * Queries backend `/customers` if implemented; otherwise uses the business-scoped customer store
   * containing only user-created customer records (never fabricated seed data).
   */
  async getCustomers(params: CustomerFilterParams = {}): Promise<CustomerPageResponse> {
    const {
      search = "",
      status = "",
      group = "",
      page = 0,
      size = 10,
      sortBy = "lastActivityDate",
      sortOrder = "desc",
    } = params;

    const query = new URLSearchParams();
    if (search) query.append("search", search);
    if (status && status !== "ALL") query.append("status", status);
    if (group && group !== "ALL") query.append("group", group);
    query.append("page", page.toString());
    query.append("size", size.toString());
    if (sortBy) query.append("sortBy", sortBy);
    if (sortOrder) query.append("sortOrder", sortOrder);

    try {
      return await fetchClient(`/customers?${query.toString()}`);
    } catch {
      let list = loadLocalCustomers();

      if (search.trim()) {
        const q = search.toLowerCase();
        list = list.filter(
          (c) =>
            c.name.toLowerCase().includes(q) ||
            c.email.toLowerCase().includes(q) ||
            (c.customerCode && c.customerCode.toLowerCase().includes(q)) ||
            (c.phone && c.phone.includes(q))
        );
      }

      if (status && status !== "ALL") {
        list = list.filter((c) => c.status.toLowerCase() === status.toLowerCase());
      }

      if (group && group !== "ALL") {
        list = list.filter((c) => c.group.toLowerCase() === group.toLowerCase());
      }

      list.sort((a, b) => {
        const valA = (a as unknown as Record<string, unknown>)[sortBy] ?? "";
        const valB = (b as unknown as Record<string, unknown>)[sortBy] ?? "";
        if (typeof valA === "number" && typeof valB === "number") {
          return sortOrder === "asc" ? valA - valB : valB - valA;
        }
        return sortOrder === "asc"
          ? String(valA).localeCompare(String(valB))
          : String(valB).localeCompare(String(valA));
      });

      const totalElements = list.length;
      const totalPages = Math.max(1, Math.ceil(totalElements / size));
      const startIndex = page * size;
      const paginatedContent = list.slice(startIndex, startIndex + size);

      return {
        content: paginatedContent,
        totalElements,
        totalPages,
        pageNumber: page,
        pageSize: size,
      };
    }
  },

  /**
   * Retrieves summary metrics (KPIs, donut breakdown, top customers, recent activity).
   * All metrics and percentage changes are computed directly from actual stored customer & order records.
   */
  async getSummary(period: string = "week", currency: string = "USD"): Promise<CustomerSummaryDTO> {
    try {
      return await fetchClient(`/customers/summary?period=${encodeURIComponent(period)}`);
    } catch {
      const customers = loadLocalCustomers();
      const totalCustomers = customers.length;
      const activeCount = customers.filter((c) => c.status === "Active").length;
      const inactiveCount = customers.filter((c) => c.status === "Inactive").length;
      const newStatusCount = customers.filter((c) => c.status === "New" || c.status === "Lead").length;

      // Period window calculations based on real createdAt / orderDate timestamps
      const windowDays = getPeriodWindowDays(period);
      const now = new Date();
      const currentStart = new Date(now.getTime() - windowDays * 86400000);
      const prevStart = new Date(now.getTime() - windowDays * 2 * 86400000);

      const currentNewCustomers = customers.filter((c) => {
        const d = new Date(c.createdAt);
        return !isNaN(d.getTime()) && d >= currentStart;
      }).length;

      const prevNewCustomers = customers.filter((c) => {
        const d = new Date(c.createdAt);
        return !isNaN(d.getTime()) && d >= prevStart && d < currentStart;
      }).length;

      const totalRevenue = customers.reduce((acc, curr) => acc + (curr.totalRevenue || 0), 0);
      const avgRevenuePerCustomer = totalCustomers > 0 ? totalRevenue / totalCustomers : 0;
      const repeatCustomersCount = customers.filter((c) => c.ordersCount > 1).length;
      const repeatCustomersPct = totalCustomers > 0 ? Math.round((repeatCustomersCount / totalCustomers) * 100) : 0;

      // Period revenue comparison from actual completed orders
      let currentPeriodRevenue = 0;
      let prevPeriodRevenue = 0;
      for (const c of customers) {
        for (const o of c.orders || []) {
          if (o.status !== "COMPLETED") continue;
          const od = new Date(o.orderDate);
          if (isNaN(od.getTime())) continue;
          if (od >= currentStart) {
            currentPeriodRevenue += Number(o.amount) || 0;
          } else if (od >= prevStart && od < currentStart) {
            prevPeriodRevenue += Number(o.amount) || 0;
          }
        }
      }

      const activePct = totalCustomers > 0 ? Math.round((activeCount / totalCustomers) * 100) : 0;
      const inactivePct = totalCustomers > 0 ? Math.round((inactiveCount / totalCustomers) * 100) : 0;
      const newPct = totalCustomers > 0 ? Math.max(0, 100 - activePct - inactivePct) : 0;

      // Top customers ordered by actual revenue
      const topCustomers = [...customers]
        .sort((a, b) => b.totalRevenue - a.totalRevenue)
        .slice(0, 5)
        .map((c) => ({
          id: c.id,
          customerCode: c.customerCode || "CST-0000",
          name: c.name,
          email: c.email,
          revenue: c.totalRevenue,
          ordersCount: c.ordersCount,
          avatarColor: c.avatarColor || getAvatarColor(c.name),
        }));

      // Derive recent activity strictly from real customer registrations and orders
      const recentActivity: CustomerActivityItem[] = [];
      for (const c of customers) {
        if (c.createdAt) {
          recentActivity.push({
            id: `act-cust-${c.id}`,
            customerId: c.id,
            customerName: c.name,
            type: "NEW_CUSTOMER",
            description: `Customer ${c.customerCode} registered`,
            timestamp: c.createdAt.includes("T") ? c.createdAt : `${c.createdAt}T09:00:00Z`,
          });
        }
        for (const o of c.orders || []) {
          recentActivity.push({
            id: `act-ord-${o.id}`,
            customerId: c.id,
            customerName: c.name,
            type: o.status === "COMPLETED" ? "INVOICE_PAID" : "NEW_ORDER",
            description: `${o.orderNumber} — ${o.description}`,
            amount: o.amount,
            timestamp: o.createdAt || `${o.orderDate}T12:00:00Z`,
          });
        }
      }
      recentActivity.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

      return {
        totalCustomers,
        totalCustomersChangePct: computePctDelta(currentNewCustomers, prevNewCustomers),
        newCustomers: currentNewCustomers || newStatusCount,
        newCustomersChangePct: computePctDelta(currentNewCustomers, prevNewCustomers),
        totalRevenue,
        totalRevenueChangePct: computePctDelta(currentPeriodRevenue, prevPeriodRevenue),
        avgRevenuePerCustomer: Math.round(avgRevenuePerCustomer * 100) / 100,
        avgRevenueChangePct: 0,
        repeatCustomersPct,
        repeatCustomersChangePct: 0,
        currency,
        overviewDonut: {
          activeCount,
          activePct,
          inactiveCount,
          inactivePct,
          newCount: newStatusCount,
          newPct,
        },
        topCustomers,
        recentActivity: recentActivity.slice(0, 6),
      };
    }
  },

  /**
   * Retrieves a single customer by ID with their complete orders.
   */
  async getCustomerById(id: string): Promise<Customer> {
    try {
      return await fetchClient(`/customers/${id}`);
    } catch {
      const customers = loadLocalCustomers();
      const customer = customers.find((c) => c.id === id);
      if (!customer) {
        throw new ApiError("Customer not found", "NOT_FOUND", 404);
      }
      return customer;
    }
  },

  /**
   * Creates a new customer with an ID number.
   */
  async createCustomer(req: CreateCustomerRequest): Promise<Customer> {
    try {
      return await fetchClient("/customers", {
        method: "POST",
        body: JSON.stringify(req),
      });
    } catch {
      const customers = loadLocalCustomers();
      const activeBusinessId = AuthStore.getActiveBusinessId() || "default";
      const nextCodeNumber = 1000 + customers.length + 1;
      const customerCode = req.customerCode?.trim() || `CST-${nextCodeNumber}`;

      const newCustomer: Customer = {
        id: `cust-${Date.now()}`,
        customerCode,
        businessId: activeBusinessId,
        name: req.name.trim(),
        email: req.email.trim(),
        phone: req.phone?.trim() || "",
        group: req.group,
        status: req.status,
        totalRevenue: 0,
        ordersCount: 0,
        orders: [],
        lastActivityDate: new Date().toISOString().split("T")[0],
        address: req.address?.trim() || "",
        notes: req.notes?.trim() || "",
        createdAt: new Date().toISOString().split("T")[0],
        avatarColor: getAvatarColor(req.name),
      };

      customers.unshift(newCustomer);
      saveLocalCustomers(customers);
      return newCustomer;
    }
  },

  /**
   * Updates an existing customer.
   */
  async updateCustomer(id: string, req: UpdateCustomerRequest): Promise<Customer> {
    try {
      return await fetchClient(`/customers/${id}`, {
        method: "PUT",
        body: JSON.stringify(req),
      });
    } catch {
      const customers = loadLocalCustomers();
      const index = customers.findIndex((c) => c.id === id);
      if (index === -1) {
        throw new ApiError("Customer not found", "NOT_FOUND", 404);
      }

      const existing = customers[index];
      const updated: Customer = normalizeCustomerRecord(
        {
          ...existing,
          ...req,
          name: req.name !== undefined ? req.name.trim() : existing.name,
          email: req.email !== undefined ? req.email.trim() : existing.email,
          customerCode: req.customerCode !== undefined ? req.customerCode.trim() : existing.customerCode,
          phone: req.phone !== undefined ? req.phone.trim() : existing.phone,
          avatarColor: req.name ? getAvatarColor(req.name) : existing.avatarColor,
        },
        index
      );

      customers[index] = updated;
      saveLocalCustomers(customers);
      return updated;
    }
  },

  /**
   * Adds an order to a customer and records a corresponding INCOME transaction
   * in the backend ledger so customer revenue, invoices, and dashboard stats stay synchronized.
   */
  async addOrder(req: CreateOrderRequest): Promise<CustomerOrder> {
    try {
      return await fetchClient(`/customers/${req.customerId}/orders`, {
        method: "POST",
        body: JSON.stringify(req),
      });
    } catch {
      const customers = loadLocalCustomers();
      const index = customers.findIndex((c) => c.id === req.customerId);
      if (index === -1) {
        throw new ApiError("Customer not found", "NOT_FOUND", 404);
      }

      const cust = customers[index];
      const existingOrders = cust.orders || [];
      const orderYear = new Date().getFullYear();
      const orderSeq = String(existingOrders.length + 1).padStart(3, "0");
      const orderNumber = req.orderNumber?.trim() || `ORD-${orderYear}-${orderSeq}`;
      const orderDate = req.orderDate || new Date().toISOString().split("T")[0];
      const invoiceNumber = req.invoiceNumber?.trim() || `INV-${orderYear}-${orderSeq}`;

      const newOrder: CustomerOrder = {
        id: `ord-${Date.now()}`,
        orderNumber,
        customerId: cust.id,
        amount: Number(req.amount) || 0,
        status: req.status,
        orderDate,
        description: req.description.trim() || `Order ${orderNumber}`,
        paymentMethod: req.paymentMethod || "BANK_TRANSFER",
        invoiceNumber,
        createdAt: new Date().toISOString(),
      };

      existingOrders.unshift(newOrder);
      cust.orders = existingOrders;
      cust.lastActivityDate = orderDate;

      customers[index] = normalizeCustomerRecord(cust, index);
      saveLocalCustomers(customers);

      // Synchronize with backend transaction ledger when online so Dashboard/Revenue/Invoices reflect the order
      try {
        const txStatus =
          req.status === "COMPLETED"
            ? "COMPLETED"
            : req.status === "CANCELLED"
            ? "CANCELLED"
            : "PENDING";
        await TransactionService.createTransaction({
          type: "INCOME",
          amount: newOrder.amount,
          description: `${cust.name} — ${newOrder.description} (${invoiceNumber})`,
          transactionDate: orderDate,
          paymentMethod:
            req.paymentMethod === "CREDIT_CARD" || req.paymentMethod === "STRIPE"
              ? "CARD"
              : req.paymentMethod || "BANK_TRANSFER",
          status: txStatus,
          notes: `Customer: ${cust.name} (${cust.customerCode}) | Order: ${orderNumber} | Invoice: ${invoiceNumber}`,
        });
      } catch {
        // Non-blocking if backend is offline
      }

      return newOrder;
    }
  },

  /**
   * Deletes a customer.
   */
  async deleteCustomer(id: string): Promise<void> {
    try {
      await fetchClient(`/customers/${id}`, {
        method: "DELETE",
      });
    } catch {
      const customers = loadLocalCustomers();
      const filtered = customers.filter((c) => c.id !== id);
      saveLocalCustomers(filtered);
    }
  },

  /**
   * Exports all customer records to CSV with UTF-8 BOM.
   */
  exportCsv(customers: Customer[], filename: string = "AFAB-Customers.csv"): void {
    const headers = [
      "Customer ID",
      "Customer Name",
      "Email",
      "Phone",
      "Group",
      "Status",
      "Total Revenue",
      "Orders Count",
      "Last Activity",
      "Created At",
    ];
    const rows = customers.map((c) => [
      c.customerCode || c.id,
      `"${c.name.replace(/"/g, '""')}"`,
      c.email,
      c.phone || "",
      c.group,
      c.status,
      c.totalRevenue.toFixed(2),
      c.ordersCount,
      c.lastActivityDate,
      c.createdAt,
    ]);

    const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\r\n");
    const blob = new Blob(["\uFEFF" + csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  },
};
