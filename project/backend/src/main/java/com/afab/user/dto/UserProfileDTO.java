package com.afab.user.dto;

public record UserProfileDTO(
        long id,
        String name,
        String email,
        String workspaceName,
        String planType
) {}
