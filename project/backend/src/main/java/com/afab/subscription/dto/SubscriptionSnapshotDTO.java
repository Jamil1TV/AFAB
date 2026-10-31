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
    private Instant trialEnd;
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

    public Instant getTrialEnd() { return trialEnd; }
    public void setTrialEnd(Instant trialEnd) { this.trialEnd = trialEnd; }

    public Map<String, Object> getEntitlements() { return entitlements; }
    public void setEntitlements(Map<String, Object> entitlements) { this.entitlements = entitlements; }

    public Map<String, Integer> getUsage() { return usage; }
    public void setUsage(Map<String, Integer> usage) { this.usage = usage; }
}
