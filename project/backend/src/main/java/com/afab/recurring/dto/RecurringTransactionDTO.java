package com.afab.recurring.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record RecurringTransactionDTO(
        UUID id,
        UUID businessId,
        String type,
        String description,
        BigDecimal amount,
        String currency,
        UUID categoryId,
        String categoryName,
        String paymentMethod,
        String frequency,
        LocalDate startDate,
        LocalDate endDate,
        LocalDate nextExecutionDate,
        boolean active,
        String notes,
        Instant lastExecutedAt,
        Instant createdAt,
        Instant updatedAt
) {}
