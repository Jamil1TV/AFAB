package com.afab.ai.dto;

public record AiStatusDTO(
        boolean enabled,
        boolean ollamaReachable,
        String chatModel,
        boolean chatModelReady,
        String embedModel,
        boolean embedModelReady,
        long indexedChunks,
        long approvedMemories,
        AiTokenUsageDTO quota
) {}
