package com.afab.subscription.stripe;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "afab.stripe")
public class StripeProperties {

    private String secretKey = "";
    private String webhookSecret = "";
    private String portalConfigurationId = "";
    private String pricePlusMonthly = "";
    private String pricePlusYearly = "";
    private String priceProMonthly = "";
    private String priceProYearly = "";

    public boolean isConfigured() {
        return secretKey != null && !secretKey.isBlank();
    }

    public boolean isWebhookConfigured() {
        return webhookSecret != null && !webhookSecret.isBlank();
    }

    public String getSecretKey() { return secretKey; }
    public void setSecretKey(String secretKey) { this.secretKey = secretKey; }

    public String getWebhookSecret() { return webhookSecret; }
    public void setWebhookSecret(String webhookSecret) { this.webhookSecret = webhookSecret; }

    public String getPortalConfigurationId() { return portalConfigurationId; }
    public void setPortalConfigurationId(String portalConfigurationId) { this.portalConfigurationId = portalConfigurationId; }

    public String getPricePlusMonthly() { return pricePlusMonthly; }
    public void setPricePlusMonthly(String pricePlusMonthly) { this.pricePlusMonthly = pricePlusMonthly; }

    public String getPricePlusYearly() { return pricePlusYearly; }
    public void setPricePlusYearly(String pricePlusYearly) { this.pricePlusYearly = pricePlusYearly; }

    public String getPriceProMonthly() { return priceProMonthly; }
    public void setPriceProMonthly(String priceProMonthly) { this.priceProMonthly = priceProMonthly; }

    public String getPriceProYearly() { return priceProYearly; }
    public void setPriceProYearly(String priceProYearly) { this.priceProYearly = priceProYearly; }
}
