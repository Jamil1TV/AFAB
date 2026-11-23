package com.afab.business.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public class BusinessAllocationDTO {

    private String currentPlanSlug;
    private String currentPlanName;
    private int editableLimit;
    private int editableCount;
    private int readOnlyCount;
    private int totalOwnedCount;
    private boolean allocationAttentionRequired;
    private String pendingPlanSlug;
    private String pendingPlanName;
    private Integer pendingEditableLimit;
    private Instant pendingChangeEffectiveAt;
    private List<UUID> pendingBusinessIds;
    private List<BusinessAllocationItemDTO> businesses;

    public static class BusinessAllocationItemDTO {
        private UUID id;
        private String name;
        private String currency;
        private String industry;
        private String country;
        private String logoUrl;
        private String accessMode;
        private boolean editable;
        private boolean primary;
        private boolean active;
        private boolean selectedForPending;
        private Instant createdAt;

        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getCurrency() { return currency; }
        public void setCurrency(String currency) { this.currency = currency; }

        public String getIndustry() { return industry; }
        public void setIndustry(String industry) { this.industry = industry; }

        public String getCountry() { return country; }
        public void setCountry(String country) { this.country = country; }

        public String getLogoUrl() { return logoUrl; }
        public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }

        public String getAccessMode() { return accessMode; }
        public void setAccessMode(String accessMode) { this.accessMode = accessMode; }

        public boolean isEditable() { return editable; }
        public void setEditable(boolean editable) { this.editable = editable; }

        public boolean isPrimary() { return primary; }
        public void setPrimary(boolean primary) { this.primary = primary; }

        public boolean isActive() { return active; }
        public void setActive(boolean active) { this.active = active; }

        public boolean isSelectedForPending() { return selectedForPending; }
        public void setSelectedForPending(boolean selectedForPending) { this.selectedForPending = selectedForPending; }

        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    }

    public String getCurrentPlanSlug() { return currentPlanSlug; }
    public void setCurrentPlanSlug(String currentPlanSlug) { this.currentPlanSlug = currentPlanSlug; }

    public String getCurrentPlanName() { return currentPlanName; }
    public void setCurrentPlanName(String currentPlanName) { this.currentPlanName = currentPlanName; }

    public int getEditableLimit() { return editableLimit; }
    public void setEditableLimit(int editableLimit) { this.editableLimit = editableLimit; }

    public int getEditableCount() { return editableCount; }
    public void setEditableCount(int editableCount) { this.editableCount = editableCount; }

    public int getReadOnlyCount() { return readOnlyCount; }
    public void setReadOnlyCount(int readOnlyCount) { this.readOnlyCount = readOnlyCount; }

    public int getTotalOwnedCount() { return totalOwnedCount; }
    public void setTotalOwnedCount(int totalOwnedCount) { this.totalOwnedCount = totalOwnedCount; }

    public boolean isAllocationAttentionRequired() { return allocationAttentionRequired; }
    public void setAllocationAttentionRequired(boolean allocationAttentionRequired) { this.allocationAttentionRequired = allocationAttentionRequired; }

    public String getPendingPlanSlug() { return pendingPlanSlug; }
    public void setPendingPlanSlug(String pendingPlanSlug) { this.pendingPlanSlug = pendingPlanSlug; }

    public String getPendingPlanName() { return pendingPlanName; }
    public void setPendingPlanName(String pendingPlanName) { this.pendingPlanName = pendingPlanName; }

    public Integer getPendingEditableLimit() { return pendingEditableLimit; }
    public void setPendingEditableLimit(Integer pendingEditableLimit) { this.pendingEditableLimit = pendingEditableLimit; }

    public Instant getPendingChangeEffectiveAt() { return pendingChangeEffectiveAt; }
    public void setPendingChangeEffectiveAt(Instant pendingChangeEffectiveAt) { this.pendingChangeEffectiveAt = pendingChangeEffectiveAt; }

    public List<UUID> getPendingBusinessIds() { return pendingBusinessIds; }
    public void setPendingBusinessIds(List<UUID> pendingBusinessIds) { this.pendingBusinessIds = pendingBusinessIds; }

    public List<BusinessAllocationItemDTO> getBusinesses() { return businesses; }
    public void setBusinesses(List<BusinessAllocationItemDTO> businesses) { this.businesses = businesses; }
}
