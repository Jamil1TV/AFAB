package com.afab.auth.dto;

import java.util.UUID;

public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private UserDto user;
    private boolean requiresTwoFactor = false;
    private String twoFactorToken;

    private String devOtp;

    public AuthResponse() {}

    public AuthResponse(String accessToken, String refreshToken, UserDto user) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.user = user;
    }

    public static AuthResponse twoFactorRequired(String twoFactorToken) {
        AuthResponse response = new AuthResponse(null, null, null);
        response.requiresTwoFactor = true;
        response.twoFactorToken = twoFactorToken;
        return response;
    }

    public String getAccessToken() { return accessToken; }
    public String getRefreshToken() { return refreshToken; }
    public UserDto getUser() { return user; }
    public boolean isRequiresTwoFactor() { return requiresTwoFactor; }
    public String getTwoFactorToken() { return twoFactorToken; }
    public String getDevOtp() { return devOtp; }
    public void setDevOtp(String devOtp) { this.devOtp = devOtp; }

    public static class UserDto {
        private UUID id;
        private String firstName;
        private String lastName;
        private String email;
        private UUID businessId;
        private String avatarUrl;
        private boolean emailVerified;
        private boolean onboardingComplete;
        private boolean twoFactorEnabled;

        public UserDto() {}

        public UserDto(UUID id, String firstName, String lastName, String email, UUID businessId, String avatarUrl, boolean emailVerified, boolean onboardingComplete) {
            this(id, firstName, lastName, email, businessId, avatarUrl, emailVerified, onboardingComplete, false);
        }

        public UserDto(UUID id, String firstName, String lastName, String email, UUID businessId, String avatarUrl, boolean emailVerified, boolean onboardingComplete, boolean twoFactorEnabled) {
            this.id = id;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.businessId = businessId;
            this.avatarUrl = avatarUrl;
            this.emailVerified = emailVerified;
            this.onboardingComplete = onboardingComplete;
            this.twoFactorEnabled = twoFactorEnabled;
        }

        public UUID getId() { return id; }
        public String getFirstName() { return firstName; }
        public String getLastName() { return lastName; }
        public String getEmail() { return email; }
        public UUID getBusinessId() { return businessId; }
        public String getAvatarUrl() { return avatarUrl; }
        public boolean isEmailVerified() { return emailVerified; }
        public boolean isOnboardingComplete() { return onboardingComplete; }
        public boolean isTwoFactorEnabled() { return twoFactorEnabled; }
    }
}
