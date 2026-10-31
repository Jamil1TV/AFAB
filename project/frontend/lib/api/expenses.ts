import { fetchClient } from "./client";

export interface ExpenseSummaryResponse {
  totalExpenses: number;
  avgPerDay: number;
  highestExpenseTitle: string;
  highestExpenseAmount: number;
  categoryCount: number;
  recurringTotal: number;
  recurringPercentage: number;
  currency: string;
  categoryBreakdown: {
    name: string;
    amount: number;
    percentage: number;
    color: string;
  }[];
  recurringList: {
    name: string;
    amount: number;
    billingCycle: string;
    dueDate: string;
    icon: string;
  }[];
  dailyOverview: {
    date: string;
    amount: number;
  }[];
}

export class ExpenseService {
  static async getSummary(period?: string): Promise<ExpenseSummaryResponse> {
    const query = period ? `?period=${encodeURIComponent(period.toLowerCase())}` : "";
    return await fetchClient(`/expenses/summary${query}`);
  }

  static async getExpenses(params?: { categoryId?: string; search?: string; page?: number; size?: number }) {
    const query = new URLSearchParams();
    if (params?.categoryId) query.append("categoryId", params.categoryId);
    if (params?.search) query.append("search", params.search);
    if (params?.page !== undefined) query.append("page", params.page.toString());
    if (params?.size !== undefined) query.append("size", params.size.toString());

    const queryString = query.toString();
    return await fetchClient(`/expenses${queryString ? `?${queryString}` : ""}`);
  }
}
