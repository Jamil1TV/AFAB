package com.afab.finance.controller;

import com.afab.finance.dto.*;
import com.afab.finance.service.TransactionService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping
    public ResponseEntity<TransactionResponseDTO> getTransactions(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String paymentMethod,
            @RequestParam(required = false) Boolean taxDeductible,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        TransactionResponseDTO response = transactionService.getTransactions(
                authentication.getName(),
                type,
                categoryId,
                status,
                paymentMethod,
                taxDeductible,
                startDate,
                endDate,
                search,
                page,
                size
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping
    public ResponseEntity<TransactionDTO> createTransaction(
            @Valid @RequestBody CreateTransactionRequest request,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        TransactionDTO created = transactionService.createTransaction(authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<TransactionDTO> updateTransaction(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateTransactionRequest request,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        TransactionDTO updated = transactionService.updateTransaction(authentication.getName(), id, request);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTransaction(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        transactionService.deleteTransaction(authentication.getName(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/categories")
    public ResponseEntity<List<CategoryDTO>> getCategories(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        List<CategoryDTO> categories = transactionService.getCategories(authentication.getName());
        return ResponseEntity.ok(categories);
    }
}
