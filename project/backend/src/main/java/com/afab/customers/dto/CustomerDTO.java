package com.afab.customers.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record CustomerDTO(
        UUID id,
        String customerCode,
        UUID businessId,
        String name,
        String companyName,
        String email,
        String phone,
        String group,
        String status,
        BigDecimal totalRevenue,
        BigDecimal invoicedAmount,
        BigDecimal outstandingBalance,
        long ordersCount,
        String lastActivityDate,
        String address,
        String notes,
        Instant createdAt,
        Instant updatedAt,
        List<CustomerInvoiceLinkDTO> orders
) {
    public record CustomerInvoiceLinkDTO(
            UUID id,
            String orderNumber,
            UUID customerId,
            BigDecimal amount,
            String status,
            String orderDate,
            String description,
            String paymentMethod,
            String invoiceNumber,
            Instant createdAt
    ) {}
}
