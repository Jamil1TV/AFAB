package com.afab.subscription;

import com.afab.common.entity.BaseEntity;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "plans")
public class Plan extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String slug;

    @Column(name = "price_monthly", nullable = false)
    private BigDecimal priceMonthly = BigDecimal.ZERO;

    @Column(name = "price_yearly", nullable = false)
    private BigDecimal priceYearly = BigDecimal.ZERO;

    @Column(nullable = false, length = 3)
    private String currency = "USD";

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @OneToMany(mappedBy = "plan", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<PlanEntitlement> entitlements = new ArrayList<>();

    public Plan() {}

    public Plan(String name, String slug, BigDecimal priceMonthly, BigDecimal priceYearly, String currency) {
        this.name = name;
        this.slug = slug;
        this.priceMonthly = priceMonthly;
        this.priceYearly = priceYearly;
        this.currency = currency;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }

    public BigDecimal getPriceMonthly() { return priceMonthly; }
    public void setPriceMonthly(BigDecimal priceMonthly) { this.priceMonthly = priceMonthly; }

    public BigDecimal getPriceYearly() { return priceYearly; }
    public void setPriceYearly(BigDecimal priceYearly) { this.priceYearly = priceYearly; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean active) { isActive = active; }

    public List<PlanEntitlement> getEntitlements() { return entitlements; }
    public void setEntitlements(List<PlanEntitlement> entitlements) { this.entitlements = entitlements; }
}
