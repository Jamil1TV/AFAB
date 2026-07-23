package com.afab.user.dto;

import java.time.Instant;
import java.util.UUID;

public class UserProfileDTO {
    private UUID id;
    private String firstName;
    private String lastName;
    private String email;
    private String phoneNumber;
    private String avatarUrl;
    private boolean emailVerified;
    private UUID businessId;
    private String businessName;
    private String currency;
    private String country;
    private boolean onboardingComplete;
    private Instant createdAt;
    private Instant passwordChangedAt;
    private boolean twoFactorEnabled;
    private Instant lastLoginAt;
    private String lastLoginIp;
    private boolean enableAiInsights;
    private boolean compactMode;
    private boolean autoCategorizeTransactions;
    private boolean showTips;

    public UserProfileDTO() {}

    public UserProfileDTO(UUID id, String firstName, String lastName, String email, String phoneNumber,
                          String avatarUrl, boolean emailVerified, UUID businessId, String businessName, String currency,
                          String country, boolean onboardingComplete, Instant createdAt,
                          Instant passwordChangedAt, boolean twoFactorEnabled, Instant lastLoginAt, String lastLoginIp,
                          boolean enableAiInsights, boolean compactMode, boolean autoCategorizeTransactions, boolean showTips) {
        this.id = id;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.avatarUrl = avatarUrl;
        this.emailVerified = emailVerified;
        this.businessId = businessId;
        this.businessName = businessName;
        this.currency = currency;
        this.country = country;
        this.onboardingComplete = onboardingComplete;
        this.createdAt = createdAt;
        this.passwordChangedAt = passwordChangedAt;
        this.twoFactorEnabled = twoFactorEnabled;
        this.lastLoginAt = lastLoginAt;
        this.lastLoginIp = lastLoginIp;
        this.enableAiInsights = enableAiInsights;
        this.compactMode = compactMode;
        this.autoCategorizeTransactions = autoCategorizeTransactions;
        this.showTips = showTips;
    }

    public UUID getId() { return id; }
    public String getFirstName() { return firstName; }
    public String getLastName() { return lastName; }
    public String getEmail() { return email; }
    public String getPhoneNumber() { return phoneNumber; }
    public String getAvatarUrl() { return avatarUrl; }
    public boolean isEmailVerified() { return emailVerified; }
    public UUID getBusinessId() { return businessId; }
    public String getBusinessName() { return businessName; }
    public String getCurrency() { return currency; }
    public String getCountry() { return country; }
    public boolean isOnboardingComplete() { return onboardingComplete; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getPasswordChangedAt() { return passwordChangedAt; }
    public boolean isTwoFactorEnabled() { return twoFactorEnabled; }
    public Instant getLastLoginAt() { return lastLoginAt; }
    public String getLastLoginIp() { return lastLoginIp; }
    public boolean isEnableAiInsights() { return enableAiInsights; }
    public boolean isCompactMode() { return compactMode; }
    public boolean isAutoCategorizeTransactions() { return autoCategorizeTransactions; }
    public boolean isShowTips() { return showTips; }
}
