package com.afab.ai.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AiMessageDTO(
        UUID id,
        String role,
        String content,
        List<AiEvidenceItem> evidence,
        List<String> toolsUsed,
        String dataCoverage,
        String modelId,
        int promptTokens,
        int completionTokens,
        int totalTokens,
        Long latencyMs,
        Instant createdAt
) {}
