import { fetchClient } from "./client";

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

export interface CategoryItem {
  id: string;
  name: string;
  type: string;
  icon: string;
  color: string;
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
}

export class TransactionService {
  static async getTransactions(params?: {
    type?: string;
    categoryId?: string;
    search?: string;
    page?: number;
    size?: number;
  }): Promise<TransactionResponse> {
    const query = new URLSearchParams();
    if (params?.type) query.append("type", params.type);
    if (params?.categoryId) query.append("categoryId", params.categoryId);
    if (params?.search) query.append("search", params.search);
    if (params?.page !== undefined) query.append("page", params.page.toString());
    if (params?.size !== undefined) query.append("size", params.size.toString());

    const queryString = query.toString();
    const endpoint = `/transactions${queryString ? `?${queryString}` : ""}`;
    return await fetchClient(endpoint);
  }

  static async getCategories(): Promise<CategoryItem[]> {
    return await fetchClient("/transactions/categories");
  }

  static async createTransaction(payload: CreateTransactionPayload): Promise<TransactionItem> {
    return await fetchClient("/transactions", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async deleteTransaction(id: string): Promise<void> {
    return await fetchClient(`/transactions/${id}`, {
      method: "DELETE",
    });
  }
}
