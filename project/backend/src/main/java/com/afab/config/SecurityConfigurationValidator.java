package com.afab.config;

import io.jsonwebtoken.io.Decoders;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Fails fast on startup when critical security configuration is missing or unsafe.
 * Ensures production never silently runs with insecure cookies, placeholder secrets,
 * or development OTP leaks.
 */
@Component
public class SecurityConfigurationValidator {

    private static final Logger log = LoggerFactory.getLogger(SecurityConfigurationValidator.class);

    private static final Set<String> NON_PROD_PROFILES = Set.of("local", "dev", "test");

    private final Environment environment;

    @Value("${afab.jwt.secret:}")
    private String jwtSecret;

    @Value("${afab.auth.cookie.secure:true}")
    private boolean cookieSecure;

    @Value("${afab.auth.cookie.same-site:Lax}")
    private String cookieSameSite;

    @Value("${afab.auth.allow-dev-otp:false}")
    private boolean allowDevOtp;

    public SecurityConfigurationValidator(Environment environment) {
        this.environment = environment;
    }

    @PostConstruct
    public void validate() {
        Set<String> activeProfiles = Arrays.stream(environment.getActiveProfiles())
                .map(String::toLowerCase)
                .collect(Collectors.toSet());

        boolean isLocalOrTest = !activeProfiles.isEmpty()
                && activeProfiles.stream().allMatch(NON_PROD_PROFILES::contains);

        validateJwtSecret(isLocalOrTest);
        validateCookieSettings(isLocalOrTest);
        validateDevOtpFlag(isLocalOrTest);
    }

    private void validateJwtSecret(boolean isLocalOrTest) {
        if (jwtSecret == null || jwtSecret.isBlank()) {
            throw new IllegalStateException(
                    "JWT_SECRET must be configured via environment variable (base64-encoded, >= 256 bits).");
        }
        if (jwtSecret.startsWith("CHANGE_ME")) {
            throw new IllegalStateException(
                    "JWT_SECRET is still set to a placeholder value. Generate a cryptographic random secret.");
        }
        byte[] decoded;
        try {
            decoded = Decoders.BASE64.decode(jwtSecret.trim());
        } catch (Exception e) {
            throw new IllegalStateException("JWT_SECRET must be valid Base64.", e);
        }
        if (decoded.length < 32) {
            throw new IllegalStateException(
                    "JWT_SECRET decoded length must be at least 32 bytes (256 bits) for HS256/HS512.");
        }
        if (!isLocalOrTest) {
            log.info("JWT signing key validated ({} bytes).", decoded.length);
        }
    }

    private void validateCookieSettings(boolean isLocalOrTest) {
        String normalizedSameSite = cookieSameSite != null ? cookieSameSite.trim() : "Lax";
        if ("None".equalsIgnoreCase(normalizedSameSite) && !cookieSecure) {
            throw new IllegalStateException(
                    "Invalid cookie configuration: SameSite=None requires Secure=true.");
        }
        if (!isLocalOrTest && !cookieSecure) {
            throw new IllegalStateException(
                    "Insecure cookie configuration refused outside local/dev/test profiles: AFAB_COOKIE_SECURE must be true.");
        }
    }

    private void validateDevOtpFlag(boolean isLocalOrTest) {
        if (!isLocalOrTest && allowDevOtp) {
            throw new IllegalStateException(
                    "AFAB_ALLOW_DEV_OTP cannot be enabled outside local/dev profiles.");
        }
    }
}
