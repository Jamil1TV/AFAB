import { fetchClient } from "./client";

export interface CategoryItem {
  id: string;
  businessId?: string | null;
  name: string;
  type: "INCOME" | "EXPENSE";
  icon?: string;
  color?: string;
  isSystemDefault?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateCategoryPayload {
  name: string;
  type: "INCOME" | "EXPENSE";
  icon?: string;
  color?: string;
}

export interface UpdateCategoryPayload {
  name?: string;
  icon?: string;
  color?: string;
}

export class CategoryService {
  static async getCategories(): Promise<CategoryItem[]> {
    return await fetchClient("/categories");
  }

  static async createCategory(payload: CreateCategoryPayload): Promise<CategoryItem> {
    return await fetchClient("/categories", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async updateCategory(id: string, payload: UpdateCategoryPayload): Promise<CategoryItem> {
    return await fetchClient(`/categories/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  }

  static async deleteCategory(id: string): Promise<void> {
    return await fetchClient(`/categories/${id}`, {
      method: "DELETE",
    });
  }
}
