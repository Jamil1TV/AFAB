import { fetchClient } from "./client";

export interface KpiMetric {
  value: string;
  change: string;
  isPositive: boolean;
  rawValue?: number;
  rawChange?: number;
}

export interface KpiData {
  revenue: KpiMetric;
  expenses: KpiMetric;
  profit: KpiMetric;
  cashFlow: KpiMetric;
}

export interface RevenueDataPoint {
  month: string;
  name: string;
  revenue: number;
  expenses: number;
}

export interface DashboardTransactionItem {
  id: string;
  name: string;
  description: string;
  amount: string;
  rawAmount?: number;
  date: string;
  type: string;
  status: string;
  color?: string;
  initials?: string;
  isCredit?: boolean;
}

export interface ExpenseCategory {
  name: string;
  amount: string;
  value: number;
  percentage: number;
  color: string;
}

export interface ReminderItem {
  id: string;
  title: string;
  date: string;
  priority: string;
  type?: string;
}

export interface CustomerItem {
  id: string;
  name: string;
  revenue: number;
  avatar?: string;
}

export interface DashboardSummaryResponse {
  kpiData: KpiData;
  revenueData: RevenueDataPoint[];
  transactions: DashboardTransactionItem[];
  expenseCategories: ExpenseCategory[];
  reminders: ReminderItem[];
  customers: CustomerItem[];
  currency: string;
  businessName: string;
}

export class DashboardService {
  static async getSummary(period?: string): Promise<DashboardSummaryResponse> {
    const query = period ? `?period=${encodeURIComponent(period)}` : "";
    return await fetchClient(`/dashboard/summary${query}`);
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
