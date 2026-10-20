package com.afab.finance.dto;

import jakarta.validation.constraints.Size;

public class UpdateCategoryRequest {

    @Size(min = 1, max = 100, message = "Category name must be between 1 and 100 characters")
    private String name;

    @Size(max = 50, message = "Icon name cannot exceed 50 characters")
    private String icon;

    @Size(max = 30, message = "Color code cannot exceed 30 characters")
    private String color;

    public UpdateCategoryRequest() {}

    public UpdateCategoryRequest(String name, String icon, String color) {
        this.name = name;
        this.icon = icon;
        this.color = color;
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }
}
