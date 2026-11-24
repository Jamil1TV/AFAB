package com.afab.ai.dto;

import jakarta.validation.constraints.Size;

import java.time.Instant;

public class BusinessMemoryUpdateRequest {

    @Size(max = 50)
    private String memoryType;

    @Size(max = 160)
    private String title;

    @Size(max = 2000)
    private String content;

    @Size(max = 20)
    private String status;

    private Instant expiresAt;

    public String getMemoryType() { return memoryType; }
    public void setMemoryType(String memoryType) { this.memoryType = memoryType; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
}
