package com.afab.subscription.stripe.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public class BillingHistoryResponse {

    private List<SubscriptionHistoryItemDTO> subscriptionHistory;
    private List<PaymentHistoryItemDTO> paymentHistory;

    public BillingHistoryResponse() {}

    public BillingHistoryResponse(
            List<SubscriptionHistoryItemDTO> subscriptionHistory,
            List<PaymentHistoryItemDTO> paymentHistory
    ) {
        this.subscriptionHistory = subscriptionHistory;
        this.paymentHistory = paymentHistory;
    }

    public static class SubscriptionHistoryItemDTO {
        private UUID id;
        private String eventType;
        private String fromPlanSlug;
        private String toPlanSlug;
        private String fromStatus;
        private String toStatus;
        private Instant effectiveAt;
        private String details;
        private Instant createdAt;

        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }

        public String getEventType() { return eventType; }
        public void setEventType(String eventType) { this.eventType = eventType; }

        public String getFromPlanSlug() { return fromPlanSlug; }
        public void setFromPlanSlug(String fromPlanSlug) { this.fromPlanSlug = fromPlanSlug; }

        public String getToPlanSlug() { return toPlanSlug; }
        public void setToPlanSlug(String toPlanSlug) { this.toPlanSlug = toPlanSlug; }

        public String getFromStatus() { return fromStatus; }
        public void setFromStatus(String fromStatus) { this.fromStatus = fromStatus; }

        public String getToStatus() { return toStatus; }
        public void setToStatus(String toStatus) { this.toStatus = toStatus; }

        public Instant getEffectiveAt() { return effectiveAt; }
        public void setEffectiveAt(Instant effectiveAt) { this.effectiveAt = effectiveAt; }

        public String getDetails() { return details; }
        public void setDetails(String details) { this.details = details; }

        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    }

    public static class PaymentHistoryItemDTO {
        private UUID id;
        private String stripeInvoiceId;
        private Long amountCents;
        private String currency;
        private String status;
        private String failureReason;
        private String hostedInvoiceUrl;
        private String invoicePdfUrl;
        private Instant paidAt;
        private Instant failedAt;
        private Instant createdAt;

        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }

        public String getStripeInvoiceId() { return stripeInvoiceId; }
        public void setStripeInvoiceId(String stripeInvoiceId) { this.stripeInvoiceId = stripeInvoiceId; }

        public Long getAmountCents() { return amountCents; }
        public void setAmountCents(Long amountCents) { this.amountCents = amountCents; }

        public String getCurrency() { return currency; }
        public void setCurrency(String currency) { this.currency = currency; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public String getFailureReason() { return failureReason; }
        public void setFailureReason(String failureReason) { this.failureReason = failureReason; }

        public String getHostedInvoiceUrl() { return hostedInvoiceUrl; }
        public void setHostedInvoiceUrl(String hostedInvoiceUrl) { this.hostedInvoiceUrl = hostedInvoiceUrl; }

        public String getInvoicePdfUrl() { return invoicePdfUrl; }
        public void setInvoicePdfUrl(String invoicePdfUrl) { this.invoicePdfUrl = invoicePdfUrl; }

        public Instant getPaidAt() { return paidAt; }
        public void setPaidAt(Instant paidAt) { this.paidAt = paidAt; }

        public Instant getFailedAt() { return failedAt; }
        public void setFailedAt(Instant failedAt) { this.failedAt = failedAt; }

        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    }

    public List<SubscriptionHistoryItemDTO> getSubscriptionHistory() { return subscriptionHistory; }
    public void setSubscriptionHistory(List<SubscriptionHistoryItemDTO> subscriptionHistory) { this.subscriptionHistory = subscriptionHistory; }

    public List<PaymentHistoryItemDTO> getPaymentHistory() { return paymentHistory; }
    public void setPaymentHistory(List<PaymentHistoryItemDTO> paymentHistory) { this.paymentHistory = paymentHistory; }
}
