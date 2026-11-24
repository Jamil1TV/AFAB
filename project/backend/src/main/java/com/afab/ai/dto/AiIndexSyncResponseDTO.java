package com.afab.ai.dto;

public record AiIndexSyncResponseDTO(
        int indexedCount,
        int skippedUnchanged,
        int embeddingsGenerated,
        boolean embeddingAvailable,
        String message
) {}
