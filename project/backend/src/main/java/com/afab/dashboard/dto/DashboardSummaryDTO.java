package com.afab.dashboard.dto;

import java.util.List;

/**
 * Dashboard Summary DTO — returned by GET /api/v1/dashboard/summary.
 * Mirrors the frontend's expected data shape.
 */
public class DashboardSummaryDTO {

    private KpiData kpiData;
    private List<RevenueDataPoint> revenueData;
    private List<TransactionItem> transactions;
    private List<ExpenseCategory> expenseCategories;
    private List<ReminderItem> reminders;
    private List<CustomerItem> customers;
    private String currency;
    private String businessName;

    // ── Constructors ────────────────────────────

    public DashboardSummaryDTO() {}

    public DashboardSummaryDTO(KpiData kpiData, List<RevenueDataPoint> revenueData,
                                List<TransactionItem> transactions, List<ExpenseCategory> expenseCategories,
                                List<ReminderItem> reminders, List<CustomerItem> customers,
                                String currency, String businessName) {
        this.kpiData = kpiData;
        this.revenueData = revenueData;
        this.transactions = transactions;
        this.expenseCategories = expenseCategories;
        this.reminders = reminders;
        this.customers = customers;
        this.currency = currency;
        this.businessName = businessName;
    }

    // ── Getters & Setters ───────────────────────

    public KpiData getKpiData() { return kpiData; }
    public void setKpiData(KpiData kpiData) { this.kpiData = kpiData; }

    public List<RevenueDataPoint> getRevenueData() { return revenueData; }
    public void setRevenueData(List<RevenueDataPoint> revenueData) { this.revenueData = revenueData; }

    public List<TransactionItem> getTransactions() { return transactions; }
    public void setTransactions(List<TransactionItem> transactions) { this.transactions = transactions; }

    public List<ExpenseCategory> getExpenseCategories() { return expenseCategories; }
    public void setExpenseCategories(List<ExpenseCategory> expenseCategories) { this.expenseCategories = expenseCategories; }

    public List<ReminderItem> getReminders() { return reminders; }
    public void setReminders(List<ReminderItem> reminders) { this.reminders = reminders; }

    public List<CustomerItem> getCustomers() { return customers; }
    public void setCustomers(List<CustomerItem> customers) { this.customers = customers; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getBusinessName() { return businessName; }
    public void setBusinessName(String businessName) { this.businessName = businessName; }

    // ── Nested DTOs ─────────────────────────────

    public static class KpiData {
        private KpiMetric revenue;
        private KpiMetric expenses;
        private KpiMetric profit;
        private KpiMetric cashFlow;

        public KpiData() {}

        public KpiData(KpiMetric revenue, KpiMetric expenses, KpiMetric profit, KpiMetric cashFlow) {
            this.revenue = revenue;
            this.expenses = expenses;
            this.profit = profit;
            this.cashFlow = cashFlow;
        }

        public KpiMetric getRevenue() { return revenue; }
        public void setRevenue(KpiMetric revenue) { this.revenue = revenue; }

        public KpiMetric getExpenses() { return expenses; }
        public void setExpenses(KpiMetric expenses) { this.expenses = expenses; }

        public KpiMetric getProfit() { return profit; }
        public void setProfit(KpiMetric profit) { this.profit = profit; }

        public KpiMetric getCashFlow() { return cashFlow; }
        public void setCashFlow(KpiMetric cashFlow) { this.cashFlow = cashFlow; }
    }

    public static class KpiMetric {
        private String value;
        private String change;
        private boolean isPositive;

        public KpiMetric() {}

        public KpiMetric(String value, String change, boolean isPositive) {
            this.value = value;
            this.change = change;
            this.isPositive = isPositive;
        }

        public String getValue() { return value; }
        public void setValue(String value) { this.value = value; }

        public String getChange() { return change; }
        public void setChange(String change) { this.change = change; }

        public boolean getIsPositive() { return isPositive; }
        public void setIsPositive(boolean isPositive) { this.isPositive = isPositive; }
    }

    public static class RevenueDataPoint {
        private String month;
        private double revenue;
        private double expenses;

        public RevenueDataPoint() {}

        public RevenueDataPoint(String month, double revenue, double expenses) {
            this.month = month;
            this.revenue = revenue;
            this.expenses = expenses;
        }

        public String getMonth() { return month; }
        public void setMonth(String month) { this.month = month; }

        public double getRevenue() { return revenue; }
        public void setRevenue(double revenue) { this.revenue = revenue; }

        public double getExpenses() { return expenses; }
        public void setExpenses(double expenses) { this.expenses = expenses; }
    }

    public static class TransactionItem {
        private String id;
        private String description;
        private String amount;
        private String date;
        private String type;

        public TransactionItem() {}

        public TransactionItem(String id, String description, String amount, String date, String type) {
            this.id = id;
            this.description = description;
            this.amount = amount;
            this.date = date;
            this.type = type;
        }

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }

        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }

        public String getAmount() { return amount; }
        public void setAmount(String amount) { this.amount = amount; }

        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }

        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
    }

    public static class ExpenseCategory {
        private String name;
        private String amount;
        private double percentage;
        private String color;

        public ExpenseCategory() {}

        public ExpenseCategory(String name, String amount, double percentage, String color) {
            this.name = name;
            this.amount = amount;
            this.percentage = percentage;
            this.color = color;
        }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getAmount() { return amount; }
        public void setAmount(String amount) { this.amount = amount; }

        public double getPercentage() { return percentage; }
        public void setPercentage(double percentage) { this.percentage = percentage; }

        public String getColor() { return color; }
        public void setColor(String color) { this.color = color; }
    }

    public static class ReminderItem {
        private String id;
        private String title;
        private String date;
        private String priority;

        public ReminderItem() {}

        public ReminderItem(String id, String title, String date, String priority) {
            this.id = id;
            this.title = title;
            this.date = date;
            this.priority = priority;
        }

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }

        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }

        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }

        public String getPriority() { return priority; }
        public void setPriority(String priority) { this.priority = priority; }
    }

    public static class CustomerItem {
        private String id;
        private String name;
        private double revenue;
        private String avatar;

        public CustomerItem() {}

        public CustomerItem(String id, String name, double revenue, String avatar) {
            this.id = id;
            this.name = name;
            this.revenue = revenue;
            this.avatar = avatar;
        }

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public double getRevenue() { return revenue; }
        public void setRevenue(double revenue) { this.revenue = revenue; }

        public String getAvatar() { return avatar; }
        public void setAvatar(String avatar) { this.avatar = avatar; }
    }
}
