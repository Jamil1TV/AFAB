/**
 * Empty baseline export — all production AFAB pages fetch real data from
 * backend APIs (`/api/v1/*`) or authenticated user/business records.
 * No fabricated financial numbers, transactions, customers, or reminders are exported.
 */
export const MOCK_REVENUE_DATA: Array<{ name: string; revenue: number; expenses: number }> = [];

export const MOCK_KPI_DATA = {
  revenue: { value: "0.00", change: "0.0%", isPositive: true },
  expenses: { value: "0.00", change: "0.0%", isPositive: true },
  profit: { value: "0.00", change: "0.0%", isPositive: true },
  cashFlow: { value: "0.00", change: "0.0%", isPositive: true },
};

export const MOCK_TRANSACTIONS: Array<Record<string, unknown>> = [];
export const MOCK_EXPENSE_CATEGORIES: Array<Record<string, unknown>> = [];
export const MOCK_REMINDERS: Array<Record<string, unknown>> = [];
export const MOCK_CUSTOMERS: Array<Record<string, unknown>> = [];
