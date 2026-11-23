package com.afab.receipts.controller;

import com.afab.receipts.dto.ReceiptDTO;
import com.afab.receipts.service.ReceiptService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/receipts")
@Tag(name = "Receipts", description = "Private transaction receipt storage (MinIO/S3)")
public class ReceiptController {

    private final ReceiptService receiptService;

    public ReceiptController(ReceiptService receiptService) {
        this.receiptService = receiptService;
    }

    @PostMapping(value = "/transactions/{transactionId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload a private receipt (PDF, JPEG, PNG, WEBP) attached to a transaction")
    public ResponseEntity<ReceiptDTO> upload(
            Authentication auth,
            @PathVariable UUID transactionId,
            @RequestParam("file") MultipartFile file
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        ReceiptDTO created = receiptService.upload(auth.getName(), transactionId, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/transactions/{transactionId}")
    @Operation(summary = "List receipts attached to a transaction")
    public ResponseEntity<List<ReceiptDTO>> listForTransaction(
            Authentication auth,
            @PathVariable UUID transactionId
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(receiptService.listForTransaction(auth.getName(), transactionId));
    }

    @GetMapping("/{id}/download-url")
    @Operation(summary = "Generate a short-lived signed download URL for a private receipt")
    public ResponseEntity<ReceiptService.PresignedDownloadDTO> getDownloadUrl(
            Authentication auth,
            @PathVariable UUID id
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(receiptService.getDownloadUrl(auth.getName(), id));
    }

    @GetMapping("/{id}/content")
    @Operation(summary = "Stream authenticated receipt file bytes directly through the API")
    public ResponseEntity<byte[]> downloadContent(
            Authentication auth,
            @PathVariable UUID id
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        ReceiptService.ReceiptContent content = receiptService.downloadContent(auth.getName(), id);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType(content.contentType()));
        headers.setContentDisposition(ContentDisposition.attachment()
                .filename(content.filename(), StandardCharsets.UTF_8)
                .build());
        headers.setCacheControl("private, no-store");
        headers.set("X-Content-Type-Options", "nosniff");

        return new ResponseEntity<>(content.data(), headers, HttpStatus.OK);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a receipt from object storage and soft-delete its metadata")
    public ResponseEntity<Void> delete(Authentication auth, @PathVariable UUID id) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        receiptService.delete(auth.getName(), id);
        return ResponseEntity.noContent().build();
    }
}
