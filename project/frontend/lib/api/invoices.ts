import { fetchClient } from "./client";

export type InvoiceStatusType =
  | "DRAFT"
  | "SENT"
  | "UNPAID"
  | "PARTIALLY_PAID"
  | "PAID"
  | "OVERDUE"
  | "CANCELLED";

export interface InvoiceItemDTO {
  id?: string;
  description: string;
  quantity: number;
  unitPrice: number;
  taxRate: number;
  lineSubtotal?: number;
  lineTax?: number;
  lineTotal?: number;
}

export interface InvoicePaymentDTO {
  id: string;
  invoiceId: string;
  incomeTransactionId: string;
  idempotencyKey: string;
  amount: number;
  currency: string;
  convertedBaseAmount: number;
  baseCurrency: string;
  exchangeRate: number;
  paymentDate: string;
  paymentMethod: string;
  reference?: string;
  notes?: string;
  createdAt: string;
}

export interface InvoiceDTO {
  id: string;
  businessId: string;
  invoiceNumber: string;
  customerId?: string | null;
  customerName?: string | null;
  customerEmail?: string | null;
  status: InvoiceStatusType;
  storedStatus: InvoiceStatusType;
  overdue: boolean;
  issueDate: string;
  dueDate: string;
  currency: string;
  subtotal: number;
  discountAmount: number;
  taxAmount: number;
  totalAmount: number;
  paidAmount: number;
  outstandingBalance: number;
  notes?: string | null;
  issuedAt?: string | null;
  cancelledAt?: string | null;
  createdAt: string;
  updatedAt?: string | null;
  items: InvoiceItemDTO[];
  payments: InvoicePaymentDTO[];
}

export interface InvoicePageResponse {
  content: InvoiceDTO[];
  pageNumber: number;
  pageSize: number;
  totalElements: number;
  totalPages: number;
  totalInvoiced: number;
  totalPaid: number;
  totalOutstanding: number;
  currency: string;
}

export interface InvoiceSummaryResponse {
  totalInvoices: number;
  paidInvoices: number;
  pendingInvoices: number;
  overdueInvoices: number;
  totalInvoiceAmount: number;
  paidAmount: number;
  pendingAmount: number;
  overdueAmount: number;
  currency: string;
  statusBreakdown: {
    name: string;
    amount: number;
    percentage: number;
    color: string;
  }[];
  upcomingDueList: {
    invoiceId: string;
    customerName: string;
    email: string;
    dueDate: string;
    amount: number;
  }[];
}

export interface CreateInvoicePayload {
  customerId?: string;
  issueDate: string;
  dueDate: string;
  currency?: string;
  discountAmount?: number;
  notes?: string;
  items: {
    description: string;
    quantity: number;
    unitPrice: number;
    taxRate?: number;
  }[];
}

export interface RecordPaymentPayload {
  amount: number;
  currency?: string;
  paymentDate: string;
  paymentMethod: string;
  reference?: string;
  notes?: string;
  idempotencyKey?: string;
}

export class InvoiceService {
  static async getSummary(period?: string): Promise<InvoiceSummaryResponse> {
    const query = period ? `?period=${encodeURIComponent(period.toLowerCase())}` : "";
    return await fetchClient(`/invoices/summary${query}`);
  }

  static async getInvoices(params?: {
    customerId?: string;
    status?: string;
    search?: string;
    page?: number;
    size?: number;
  }): Promise<InvoicePageResponse> {
    const query = new URLSearchParams();
    if (params?.customerId) query.append("customerId", params.customerId);
    if (params?.status && params.status !== "ALL") query.append("status", params.status);
    if (params?.search) query.append("search", params.search);
    if (params?.page !== undefined) query.append("page", params.page.toString());
    if (params?.size !== undefined) query.append("size", params.size.toString());

    const queryString = query.toString();
    return await fetchClient(`/invoices${queryString ? `?${queryString}` : ""}`);
  }

  static async getInvoiceById(id: string): Promise<InvoiceDTO> {
    return await fetchClient(`/invoices/${id}`);
  }

  static async createInvoice(payload: CreateInvoicePayload): Promise<InvoiceDTO> {
    return await fetchClient("/invoices", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async updateDraftInvoice(id: string, payload: CreateInvoicePayload): Promise<InvoiceDTO> {
    return await fetchClient(`/invoices/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  }

  static async issueInvoice(id: string, sent: boolean = false): Promise<InvoiceDTO> {
    return await fetchClient(`/invoices/${id}/issue?sent=${sent}`, {
      method: "POST",
    });
  }

  static async cancelInvoice(id: string): Promise<InvoiceDTO> {
    return await fetchClient(`/invoices/${id}/cancel`, {
      method: "POST",
    });
  }

  static async recordPayment(
    invoiceId: string,
    payload: RecordPaymentPayload,
    idempotencyKey: string
  ): Promise<InvoicePaymentDTO> {
    return await fetchClient(`/invoices/${invoiceId}/payments`, {
      method: "POST",
      headers: {
        "Idempotency-Key": idempotencyKey,
      },
      body: JSON.stringify({ ...payload, idempotencyKey }),
    });
  }

  static async getPayments(invoiceId: string): Promise<InvoicePaymentDTO[]> {
    return await fetchClient(`/invoices/${invoiceId}/payments`);
  }
}
