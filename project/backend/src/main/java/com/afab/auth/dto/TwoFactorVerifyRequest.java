package com.afab.auth.dto;

import jakarta.validation.constraints.NotBlank;

public class TwoFactorVerifyRequest {
    @NotBlank(message = "Two-factor session token is required")
    private String twoFactorToken;

    @NotBlank(message = "Code is required")
    private String code;

    private Boolean rememberMe = false;

    public String getTwoFactorToken() { return twoFactorToken; }
    public void setTwoFactorToken(String twoFactorToken) { this.twoFactorToken = twoFactorToken; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public Boolean getRememberMe() { return rememberMe; }
    public void setRememberMe(Boolean rememberMe) { this.rememberMe = rememberMe; }
}
