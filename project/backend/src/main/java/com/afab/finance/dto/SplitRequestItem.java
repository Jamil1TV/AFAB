package com.afab.finance.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.UUID;

public class SplitRequestItem {

    @NotNull(message = "Category is required for each split item")
    private UUID categoryId;

    @NotNull(message = "Amount is required for each split item")
    @DecimalMin(value = "0.01", message = "Split amount must be greater than 0")
    private BigDecimal amount;

    private String description;

    public SplitRequestItem() {}

    public SplitRequestItem(UUID categoryId, BigDecimal amount, String description) {
        this.categoryId = categoryId;
        this.amount = amount;
        this.description = description;
    }

    public UUID getCategoryId() { return categoryId; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
