import { fetchClient } from "./client";

// ── Mock data for UI testing when backend is unavailable ──
const MOCK_DASHBOARD_DATA = {
  kpiData: {
    revenue: { value: "$48,350", change: "+12.5%", isPositive: true },
    expenses: { value: "$18,200", change: "-3.2%", isPositive: true },
    profit: { value: "$30,150", change: "+18.7%", isPositive: true },
    cashFlow: { value: "$25,400", change: "+8.1%", isPositive: true },
  },
  revenueData: [
    { month: "Jan", revenue: 18000, expenses: 12000 },
    { month: "Feb", revenue: 22000, expenses: 14000 },
    { month: "Mar", revenue: 19500, expenses: 11000 },
    { month: "Apr", revenue: 28000, expenses: 15000 },
    { month: "May", revenue: 32000, expenses: 16500 },
    { month: "Jun", revenue: 48350, expenses: 18200 },
  ],
  transactions: [
    { id: 1, description: "Client Payment - Al Futtaim", amount: "+$12,500", date: "Jul 20", type: "income" },
    { id: 2, description: "Office Rent", amount: "-$3,200", date: "Jul 18", type: "expense" },
    { id: 3, description: "Software Licenses", amount: "-$890", date: "Jul 15", type: "expense" },
    { id: 4, description: "Consulting Fee - Emaar", amount: "+$8,750", date: "Jul 12", type: "income" },
    { id: 5, description: "Marketing Campaign", amount: "-$2,100", date: "Jul 10", type: "expense" },
  ],
  expenseCategories: [
    { name: "Operations", amount: "$7,200", percentage: 39.5, color: "#8b5cf6" },
    { name: "Marketing", amount: "$4,100", percentage: 22.5, color: "#06b6d4" },
    { name: "Salaries", amount: "$3,800", percentage: 20.9, color: "#f59e0b" },
    { name: "Software", amount: "$1,900", percentage: 10.4, color: "#10b981" },
    { name: "Other", amount: "$1,200", percentage: 6.6, color: "#6b7280" },
  ],
  reminders: [
    { id: 1, title: "VAT Filing Due", date: "Jul 25", priority: "high" },
    { id: 2, title: "Client Invoice #1042", date: "Jul 28", priority: "medium" },
    { id: 3, title: "Annual Audit Prep", date: "Aug 5", priority: "low" },
  ],
  customers: [
    { id: 1, name: "Al Futtaim Group", revenue: 45200, avatar: "https://i.pravatar.cc/150?u=alfuttaim" },
    { id: 2, name: "Emaar Properties", revenue: 38750, avatar: "https://i.pravatar.cc/150?u=emaar" },
    { id: 3, name: "Dubai Holdings", revenue: 29100, avatar: "https://i.pravatar.cc/150?u=dubaihold" },
    { id: 4, name: "Majid Al Futtaim", revenue: 22800, avatar: "https://i.pravatar.cc/150?u=majidf" },
  ],
};

const MOCK_USER_PROFILE = {
  id: 1,
  name: "Ahmed J.",
  email: "ahmed@acme.com",
  workspaceName: "Acme Corp",
  planType: "Free Plan",
};

export class DashboardService {
  static async getSummary() {
    try {
      return await fetchClient("/dashboard/summary");
    } catch {
      // Return mock data when backend is unavailable
      console.warn("[AFAB] Backend unavailable — using mock dashboard data");
      return MOCK_DASHBOARD_DATA;
    }
  }
}

export class UserService {
  static async getProfile() {
    try {
      return await fetchClient("/user/me");
    } catch {
      // Return mock profile when backend is unavailable
      console.warn("[AFAB] Backend unavailable — using mock user profile");
      return MOCK_USER_PROFILE;
    }
  }
}
