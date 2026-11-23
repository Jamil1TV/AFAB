package com.afab.invoices.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public class CreateInvoiceRequest {

    private UUID customerId;

    @NotNull(message = "Issue date is required")
    private LocalDate issueDate;

    @NotNull(message = "Due date is required")
    private LocalDate dueDate;

    @Pattern(regexp = "^[A-Za-z]{3}$", message = "Currency must be a 3-letter ISO code")
    private String currency;

    @DecimalMin(value = "0.0000", message = "Discount cannot be negative")
    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Size(max = 2000, message = "Notes cannot exceed 2000 characters")
    private String notes;

    @NotEmpty(message = "Invoice must include at least one line item")
    @Valid
    private List<InvoiceItemRequest> items;

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public LocalDate getIssueDate() { return issueDate; }
    public void setIssueDate(LocalDate issueDate) { this.issueDate = issueDate; }

    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public BigDecimal getDiscountAmount() { return discountAmount != null ? discountAmount : BigDecimal.ZERO; }
    public void setDiscountAmount(BigDecimal discountAmount) { this.discountAmount = discountAmount; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public List<InvoiceItemRequest> getItems() { return items; }
    public void setItems(List<InvoiceItemRequest> items) { this.items = items; }

    public static class InvoiceItemRequest {
        @NotBlank(message = "Item description is required")
        @Size(max = 255)
        private String description;

        @NotNull(message = "Quantity is required")
        @DecimalMin(value = "0.0001", message = "Quantity must be greater than zero")
        private BigDecimal quantity = BigDecimal.ONE;

        @NotNull(message = "Unit price is required")
        @DecimalMin(value = "0.0000", message = "Unit price cannot be negative")
        private BigDecimal unitPrice;

        @DecimalMin(value = "0.00", message = "Tax rate cannot be negative")
        @DecimalMax(value = "100.00", message = "Tax rate cannot exceed 100%")
        private BigDecimal taxRate = BigDecimal.ZERO;

        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }

        public BigDecimal getQuantity() { return quantity; }
        public void setQuantity(BigDecimal quantity) { this.quantity = quantity; }

        public BigDecimal getUnitPrice() { return unitPrice; }
        public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }

        public BigDecimal getTaxRate() { return taxRate != null ? taxRate : BigDecimal.ZERO; }
        public void setTaxRate(BigDecimal taxRate) { this.taxRate = taxRate; }
    }
}
