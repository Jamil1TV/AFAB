package com.afab.invoices.dto;

import java.math.BigDecimal;
import java.util.List;

public record InvoicePageDTO(
        List<InvoiceDTO> content,
        int pageNumber,
        int pageSize,
        long totalElements,
        int totalPages,
        BigDecimal totalInvoiced,
        BigDecimal totalPaid,
        BigDecimal totalOutstanding,
        String currency
) {}
