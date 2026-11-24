package com.afab.ai.dto;

import java.time.Instant;
import java.util.UUID;

public record AiAttachmentDTO(
        UUID id,
        String kind,
        String originalFilename,
        String contentType,
        long fileSizeBytes,
        boolean hasExtractedText,
        String extractedPreview,
        String status,
        Instant createdAt
) {}
