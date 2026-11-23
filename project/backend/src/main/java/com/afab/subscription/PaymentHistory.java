package com.afab.subscription;

import com.afab.user.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "payment_history")
public class PaymentHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "stripe_invoice_id", nullable = false, unique = true)
    private String stripeInvoiceId;

    @Column(name = "stripe_subscription_id")
    private String stripeSubscriptionId;

    @Column(name = "amount_cents", nullable = false)
    private Long amountCents = 0L;

    @Column(nullable = false, length = 10)
    private String currency = "USD";

    @Column(nullable = false, length = 30)
    private String status; // PAID, FAILED, OPEN

    @Column(name = "failure_reason", columnDefinition = "TEXT")
    private String failureReason;

    @Column(name = "hosted_invoice_url", columnDefinition = "TEXT")
    private String hostedInvoiceUrl;

    @Column(name = "invoice_pdf_url", columnDefinition = "TEXT")
    private String invoicePdfUrl;

    @Column(name = "paid_at")
    private Instant paidAt;

    @Column(name = "failed_at")
    private Instant failedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public PaymentHistory() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getStripeInvoiceId() { return stripeInvoiceId; }
    public void setStripeInvoiceId(String stripeInvoiceId) { this.stripeInvoiceId = stripeInvoiceId; }

    public String getStripeSubscriptionId() { return stripeSubscriptionId; }
    public void setStripeSubscriptionId(String stripeSubscriptionId) { this.stripeSubscriptionId = stripeSubscriptionId; }

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
