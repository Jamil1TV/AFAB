package com.afab.customers.controller;

import com.afab.customers.dto.*;
import com.afab.customers.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping
    public ResponseEntity<CustomerPageDTO> listCustomers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String group,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder,
            Authentication authentication
    ) {
        return ResponseEntity.ok(customerService.listCustomers(
                authentication.getName(), search, status, group, page, size, sortBy, sortOrder
        ));
    }

    @GetMapping("/summary")
    public ResponseEntity<CustomerSummaryDTO> getSummary(
            @RequestParam(defaultValue = "month") String period,
            Authentication authentication
    ) {
        return ResponseEntity.ok(customerService.getSummary(authentication.getName(), period));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CustomerDTO> getCustomer(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        return ResponseEntity.ok(customerService.getCustomerById(authentication.getName(), id));
    }

    @PostMapping
    public ResponseEntity<CustomerDTO> createCustomer(
            @Valid @RequestBody CreateCustomerRequest request,
            Authentication authentication
    ) {
        CustomerDTO created = customerService.createCustomer(authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<CustomerDTO> updateCustomer(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateCustomerRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(customerService.updateCustomer(authentication.getName(), id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> archiveCustomer(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        customerService.archiveCustomer(authentication.getName(), id);
        return ResponseEntity.noContent().build();
    }
}
