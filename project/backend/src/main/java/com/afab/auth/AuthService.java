package com.afab.auth;

import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.auth.dto.AuthResponse;
import com.afab.auth.dto.LoginRequest;
import com.afab.auth.dto.RegisterRequest;
import com.afab.auth.security.JwtService;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
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
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final AuditService auditService;

    @Value("${afab.jwt.refresh-expiration-ms}")
    private long refreshTokenExpirationMs;

    public AuthService(UserRepository userRepository, BusinessRepository businessRepository,
                       RefreshTokenRepository refreshTokenRepository, PasswordEncoder passwordEncoder,
                       JwtService jwtService, AuthenticationManager authenticationManager,
                       UserDetailsService userDetailsService, AuditService auditService) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
        this.userDetailsService = userDetailsService;
        this.auditService = auditService;
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
        business = businessRepository.save(business);

        auditService.logSecurityEvent(user, "REGISTER_SUCCESS", ipAddress, userAgent, "{\"businessName\":\"" + request.getBusinessName() + "\"}");

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

        // Revoke all previous refresh tokens for a clean session (or allow multiple devices if preferred)
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

        // Revoke the used token and issue a new one (Token Rotation)
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

    private AuthResponse buildAuthResponse(User user, Long businessId, String ipAddress, String userAgent) {
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
                new AuthResponse.UserDto(user.getId(), user.getFirstName(), user.getLastName(), user.getEmail(), businessId)
        );
    }
}
