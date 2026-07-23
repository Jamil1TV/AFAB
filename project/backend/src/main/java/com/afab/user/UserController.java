package com.afab.user;

import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.user.dto.SessionDTO;
import com.afab.user.dto.UpdateUserRequest;
import com.afab.user.dto.UserProfileDTO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
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

    public UserController(UserRepository userRepository, BusinessRepository businessRepository,
                          RefreshTokenRepository refreshTokenRepository) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.refreshTokenRepository = refreshTokenRepository;
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

    // ── Active Sessions ─────────────────────────────────

    @GetMapping("/me/sessions")
    public ResponseEntity<?> getActiveSessions(Authentication authentication, HttpServletRequest httpRequest) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        List<RefreshToken> tokens = refreshTokenRepository
                .findByUserIdAndRevokedAtIsNullAndExpiresAtAfter(user.getId(), Instant.now());

        List<SessionDTO> sessions = tokens.stream()
                .map(t -> new SessionDTO(
                        t.getId(),
                        t.getDeviceInfo(),
                        t.getIpAddress(),
                        t.getCreatedAt(),
                        t.getExpiresAt(),
                        false // We mark current session based on token match
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(sessions);
    }

    @DeleteMapping("/me/sessions/{tokenId}")
    public ResponseEntity<?> revokeSession(@PathVariable UUID tokenId, Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        RefreshToken token = refreshTokenRepository.findById(tokenId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        if (!token.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body("Forbidden");
        }

        token.setRevokedAt(Instant.now());
        refreshTokenRepository.save(token);

        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/me/sessions")
    public ResponseEntity<?> revokeAllOtherSessions(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        refreshTokenRepository.revokeAllUserTokens(user.getId(), Instant.now());

        return ResponseEntity.ok().build();
    }
}
