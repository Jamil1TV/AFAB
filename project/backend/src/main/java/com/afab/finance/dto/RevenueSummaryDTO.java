package com.afab.finance.dto;

import java.math.BigDecimal;
import java.util.List;

public class RevenueSummaryDTO {
    private BigDecimal totalRevenue;
    private BigDecimal grossRevenue;
    private BigDecimal discounts;
    private BigDecimal refunds;
    private BigDecimal netRevenue;
    private BigDecimal avgPerDay;
    private BigDecimal highestRevenueAmount;
    private String highestRevenueDate;
    private long totalInvoices;
    private String currency;
    private List<RevenueSourceItem> revenueBySource;
    private List<TopProductItem> topProducts;
    private List<DailyOverviewPoint> dailyOverview;

    public RevenueSummaryDTO() {}

    public RevenueSummaryDTO(BigDecimal totalRevenue, BigDecimal grossRevenue, BigDecimal discounts,
                             BigDecimal refunds, BigDecimal netRevenue, BigDecimal avgPerDay,
                             BigDecimal highestRevenueAmount, String highestRevenueDate, long totalInvoices,
                             String currency, List<RevenueSourceItem> revenueBySource,
                             List<TopProductItem> topProducts, List<DailyOverviewPoint> dailyOverview) {
        this.totalRevenue = totalRevenue;
        this.grossRevenue = grossRevenue;
        this.discounts = discounts;
        this.refunds = refunds;
        this.netRevenue = netRevenue;
        this.avgPerDay = avgPerDay;
        this.highestRevenueAmount = highestRevenueAmount;
        this.highestRevenueDate = highestRevenueDate;
        this.totalInvoices = totalInvoices;
        this.currency = currency;
        this.revenueBySource = revenueBySource;
        this.topProducts = topProducts;
        this.dailyOverview = dailyOverview;
    }

    public BigDecimal getTotalRevenue() { return totalRevenue; }
    public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }

    public BigDecimal getGrossRevenue() { return grossRevenue; }
    public void setGrossRevenue(BigDecimal grossRevenue) { this.grossRevenue = grossRevenue; }

    public BigDecimal getDiscounts() { return discounts; }
    public void setDiscounts(BigDecimal discounts) { this.discounts = discounts; }

    public BigDecimal getRefunds() { return refunds; }
    public void setRefunds(BigDecimal refunds) { this.refunds = refunds; }

    public BigDecimal getNetRevenue() { return netRevenue; }
    public void setNetRevenue(BigDecimal netRevenue) { this.netRevenue = netRevenue; }

    public BigDecimal getAvgPerDay() { return avgPerDay; }
    public void setAvgPerDay(BigDecimal avgPerDay) { this.avgPerDay = avgPerDay; }

    public BigDecimal getHighestRevenueAmount() { return highestRevenueAmount; }
    public void setHighestRevenueAmount(BigDecimal highestRevenueAmount) { this.highestRevenueAmount = highestRevenueAmount; }

    public String getHighestRevenueDate() { return highestRevenueDate; }
    public void setHighestRevenueDate(String highestRevenueDate) { this.highestRevenueDate = highestRevenueDate; }

    public long getTotalInvoices() { return totalInvoices; }
    public void setTotalInvoices(long totalInvoices) { this.totalInvoices = totalInvoices; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public List<RevenueSourceItem> getRevenueBySource() { return revenueBySource; }
    public void setRevenueBySource(List<RevenueSourceItem> revenueBySource) { this.revenueBySource = revenueBySource; }

    public List<TopProductItem> getTopProducts() { return topProducts; }
    public void setTopProducts(List<TopProductItem> topProducts) { this.topProducts = topProducts; }

    public List<DailyOverviewPoint> getDailyOverview() { return dailyOverview; }
    public void setDailyOverview(List<DailyOverviewPoint> dailyOverview) { this.dailyOverview = dailyOverview; }

    public static class RevenueSourceItem {
        private String name;
        private BigDecimal amount;
        private double percentage;
        private String color;

        public RevenueSourceItem() {}

        public RevenueSourceItem(String name, BigDecimal amount, double percentage, String color) {
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

    public static class TopProductItem {
        private String name;
        private BigDecimal amount;
        private double percentage;
        private String color;

        public TopProductItem() {}

        public TopProductItem(String name, BigDecimal amount, double percentage, String color) {
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
