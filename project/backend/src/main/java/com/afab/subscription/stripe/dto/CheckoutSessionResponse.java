package com.afab.subscription.stripe.dto;

public class CheckoutSessionResponse {

    private String sessionId;
    private String url;
    private String mode; // "CHECKOUT" or "PORTAL"

    public CheckoutSessionResponse() {}

    public CheckoutSessionResponse(String sessionId, String url, String mode) {
        this.sessionId = sessionId;
        this.url = url;
        this.mode = mode;
    }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
}
