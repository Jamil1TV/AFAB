package com.afab.business.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request DTO for updating business onboarding details.
 */
public class UpdateBusinessRequest {

    @NotBlank(message = "Country is required")
    @Size(max = 100)
    private String country;

    @NotBlank(message = "Currency is required")
    @Size(min = 3, max = 3, message = "Currency must be a 3-letter ISO code")
    private String currency;

    @NotBlank(message = "Timezone is required")
    @Size(max = 50)
    private String timezone;

    private Integer fiscalYearStartMonth = 1;

    private String industry;

    private String businessType;

    // ── Getters & Setters ───────────────────────

    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getTimezone() { return timezone; }
    public void setTimezone(String timezone) { this.timezone = timezone; }

    public Integer getFiscalYearStartMonth() { return fiscalYearStartMonth; }
    public void setFiscalYearStartMonth(Integer fiscalYearStartMonth) { this.fiscalYearStartMonth = fiscalYearStartMonth; }

    public String getIndustry() { return industry; }
    public void setIndustry(String industry) { this.industry = industry; }

    public String getBusinessType() { return businessType; }
    public void setBusinessType(String businessType) { this.businessType = businessType; }
}
