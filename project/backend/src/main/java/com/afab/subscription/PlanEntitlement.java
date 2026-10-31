package com.afab.subscription;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "plan_entitlements", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"plan_id", "feature_key"})
})
public class PlanEntitlement {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_id", nullable = false)
    private Plan plan;

    @Column(name = "feature_key", nullable = false)
    private String featureKey;

    @Column(nullable = false)
    private String type; // BOOLEAN, LIMIT, QUOTA, LEVEL

    @Column(nullable = false)
    private String value;

    public PlanEntitlement() {}

    public PlanEntitlement(Plan plan, String featureKey, String type, String value) {
        this.plan = plan;
        this.featureKey = featureKey;
        this.type = type;
        this.value = value;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Plan getPlan() { return plan; }
    public void setPlan(Plan plan) { this.plan = plan; }

    public String getFeatureKey() { return featureKey; }
    public void setFeatureKey(String featureKey) { this.featureKey = featureKey; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
}
