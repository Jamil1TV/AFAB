package com.afab.ai.dto;

import java.math.BigDecimal;

public record AiEvidenceItem(
        String type,
        String id,
        String title,
        String subtitle,
        BigDecimal amount,
        String currency,
        String date,
        String href
) {}
