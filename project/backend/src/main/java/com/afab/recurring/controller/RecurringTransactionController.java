package com.afab.recurring.controller;

import com.afab.recurring.dto.RecurringTransactionDTO;
import com.afab.recurring.dto.RecurringTransactionRequest;
import com.afab.recurring.service.RecurringTransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/recurring-transactions")
@Tag(name = "Recurring Transactions", description = "Automated recurring income and expense rules")
public class RecurringTransactionController {

    private final RecurringTransactionService recurringService;

    public RecurringTransactionController(RecurringTransactionService recurringService) {
        this.recurringService = recurringService;
    }

    @GetMapping
    @Operation(summary = "List recurring transaction rules for the active business")
    public ResponseEntity<List<RecurringTransactionDTO>> list(Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(recurringService.list(auth.getName()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a single recurring transaction rule")
    public ResponseEntity<RecurringTransactionDTO> getById(Authentication auth, @PathVariable UUID id) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(recurringService.getById(auth.getName(), id));
    }

    @PostMapping
    @Operation(summary = "Create a recurring transaction rule")
    public ResponseEntity<RecurringTransactionDTO> create(
            Authentication auth,
            @Valid @RequestBody RecurringTransactionRequest request
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(recurringService.create(auth.getName(), request));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a recurring transaction rule")
    public ResponseEntity<RecurringTransactionDTO> update(
            Authentication auth,
            @PathVariable UUID id,
            @Valid @RequestBody RecurringTransactionRequest request
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(recurringService.update(auth.getName(), id, request));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Pause or resume a recurring transaction rule")
    public ResponseEntity<RecurringTransactionDTO> updateStatus(
            Authentication auth,
            @PathVariable UUID id,
            @RequestBody Map<String, Boolean> body
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        Boolean active = body != null ? body.get("active") : null;
        if (active == null) {
            throw new IllegalArgumentException("Field 'active' (boolean) is required.");
        }
        return ResponseEntity.ok(recurringService.setActive(auth.getName(), id, active));
    }

    @PostMapping("/{id}/run-due")
    @Operation(summary = "Manually execute any currently due occurrences for a rule (idempotent)")
    public ResponseEntity<RecurringTransactionService.RunResult> runDue(
            Authentication auth,
            @PathVariable UUID id
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(recurringService.runDueForRule(auth.getName(), id));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete (or deactivate if executed) a recurring transaction rule")
    public ResponseEntity<Void> delete(Authentication auth, @PathVariable UUID id) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        recurringService.delete(auth.getName(), id);
        return ResponseEntity.noContent().build();
    }
}
