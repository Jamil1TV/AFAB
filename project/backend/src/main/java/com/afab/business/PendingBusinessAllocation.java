package com.afab.business;

import com.afab.user.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "pending_business_allocations", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "business_id"})
})
public class PendingBusinessAllocation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    @Column(name = "target_plan_slug", nullable = false, length = 50)
    private String targetPlanSlug;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public PendingBusinessAllocation() {}

    public PendingBusinessAllocation(User user, Business business, String targetPlanSlug) {
        this.user = user;
        this.business = business;
        this.targetPlanSlug = targetPlanSlug;
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Business getBusiness() { return business; }
    public void setBusiness(Business business) { this.business = business; }

    public String getTargetPlanSlug() { return targetPlanSlug; }
    public void setTargetPlanSlug(String targetPlanSlug) { this.targetPlanSlug = targetPlanSlug; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
