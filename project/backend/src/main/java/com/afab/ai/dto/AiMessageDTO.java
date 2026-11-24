package com.afab.ai.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AiMessageDTO(
        UUID id,
        String role,
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
        int promptTokens,
        int completionTokens,
        int totalTokens,
        Long latencyMs,
        Instant createdAt
) {}
