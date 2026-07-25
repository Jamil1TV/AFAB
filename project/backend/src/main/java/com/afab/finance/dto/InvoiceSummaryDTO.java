package com.afab.finance.dto;

import java.math.BigDecimal;
import java.util.List;

public class InvoiceSummaryDTO {
    private long totalInvoices;
    private long paidInvoices;
    private long pendingInvoices;
    private long overdueInvoices;
    private BigDecimal totalInvoiceAmount;
    private BigDecimal paidAmount;
    private BigDecimal pendingAmount;
    private BigDecimal overdueAmount;
    private String currency;
    private List<StatusBreakdownItem> statusBreakdown;
    private List<UpcomingInvoiceItem> upcomingDueList;

    public InvoiceSummaryDTO() {}

    public InvoiceSummaryDTO(long totalInvoices, long paidInvoices, long pendingInvoices, long overdueInvoices,
                             BigDecimal totalInvoiceAmount, BigDecimal paidAmount, BigDecimal pendingAmount,
                             BigDecimal overdueAmount, String currency, List<StatusBreakdownItem> statusBreakdown,
                             List<UpcomingInvoiceItem> upcomingDueList) {
        this.totalInvoices = totalInvoices;
        this.paidInvoices = paidInvoices;
        this.pendingInvoices = pendingInvoices;
        this.overdueInvoices = overdueInvoices;
        this.totalInvoiceAmount = totalInvoiceAmount;
        this.paidAmount = paidAmount;
        this.pendingAmount = pendingAmount;
        this.overdueAmount = overdueAmount;
        this.currency = currency;
        this.statusBreakdown = statusBreakdown;
        this.upcomingDueList = upcomingDueList;
    }

    public long getTotalInvoices() { return totalInvoices; }
    public void setTotalInvoices(long totalInvoices) { this.totalInvoices = totalInvoices; }

    public long getPaidInvoices() { return paidInvoices; }
    public void setPaidInvoices(long paidInvoices) { this.paidInvoices = paidInvoices; }

    public long getPendingInvoices() { return pendingInvoices; }
    public void setPendingInvoices(long pendingInvoices) { this.pendingInvoices = pendingInvoices; }

    public long getOverdueInvoices() { return overdueInvoices; }
    public void setOverdueInvoices(long overdueInvoices) { this.overdueInvoices = overdueInvoices; }

    public BigDecimal getTotalInvoiceAmount() { return totalInvoiceAmount; }
    public void setTotalInvoiceAmount(BigDecimal totalInvoiceAmount) { this.totalInvoiceAmount = totalInvoiceAmount; }

    public BigDecimal getPaidAmount() { return paidAmount; }
    public void setPaidAmount(BigDecimal paidAmount) { this.paidAmount = paidAmount; }

    public BigDecimal getPendingAmount() { return pendingAmount; }
    public void setPendingAmount(BigDecimal pendingAmount) { this.pendingAmount = pendingAmount; }

    public BigDecimal getOverdueAmount() { return overdueAmount; }
    public void setOverdueAmount(BigDecimal overdueAmount) { this.overdueAmount = overdueAmount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public List<StatusBreakdownItem> getStatusBreakdown() { return statusBreakdown; }
    public void setStatusBreakdown(List<StatusBreakdownItem> statusBreakdown) { this.statusBreakdown = statusBreakdown; }

    public List<UpcomingInvoiceItem> getUpcomingDueList() { return upcomingDueList; }
    public void setUpcomingDueList(List<UpcomingInvoiceItem> upcomingDueList) { this.upcomingDueList = upcomingDueList; }

    public static class StatusBreakdownItem {
        private String name;
        private BigDecimal amount;
        private double percentage;
        private String color;

        public StatusBreakdownItem() {}

        public StatusBreakdownItem(String name, BigDecimal amount, double percentage, String color) {
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

    public static class UpcomingInvoiceItem {
        private String invoiceId;
        private String customerName;
        private String email;
        private String dueDate;
        private BigDecimal amount;

        public UpcomingInvoiceItem() {}

        public UpcomingInvoiceItem(String invoiceId, String customerName, String email, String dueDate, BigDecimal amount) {
            this.invoiceId = invoiceId;
            this.customerName = customerName;
            this.email = email;
            this.dueDate = dueDate;
            this.amount = amount;
        }

        public String getInvoiceId() { return invoiceId; }
        public void setInvoiceId(String invoiceId) { this.invoiceId = invoiceId; }
        public String getCustomerName() { return customerName; }
        public void setCustomerName(String customerName) { this.customerName = customerName; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getDueDate() { return dueDate; }
        public void setDueDate(String dueDate) { this.dueDate = dueDate; }
        public BigDecimal getAmount() { return amount; }
        public void setAmount(BigDecimal amount) { this.amount = amount; }
    }
}
