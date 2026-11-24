package com.afab.receipts.service;

import com.afab.business.Business;
import com.afab.business.BusinessAccessGuard;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.receipts.domain.Receipt;
import com.afab.receipts.dto.ReceiptDTO;
import com.afab.receipts.repository.ReceiptRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Private Receipt Storage Service.
 * Enforces strict file size limits, MIME + magic-byte validation, SHA-256 checksums,
 * private tenant-prefixed object keys, and authorization checks on every access.
 */
@Service
public class ReceiptService {

    private static final Map<String, String> ALLOWED_MIME_TO_EXT = Map.of(
            "application/pdf", "pdf",
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp"
    );

    private final ReceiptRepository receiptRepository;
    private final TransactionRepository transactionRepository;
    private final CurrentBusinessService currentBusinessService;
    private final ObjectStorageService objectStorageService;
    private final AuditService auditService;
    private final long maxFileSizeBytes;
    private final int presignExpirySeconds;

    public ReceiptService(
            ReceiptRepository receiptRepository,
            TransactionRepository transactionRepository,
            CurrentBusinessService currentBusinessService,
            ObjectStorageService objectStorageService,
            AuditService auditService,
            @Value("${afab.minio.max-file-size-bytes:10485760}") long maxFileSizeBytes,
            @Value("${afab.minio.presign-expiry-seconds:300}") int presignExpirySeconds
    ) {
        this.receiptRepository = receiptRepository;
        this.transactionRepository = transactionRepository;
        this.currentBusinessService = currentBusinessService;
        this.objectStorageService = objectStorageService;
        this.auditService = auditService;
        this.maxFileSizeBytes = maxFileSizeBytes;
        this.presignExpirySeconds = Math.max(30, Math.min(3600, presignExpirySeconds));
    }

    @Transactional
    public ReceiptDTO upload(String userEmail, UUID transactionId, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Receipt file is required and cannot be empty.");
        }
        if (file.getSize() > maxFileSizeBytes) {
            throw new IllegalArgumentException("Receipt file exceeds maximum allowed size of " + (maxFileSizeBytes / (1024 * 1024)) + " MB.");
        }

        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);
        Transaction tx = loadOwnedTransaction(transactionId, business.getId());

        byte[] content;
        try {
            content = file.getBytes();
        } catch (IOException e) {
            throw new IllegalArgumentException("Failed to read uploaded receipt file.");
        }

        if (content.length == 0 || content.length > maxFileSizeBytes) {
            throw new IllegalArgumentException("Receipt file size is invalid or exceeds limit.");
        }

        String normalizedMime = normalizeMime(file.getContentType());
        String detectedMime = detectMimeFromMagicBytes(content);
        if (detectedMime == null || !ALLOWED_MIME_TO_EXT.containsKey(detectedMime)) {
            throw new IllegalArgumentException("Unsupported or invalid file content. Only PDF, JPEG, PNG, and WEBP receipts are accepted.");
        }
        if (normalizedMime != null && !normalizedMime.equals("application/octet-stream") && !normalizedMime.equals(detectedMime)) {
            throw new IllegalArgumentException("File content does not match declared content type (" + normalizedMime + ").");
        }

        String ext = ALLOWED_MIME_TO_EXT.get(detectedMime);
        String sanitizedFilename = sanitizeFilename(file.getOriginalFilename(), ext);
        String checksum = sha256Hex(content);
        String objectKey = String.format("businesses/%s/transactions/%s/%s.%s",
                business.getId(), tx.getId(), UUID.randomUUID(), ext);

        objectStorageService.putObject(objectKey, content, detectedMime);

        Receipt receipt = new Receipt();
        receipt.setBusiness(business);
        receipt.setTransaction(tx);
        receipt.setUploadedBy(user);
        receipt.setObjectKey(objectKey);
        receipt.setOriginalFilename(sanitizedFilename);
        receipt.setContentType(detectedMime);
        receipt.setFileSizeBytes(content.length);
        receipt.setSha256Checksum(checksum);

        try {
            receipt = receiptRepository.save(receipt);
        } catch (RuntimeException ex) {
            // Best-effort cleanup of orphaned object if DB persistence fails
            try {
                objectStorageService.deleteObject(objectKey);
            } catch (Exception ignored) {
                // ignore secondary cleanup failure
            }
            throw ex;
        }

        auditService.log(user, "UPLOAD_RECEIPT", "Receipt", receipt.getId(), null);
        return toDTO(receipt);
    }

    @Transactional(readOnly = true)
    public List<ReceiptDTO> listForTransaction(String userEmail, UUID transactionId) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        loadOwnedTransaction(transactionId, business.getId());
        return receiptRepository.findActiveByBusinessIdAndTransactionId(business.getId(), transactionId)
                .stream()
                .map(this::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public PresignedDownloadDTO getDownloadUrl(String userEmail, UUID receiptId) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Receipt receipt = loadOwnedReceipt(receiptId, business.getId());
        String url = objectStorageService.generatePresignedGetUrl(receipt.getObjectKey(), presignExpirySeconds);
        return new PresignedDownloadDTO(
                receipt.getId(),
                url,
                presignExpirySeconds,
                receipt.getOriginalFilename(),
                receipt.getContentType()
        );
    }

    @Transactional(readOnly = true)
    public ReceiptContent downloadContent(String userEmail, UUID receiptId) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Receipt receipt = loadOwnedReceipt(receiptId, business.getId());
        byte[] bytes = objectStorageService.getObject(receipt.getObjectKey());
        return new ReceiptContent(bytes, receipt.getOriginalFilename(), receipt.getContentType());
    }

    @Transactional
    public void delete(String userEmail, UUID receiptId) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);
        Receipt receipt = loadOwnedReceipt(receiptId, business.getId());

        objectStorageService.deleteObject(receipt.getObjectKey());
        receipt.setDeletedAt(Instant.now());
        receiptRepository.save(receipt);
        auditService.log(user, "DELETE_RECEIPT", "Receipt", receipt.getId(), null);
    }

    private Transaction loadOwnedTransaction(UUID transactionId, UUID businessId) {
        Transaction tx = transactionRepository.findActiveById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found: " + transactionId));
        if (tx.getBusiness() == null || !tx.getBusiness().getId().equals(businessId)) {
            throw new ForbiddenException("Unauthorized: Transaction belongs to another business.");
        }
        return tx;
    }

    private Receipt loadOwnedReceipt(UUID receiptId, UUID businessId) {
        Receipt receipt = receiptRepository.findActiveById(receiptId)
                .orElseThrow(() -> new ResourceNotFoundException("Receipt not found: " + receiptId));
        if (receipt.getBusiness() == null || !receipt.getBusiness().getId().equals(businessId)) {
            throw new ForbiddenException("Unauthorized: Receipt belongs to another business.");
        }
        return receipt;
    }

    static String normalizeMime(String rawMime) {
        if (rawMime == null || rawMime.isBlank()) {
            return null;
        }
        String base = rawMime.split(";")[0].trim().toLowerCase(Locale.ROOT);
        if ("image/jpg".equals(base)) {
            return "image/jpeg";
        }
        return base;
    }

    static String detectMimeFromMagicBytes(byte[] data) {
        if (data == null || data.length < 4) {
            return null;
        }
        // PDF: %PDF-
        if (data.length >= 5
                && data[0] == 0x25 && data[1] == 0x50 && data[2] == 0x44 && data[3] == 0x46 && data[4] == 0x2D) {
            return "application/pdf";
        }
        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (data.length >= 8
                && (data[0] & 0xFF) == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47
                && data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A) {
            return "image/png";
        }
        // JPEG: FF D8 FF
        if ((data[0] & 0xFF) == 0xFF && (data[1] & 0xFF) == 0xD8 && (data[2] & 0xFF) == 0xFF) {
            return "image/jpeg";
        }
        // WEBP: RIFF....WEBP
        if (data.length >= 12
                && data[0] == 'R' && data[1] == 'I' && data[2] == 'F' && data[3] == 'F'
                && data[8] == 'W' && data[9] == 'E' && data[10] == 'B' && data[11] == 'P') {
            return "image/webp";
        }
        return null;
    }

    static String sanitizeFilename(String original, String fallbackExt) {
        if (original == null || original.isBlank()) {
            return "receipt." + fallbackExt;
        }
        String base = original.replace("\\", "/");
        int slash = base.lastIndexOf('/');
        if (slash >= 0) {
            base = base.substring(slash + 1);
        }
        base = base.replaceAll("[\\r\\n\\t\\p{Cntrl}\"/\\\\<>:|?*]", "_").trim();
        while (base.startsWith(".")) {
            base = base.substring(1);
        }
        if (base.isBlank()) {
            return "receipt." + fallbackExt;
        }
        if (base.length() > 200) {
            base = base.substring(0, 200);
        }
        return base;
    }

    private static String sha256Hex(byte[] bytes) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(bytes));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    private ReceiptDTO toDTO(Receipt r) {
        return new ReceiptDTO(
                r.getId(),
                r.getBusiness() != null ? r.getBusiness().getId() : null,
                r.getTransaction() != null ? r.getTransaction().getId() : null,
                r.getOriginalFilename(),
                r.getContentType(),
                r.getFileSizeBytes(),
                r.getSha256Checksum(),
                r.getCreatedAt()
        );
    }

    public record PresignedDownloadDTO(
            UUID receiptId,
            String url,
            int expiresInSeconds,
            String filename,
            String contentType
    ) {}

    public record ReceiptContent(byte[] data, String filename, String contentType) {}
}
