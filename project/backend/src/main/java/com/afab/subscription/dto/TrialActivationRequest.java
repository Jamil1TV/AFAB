package com.afab.subscription.dto;

import jakarta.validation.constraints.NotBlank;

public class TrialActivationRequest {

    @NotBlank(message = "Plan slug is required (e.g. 'plus' or 'pro')")
    private String planSlug;

    public TrialActivationRequest() {}

    public TrialActivationRequest(String planSlug) {
        this.planSlug = planSlug;
    }

    public String getPlanSlug() { return planSlug; }
    public void setPlanSlug(String planSlug) { this.planSlug = planSlug; }
}
