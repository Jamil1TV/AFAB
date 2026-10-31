package com.afab.mail;

/**
 * Thrown when an email could not be delivered to the SMTP server after all retry attempts.
 *
 * Callers decide how to react:
 * - Registration keeps the account and tells the client the code was not sent.
 * - Resend-verification returns 503 so the user sees a real error instead of a fake "code sent".
 * - Password-reset flows swallow it (after logging) to avoid leaking which emails exist.
 */
public class EmailDeliveryException extends RuntimeException {

    /** True when the SMTP server rejected the credentials (e.g. Gmail 535 — revoked App Password). */
    private final boolean authenticationFailure;

    public EmailDeliveryException(String message, Throwable cause, boolean authenticationFailure) {
        super(message, cause);
        this.authenticationFailure = authenticationFailure;
    }

    public boolean isAuthenticationFailure() {
        return authenticationFailure;
    }
}

