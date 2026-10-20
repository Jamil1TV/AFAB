package com.afab.user;

import com.afab.auth.AuthService;
import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.auth.dto.*;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.user.dto.SessionDTO;
import com.afab.user.dto.UpdateUserRequest;
import com.afab.user.dto.UserProfileDTO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/user")
public class UserController {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final AuthService authService;

    public UserController(UserRepository userRepository, BusinessRepository businessRepository,
                          RefreshTokenRepository refreshTokenRepository, AuthService authService) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.authService = authService;
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Business business = businessRepository.findByUserId(user.getId()).orElse(null);

        UserProfileDTO profile = new UserProfileDTO(
                user.getId(),
                user.getFirstName(),
                user.getLastName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getAvatarUrl(),
                user.getEmailVerifiedAt() != null,
                business != null ? business.getId() : null,
                business != null ? business.getName() : "My Workspace",
                business != null ? business.getCurrency() : "USD",
                business != null ? business.getCountry() : null,
                business != null && business.isOnboardingComplete(),
                user.getCreatedAt(),
                user.getPasswordChangedAt(),
                user.getTwoFactorEnabled(),
                user.getLastLoginAt(),
                user.getLastLoginIp(),
                user.getEnableAiInsights(),
                user.getCompactMode(),
                user.getAutoCategorizeTransactions(),
                user.getShowTips()
        );

        return ResponseEntity.ok(profile);
    }

    @PutMapping("/me")
    public ResponseEntity<?> updateProfile(
            @Valid @RequestBody UpdateUserRequest request,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (request.getFirstName() != null) user.setFirstName(request.getFirstName());
        if (request.getLastName() != null) user.setLastName(request.getLastName());
        if (request.getPhoneNumber() != null) user.setPhoneNumber(request.getPhoneNumber());
        if (request.getAvatarUrl() != null) user.setAvatarUrl(request.getAvatarUrl());
        if (request.getEnableAiInsights() != null) user.setEnableAiInsights(request.getEnableAiInsights());
        if (request.getCompactMode() != null) user.setCompactMode(request.getCompactMode());
        if (request.getAutoCategorizeTransactions() != null) user.setAutoCategorizeTransactions(request.getAutoCategorizeTransactions());
        if (request.getShowTips() != null) user.setShowTips(request.getShowTips());

        userRepository.save(user);

        return ResponseEntity.ok().build();
    }

    // ── 2FA Management ─────────────────────────────────

    @GetMapping("/2fa/setup")
    public ResponseEntity<?> setupTwoFactor(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return ResponseEntity.ok(authService.setupTwoFactor(user.getId()));
    }

    @PostMapping("/2fa/enable")
    public ResponseEntity<?> enableTwoFactor(
            @Valid @RequestBody TwoFactorEnableRequest request,
            Authentication authentication,
            HttpServletRequest httpRequest
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        try {
            authService.enableTwoFactor(user.getId(), request, getClientIp(httpRequest), httpRequest.getHeader("User-Agent"));
            return ResponseEntity.ok().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ErrorResponse.error("INVALID_CODE", e.getMessage()));
        }
    }

    @PostMapping("/2fa/disable")
    public ResponseEntity<?> disableTwoFactor(
            @Valid @RequestBody TwoFactorDisableRequest request,
            Authentication authentication,
            HttpServletRequest httpRequest
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        try {
            authService.disableTwoFactor(user.getId(), request, getClientIp(httpRequest), httpRequest.getHeader("User-Agent"));
            return ResponseEntity.ok().build();
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ErrorResponse.error("INVALID_PASSWORD", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ErrorResponse.error("DISABLE_FAILED", e.getMessage()));
        }
    }

    @PostMapping("/2fa/backup-codes")
    public ResponseEntity<?> regenerateBackupCodes(
            Authentication authentication,
            HttpServletRequest httpRequest
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        try {
            List<String> codes = authService.regenerateBackupCodes(user.getId(), getClientIp(httpRequest), httpRequest.getHeader("User-Agent"));
            return ResponseEntity.ok(codes);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ErrorResponse.error("FAILED", e.getMessage()));
        }
    }

    // ── Active Sessions ─────────────────────────────────

    @GetMapping("/me/sessions")
    public ResponseEntity<?> getActiveSessions(
            @CookieValue(name = "refreshToken", required = false) String cookieRefreshToken,
            @RequestHeader(value = "X-Refresh-Token", required = false) String headerRefreshToken,
            Authentication authentication,
            HttpServletRequest httpRequest
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String currentToken = cookieRefreshToken != null ? cookieRefreshToken : headerRefreshToken;
        String clientIp = getClientIp(httpRequest);

        List<RefreshToken> tokens = refreshTokenRepository
                .findByUserIdAndRevokedAtIsNullAndExpiresAtAfter(user.getId(), Instant.now());

        List<SessionDTO> sessions = tokens.stream()
                .map(t -> {
                    boolean isCurrent = false;
                    if (currentToken != null && currentToken.equals(t.getTokenHash())) {
                        isCurrent = true;
                    } else if (currentToken == null && clientIp != null && clientIp.equals(t.getIpAddress())) {
                        isCurrent = true;
                    }
                    return new SessionDTO(
                            t.getId(),
                            t.getDeviceInfo(),
                            t.getIpAddress(),
                            t.getCreatedAt(),
                            t.getExpiresAt(),
                            isCurrent
                    );
                })
                .collect(Collectors.toList());

        return ResponseEntity.ok(sessions);
    }

    @DeleteMapping("/me/sessions/{tokenId}")
    public ResponseEntity<?> revokeSession(@PathVariable UUID tokenId, Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        RefreshToken token = refreshTokenRepository.findById(tokenId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        if (!token.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Forbidden");
        }

        token.setRevokedAt(Instant.now());
        refreshTokenRepository.save(token);

        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/me/sessions")
    public ResponseEntity<?> revokeAllOtherSessions(
            @CookieValue(name = "refreshToken", required = false) String cookieRefreshToken,
            @RequestHeader(value = "X-Refresh-Token", required = false) String headerRefreshToken,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String currentToken = cookieRefreshToken != null ? cookieRefreshToken : headerRefreshToken;

        List<RefreshToken> tokens = refreshTokenRepository
                .findByUserIdAndRevokedAtIsNullAndExpiresAtAfter(user.getId(), Instant.now());

        Instant now = Instant.now();
        for (RefreshToken t : tokens) {
            if (currentToken == null || !currentToken.equals(t.getTokenHash())) {
                t.setRevokedAt(now);
                refreshTokenRepository.save(t);
            }
        }

        return ResponseEntity.ok().build();
    }

    private String getClientIp(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null || xfHeader.isEmpty() || "unknown".equalsIgnoreCase(xfHeader)) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0].trim();
    }
}
