package com.afab.dashboard.dto;

import java.util.List;
import java.util.Map;

public class DashboardSummaryDTO {

    private Map<String, KpiMetric> kpiData;
    private List<RevenueData> revenueData;
    private List<Transaction> transactions;
    private List<ExpenseCategory> expenseCategories;
    private List<Reminder> reminders;
    private List<Customer> customers;

    // Getters and Setters

    public Map<String, KpiMetric> getKpiData() {
        return kpiData;
    }

    public void setKpiData(Map<String, KpiMetric> kpiData) {
        this.kpiData = kpiData;
    }

    public List<RevenueData> getRevenueData() {
        return revenueData;
    }

    public void setRevenueData(List<RevenueData> revenueData) {
        this.revenueData = revenueData;
    }

    public List<Transaction> getTransactions() {
        return transactions;
    }

    public void setTransactions(List<Transaction> transactions) {
        this.transactions = transactions;
    }

    public List<ExpenseCategory> getExpenseCategories() {
        return expenseCategories;
    }

    public void setExpenseCategories(List<ExpenseCategory> expenseCategories) {
        this.expenseCategories = expenseCategories;
    }

    public List<Reminder> getReminders() {
        return reminders;
    }

    public void setReminders(List<Reminder> reminders) {
        this.reminders = reminders;
    }

    public List<Customer> getCustomers() {
        return customers;
    }

    public void setCustomers(List<Customer> customers) {
        this.customers = customers;
    }

    // Inner Classes for Data Structures

    public static class KpiMetric {
        private String value;
        private String change;
        private boolean isPositive;

        public KpiMetric(String value, String change, boolean isPositive) {
            this.value = value;
            this.change = change;
            this.isPositive = isPositive;
        }

        public String getValue() { return value; }
        public void setValue(String value) { this.value = value; }
        public String getChange() { return change; }
        public void setChange(String change) { this.change = change; }
        public boolean isIsPositive() { return isPositive; } 
        public void setIsPositive(boolean positive) { isPositive = positive; }
    }

    public static class RevenueData {
        private String name;
        private int revenue;
        private int expenses;

        public RevenueData(String name, int revenue, int expenses) {
            this.name = name;
            this.revenue = revenue;
            this.expenses = expenses;
        }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public int getRevenue() { return revenue; }
        public void setRevenue(int revenue) { this.revenue = revenue; }
        public int getExpenses() { return expenses; }
        public void setExpenses(int expenses) { this.expenses = expenses; }
    }

    public static class Transaction {
        private long id;
        private String name;
        private String date;
        private String amount;
        private String status;
        private boolean isCredit;
        private String initials;
        private String color;

        public Transaction(long id, String name, String date, String amount, String status, boolean isCredit, String initials, String color) {
            this.id = id;
            this.name = name;
            this.date = date;
            this.amount = amount;
            this.status = status;
            this.isCredit = isCredit;
            this.initials = initials;
            this.color = color;
        }

        public long getId() { return id; }
        public void setId(long id) { this.id = id; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        public String getAmount() { return amount; }
        public void setAmount(String amount) { this.amount = amount; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public boolean isIsCredit() { return isCredit; }
        public void setIsCredit(boolean credit) { isCredit = credit; }
        public String getInitials() { return initials; }
        public void setInitials(String initials) { this.initials = initials; }
        public String getColor() { return color; }
        public void setColor(String color) { this.color = color; }
    }

    public static class ExpenseCategory {
        private String name;
        private int value;
        private String color;

        public ExpenseCategory(String name, int value, String color) {
            this.name = name;
            this.value = value;
            this.color = color;
        }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public int getValue() { return value; }
        public void setValue(int value) { this.value = value; }
        public String getColor() { return color; }
        public void setColor(String color) { this.color = color; }
    }

    public static class Reminder {
        private long id;
        private String title;
        private String date;
        private String type;

        public Reminder(long id, String title, String date, String type) {
            this.id = id;
            this.title = title;
            this.date = date;
            this.type = type;
        }

        public long getId() { return id; }
        public void setId(long id) { this.id = id; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
    }

    public static class Customer {
        private long id;
        private String name;
        private String revenue;
        private String avatar;

        public Customer(long id, String name, String revenue, String avatar) {
            this.id = id;
            this.name = name;
            this.revenue = revenue;
            this.avatar = avatar;
        }

        public long getId() { return id; }
        public void setId(long id) { this.id = id; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getRevenue() { return revenue; }
        public void setRevenue(String revenue) { this.revenue = revenue; }
        public String getAvatar() { return avatar; }
        public void setAvatar(String avatar) { this.avatar = avatar; }
    }
}
