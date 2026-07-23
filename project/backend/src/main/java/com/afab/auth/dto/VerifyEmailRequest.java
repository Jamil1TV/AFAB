package com.afab.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request to verify email using a 6-digit OTP code.
 */
public class VerifyEmailRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Verification code is required")
    @Size(min = 6, max = 6, message = "Code must be exactly 6 digits")
    private String code;

    public VerifyEmailRequest() {}

    public VerifyEmailRequest(String email, String code) {
        this.email = email;
        this.code = code;
    }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
}
