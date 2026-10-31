package com.afab.mail;

import jakarta.mail.AuthenticationFailedException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MailHealthMonitorTest {

    @Mock
    private JavaMailSenderImpl mailSender;

    private MailHealthMonitor monitor;

    @BeforeEach
    void setUp() {
        monitor = new MailHealthMonitor(mailSender);
    }

    @Test
    @DisplayName("checkConnection marks healthy when testConnection succeeds")
    void checkConnection_success() throws Exception {
        doNothing().when(mailSender).testConnection();

        boolean result = monitor.checkConnection();

        assertThat(result).isTrue();
        assertThat(monitor.isHealthy()).isTrue();
        Map<String, Object> status = monitor.getStatus();
        assertThat(status.get("status")).isEqualTo("UP");
        assertThat(status.get("lastCheckedAt")).isNotNull();
    }

    @Test
    @DisplayName("checkConnection records failure when testConnection throws")
    void checkConnection_failure() throws Exception {
        doThrow(new MailAuthenticationException("Authentication failed"))
                .when(mailSender).testConnection();

        boolean result = monitor.checkConnection();

        assertThat(result).isFalse();
        assertThat(monitor.isHealthy()).isFalse();
        Map<String, Object> status = monitor.getStatus();
        assertThat(status.get("status")).isEqualTo("DOWN");
        assertThat(String.valueOf(status.get("error"))).contains("Authentication failed");
    }

    @Test
    @DisplayName("isAuthenticationFailure detects auth-related exceptions")
    void isAuthenticationFailure_detection() {
        assertThat(MailHealthMonitor.isAuthenticationFailure(new MailAuthenticationException("535 BadCredentials")))
                .isTrue();
        assertThat(MailHealthMonitor.isAuthenticationFailure(new AuthenticationFailedException("Bad password")))
                .isTrue();
        assertThat(MailHealthMonitor.isAuthenticationFailure(new RuntimeException("Connection timed out")))
                .isFalse();
    }
}
