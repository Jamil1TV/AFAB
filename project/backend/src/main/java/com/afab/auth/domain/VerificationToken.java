package com.afab.auth.domain;

import com.afab.user.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Verification Token entity — stores OTP codes and magic link tokens
 * for Email Verification, Phone Verification, and Password Resets.
 *
 * Security Design:
 * - Tokens are hashed (SHA-256) before storage to prevent database leak exposure.
 * - Each token has a strict expiration window (default: 15 minutes).
 * - Tokens are single-use: once verified, `used_at` is populated and the token is invalidated.
 * - Old tokens are automatically invalidated when a new one is generated for the same user+type.
 */
@Entity
@Table(name = "verification_tokens")
public class VerificationToken {

    public enum TokenType {
        EMAIL_VERIFICATION,
        PHONE_VERIFICATION,
        PASSWORD_RESET
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * The SHA-256 hash of the actual token/OTP code.
     * We NEVER store the raw token in the database for security.
     */
    @Column(nullable = false)
    private String token;

    @Column(name = "token_type", nullable = false)
    @Enumerated(EnumType.STRING)
    private TokenType tokenType;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    // ── Constructors ────────────────────────────

    public VerificationToken() {}

    public VerificationToken(User user, String token, TokenType tokenType, Instant expiresAt) {
        this.user = user;
        this.token = token;
        this.tokenType = tokenType;
        this.expiresAt = expiresAt;
    }

    // ── Business Logic ──────────────────────────

    public boolean isExpired() {
        return Instant.now().isAfter(expiresAt);
    }

    public boolean isUsed() {
        return usedAt != null;
    }

    public boolean isValid() {
        return !isExpired() && !isUsed();
    }

    // ── Getters & Setters ───────────────────────

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public TokenType getTokenType() { return tokenType; }
    public void setTokenType(TokenType tokenType) { this.tokenType = tokenType; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Instant getUsedAt() { return usedAt; }
    public void setUsedAt(Instant usedAt) { this.usedAt = usedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
