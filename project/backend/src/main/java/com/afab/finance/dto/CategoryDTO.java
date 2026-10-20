package com.afab.finance.dto;

import java.time.Instant;
import java.util.UUID;

public class CategoryDTO {
    private UUID id;
    private UUID businessId;
    private String name;
    private String type;
    private String icon;
    private String color;
    private boolean isSystemDefault;
    private Instant createdAt;
    private Instant updatedAt;

    public CategoryDTO() {}

    public CategoryDTO(UUID id, String name, String type, String icon, String color) {
        this.id = id;
        this.name = name;
        this.type = type;
        this.icon = icon;
        this.color = color;
        this.isSystemDefault = true;
    }

    public CategoryDTO(UUID id, UUID businessId, String name, String type, String icon, String color, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.businessId = businessId;
        this.name = name;
        this.type = type;
        this.icon = icon;
        this.color = color;
        this.isSystemDefault = (businessId == null);
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { 
        this.businessId = businessId; 
        this.isSystemDefault = (businessId == null);
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }

    public boolean isSystemDefault() { return isSystemDefault; }
    public void setSystemDefault(boolean systemDefault) { isSystemDefault = systemDefault; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
