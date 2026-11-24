package com.afab.ai.dto;

import java.time.Instant;

public record AiHealthDTO(
        boolean enabled,
        boolean ollamaReachable,
        String chatModel,
        boolean chatModelReady,
        boolean chatModelLoaded,
        String embedModel,
        boolean embedModelReady,
        boolean busy,
        long latencyMs,
        Instant checkedAt
) {}
