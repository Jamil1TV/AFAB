package com.afab.subscription.stripe.dto;

import com.afab.subscription.dto.SubscriptionSnapshotDTO;

public class UpgradeSubscriptionResponse {

    private String mode; // DIRECT_UPGRADE or CHECKOUT
    private String sessionId;
    private String url;
    private SubscriptionSnapshotDTO snapshot;

    public UpgradeSubscriptionResponse() {}

    public UpgradeSubscriptionResponse(String mode, String sessionId, String url, SubscriptionSnapshotDTO snapshot) {
        this.mode = mode;
        this.sessionId = sessionId;
        this.url = url;
        this.snapshot = snapshot;
    }

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public SubscriptionSnapshotDTO getSnapshot() { return snapshot; }
    public void setSnapshot(SubscriptionSnapshotDTO snapshot) { this.snapshot = snapshot; }
}
