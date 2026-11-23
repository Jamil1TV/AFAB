package com.afab.auth;

import com.afab.auth.domain.*;
import com.afab.auth.dto.*;
import com.afab.auth.security.JwtService;
import com.afab.auth.security.TotpService;
import com.afab.business.Business;
import com.afab.business.BusinessMember;
import com.afab.business.BusinessMemberRepository;
import com.afab.business.BusinessRepository;
import com.afab.mail.EmailDeliveryException;
import com.afab.mail.EmailService;
import com.afab.security.AuditService;
import com.afab.security.LogSanitizer;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final BusinessMemberRepository businessMemberRepository;
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

    @Value("${afab.jwt.refresh-expiration-ms:604800000}")
    private long refreshTokenExpirationMs;

    @Value("${afab.frontend-url:http://localhost:3000}")
    private String frontendUrl;

    @Value("${afab.password-reset.expiration-minutes:15}")
    private int passwordResetExpirationMinutes;

    @Value("${spring.profiles.active:prod}")
    private String activeProfile;

    @Value("${afab.auth.allow-dev-otp:false}")
    private boolean allowDevOtp;

    public AuthService(UserRepository userRepository, BusinessRepository businessRepository,
                       BusinessMemberRepository businessMemberRepository,
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
        this.businessMemberRepository = businessMemberRepository;
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

    /**
     * Resolves the user's active business cleanly without assuming 1:1 user-to-business constraint.
     */
    public Business resolveUserActiveBusiness(User user) {
        if (user.getActiveBusinessId() != null) {
            Optional<BusinessMember> memberOpt = businessMemberRepository
                    .findWithBusinessByBusinessIdAndUserId(user.getActiveBusinessId(), user.getId());
            if (memberOpt.isPresent()
                    && "ACTIVE".equalsIgnoreCase(memberOpt.get().getStatus())
                    && memberOpt.get().getBusiness().getArchivedAt() == null) {
                return memberOpt.get().getBusiness();
            }
        }
        List<BusinessMember> members = businessMemberRepository.findAllActiveByUserIdWithBusiness(user.getId());
        if (!members.isEmpty()) {
            Business b = members.get(0).getBusiness();
            user.setActiveBusinessId(b.getId());
            userRepository.save(user);
            return b;
        }
        Business b = businessRepository.findFirstByUserIdAndArchivedAtIsNull(user.getId())
                .orElseThrow(() -> new IllegalStateException("No active business found for authenticated user"));
        user.setActiveBusinessId(b.getId());
        userRepository.save(user);
        return b;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request, String ipAddress, String userAgent) {
        String normalizedEmail = normalizeEmail(request.getEmail());
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new IllegalArgumentException("Unable to complete registration. If you already have an account, please sign in.");
        }

        User user = new User();
        user.setFirstName(request.getFirstName().trim());
        user.setLastName(request.getLastName().trim());
        user.setEmail(normalizedEmail);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setAvatarUrl("https://api.dicebear.com/7.x/avataaars/svg?seed=" + sha256(normalizedEmail).substring(0, 12));
        user = userRepository.save(user);

        Business business = new Business();
        business.setUser(user);
        business.setName(request.getBusinessName().trim());
        business.setCurrency("USD");
        business = businessRepository.save(business);

        BusinessMember ownerMember = new BusinessMember(business, user, "OWNER", "ACTIVE");
        businessMemberRepository.save(ownerMember);

        user.setActiveBusinessId(business.getId());
        user = userRepository.save(user);

        auditService.logSecurityEvent(user, "REGISTER_SUCCESS", ipAddress, userAgent, null);

        String otp = createVerificationOtp(user);
        boolean emailSent = true;
        try {
            emailService.sendVerificationOtp(user.getEmail(), user.getFirstName(), otp);
        } catch (EmailDeliveryException e) {
            log.error("Registration succeeded for {} but verification email could not be sent: {}",
                    LogSanitizer.maskEmail(user.getEmail()), LogSanitizer.sanitizeMessage(e.getMessage()));
            emailSent = false;
        }

        AuthResponse response = buildAuthResponse(user, business.getId(), ipAddress, userAgent, false, UUID.randomUUID());
        response.setVerificationEmailSent(emailSent);
        if (isDevOtpExposed()) {
            response.setDevOtp(otp);
        }
        return response;
    }

    /**
     * Login with enumeration-resistant error handling and brute-force lockout protection.
     */
    @Transactional(noRollbackFor = {BadCredentialsException.class, LockedException.class})
    public AuthResponse login(LoginRequest request, String ipAddress, String userAgent) {
        String normalizedEmail = normalizeEmail(request.getEmail());
        User user = userRepository.findByEmail(normalizedEmail).orElse(null);
        if (user == null) {
            throw new BadCredentialsException("Invalid email or password.");
        }

        if (!"ACTIVE".equals(user.getStatus()) || user.getDeletedAt() != null) {
            throw new DisabledException("Your account is not active.");
        }

        if (user.getLockoutUntil() != null && user.getLockoutUntil().isAfter(Instant.now())) {
            long remainingMinutes = java.time.Duration.between(Instant.now(), user.getLockoutUntil()).toMinutes() + 1;
            throw new LockedException("Account is temporarily locked due to multiple failed login attempts. Please try again in " + remainingMinutes + " minute(s).");
        }

        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(normalizedEmail, request.getPassword())
            );
        } catch (DisabledException e) {
            throw new DisabledException("Your account is not active.");
        } catch (BadCredentialsException e) {
            int failed = user.getFailedLoginAttempts() + 1;
            user.setFailedLoginAttempts(failed);
            if (failed >= 5) {
                user.setLockoutUntil(Instant.now().plus(15, ChronoUnit.MINUTES));
                userRepository.save(user);
                auditService.logSecurityEvent(user, "ACCOUNT_LOCKED", ipAddress, userAgent, "{\"reason\":\"max_failed_attempts\"}");
                throw new LockedException("Account temporarily locked due to too many failed attempts. Please try again in 15 minutes.");
            } else {
                userRepository.save(user);
                auditService.logSecurityEvent(user, "LOGIN_FAILED_BAD_PASSWORD", ipAddress, userAgent, "{\"failedAttempts\":" + failed + "}");
                throw new BadCredentialsException("Invalid email or password.");
            }
        }

        user.setFailedLoginAttempts(0);
        user.setLockoutUntil(null);
        user.setLastLoginAt(Instant.now());
        user.setLastLoginIp(ipAddress);
        userRepository.save(user);

        if (user.isTwoFactorEnabled()) {
            String challengeToken = jwtService.generateTwoFactorChallengeToken(user.getEmail());
            auditService.logSecurityEvent(user, "LOGIN_2FA_CHALLENGE", ipAddress, userAgent, null);
            return AuthResponse.twoFactorRequired(challengeToken);
        }

        Business business = resolveUserActiveBusiness(user);
        auditService.logSecurityEvent(user, "LOGIN_SUCCESS", ipAddress, userAgent, null);

        boolean rememberMe = Boolean.TRUE.equals(request.getRememberMe());
        return buildAuthResponse(user, business.getId(), ipAddress, userAgent, rememberMe, UUID.randomUUID());
    }

    @Transactional
    public AuthResponse verifyTwoFactorLogin(TwoFactorVerifyRequest request, String ipAddress, String userAgent) {
        String email = jwtService.validateTwoFactorChallengeToken(request.getTwoFactorToken());
        if (email == null) {
            throw new IllegalArgumentException("Two-factor authentication session expired or invalid. Please login again.");
        }

        User user = userRepository.findByEmail(normalizeEmail(email))
                .orElseThrow(() -> new BadCredentialsException("Invalid authentication session."));

        if (!"ACTIVE".equals(user.getStatus()) || user.getDeletedAt() != null) {
            throw new DisabledException("Your account is not active.");
        }

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

        Business business = resolveUserActiveBusiness(user);
        auditService.logSecurityEvent(user, "LOGIN_2FA_SUCCESS", ipAddress, userAgent, null);

        boolean rememberMe = Boolean.TRUE.equals(request.getRememberMe());
        return buildAuthResponse(user, business.getId(), ipAddress, userAgent, rememberMe, UUID.randomUUID());
    }

    private boolean verifyAndConsumeBackupCode(User user, String code, String ipAddress, String userAgent) {
        if (user.getTwoFactorBackupCodes() == null || user.getTwoFactorBackupCodes().isBlank()) {
            return false;
        }

        String cleanCode = code.replace(" ", "").toUpperCase(Locale.ROOT);
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
                    .map(c -> sha256(c.replace(" ", "").toUpperCase(Locale.ROOT)))
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
                .map(c -> sha256(c.replace(" ", "").toUpperCase(Locale.ROOT)))
                .collect(Collectors.toList());

        user.setTwoFactorBackupCodes(String.join(",", hashedCodes));
        userRepository.save(user);

        auditService.logSecurityEvent(user, "2FA_BACKUP_CODES_REGENERATED", ipAddress, userAgent, null);
        return plainCodes;
    }

    /**
     * Rotates a refresh token stored as SHA-256 hash.
     * Detects reuse of an already-revoked token and immediately revokes the entire token family.
     */
    @Transactional(noRollbackFor = RefreshTokenReuseException.class)
    public AuthResponse refreshToken(String rawRefreshToken, String ipAddress, String userAgent) {
        String hashed = hashToken(rawRefreshToken);
        RefreshToken savedToken = refreshTokenRepository.findByTokenHash(hashed)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token"));

        if (savedToken.getRevokedAt() != null) {
            // Reuse of a previously rotated or logged-out refresh token indicates potential theft.
            Instant now = Instant.now();
            refreshTokenRepository.revokeTokenFamily(savedToken.getTokenFamilyId(), now);
            auditService.logSecurityEvent(
                    savedToken.getUser(),
                    "REFRESH_TOKEN_REUSE_DETECTED",
                    ipAddress,
                    userAgent,
                    "{\"familyId\":\"" + savedToken.getTokenFamilyId() + "\"}"
            );
            throw new RefreshTokenReuseException("Refresh token reuse detected. Session has been invalidated.");
        }

        if (savedToken.getExpiresAt().isBefore(Instant.now())) {
            throw new IllegalArgumentException("Refresh token is expired");
        }

        User user = savedToken.getUser();
        if (!"ACTIVE".equals(user.getStatus()) || user.getDeletedAt() != null) {
            savedToken.setRevokedAt(Instant.now());
            refreshTokenRepository.save(savedToken);
            throw new IllegalArgumentException("Account is not active");
        }

        Business business = resolveUserActiveBusiness(user);

        savedToken.setRevokedAt(Instant.now());
        refreshTokenRepository.save(savedToken);

        auditService.logSecurityEvent(user, "TOKEN_REFRESH", ipAddress, userAgent, null);

        boolean wasRememberMe = savedToken.isRememberMe()
                || (savedToken.getCreatedAt() != null
                    && java.time.Duration.between(savedToken.getCreatedAt(), savedToken.getExpiresAt()).toDays() > 2);

        return buildAuthResponse(user, business.getId(), ipAddress, userAgent, wasRememberMe, savedToken.getTokenFamilyId());
    }

    @Transactional
    public void logout(String rawRefreshToken, String ipAddress, String userAgent) {
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            return;
        }
        String hashed = hashToken(rawRefreshToken);
        refreshTokenRepository.findByTokenHash(hashed).ifPresent(token -> {
            if (token.getRevokedAt() == null) {
                token.setRevokedAt(Instant.now());
                refreshTokenRepository.save(token);
            }
            auditService.logSecurityEvent(token.getUser(), "LOGOUT_SUCCESS", ipAddress, userAgent, null);
        });
    }

    // ── Email Verification Flow ────────────────────────

    /**
     * Enumeration-safe resend: does not disclose whether the email exists or is already verified.
     * Returns an optional dev OTP ONLY when explicitly enabled in local/dev profiles.
     */
    @Transactional
    public Optional<String> resendVerificationEmail(String email) {
        Optional<User> userOpt = userRepository.findByEmail(normalizeEmail(email));
        if (userOpt.isEmpty()) {
            return Optional.empty();
        }
        User user = userOpt.get();
        if (user.getEmailVerifiedAt() != null || !"ACTIVE".equals(user.getStatus())) {
            return Optional.empty();
        }

        String otp = sendVerificationOtp(user);
        return isDevOtpExposed() ? Optional.of(otp) : Optional.empty();
    }

    @Transactional
    public void verifyEmail(String email, String code, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(normalizeEmail(email))
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired verification code"));

        if (user.getEmailVerifiedAt() != null) {
            throw new IllegalArgumentException("Invalid or expired verification code");
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
        String otp = createVerificationOtp(user);
        emailService.sendVerificationOtp(user.getEmail(), user.getFirstName(), otp);
        return otp;
    }

    private String createVerificationOtp(User user) {
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
        return otp;
    }

    // ── Password Reset Flow (OTP-based) ────────────────────────────

    @Transactional
    public void forgotPassword(String email, String ipAddress, String userAgent) {
        userRepository.findByEmail(normalizeEmail(email)).ifPresent(user -> {
            if (!"ACTIVE".equals(user.getStatus())) return;
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

            try {
                emailService.sendPasswordResetOtp(user.getEmail(), user.getFirstName(), otp);
            } catch (EmailDeliveryException e) {
                log.error("Password reset OTP for {} could not be delivered: {}",
                        LogSanitizer.maskEmail(user.getEmail()), LogSanitizer.sanitizeMessage(e.getMessage()));
            }
            auditService.logSecurityEvent(user, "PASSWORD_RESET_REQUESTED", ipAddress, userAgent, null);
        });
    }

    @Transactional
    public void resetPassword(String email, String code, String newPassword, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(normalizeEmail(email))
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired reset code"));

        VerificationToken token = verificationTokenRepository.findLatestValidToken(user.getId(), VerificationToken.TokenType.PASSWORD_RESET, Instant.now())
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired reset code"));

        if (!passwordEncoder.matches(code, token.getToken())) {
            throw new IllegalArgumentException("Invalid or expired reset code");
        }

        token.setUsedAt(Instant.now());
        verificationTokenRepository.save(token);

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordChangedAt(Instant.now());

        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());
        userRepository.save(user);

        auditService.logSecurityEvent(user, "PASSWORD_RESET_COMPLETED", ipAddress, userAgent, null);
    }

    // ── Password Reset Flow (Link/Token-based) ────────────────────────

    @Transactional
    public void forgotPasswordLink(String email, String ipAddress, String userAgent) {
        userRepository.findByEmail(normalizeEmail(email)).ifPresent(user -> {
            if (!"ACTIVE".equals(user.getStatus())) return;
            passwordResetTokenRepository.invalidateAllUserTokens(user.getId(), Instant.now());

            String rawToken = generateSecureToken();
            String tokenHash = sha256(rawToken);

            PasswordResetToken resetToken = new PasswordResetToken(
                    user,
                    tokenHash,
                    Instant.now().plus(passwordResetExpirationMinutes, ChronoUnit.MINUTES)
            );
            passwordResetTokenRepository.save(resetToken);

            String resetLink = frontendUrl + "/en/reset-password?token=" + rawToken;

            try {
                emailService.sendPasswordResetLink(user.getEmail(), user.getFirstName(), resetLink);
            } catch (EmailDeliveryException e) {
                log.error("Password reset link for {} could not be delivered: {}",
                        LogSanitizer.maskEmail(user.getEmail()), LogSanitizer.sanitizeMessage(e.getMessage()));
            }
            auditService.logSecurityEvent(user, "PASSWORD_RESET_LINK_REQUESTED", ipAddress, userAgent, null);
        });
    }

    @Transactional(readOnly = true)
    public String validateResetToken(String rawToken) {
        String tokenHash = sha256(rawToken);
        PasswordResetToken resetToken = passwordResetTokenRepository.findByTokenHash(tokenHash)
                .orElse(null);

        if (resetToken == null || resetToken.isUsed()) {
            return "INVALID";
        }
        if (resetToken.isExpired()) {
            return "EXPIRED";
        }
        return "VALID";
    }

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

        resetToken.setUsedAt(Instant.now());
        passwordResetTokenRepository.save(resetToken);

        User user = resetToken.getUser();
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordChangedAt(Instant.now());
        userRepository.save(user);

        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());

        auditService.logSecurityEvent(user, "PASSWORD_RESET_BY_TOKEN_COMPLETED", ipAddress, userAgent, null);
    }

    // ── Change Password ────────────────────────────────

    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(normalizeEmail(email))
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            auditService.logSecurityEvent(user, "PASSWORD_CHANGE_FAILED", ipAddress, userAgent, "{\"reason\":\"invalid_current_password\"}");
            throw new IllegalArgumentException("Current password is incorrect");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordChangedAt(Instant.now());
        userRepository.save(user);

        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());

        auditService.logSecurityEvent(user, "PASSWORD_CHANGED", ipAddress, userAgent, null);
    }

    // ── Utility Methods ────────────────────────────────

    public static String hashToken(String rawToken) {
        return sha256(rawToken);
    }

    private AuthResponse buildAuthResponse(User user, UUID businessId, String ipAddress, String userAgent,
                                           boolean rememberMe, UUID tokenFamilyId) {
        var userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String accessToken = jwtService.generateToken(userDetails);

        long expirationDuration = rememberMe ? (30L * 24L * 60L * 60L * 1000L) : refreshTokenExpirationMs;

        String rawRefreshToken = generateSecureToken();
        String refreshTokenHash = hashToken(rawRefreshToken);

        RefreshToken refreshToken = new RefreshToken(
                user,
                refreshTokenHash,
                Instant.now().plusMillis(expirationDuration),
                userAgent != null && userAgent.length() > 255 ? userAgent.substring(0, 255) : userAgent,
                ipAddress,
                tokenFamilyId,
                rememberMe
        );
        refreshTokenRepository.save(refreshToken);

        Business business = businessRepository.findById(businessId).orElse(null);
        boolean onboardingComplete = business != null && business.isOnboardingComplete();

        AuthResponse response = new AuthResponse(
                accessToken,
                rawRefreshToken,
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
        response.setRememberMe(rememberMe);
        return response;
    }

    private boolean isDevOtpExposed() {
        return allowDevOtp && ("local".equalsIgnoreCase(activeProfile) || "dev".equalsIgnoreCase(activeProfile));
    }

    private String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }

    private String generateNumericOtp(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(SECURE_RANDOM.nextInt(10));
        }
        return sb.toString();
    }

    private String generateSecureToken() {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm not available", e);
        }
    }

    public static class RefreshTokenReuseException extends IllegalArgumentException {
        public RefreshTokenReuseException(String message) {
            super(message);
        }
    }
}
