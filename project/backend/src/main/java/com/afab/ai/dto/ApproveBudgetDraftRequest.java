package com.afab.ai.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public class ApproveBudgetDraftRequest {

    @NotNull
    private UUID messageId;

    @NotBlank
    private String draftId;

    @NotBlank
    @Size(max = 150)
    private String name;

    @NotNull
    @DecimalMin(value = "0.0001")
    private BigDecimal amount;

    private UUID categoryId;
    private String periodType = "MONTHLY";
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer alertThresholdPercent = 80;

    @Size(max = 1000)
    private String description;

    public UUID getMessageId() { return messageId; }
    public void setMessageId(UUID messageId) { this.messageId = messageId; }

    public String getDraftId() { return draftId; }
    public void setDraftId(String draftId) { this.draftId = draftId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

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
