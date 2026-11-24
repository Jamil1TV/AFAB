package com.afab.ai.service;

import com.afab.ai.domain.AiStagedAttachment;
import com.afab.ai.domain.AiStagedAttachmentRepository;
import com.afab.ai.dto.AiAttachmentDTO;
import com.afab.ai.rag.AiEntityChangedEvent;
import com.afab.ai.rag.AiRagIndexService;
import com.afab.business.Business;
import com.afab.business.BusinessAccessGuard;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Transaction;
import com.afab.receipts.domain.Receipt;
import com.afab.receipts.repository.ReceiptRepository;
import com.afab.receipts.service.ObjectStorageService;
import com.afab.user.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Tenant-isolated multimodal staging service for both images (receipts, invoices, screenshots)
 * and documents (PDF, XLSX, CSV, TXT, JSON, MD) sent to AFAB Copilot.
 */
@Service
public class AiAttachmentService {

    private static final Logger log = LoggerFactory.getLogger(AiAttachmentService.class);
    private static final int MAX_ATTACHMENTS_PER_TURN = 3;

    public record DocumentContext(UUID id, String filename, String contentType, String extractedText) {}

    public record TurnAttachments(
            List<AiAttachmentDTO> metadata,
            List<String> imageBase64List,
            List<DocumentContext> documents,
            UUID primaryReceiptAttachmentId
    ) {
        public static TurnAttachments empty() {
            return new TurnAttachments(List.of(), List.of(), List.of(), null);
        }
    }

    public record PreviewPayload(byte[] bytes, String filename, String contentType) {}

    private static final Map<String, String> IMAGE_MIME_TO_EXT = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp"
    );

    private final AiStagedAttachmentRepository attachmentRepository;
    private final ObjectStorageService objectStorageService;
    private final ReceiptRepository receiptRepository;
    private final CurrentBusinessService currentBusinessService;
    private final AiFileExtractor fileExtractor;
    private final AiRagIndexService ragIndexService;
    private final ApplicationEventPublisher eventPublisher;
    private final long maxFileSizeBytes;

    public AiAttachmentService(
            AiStagedAttachmentRepository attachmentRepository,
            ObjectStorageService objectStorageService,
            ReceiptRepository receiptRepository,
            CurrentBusinessService currentBusinessService,
            AiFileExtractor fileExtractor,
            AiRagIndexService ragIndexService,
            ApplicationEventPublisher eventPublisher,
            @Value("${afab.minio.max-file-size-bytes:10485760}") long maxFileSizeBytes
    ) {
        this.attachmentRepository = attachmentRepository;
        this.objectStorageService = objectStorageService;
        this.receiptRepository = receiptRepository;
        this.currentBusinessService = currentBusinessService;
        this.fileExtractor = fileExtractor;
        this.ragIndexService = ragIndexService;
        this.eventPublisher = eventPublisher;
        this.maxFileSizeBytes = maxFileSizeBytes;
    }

    @Transactional
    public AiAttachmentDTO stageFile(String userEmail, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Attachment file is required and cannot be empty.");
        }
        if (file.getSize() > maxFileSizeBytes) {
            throw new IllegalArgumentException("File exceeds maximum allowed size of " + (maxFileSizeBytes / (1024 * 1024)) + " MB.");
        }

        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        byte[] content;
        try {
            content = file.getBytes();
        } catch (IOException e) {
            throw new IllegalArgumentException("Unable to read uploaded file.");
        }
        if (content.length == 0 || content.length > maxFileSizeBytes) {
            throw new IllegalArgumentException("Uploaded file size is invalid or exceeds limit.");
        }

        DetectedType detected = detectAndValidate(content, file.getContentType(), file.getOriginalFilename());
        String sanitizedFilename = sanitizeFilename(file.getOriginalFilename(), detected.ext());
        String checksum = sha256Hex(content);
        UUID id = UUID.randomUUID();
        String objectKey = String.format("ai-staging/%s/%s.%s", business.getId(), id, detected.ext());

        String extractedText = null;
        if ("DOCUMENT".equals(detected.kind())) {
            extractedText = fileExtractor.extractText(content, detected.mime(), sanitizedFilename);
        }

        objectStorageService.putObject(objectKey, content, detected.mime());

        AiStagedAttachment entity = new AiStagedAttachment();
        entity.setId(id);
        entity.setBusiness(business);
        entity.setUser(user);
        entity.setKind(detected.kind());
        entity.setObjectKey(objectKey);
        entity.setOriginalFilename(sanitizedFilename);
        entity.setContentType(detected.mime());
        entity.setFileSizeBytes(content.length);
        entity.setSha256Checksum(checksum);
        entity.setExtractedText(extractedText);
        entity.setStatus("STAGED");
        entity.setExpiresAt(Instant.now().plus(24, ChronoUnit.HOURS));

        try {
            entity = attachmentRepository.save(entity);
        } catch (RuntimeException ex) {
            try {
                objectStorageService.deleteObject(objectKey);
            } catch (Exception ignored) {}
            throw ex;
        }

        return toDTO(entity);
    }

    @Transactional(readOnly = true)
    public PreviewPayload downloadPreview(String userEmail, UUID attachmentId) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        AiStagedAttachment att = attachmentRepository.findByIdAndBusinessId(attachmentId, business.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Attachment not found."));
        byte[] bytes = objectStorageService.getObject(att.getObjectKey());
        return new PreviewPayload(bytes, att.getOriginalFilename(), att.getContentType());
    }

    @Transactional(readOnly = true)
    public TurnAttachments loadAttachmentsForTurn(UUID businessId, List<UUID> attachmentIds) {
        if (attachmentIds == null || attachmentIds.isEmpty()) {
            return TurnAttachments.empty();
        }
        List<UUID> uniqueIds = attachmentIds.stream().filter(Objects::nonNull).distinct().limit(MAX_ATTACHMENTS_PER_TURN).toList();
        List<AiStagedAttachment> found = attachmentRepository.findAllByIdInAndBusinessId(businessId, uniqueIds);
        if (found.size() != uniqueIds.size()) {
            throw new ForbiddenException("Unauthorized or invalid attachment reference.");
        }

        List<AiAttachmentDTO> metadata = new ArrayList<>();
        List<String> imagesBase64 = new ArrayList<>();
        List<DocumentContext> docs = new ArrayList<>();
        UUID primaryReceiptId = null;

        for (AiStagedAttachment att : found) {
            if ("EXPIRED".equalsIgnoreCase(att.getStatus())) {
                throw new IllegalArgumentException("One of the attached files has expired. Please re-attach it.");
            }
            metadata.add(toDTO(att));
            if ("IMAGE".equalsIgnoreCase(att.getKind())) {
                byte[] bytes = objectStorageService.getObject(att.getObjectKey());
                imagesBase64.add(Base64.getEncoder().encodeToString(bytes));
                if (primaryReceiptId == null) {
                    primaryReceiptId = att.getId();
                }
            } else {
                String text = att.getExtractedText() != null ? att.getExtractedText() : "";
                docs.add(new DocumentContext(att.getId(), att.getOriginalFilename(), att.getContentType(), text));
                if (primaryReceiptId == null && "application/pdf".equalsIgnoreCase(att.getContentType())) {
                    primaryReceiptId = att.getId();
                }
            }
        }

        return new TurnAttachments(List.copyOf(metadata), List.copyOf(imagesBase64), List.copyOf(docs), primaryReceiptId);
    }

    @Transactional
    public Receipt promoteToTransactionReceipt(
            User user,
            Business business,
            Transaction tx,
            UUID attachmentId,
            String extractedOcrSummary
    ) {
        if (attachmentId == null) {
            return null;
        }
        AiStagedAttachment staged = attachmentRepository.findByIdAndBusinessId(attachmentId, business.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Staged attachment not found."));

        if ("PROMOTED".equalsIgnoreCase(staged.getStatus()) && staged.getPromotedReceiptId() != null) {
            return receiptRepository.findActiveById(staged.getPromotedReceiptId()).orElse(null);
        }

        String ct = staged.getContentType() != null ? staged.getContentType().toLowerCase(Locale.ROOT) : "";
        boolean receiptEligible = IMAGE_MIME_TO_EXT.containsKey(ct) || "application/pdf".equals(ct);
        if (!receiptEligible) {
            return null;
        }

        byte[] content = objectStorageService.getObject(staged.getObjectKey());
        String ext = IMAGE_MIME_TO_EXT.getOrDefault(ct, "pdf");
        String permanentKey = String.format("businesses/%s/transactions/%s/%s.%s",
                business.getId(), tx.getId(), UUID.randomUUID(), ext);

        objectStorageService.putObject(permanentKey, content, ct);

        Receipt receipt = new Receipt();
        receipt.setBusiness(business);
        receipt.setTransaction(tx);
        receipt.setUploadedBy(user);
        receipt.setObjectKey(permanentKey);
        receipt.setOriginalFilename(staged.getOriginalFilename());
        receipt.setContentType(ct);
        receipt.setFileSizeBytes(staged.getFileSizeBytes());
        receipt.setSha256Checksum(staged.getSha256Checksum());
        receipt = receiptRepository.save(receipt);

        staged.setStatus("PROMOTED");
        staged.setPromotedReceiptId(receipt.getId());
        attachmentRepository.save(staged);

        try {
            objectStorageService.deleteObject(staged.getObjectKey());
        } catch (Exception ignored) {}

        String ocrText = (extractedOcrSummary != null && !extractedOcrSummary.isBlank())
                ? extractedOcrSummary
                : staged.getExtractedText();
        if (ocrText != null && !ocrText.isBlank()) {
            ragIndexService.upsertReceiptChunk(
                    business.getId(),
                    receipt.getId(),
                    receipt.getOriginalFilename(),
                    tx.getDescription(),
                    ocrText
            );
        } else if (eventPublisher != null) {
            eventPublisher.publishEvent(new AiEntityChangedEvent(business.getId(), "RECEIPT", receipt.getId(), false));
        }

        return receipt;
    }

    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void cleanupExpiredAttachments() {
        List<AiStagedAttachment> expired = attachmentRepository.findExpiredStaged(Instant.now());
        for (AiStagedAttachment att : expired) {
            try {
                objectStorageService.deleteObject(att.getObjectKey());
            } catch (Exception e) {
                log.debug("Failed deleting expired staging object {}: {}", att.getObjectKey(), e.getMessage());
            }
            att.setStatus("EXPIRED");
        }
        if (!expired.isEmpty()) {
            attachmentRepository.saveAll(expired);
        }
    }

    private record DetectedType(String kind, String mime, String ext) {}

    private DetectedType detectAndValidate(byte[] data, String rawMime, String filename) {
        String lowerName = filename != null ? filename.toLowerCase(Locale.ROOT).trim() : "";

        // 1. Magic byte detection for images & PDF
        if (data.length >= 5 && data[0] == '%' && data[1] == 'P' && data[2] == 'D' && data[3] == 'F' && data[4] == '-') {
            return new DetectedType("DOCUMENT", "application/pdf", "pdf");
        }
        if (data.length >= 8 && (data[0] & 0xFF) == 0x89 && data[1] == 'P' && data[2] == 'N' && data[3] == 'G'
                && data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A) {
            return new DetectedType("IMAGE", "image/png", "png");
        }
        if (data.length >= 3 && (data[0] & 0xFF) == 0xFF && (data[1] & 0xFF) == 0xD8 && (data[2] & 0xFF) == 0xFF) {
            return new DetectedType("IMAGE", "image/jpeg", "jpg");
        }
        if (data.length >= 12 && data[0] == 'R' && data[1] == 'I' && data[2] == 'F' && data[3] == 'F'
                && data[8] == 'W' && data[9] == 'E' && data[10] == 'B' && data[11] == 'P') {
            return new DetectedType("IMAGE", "image/webp", "webp");
        }
        // 2. XLSX ZIP signature (PK 03 04) + .xlsx extension
        if (data.length >= 4 && data[0] == 'P' && data[1] == 'K' && data[2] == 0x03 && data[3] == 0x04
                && lowerName.endsWith(".xlsx")) {
            return new DetectedType("DOCUMENT", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "xlsx");
        }

        // 3. Text-based files (.csv, .txt, .json, .md)
        String ext = extractExtension(lowerName);
        if (Set.of("csv", "txt", "json", "md").contains(ext)) {
            assertNoBinaryNul(data);
            String mime = switch (ext) {
                case "csv" -> "text/csv";
                case "json" -> "application/json";
                case "md" -> "text/markdown";
                default -> "text/plain";
            };
            return new DetectedType("DOCUMENT", mime, ext);
        }

        throw new IllegalArgumentException(
                "Unsupported file format. Accepted formats: JPG, PNG, WEBP, PDF, XLSX, CSV, TXT, JSON, MD."
        );
    }

    private void assertNoBinaryNul(byte[] data) {
        for (byte b : data) {
            if (b == 0) {
                throw new IllegalArgumentException("Unsupported binary file content.");
            }
        }
    }

    private String extractExtension(String lowerName) {
        int dot = lowerName.lastIndexOf('.');
        return dot >= 0 && dot < lowerName.length() - 1 ? lowerName.substring(dot + 1) : "";
    }

    private String sanitizeFilename(String original, String fallbackExt) {
        if (original == null || original.isBlank()) {
            return "attachment." + fallbackExt;
        }
        String base = original.replace("\\", "/");
        int slash = base.lastIndexOf('/');
        if (slash >= 0) base = base.substring(slash + 1);
        base = base.replaceAll("[\\r\\n\\t\\p{Cntrl}\"/\\\\<>:|?*]", "_").trim();
        while (base.startsWith(".")) base = base.substring(1);
        if (base.isBlank()) return "attachment." + fallbackExt;
        return base.length() > 200 ? base.substring(0, 200) : base;
    }

    private static String sha256Hex(byte[] bytes) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(bytes));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    public AiAttachmentDTO toDTO(AiStagedAttachment a) {
        String preview = null;
        if (a.getExtractedText() != null && !a.getExtractedText().isBlank()) {
            String t = a.getExtractedText().trim();
            preview = t.length() <= 160 ? t : t.substring(0, 157) + "...";
        }
        return new AiAttachmentDTO(
                a.getId(),
                a.getKind(),
                a.getOriginalFilename(),
                a.getContentType(),
                a.getFileSizeBytes(),
                a.getExtractedText() != null && !a.getExtractedText().isBlank(),
                preview,
                a.getStatus(),
                a.getCreatedAt()
        );
    }
}
