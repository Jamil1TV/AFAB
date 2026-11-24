package com.afab.ai.domain;

import com.afab.business.Business;
import com.afab.user.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_tool_audit")
public class AiToolAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "conversation_id")
    private UUID conversationId;

    @Column(name = "tool_name", nullable = false, length = 80)
    private String toolName;

    @Column(name = "arguments_hash", nullable = false, length = 64)
    private String argumentsHash;

    @Column(name = "result_status", nullable = false, length = 40)
    private String resultStatus;

    @Column(name = "approval_status", nullable = false, length = 30)
    private String approvalStatus = "AUTO_READ_ONLY";

    @Column(name = "duration_ms", nullable = false)
    private long durationMs = 0L;

    @Column(name = "executed_at", nullable = false, updatable = false)
    private Instant executedAt;

    public AiToolAudit() {}

    @PrePersist
    protected void onCreate() {
        this.executedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Business getBusiness() { return business; }
    public void setBusiness(Business business) { this.business = business; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public UUID getConversationId() { return conversationId; }
    public void setConversationId(UUID conversationId) { this.conversationId = conversationId; }

    public String getToolName() { return toolName; }
    public void setToolName(String toolName) { this.toolName = toolName; }

    public String getArgumentsHash() { return argumentsHash; }
    public void setArgumentsHash(String argumentsHash) { this.argumentsHash = argumentsHash; }

    public String getResultStatus() { return resultStatus; }
    public void setResultStatus(String resultStatus) { this.resultStatus = resultStatus; }

    public String getApprovalStatus() { return approvalStatus; }
    public void setApprovalStatus(String approvalStatus) { this.approvalStatus = approvalStatus; }

    public long getDurationMs() { return durationMs; }
    public void setDurationMs(long durationMs) { this.durationMs = durationMs; }

    public Instant getExecutedAt() { return executedAt; }
}
