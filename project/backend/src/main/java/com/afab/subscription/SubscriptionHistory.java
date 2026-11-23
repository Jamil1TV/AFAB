package com.afab.subscription;

import com.afab.user.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "subscription_history")
public class SubscriptionHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "event_type", nullable = false, length = 60)
    private String eventType;

    @Column(name = "from_plan_slug", length = 50)
    private String fromPlanSlug;

    @Column(name = "to_plan_slug", length = 50)
    private String toPlanSlug;

    @Column(name = "from_status", length = 30)
    private String fromStatus;

    @Column(name = "to_status", length = 30)
    private String toStatus;

    @Column(name = "stripe_event_id")
    private String stripeEventId;

    @Column(name = "effective_at")
    private Instant effectiveAt;

    @Column(columnDefinition = "TEXT")
    private String details;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public SubscriptionHistory() {}

    public SubscriptionHistory(User user, String eventType, String fromPlanSlug, String toPlanSlug,
                               String fromStatus, String toStatus, String stripeEventId,
                               Instant effectiveAt, String details) {
        this.user = user;
        this.eventType = eventType;
        this.fromPlanSlug = fromPlanSlug;
        this.toPlanSlug = toPlanSlug;
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
        this.stripeEventId = stripeEventId;
        this.effectiveAt = effectiveAt;
        this.details = details;
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }

    public String getFromPlanSlug() { return fromPlanSlug; }
    public void setFromPlanSlug(String fromPlanSlug) { this.fromPlanSlug = fromPlanSlug; }

    public String getToPlanSlug() { return toPlanSlug; }
    public void setToPlanSlug(String toPlanSlug) { this.toPlanSlug = toPlanSlug; }

    public String getFromStatus() { return fromStatus; }
    public void setFromStatus(String fromStatus) { this.fromStatus = fromStatus; }

    public String getToStatus() { return toStatus; }
    public void setToStatus(String toStatus) { this.toStatus = toStatus; }

    public String getStripeEventId() { return stripeEventId; }
    public void setStripeEventId(String stripeEventId) { this.stripeEventId = stripeEventId; }

    public Instant getEffectiveAt() { return effectiveAt; }
    public void setEffectiveAt(Instant effectiveAt) { this.effectiveAt = effectiveAt; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
