package com.afab.finance.controller;

import com.afab.finance.dto.ExpenseSummaryDTO;
import com.afab.finance.dto.TransactionResponseDTO;
import com.afab.finance.service.TransactionService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/expenses")
public class ExpenseController {

    private final TransactionService transactionService;

    public ExpenseController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping("/summary")
    public ResponseEntity<ExpenseSummaryDTO> getExpenseSummary(Authentication authentication) {
        ExpenseSummaryDTO summary = transactionService.getExpenseSummary(authentication.getName());
        return ResponseEntity.ok(summary);
    }

    @GetMapping
    public ResponseEntity<TransactionResponseDTO> getExpenses(
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size,
            Authentication authentication
    ) {
        TransactionResponseDTO response = transactionService.getTransactions(
                authentication.getName(),
                "EXPENSE",
                categoryId,
                search,
                page,
                size
        );
        return ResponseEntity.ok(response);
    }
}
