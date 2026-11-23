package com.afab.subscription.stripe.dto;

import jakarta.validation.constraints.NotBlank;

public class CheckoutRequest {

    @NotBlank(message = "Plan slug is required ('plus' or 'pro')")
    private String planSlug;

    @NotBlank(message = "Billing interval is required ('monthly' or 'yearly')")
    private String billingInterval = "monthly";

    private String locale = "en";

    private String returnPath = "/dashboard/settings/subscription";

    public CheckoutRequest() {}

    public String getPlanSlug() { return planSlug; }
    public void setPlanSlug(String planSlug) { this.planSlug = planSlug; }

    public String getBillingInterval() { return billingInterval; }
    public void setBillingInterval(String billingInterval) { this.billingInterval = billingInterval; }

    public String getLocale() { return locale; }
    public void setLocale(String locale) { this.locale = locale; }

    public String getReturnPath() { return returnPath; }
    public void setReturnPath(String returnPath) { this.returnPath = returnPath; }
}
