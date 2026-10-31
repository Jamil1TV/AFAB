package com.afab.mail;

import jakarta.mail.AuthenticationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Continuously verifies that the SMTP server accepts our credentials.
 *
 * Why: a revoked Gmail App Password (Google auto-revokes passwords that leak, e.g. when a
 * .env file is pushed to a public repo, or when the account password changes) used to fail
 * silently — new users simply never received their verification code. This monitor:
 *  - validates config + logs into SMTP at startup,
 *  - re-checks every 30 minutes (configurable),
 *  - tracks the outcome of every real send,
 *  - logs a loud, actionable ERROR the moment delivery breaks,
 *  - exposes the status via /api/v1/health.
 */
@Component
public class MailHealthMonitor {

    private static final Logger log = LoggerFactory.getLogger(MailHealthMonitor.class);

    private final JavaMailSender mailSender;

    @Value("${spring.mail.host:}")
    private String host;

    @Value("${spring.mail.username:}")
    private String username;

    @Value("${spring.mail.password:}")
    private String password;

    @Value("${afab.mail.from:}")
    private String fromAddress;

    private volatile boolean healthy = false;
    private volatile Instant lastCheckedAt;
    private volatile Instant lastSuccessAt;
    private volatile String lastError = "Not checked yet";

    public MailHealthMonitor(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Async
    @EventListener(ApplicationReadyEvent.class)
    public void checkOnStartup() {
        validateConfiguration();
        checkConnection();
    }

    @Scheduled(
            initialDelayString = "${afab.mail.health-check-interval-ms:1800000}",
            fixedDelayString = "${afab.mail.health-check-interval-ms:1800000}")
    public void scheduledCheck() {
        checkConnection();
    }

    /** Opens an SMTP connection and authenticates without sending anything. */
    public synchronized boolean checkConnection() {
        lastCheckedAt = Instant.now();
        if (!(mailSender instanceof JavaMailSenderImpl impl)) {
            // Non-standard sender (e.g. a test double) — nothing we can probe.
            markHealthy();
            return true;
        }
        try {
            impl.testConnection();
            boolean wasUnhealthy = !healthy;
            markHealthy();
            if (wasUnhealthy) {
                log.info("✅ SMTP connection OK ({} as {}) — verification emails will be delivered.", host, username);
            }
            return true;
        } catch (Exception e) {
            recordFailure(e);
            return false;
        }
    }

    /** Called by the email service after every successful send. */
    void recordSuccess() {
        markHealthy();
    }

    /** Called by the email service after a send finally fails (and by the connection probe). */
    void recordFailure(Throwable e) {
        boolean auth = isAuthenticationFailure(e);
        healthy = false;
        lastCheckedAt = Instant.now();
        lastError = rootMessage(e);
        if (auth) {
            log.error("""

                    ════════════════════════════════════════════════════════════════════
                    ❌ SMTP AUTHENTICATION FAILED — USERS WILL NOT RECEIVE EMAILS
                       Server : {}
                       User   : {}
                       Error  : {}

                       The Gmail App Password is invalid or was revoked by Google.
                       FIX:
                        1. Go to https://myaccount.google.com/apppasswords
                           (2-Step Verification must be ON for that account)
                        2. Create a new App Password
                        3. Put it in project/.env as MAIL_PASSWORD (never commit .env!)
                        4. Recreate the backend:  docker compose up -d afab-backend
                    ════════════════════════════════════════════════════════════════════""",
                    host, username, lastError);
        } else {
            log.error("❌ SMTP delivery problem ({} as {}): {}", host, username, lastError);
        }
    }

    public boolean isHealthy() {
        return healthy;
    }

    public Map<String, Object> getStatus() {
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("status", healthy ? "UP" : "DOWN");
        status.put("lastCheckedAt", lastCheckedAt);
        status.put("lastSuccessAt", lastSuccessAt);
        if (!healthy) {
            status.put("error", lastError);
        }
        return status;
    }

    static boolean isAuthenticationFailure(Throwable e) {
        for (Throwable t = e; t != null; t = t.getCause()) {
            if (t instanceof MailAuthenticationException || t instanceof AuthenticationFailedException) {
                return true;
            }
            String msg = t.getMessage();
            if (msg != null && (msg.contains("535") || msg.contains("534") || msg.contains("BadCredentials"))) {
                return true;
            }
        }
        return false;
    }

    private void markHealthy() {
        healthy = true;
        lastSuccessAt = Instant.now();
        lastError = null;
    }

    private void validateConfiguration() {
        if (username == null || username.isBlank() || password == null || password.isBlank()) {
            log.error("❌ MAIL_USERNAME / MAIL_PASSWORD are not set — verification emails cannot be sent. "
                    + "Set them in project/.env and restart the backend.");
            return;
        }
        String compactPassword = password.replace(" ", "");
        if (host.contains("gmail") && compactPassword.length() != 16) {
            log.warn("⚠️ MAIL_PASSWORD does not look like a Gmail App Password (expected 16 letters, got {}). "
                    + "Gmail rejects normal account passwords for SMTP.", compactPassword.length());
        }
        if (host.contains("gmail") && fromAddress != null && !fromAddress.isBlank()
                && !fromAddress.equalsIgnoreCase(username)) {
            log.warn("⚠️ MAIL_FROM ({}) differs from MAIL_USERNAME ({}). Gmail will rewrite the sender unless "
                    + "it is a verified 'Send mail as' alias, and messages are more likely to land in spam.",
                    fromAddress, username);
        }
    }

    private static String rootMessage(Throwable e) {
        Throwable root = e;
        while (root.getCause() != null && root.getCause() != root) {
            root = root.getCause();
        }
        String msg = root.getMessage() != null ? root.getMessage() : root.getClass().getSimpleName();
        return msg.replaceAll("\\s+", " ").trim();
    }
}

