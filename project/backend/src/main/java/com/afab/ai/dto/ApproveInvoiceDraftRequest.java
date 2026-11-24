package com.afab.ai.dto;

import com.afab.invoices.dto.CreateInvoiceRequest.InvoiceItemRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public class ApproveInvoiceDraftRequest {

    @NotNull
    private UUID messageId;

    @NotBlank
    private String draftId;

    private UUID customerId;

    @NotNull
    private LocalDate issueDate;

    @NotNull
    private LocalDate dueDate;

    @Size(max = 3)
    private String currency;

    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Size(max = 2000)
    private String notes;

    private boolean issueImmediately = false;

    @NotEmpty
    @Valid
    private List<InvoiceItemRequest> items;

    public UUID getMessageId() { return messageId; }
    public void setMessageId(UUID messageId) { this.messageId = messageId; }

    public String getDraftId() { return draftId; }
    public void setDraftId(String draftId) { this.draftId = draftId; }

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public LocalDate getIssueDate() { return issueDate; }
    public void setIssueDate(LocalDate issueDate) { this.issueDate = issueDate; }

    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public BigDecimal getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(BigDecimal discountAmount) { this.discountAmount = discountAmount; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public boolean isIssueImmediately() { return issueImmediately; }
    public void setIssueImmediately(boolean issueImmediately) { this.issueImmediately = issueImmediately; }

    public List<InvoiceItemRequest> getItems() { return items; }
    public void setItems(List<InvoiceItemRequest> items) { this.items = items; }
}
