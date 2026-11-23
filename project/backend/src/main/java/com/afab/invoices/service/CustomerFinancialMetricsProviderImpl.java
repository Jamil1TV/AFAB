package com.afab.invoices.service;

import com.afab.customers.dto.CustomerDTO.CustomerInvoiceLinkDTO;
import com.afab.customers.service.CustomerFinancialMetricsProvider;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.*;

/**
 * Computes real customer financial totals (paid revenue, invoiced amount, outstanding balance)
 * strictly from persisted Invoices & Payments.
 */
@Component
public class CustomerFinancialMetricsProviderImpl implements CustomerFinancialMetricsProvider {

    private final InvoiceRepository invoiceRepository;

    public CustomerFinancialMetricsProviderImpl(InvoiceRepository invoiceRepository) {
        this.invoiceRepository = invoiceRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<UUID, CustomerMetrics> getMetricsForBusiness(UUID businessId) {
        List<Invoice> invoices = invoiceRepository.findAllByBusinessIdWithCustomer(businessId);
        Map<UUID, List<Invoice>> byCustomer = new HashMap<>();
        for (Invoice inv : invoices) {
            if (inv.getCustomer() != null && inv.getStatus() != InvoiceStatus.CANCELLED) {
                byCustomer.computeIfAbsent(inv.getCustomer().getId(), k -> new ArrayList<>()).add(inv);
            }
        }

        Map<UUID, CustomerMetrics> result = new HashMap<>();
        LocalDate today = LocalDate.now();
        for (var entry : byCustomer.entrySet()) {
            result.put(entry.getKey(), aggregate(entry.getKey(), entry.getValue(), today));
        }
        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public CustomerMetrics getMetricsForCustomer(UUID businessId, UUID customerId) {
        List<Invoice> invoices = invoiceRepository.findAllByBusinessIdAndCustomerId(businessId, customerId).stream()
                .filter(inv -> inv.getStatus() != InvoiceStatus.CANCELLED)
                .toList();
        return aggregate(customerId, invoices, LocalDate.now());
    }

    private CustomerMetrics aggregate(UUID customerId, List<Invoice> invoices, LocalDate today) {
        BigDecimal paidRevenue = BigDecimal.ZERO;
        BigDecimal invoicedTotal = BigDecimal.ZERO;
        BigDecimal outstanding = BigDecimal.ZERO;
        Instant lastActivity = null;
        List<CustomerInvoiceLinkDTO> links = new ArrayList<>();

        for (Invoice inv : invoices) {
            paidRevenue = paidRevenue.add(inv.getPaidAmount() != null ? inv.getPaidAmount() : BigDecimal.ZERO);
            if (inv.getStatus() != InvoiceStatus.DRAFT) {
                invoicedTotal = invoicedTotal.add(inv.getTotalAmount() != null ? inv.getTotalAmount() : BigDecimal.ZERO);
                outstanding = outstanding.add(inv.getOutstandingBalance() != null ? inv.getOutstandingBalance() : BigDecimal.ZERO);
            }
            Instant ts = inv.getUpdatedAt() != null ? inv.getUpdatedAt() : inv.getCreatedAt();
            if (ts != null && (lastActivity == null || ts.isAfter(lastActivity))) {
                lastActivity = ts;
            }
            links.add(new CustomerInvoiceLinkDTO(
                    inv.getId(),
                    inv.getInvoiceNumber(),
                    customerId,
                    inv.getTotalAmount(),
                    inv.computeEffectiveStatus(today).name(),
                    inv.getIssueDate() != null ? inv.getIssueDate().toString() : "",
                    inv.getNotes() != null && !inv.getNotes().isBlank() ? inv.getNotes() : "Invoice " + inv.getInvoiceNumber(),
                    null,
                    inv.getInvoiceNumber(),
                    inv.getCreatedAt()
            ));
        }

        return new CustomerMetrics(paidRevenue, invoicedTotal, outstanding, invoices.size(), lastActivity, links);
    }
}
