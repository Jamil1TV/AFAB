package com.afab.finance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class CreateCategoryRequest {

    @NotBlank(message = "Category name is required")
    @Size(min = 1, max = 100, message = "Category name must be between 1 and 100 characters")
    private String name;

    @NotBlank(message = "Category type is required")
    @Pattern(regexp = "^(INCOME|EXPENSE)$", message = "Type must be either INCOME or EXPENSE")
    private String type;

    @Size(max = 50, message = "Icon name cannot exceed 50 characters")
    private String icon;

    @Size(max = 30, message = "Color code cannot exceed 30 characters")
    private String color;

    public CreateCategoryRequest() {}

    public CreateCategoryRequest(String name, String type, String icon, String color) {
        this.name = name;
        this.type = type;
        this.icon = icon;
        this.color = color;
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }
}
