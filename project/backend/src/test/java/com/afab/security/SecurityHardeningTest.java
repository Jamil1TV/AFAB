package com.afab.security;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.afab.config.SecurityConfigurationValidator;
import com.afab.mail.MailHealthMonitor;
import com.afab.mail.SmtpEmailServiceImpl;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Base64;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class SecurityHardeningTest {

    @Test
    @DisplayName("LogSanitizer masks emails and redacts JWTs, Bearer headers, and secret params")
    void logSanitizerRedactsSensitiveData() {
        assertThat(LogSanitizer.maskEmail("founder@afab.io")).isEqualTo("f***@afab.io");
        assertThat(LogSanitizer.maskEmail("a@b.co")).isEqualTo("*@b.co");

        String raw = "Auth failed for Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0.sig123 token=supersecret123\r\nforged";
        String sanitized = LogSanitizer.sanitizeMessage(raw);

        assertThat(sanitized).doesNotContain("eyJhbGciOiJIUzI1NiJ9");
        assertThat(sanitized).doesNotContain("supersecret123");
        assertThat(sanitized).doesNotContain("\r").doesNotContain("\n");
        assertThat(sanitized).contains("[REDACTED]");
    }

    @Test
    @DisplayName("SmtpEmailServiceImpl never logs OTP codes, reset tokens, or raw emails")
    void smtpServiceDoesNotLogOtpOrResetLink() {
        JavaMailSender mailSender = mock(JavaMailSender.class);
        MailHealthMonitor monitor = mock(MailHealthMonitor.class);
        when(mailSender.createMimeMessage()).thenAnswer(inv -> new MimeMessage(Session.getInstance(new Properties())));

        SmtpEmailServiceImpl service = new SmtpEmailServiceImpl(mailSender, monitor);
        ReflectionTestUtils.setField(service, "fromAddress", "no-reply@example.com");
        ReflectionTestUtils.setField(service, "fromName", "AFAB");
        ReflectionTestUtils.setField(service, "frontendUrl", "https://app.example.com");
        ReflectionTestUtils.setField(service, "maxAttempts", 1);
        ReflectionTestUtils.setField(service, "retryBackoffMs", 1L);

        Logger logger = (Logger) LoggerFactory.getLogger(SmtpEmailServiceImpl.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);

        try {
            service.sendVerificationOtp("victim@company.com", "Alice", "839201");
            service.sendPasswordResetOtp("victim@company.com", "Alice", "445566");
            service.sendPasswordResetLink("victim@company.com", "Alice", "https://app.example.com/en/reset-password?token=SECRET_RESET_TOKEN_XYZ");

            String combinedLogs = appender.list.stream()
                    .map(ILoggingEvent::getFormattedMessage)
                    .reduce("", (a, b) -> a + "\n" + b);

            assertThat(combinedLogs).doesNotContain("839201");
            assertThat(combinedLogs).doesNotContain("445566");
            assertThat(combinedLogs).doesNotContain("SECRET_RESET_TOKEN_XYZ");
            assertThat(combinedLogs).doesNotContain("victim@company.com");
            assertThat(combinedLogs).contains("v***@company.com");
        } finally {
            logger.detachAppender(appender);
        }
    }

    @Test
    @DisplayName("SecurityConfigurationValidator rejects insecure cookies, weak secrets, and devOtp in prod")
    void securityValidatorRejectsUnsafeProductionConfig() {
        String validSecret = Base64.getEncoder().encodeToString("0123456789abcdef0123456789abcdef".getBytes());

        // 1. Rejects insecure cookie in prod
        MockEnvironment prodEnv = new MockEnvironment().withProperty("spring.profiles.active", "prod");
        prodEnv.setActiveProfiles("prod");
        SecurityConfigurationValidator insecureCookie = new SecurityConfigurationValidator(prodEnv);
        ReflectionTestUtils.setField(insecureCookie, "jwtSecret", validSecret);
        ReflectionTestUtils.setField(insecureCookie, "cookieSecure", false);
        ReflectionTestUtils.setField(insecureCookie, "cookieSameSite", "Lax");
        ReflectionTestUtils.setField(insecureCookie, "allowDevOtp", false);
        assertThatThrownBy(insecureCookie::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("AFAB_COOKIE_SECURE");

        // 2. Rejects placeholder JWT secret
        SecurityConfigurationValidator placeholderSecret = new SecurityConfigurationValidator(prodEnv);
        ReflectionTestUtils.setField(placeholderSecret, "jwtSecret", "CHANGE_ME_BASE64");
        ReflectionTestUtils.setField(placeholderSecret, "cookieSecure", true);
        ReflectionTestUtils.setField(placeholderSecret, "cookieSameSite", "Lax");
        ReflectionTestUtils.setField(placeholderSecret, "allowDevOtp", false);
        assertThatThrownBy(placeholderSecret::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("placeholder");

        // 3. Rejects allowDevOtp in prod
        SecurityConfigurationValidator devOtpInProd = new SecurityConfigurationValidator(prodEnv);
        ReflectionTestUtils.setField(devOtpInProd, "jwtSecret", validSecret);
        ReflectionTestUtils.setField(devOtpInProd, "cookieSecure", true);
        ReflectionTestUtils.setField(devOtpInProd, "cookieSameSite", "Lax");
        ReflectionTestUtils.setField(devOtpInProd, "allowDevOtp", true);
        assertThatThrownBy(devOtpInProd::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("AFAB_ALLOW_DEV_OTP");

        // 4. Accepts valid prod config
        SecurityConfigurationValidator validProd = new SecurityConfigurationValidator(prodEnv);
        ReflectionTestUtils.setField(validProd, "jwtSecret", validSecret);
        ReflectionTestUtils.setField(validProd, "cookieSecure", true);
        ReflectionTestUtils.setField(validProd, "cookieSameSite", "Lax");
        ReflectionTestUtils.setField(validProd, "allowDevOtp", false);
        validProd.validate();
    }

    @Test
    @DisplayName("ClientIpResolver ignores spoofed X-Forwarded-For unless peer is trusted proxy")
    void clientIpResolverPreventsHeaderSpoofing() {
        MockHttpServletRequest req = new MockHttpServletRequest();
        req.setRemoteAddr("203.0.113.50");
        req.addHeader("X-Forwarded-For", "1.2.3.4, 5.6.7.8");

        ClientIpResolver noTrustedProxies = new ClientIpResolver("");
        assertThat(noTrustedProxies.resolve(req)).isEqualTo("203.0.113.50");

        ClientIpResolver trustedProxy = new ClientIpResolver("10.0.0.1, 10.0.0.2");
        MockHttpServletRequest proxiedReq = new MockHttpServletRequest();
        proxiedReq.setRemoteAddr("10.0.0.2");
        proxiedReq.addHeader("X-Forwarded-For", "198.51.100.77, 10.0.0.1");
        assertThat(trustedProxy.resolve(proxiedReq)).isEqualTo("198.51.100.77");
    }
}
