package com.afab.ai.domain;

import com.afab.business.Business;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_messages")
public class AiMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", nullable = false)
    private AiConversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    @Column(nullable = false, length = 20)
    private String role;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "evidence_json", columnDefinition = "TEXT")
    private String evidenceJson;

    @Column(name = "tools_used_json", columnDefinition = "TEXT")
    private String toolsUsedJson;

    @Column(name = "thinking_content", columnDefinition = "TEXT")
    private String thinkingContent;

    @Column(name = "charts_json", columnDefinition = "TEXT")
    private String chartsJson;

    @Column(name = "action_drafts_json", columnDefinition = "TEXT")
    private String actionDraftsJson;

    @Column(name = "attachments_json", columnDefinition = "TEXT")
    private String attachmentsJson;

    @Column(name = "reasoning_mode", nullable = false, length = 16)
    private String reasoningMode = "fast";

    @Column(name = "response_language", length = 24)
    private String responseLanguage;

    @Column(name = "data_coverage", length = 50)
    private String dataCoverage;

    @Column(name = "model_id", length = 120)
    private String modelId;

    @Column(name = "prompt_version", length = 60)
    private String promptVersion;

    @Column(name = "prompt_tokens", nullable = false)
    private int promptTokens = 0;

    @Column(name = "completion_tokens", nullable = false)
    private int completionTokens = 0;

    @Column(name = "total_tokens", nullable = false)
    private int totalTokens = 0;

    @Column(name = "latency_ms")
    private Long latencyMs;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public AiMessage() {}

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public AiConversation getConversation() { return conversation; }
    public void setConversation(AiConversation conversation) { this.conversation = conversation; }

    public Business getBusiness() { return business; }
    public void setBusiness(Business business) { this.business = business; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getEvidenceJson() { return evidenceJson; }
    public void setEvidenceJson(String evidenceJson) { this.evidenceJson = evidenceJson; }

    public String getToolsUsedJson() { return toolsUsedJson; }
    public void setToolsUsedJson(String toolsUsedJson) { this.toolsUsedJson = toolsUsedJson; }

    public String getThinkingContent() { return thinkingContent; }
    public void setThinkingContent(String thinkingContent) { this.thinkingContent = thinkingContent; }

    public String getChartsJson() { return chartsJson; }
    public void setChartsJson(String chartsJson) { this.chartsJson = chartsJson; }

    public String getActionDraftsJson() { return actionDraftsJson; }
    public void setActionDraftsJson(String actionDraftsJson) { this.actionDraftsJson = actionDraftsJson; }

    public String getAttachmentsJson() { return attachmentsJson; }
    public void setAttachmentsJson(String attachmentsJson) { this.attachmentsJson = attachmentsJson; }

    public String getReasoningMode() { return reasoningMode; }
    public void setReasoningMode(String reasoningMode) { this.reasoningMode = reasoningMode; }

    public String getResponseLanguage() { return responseLanguage; }
    public void setResponseLanguage(String responseLanguage) { this.responseLanguage = responseLanguage; }

    public String getDataCoverage() { return dataCoverage; }
    public void setDataCoverage(String dataCoverage) { this.dataCoverage = dataCoverage; }

    public String getModelId() { return modelId; }
    public void setModelId(String modelId) { this.modelId = modelId; }

    public String getPromptVersion() { return promptVersion; }
    public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }

    public int getPromptTokens() { return promptTokens; }
    public void setPromptTokens(int promptTokens) { this.promptTokens = promptTokens; }

    public int getCompletionTokens() { return completionTokens; }
    public void setCompletionTokens(int completionTokens) { this.completionTokens = completionTokens; }

    public int getTotalTokens() { return totalTokens; }
    public void setTotalTokens(int totalTokens) { this.totalTokens = totalTokens; }

    public Long getLatencyMs() { return latencyMs; }
    public void setLatencyMs(Long latencyMs) { this.latencyMs = latencyMs; }

    public Instant getCreatedAt() { return createdAt; }
}
