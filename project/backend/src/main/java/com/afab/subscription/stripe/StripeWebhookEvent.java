package com.afab.subscription.stripe;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "stripe_webhook_events")
public class StripeWebhookEvent {

    @Id
    @Column(name = "event_id", nullable = false, updatable = false)
    private String eventId;

    @Column(name = "event_type", nullable = false)
    private String eventType;

    @Column(name = "processed_at", nullable = false)
    private Instant processedAt = Instant.now();

    public StripeWebhookEvent() {}

    public StripeWebhookEvent(String eventId, String eventType) {
        this.eventId = eventId;
        this.eventType = eventType;
        this.processedAt = Instant.now();
    }

    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }

    public Instant getProcessedAt() { return processedAt; }
    public void setProcessedAt(Instant processedAt) { this.processedAt = processedAt; }
}
