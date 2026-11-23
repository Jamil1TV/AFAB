package com.afab.invoices.dto;

import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDate;

public class RecordPaymentRequest {

    @NotNull(message = "Payment amount is required")
    @DecimalMin(value = "0.0001", message = "Payment amount must be greater than zero")
    private BigDecimal amount;

    @Pattern(regexp = "^[A-Za-z]{3}$", message = "Currency must be a 3-letter ISO code")
    private String currency;

    @NotNull(message = "Payment date is required")
    private LocalDate paymentDate;

    @Pattern(regexp = "^(BANK_TRANSFER|CARD|CREDIT_CARD|CASH|OTHER)$", message = "Invalid payment method")
    private String paymentMethod = "BANK_TRANSFER";

    @Size(max = 255)
    private String reference;

    @Size(max = 1000)
    private String notes;

    @Size(max = 128)
    private String idempotencyKey;

    @DecimalMin(value = "0.000001", message = "Exchange rate must be positive")
    private BigDecimal exchangeRate;

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public LocalDate getPaymentDate() { return paymentDate; }
    public void setPaymentDate(LocalDate paymentDate) { this.paymentDate = paymentDate; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String idempotencyKey) { this.idempotencyKey = idempotencyKey; }

    public BigDecimal getExchangeRate() { return exchangeRate; }
    public void setExchangeRate(BigDecimal exchangeRate) { this.exchangeRate = exchangeRate; }
}
