import { fetchClient } from "./client";

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

export class InvoiceService {
  static async getSummary(): Promise<InvoiceSummaryResponse> {
    return await fetchClient("/invoices/summary");
  }

  static async getInvoices(params?: { categoryId?: string; search?: string; page?: number; size?: number }) {
    const query = new URLSearchParams();
    if (params?.categoryId) query.append("categoryId", params.categoryId);
    if (params?.search) query.append("search", params.search);
    if (params?.page !== undefined) query.append("page", params.page.toString());
    if (params?.size !== undefined) query.append("size", params.size.toString());

    const queryString = query.toString();
    return await fetchClient(`/invoices${queryString ? `?${queryString}` : ""}`);
  }
}
