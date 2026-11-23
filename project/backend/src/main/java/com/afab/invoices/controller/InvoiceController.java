package com.afab.invoices.controller;

import com.afab.finance.dto.InvoiceSummaryDTO;
import com.afab.invoices.dto.*;
import com.afab.invoices.dto.InvoiceDTO.PaymentDTO;
import com.afab.invoices.service.InvoiceService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/invoices")
public class InvoiceController {

    private final InvoiceService invoiceService;

    public InvoiceController(InvoiceService invoiceService) {
        this.invoiceService = invoiceService;
    }

    @GetMapping("/summary")
    public ResponseEntity<InvoiceSummaryDTO> getSummary(
            Authentication authentication,
            @RequestParam(value = "period", required = false, defaultValue = "month") String period
    ) {
        return ResponseEntity.ok(invoiceService.getSummary(authentication.getName(), period));
    }

    @GetMapping
    public ResponseEntity<InvoicePageDTO> listInvoices(
            @RequestParam(required = false) UUID customerId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size,
            Authentication authentication
    ) {
        return ResponseEntity.ok(invoiceService.listInvoices(
                authentication.getName(), customerId, status, search, page, size
        ));
    }

    @GetMapping("/{id}")
    public ResponseEntity<InvoiceDTO> getInvoice(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        return ResponseEntity.ok(invoiceService.getInvoiceById(authentication.getName(), id));
    }

    @PostMapping
    public ResponseEntity<InvoiceDTO> createInvoice(
            @Valid @RequestBody CreateInvoiceRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(invoiceService.createInvoice(authentication.getName(), request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<InvoiceDTO> updateDraftInvoice(
            @PathVariable UUID id,
            @Valid @RequestBody CreateInvoiceRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(invoiceService.updateDraftInvoice(authentication.getName(), id, request));
    }

    @PostMapping("/{id}/issue")
    public ResponseEntity<InvoiceDTO> issueInvoice(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "false") boolean sent,
            Authentication authentication
    ) {
        return ResponseEntity.ok(invoiceService.issueInvoice(authentication.getName(), id, sent));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<InvoiceDTO> cancelInvoice(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        return ResponseEntity.ok(invoiceService.cancelInvoice(authentication.getName(), id));
    }

    @PostMapping("/{id}/payments")
    public ResponseEntity<PaymentDTO> recordPayment(
            @PathVariable UUID id,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @Valid @RequestBody RecordPaymentRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(invoiceService.recordPayment(authentication.getName(), id, request, idempotencyKey));
    }

    @GetMapping("/{id}/payments")
    public ResponseEntity<List<PaymentDTO>> listPayments(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        return ResponseEntity.ok(invoiceService.listInvoicePayments(authentication.getName(), id));
    }
}
