package com.afab.ai.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AiConversationDetailDTO(
        UUID id,
        String title,
        String locale,
        Instant createdAt,
        Instant updatedAt,
        List<AiMessageDTO> messages
) {}
