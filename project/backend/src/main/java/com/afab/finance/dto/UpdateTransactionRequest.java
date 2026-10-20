package com.afab.finance.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public class UpdateTransactionRequest {

    @Pattern(regexp = "^(INCOME|EXPENSE)$", message = "Type must be either INCOME or EXPENSE")
    private String type;

    @DecimalMin(value = "0.0001", message = "Amount must be greater than zero")
    private BigDecimal amount;

    @Size(min = 1, max = 255, message = "Description must be between 1 and 255 characters")
    private String description;

    private LocalDate transactionDate;

    private UUID categoryId;

    @Pattern(regexp = "^(BANK_TRANSFER|CARD|CREDIT_CARD|CASH|OTHER)$", message = "Invalid payment method")
    private String paymentMethod;

    @Pattern(regexp = "^(COMPLETED|PENDING|CANCELLED)$", message = "Invalid transaction status")
    private String status;

    @Size(max = 1000, message = "Notes cannot exceed 1000 characters")
    private String notes;

    private Boolean taxDeductible;

    private BigDecimal taxRate;

    @Valid
    private List<SplitRequestItem> splitItems;

    public UpdateTransactionRequest() {}

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDate getTransactionDate() { return transactionDate; }
    public void setTransactionDate(LocalDate transactionDate) { this.transactionDate = transactionDate; }

    public UUID getCategoryId() { return categoryId; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Boolean getTaxDeductible() { return taxDeductible; }
    public void setTaxDeductible(Boolean taxDeductible) { this.taxDeductible = taxDeductible; }

    public BigDecimal getTaxRate() { return taxRate; }
    public void setTaxRate(BigDecimal taxRate) { this.taxRate = taxRate; }

    public List<SplitRequestItem> getSplitItems() { return splitItems; }
    public void setSplitItems(List<SplitRequestItem> splitItems) { this.splitItems = splitItems; }
}
