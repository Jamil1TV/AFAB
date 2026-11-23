package com.afab.invoices.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record InvoiceDTO(
        UUID id,
        UUID businessId,
        String invoiceNumber,
        UUID customerId,
        String customerName,
        String customerEmail,
        String status,
        String storedStatus,
        boolean overdue,
        LocalDate issueDate,
        LocalDate dueDate,
        String currency,
        BigDecimal subtotal,
        BigDecimal discountAmount,
        BigDecimal taxAmount,
        BigDecimal totalAmount,
        BigDecimal paidAmount,
        BigDecimal outstandingBalance,
        String notes,
        Instant issuedAt,
        Instant cancelledAt,
        Instant createdAt,
        Instant updatedAt,
        List<InvoiceItemDTO> items,
        List<PaymentDTO> payments
) {
    public record InvoiceItemDTO(
            UUID id,
            String description,
            BigDecimal quantity,
            BigDecimal unitPrice,
            BigDecimal taxRate,
            BigDecimal lineSubtotal,
            BigDecimal lineTax,
            BigDecimal lineTotal
    ) {}

    public record PaymentDTO(
            UUID id,
            UUID invoiceId,
            UUID incomeTransactionId,
            String idempotencyKey,
            BigDecimal amount,
            String currency,
            BigDecimal convertedBaseAmount,
            String baseCurrency,
            BigDecimal exchangeRate,
            LocalDate paymentDate,
            String paymentMethod,
            String reference,
            String notes,
            Instant createdAt
    ) {}
}
