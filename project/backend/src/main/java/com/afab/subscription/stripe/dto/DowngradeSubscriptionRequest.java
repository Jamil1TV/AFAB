package com.afab.subscription.stripe.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.UUID;

public class DowngradeSubscriptionRequest {

    @NotBlank(message = "Target plan slug is required")
    private String targetPlanSlug;

    private String billingInterval;

    private List<UUID> selectedBusinessIds;

    private Boolean deferAllocation = false;

    public String getTargetPlanSlug() { return targetPlanSlug; }
    public void setTargetPlanSlug(String targetPlanSlug) { this.targetPlanSlug = targetPlanSlug; }

    public String getBillingInterval() { return billingInterval; }
    public void setBillingInterval(String billingInterval) { this.billingInterval = billingInterval; }

    public List<UUID> getSelectedBusinessIds() { return selectedBusinessIds; }
    public void setSelectedBusinessIds(List<UUID> selectedBusinessIds) { this.selectedBusinessIds = selectedBusinessIds; }

    public Boolean getDeferAllocation() { return deferAllocation; }
    public void setDeferAllocation(Boolean deferAllocation) { this.deferAllocation = deferAllocation; }
}
