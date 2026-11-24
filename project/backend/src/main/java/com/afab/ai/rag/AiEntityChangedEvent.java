package com.afab.ai.rag;

import java.util.UUID;

public record AiEntityChangedEvent(
        UUID businessId,
        String sourceType,
        UUID sourceId,
        boolean deleted
) {}
