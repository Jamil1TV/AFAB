package com.afab.subscription;

import com.afab.common.entity.BaseEntity;
import com.afab.user.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "subscriptions", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id"})
})
public class Subscription extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "plan_id", nullable = false)
    private Plan plan;

    @Column(nullable = false)
    private String status = "ACTIVE"; // ACTIVE, TRIALING, PAST_DUE, CANCELED, EXPIRED

    @Column(name = "period_start", nullable = false)
    private Instant periodStart = Instant.now();

    @Column(name = "period_end")
    private Instant periodEnd;

    @Column(name = "trial_start")
    private Instant trialStart;

    @Column(name = "trial_end")
    private Instant trialEnd;

    @Column(name = "cancel_at_period_end", nullable = false)
    private Boolean cancelAtPeriodEnd = false;

    @Column(name = "canceled_at")
    private Instant canceledAt;

    @Column(name = "effective_cancel_at")
    private Instant effectiveCancelAt;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "pending_plan_id")
    private Plan pendingPlan;

    @Column(name = "pending_billing_interval", length = 20)
    private String pendingBillingInterval;

    @Column(name = "pending_change_effective_at")
    private Instant pendingChangeEffectiveAt;

    @Column(name = "stripe_customer_id")
    private String stripeCustomerId;

    @Column(name = "stripe_subscription_id")
    private String stripeSubscriptionId;

    @Column(name = "stripe_price_id")
    private String stripePriceId;

    @Column(name = "stripe_schedule_id")
    private String stripeScheduleId;

    @Column(name = "billing_interval")
    private String billingInterval;

    @Column(name = "trial_used", nullable = false)
    private Boolean trialUsed = false;

    @Column(name = "first_payment_failure_at")
    private Instant firstPaymentFailureAt;

    @Column(name = "grace_period_ends_at")
    private Instant gracePeriodEndsAt;

    @Column(name = "last_payment_failure_reason", columnDefinition = "TEXT")
    private String lastPaymentFailureReason;

    @Column(name = "last_stripe_event_created")
    private Long lastStripeEventCreated;

    @Column(name = "allocation_attention_required", nullable = false)
    private Boolean allocationAttentionRequired = false;

    @Column(name = "trial_reminder_sent_at")
    private Instant trialReminderSentAt;

    @Column(name = "grace_reminder_sent_at")
    private Instant graceReminderSentAt;

    public Subscription() {}

    public Subscription(User user, Plan plan, String status, Instant periodStart) {
        this.user = user;
        this.plan = plan;
        this.status = status;
        this.periodStart = periodStart;
    }

    public boolean isTrialActive() {
        return "TRIALING".equalsIgnoreCase(status) && trialEnd != null && trialEnd.isAfter(Instant.now());
    }

    public boolean isInGracePeriod() {
        return "PAST_DUE".equalsIgnoreCase(status)
                && gracePeriodEndsAt != null
                && gracePeriodEndsAt.isAfter(Instant.now());
    }

    public boolean isSubscribed() {
        if ("ACTIVE".equalsIgnoreCase(status)) return true;
        if (isTrialActive()) return true;
        return isInGracePeriod();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Plan getPlan() { return plan; }
    public void setPlan(Plan plan) { this.plan = plan; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getPeriodStart() { return periodStart; }
    public void setPeriodStart(Instant periodStart) { this.periodStart = periodStart; }

    public Instant getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(Instant periodEnd) { this.periodEnd = periodEnd; }

    public Instant getTrialStart() { return trialStart; }
    public void setTrialStart(Instant trialStart) { this.trialStart = trialStart; }

    public Instant getTrialEnd() { return trialEnd; }
    public void setTrialEnd(Instant trialEnd) { this.trialEnd = trialEnd; }

    public Boolean getCancelAtPeriodEnd() { return cancelAtPeriodEnd; }
    public void setCancelAtPeriodEnd(Boolean cancelAtPeriodEnd) { this.cancelAtPeriodEnd = cancelAtPeriodEnd; }

    public Instant getCanceledAt() { return canceledAt; }
    public void setCanceledAt(Instant canceledAt) { this.canceledAt = canceledAt; }

    public Instant getEffectiveCancelAt() { return effectiveCancelAt; }
    public void setEffectiveCancelAt(Instant effectiveCancelAt) { this.effectiveCancelAt = effectiveCancelAt; }

    public Plan getPendingPlan() { return pendingPlan; }
    public void setPendingPlan(Plan pendingPlan) { this.pendingPlan = pendingPlan; }

    public String getPendingBillingInterval() { return pendingBillingInterval; }
    public void setPendingBillingInterval(String pendingBillingInterval) { this.pendingBillingInterval = pendingBillingInterval; }

    public Instant getPendingChangeEffectiveAt() { return pendingChangeEffectiveAt; }
    public void setPendingChangeEffectiveAt(Instant pendingChangeEffectiveAt) { this.pendingChangeEffectiveAt = pendingChangeEffectiveAt; }

    public String getStripeCustomerId() { return stripeCustomerId; }
    public void setStripeCustomerId(String stripeCustomerId) { this.stripeCustomerId = stripeCustomerId; }

    public String getStripeSubscriptionId() { return stripeSubscriptionId; }
    public void setStripeSubscriptionId(String stripeSubscriptionId) { this.stripeSubscriptionId = stripeSubscriptionId; }

    public String getStripePriceId() { return stripePriceId; }
    public void setStripePriceId(String stripePriceId) { this.stripePriceId = stripePriceId; }

    public String getStripeScheduleId() { return stripeScheduleId; }
    public void setStripeScheduleId(String stripeScheduleId) { this.stripeScheduleId = stripeScheduleId; }

    public String getBillingInterval() { return billingInterval; }
    public void setBillingInterval(String billingInterval) { this.billingInterval = billingInterval; }

    public Boolean getTrialUsed() { return trialUsed; }
    public void setTrialUsed(Boolean trialUsed) { this.trialUsed = trialUsed; }

    public Instant getFirstPaymentFailureAt() { return firstPaymentFailureAt; }
    public void setFirstPaymentFailureAt(Instant firstPaymentFailureAt) { this.firstPaymentFailureAt = firstPaymentFailureAt; }

    public Instant getGracePeriodEndsAt() { return gracePeriodEndsAt; }
    public void setGracePeriodEndsAt(Instant gracePeriodEndsAt) { this.gracePeriodEndsAt = gracePeriodEndsAt; }

    public String getLastPaymentFailureReason() { return lastPaymentFailureReason; }
    public void setLastPaymentFailureReason(String lastPaymentFailureReason) { this.lastPaymentFailureReason = lastPaymentFailureReason; }

    public Long getLastStripeEventCreated() { return lastStripeEventCreated; }
    public void setLastStripeEventCreated(Long lastStripeEventCreated) { this.lastStripeEventCreated = lastStripeEventCreated; }

    public Boolean getAllocationAttentionRequired() { return allocationAttentionRequired; }
    public void setAllocationAttentionRequired(Boolean allocationAttentionRequired) { this.allocationAttentionRequired = allocationAttentionRequired; }

    public Instant getTrialReminderSentAt() { return trialReminderSentAt; }
    public void setTrialReminderSentAt(Instant trialReminderSentAt) { this.trialReminderSentAt = trialReminderSentAt; }

    public Instant getGraceReminderSentAt() { return graceReminderSentAt; }
    public void setGraceReminderSentAt(Instant graceReminderSentAt) { this.graceReminderSentAt = graceReminderSentAt; }
}
