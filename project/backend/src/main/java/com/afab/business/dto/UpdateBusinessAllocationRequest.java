package com.afab.business.dto;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import java.util.UUID;

public class UpdateBusinessAllocationRequest {

    @NotEmpty(message = "At least one business must be selected")
    private List<UUID> selectedBusinessIds;

    private UUID primaryBusinessId;

    public List<UUID> getSelectedBusinessIds() { return selectedBusinessIds; }
    public void setSelectedBusinessIds(List<UUID> selectedBusinessIds) { this.selectedBusinessIds = selectedBusinessIds; }

    public UUID getPrimaryBusinessId() { return primaryBusinessId; }
    public void setPrimaryBusinessId(UUID primaryBusinessId) { this.primaryBusinessId = primaryBusinessId; }
}
