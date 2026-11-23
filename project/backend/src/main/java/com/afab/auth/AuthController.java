package com.afab.auth;

import com.afab.auth.dto.*;
import com.afab.auth.security.AuthCookieService;
import com.afab.mail.EmailDeliveryException;
import com.afab.security.ClientIpResolver;
import com.afab.security.DistributedRateLimiter;
import com.afab.security.DistributedRateLimiter.Endpoint;
import com.afab.security.DistributedRateLimiter.RateLimitResult;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final AuthCookieService authCookieService;
    private final DistributedRateLimiter rateLimiter;
    private final ClientIpResolver clientIpResolver;

    @Value("${afab.jwt.refresh-expiration-ms:604800000}")
    private long refreshExpirationMs;

    public AuthController(
            AuthService authService,
            AuthCookieService authCookieService,
            DistributedRateLimiter rateLimiter,
            ClientIpResolver clientIpResolver
    ) {
        this.authService = authService;
        this.authCookieService = authCookieService;
        this.rateLimiter = rateLimiter;
        this.clientIpResolver = clientIpResolver;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.REGISTER, clientIp, request.getEmail());
        if (limited != null) return limited;

        try {
            AuthResponse response = authService.register(
                    request,
                    clientIp,
                    httpRequest.getHeader("User-Agent")
            );
            return buildAuthenticatedResponse(response, defaultRefreshMaxAgeSeconds());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("REGISTRATION_FAILED", e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.LOGIN, clientIp, request.getEmail());
        if (limited != null) return limited;

        try {
            AuthResponse response = authService.login(
                    request,
                    clientIp,
                    httpRequest.getHeader("User-Agent")
            );

            if (response.isRequiresTwoFactor()) {
                return ResponseEntity.ok(response);
            }

            long maxAgeSeconds = Boolean.TRUE.equals(request.getRememberMe())
                    ? (30L * 24 * 60 * 60)
                    : defaultRefreshMaxAgeSeconds();
            return buildAuthenticatedResponse(response, maxAgeSeconds);
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("INVALID_CREDENTIALS", "Invalid email or password."));
        } catch (DisabledException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("ACCOUNT_DISABLED", "Your account is not active."));
        } catch (LockedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("ACCOUNT_LOCKED", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse.error("SERVER_ERROR", "Something went wrong. Please try again later."));
        }
    }

    @PostMapping("/2fa/verify-login")
    public ResponseEntity<?> verifyTwoFactorLogin(
            @Valid @RequestBody TwoFactorVerifyRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.OTP_VERIFY, clientIp, null);
        if (limited != null) return limited;

        try {
            AuthResponse response = authService.verifyTwoFactorLogin(
                    request,
                    clientIp,
                    httpRequest.getHeader("User-Agent")
            );

            long maxAgeSeconds = Boolean.TRUE.equals(request.getRememberMe())
                    ? (30L * 24 * 60 * 60)
                    : defaultRefreshMaxAgeSeconds();
            return buildAuthenticatedResponse(response, maxAgeSeconds);
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("INVALID_2FA_CODE", e.getMessage()));
        } catch (DisabledException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("ACCOUNT_DISABLED", "Your account is not active."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse.error("INVALID_2FA_REQUEST", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse.error("SERVER_ERROR", "Authentication failed. Please try again."));
        }
    }

    /**
     * Rotates refresh token exclusively from HttpOnly cookie.
     * Protected by double-submit CSRF token + Origin validation.
     */
    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(
            @CookieValue(name = AuthCookieService.REFRESH_COOKIE_NAME, required = false) String cookieRefreshToken,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.REFRESH, clientIp, null);
        if (limited != null) return limited;

        if (cookieRefreshToken == null || cookieRefreshToken.isBlank()) {
            return clearCookiesUnauthorized("INVALID_REFRESH_TOKEN", "Refresh token is missing.");
        }

        if (!authCookieService.verifyCsrfAndOrigin(httpRequest)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("CSRF_VALIDATION_FAILED", "Invalid or missing CSRF token."));
        }

        try {
            AuthResponse response = authService.refreshToken(
                    cookieRefreshToken,
                    clientIp,
                    httpRequest.getHeader("User-Agent")
            );

            long maxAgeSeconds = response.isRememberMe()
                    ? (30L * 24 * 60 * 60)
                    : defaultRefreshMaxAgeSeconds();
            return buildAuthenticatedResponse(response, maxAgeSeconds);
        } catch (AuthService.RefreshTokenReuseException e) {
            return clearCookiesUnauthorized("REFRESH_TOKEN_REUSE", "Session invalidated for security. Please sign in again.");
        } catch (Exception e) {
            return clearCookiesUnauthorized("INVALID_REFRESH_TOKEN", "Invalid or expired refresh token.");
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            @CookieValue(name = AuthCookieService.REFRESH_COOKIE_NAME, required = false) String cookieRefreshToken,
            HttpServletRequest httpRequest
    ) {
        // If a refresh cookie is present, enforce CSRF so cross-site attackers cannot force logout
        if (cookieRefreshToken != null && !cookieRefreshToken.isBlank()
                && !authCookieService.verifyCsrfAndOrigin(httpRequest)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("CSRF_VALIDATION_FAILED", "Invalid or missing CSRF token."));
        }

        if (cookieRefreshToken != null && !cookieRefreshToken.isBlank()) {
            authService.logout(
                    cookieRefreshToken,
                    clientIpResolver.resolve(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
        }

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearRefreshCookie().toString())
                .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearCsrfCookie().toString())
                .body(ErrorResponse.success("Logged out successfully."));
    }

    // ── Email Verification ─────────────────────────────────

    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(
            @Valid @RequestBody VerifyEmailRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.VERIFY_EMAIL, clientIp, request.getEmail());
        if (limited != null) return limited;

        try {
            authService.verifyEmail(
                    request.getEmail(),
                    request.getCode(),
                    clientIp,
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(ErrorResponse.success("Email verified successfully."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("VERIFICATION_FAILED", e.getMessage()));
        }
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<?> resendVerification(
            @Valid @RequestBody ResendVerificationRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.VERIFY_EMAIL, clientIp, request.getEmail());
        if (limited != null) return limited;

        try {
            Optional<String> maybeDevOtp = authService.resendVerificationEmail(request.getEmail());
            Map<String, Object> body = new HashMap<>();
            body.put("success", true);
            body.put("message", "If an unverified account exists for this email, a verification code has been sent.");
            maybeDevOtp.ifPresent(otp -> body.put("devOtp", otp));
            return ResponseEntity.ok(body);
        } catch (EmailDeliveryException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ErrorResponse.error("EMAIL_DELIVERY_FAILED",
                            "We couldn't send the verification email right now. Please try again in a few minutes."));
        }
    }

    // ── Password Reset (OTP-based) ─────────────────────────────────

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.FORGOT_PASSWORD, clientIp, request.getEmail());
        if (limited != null) return limited;

        authService.forgotPassword(
                request.getEmail(),
                clientIp,
                httpRequest.getHeader("User-Agent")
        );
        return ResponseEntity.ok(ErrorResponse.success("If an account with that email exists, a reset code has been sent."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.RESET_PASSWORD, clientIp, request.getEmail());
        if (limited != null) return limited;

        try {
            authService.resetPassword(
                    request.getEmail(),
                    request.getCode(),
                    request.getNewPassword(),
                    clientIp,
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(ErrorResponse.success("Password has been reset successfully."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("RESET_FAILED", e.getMessage()));
        }
    }

    // ── Password Reset (Link/Token-based) ───────────────────────────────

    @PostMapping("/forgot-password-link")
    public ResponseEntity<?> forgotPasswordLink(
            @Valid @RequestBody ForgotPasswordRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.FORGOT_PASSWORD, clientIp, request.getEmail());
        if (limited != null) return limited;

        authService.forgotPasswordLink(
                request.getEmail(),
                clientIp,
                httpRequest.getHeader("User-Agent")
        );
        return ResponseEntity.ok(ErrorResponse.success("If an account with that email exists, a password reset link has been sent."));
    }

    @PostMapping("/validate-reset-token")
    public ResponseEntity<?> validateResetToken(
            @Valid @RequestBody ValidateTokenRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.RESET_PASSWORD, clientIp, null);
        if (limited != null) return limited;

        String status = authService.validateResetToken(request.getToken());

        return switch (status) {
            case "VALID" -> ResponseEntity.ok(ErrorResponse.success("Token is valid."));
            case "EXPIRED" -> ResponseEntity.badRequest()
                    .body(ErrorResponse.error("TOKEN_EXPIRED", "This reset link has expired."));
            default -> ResponseEntity.badRequest()
                    .body(ErrorResponse.error("INVALID_TOKEN", "Invalid reset link."));
        };
    }

    @PostMapping("/reset-password-token")
    public ResponseEntity<?> resetPasswordByToken(
            @Valid @RequestBody ResetPasswordByTokenRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = clientIpResolver.resolve(httpRequest);
        ResponseEntity<?> limited = enforceRateLimit(Endpoint.RESET_PASSWORD, clientIp, null);
        if (limited != null) return limited;

        try {
            authService.resetPasswordByToken(
                    request.getToken(),
                    request.getPassword(),
                    clientIp,
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(ErrorResponse.success("Password has been reset successfully."));
        } catch (IllegalArgumentException e) {
            String code = e.getMessage();
            return switch (code) {
                case "TOKEN_EXPIRED" -> ResponseEntity.badRequest()
                        .body(ErrorResponse.error("TOKEN_EXPIRED", "This reset link has expired."));
                case "INVALID_TOKEN" -> ResponseEntity.badRequest()
                        .body(ErrorResponse.error("INVALID_TOKEN", "Invalid reset link."));
                default -> ResponseEntity.badRequest()
                        .body(ErrorResponse.error("RESET_FAILED", "Password reset failed. Please try again."));
            };
        }
    }

    // ── Change Password ─────────────────────────────────

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            HttpServletRequest httpRequest,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("UNAUTHORIZED", "You must be logged in to change your password."));
        }

        try {
            authService.changePassword(
                    authentication.getName(),
                    request.getCurrentPassword(),
                    request.getNewPassword(),
                    clientIpResolver.resolve(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearRefreshCookie().toString())
                    .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearCsrfCookie().toString())
                    .body(ErrorResponse.success("Password changed successfully. Please sign in again."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("CHANGE_PASSWORD_FAILED", e.getMessage()));
        }
    }

    // ── Helpers ─────────────────────────────────────────────

    private ResponseEntity<AuthResponse> buildAuthenticatedResponse(AuthResponse response, long maxAgeSeconds) {
        String csrfToken = authCookieService.generateCsrfToken();
        response.setCsrfToken(csrfToken);

        ResponseCookie refreshCookie = authCookieService.buildRefreshCookie(response.getRefreshToken(), maxAgeSeconds);
        ResponseCookie csrfCookie = authCookieService.buildCsrfCookie(csrfToken, maxAgeSeconds);

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, refreshCookie.toString())
                .header(HttpHeaders.SET_COOKIE, csrfCookie.toString())
                .body(response);
    }

    private ResponseEntity<ErrorResponse> clearCookiesUnauthorized(String code, String message) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearRefreshCookie().toString())
                .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearCsrfCookie().toString())
                .body(ErrorResponse.error(code, message));
    }

    private ResponseEntity<?> enforceRateLimit(Endpoint endpoint, String clientIp, String secondaryIdentifier) {
        RateLimitResult decision = rateLimiter.check(endpoint, clientIp, secondaryIdentifier);
        if (decision.serviceUnavailable()) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .header(HttpHeaders.RETRY_AFTER, String.valueOf(decision.retryAfterSeconds()))
                    .body(ErrorResponse.error("RATE_LIMIT_UNAVAILABLE", "Authentication service is temporarily unavailable. Please try again shortly."));
        }
        if (!decision.allowed()) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .header(HttpHeaders.RETRY_AFTER, String.valueOf(decision.retryAfterSeconds()))
                    .header("X-RateLimit-Remaining", "0")
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }
        return null;
    }

    private long defaultRefreshMaxAgeSeconds() {
        return Math.max(60L, refreshExpirationMs / 1000L);
    }
}
