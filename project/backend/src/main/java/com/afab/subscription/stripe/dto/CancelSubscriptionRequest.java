package com.afab.subscription.stripe.dto;

import java.util.List;
import java.util.UUID;

public class CancelSubscriptionRequest {

    private List<UUID> selectedBusinessIds;

    public List<UUID> getSelectedBusinessIds() { return selectedBusinessIds; }
    public void setSelectedBusinessIds(List<UUID> selectedBusinessIds) { this.selectedBusinessIds = selectedBusinessIds; }
}
