package com.afab.auth;

import com.afab.auth.dto.*;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
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
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    
    // Rate Limiting Bucket: 60 requests per minute for auth endpoints
    private final Bucket authBucket;

    @Value("${spring.profiles.active:local}")
    private String activeProfile;

    public AuthController(AuthService authService) {
        this.authService = authService;
        
        Bandwidth limit = Bandwidth.builder().capacity(60).refillGreedy(60, Duration.ofMinutes(1)).build();
        this.authBucket = Bucket.builder()
                .addLimit(limit)
                .build();
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest httpRequest
    ) {
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }

        try {
            AuthResponse response = authService.register(
                    request,
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );

            ResponseCookie cookie = ResponseCookie.from("refreshToken", response.getRefreshToken())
                    .httpOnly(true)
                    .secure(false)
                    .sameSite("Lax")
                    .path("/api/v1/auth")
                    .maxAge(24L * 60 * 60)
                    .build();

            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, cookie.toString())
                    .body(response);
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
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }

        try {
            AuthResponse response = authService.login(
                    request,
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );

            // If 2FA is required, don't set refresh cookie yet
            if (response.isRequiresTwoFactor()) {
                return ResponseEntity.ok(response);
            }

            long maxAgeSeconds = Boolean.TRUE.equals(request.getRememberMe()) ? (30L * 24 * 60 * 60) : (24L * 60 * 60);
            ResponseCookie cookie = ResponseCookie.from("refreshToken", response.getRefreshToken())
                    .httpOnly(true)
                    .secure(false)
                    .sameSite("Lax")
                    .path("/api/v1/auth")
                    .maxAge(maxAgeSeconds)
                    .build();

            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, cookie.toString())
                    .body(response);
        } catch (UsernameNotFoundException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("EMAIL_NOT_FOUND", "No account exists with this email."));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("INVALID_PASSWORD", e.getMessage()));
        } catch (DisabledException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("ACCOUNT_DISABLED", "Your account has been disabled."));
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
        try {
            AuthResponse response = authService.verifyTwoFactorLogin(
                    request,
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );

            long maxAgeSeconds = Boolean.TRUE.equals(request.getRememberMe()) ? (30L * 24 * 60 * 60) : (24L * 60 * 60);
            ResponseCookie cookie = ResponseCookie.from("refreshToken", response.getRefreshToken())
                    .httpOnly(true)
                    .secure(false)
                    .sameSite("Lax")
                    .path("/api/v1/auth")
                    .maxAge(maxAgeSeconds)
                    .build();

            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, cookie.toString())
                    .body(response);
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("INVALID_2FA_CODE", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ErrorResponse.error("INVALID_2FA_REQUEST", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse.error("SERVER_ERROR", "Authentication failed. Please try again."));
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(
            @RequestBody(required = false) TokenRefreshRequest request,
            @CookieValue(name = "refreshToken", required = false) String cookieRefreshToken,
            HttpServletRequest httpRequest
    ) {
        String token = null;
        if (cookieRefreshToken != null && !cookieRefreshToken.isBlank()) {
            token = cookieRefreshToken;
        } else if (request != null && request.getRefreshToken() != null && !request.getRefreshToken().isBlank()) {
            token = request.getRefreshToken();
        }

        if (token == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("INVALID_REFRESH_TOKEN", "Refresh token is missing."));
        }

        try {
            AuthResponse response = authService.refreshToken(
                    token,
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );

            ResponseCookie cookie = ResponseCookie.from("refreshToken", response.getRefreshToken())
                    .httpOnly(true)
                    .secure(false)
                    .sameSite("Lax")
                    .path("/api/v1/auth")
                    .maxAge(30L * 24 * 60 * 60)
                    .build();

            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, cookie.toString())
                    .body(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("INVALID_REFRESH_TOKEN", "Invalid or expired refresh token."));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            @RequestBody(required = false) TokenRefreshRequest request,
            @CookieValue(name = "refreshToken", required = false) String cookieRefreshToken,
            HttpServletRequest httpRequest
    ) {
        String token = null;
        if (cookieRefreshToken != null && !cookieRefreshToken.isBlank()) {
            token = cookieRefreshToken;
        } else if (request != null && request.getRefreshToken() != null) {
            token = request.getRefreshToken();
        }

        if (token != null) {
            authService.logout(
                    token,
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
        }

        ResponseCookie cookie = ResponseCookie.from("refreshToken", "")
                .httpOnly(true)
                .secure(false)
                .sameSite("Lax")
                .path("/api/v1/auth")
                .maxAge(0)
                .build();

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie.toString())
                .body(ErrorResponse.success("Logged out successfully."));
    }

    // ── Email Verification ─────────────────────────────────

    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(
            @Valid @RequestBody VerifyEmailRequest request,
            HttpServletRequest httpRequest
    ) {
        try {
            authService.verifyEmail(
                    request.getEmail(),
                    request.getCode(),
                    getClientIp(httpRequest),
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
            @Valid @RequestBody ResendVerificationRequest request
    ) {
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }
        try {
            String otp = authService.resendVerificationEmail(request.getEmail());
            Map<String, Object> body = new HashMap<>();
            body.put("success", true);
            body.put("message", "Verification code sent.");
            if ("local".equalsIgnoreCase(activeProfile) || "dev".equalsIgnoreCase(activeProfile)) {
                body.put("devOtp", otp);
            }
            return ResponseEntity.ok(body);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("RESEND_FAILED", e.getMessage()));
        }
    }

    // ── Password Reset (OTP-based — existing) ─────────────────────────────────

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request,
            HttpServletRequest httpRequest
    ) {
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }
        
        // We always return OK to prevent email enumeration
        authService.forgotPassword(
                request.getEmail(),
                getClientIp(httpRequest),
                httpRequest.getHeader("User-Agent")
        );
        return ResponseEntity.ok(ErrorResponse.success("If an account with that email exists, a reset code has been sent."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request,
            HttpServletRequest httpRequest
    ) {
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }
        try {
            authService.resetPassword(
                    request.getEmail(),
                    request.getCode(),
                    request.getNewPassword(),
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(ErrorResponse.success("Password has been reset successfully."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("RESET_FAILED", e.getMessage()));
        }
    }

    // ── Password Reset (Link/Token-based — new) ───────────────────────────────

    @PostMapping("/forgot-password-link")
    public ResponseEntity<?> forgotPasswordLink(
            @Valid @RequestBody ForgotPasswordRequest request,
            HttpServletRequest httpRequest
    ) {
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }

        // Always return same response to prevent email enumeration
        authService.forgotPasswordLink(
                request.getEmail(),
                getClientIp(httpRequest),
                httpRequest.getHeader("User-Agent")
        );
        return ResponseEntity.ok(ErrorResponse.success("If an account with that email exists, a password reset link has been sent."));
    }

    @PostMapping("/validate-reset-token")
    public ResponseEntity<?> validateResetToken(
            @Valid @RequestBody ValidateTokenRequest request
    ) {
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
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ErrorResponse.error("RATE_LIMITED", "Too many requests. Please wait and try again."));
        }

        try {
            authService.resetPasswordByToken(
                    request.getToken(),
                    request.getPassword(),
                    getClientIp(httpRequest),
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
            @Valid @RequestBody com.afab.auth.dto.ChangePasswordRequest request,
            HttpServletRequest httpRequest,
            org.springframework.security.core.Authentication authentication
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
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(ErrorResponse.success("Password changed successfully."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("CHANGE_PASSWORD_FAILED", e.getMessage()));
        }
    }

    // ── Utils ─────────────────────────────────────────────

    private String getClientIp(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0];
    }
}
