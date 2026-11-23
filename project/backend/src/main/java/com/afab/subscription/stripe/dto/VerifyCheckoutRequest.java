package com.afab.subscription.stripe.dto;

import jakarta.validation.constraints.NotBlank;

public class VerifyCheckoutRequest {

    @NotBlank(message = "Stripe Checkout session ID is required")
    private String sessionId;

    public VerifyCheckoutRequest() {}

    public VerifyCheckoutRequest(String sessionId) {
        this.sessionId = sessionId;
    }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }
}
