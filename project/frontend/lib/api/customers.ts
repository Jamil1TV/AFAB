import { fetchClient, ApiError } from "./client";

export type CustomerGroup = "Standard" | "Business" | "Premium" | "Enterprise";
export type CustomerStatus = "Active" | "Inactive" | "New" | "Lead" | "Archived";
export type OrderStatus = "COMPLETED" | "PENDING" | "PROCESSING" | "CANCELLED" | "PAID" | "PARTIALLY_PAID" | "UNPAID" | "OVERDUE" | "DRAFT" | "SENT";

export interface CustomerOrder {
  id: string;
  orderNumber: string;
  customerId: string;
  amount: number;
  status: OrderStatus;
  orderDate: string;
  description: string;
  paymentMethod?: string;
  invoiceNumber?: string;
  createdAt: string;
}

export interface Customer {
  id: string;
  customerCode: string;
  businessId: string;
  name: string;
  companyName?: string;
  email: string;
  phone?: string;
  group: CustomerGroup;
  status: CustomerStatus;
  totalRevenue: number;
  invoicedAmount?: number;
  outstandingBalance?: number;
  ordersCount: number;
  orders?: CustomerOrder[];
  lastActivityDate: string;
  address?: string;
  notes?: string;
  createdAt: string;
  updatedAt?: string;
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
  companyName?: string;
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
  companyName?: string;
  email?: string;
  customerCode?: string;
  phone?: string;
  group?: CustomerGroup;
  status?: CustomerStatus;
  address?: string;
  notes?: string;
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
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function hydrateCustomer(c: Customer): Customer {
  return {
    ...c,
    totalRevenue: Number(c.totalRevenue) || 0,
    invoicedAmount: Number(c.invoicedAmount) || 0,
    outstandingBalance: Number(c.outstandingBalance) || 0,
    ordersCount: Number(c.ordersCount) || 0,
    orders: Array.isArray(c.orders) ? c.orders : [],
    avatarColor: c.avatarColor || getAvatarColor(c.name || "C"),
  };
}

/**
 * Customer API Client — backed strictly by `/api/v1/customers`.
 * Never falls back to localStorage or synthetic data on backend failure.
 */
export const CustomerService = {
  async getCustomers(params: CustomerFilterParams = {}): Promise<CustomerPageResponse> {
    const {
      search = "",
      status = "",
      group = "",
      page = 0,
      size = 10,
      sortBy = "createdAt",
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

    const res: CustomerPageResponse = await fetchClient(`/customers?${query.toString()}`);
    return {
      ...res,
      content: (res.content || []).map(hydrateCustomer),
    };
  },

  async getSummary(period: string = "month", _currency?: string): Promise<CustomerSummaryDTO> {
    return await fetchClient(`/customers/summary?period=${encodeURIComponent(period)}`);
  },

  async getCustomerById(id: string): Promise<Customer> {
    const res: Customer = await fetchClient(`/customers/${id}`);
    return hydrateCustomer(res);
  },

  async createCustomer(req: CreateCustomerRequest): Promise<Customer> {
    const res: Customer = await fetchClient("/customers", {
      method: "POST",
      body: JSON.stringify(req),
    });
    return hydrateCustomer(res);
  },

  async updateCustomer(id: string, req: UpdateCustomerRequest): Promise<Customer> {
    const res: Customer = await fetchClient(`/customers/${id}`, {
      method: "PUT",
      body: JSON.stringify(req),
    });
    return hydrateCustomer(res);
  },

  /**
   * Creates a real Invoice linked to the customer instead of a synthetic localStorage order.
   */
  async addOrder(req: CreateOrderRequest): Promise<CustomerOrder> {
    const today = req.orderDate || new Date().toISOString().split("T")[0];
    const invoice = await fetchClient("/invoices", {
      method: "POST",
      body: JSON.stringify({
        customerId: req.customerId,
        issueDate: today,
        dueDate: today,
        notes: req.description,
        items: [
          {
            description: req.description || "Customer Invoice Item",
            quantity: 1,
            unitPrice: Number(req.amount) || 0,
            taxRate: 0,
          },
        ],
      }),
    });

    // If caller requested immediate completion, issue and record a real payment
    if (req.status === "COMPLETED" || req.status === "PAID") {
      await fetchClient(`/invoices/${invoice.id}/issue`, { method: "POST" });
      await fetchClient(`/invoices/${invoice.id}/payments`, {
        method: "POST",
        headers: {
          "Idempotency-Key": `cust-order-${invoice.id}`,
        },
        body: JSON.stringify({
          amount: Number(req.amount) || 0,
          paymentDate: today,
          paymentMethod: req.paymentMethod === "CREDIT_CARD" || req.paymentMethod === "STRIPE"
            ? "CARD"
            : (req.paymentMethod || "BANK_TRANSFER"),
          reference: req.orderNumber || invoice.invoiceNumber,
        }),
      });
    }

    return {
      id: invoice.id,
      orderNumber: invoice.invoiceNumber,
      customerId: req.customerId,
      amount: Number(invoice.totalAmount ?? req.amount) || 0,
      status: req.status === "COMPLETED" ? "PAID" : (invoice.status || "DRAFT"),
      orderDate: invoice.issueDate || today,
      description: req.description,
      paymentMethod: req.paymentMethod || "BANK_TRANSFER",
      invoiceNumber: invoice.invoiceNumber,
      createdAt: invoice.createdAt || new Date().toISOString(),
    };
  },

  async deleteCustomer(id: string): Promise<void> {
    await fetchClient(`/customers/${id}`, {
      method: "DELETE",
    });
  },

  exportCsv(customers: Customer[], filename: string = "AFAB-Customers.csv"): void {
    const headers = [
      "Customer ID",
      "Customer Name",
      "Company",
      "Email",
      "Phone",
      "Group",
      "Status",
      "Total Paid Revenue",
      "Invoices Count",
      "Last Activity",
      "Created At",
    ];
    const rows = customers.map((c) => [
      c.customerCode || c.id,
      `"${(c.name || "").replace(/"/g, '""')}"`,
      `"${(c.companyName || "").replace(/"/g, '""')}"`,
      c.email || "",
      c.phone || "",
      c.group,
      c.status,
      (Number(c.totalRevenue) || 0).toFixed(2),
      c.ordersCount,
      c.lastActivityDate || "",
      c.createdAt || "",
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

export { ApiError };
