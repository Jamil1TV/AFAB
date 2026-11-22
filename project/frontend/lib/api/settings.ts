import { fetchClient } from "./client";

export class SettingsService {
  static async getMyBusiness() {
    return fetchClient("/business/mine");
  }

  static async updateBusiness(businessId: string, data: Record<string, unknown>) {
    return fetchClient(`/business/${businessId}`, {
      method: "PUT",
      body: JSON.stringify(data),
    });
  }

  static async getProfile() {
    return fetchClient("/user/me");
  }

  static async updateProfile(data: Record<string, unknown>) {
    return fetchClient("/user/me", {
      method: "PUT",
      body: JSON.stringify(data),
    });
  }

  static async changePassword(currentPassword: string, newPassword: string) {
    return fetchClient("/auth/change-password", {
      method: "POST",
      body: JSON.stringify({ currentPassword, newPassword }),
    });
  }

  static async getSessions() {
    return fetchClient("/user/me/sessions");
  }

  static async revokeSession(tokenId: string) {
    return fetchClient(`/user/me/sessions/${tokenId}`, {
      method: "DELETE",
    });
  }

  static async revokeAllSessions() {
    return fetchClient("/user/me/sessions", {
      method: "DELETE",
    });
  }

  static async exportMyData(): Promise<{
    filename: string;
    summary: {
      businessesCount: number;
      categoriesCount: number;
      transactionsCount: number;
      activeSessionsCount: number;
    };
  }> {
    const data = await fetchClient("/user/me/export", {
      method: "GET",
    });

    const today = new Date().toISOString().slice(0, 10);
    const filename = `afab-account-export-${today}.json`;

    if (typeof window !== "undefined") {
      const jsonString = JSON.stringify(data, null, 2);
      const blob = new Blob([jsonString], { type: "application/json;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    }

    return {
      filename,
      summary: data?.summary || {
        businessesCount: 0,
        categoriesCount: 0,
        transactionsCount: 0,
        activeSessionsCount: 0,
      },
    };
  }

  static async deleteAccount(confirmation: string) {
    return fetchClient("/user/me", {
      method: "DELETE",
      body: JSON.stringify({ confirmation }),
    });
  }
}
