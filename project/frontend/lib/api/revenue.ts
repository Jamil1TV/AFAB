import { fetchClient } from "./client";

export interface RevenueSummaryResponse {
  totalRevenue: number;
  grossRevenue: number;
  discounts: number;
  refunds: number;
  netRevenue: number;
  avgPerDay: number;
  highestRevenueAmount: number;
  highestRevenueDate: string;
  totalInvoices: number;
  currency: string;
  revenueBySource: {
    name: string;
    amount: number;
    percentage: number;
    color: string;
  }[];
  topProducts: {
    name: string;
    amount: number;
    percentage: number;
    color: string;
  }[];
  dailyOverview: {
    date: string;
    amount: number;
  }[];
}

export class RevenueService {
  static async getSummary(): Promise<RevenueSummaryResponse> {
    return await fetchClient("/revenue/summary");
  }

  static async getRevenue(params?: { categoryId?: string; search?: string; page?: number; size?: number }) {
    const query = new URLSearchParams();
    if (params?.categoryId) query.append("categoryId", params.categoryId);
    if (params?.search) query.append("search", params.search);
    if (params?.page !== undefined) query.append("page", params.page.toString());
    if (params?.size !== undefined) query.append("size", params.size.toString());

    const queryString = query.toString();
    return await fetchClient(`/revenue${queryString ? `?${queryString}` : ""}`);
  }
}
