package com.afab.user.dto;

import java.time.Instant;
import java.util.UUID;

public class SessionDTO {
    private UUID id;
    private String deviceInfo;
    private String ipAddress;
    private Instant createdAt;
    private Instant expiresAt;
    private boolean currentSession;

    public SessionDTO() {}

    public SessionDTO(UUID id, String deviceInfo, String ipAddress, Instant createdAt, Instant expiresAt, boolean currentSession) {
        this.id = id;
        this.deviceInfo = deviceInfo;
        this.ipAddress = ipAddress;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
        this.currentSession = currentSession;
    }

    public UUID getId() { return id; }
    public String getDeviceInfo() { return deviceInfo; }
    public String getIpAddress() { return ipAddress; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getExpiresAt() { return expiresAt; }
    public boolean isCurrentSession() { return currentSession; }
}
