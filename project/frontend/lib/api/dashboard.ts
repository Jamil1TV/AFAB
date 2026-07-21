import { fetchClient } from "./client";

export class DashboardService {
  static async getSummary() {
    return fetchClient("/dashboard/summary");
  }
}

export class UserService {
  static async getProfile() {
    return fetchClient("/user/me");
  }
}
