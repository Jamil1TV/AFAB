package com.afab.ai.dto;

import java.time.Instant;

public record AiStatusDTO(
        boolean enabled,
        boolean ollamaReachable,
        String chatModel,
        boolean chatModelReady,
        boolean chatModelLoaded,
        String embedModel,
        boolean embedModelReady,
        boolean busy,
        long latencyMs,
        Instant checkedAt,
        long indexedChunks,
        long approvedMemories,
        AiTokenUsageDTO quota
) {}
