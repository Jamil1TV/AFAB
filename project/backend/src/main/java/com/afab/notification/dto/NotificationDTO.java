package com.afab.notification.dto;

import java.time.Instant;
import java.util.UUID;

public class NotificationDTO {
    private UUID id;
    private String type;
    private String severity;
    private String title;
    private String message;
    private String actionUrl;
    private boolean read;
    private Instant readAt;
    private Instant createdAt;

    public NotificationDTO() {}

    public NotificationDTO(UUID id, String type, String severity, String title, String message,
                           String actionUrl, Instant readAt, Instant createdAt) {
        this.id = id;
        this.type = type;
        this.severity = severity;
        this.title = title;
        this.message = message;
        this.actionUrl = actionUrl;
        this.read = readAt != null;
        this.readAt = readAt;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getSeverity() { return severity; }
    public void setSeverity(String severity) { this.severity = severity; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getActionUrl() { return actionUrl; }
    public void setActionUrl(String actionUrl) { this.actionUrl = actionUrl; }

    public boolean isRead() { return read; }
    public void setRead(boolean read) { this.read = read; }

    public Instant getReadAt() { return readAt; }
    public void setReadAt(Instant readAt) { this.readAt = readAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
