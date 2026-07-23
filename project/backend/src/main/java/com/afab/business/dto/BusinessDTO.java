package com.afab.business.dto;

import java.util.UUID;

/**
 * Response DTO for business data.
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
    private String status;
    private boolean onboardingComplete;

    public BusinessDTO() {}

    public BusinessDTO(UUID id, String name, String country, String currency, String timezone,
                       Integer fiscalYearStartMonth, String industry, String businessType,
                       String status, boolean onboardingComplete) {
        this.id = id;
        this.name = name;
        this.country = country;
        this.currency = currency;
        this.timezone = timezone;
        this.fiscalYearStartMonth = fiscalYearStartMonth;
        this.industry = industry;
        this.businessType = businessType;
        this.status = status;
        this.onboardingComplete = onboardingComplete;
    }

    // ── Getters ───────────────────────

    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getCountry() { return country; }
    public String getCurrency() { return currency; }
    public String getTimezone() { return timezone; }
    public Integer getFiscalYearStartMonth() { return fiscalYearStartMonth; }
    public String getIndustry() { return industry; }
    public String getBusinessType() { return businessType; }
    public String getStatus() { return status; }
    public boolean isOnboardingComplete() { return onboardingComplete; }
}
