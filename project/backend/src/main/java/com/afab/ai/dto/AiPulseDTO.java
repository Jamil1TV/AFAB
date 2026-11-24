package com.afab.ai.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record AiPulseDTO(
        String currency,
        Instant generatedAt,
        int highCount,
        int mediumCount,
        int infoCount,
        BigDecimal monthRevenue,
        BigDecimal monthExpenses,
        BigDecimal monthNetProfit,
        BigDecimal overdueTotal,
        int overdueCount,
        int missingReceiptCount,
        List<PulseAlert> alerts
) {
    public record PulseAlert(
            String id,
            String type,       // SPENDING_SPIKE | DUPLICATE_EXPENSE | BUDGET_BURN | MISSING_RECEIPTS | OVERDUE_INVOICES
            String severity,   // HIGH | MEDIUM | INFO
            String title,
            String description,
            BigDecimal metricValue,
            String currency,
            String actionLabel,
            String copilotPrompt,
            String href
    ) {}
}
