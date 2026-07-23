import { fetchClient } from "./client";

export class SettingsService {
  static async getMyBusiness() {
    return fetchClient("/business/mine");
  }

  static async updateBusiness(businessId: string, data: Record<string, any>) {
    return fetchClient(`/business/${businessId}`, {
      method: "PUT",
      body: JSON.stringify(data),
    });
  }

  static async getProfile() {
    return fetchClient("/user/me");
  }

  static async updateProfile(data: Record<string, any>) {
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
}
