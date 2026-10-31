package com.afab.subscription;

import com.afab.user.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "usage_counters", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "feature_key", "period_start"})
})
public class UsageCounter {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "feature_key", nullable = false)
    private String featureKey;

    @Column(name = "period_start", nullable = false)
    private Instant periodStart;

    @Column(nullable = false)
    private int used = 0;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public UsageCounter() {}

    public UsageCounter(User user, String featureKey, Instant periodStart, int used) {
        this.user = user;
        this.featureKey = featureKey;
        this.periodStart = periodStart;
        this.used = used;
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getFeatureKey() { return featureKey; }
    public void setFeatureKey(String featureKey) { this.featureKey = featureKey; }

    public Instant getPeriodStart() { return periodStart; }
    public void setPeriodStart(Instant periodStart) { this.periodStart = periodStart; }

    public int getUsed() { return used; }
    public void setUsed(int used) { this.used = used; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
