package com.afab.ai.controller;

import com.afab.ai.dto.*;
import com.afab.ai.service.AiCopilotService;
import com.afab.ai.service.BusinessMemoryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final AiCopilotService copilotService;
    private final BusinessMemoryService memoryService;

    public AiController(AiCopilotService copilotService, BusinessMemoryService memoryService) {
        this.copilotService = copilotService;
        this.memoryService = memoryService;
    }

    @GetMapping("/status")
    public ResponseEntity<AiStatusDTO> getStatus(Authentication authentication) {
        return ResponseEntity.ok(copilotService.getStatus(authentication.getName()));
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
