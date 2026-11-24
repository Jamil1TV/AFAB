package com.afab.ai.dto;

import java.time.Instant;
import java.util.UUID;

public record BusinessMemoryDTO(
        UUID id,
        String memoryType,
        String title,
        String content,
        String sourceType,
        UUID sourceId,
        String status,
        String visibility,
        String modelId,
        boolean hasVector,
        Instant expiresAt,
        Instant createdAt,
        Instant updatedAt
) {}
