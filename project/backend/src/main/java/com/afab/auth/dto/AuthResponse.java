package com.afab.auth.dto;

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
        private Long id;
        private String firstName;
        private String lastName;
        private String email;
        private Long businessId;

        public UserDto(Long id, String firstName, String lastName, String email, Long businessId) {
            this.id = id;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.businessId = businessId;
        }

        public Long getId() { return id; }
        public String getFirstName() { return firstName; }
        public String getLastName() { return lastName; }
        public String getEmail() { return email; }
        public Long getBusinessId() { return businessId; }
    }
}
