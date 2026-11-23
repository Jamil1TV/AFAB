package com.afab.business.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class TransferOwnershipRequest {

    @NotNull(message = "Target user ID is required")
    private UUID targetUserId;

    public TransferOwnershipRequest() {}

    public TransferOwnershipRequest(UUID targetUserId) {
        this.targetUserId = targetUserId;
    }

    public UUID getTargetUserId() { return targetUserId; }
    public void setTargetUserId(UUID targetUserId) { this.targetUserId = targetUserId; }
}
