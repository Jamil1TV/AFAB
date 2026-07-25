package com.afab.finance.dto;

import java.math.BigDecimal;
import java.util.List;

public class ExpenseSummaryDTO {
    private BigDecimal totalExpenses;
    private BigDecimal avgPerDay;
    private String highestExpenseTitle;
    private BigDecimal highestExpenseAmount;
    private long categoryCount;
    private BigDecimal recurringTotal;
    private double recurringPercentage;
    private String currency;
    private List<CategoryBreakdownItem> categoryBreakdown;
    private List<RecurringItem> recurringList;
    private List<DailyOverviewPoint> dailyOverview;

    public ExpenseSummaryDTO() {}

    public ExpenseSummaryDTO(BigDecimal totalExpenses, BigDecimal avgPerDay, String highestExpenseTitle,
                             BigDecimal highestExpenseAmount, long categoryCount, BigDecimal recurringTotal,
                             double recurringPercentage, String currency, List<CategoryBreakdownItem> categoryBreakdown,
                             List<RecurringItem> recurringList, List<DailyOverviewPoint> dailyOverview) {
        this.totalExpenses = totalExpenses;
        this.avgPerDay = avgPerDay;
        this.highestExpenseTitle = highestExpenseTitle;
        this.highestExpenseAmount = highestExpenseAmount;
        this.categoryCount = categoryCount;
        this.recurringTotal = recurringTotal;
        this.recurringPercentage = recurringPercentage;
        this.currency = currency;
        this.categoryBreakdown = categoryBreakdown;
        this.recurringList = recurringList;
        this.dailyOverview = dailyOverview;
    }

    public BigDecimal getTotalExpenses() { return totalExpenses; }
    public void setTotalExpenses(BigDecimal totalExpenses) { this.totalExpenses = totalExpenses; }

    public BigDecimal getAvgPerDay() { return avgPerDay; }
    public void setAvgPerDay(BigDecimal avgPerDay) { this.avgPerDay = avgPerDay; }

    public String getHighestExpenseTitle() { return highestExpenseTitle; }
    public void setHighestExpenseTitle(String highestExpenseTitle) { this.highestExpenseTitle = highestExpenseTitle; }

    public BigDecimal getHighestExpenseAmount() { return highestExpenseAmount; }
    public void setHighestExpenseAmount(BigDecimal highestExpenseAmount) { this.highestExpenseAmount = highestExpenseAmount; }

    public long getCategoryCount() { return categoryCount; }
    public void setCategoryCount(long categoryCount) { this.categoryCount = categoryCount; }

    public BigDecimal getRecurringTotal() { return recurringTotal; }
    public void setRecurringTotal(BigDecimal recurringTotal) { this.recurringTotal = recurringTotal; }

    public double getRecurringPercentage() { return recurringPercentage; }
    public void setRecurringPercentage(double recurringPercentage) { this.recurringPercentage = recurringPercentage; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public List<CategoryBreakdownItem> getCategoryBreakdown() { return categoryBreakdown; }
    public void setCategoryBreakdown(List<CategoryBreakdownItem> categoryBreakdown) { this.categoryBreakdown = categoryBreakdown; }

    public List<RecurringItem> getRecurringList() { return recurringList; }
    public void setRecurringList(List<RecurringItem> recurringList) { this.recurringList = recurringList; }

    public List<DailyOverviewPoint> getDailyOverview() { return dailyOverview; }
    public void setDailyOverview(List<DailyOverviewPoint> dailyOverview) { this.dailyOverview = dailyOverview; }

    public static class CategoryBreakdownItem {
        private String name;
        private BigDecimal amount;
        private double percentage;
        private String color;

        public CategoryBreakdownItem() {}

        public CategoryBreakdownItem(String name, BigDecimal amount, double percentage, String color) {
            this.name = name;
            this.amount = amount;
            this.percentage = percentage;
            this.color = color;
        }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public BigDecimal getAmount() { return amount; }
        public void setAmount(BigDecimal amount) { this.amount = amount; }
        public double getPercentage() { return percentage; }
        public void setPercentage(double percentage) { this.percentage = percentage; }
        public String getColor() { return color; }
        public void setColor(String color) { this.color = color; }
    }

    public static class RecurringItem {
        private String name;
        private BigDecimal amount;
        private String billingCycle;
        private String dueDate;
        private String icon;

        public RecurringItem() {}

        public RecurringItem(String name, BigDecimal amount, String billingCycle, String dueDate, String icon) {
            this.name = name;
            this.amount = amount;
            this.billingCycle = billingCycle;
            this.dueDate = dueDate;
            this.icon = icon;
        }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public BigDecimal getAmount() { return amount; }
        public void setAmount(BigDecimal amount) { this.amount = amount; }
        public String getBillingCycle() { return billingCycle; }
        public void setBillingCycle(String billingCycle) { this.billingCycle = billingCycle; }
        public String getDueDate() { return dueDate; }
        public void setDueDate(String dueDate) { this.dueDate = dueDate; }
        public String getIcon() { return icon; }
        public void setIcon(String icon) { this.icon = icon; }
    }

    public static class DailyOverviewPoint {
        private String date;
        private BigDecimal amount;

        public DailyOverviewPoint() {}

        public DailyOverviewPoint(String date, BigDecimal amount) {
            this.date = date;
            this.amount = amount;
        }

        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        public BigDecimal getAmount() { return amount; }
        public void setAmount(BigDecimal amount) { this.amount = amount; }
    }
}
