package com.afab.subscription;

import com.afab.common.entity.BaseEntity;
import com.afab.user.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "subscriptions", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id"})
})
public class Subscription extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "plan_id", nullable = false)
    private Plan plan;

    @Column(nullable = false)
    private String status = "ACTIVE"; // ACTIVE, TRIALING, PAST_DUE, CANCELED, EXPIRED

    @Column(name = "period_start", nullable = false)
    private Instant periodStart = Instant.now();

    @Column(name = "period_end")
    private Instant periodEnd;

    @Column(name = "trial_end")
    private Instant trialEnd;

    @Column(name = "cancel_at_period_end", nullable = false)
    private Boolean cancelAtPeriodEnd = false;

    public Subscription() {}

    public Subscription(User user, Plan plan, String status, Instant periodStart) {
        this.user = user;
        this.plan = plan;
        this.status = status;
        this.periodStart = periodStart;
    }

    public boolean isTrialActive() {
        return "TRIALING".equalsIgnoreCase(status) && trialEnd != null && trialEnd.isAfter(Instant.now());
    }

    public boolean isSubscribed() {
        if ("ACTIVE".equalsIgnoreCase(status)) return true;
        return isTrialActive();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Plan getPlan() { return plan; }
    public void setPlan(Plan plan) { this.plan = plan; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getPeriodStart() { return periodStart; }
    public void setPeriodStart(Instant periodStart) { this.periodStart = periodStart; }

    public Instant getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(Instant periodEnd) { this.periodEnd = periodEnd; }

    public Instant getTrialEnd() { return trialEnd; }
    public void setTrialEnd(Instant trialEnd) { this.trialEnd = trialEnd; }

    public Boolean getCancelAtPeriodEnd() { return cancelAtPeriodEnd; }
    public void setCancelAtPeriodEnd(Boolean cancelAtPeriodEnd) { this.cancelAtPeriodEnd = cancelAtPeriodEnd; }
}
