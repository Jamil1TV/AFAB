package com.afab.reports.dto;

import java.math.BigDecimal;

public class CategoryShareDTO {
    private String categoryName;
    private BigDecimal amount;
    private double percentage;
    private int transactionCount;

    public CategoryShareDTO() {}

    public CategoryShareDTO(String categoryName, BigDecimal amount, double percentage, int transactionCount) {
        this.categoryName = categoryName;
        this.amount = amount;
        this.percentage = percentage;
        this.transactionCount = transactionCount;
    }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public double getPercentage() { return percentage; }
    public void setPercentage(double percentage) { this.percentage = percentage; }

    public int getTransactionCount() { return transactionCount; }
    public void setTransactionCount(int transactionCount) { this.transactionCount = transactionCount; }
}
