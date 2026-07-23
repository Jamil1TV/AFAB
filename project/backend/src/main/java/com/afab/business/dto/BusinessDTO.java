package com.afab.business.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * Response DTO for business data — includes all profile fields.
 */
public class BusinessDTO {
    private UUID id;
    private String name;
    private String country;
    private String currency;
    private String timezone;
    private Integer fiscalYearStartMonth;
    private String industry;
    private String businessType;
    private String businessEmail;
    private String phoneNumber;
    private String website;
    private String taxId;
    private String addressLine;
    private String city;
    private String state;
    private String postalCode;
    private String description;
    private String logoUrl;
    private String status;
    private boolean onboardingComplete;
    private Instant createdAt;
    private String dateFormat;
    private String numberFormat;

    public BusinessDTO() {}

    // ── Getters ───────────────────────

    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getCountry() { return country; }
    public String getCurrency() { return currency; }
    public String getTimezone() { return timezone; }
    public Integer getFiscalYearStartMonth() { return fiscalYearStartMonth; }
    public String getIndustry() { return industry; }
    public String getBusinessType() { return businessType; }
    public String getBusinessEmail() { return businessEmail; }
    public String getPhoneNumber() { return phoneNumber; }
    public String getWebsite() { return website; }
    public String getTaxId() { return taxId; }
    public String getAddressLine() { return addressLine; }
    public String getCity() { return city; }
    public String getState() { return state; }
    public String getPostalCode() { return postalCode; }
    public String getDescription() { return description; }
    public String getLogoUrl() { return logoUrl; }
    public String getStatus() { return status; }
    public boolean isOnboardingComplete() { return onboardingComplete; }
    public Instant getCreatedAt() { return createdAt; }
    public String getDateFormat() { return dateFormat; }
    public String getNumberFormat() { return numberFormat; }

    // ── Setters ───────────────────────

    public void setId(UUID id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setCountry(String country) { this.country = country; }
    public void setCurrency(String currency) { this.currency = currency; }
    public void setTimezone(String timezone) { this.timezone = timezone; }
    public void setFiscalYearStartMonth(Integer fiscalYearStartMonth) { this.fiscalYearStartMonth = fiscalYearStartMonth; }
    public void setIndustry(String industry) { this.industry = industry; }
    public void setBusinessType(String businessType) { this.businessType = businessType; }
    public void setBusinessEmail(String businessEmail) { this.businessEmail = businessEmail; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public void setWebsite(String website) { this.website = website; }
    public void setTaxId(String taxId) { this.taxId = taxId; }
    public void setAddressLine(String addressLine) { this.addressLine = addressLine; }
    public void setCity(String city) { this.city = city; }
    public void setState(String state) { this.state = state; }
    public void setPostalCode(String postalCode) { this.postalCode = postalCode; }
    public void setDescription(String description) { this.description = description; }
    public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }
    public void setStatus(String status) { this.status = status; }
    public void setOnboardingComplete(boolean onboardingComplete) { this.onboardingComplete = onboardingComplete; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public void setDateFormat(String dateFormat) { this.dateFormat = dateFormat; }
    public void setNumberFormat(String numberFormat) { this.numberFormat = numberFormat; }
}
