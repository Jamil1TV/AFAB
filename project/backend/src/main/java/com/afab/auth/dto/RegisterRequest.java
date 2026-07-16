package com.afab.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Registration request DTO with validation.
 */
public record RegisterRequest(

        @NotBlank(message = "Name is required")
        @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
        String name,

        @NotBlank(message = "Email is required")
        @Email(message = "Invalid email format")
        String email,

        @NotBlank(message = "Password is required")
        @Size(min = 8, max = 128, message = "Password must be between 8 and 128 characters")
        String password,

        @NotBlank(message = "Business name is required")
        @Size(min = 2, max = 200, message = "Business name must be between 2 and 200 characters")
        String businessName,

        @Size(min = 3, max = 3, message = "Currency must be a 3-letter ISO code")
        String currency
) {
}
