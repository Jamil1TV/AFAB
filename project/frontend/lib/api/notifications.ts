import { fetchClient, fetchCachedClient } from "./client";

export interface NotificationItem {
  id: string;
  type: string;
  severity: "INFO" | "SUCCESS" | "WARNING" | "ERROR";
  title: string;
  message: string;
  actionUrl?: string | null;
  read: boolean;
  readAt?: string | null;
  createdAt: string;
}

export interface NotificationsResponse {
  unreadCount: number;
  notifications: NotificationItem[];
}

export class NotificationService {
  static async list(force: boolean = false): Promise<NotificationsResponse> {
    return fetchCachedClient("/notifications", { ttlMs: 15_000, force });
  }

  static async markAsRead(id: string): Promise<NotificationsResponse> {
    return fetchClient(`/notifications/${id}/read`, {
      method: "PUT",
    });
  }

  static async markAllAsRead(): Promise<NotificationsResponse> {
    return fetchClient("/notifications/read-all", {
      method: "PUT",
    });
  }
}
