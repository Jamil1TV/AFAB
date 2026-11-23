package com.afab.budgets.dto;

import java.math.BigDecimal;
import java.util.List;

public record BudgetSummaryDTO(
        String currency,
        int activeBudgetCount,
        int approachingCount,
        int overBudgetCount,
        BigDecimal totalBudgeted,
        BigDecimal totalSpent,
        BigDecimal totalRemaining,
        List<BudgetDTO> budgets
) {}
