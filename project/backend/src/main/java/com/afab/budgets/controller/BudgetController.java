package com.afab.budgets.controller;

import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetRequest;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/budgets")
@Tag(name = "Budgets", description = "Business expense budgets and deterministic spending alerts")
public class BudgetController {

    private final BudgetService budgetService;

    public BudgetController(BudgetService budgetService) {
        this.budgetService = budgetService;
    }

    @GetMapping
    @Operation(summary = "List budgets with real-time actual spending calculations")
    public ResponseEntity<List<BudgetDTO>> list(
            Authentication auth,
            @RequestParam(defaultValue = "false") boolean includeArchived
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(budgetService.list(auth.getName(), includeArchived));
    }

    @GetMapping("/summary")
    @Operation(summary = "Get active budget summary with approaching and over-budget alerts")
    public ResponseEntity<BudgetSummaryDTO> summary(Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(budgetService.getSummary(auth.getName()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a single budget with live spending metrics")
    public ResponseEntity<BudgetDTO> getById(Authentication auth, @PathVariable UUID id) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(budgetService.getById(auth.getName(), id));
    }

    @PostMapping
    @Operation(summary = "Create an overall or category-scoped expense budget")
    public ResponseEntity<BudgetDTO> create(
            Authentication auth,
            @Valid @RequestBody BudgetRequest request
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(budgetService.create(auth.getName(), request));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing budget")
    public ResponseEntity<BudgetDTO> update(
            Authentication auth,
            @PathVariable UUID id,
            @Valid @RequestBody BudgetRequest request
    ) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(budgetService.update(auth.getName(), id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Archive a budget")
    public ResponseEntity<Void> archive(Authentication auth, @PathVariable UUID id) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        budgetService.archive(auth.getName(), id);
        return ResponseEntity.noContent().build();
    }
}
