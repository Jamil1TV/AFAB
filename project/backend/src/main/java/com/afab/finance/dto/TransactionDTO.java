package com.afab.finance.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public class TransactionDTO {
    private UUID id;
    private String type;
    private BigDecimal amount;
    private String currency;
    private String description;
    private LocalDate transactionDate;
    private String paymentMethod;
    private String status;
    private String categoryName;
    private String categoryColor;
    private String categoryIcon;
    private UUID categoryId;

    public TransactionDTO() {}

    public TransactionDTO(UUID id, String type, BigDecimal amount, String currency, String description,
                          LocalDate transactionDate, String paymentMethod, String status,
                          String categoryName, String categoryColor, String categoryIcon, UUID categoryId) {
        this.id = id;
        this.type = type;
        this.amount = amount;
        this.currency = currency;
        this.description = description;
        this.transactionDate = transactionDate;
        this.paymentMethod = paymentMethod;
        this.status = status;
        this.categoryName = categoryName;
        this.categoryColor = categoryColor;
        this.categoryIcon = categoryIcon;
        this.categoryId = categoryId;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDate getTransactionDate() { return transactionDate; }
    public void setTransactionDate(LocalDate transactionDate) { this.transactionDate = transactionDate; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public String getCategoryColor() { return categoryColor; }
    public void setCategoryColor(String categoryColor) { this.categoryColor = categoryColor; }

    public String getCategoryIcon() { return categoryIcon; }
    public void setCategoryIcon(String categoryIcon) { this.categoryIcon = categoryIcon; }

    public UUID getCategoryId() { return categoryId; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }
}
