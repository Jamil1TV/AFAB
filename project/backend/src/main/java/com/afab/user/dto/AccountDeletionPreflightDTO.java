package com.afab.user.dto;

import java.util.List;
import java.util.UUID;

/**
 * Preflight check response before deleting a user account.
 * Identifies any active owned businesses that must be transferred or archived first.
 */
public record AccountDeletionPreflightDTO(
        boolean canDelete,
        List<BlockingBusinessDTO> blockingBusinesses,
        String guidance
) {
    public record BlockingBusinessDTO(
            UUID businessId,
            String businessName,
            long activeMemberCount,
            boolean hasOtherActiveMembers
    ) {}
}
