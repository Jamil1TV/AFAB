package com.afab.business;

import com.afab.common.entity.BaseEntity;
import com.afab.user.User;
import jakarta.persistence.*;
import java.util.UUID;

import java.time.Instant;

/**
 * Business entity — every user owns exactly one business in V1.
 */
@Entity
@Table(name = "businesses")
public class Business extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 3)
    private String currency;

    @Column(length = 100)
    private String country;

    @Column(length = 50)
    private String timezone;

    @Column(name = "fiscal_year_start_month", nullable = false)
    private Integer fiscalYearStartMonth = 1;

    @Column(length = 100)
    private String industry;

    @Column(name = "business_type", length = 50)
    private String businessType;

    @Column(nullable = false)
    private String status = "ACTIVE";

    @Column(name = "deleted_at")
    private Instant deletedAt;

    // ── Constructors ────────────────────────────

    public Business() {}

    public Business(User user, String name, String currency) {
        this.user = user;
        this.name = name;
        this.currency = currency;
    }

    // ── Getters & Setters ───────────────────────

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone;
    }

    public Integer getFiscalYearStartMonth() {
        return fiscalYearStartMonth;
    }

    public void setFiscalYearStartMonth(Integer fiscalYearStartMonth) {
        this.fiscalYearStartMonth = fiscalYearStartMonth;
    }

    public String getIndustry() { return industry; }
    public void setIndustry(String industry) { this.industry = industry; }

    public String getBusinessType() { return businessType; }
    public void setBusinessType(String businessType) { this.businessType = businessType; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getDeletedAt() { return deletedAt; }
    public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }

    /**
     * Onboarding is considered complete when country and timezone are filled.
     */
    public boolean isOnboardingComplete() {
        return country != null && !country.isBlank()
                && timezone != null && !timezone.isBlank();
    }
}
