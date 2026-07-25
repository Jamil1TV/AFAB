import { fetchClient } from "./client";

export class DashboardService {
  static async getSummary() {
    return await fetchClient("/dashboard/summary");
  }
}

export interface UserProfile {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  workspaceName: string;
  planType: string;
  avatarUrl?: string;
  enableAiInsights?: boolean;
  compactMode?: boolean;
  autoCategorizeTransactions?: boolean;
  showTips?: boolean;
}

export interface BusinessProfile {
  id?: string;
  name: string;
  country?: string;
  currency?: string;
  timezone?: string;
  fiscalYearStartMonth?: number;
  industry?: string;
  businessType?: string;
  businessEmail?: string;
  phoneNumber?: string;
  website?: string;
  taxId?: string;
  addressLine?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  description?: string;
  logoUrl?: string;
  status?: string;
  onboardingComplete?: boolean;
  dateFormat?: string;
  numberFormat?: string;
}

export class UserService {
  static async getProfile() {
    try {
      return await fetchClient("/user/me");
    } catch (error) {
      console.error("[AFAB] Failed to fetch user profile", error);
      throw error;
    }
  }
}
