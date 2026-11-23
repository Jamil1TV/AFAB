package com.afab.subscription.stripe;

import com.stripe.StripeClient;
import org.springframework.stereotype.Component;

@Component
public class StripeClientFactory {

    private final StripeProperties properties;
    private volatile String cachedKey;
    private volatile StripeClient cachedClient;

    public StripeClientFactory(StripeProperties properties) {
        this.properties = properties;
    }

    public StripeClient getClient() {
        if (!properties.isConfigured()) {
            throw new BillingNotConfiguredException(
                    "Stripe billing is not configured yet. Please set STRIPE_SECRET_KEY in project/.env."
            );
        }
        String key = properties.getSecretKey().trim();
        if (cachedClient == null || !key.equals(cachedKey)) {
            synchronized (this) {
                if (cachedClient == null || !key.equals(cachedKey)) {
                    cachedClient = new StripeClient(key);
                    cachedKey = key;
                }
            }
        }
        return cachedClient;
    }
}
