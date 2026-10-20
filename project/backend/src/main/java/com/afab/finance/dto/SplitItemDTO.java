package com.afab.finance.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record SplitItemDTO(
    UUID id,
    UUID categoryId,
    String categoryName,
    String categoryColor,
    String categoryIcon,
    BigDecimal amount,
    String description
) {}
