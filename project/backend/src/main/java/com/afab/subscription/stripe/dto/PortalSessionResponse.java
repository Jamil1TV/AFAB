package com.afab.subscription.stripe.dto;

public class PortalSessionResponse {

    private String url;

    public PortalSessionResponse() {}

    public PortalSessionResponse(String url) {
        this.url = url;
    }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
}
