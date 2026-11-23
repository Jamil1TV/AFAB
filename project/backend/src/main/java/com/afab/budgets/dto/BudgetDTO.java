package com.afab.budgets.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record BudgetDTO(
        UUID id,
        UUID businessId,
        String name,
        BigDecimal budgetAmount,
        String currency,
        UUID categoryId,
        String categoryName,
        String categoryColor,
        String periodType,
        LocalDate startDate,
        LocalDate endDate,
        int alertThresholdPercent,
        String description,
        String status,
        BigDecimal actualSpending,
        BigDecimal remainingAmount,
        BigDecimal overBudgetAmount,
        BigDecimal percentageConsumed,
        String alertLevel, // OK, APPROACHING, OVER_BUDGET
        Instant createdAt,
        Instant updatedAt
) {}
