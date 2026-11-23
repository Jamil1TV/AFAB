package com.afab.invoices.domain;

public enum InvoiceStatus {
    DRAFT,
    SENT,
    UNPAID,
    PARTIALLY_PAID,
    PAID,
    OVERDUE,
    CANCELLED;

    public boolean isPayable() {
        return this == SENT || this == UNPAID || this == PARTIALLY_PAID || this == OVERDUE;
    }
}
