import { fetchClient } from "./client";

export type RecurrenceFrequency = "WEEKLY" | "MONTHLY" | "QUARTERLY" | "YEARLY";

export interface RecurringTransactionItem {
  id: string;
  businessId: string;
  type: "INCOME" | "EXPENSE";
  description: string;
  amount: number;
  currency: string;
  categoryId?: string | null;
  categoryName?: string | null;
  paymentMethod: string;
  frequency: RecurrenceFrequency;
  startDate: string;
  endDate?: string | null;
  nextExecutionDate: string;
  active: boolean;
  notes?: string | null;
  lastExecutedAt?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface RecurringTransactionPayload {
  type: "INCOME" | "EXPENSE";
  description: string;
  amount: number;
  currency?: string;
  categoryId?: string | null;
  paymentMethod?: string;
  frequency: RecurrenceFrequency;
  startDate: string;
  endDate?: string | null;
  active?: boolean;
  notes?: string | null;
}

export interface RecurringRunResult {
  rule: RecurringTransactionItem;
  generatedCount: number;
  transactionIds: string[];
}

export class RecurringTransactionApi {
  static async list(): Promise<RecurringTransactionItem[]> {
    return await fetchClient("/recurring-transactions");
  }

  static async create(payload: RecurringTransactionPayload): Promise<RecurringTransactionItem> {
    return await fetchClient("/recurring-transactions", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async update(id: string, payload: RecurringTransactionPayload): Promise<RecurringTransactionItem> {
    return await fetchClient(`/recurring-transactions/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  }

  static async setActive(id: string, active: boolean): Promise<RecurringTransactionItem> {
    return await fetchClient(`/recurring-transactions/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ active }),
    });
  }

  static async runDue(id: string): Promise<RecurringRunResult> {
    return await fetchClient(`/recurring-transactions/${id}/run-due`, {
      method: "POST",
    });
  }

  static async delete(id: string): Promise<void> {
    await fetchClient(`/recurring-transactions/${id}`, {
      method: "DELETE",
    });
  }
}
