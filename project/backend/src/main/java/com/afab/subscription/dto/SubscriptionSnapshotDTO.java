package com.afab.subscription.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public class SubscriptionSnapshotDTO {

    private UUID planId;
    private String planName;
    private String planSlug;
    private BigDecimal priceMonthly;
    private BigDecimal priceYearly;
    private String currency;
    private String status;
    private boolean isTrial;
    private Long trialDaysRemaining;
    private Instant periodStart;
    private Instant periodEnd;
    private Instant trialStart;
    private Instant trialEnd;
    private String billingInterval;
    private boolean cancelAtPeriodEnd;
    private Instant canceledAt;
    private Instant effectiveCancelAt;
    private String pendingPlanSlug;
    private String pendingPlanName;
    private String pendingBillingInterval;
    private Instant pendingChangeEffectiveAt;
    private Instant firstPaymentFailureAt;
    private Instant gracePeriodEndsAt;
    private Long gracePeriodHoursRemaining;
    private String lastPaymentFailureReason;
    private boolean trialUsed;
    private boolean trialEligible;
    private boolean allocationAttentionRequired;
    private int editableBusinessLimit;
    private int editableBusinessCount;
    private int totalBusinessCount;
    private boolean hasStripeCustomer;
    private boolean hasActiveStripeSubscription;
    private boolean stripeConfigured;
    private Map<String, Object> entitlements;
    private Map<String, Integer> usage;

    public SubscriptionSnapshotDTO() {}

    public UUID getPlanId() { return planId; }
    public void setPlanId(UUID planId) { this.planId = planId; }

    public String getPlanName() { return planName; }
    public void setPlanName(String planName) { this.planName = planName; }

    public String getPlanSlug() { return planSlug; }
    public void setPlanSlug(String planSlug) { this.planSlug = planSlug; }

    public BigDecimal getPriceMonthly() { return priceMonthly; }
    public void setPriceMonthly(BigDecimal priceMonthly) { this.priceMonthly = priceMonthly; }

    public BigDecimal getPriceYearly() { return priceYearly; }
    public void setPriceYearly(BigDecimal priceYearly) { this.priceYearly = priceYearly; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public boolean isTrial() { return isTrial; }
    public void setTrial(boolean trial) { isTrial = trial; }

    public Long getTrialDaysRemaining() { return trialDaysRemaining; }
    public void setTrialDaysRemaining(Long trialDaysRemaining) { this.trialDaysRemaining = trialDaysRemaining; }

    public Instant getPeriodStart() { return periodStart; }
    public void setPeriodStart(Instant periodStart) { this.periodStart = periodStart; }

    public Instant getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(Instant periodEnd) { this.periodEnd = periodEnd; }

    public Instant getTrialStart() { return trialStart; }
    public void setTrialStart(Instant trialStart) { this.trialStart = trialStart; }

    public Instant getTrialEnd() { return trialEnd; }
    public void setTrialEnd(Instant trialEnd) { this.trialEnd = trialEnd; }

    public Map<String, Object> getEntitlements() { return entitlements; }
    public void setEntitlements(Map<String, Object> entitlements) { this.entitlements = entitlements; }

    public Map<String, Integer> getUsage() { return usage; }
    public void setUsage(Map<String, Integer> usage) { this.usage = usage; }

    public String getBillingInterval() { return billingInterval; }
    public void setBillingInterval(String billingInterval) { this.billingInterval = billingInterval; }

    public boolean isCancelAtPeriodEnd() { return cancelAtPeriodEnd; }
    public void setCancelAtPeriodEnd(boolean cancelAtPeriodEnd) { this.cancelAtPeriodEnd = cancelAtPeriodEnd; }

    public Instant getCanceledAt() { return canceledAt; }
    public void setCanceledAt(Instant canceledAt) { this.canceledAt = canceledAt; }

    public Instant getEffectiveCancelAt() { return effectiveCancelAt; }
    public void setEffectiveCancelAt(Instant effectiveCancelAt) { this.effectiveCancelAt = effectiveCancelAt; }

    public String getPendingPlanSlug() { return pendingPlanSlug; }
    public void setPendingPlanSlug(String pendingPlanSlug) { this.pendingPlanSlug = pendingPlanSlug; }

    public String getPendingPlanName() { return pendingPlanName; }
    public void setPendingPlanName(String pendingPlanName) { this.pendingPlanName = pendingPlanName; }

    public String getPendingBillingInterval() { return pendingBillingInterval; }
    public void setPendingBillingInterval(String pendingBillingInterval) { this.pendingBillingInterval = pendingBillingInterval; }

    public Instant getPendingChangeEffectiveAt() { return pendingChangeEffectiveAt; }
    public void setPendingChangeEffectiveAt(Instant pendingChangeEffectiveAt) { this.pendingChangeEffectiveAt = pendingChangeEffectiveAt; }

    public Instant getFirstPaymentFailureAt() { return firstPaymentFailureAt; }
    public void setFirstPaymentFailureAt(Instant firstPaymentFailureAt) { this.firstPaymentFailureAt = firstPaymentFailureAt; }

    public Instant getGracePeriodEndsAt() { return gracePeriodEndsAt; }
    public void setGracePeriodEndsAt(Instant gracePeriodEndsAt) { this.gracePeriodEndsAt = gracePeriodEndsAt; }

    public Long getGracePeriodHoursRemaining() { return gracePeriodHoursRemaining; }
    public void setGracePeriodHoursRemaining(Long gracePeriodHoursRemaining) { this.gracePeriodHoursRemaining = gracePeriodHoursRemaining; }

    public String getLastPaymentFailureReason() { return lastPaymentFailureReason; }
    public void setLastPaymentFailureReason(String lastPaymentFailureReason) { this.lastPaymentFailureReason = lastPaymentFailureReason; }

    public boolean isTrialUsed() { return trialUsed; }
    public void setTrialUsed(boolean trialUsed) { this.trialUsed = trialUsed; }

    public boolean isTrialEligible() { return trialEligible; }
    public void setTrialEligible(boolean trialEligible) { this.trialEligible = trialEligible; }

    public boolean isAllocationAttentionRequired() { return allocationAttentionRequired; }
    public void setAllocationAttentionRequired(boolean allocationAttentionRequired) { this.allocationAttentionRequired = allocationAttentionRequired; }

    public int getEditableBusinessLimit() { return editableBusinessLimit; }
    public void setEditableBusinessLimit(int editableBusinessLimit) { this.editableBusinessLimit = editableBusinessLimit; }

    public int getEditableBusinessCount() { return editableBusinessCount; }
    public void setEditableBusinessCount(int editableBusinessCount) { this.editableBusinessCount = editableBusinessCount; }

    public int getTotalBusinessCount() { return totalBusinessCount; }
    public void setTotalBusinessCount(int totalBusinessCount) { this.totalBusinessCount = totalBusinessCount; }

    public boolean isHasStripeCustomer() { return hasStripeCustomer; }
    public void setHasStripeCustomer(boolean hasStripeCustomer) { this.hasStripeCustomer = hasStripeCustomer; }

    public boolean isHasActiveStripeSubscription() { return hasActiveStripeSubscription; }
    public void setHasActiveStripeSubscription(boolean hasActiveStripeSubscription) { this.hasActiveStripeSubscription = hasActiveStripeSubscription; }

    public boolean isStripeConfigured() { return stripeConfigured; }
    public void setStripeConfigured(boolean stripeConfigured) { this.stripeConfigured = stripeConfigured; }
}
