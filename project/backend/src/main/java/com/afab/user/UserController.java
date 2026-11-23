package com.afab.user;

import com.afab.auth.AuthService;
import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.auth.dto.*;
import com.afab.auth.security.AuthCookieService;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.security.ClientIpResolver;
import com.afab.user.dto.DeleteAccountRequest;
import com.afab.user.dto.SessionDTO;
import com.afab.user.dto.UpdateUserRequest;
import com.afab.user.dto.UserProfileDTO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/user")
public class UserController {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final AuthService authService;
    private final com.afab.business.CurrentBusinessService currentBusinessService;
    private final UserAccountService userAccountService;
    private final AuthCookieService authCookieService;
    private final ClientIpResolver clientIpResolver;

    public UserController(UserRepository userRepository, BusinessRepository businessRepository,
                          RefreshTokenRepository refreshTokenRepository, AuthService authService,
                          com.afab.business.CurrentBusinessService currentBusinessService,
                          UserAccountService userAccountService,
                          AuthCookieService authCookieService,
                          ClientIpResolver clientIpResolver) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.authService = authService;
        this.currentBusinessService = currentBusinessService;
        this.userAccountService = userAccountService;
        this.authCookieService = authCookieService;
        this.clientIpResolver = clientIpResolver;
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return ResponseEntity.ok(buildUserProfileDTO(user));
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

        if (request.getFirstName() != null) {
            String trimmedFirst = request.getFirstName().trim();
            if (trimmedFirst.isEmpty()) {
                return ResponseEntity.badRequest().body(ErrorResponse.error("INVALID_FIRST_NAME", "First name cannot be empty."));
            }
            user.setFirstName(trimmedFirst);
        }
        if (request.getLastName() != null) {
            String trimmedLast = request.getLastName().trim();
            if (trimmedLast.isEmpty()) {
                return ResponseEntity.badRequest().body(ErrorResponse.error("INVALID_LAST_NAME", "Last name cannot be empty."));
            }
            user.setLastName(trimmedLast);
        }
        if (request.getPhoneNumber() != null) {
            String trimmedPhone = request.getPhoneNumber().trim();
            if (trimmedPhone.isEmpty()) {
                user.setPhoneNumber(null);
            } else {
                if (userRepository.existsByPhoneNumberAndIdNot(trimmedPhone, user.getId())) {
                    return ResponseEntity.badRequest().body(ErrorResponse.error("PHONE_TAKEN", "This phone number is already in use by another account."));
                }
                user.setPhoneNumber(trimmedPhone);
            }
        }
        if (request.getAvatarUrl() != null) {
            String trimmedAvatar = request.getAvatarUrl().trim();
            user.setAvatarUrl(trimmedAvatar.isEmpty() ? null : trimmedAvatar);
        }
        if (request.getEnableAiInsights() != null) user.setEnableAiInsights(request.getEnableAiInsights());
        if (request.getCompactMode() != null) user.setCompactMode(request.getCompactMode());
        if (request.getAutoCategorizeTransactions() != null) user.setAutoCategorizeTransactions(request.getAutoCategorizeTransactions());
        if (request.getShowTips() != null) user.setShowTips(request.getShowTips());

        userRepository.save(user);

        return ResponseEntity.ok(buildUserProfileDTO(user));
    }

    @GetMapping("/me/export")
    public ResponseEntity<?> exportMyData(
            Authentication authentication,
            HttpServletRequest httpRequest
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        Map<String, Object> exportData = userAccountService.exportUserData(
                authentication.getName(),
                getClientIp(httpRequest),
                httpRequest.getHeader("User-Agent")
        );

        String filename = "afab-account-export-" + LocalDate.now() + ".json";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_JSON)
                .body(exportData);
    }

    @GetMapping("/me/deletion-preflight")
    public ResponseEntity<?> getDeletionPreflight(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }
        return ResponseEntity.ok(userAccountService.getDeletionPreflight(authentication.getName()));
    }

    @DeleteMapping("/me")
    public ResponseEntity<?> deleteMyAccount(
            @Valid @RequestBody DeleteAccountRequest request,
            Authentication authentication,
            HttpServletRequest httpRequest
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        try {
            userAccountService.deleteUserAccount(
                    authentication.getName(),
                    request.getConfirmation(),
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );

            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearRefreshCookie().toString())
                    .header(HttpHeaders.SET_COOKIE, authCookieService.buildClearCsrfCookie().toString())
                    .body(ErrorResponse.success("Your account has been safely deactivated and anonymized."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ErrorResponse.error("DELETE_CONFIRMATION_INVALID", e.getMessage()));
        }
    }

    private UserProfileDTO buildUserProfileDTO(User user) {
        Business business = null;
        try {
            business = currentBusinessService.getCurrentBusiness(user.getEmail());
        } catch (Exception e) {
            business = businessRepository.findFirstByUserIdAndArchivedAtIsNull(user.getId()).orElse(null);
        }

        return new UserProfileDTO(
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
                user.getShowTips(),
                user.getPlanTier()
        );
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
            @CookieValue(name = AuthCookieService.REFRESH_COOKIE_NAME, required = false) String cookieRefreshToken,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String currentTokenHash = (cookieRefreshToken != null && !cookieRefreshToken.isBlank())
                ? AuthService.hashToken(cookieRefreshToken) : null;

        List<RefreshToken> tokens = refreshTokenRepository
                .findByUserIdAndRevokedAtIsNullAndExpiresAtAfter(user.getId(), Instant.now());

        List<SessionDTO> sessions = tokens.stream()
                .map(t -> {
                    boolean isCurrent = currentTokenHash != null && currentTokenHash.equals(t.getTokenHash());
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
            @CookieValue(name = AuthCookieService.REFRESH_COOKIE_NAME, required = false) String cookieRefreshToken,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String currentTokenHash = (cookieRefreshToken != null && !cookieRefreshToken.isBlank())
                ? AuthService.hashToken(cookieRefreshToken) : null;

        List<RefreshToken> tokens = refreshTokenRepository
                .findByUserIdAndRevokedAtIsNullAndExpiresAtAfter(user.getId(), Instant.now());

        Instant now = Instant.now();
        for (RefreshToken t : tokens) {
            if (currentTokenHash == null || !currentTokenHash.equals(t.getTokenHash())) {
                t.setRevokedAt(now);
                refreshTokenRepository.save(t);
            }
        }

        return ResponseEntity.ok().build();
    }

    private String getClientIp(HttpServletRequest request) {
        return clientIpResolver.resolve(request);
    }
}
