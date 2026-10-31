package com.afab.subscription.dto;

import jakarta.validation.constraints.NotBlank;

public class PlanSwitchRequest {

    @NotBlank(message = "Plan slug is required (e.g. 'free', 'plus', 'pro')")
    private String planSlug;

    public PlanSwitchRequest() {}

    public PlanSwitchRequest(String planSlug) {
        this.planSlug = planSlug;
    }

    public String getPlanSlug() { return planSlug; }
    public void setPlanSlug(String planSlug) { this.planSlug = planSlug; }
}
