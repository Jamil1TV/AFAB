package com.afab.budgets.dto;

import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public class BudgetRequest {

    @NotBlank(message = "Budget name is required")
    @Size(max = 150)
    private String name;

    @NotNull(message = "Budget amount is required")
    @DecimalMin(value = "0.0001", message = "Budget amount must be greater than zero")
    private BigDecimal amount;

    @Pattern(regexp = "^[A-Za-z]{3}$", message = "Currency must be a 3-letter ISO code")
    private String currency;

    private UUID categoryId; // null = overall business budget

    @Pattern(regexp = "^(MONTHLY|QUARTERLY|YEARLY|CUSTOM)$", message = "Period type must be MONTHLY, QUARTERLY, YEARLY, or CUSTOM")
    private String periodType = "MONTHLY";

    private LocalDate startDate;
    private LocalDate endDate;

    @Min(value = 1, message = "Alert threshold must be between 1 and 100")
    @Max(value = 100, message = "Alert threshold must be between 1 and 100")
    private Integer alertThresholdPercent = 80;

    @Size(max = 1000)
    private String description;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public UUID getCategoryId() { return categoryId; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }

    public String getPeriodType() { return periodType; }
    public void setPeriodType(String periodType) { this.periodType = periodType; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public Integer getAlertThresholdPercent() { return alertThresholdPercent; }
    public void setAlertThresholdPercent(Integer alertThresholdPercent) { this.alertThresholdPercent = alertThresholdPercent; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
