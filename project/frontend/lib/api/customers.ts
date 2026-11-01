import { fetchClient, ApiError } from "./client";
import { AuthStore } from "@/lib/auth-store";

export type CustomerGroup = "Standard" | "Business" | "Premium" | "Enterprise";
export type CustomerStatus = "Active" | "Inactive" | "New" | "Lead";
export type OrderStatus = "COMPLETED" | "PENDING" | "PROCESSING" | "CANCELLED";

export interface CustomerOrder {
  id: string;
  orderNumber: string; // e.g. "ORD-2024-001"
  customerId: string;
  amount: number;
  status: OrderStatus;
  orderDate: string; // YYYY-MM-DD
  description: string;
  paymentMethod?: string; // "BANK_TRANSFER" | "CREDIT_CARD" | "CASH" | "STRIPE"
  invoiceNumber?: string; // e.g. "INV-2024-089"
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

// Color palette generator for consistent avatars matching the Stitch design
const AVATAR_COLORS = [
  "bg-purple-500/20 text-purple-400 border-purple-500/30",
  "bg-orange-500/20 text-orange-400 border-orange-500/30",
  "bg-blue-500/20 text-blue-400 border-blue-500/30",
  "bg-emerald-500/20 text-emerald-400 border-emerald-500/30",
  "bg-pink-500/20 text-pink-400 border-pink-500/30",
  "bg-indigo-500/20 text-indigo-400 border-indigo-500/30",
  "bg-teal-500/20 text-teal-400 border-teal-500/30",
  "bg-amber-500/20 text-amber-400 border-amber-500/30",
];

function getAvatarColor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  const index = Math.abs(hash) % AVATAR_COLORS.length;
  return AVATAR_COLORS[index];
}

// Initial realistic seed dataset matching the Stitch high-fidelity mockup
function getInitialSeedData(businessId: string): Customer[] {
  return [
    {
      id: "cust-1",
      customerCode: "CST-1001",
      businessId,
      name: "AFAB Pro Plan",
      email: "info@afab.com",
      phone: "+1 (555) 123-4567",
      group: "Premium",
      status: "Active",
      totalRevenue: 12450.00,
      ordersCount: 24,
      lastActivityDate: "2024-05-18",
      address: "San Francisco, CA, USA",
      notes: "Annual corporate subscription with 10 team seats.",
      createdAt: "2023-11-12",
      avatarColor: AVATAR_COLORS[0],
      orders: [
        {
          id: "ord-101",
          orderNumber: "ORD-2024-001",
          customerId: "cust-1",
          amount: 4500.00,
          status: "COMPLETED",
          orderDate: "2024-05-18",
          description: "Enterprise Subscription Renewal (Q2)",
          paymentMethod: "BANK_TRANSFER",
          invoiceNumber: "INV-2024-089",
          createdAt: "2024-05-18T10:00:00Z"
        },
        {
          id: "ord-102",
          orderNumber: "ORD-2024-002",
          customerId: "cust-1",
          amount: 2950.00,
          status: "COMPLETED",
          orderDate: "2024-04-12",
          description: "Priority AI Analytics Quota Expansion",
          paymentMethod: "STRIPE",
          invoiceNumber: "INV-2024-064",
          createdAt: "2024-04-12T14:30:00Z"
        }
      ]
    },
    {
      id: "cust-2",
      customerCode: "CST-1002",
      businessId,
      name: "AI Assistant Add-on",
      email: "billing@aiassist.com",
      phone: "+1 (555) 987-6543",
      group: "Business",
      status: "Active",
      totalRevenue: 8750.00,
      ordersCount: 18,
      lastActivityDate: "2024-05-17",
      address: "Austin, TX, USA",
      notes: "Custom quota expansion package.",
      createdAt: "2024-01-15",
      avatarColor: AVATAR_COLORS[1],
      orders: [
        {
          id: "ord-201",
          orderNumber: "ORD-2024-015",
          customerId: "cust-2",
          amount: 875.00,
          status: "COMPLETED",
          orderDate: "2024-05-17",
          description: "Monthly Intelligence Engine API Quota",
          paymentMethod: "CREDIT_CARD",
          invoiceNumber: "INV-2024-088",
          createdAt: "2024-05-17T09:00:00Z"
        }
      ]
    },
    {
      id: "cust-3",
      customerCode: "CST-1003",
      businessId,
      name: "Financial Reports",
      email: "finance@reports.com",
      phone: "+1 (555) 456-7890",
      group: "Standard",
      status: "Active",
      totalRevenue: 6320.00,
      ordersCount: 15,
      lastActivityDate: "2024-05-16",
      address: "New York, NY, USA",
      notes: "Standard monthly reporting subscription.",
      createdAt: "2024-02-01",
      avatarColor: AVATAR_COLORS[2],
      orders: [
        {
          id: "ord-301",
          orderNumber: "ORD-2024-021",
          customerId: "cust-3",
          amount: 2450.00,
          status: "COMPLETED",
          orderDate: "2024-05-16",
          description: "Automated Fiscal Audit Statement Pack",
          paymentMethod: "BANK_TRANSFER",
          invoiceNumber: "INV-2024-082",
          createdAt: "2024-05-16T11:20:00Z"
        }
      ]
    },
    {
      id: "cust-4",
      customerCode: "CST-1004",
      businessId,
      name: "Consulting Service",
      email: "contact@consult.com",
      phone: "+1 (555) 321-0987",
      group: "Premium",
      status: "Active",
      totalRevenue: 5980.00,
      ordersCount: 11,
      lastActivityDate: "2024-05-15",
      address: "London, UK",
      notes: "Strategic financial advisory retainer.",
      createdAt: "2024-02-14",
      avatarColor: AVATAR_COLORS[3],
      orders: [
        {
          id: "ord-401",
          orderNumber: "ORD-2024-033",
          customerId: "cust-4",
          amount: 3200.00,
          status: "COMPLETED",
          orderDate: "2024-05-15",
          description: "Retainer Fee — Q2 Cash Flow Advisory",
          paymentMethod: "BANK_TRANSFER",
          invoiceNumber: "INV-2024-074",
          createdAt: "2024-05-15T16:45:00Z"
        }
      ]
    },
    {
      id: "cust-5",
      customerCode: "CST-1005",
      businessId,
      name: "Design Work",
      email: "hello@designhub.com",
      phone: "+1 (555) 654-3210",
      group: "Standard",
      status: "Inactive",
      totalRevenue: 4450.00,
      ordersCount: 9,
      lastActivityDate: "2024-05-10",
      address: "Berlin, Germany",
      notes: "UI/UX sprint deliverables.",
      createdAt: "2024-02-28",
      avatarColor: AVATAR_COLORS[4],
      orders: []
    },
    {
      id: "cust-6",
      customerCode: "CST-1006",
      businessId,
      name: "Web Development",
      email: "web@devstudio.com",
      phone: "+1 (555) 789-0123",
      group: "Business",
      status: "Active",
      totalRevenue: 3880.00,
      ordersCount: 8,
      lastActivityDate: "2024-05-09",
      address: "Toronto, Canada",
      notes: "Full-stack integration contract.",
      createdAt: "2024-03-05",
      avatarColor: AVATAR_COLORS[5],
      orders: []
    },
    {
      id: "cust-7",
      customerCode: "CST-1007",
      businessId,
      name: "Marketing Agency",
      email: "hello@marketing.com",
      phone: "+1 (555) 210-9876",
      group: "Standard",
      status: "Inactive",
      totalRevenue: 2950.00,
      ordersCount: 6,
      lastActivityDate: "2024-05-08",
      address: "Dubai, UAE",
      notes: "Q1 growth campaign.",
      createdAt: "2024-03-12",
      avatarColor: AVATAR_COLORS[6],
      orders: []
    },
    {
      id: "cust-8",
      customerCode: "CST-1008",
      businessId,
      name: "Software Solutions",
      email: "contact@softsol.com",
      phone: "+1 (555) 876-5432",
      group: "Premium",
      status: "Active",
      totalRevenue: 2450.00,
      ordersCount: 5,
      lastActivityDate: "2024-05-07",
      address: "Singapore",
      notes: "ERP data migration consulting.",
      createdAt: "2024-03-20",
      avatarColor: AVATAR_COLORS[7],
      orders: []
    },
    {
      id: "cust-9",
      customerCode: "CST-1009",
      businessId,
      name: "Global Logistics LLC",
      email: "ops@globallogistics.com",
      phone: "+1 (555) 345-6789",
      group: "Enterprise",
      status: "Active",
      totalRevenue: 15800.00,
      ordersCount: 32,
      lastActivityDate: "2024-05-18",
      address: "Rotterdam, Netherlands",
      notes: "Enterprise customs & multi-currency billing.",
      createdAt: "2023-10-05",
      avatarColor: AVATAR_COLORS[0],
      orders: []
    },
    {
      id: "cust-10",
      customerCode: "CST-1010",
      businessId,
      name: "Apex Retail Group",
      email: "accounts@apexretail.com",
      phone: "+1 (555) 678-9012",
      group: "Business",
      status: "Active",
      totalRevenue: 11820.00,
      ordersCount: 22,
      lastActivityDate: "2024-05-17",
      address: "Sydney, Australia",
      notes: "Point-of-sale receipt sync client.",
      createdAt: "2023-12-10",
      avatarColor: AVATAR_COLORS[1],
      orders: []
    }
  ];
}

// Storage helpers scoped by active business
function getStorageKey(): string {
  const activeBusinessId = AuthStore.getActiveBusinessId() || "default";
  return `afab_customers_${activeBusinessId}`;
}

function loadLocalCustomers(): Customer[] {
  if (typeof window === "undefined") return [];
  const key = getStorageKey();
  const raw = localStorage.getItem(key);
  if (!raw) {
    const activeBusinessId = AuthStore.getActiveBusinessId() || "default";
    const seed = getInitialSeedData(activeBusinessId);
    localStorage.setItem(key, JSON.stringify(seed));
    return seed;
  }
  try {
    const parsed: Customer[] = JSON.parse(raw);
    // Ensure legacy data gets customerCode and orders array
    let migrated = false;
    parsed.forEach((c, index) => {
      if (!c.customerCode) {
        c.customerCode = `CST-${1001 + index}`;
        migrated = true;
      }
      if (!c.orders) {
        c.orders = [];
        migrated = true;
      }
    });
    if (migrated) {
      localStorage.setItem(key, JSON.stringify(parsed));
    }
    return parsed;
  } catch {
    return [];
  }
}

function saveLocalCustomers(customers: Customer[]): void {
  if (typeof window === "undefined") return;
  const key = getStorageKey();
  localStorage.setItem(key, JSON.stringify(customers));
}

export const CustomerService = {
  /**
   * Retrieves paginated, filtered customers.
   * Tries backend first; falls back transparently to business-scoped local store.
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
      // Offline/Local data engine
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

      // Sort
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
   */
  async getSummary(period: string = "week", currency: string = "USD"): Promise<CustomerSummaryDTO> {
    try {
      return await fetchClient(`/customers/summary?period=${encodeURIComponent(period)}`);
    } catch {
      const customers = loadLocalCustomers();
      const totalCustomers = customers.length;
      const activeCount = customers.filter((c) => c.status === "Active").length;
      const inactiveCount = customers.filter((c) => c.status === "Inactive").length;
      const newCount = customers.filter((c) => c.status === "New" || c.status === "Lead").length;

      const totalRevenue = customers.reduce((acc, curr) => acc + (curr.totalRevenue || 0), 0);
      const avgRevenuePerCustomer = totalCustomers > 0 ? totalRevenue / totalCustomers : 0;
      const repeatCustomersCount = customers.filter((c) => c.ordersCount > 1).length;
      const repeatCustomersPct = totalCustomers > 0 ? Math.round((repeatCustomersCount / totalCustomers) * 100) : 0;

      // Top customers ordered by revenue
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

      // Generate activity log
      const recentActivity: CustomerActivityItem[] = [
        {
          id: "act-1",
          customerId: customers[0]?.id || "c1",
          customerName: customers[0]?.name || "Web Development",
          type: "NEW_CUSTOMER",
          description: "Customer account CST-1001 registered",
          timestamp: "2024-05-18T10:30:00Z",
        },
        {
          id: "act-2",
          customerId: customers[1]?.id || "c2",
          customerName: customers[1]?.name || "Financial Reports",
          type: "INVOICE_PAID",
          description: "Order #ORD-2024-001 ($4,500.00) completed",
          amount: 4500.00,
          timestamp: "2024-05-17T14:15:00Z",
        },
        {
          id: "act-3",
          customerId: customers[2]?.id || "c3",
          customerName: customers[2]?.name || "AI Assistant Add-on",
          type: "PAYMENT_RECEIVED",
          description: "Order #ORD-2024-015 ($875.00) received",
          amount: 875.00,
          timestamp: "2024-05-17T09:00:00Z",
        },
        {
          id: "act-4",
          customerId: customers[3]?.id || "c4",
          customerName: customers[3]?.name || "Consulting Service",
          type: "NEW_ORDER",
          description: "Order #ORD-2024-033 ($3,200.00) created",
          amount: 3200.00,
          timestamp: "2024-05-15T16:45:00Z",
        },
      ];

      return {
        totalCustomers,
        totalCustomersChangePct: 12.5,
        newCustomers: newCount > 0 ? newCount : 24,
        newCustomersChangePct: 8.4,
        totalRevenue,
        totalRevenueChangePct: 18.2,
        avgRevenuePerCustomer: Math.round(avgRevenuePerCustomer),
        avgRevenueChangePct: 6.7,
        repeatCustomersPct,
        repeatCustomersChangePct: 5.1,
        currency,
        overviewDonut: {
          activeCount,
          activePct: totalCustomers > 0 ? Math.round((activeCount / totalCustomers) * 100) : 68,
          inactiveCount,
          inactivePct: totalCustomers > 0 ? Math.round((inactiveCount / totalCustomers) * 100) : 22,
          newCount: totalCustomers > 0 ? totalCustomers - activeCount - inactiveCount : 10,
          newPct: totalCustomers > 0 ? Math.max(0, 100 - Math.round((activeCount / totalCustomers) * 100) - Math.round((inactiveCount / totalCustomers) * 100)) : 10,
        },
        topCustomers,
        recentActivity,
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
      const updated: Customer = {
        ...existing,
        ...req,
        name: req.name !== undefined ? req.name.trim() : existing.name,
        email: req.email !== undefined ? req.email.trim() : existing.email,
        customerCode: req.customerCode !== undefined ? req.customerCode.trim() : existing.customerCode,
        phone: req.phone !== undefined ? req.phone.trim() : existing.phone,
        avatarColor: req.name ? getAvatarColor(req.name) : existing.avatarColor,
      };

      customers[index] = updated;
      saveLocalCustomers(customers);
      return updated;
    }
  },

  /**
   * Adds an order to a customer.
   * Updates the customer's orders array, orders count, revenue, and activity feed.
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

      const newOrder: CustomerOrder = {
        id: `ord-${Date.now()}`,
        orderNumber,
        customerId: cust.id,
        amount: Number(req.amount) || 0,
        status: req.status,
        orderDate,
        description: req.description.trim() || `Order ${orderNumber}`,
        paymentMethod: req.paymentMethod || "BANK_TRANSFER",
        invoiceNumber: req.invoiceNumber || `INV-${orderYear}-${orderSeq}`,
        createdAt: new Date().toISOString(),
      };

      existingOrders.unshift(newOrder);
      cust.orders = existingOrders;
      cust.ordersCount = existingOrders.length;
      cust.lastActivityDate = orderDate;

      // Only add to total revenue if completed
      if (req.status === "COMPLETED") {
        cust.totalRevenue = (cust.totalRevenue || 0) + newOrder.amount;
      }

      customers[index] = cust;
      saveLocalCustomers(customers);
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
    const headers = ["Customer ID", "Customer Name", "Email", "Phone", "Group", "Status", "Total Revenue", "Orders Count", "Last Activity", "Created At"];
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
    // UTF-8 BOM
    const blob = new Blob(["\uFEFF" + csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  },
};
