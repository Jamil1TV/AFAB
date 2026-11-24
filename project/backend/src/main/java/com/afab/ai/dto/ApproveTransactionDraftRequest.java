package com.afab.ai.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public class ApproveTransactionDraftRequest {

    @NotNull
    private UUID messageId;

    @NotBlank
    private String draftId;

    @NotBlank
    private String type; // EXPENSE | INCOME

    @NotNull
    @DecimalMin(value = "0.0001")
    private BigDecimal amount;

    @Size(max = 3)
    private String originalCurrency;

    @NotBlank
    @Size(max = 255)
    private String description;

    @NotNull
    private LocalDate transactionDate;

    private UUID categoryId;
    private String paymentMethod = "BANK_TRANSFER";
    private String status = "COMPLETED";

    @Size(max = 1000)
    private String notes;

    private UUID stagedAttachmentId;

    @Size(max = 4000)
    private String extractedOcrText;

    public UUID getMessageId() { return messageId; }
    public void setMessageId(UUID messageId) { this.messageId = messageId; }

    public String getDraftId() { return draftId; }
    public void setDraftId(String draftId) { this.draftId = draftId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getOriginalCurrency() { return originalCurrency; }
    public void setOriginalCurrency(String originalCurrency) { this.originalCurrency = originalCurrency; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDate getTransactionDate() { return transactionDate; }
    public void setTransactionDate(LocalDate transactionDate) { this.transactionDate = transactionDate; }

    public UUID getCategoryId() { return categoryId; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public UUID getStagedAttachmentId() { return stagedAttachmentId; }
    public void setStagedAttachmentId(UUID stagedAttachmentId) { this.stagedAttachmentId = stagedAttachmentId; }

    public String getExtractedOcrText() { return extractedOcrText; }
    public void setExtractedOcrText(String extractedOcrText) { this.extractedOcrText = extractedOcrText; }
}
