package com.afab.ai.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AiChatResponseDTO(
        UUID conversationId,
        String conversationTitle,
        UUID messageId,
        String content,
        String thinkingContent,
        List<AiEvidenceItem> evidence,
        List<String> toolsUsed,
        List<AiChartSpecDTO> charts,
        List<AiActionDraftDTO> actionDrafts,
        List<AiAttachmentDTO> attachments,
        String dataCoverage,
        String modelId,
        String reasoningMode,
        String responseLanguage,
        long latencyMs,
        AiTokenUsageDTO tokenUsage,
        List<String> suggestedFollowUps,
        Instant createdAt
) {}
