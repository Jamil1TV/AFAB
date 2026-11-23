package com.afab.subscription.stripe.dto;

public class PortalRequest {

    private String locale = "en";
    private String returnPath = "/dashboard/settings/subscription";

    public PortalRequest() {}

    public String getLocale() { return locale; }
    public void setLocale(String locale) { this.locale = locale; }

    public String getReturnPath() { return returnPath; }
    public void setReturnPath(String returnPath) { this.returnPath = returnPath; }
}
