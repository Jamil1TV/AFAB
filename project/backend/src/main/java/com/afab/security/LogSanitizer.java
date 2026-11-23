package com.afab.security;

import java.util.regex.Pattern;

/**
 * Utility for redacting PII and secrets before writing to application logs.
 * Prevents credential leakage and CRLF log injection.
 */
public final class LogSanitizer {

    private static final Pattern JWT_PATTERN = Pattern.compile("eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+");
    private static final Pattern TOKEN_PARAM_PATTERN = Pattern.compile("(?i)(token|code|otp|password|secret|apikey|api_key)=([^&\\s]+)");
    private static final Pattern BEARER_PATTERN = Pattern.compile("(?i)Bearer\\s+[A-Za-z0-9._~+/=-]+");

    private LogSanitizer() {}

    /**
     * Masks an email address as `a***@domain.tld` so logs remain traceable without exposing raw PII.
     */
    public static String maskEmail(String email) {
        if (email == null || email.isBlank()) {
            return "<empty>";
        }
        String trimmed = stripControlChars(email.trim());
        int atIdx = trimmed.indexOf('@');
        if (atIdx <= 0) {
            return "***";
        }
        String local = trimmed.substring(0, atIdx);
        String domain = trimmed.substring(atIdx);
        if (local.length() == 1) {
            return "*" + domain;
        }
        return local.charAt(0) + "***" + domain;
    }

    /**
     * Strips CR/LF characters and redacts JWTs, Bearer headers, and sensitive query/kv parameters.
     */
    public static String sanitizeMessage(String message) {
        if (message == null) {
            return "";
        }
        String cleaned = stripControlChars(message);
        cleaned = BEARER_PATTERN.matcher(cleaned).replaceAll("Bearer [REDACTED]");
        cleaned = JWT_PATTERN.matcher(cleaned).replaceAll("[REDACTED_JWT]");
        cleaned = TOKEN_PARAM_PATTERN.matcher(cleaned).replaceAll("$1=[REDACTED]");
        return cleaned;
    }

    private static String stripControlChars(String value) {
        return value.replace('\r', ' ').replace('\n', ' ').replace('\t', ' ').trim();
    }
}
