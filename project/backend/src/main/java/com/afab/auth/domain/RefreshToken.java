package com.afab.auth.domain;

import com.afab.user.User;
import jakarta.persistence.*;
import java.util.UUID;

import java.time.Instant;

/**
 * Persisted Refresh Token for stateless JWT sessions.
 * Allows revoking sessions instantly if an account is compromised.
 */
@Entity
@Table(name = "refresh_tokens")
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "token_hash", nullable = false, unique = true, length = 512)
    private String tokenHash;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "revoked_at")
    private Instant revokedAt;

    @Column(name = "device_info")
    private String deviceInfo;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "token_family_id", nullable = false)
    private UUID tokenFamilyId;

    @Column(name = "remember_me", nullable = false)
    private boolean rememberMe = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
        if (this.tokenFamilyId == null) {
            this.tokenFamilyId = UUID.randomUUID();
        }
    }

    // ── Constructors ────────────────────────────

    public RefreshToken() {}

    public RefreshToken(User user, String tokenHash, Instant expiresAt, String deviceInfo, String ipAddress) {
        this(user, tokenHash, expiresAt, deviceInfo, ipAddress, UUID.randomUUID(), false);
    }

    public RefreshToken(User user, String tokenHash, Instant expiresAt, String deviceInfo, String ipAddress,
                        UUID tokenFamilyId, boolean rememberMe) {
        this.user = user;
        this.tokenHash = tokenHash;
        this.expiresAt = expiresAt;
        this.deviceInfo = deviceInfo;
        this.ipAddress = ipAddress;
        this.tokenFamilyId = tokenFamilyId != null ? tokenFamilyId : UUID.randomUUID();
        this.rememberMe = rememberMe;
    }

    // ── Getters & Setters ───────────────────────

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getTokenHash() { return tokenHash; }
    public void setTokenHash(String tokenHash) { this.tokenHash = tokenHash; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Instant getRevokedAt() { return revokedAt; }
    public void setRevokedAt(Instant revokedAt) { this.revokedAt = revokedAt; }

    public String getDeviceInfo() { return deviceInfo; }
    public void setDeviceInfo(String deviceInfo) { this.deviceInfo = deviceInfo; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public UUID getTokenFamilyId() { return tokenFamilyId; }
    public void setTokenFamilyId(UUID tokenFamilyId) { this.tokenFamilyId = tokenFamilyId; }

    public boolean isRememberMe() { return rememberMe; }
    public void setRememberMe(boolean rememberMe) { this.rememberMe = rememberMe; }

    public Instant getCreatedAt() { return createdAt; }
}
