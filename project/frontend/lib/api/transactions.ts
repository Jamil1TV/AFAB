import { fetchClient } from "./client";
import { CategoryItem } from "./categories";
export type { CategoryItem };

export interface SplitItem {
  id: string;
  categoryId?: string;
  categoryName: string;
  categoryColor: string;
  categoryIcon: string;
  amount: number;
  description?: string;
}

export interface SplitRequestItem {
  categoryId: string;
  amount: number;
  description?: string;
}

export interface TransactionItem {
  id: string;
  type: "INCOME" | "EXPENSE";
  amount: number;
  currency: string;
  description: string;
  transactionDate: string;
  paymentMethod: string;
  status: string;
  categoryName: string;
  categoryColor: string;
  categoryIcon: string;
  categoryId?: string;
  notes?: string;
  taxDeductible?: boolean;
  taxRate?: number;
  isSplit?: boolean;
  parentTransactionId?: string;
  potentialDuplicate?: boolean;
  priceHikePercentage?: number;
  splitItems?: SplitItem[];
  createdAt?: string;
  updatedAt?: string;
}

export interface TransactionResponse {
  content: TransactionItem[];
  pageNumber: number;
  pageSize: number;
  totalElements: number;
  totalPages: number;
  totalInflow: number;
  totalOutflow: number;
  netBalance: number;
  currency: string;
}

export interface CreateTransactionPayload {
  type: "INCOME" | "EXPENSE";
  amount: number;
  description: string;
  transactionDate: string;
  categoryId?: string;
  paymentMethod?: string;
  status?: string;
  notes?: string;
  taxDeductible?: boolean;
  taxRate?: number;
  splitItems?: SplitRequestItem[];
}

export interface UpdateTransactionPayload {
  type?: "INCOME" | "EXPENSE";
  amount?: number;
  description?: string;
  transactionDate?: string;
  categoryId?: string;
  paymentMethod?: string;
  status?: string;
  notes?: string;
  taxDeductible?: boolean;
  taxRate?: number;
  splitItems?: SplitRequestItem[];
}

export interface TransactionFilterParams {
  type?: string;
  categoryId?: string;
  status?: string;
  paymentMethod?: string;
  taxDeductible?: boolean;
  startDate?: string;
  endDate?: string;
  search?: string;
  page?: number;
  size?: number;
}

export class TransactionService {
  static async getTransactions(params?: TransactionFilterParams): Promise<TransactionResponse> {
    const query = new URLSearchParams();
    if (params?.type) query.append("type", params.type);
    if (params?.categoryId) query.append("categoryId", params.categoryId);
    if (params?.status) query.append("status", params.status);
    if (params?.paymentMethod) query.append("paymentMethod", params.paymentMethod);
    if (params?.taxDeductible !== undefined) query.append("taxDeductible", params.taxDeductible.toString());
    if (params?.startDate) query.append("startDate", params.startDate);
    if (params?.endDate) query.append("endDate", params.endDate);
    if (params?.search) query.append("search", params.search);
    if (params?.page !== undefined) query.append("page", params.page.toString());
    if (params?.size !== undefined) query.append("size", params.size.toString());

    const queryString = query.toString();
    const endpoint = `/transactions${queryString ? `?${queryString}` : ""}`;
    return await fetchClient(endpoint);
  }

  static async getCategories(): Promise<CategoryItem[]> {
    return await fetchClient("/categories");
  }

  static async createTransaction(payload: CreateTransactionPayload): Promise<TransactionItem> {
    return await fetchClient("/transactions", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async updateTransaction(id: string, payload: UpdateTransactionPayload): Promise<TransactionItem> {
    return await fetchClient(`/transactions/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  }

  static async deleteTransaction(id: string): Promise<void> {
    return await fetchClient(`/transactions/${id}`, {
      method: "DELETE",
    });
  }
}
