package com.afab.finance.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
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
    private String notes;
    private Boolean taxDeductible;
    private BigDecimal taxRate;
    private Boolean isSplit;
    private UUID parentTransactionId;
    private Boolean potentialDuplicate;
    private BigDecimal priceHikePercentage;
    private List<SplitItemDTO> splitItems = new ArrayList<>();
    private Instant createdAt;
    private Instant updatedAt;

    public TransactionDTO() {}

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

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Boolean getTaxDeductible() { return taxDeductible != null && taxDeductible; }
    public void setTaxDeductible(Boolean taxDeductible) { this.taxDeductible = taxDeductible; }

    public BigDecimal getTaxRate() { return taxRate; }
    public void setTaxRate(BigDecimal taxRate) { this.taxRate = taxRate; }

    public Boolean getIsSplit() { return isSplit != null && isSplit; }
    public void setIsSplit(Boolean isSplit) { this.isSplit = isSplit; }

    public UUID getParentTransactionId() { return parentTransactionId; }
    public void setParentTransactionId(UUID parentTransactionId) { this.parentTransactionId = parentTransactionId; }

    public Boolean getPotentialDuplicate() { return potentialDuplicate != null && potentialDuplicate; }
    public void setPotentialDuplicate(Boolean potentialDuplicate) { this.potentialDuplicate = potentialDuplicate; }

    public BigDecimal getPriceHikePercentage() { return priceHikePercentage; }
    public void setPriceHikePercentage(BigDecimal priceHikePercentage) { this.priceHikePercentage = priceHikePercentage; }

    public List<SplitItemDTO> getSplitItems() { return splitItems; }
    public void setSplitItems(List<SplitItemDTO> splitItems) { this.splitItems = splitItems; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
