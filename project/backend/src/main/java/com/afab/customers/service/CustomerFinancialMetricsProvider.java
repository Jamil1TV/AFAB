package com.afab.customers.service;

import com.afab.customers.dto.CustomerDTO.CustomerInvoiceLinkDTO;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Provides real financial metrics (paid revenue, invoiced totals, balances, invoice links)
 * per customer from the Invoice & Payment ledger (implemented by P1.3 Invoice domain).
 */
public interface CustomerFinancialMetricsProvider {

    record CustomerMetrics(
            BigDecimal totalPaidRevenue,
            BigDecimal totalInvoicedAmount,
            BigDecimal outstandingBalance,
            long invoiceCount,
            Instant lastInvoiceActivityAt,
            List<CustomerInvoiceLinkDTO> invoices
    ) {
        public static CustomerMetrics empty() {
            return new CustomerMetrics(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L, null, List.of());
        }
    }

    Map<UUID, CustomerMetrics> getMetricsForBusiness(UUID businessId);

    CustomerMetrics getMetricsForCustomer(UUID businessId, UUID customerId);
}
