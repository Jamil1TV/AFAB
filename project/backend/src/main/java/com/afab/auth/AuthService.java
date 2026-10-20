package com.afab.auth;

import com.afab.auth.domain.*;
import com.afab.auth.dto.*;
import com.afab.auth.security.JwtService;
import com.afab.auth.security.TotpService;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.mail.EmailService;
import com.afab.security.AuditService;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final VerificationTokenRepository verificationTokenRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final TotpService totpService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final AuditService auditService;
    private final EmailService emailService;

    @Value("${afab.jwt.refresh-expiration-ms}")
    private long refreshTokenExpirationMs;

    @Value("${afab.frontend-url}")
    private String frontendUrl;

    @Value("${afab.password-reset.expiration-minutes}")
    private int passwordResetExpirationMinutes;

    public AuthService(UserRepository userRepository, BusinessRepository businessRepository,
                       RefreshTokenRepository refreshTokenRepository,
                       VerificationTokenRepository verificationTokenRepository,
                       PasswordResetTokenRepository passwordResetTokenRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService, TotpService totpService,
                       AuthenticationManager authenticationManager,
                       UserDetailsService userDetailsService, AuditService auditService,
                       EmailService emailService) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.verificationTokenRepository = verificationTokenRepository;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.totpService = totpService;
        this.authenticationManager = authenticationManager;
        this.userDetailsService = userDetailsService;
        this.auditService = auditService;
        this.emailService = emailService;
    }

    @Value("${spring.profiles.active:local}")
    private String activeProfile;

    @Transactional
    public AuthResponse register(RegisterRequest request, String ipAddress, String userAgent) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already in use");
        }

        User user = new User();
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setAvatarUrl("https://api.dicebear.com/7.x/avataaars/svg?seed=" + request.getEmail());
        user = userRepository.save(user);

        Business business = new Business();
        business.setUser(user);
        business.setName(request.getBusinessName());
        business.setCurrency("USD");
        business = businessRepository.save(business);

        auditService.logSecurityEvent(user, "REGISTER_SUCCESS", ipAddress, userAgent, "{\"businessName\":\"" + request.getBusinessName() + "\"}");

        // Send Email Verification OTP
        String otp = sendVerificationOtp(user);

        AuthResponse response = buildAuthResponse(user, business.getId(), ipAddress, userAgent, false);
        if ("local".equalsIgnoreCase(activeProfile) || "dev".equalsIgnoreCase(activeProfile)) {
            response.setDevOtp(otp);
        }
        return response;
    }

    /**
     * Login with structured error handling.
     * Throws typed Spring Security exceptions that the controller maps to specific error codes.
     *
     * Exception mapping:
     * - UsernameNotFoundException → EMAIL_NOT_FOUND
     * - BadCredentialsException  → INVALID_PASSWORD
     * - DisabledException        → ACCOUNT_DISABLED
     */
    @Transactional(noRollbackFor = {BadCredentialsException.class, LockedException.class})
    public AuthResponse login(LoginRequest request, String ipAddress, String userAgent) {
        // 1) Check if user exists first — distinguish "no account" from "wrong password"
        User user = userRepository.findByEmail(request.getEmail()).orElse(null);
        if (user == null) {
            throw new UsernameNotFoundException("No account exists with this email.");
        }

        // 2) Check account status
        if (!"ACTIVE".equals(user.getStatus())) {
            throw new DisabledException("Your account has been disabled.");
        }

        // 3) Check account lockout
        if (user.getLockoutUntil() != null && user.getLockoutUntil().isAfter(Instant.now())) {
            long remainingMinutes = java.time.Duration.between(Instant.now(), user.getLockoutUntil()).toMinutes() + 1;
            throw new LockedException("Account is temporarily locked due to multiple failed login attempts. Please try again in " + remainingMinutes + " minute(s).");
        }

        // 4) Authenticate
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
            );
        } catch (DisabledException e) {
            throw new DisabledException("Your account has been disabled.");
        } catch (BadCredentialsException e) {
            int failed = user.getFailedLoginAttempts() + 1;
            user.setFailedLoginAttempts(failed);
            if (failed >= 5) {
                user.setLockoutUntil(Instant.now().plus(15, ChronoUnit.MINUTES));
                userRepository.save(user);
                auditService.logSecurityEvent(user, "ACCOUNT_LOCKED", ipAddress, userAgent, "{\"reason\":\"max_failed_attempts\"}");
                throw new LockedException("Account locked due to 5 consecutive failed login attempts. Try again in 15 minutes.");
            } else {
                userRepository.save(user);
                auditService.logSecurityEvent(user, "LOGIN_FAILED_BAD_PASSWORD", ipAddress, userAgent, "{\"failedAttempts\":" + failed + "}");
                throw new BadCredentialsException("Incorrect password. " + (5 - failed) + " attempt(s) remaining before temporary lockout.");
            }
        }

        // 5) Success — reset failed attempts & update login metadata
        user.setFailedLoginAttempts(0);
        user.setLockoutUntil(null);
        user.setLastLoginAt(Instant.now());
        user.setLastLoginIp(ipAddress);
        userRepository.save(user);

        // 6) 2FA verification challenge if enabled
        if (user.isTwoFactorEnabled()) {
            String challengeToken = jwtService.generateTwoFactorChallengeToken(user.getEmail());
            auditService.logSecurityEvent(user, "LOGIN_2FA_CHALLENGE", ipAddress, userAgent, null);
            return AuthResponse.twoFactorRequired(challengeToken);
        }

        Business business = businessRepository.findByUserId(user.getId()).orElseThrow();
        auditService.logSecurityEvent(user, "LOGIN_SUCCESS", ipAddress, userAgent, null);

        boolean rememberMe = Boolean.TRUE.equals(request.getRememberMe());
        return buildAuthResponse(user, business.getId(), ipAddress, userAgent, rememberMe);
    }

    @Transactional
    public AuthResponse verifyTwoFactorLogin(TwoFactorVerifyRequest request, String ipAddress, String userAgent) {
        String email = jwtService.validateTwoFactorChallengeToken(request.getTwoFactorToken());
        if (email == null) {
            throw new IllegalArgumentException("Two-factor authentication session expired or invalid. Please login again.");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        if (!user.isTwoFactorEnabled()) {
            throw new IllegalArgumentException("Two-factor authentication is not enabled for this account.");
        }

        String inputCode = request.getCode() != null ? request.getCode().trim() : "";
        boolean valid = totpService.verifyCode(user.getTwoFactorSecret(), inputCode);

        if (!valid) {
            valid = verifyAndConsumeBackupCode(user, inputCode, ipAddress, userAgent);
        }

        if (!valid) {
            auditService.logSecurityEvent(user, "LOGIN_2FA_FAILED", ipAddress, userAgent, "{\"reason\":\"invalid_code\"}");
            throw new BadCredentialsException("Invalid authentication code. Please check your authenticator app or backup codes.");
        }

        Business business = businessRepository.findByUserId(user.getId()).orElseThrow();
        auditService.logSecurityEvent(user, "LOGIN_2FA_SUCCESS", ipAddress, userAgent, null);

        boolean rememberMe = Boolean.TRUE.equals(request.getRememberMe());
        return buildAuthResponse(user, business.getId(), ipAddress, userAgent, rememberMe);
    }

    private boolean verifyAndConsumeBackupCode(User user, String code, String ipAddress, String userAgent) {
        if (user.getTwoFactorBackupCodes() == null || user.getTwoFactorBackupCodes().isBlank()) {
            return false;
        }

        String cleanCode = code.replace(" ", "").toUpperCase();
        String codeHash = sha256(cleanCode);

        List<String> storedHashes = new ArrayList<>(Arrays.asList(user.getTwoFactorBackupCodes().split(",")));
        if (storedHashes.remove(codeHash)) {
            user.setTwoFactorBackupCodes(String.join(",", storedHashes));
            userRepository.save(user);
            auditService.logSecurityEvent(user, "2FA_BACKUP_CODE_USED", ipAddress, userAgent, "{\"remainingCodes\":" + storedHashes.size() + "}");
            return true;
        }
        return false;
    }

    @Transactional(readOnly = true)
    public TwoFactorSetupResponse setupTwoFactor(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String secret = totpService.generateSecret();
        String qrUri = totpService.getQrCodeUri(user.getEmail(), secret, "AFAB Finance");
        List<String> backupCodes = totpService.generateBackupCodes();

        return new TwoFactorSetupResponse(secret, qrUri, backupCodes);
    }

    @Transactional
    public void enableTwoFactor(UUID userId, TwoFactorEnableRequest request, String ipAddress, String userAgent) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!totpService.verifyCode(request.getSecret(), request.getCode())) {
            throw new IllegalArgumentException("Invalid verification code. Please check the code on your authenticator app.");
        }

        user.setTwoFactorSecret(request.getSecret());
        user.setTwoFactorEnabled(true);

        if (request.getBackupCodes() != null && !request.getBackupCodes().isEmpty()) {
            List<String> hashedCodes = request.getBackupCodes().stream()
                    .map(c -> sha256(c.replace(" ", "").toUpperCase()))
                    .collect(Collectors.toList());
            user.setTwoFactorBackupCodes(String.join(",", hashedCodes));
        }

        userRepository.save(user);
        auditService.logSecurityEvent(user, "2FA_ENABLED", ipAddress, userAgent, null);
    }

    @Transactional
    public void disableTwoFactor(UUID userId, TwoFactorDisableRequest request, String ipAddress, String userAgent) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!user.isTwoFactorEnabled()) {
            throw new IllegalArgumentException("Two-factor authentication is not enabled.");
        }

        if (request.getPassword() == null || !passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            auditService.logSecurityEvent(user, "2FA_DISABLE_FAILED", ipAddress, userAgent, "{\"reason\":\"invalid_password\"}");
            throw new BadCredentialsException("Invalid password. Current password is required to disable 2FA.");
        }

        user.setTwoFactorEnabled(false);
        user.setTwoFactorSecret(null);
        user.setTwoFactorBackupCodes(null);
        userRepository.save(user);

        auditService.logSecurityEvent(user, "2FA_DISABLED", ipAddress, userAgent, null);
    }

    @Transactional
    public List<String> regenerateBackupCodes(UUID userId, String ipAddress, String userAgent) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!user.isTwoFactorEnabled()) {
            throw new IllegalArgumentException("Two-factor authentication must be enabled to regenerate backup codes.");
        }

        List<String> plainCodes = totpService.generateBackupCodes();
        List<String> hashedCodes = plainCodes.stream()
                .map(c -> sha256(c.replace(" ", "").toUpperCase()))
                .collect(Collectors.toList());

        user.setTwoFactorBackupCodes(String.join(",", hashedCodes));
        userRepository.save(user);

        auditService.logSecurityEvent(user, "2FA_BACKUP_CODES_REGENERATED", ipAddress, userAgent, null);
        return plainCodes;
    }

    @Transactional
    public AuthResponse refreshToken(String tokenHash, String ipAddress, String userAgent) {
        RefreshToken savedToken = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token"));

        if (savedToken.getRevokedAt() != null || savedToken.getExpiresAt().isBefore(Instant.now())) {
            throw new IllegalArgumentException("Refresh token is expired or revoked");
        }

        User user = savedToken.getUser();
        Business business = businessRepository.findByUserId(user.getId()).orElseThrow();

        savedToken.setRevokedAt(Instant.now());
        refreshTokenRepository.save(savedToken);

        auditService.logSecurityEvent(user, "TOKEN_REFRESH", ipAddress, userAgent, null);

        // Retain 30-day expiration if previous token had a 30-day lifetime
        boolean wasRememberMe = java.time.Duration.between(savedToken.getCreatedAt(), savedToken.getExpiresAt()).toDays() > 2;

        return buildAuthResponse(user, business.getId(), ipAddress, userAgent, wasRememberMe);
    }

    @Transactional
    public void logout(String tokenHash, String ipAddress, String userAgent) {
        refreshTokenRepository.findByTokenHash(tokenHash).ifPresent(token -> {
            token.setRevokedAt(Instant.now());
            refreshTokenRepository.save(token);
            auditService.logSecurityEvent(token.getUser(), "LOGOUT_SUCCESS", ipAddress, userAgent, null);
        });
    }

    // ── Email Verification Flow ────────────────────────

    @Transactional
    public String resendVerificationEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.getEmailVerifiedAt() != null) {
            throw new IllegalArgumentException("Email is already verified");
        }

        return sendVerificationOtp(user);
    }

    @Transactional
    public void verifyEmail(String email, String code, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.getEmailVerifiedAt() != null) {
            throw new IllegalArgumentException("Email is already verified");
        }

        VerificationToken token = verificationTokenRepository.findLatestValidToken(user.getId(), VerificationToken.TokenType.EMAIL_VERIFICATION, Instant.now())
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired verification code"));

        if (!passwordEncoder.matches(code, token.getToken())) {
            throw new IllegalArgumentException("Invalid or expired verification code");
        }

        token.setUsedAt(Instant.now());
        verificationTokenRepository.save(token);

        user.setEmailVerifiedAt(Instant.now());
        userRepository.save(user);

        auditService.logSecurityEvent(user, "EMAIL_VERIFIED", ipAddress, userAgent, null);
    }

    private String sendVerificationOtp(User user) {
        // Invalidate old tokens
        verificationTokenRepository.invalidateAllUserTokens(user.getId(), VerificationToken.TokenType.EMAIL_VERIFICATION, Instant.now());

        String otp = generateNumericOtp(6);
        String hashedOtp = passwordEncoder.encode(otp);
        VerificationToken token = new VerificationToken(
                user,
                hashedOtp,
                VerificationToken.TokenType.EMAIL_VERIFICATION,
                Instant.now().plus(15, ChronoUnit.MINUTES)
        );
        verificationTokenRepository.save(token);

        emailService.sendVerificationOtp(user.getEmail(), user.getFirstName(), otp);
        return otp;
    }

    // ── Password Reset Flow (OTP-based — existing) ────────────────────────────

    @Transactional
    public void forgotPassword(String email, String ipAddress, String userAgent) {
        userRepository.findByEmail(email).ifPresent(user -> {
            verificationTokenRepository.invalidateAllUserTokens(user.getId(), VerificationToken.TokenType.PASSWORD_RESET, Instant.now());

            String otp = generateNumericOtp(6);
            String hashedOtp = passwordEncoder.encode(otp);
            VerificationToken token = new VerificationToken(
                    user,
                    hashedOtp,
                    VerificationToken.TokenType.PASSWORD_RESET,
                    Instant.now().plus(15, ChronoUnit.MINUTES)
            );
            verificationTokenRepository.save(token);

            emailService.sendPasswordResetOtp(user.getEmail(), user.getFirstName(), otp);
            auditService.logSecurityEvent(user, "PASSWORD_RESET_REQUESTED", ipAddress, userAgent, null);
        });
        // We don't throw an error if the user isn't found to prevent email enumeration attacks
    }

    @Transactional
    public void resetPassword(String email, String code, String newPassword, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Invalid request"));

        VerificationToken token = verificationTokenRepository.findLatestValidToken(user.getId(), VerificationToken.TokenType.PASSWORD_RESET, Instant.now())
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired reset code"));

        if (!passwordEncoder.matches(code, token.getToken())) {
            throw new IllegalArgumentException("Invalid or expired reset code");
        }

        token.setUsedAt(Instant.now());
        verificationTokenRepository.save(token);

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        
        // Also revoke all refresh tokens so they are logged out of everywhere else
        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());
        userRepository.save(user);

        auditService.logSecurityEvent(user, "PASSWORD_RESET_COMPLETED", ipAddress, userAgent, null);
    }

    // ── Password Reset Flow (Link/Token-based — new) ────────────────────────

    /**
     * Generates a cryptographically random URL token, stores its SHA-256 hash,
     * and sends a password reset link to the user's email.
     * Always returns silently to prevent email enumeration.
     */
    @Transactional
    public void forgotPasswordLink(String email, String ipAddress, String userAgent) {
        userRepository.findByEmail(email).ifPresent(user -> {
            // Invalidate all existing tokens for this user
            passwordResetTokenRepository.invalidateAllUserTokens(user.getId(), Instant.now());

            // Generate a cryptographically random token
            String rawToken = UUID.randomUUID().toString();
            String tokenHash = sha256(rawToken);

            PasswordResetToken resetToken = new PasswordResetToken(
                    user,
                    tokenHash,
                    Instant.now().plus(passwordResetExpirationMinutes, ChronoUnit.MINUTES)
            );
            passwordResetTokenRepository.save(resetToken);

            // Build reset link
            String resetLink = frontendUrl + "/en/reset-password?token=" + rawToken;

            emailService.sendPasswordResetLink(user.getEmail(), user.getFirstName(), resetLink);
            auditService.logSecurityEvent(user, "PASSWORD_RESET_LINK_REQUESTED", ipAddress, userAgent, null);
        });
        // Silent return to prevent email enumeration
    }

    /**
     * Validates a password reset token without consuming it.
     * Returns the validation status.
     *
     * @return "VALID", "EXPIRED", or "INVALID"
     */
    @Transactional(readOnly = true)
    public String validateResetToken(String rawToken) {
        String tokenHash = sha256(rawToken);
        PasswordResetToken resetToken = passwordResetTokenRepository.findByTokenHash(tokenHash)
                .orElse(null);

        if (resetToken == null) {
            return "INVALID";
        }

        if (resetToken.isUsed()) {
            return "INVALID";
        }

        if (resetToken.isExpired()) {
            return "EXPIRED";
        }

        return "VALID";
    }

    /**
     * Resets the user's password using a URL token.
     * Validates the token, updates the password, invalidates the token,
     * and revokes all refresh tokens.
     */
    @Transactional
    public void resetPasswordByToken(String rawToken, String newPassword, String ipAddress, String userAgent) {
        String tokenHash = sha256(rawToken);
        PasswordResetToken resetToken = passwordResetTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new IllegalArgumentException("INVALID_TOKEN"));

        if (resetToken.isUsed()) {
            throw new IllegalArgumentException("INVALID_TOKEN");
        }

        if (resetToken.isExpired()) {
            throw new IllegalArgumentException("TOKEN_EXPIRED");
        }

        // Mark token as used
        resetToken.setUsedAt(Instant.now());
        passwordResetTokenRepository.save(resetToken);

        // Update password
        User user = resetToken.getUser();
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordChangedAt(Instant.now());
        userRepository.save(user);

        // Revoke all refresh tokens for security
        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());

        auditService.logSecurityEvent(user, "PASSWORD_RESET_BY_TOKEN_COMPLETED", ipAddress, userAgent, null);
    }

    // ── Change Password ────────────────────────────────

    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // Verify current password
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            auditService.logSecurityEvent(user, "PASSWORD_CHANGE_FAILED", ipAddress, userAgent, "{\"reason\":\"invalid_current_password\"}");
            throw new IllegalArgumentException("Current password is incorrect");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordChangedAt(Instant.now());
        userRepository.save(user);

        // Revoke all other refresh tokens so other sessions are logged out
        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());

        auditService.logSecurityEvent(user, "PASSWORD_CHANGED", ipAddress, userAgent, null);
    }

    // ── Utility Methods ────────────────────────────────

    private AuthResponse buildAuthResponse(User user, UUID businessId, String ipAddress, String userAgent, boolean rememberMe) {
        var userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String accessToken = jwtService.generateToken(userDetails);

        // 30 days = 30 * 24 * 60 * 60 * 1000 = 2,592,000,000 ms
        long expirationDuration = rememberMe ? (30L * 24L * 60L * 60L * 1000L) : refreshTokenExpirationMs;

        String refreshTokenString = UUID.randomUUID().toString();
        RefreshToken refreshToken = new RefreshToken(
                user,
                refreshTokenString,
                Instant.now().plusMillis(expirationDuration),
                userAgent != null && userAgent.length() > 255 ? userAgent.substring(0, 255) : userAgent,
                ipAddress
        );
        refreshTokenRepository.save(refreshToken);

        Business business = businessRepository.findById(businessId).orElse(null);
        boolean onboardingComplete = business != null && business.isOnboardingComplete();

        return new AuthResponse(
                accessToken,
                refreshTokenString,
                new AuthResponse.UserDto(
                        user.getId(),
                        user.getFirstName(),
                        user.getLastName(),
                        user.getEmail(),
                        businessId,
                        user.getAvatarUrl(),
                        user.getEmailVerifiedAt() != null,
                        onboardingComplete,
                        user.isTwoFactorEnabled()
                )
        );
    }

    private String generateNumericOtp(int length) {
        Random random = new Random();
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(random.nextInt(10));
        }
        return sb.toString();
    }

    /**
     * Computes SHA-256 hash of the input string and returns it as a hex string.
     */
    private String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }
}
