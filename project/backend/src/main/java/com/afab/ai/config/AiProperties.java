package com.afab.ai.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "afab.ai")
public class AiProperties {

    private boolean enabled = true;
    private String ollamaBaseUrl = "http://localhost:11434";
    private String chatModel = "gemma4:e4b";
    private String embedModel = "embeddinggemma-2:270m";
    private int embeddingDimension = 768;
    private int numCtx = 4096;
    private int maxOutputTokens = 1024;
    private int maxToolCallsPerTurn = 4;
    private int maxConcurrentRequests = 1;
    private int timeoutSeconds = 90;
    private boolean thinkingEnabled = false;
    private String promptVersion = "copilot-v1.0";

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public String getOllamaBaseUrl() { return ollamaBaseUrl; }
    public void setOllamaBaseUrl(String ollamaBaseUrl) { this.ollamaBaseUrl = ollamaBaseUrl; }

    public String getChatModel() { return chatModel; }
    public void setChatModel(String chatModel) { this.chatModel = chatModel; }

    public String getEmbedModel() { return embedModel; }
    public void setEmbedModel(String embedModel) { this.embedModel = embedModel; }

    public int getEmbeddingDimension() { return embeddingDimension; }
    public void setEmbeddingDimension(int embeddingDimension) { this.embeddingDimension = embeddingDimension; }

    public int getNumCtx() { return numCtx; }
    public void setNumCtx(int numCtx) { this.numCtx = numCtx; }

    public int getMaxOutputTokens() { return maxOutputTokens; }
    public void setMaxOutputTokens(int maxOutputTokens) { this.maxOutputTokens = maxOutputTokens; }

    public int getMaxToolCallsPerTurn() { return maxToolCallsPerTurn; }
    public void setMaxToolCallsPerTurn(int maxToolCallsPerTurn) { this.maxToolCallsPerTurn = maxToolCallsPerTurn; }

    public int getMaxConcurrentRequests() { return maxConcurrentRequests; }
    public void setMaxConcurrentRequests(int maxConcurrentRequests) { this.maxConcurrentRequests = maxConcurrentRequests; }

    public int getTimeoutSeconds() { return timeoutSeconds; }
    public void setTimeoutSeconds(int timeoutSeconds) { this.timeoutSeconds = timeoutSeconds; }

    public boolean isThinkingEnabled() { return thinkingEnabled; }
    public void setThinkingEnabled(boolean thinkingEnabled) { this.thinkingEnabled = thinkingEnabled; }

    public String getPromptVersion() { return promptVersion; }
    public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }
}
