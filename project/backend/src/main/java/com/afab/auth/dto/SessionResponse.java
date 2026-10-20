package com.afab.auth.dto;

import java.time.Instant;
import java.util.UUID;

public class SessionResponse {
    private UUID id;
    private String deviceInfo;
    private String ipAddress;
    private Instant createdAt;
    private Instant expiresAt;
    private boolean current;

    public SessionResponse() {}

    public SessionResponse(UUID id, String deviceInfo, String ipAddress, Instant createdAt, Instant expiresAt, boolean current) {
        this.id = id;
        this.deviceInfo = deviceInfo;
        this.ipAddress = ipAddress;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
        this.current = current;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getDeviceInfo() { return deviceInfo; }
    public void setDeviceInfo(String deviceInfo) { this.deviceInfo = deviceInfo; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public boolean isCurrent() { return current; }
    public void setCurrent(boolean current) { this.current = current; }
}
