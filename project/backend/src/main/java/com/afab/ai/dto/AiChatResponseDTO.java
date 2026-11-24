package com.afab.ai.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AiChatResponseDTO(
        UUID conversationId,
        String conversationTitle,
        UUID messageId,
        String content,
        List<AiEvidenceItem> evidence,
        List<String> toolsUsed,
        String dataCoverage,
        String modelId,
        long latencyMs,
        AiTokenUsageDTO tokenUsage,
        List<String> suggestedFollowUps,
        Instant createdAt
) {}
