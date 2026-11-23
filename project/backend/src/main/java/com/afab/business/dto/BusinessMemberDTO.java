package com.afab.business.dto;

import java.time.Instant;
import java.util.UUID;

public record BusinessMemberDTO(
        UUID memberId,
        UUID userId,
        String firstName,
        String lastName,
        String email,
        String role,
        String status,
        Instant joinedAt
) {}
