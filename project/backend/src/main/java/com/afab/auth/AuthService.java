package com.afab.auth;

import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.auth.domain.VerificationToken;
import com.afab.auth.domain.VerificationTokenRepository;
import com.afab.auth.dto.AuthResponse;
import com.afab.auth.dto.LoginRequest;
import com.afab.auth.dto.RegisterRequest;
import com.afab.auth.security.JwtService;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.mail.EmailService;
import com.afab.security.AuditService;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Random;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final VerificationTokenRepository verificationTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final AuditService auditService;
    private final EmailService emailService;

    @Value("${afab.jwt.refresh-expiration-ms}")
    private long refreshTokenExpirationMs;

    public AuthService(UserRepository userRepository, BusinessRepository businessRepository,
                       RefreshTokenRepository refreshTokenRepository,
                       VerificationTokenRepository verificationTokenRepository, PasswordEncoder passwordEncoder,
                       JwtService jwtService, AuthenticationManager authenticationManager,
                       UserDetailsService userDetailsService, AuditService auditService,
                       EmailService emailService) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.verificationTokenRepository = verificationTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
        this.userDetailsService = userDetailsService;
        this.auditService = auditService;
        this.emailService = emailService;
    }

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
        user = userRepository.save(user);

        Business business = new Business();
        business.setUser(user);
        business.setName(request.getBusinessName());
        business.setCurrency("USD");
        business = businessRepository.save(business);

        auditService.logSecurityEvent(user, "REGISTER_SUCCESS", ipAddress, userAgent, "{\"businessName\":\"" + request.getBusinessName() + "\"}");

        // Send Email Verification OTP
        sendVerificationOtp(user);

        return buildAuthResponse(user, business.getId(), ipAddress, userAgent);
    }

    @Transactional
    public AuthResponse login(LoginRequest request, String ipAddress, String userAgent) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail()).orElseThrow();
        user.setLastLoginAt(Instant.now());
        user.setLastLoginIp(ipAddress);
        userRepository.save(user);

        Business business = businessRepository.findByUserId(user.getId()).orElseThrow();

        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());
        auditService.logSecurityEvent(user, "LOGIN_SUCCESS", ipAddress, userAgent, null);

        return buildAuthResponse(user, business.getId(), ipAddress, userAgent);
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

        return buildAuthResponse(user, business.getId(), ipAddress, userAgent);
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
    public void resendVerificationEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.getEmailVerifiedAt() != null) {
            throw new IllegalArgumentException("Email is already verified");
        }

        sendVerificationOtp(user);
    }

    @Transactional
    public void verifyEmail(String email, String code, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.getEmailVerifiedAt() != null) {
            throw new IllegalArgumentException("Email is already verified");
        }

        VerificationToken token = verificationTokenRepository.findValidToken(code, VerificationToken.TokenType.EMAIL_VERIFICATION, Instant.now())
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired verification code"));

        if (!token.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("Invalid verification code");
        }

        token.setUsedAt(Instant.now());
        verificationTokenRepository.save(token);

        user.setEmailVerifiedAt(Instant.now());
        userRepository.save(user);

        auditService.logSecurityEvent(user, "EMAIL_VERIFIED", ipAddress, userAgent, null);
    }

    private void sendVerificationOtp(User user) {
        // Invalidate old tokens
        verificationTokenRepository.invalidateAllUserTokens(user.getId(), VerificationToken.TokenType.EMAIL_VERIFICATION, Instant.now());

        String otp = generateNumericOtp(6);
        VerificationToken token = new VerificationToken(
                user,
                otp, // TODO: In a production super-secure environment, hash this OTP before saving
                VerificationToken.TokenType.EMAIL_VERIFICATION,
                Instant.now().plus(15, ChronoUnit.MINUTES)
        );
        verificationTokenRepository.save(token);

        emailService.sendVerificationOtp(user.getEmail(), user.getFirstName(), otp);
    }

    // ── Password Reset Flow ────────────────────────────

    @Transactional
    public void forgotPassword(String email, String ipAddress, String userAgent) {
        userRepository.findByEmail(email).ifPresent(user -> {
            verificationTokenRepository.invalidateAllUserTokens(user.getId(), VerificationToken.TokenType.PASSWORD_RESET, Instant.now());

            String otp = generateNumericOtp(6);
            VerificationToken token = new VerificationToken(
                    user,
                    otp,
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

        VerificationToken token = verificationTokenRepository.findValidToken(code, VerificationToken.TokenType.PASSWORD_RESET, Instant.now())
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired reset code"));

        if (!token.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("Invalid reset code");
        }

        token.setUsedAt(Instant.now());
        verificationTokenRepository.save(token);

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        
        // Also revoke all refresh tokens so they are logged out of everywhere else
        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());
        userRepository.save(user);

        auditService.logSecurityEvent(user, "PASSWORD_RESET_COMPLETED", ipAddress, userAgent, null);
    }

    // ── Utility Methods ────────────────────────────────

    private AuthResponse buildAuthResponse(User user, UUID businessId, String ipAddress, String userAgent) {
        var userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String accessToken = jwtService.generateToken(userDetails);

        String refreshTokenString = UUID.randomUUID().toString();
        RefreshToken refreshToken = new RefreshToken(
                user,
                refreshTokenString,
                Instant.now().plusMillis(refreshTokenExpirationMs),
                userAgent != null && userAgent.length() > 255 ? userAgent.substring(0, 255) : userAgent
        );
        refreshTokenRepository.save(refreshToken);

        return new AuthResponse(
                accessToken,
                refreshTokenString,
                new AuthResponse.UserDto(user.getId(), user.getFirstName(), user.getLastName(), user.getEmail(), businessId, user.getEmailVerifiedAt() != null)
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
}
