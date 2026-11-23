package com.afab.recurring.dto;

import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public class RecurringTransactionRequest {

    @NotBlank(message = "Type is required")
    @Pattern(regexp = "^(INCOME|EXPENSE)$", message = "Type must be INCOME or EXPENSE")
    private String type;

    @NotBlank(message = "Description is required")
    @Size(max = 255)
    private String description;

    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.0001", message = "Amount must be greater than zero")
    private BigDecimal amount;

    @Pattern(regexp = "^[A-Za-z]{3}$", message = "Currency must be a 3-letter ISO code")
    private String currency;

    private UUID categoryId;

    @Pattern(regexp = "^(BANK_TRANSFER|CARD|CREDIT_CARD|CASH|OTHER)$", message = "Invalid payment method")
    private String paymentMethod = "BANK_TRANSFER";

    @NotBlank(message = "Frequency is required")
    @Pattern(regexp = "^(WEEKLY|MONTHLY|QUARTERLY|YEARLY)$", message = "Frequency must be WEEKLY, MONTHLY, QUARTERLY, or YEARLY")
    private String frequency;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    private LocalDate endDate;

    private Boolean active = true;

    @Size(max = 1000)
    private String notes;

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public UUID getCategoryId() { return categoryId; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getFrequency() { return frequency; }
    public void setFrequency(String frequency) { this.frequency = frequency; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
