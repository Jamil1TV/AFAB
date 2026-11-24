package com.afab.ai.dto;

import java.time.Instant;
import java.util.UUID;

public record AiConversationSummaryDTO(
        UUID id,
        String title,
        String locale,
        String activeLanguage,
        Instant createdAt,
        Instant updatedAt,
        long messageCount
) {}
