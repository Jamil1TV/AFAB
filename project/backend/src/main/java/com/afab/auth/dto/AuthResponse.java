package com.afab.auth.dto;

import java.util.UUID;

public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private UserDto user;

    public AuthResponse(String accessToken, String refreshToken, UserDto user) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.user = user;
    }

    public String getAccessToken() { return accessToken; }
    public String getRefreshToken() { return refreshToken; }
    public UserDto getUser() { return user; }

    public static class UserDto {
        private UUID id;
        private String firstName;
        private String lastName;
        private String email;
        private UUID businessId;
        private boolean emailVerified;

        public UserDto(UUID id, String firstName, String lastName, String email, UUID businessId, boolean emailVerified) {
            this.id = id;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.businessId = businessId;
            this.emailVerified = emailVerified;
        }

        public UUID getId() { return id; }
        public String getFirstName() { return firstName; }
        public String getLastName() { return lastName; }
        public String getEmail() { return email; }
        public UUID getBusinessId() { return businessId; }
        public boolean isEmailVerified() { return emailVerified; }
    }
}
