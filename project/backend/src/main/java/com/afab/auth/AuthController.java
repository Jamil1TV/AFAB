package com.afab.auth;

import com.afab.auth.dto.*;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    
    // Rate Limiting Bucket: 5 requests per minute for auth endpoints
    private final Bucket authBucket;

    public AuthController(AuthService authService) {
        this.authService = authService;
        
        Bandwidth limit = Bandwidth.builder().capacity(5).refillGreedy(5, Duration.ofMinutes(1)).build();
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
            return ResponseEntity.ok(response);
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
            return ResponseEntity.ok(response);
        } catch (UsernameNotFoundException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("EMAIL_NOT_FOUND", "No account exists with this email."));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.error("INVALID_PASSWORD", "Incorrect password."));
        } catch (DisabledException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("ACCOUNT_DISABLED", "Your account has been disabled."));
        } catch (LockedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("ACCOUNT_LOCKED", "Your account has been locked."));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ErrorResponse.error("SERVER_ERROR", "Something went wrong. Please try again later."));
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(
            @Valid @RequestBody TokenRefreshRequest request,
            HttpServletRequest httpRequest
    ) {
        try {
            AuthResponse response = authService.refreshToken(
                    request.getRefreshToken(),
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.error("INVALID_REFRESH_TOKEN", "Invalid or expired refresh token."));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            @Valid @RequestBody TokenRefreshRequest request,
            HttpServletRequest httpRequest
    ) {
        authService.logout(
                request.getRefreshToken(),
                getClientIp(httpRequest),
                httpRequest.getHeader("User-Agent")
        );
        return ResponseEntity.ok(ErrorResponse.success("Logged out successfully."));
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
            authService.resendVerificationEmail(request.getEmail());
            return ResponseEntity.ok(ErrorResponse.success("Verification code sent."));
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
