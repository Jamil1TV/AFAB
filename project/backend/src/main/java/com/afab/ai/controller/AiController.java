package com.afab.ai.controller;

import com.afab.ai.dto.*;
import com.afab.ai.service.*;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final AiCopilotService copilotService;
    private final BusinessMemoryService memoryService;
    private final AiAttachmentService attachmentService;
    private final AiActionExecutionService actionExecutionService;
    private final AiPulseService pulseService;

    @Autowired
    public AiController(
            AiCopilotService copilotService,
            BusinessMemoryService memoryService,
            @Autowired(required = false) AiAttachmentService attachmentService,
            @Autowired(required = false) AiActionExecutionService actionExecutionService,
            @Autowired(required = false) AiPulseService pulseService
    ) {
        this.copilotService = copilotService;
        this.memoryService = memoryService;
        this.attachmentService = attachmentService;
        this.actionExecutionService = actionExecutionService;
        this.pulseService = pulseService;
    }

    @GetMapping("/status")
    public ResponseEntity<AiStatusDTO> getStatus(
            Authentication authentication,
            @RequestParam(defaultValue = "false") boolean fresh
    ) {
        return ResponseEntity.ok(copilotService.getStatus(authentication.getName(), fresh));
    }

    @GetMapping("/health")
    public ResponseEntity<AiHealthDTO> getHealth(
            @RequestParam(defaultValue = "true") boolean fresh
    ) {
        return ResponseEntity.ok(copilotService.getHealth(fresh));
    }

    @GetMapping(value = "/health/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamHealth() {
        return copilotService.streamHealth();
    }

    @GetMapping("/pulse")
    public ResponseEntity<AiPulseDTO> getPulse(Authentication authentication) {
        return ResponseEntity.ok(pulseService.getPulse(authentication.getName()));
    }

    @PostMapping("/chat")
    public ResponseEntity<AiChatResponseDTO> chat(
            Authentication authentication,
            @Valid @RequestBody AiChatRequest request
    ) {
        return ResponseEntity.ok(copilotService.chat(authentication.getName(), request));
    }

    @PostMapping(value = "/chat/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamChat(
            Authentication authentication,
            @Valid @RequestBody AiChatRequest request
    ) {
        return copilotService.streamChat(authentication.getName(), request);
    }

    @PostMapping(value = "/attachments/stage", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AiAttachmentDTO> stageAttachment(
            Authentication authentication,
            @RequestParam("file") MultipartFile file
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(attachmentService.stageFile(authentication.getName(), file));
    }

    @GetMapping("/attachments/{id}/preview")
    public ResponseEntity<byte[]> previewAttachment(
            Authentication authentication,
            @PathVariable UUID id
    ) {
        AiAttachmentService.PreviewPayload payload = attachmentService.downloadPreview(authentication.getName(), id);
        MediaType mediaType;
        try {
            mediaType = MediaType.parseMediaType(payload.contentType());
        } catch (Exception e) {
            mediaType = MediaType.APPLICATION_OCTET_STREAM;
        }
        return ResponseEntity.ok()
                .contentType(mediaType)
                .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES).cachePrivate())
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + payload.filename().replace("\"", "_") + "\"")
                .body(payload.bytes());
    }

    @PostMapping("/actions/approve-transaction")
    public ResponseEntity<AiActionDraftDTO> approveTransaction(
            Authentication authentication,
            @Valid @RequestBody ApproveTransactionDraftRequest request
    ) {
        return ResponseEntity.ok(actionExecutionService.approveTransaction(authentication.getName(), request));
    }

    @PostMapping("/actions/approve-invoice")
    public ResponseEntity<AiActionDraftDTO> approveInvoice(
            Authentication authentication,
            @Valid @RequestBody ApproveInvoiceDraftRequest request
    ) {
        return ResponseEntity.ok(actionExecutionService.approveInvoice(authentication.getName(), request));
    }

    @PostMapping("/actions/approve-budget")
    public ResponseEntity<AiActionDraftDTO> approveBudget(
            Authentication authentication,
            @Valid @RequestBody ApproveBudgetDraftRequest request
    ) {
        return ResponseEntity.ok(actionExecutionService.approveBudget(authentication.getName(), request));
    }

    @PostMapping("/actions/approve-memory")
    public ResponseEntity<AiActionDraftDTO> approveMemory(
            Authentication authentication,
            @Valid @RequestBody ApproveMemoryDraftRequest request
    ) {
        return ResponseEntity.ok(actionExecutionService.approveMemory(authentication.getName(), request));
    }

    @PatchMapping("/messages/{messageId}/drafts/{draftId}/dismiss")
    public ResponseEntity<AiActionDraftDTO> dismissDraft(
            Authentication authentication,
            @PathVariable UUID messageId,
            @PathVariable String draftId
    ) {
        return ResponseEntity.ok(actionExecutionService.dismissDraft(authentication.getName(), messageId, draftId));
    }

    @PostMapping("/index/sync")
    public ResponseEntity<AiIndexSyncResponseDTO> syncIndex(Authentication authentication) {
        return ResponseEntity.ok(copilotService.syncIndex(authentication.getName()));
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<AiConversationSummaryDTO>> listConversations(Authentication authentication) {
        return ResponseEntity.ok(copilotService.listConversations(authentication.getName()));
    }

    @GetMapping("/conversations/{id}")
    public ResponseEntity<AiConversationDetailDTO> getConversation(
            Authentication authentication,
            @PathVariable UUID id
    ) {
        return ResponseEntity.ok(copilotService.getConversation(authentication.getName(), id));
    }

    @DeleteMapping("/conversations/{id}")
    public ResponseEntity<Void> deleteConversation(
            Authentication authentication,
            @PathVariable UUID id
    ) {
        copilotService.deleteConversation(authentication.getName(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/memory")
    public ResponseEntity<List<BusinessMemoryDTO>> listMemory(
            Authentication authentication,
            @RequestParam(required = false, defaultValue = "ALL") String status
    ) {
        return ResponseEntity.ok(memoryService.list(authentication.getName(), status));
    }

    @PostMapping("/memory")
    public ResponseEntity<BusinessMemoryDTO> createMemory(
            Authentication authentication,
            @Valid @RequestBody BusinessMemoryRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(memoryService.create(authentication.getName(), request));
    }

    @PatchMapping("/memory/{id}")
    public ResponseEntity<BusinessMemoryDTO> updateMemory(
            Authentication authentication,
            @PathVariable UUID id,
            @Valid @RequestBody BusinessMemoryUpdateRequest request
    ) {
        return ResponseEntity.ok(memoryService.update(authentication.getName(), id, request));
    }

    @DeleteMapping("/memory/{id}")
    public ResponseEntity<Void> deleteMemory(
            Authentication authentication,
            @PathVariable UUID id
    ) {
        memoryService.delete(authentication.getName(), id);
        return ResponseEntity.noContent().build();
    }
}
