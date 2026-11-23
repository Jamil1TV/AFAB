package com.afab.customers.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CustomerPageDTO(
        List<CustomerDTO> content,
        long totalElements,
        int totalPages,
        int pageNumber,
        int pageSize
) {}
