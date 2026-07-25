package com.afab.finance.controller;

import com.afab.finance.dto.InvoiceSummaryDTO;
import com.afab.finance.dto.TransactionResponseDTO;
import com.afab.finance.service.TransactionService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/invoices")
public class InvoiceController {

    private final TransactionService transactionService;

    public InvoiceController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping("/summary")
    public ResponseEntity<InvoiceSummaryDTO> getInvoiceSummary(Authentication authentication) {
        InvoiceSummaryDTO summary = transactionService.getInvoiceSummary(authentication.getName());
        return ResponseEntity.ok(summary);
    }

    @GetMapping
    public ResponseEntity<TransactionResponseDTO> getInvoices(
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size,
            Authentication authentication
    ) {
        TransactionResponseDTO response = transactionService.getTransactions(
                authentication.getName(),
                "INCOME",
                categoryId,
                search,
                page,
                size
        );
        return ResponseEntity.ok(response);
    }
}
