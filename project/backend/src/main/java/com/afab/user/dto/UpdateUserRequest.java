package com.afab.user.dto;

import jakarta.validation.constraints.Size;

public class UpdateUserRequest {

    @Size(min = 1, max = 255, message = "First name must be between 1 and 255 characters")
    private String firstName;

    @Size(min = 1, max = 255, message = "Last name must be between 1 and 255 characters")
    private String lastName;

    @Size(max = 50)
    private String phoneNumber;

    @Size(max = 500)
    private String avatarUrl;

    private Boolean enableAiInsights;
    private Boolean compactMode;
    private Boolean autoCategorizeTransactions;
    private Boolean showTips;

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public Boolean getEnableAiInsights() { return enableAiInsights; }
    public void setEnableAiInsights(Boolean enableAiInsights) { this.enableAiInsights = enableAiInsights; }

    public Boolean getCompactMode() { return compactMode; }
    public void setCompactMode(Boolean compactMode) { this.compactMode = compactMode; }

    public Boolean getAutoCategorizeTransactions() { return autoCategorizeTransactions; }
    public void setAutoCategorizeTransactions(Boolean autoCategorizeTransactions) { this.autoCategorizeTransactions = autoCategorizeTransactions; }

    public Boolean getShowTips() { return showTips; }
    public void setShowTips(Boolean showTips) { this.showTips = showTips; }
}
