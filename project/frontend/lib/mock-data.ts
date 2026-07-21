export const MOCK_REVENUE_DATA = [
  { name: "Mon", revenue: 4000, expenses: 2400 },
  { name: "Tue", revenue: 3000, expenses: 1398 },
  { name: "Wed", revenue: 2000, expenses: 9800 },
  { name: "Thu", revenue: 2780, expenses: 3908 },
  { name: "Fri", revenue: 1890, expenses: 4800 },
  { name: "Sat", revenue: 2390, expenses: 3800 },
  { name: "Sun", revenue: 3490, expenses: 4300 },
];

export const MOCK_KPI_DATA = {
  revenue: { value: "$24,850.00", change: "+12.5%", isPositive: true },
  expenses: { value: "$9,420.00", change: "-8.4%", isPositive: false },
  profit: { value: "$15,430.00", change: "+33.4%", isPositive: true },
  cashFlow: { value: "$8,750.00", change: "+16.7%", isPositive: true },
};

export const MOCK_TRANSACTIONS = [
  { id: 1, name: "Stripe Payment", date: "May 18, 2024 - 10:40 AM", amount: "+$1,250.00", status: "Completed", isCredit: true, initials: "S", color: "bg-[#635BFF]" },
  { id: 2, name: "AWS Cloud", date: "May 17, 2024 - 09:15 AM", amount: "-$340.00", status: "Pending", isCredit: false, initials: "A", color: "bg-[#FF9900]" },
  { id: 3, name: "Upwork Escrow", date: "May 16, 2024 - 04:30 PM", amount: "-$850.00", status: "Completed", isCredit: false, initials: "U", color: "bg-[#14A800]" },
  { id: 4, name: "Shopify Payout", date: "May 15, 2024 - 11:20 AM", amount: "+$3,420.00", status: "Completed", isCredit: true, initials: "S", color: "bg-[#95BF47]" },
  { id: 5, name: "Google Workspace", date: "May 14, 2024 - 08:00 AM", amount: "-$45.00", status: "Completed", isCredit: false, initials: "G", color: "bg-[#4285F4]" },
];

export const MOCK_EXPENSE_CATEGORIES = [
  { name: "Marketing", value: 4200, color: "#8b5cf6" },
  { name: "Subscriptions", value: 2200, color: "#06b6d4" },
  { name: "Operations", value: 1800, color: "#22c55e" },
  { name: "Other", value: 1220, color: "#9ca3af" },
];

export const MOCK_REMINDERS = [
  { id: 1, title: "Review Q3 Tax Documents", date: "Tomorrow, 10:00 AM", type: "Tax" },
  { id: 2, title: "Client Meeting - Vercel", date: "Wed, 2:30 PM", type: "Meeting" },
  { id: 3, title: "Renew AWS Subscription", date: "Fri, 12:00 PM", type: "Subscription" },
];

export const MOCK_CUSTOMERS = [
  { id: 1, name: "Acme Corp", revenue: "$12,450", avatar: "https://i.pravatar.cc/150?u=a042581f4e29026024d" },
  { id: 2, name: "Globex Inc", revenue: "$8,320", avatar: "https://i.pravatar.cc/150?u=a042581f4e29026704d" },
  { id: 3, name: "Soylent Corp", revenue: "$5,100", avatar: "https://i.pravatar.cc/150?u=a04258114e29026702d" },
];
