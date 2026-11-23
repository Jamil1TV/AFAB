package com.afab.subscription.stripe;

public class BillingNotConfiguredException extends RuntimeException {
    public BillingNotConfiguredException(String message) {
        super(message);
    }
}
