package com.afab.auth;

import com.afab.auth.domain.PasswordResetTokenRepository;
import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.auth.domain.VerificationTokenRepository;
import com.afab.auth.dto.AuthResponse;
import com.afab.auth.dto.LoginRequest;
import com.afab.auth.security.AuthCookieService;
import com.afab.auth.security.JwtService;
import com.afab.auth.security.TotpService;
import com.afab.business.Business;
import com.afab.business.BusinessMember;
import com.afab.business.BusinessMemberRepository;
import com.afab.business.BusinessRepository;
import com.afab.mail.EmailService;
import com.afab.security.AuditService;
import com.afab.security.ClientIpResolver;
import com.afab.security.DistributedRateLimiter;
import com.afab.security.DistributedRateLimiter.Endpoint;
import com.afab.security.DistributedRateLimiter.RateLimitResult;
import com.afab.user.User;
import com.afab.user.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthSecurityTest {

    @Mock private UserRepository userRepository;
    @Mock private BusinessRepository businessRepository;
    @Mock private BusinessMemberRepository businessMemberRepository;
    @Mock private RefreshTokenRepository refreshTokenRepository;
    @Mock private VerificationTokenRepository verificationTokenRepository;
    @Mock private PasswordResetTokenRepository passwordResetTokenRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtService jwtService;
    @Mock private TotpService totpService;
    @Mock private AuthenticationManager authenticationManager;
    @Mock private UserDetailsService userDetailsService;
    @Mock private AuditService auditService;
    @Mock private EmailService emailService;
    @Mock private DistributedRateLimiter rateLimiter;

    private AuthService authService;
    private AuthCookieService authCookieService;
    private AuthController authController;

    private User activeUser;
    private Business activeBusiness;

    @BeforeEach
    void setUp() {
        authService = new AuthService(
                userRepository, businessRepository, businessMemberRepository,
                refreshTokenRepository, verificationTokenRepository, passwordResetTokenRepository,
                passwordEncoder, jwtService, totpService, authenticationManager,
                userDetailsService, auditService, emailService
        );
        ReflectionTestUtils.setField(authService, "refreshTokenExpirationMs", 604_800_000L);
        ReflectionTestUtils.setField(authService, "frontendUrl", "https://app.example.com");
        ReflectionTestUtils.setField(authService, "passwordResetExpirationMinutes", 15);
        ReflectionTestUtils.setField(authService, "activeProfile", "prod");
        ReflectionTestUtils.setField(authService, "allowDevOtp", false);

        authCookieService = new AuthCookieService();
        ReflectionTestUtils.setField(authCookieService, "cookieSecure", true);
        ReflectionTestUtils.setField(authCookieService, "cookieSameSite", "Lax");
        ReflectionTestUtils.setField(authCookieService, "refreshPath", "/api/v1/auth");
        ReflectionTestUtils.setField(authCookieService, "csrfCookieName", "afab_csrf");
        ReflectionTestUtils.setField(authCookieService, "csrfHeaderName", "X-CSRF-Token");
        ReflectionTestUtils.setField(authCookieService, "allowedOriginsRaw", "https://app.example.com");

        authController = new AuthController(authService, authCookieService, rateLimiter, new ClientIpResolver(""));
        ReflectionTestUtils.setField(authController, "refreshExpirationMs", 604_800_000L);

        activeUser = new User("Alice", "Founder", "alice@example.com", "hashed");
        activeUser.setId(UUID.randomUUID());
        activeUser.setStatus("ACTIVE");

        activeBusiness = new Business(activeUser, "Alice Co", "USD");
        activeBusiness.setId(UUID.randomUUID());
        activeUser.setActiveBusinessId(activeBusiness.getId());
    }

    @Test
    @DisplayName("Login sets HttpOnly Secure refreshToken cookie and omits refreshToken from JSON body")
    void loginSetsSecureCookieAndHidesRefreshTokenFromJson() throws Exception {
        when(rateLimiter.check(eq(Endpoint.LOGIN), any(), any())).thenReturn(RateLimitResult.ok(9));
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(activeUser));
        BusinessMember member = new BusinessMember(activeBusiness, activeUser, "OWNER", "ACTIVE");
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(activeBusiness.getId(), activeUser.getId()))
                .thenReturn(Optional.of(member));
        when(businessRepository.findById(activeBusiness.getId())).thenReturn(Optional.of(activeBusiness));
        UserDetails ud = new org.springframework.security.core.userdetails.User("alice@example.com", "hashed", Collections.emptyList());
        when(userDetailsService.loadUserByUsername("alice@example.com")).thenReturn(ud);
        when(jwtService.generateToken(ud)).thenReturn("access-jwt-123");

        LoginRequest req = new LoginRequest();
        req.setEmail("alice@example.com");
        req.setPassword("CorrectPass123!");
        MockHttpServletRequest httpReq = new MockHttpServletRequest();
        httpReq.setRemoteAddr("198.51.100.10");

        ResponseEntity<?> response = authController.login(req, httpReq);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        List<String> cookies = response.getHeaders().get(HttpHeaders.SET_COOKIE);
        assertThat(cookies).isNotNull().hasSize(3);
        assertThat(cookies.get(0)).contains("refreshToken=").contains("Path=/api/v1/auth").contains("HttpOnly").contains("Secure").contains("SameSite=Lax");
        assertThat(cookies.get(1)).contains("refreshToken=").contains("Path=/api/v1;").contains("Max-Age=0");
        assertThat(cookies.get(2)).contains("afab_csrf=").contains("Secure");

        // Verify refresh token is stored HASHED (not plaintext) in DB
        ArgumentCaptor<RefreshToken> rtCaptor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(refreshTokenRepository).save(rtCaptor.capture());
        AuthResponse body = (AuthResponse) response.getBody();
        assertThat(body).isNotNull();
        assertThat(rtCaptor.getValue().getTokenHash()).isEqualTo(AuthService.hashToken(body.getRefreshToken()));
        assertThat(rtCaptor.getValue().getTokenHash()).isNotEqualTo(body.getRefreshToken());

        // Verify JSON serialization NEVER contains refreshToken
        String json = new ObjectMapper().writeValueAsString(body);
        assertThat(json).contains("accessToken").doesNotContain("refreshToken").doesNotContain(body.getRefreshToken());
    }

    @Test
    @DisplayName("Login does not reveal whether an email address exists")
    void loginPreventsEmailEnumeration() {
        when(rateLimiter.check(eq(Endpoint.LOGIN), any(), any())).thenReturn(RateLimitResult.ok(9));
        when(userRepository.findByEmail("unknown@example.com")).thenReturn(Optional.empty());

        LoginRequest req = new LoginRequest();
        req.setEmail("unknown@example.com");
        req.setPassword("Wrong123!");

        ResponseEntity<?> res = authController.login(req, new MockHttpServletRequest());
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(res.getBody().toString()).doesNotContain("EMAIL_NOT_FOUND");
    }

    @Test
    @DisplayName("Refresh token reuse detection revokes entire token family")
    void refreshTokenReuseRevokesFamily() {
        String rawToken = "reused-token-value";
        UUID familyId = UUID.randomUUID();
        RefreshToken revoked = new RefreshToken(
                activeUser, AuthService.hashToken(rawToken),
                Instant.now().plus(7, ChronoUnit.DAYS), "Chrome", "127.0.0.1", familyId, false
        );
        revoked.setRevokedAt(Instant.now().minusSeconds(60));
        when(refreshTokenRepository.findByTokenHash(AuthService.hashToken(rawToken)))
                .thenReturn(Optional.of(revoked));

        assertThatThrownBy(() -> authService.refreshToken(rawToken, "127.0.0.1", "Chrome"))
                .isInstanceOf(AuthService.RefreshTokenReuseException.class);

        verify(refreshTokenRepository).revokeTokenFamily(eq(familyId), any(Instant.class));
        verify(auditService).logSecurityEvent(eq(activeUser), eq("REFRESH_TOKEN_REUSE_DETECTED"), any(), any(), any());
    }

    @Test
    @DisplayName("Expired refresh token is rejected cleanly")
    void expiredRefreshTokenRejected() {
        String rawToken = "expired-token";
        RefreshToken expired = new RefreshToken(
                activeUser, AuthService.hashToken(rawToken),
                Instant.now().minusSeconds(5), "Chrome", "127.0.0.1", UUID.randomUUID(), false
        );
        when(refreshTokenRepository.findByTokenHash(AuthService.hashToken(rawToken)))
                .thenReturn(Optional.of(expired));

        assertThatThrownBy(() -> authService.refreshToken(rawToken, "127.0.0.1", "Chrome"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("expired");
    }

    @Test
    @DisplayName("Refresh endpoint enforces CSRF token + Origin check and rejects missing/mismatched CSRF with 403")
    void refreshEnforcesCsrf() {
        when(rateLimiter.check(eq(Endpoint.REFRESH), any(), any())).thenReturn(RateLimitResult.ok(29));

        MockHttpServletRequest badReq = new MockHttpServletRequest();
        badReq.addHeader("Origin", "https://evil.attacker.example");
        badReq.addHeader("X-CSRF-Token", "csrf123");
        badReq.setCookies(new Cookie("afab_csrf", "csrf123"));

        ResponseEntity<?> res = authController.refresh("some-refresh-cookie", badReq);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        MockHttpServletRequest missingHeader = new MockHttpServletRequest();
        missingHeader.addHeader("Origin", "https://app.example.com");
        missingHeader.setCookies(new Cookie("afab_csrf", "csrf123"));
        ResponseEntity<?> res2 = authController.refresh("some-refresh-cookie", missingHeader);
        assertThat(res2.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    @DisplayName("Logout revokes refresh token in DB and expires both cookies")
    void logoutRevokesSessionAndClearsCookies() {
        String rawToken = "active-refresh-token";
        RefreshToken stored = new RefreshToken(
                activeUser, AuthService.hashToken(rawToken),
                Instant.now().plus(7, ChronoUnit.DAYS), "Chrome", "127.0.0.1", UUID.randomUUID(), false
        );
        when(refreshTokenRepository.findByTokenHash(AuthService.hashToken(rawToken)))
                .thenReturn(Optional.of(stored));

        MockHttpServletRequest req = new MockHttpServletRequest();
        req.addHeader("Origin", "https://app.example.com");
        req.addHeader("X-CSRF-Token", "valid-csrf");
        req.setCookies(new Cookie("afab_csrf", "valid-csrf"));

        ResponseEntity<?> response = authController.logout(rawToken, req);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(stored.getRevokedAt()).isNotNull();
        verify(refreshTokenRepository).save(stored);
        List<String> cookies = response.getHeaders().get(HttpHeaders.SET_COOKIE);
        assertThat(cookies).hasSize(3);
        assertThat(cookies.get(0)).contains("Path=/api/v1/auth").contains("Max-Age=0");
        assertThat(cookies.get(1)).contains("Path=/api/v1;").contains("Max-Age=0");
        assertThat(cookies.get(2)).contains("afab_csrf=").contains("Max-Age=0");
    }

    @Test
    @DisplayName("Rate-limited login returns HTTP 429 with Retry-After header")
    void rateLimitedReturns429() {
        when(rateLimiter.check(eq(Endpoint.LOGIN), any(), any())).thenReturn(RateLimitResult.rejected(45));

        LoginRequest req = new LoginRequest();
        req.setEmail("alice@example.com");
        req.setPassword("secret");

        ResponseEntity<?> res = authController.login(req, new MockHttpServletRequest());
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
        assertThat(res.getHeaders().getFirst(HttpHeaders.RETRY_AFTER)).isEqualTo("45");
    }
}
