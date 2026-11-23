package com.afab.business.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import java.util.UUID;

public class SavePendingAllocationRequest {

    @NotBlank(message = "Target plan slug is required")
    private String targetPlanSlug;

    @NotEmpty(message = "Selected business IDs are required")
    private List<UUID> selectedBusinessIds;

    public String getTargetPlanSlug() { return targetPlanSlug; }
    public void setTargetPlanSlug(String targetPlanSlug) { this.targetPlanSlug = targetPlanSlug; }

    public List<UUID> getSelectedBusinessIds() { return selectedBusinessIds; }
    public void setSelectedBusinessIds(List<UUID> selectedBusinessIds) { this.selectedBusinessIds = selectedBusinessIds; }
}
