import { fetchClient } from "./client";

export type BudgetPeriodType = "MONTHLY" | "QUARTERLY" | "YEARLY" | "CUSTOM";
export type BudgetAlertLevel = "OK" | "APPROACHING" | "OVER_BUDGET";

export interface BudgetItem {
  id: string;
  businessId: string;
  name: string;
  budgetAmount: number;
  currency: string;
  categoryId?: string | null;
  categoryName: string;
  categoryColor: string;
  periodType: BudgetPeriodType;
  startDate: string;
  endDate: string;
  alertThresholdPercent: number;
  description?: string | null;
  status: string;
  actualSpending: number;
  remainingAmount: number;
  overBudgetAmount: number;
  percentageConsumed: number;
  alertLevel: BudgetAlertLevel;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface BudgetSummary {
  currency: string;
  activeBudgetCount: number;
  approachingCount: number;
  overBudgetCount: number;
  totalBudgeted: number;
  totalSpent: number;
  totalRemaining: number;
  budgets: BudgetItem[];
}

export interface BudgetPayload {
  name: string;
  amount: number;
  currency?: string;
  categoryId?: string | null;
  periodType: BudgetPeriodType;
  startDate?: string | null;
  endDate?: string | null;
  alertThresholdPercent?: number;
  description?: string | null;
}

export class BudgetApi {
  static async list(includeArchived = false): Promise<BudgetItem[]> {
    return await fetchClient(`/budgets?includeArchived=${includeArchived}`);
  }

  static async getSummary(): Promise<BudgetSummary> {
    return await fetchClient("/budgets/summary");
  }

  static async create(payload: BudgetPayload): Promise<BudgetItem> {
    return await fetchClient("/budgets", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async update(id: string, payload: BudgetPayload): Promise<BudgetItem> {
    return await fetchClient(`/budgets/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  }

  static async archive(id: string): Promise<void> {
    await fetchClient(`/budgets/${id}`, {
      method: "DELETE",
    });
  }
}
