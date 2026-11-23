package com.afab.receipts.dto;

import java.time.Instant;
import java.util.UUID;

public record ReceiptDTO(
        UUID id,
        UUID businessId,
        UUID transactionId,
        String originalFilename,
        String contentType,
        long fileSizeBytes,
        String sha256Checksum,
        Instant createdAt
) {}
