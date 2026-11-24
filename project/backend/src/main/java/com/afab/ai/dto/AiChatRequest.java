package com.afab.ai.dto;

import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public class AiChatRequest {

    @Size(max = 4000, message = "Message cannot exceed 4000 characters")
    private String message = "";

    private UUID conversationId;

    @Size(max = 16)
    private String locale;

    @Size(max = 16)
    private String reasoningMode = "fast";

    private List<UUID> attachmentIds;

    private Map<String, String> screenContext;

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public UUID getConversationId() { return conversationId; }
    public void setConversationId(UUID conversationId) { this.conversationId = conversationId; }

    public String getLocale() { return locale; }
    public void setLocale(String locale) { this.locale = locale; }

    public String getReasoningMode() { return reasoningMode; }
    public void setReasoningMode(String reasoningMode) { this.reasoningMode = reasoningMode; }

    public List<UUID> getAttachmentIds() { return attachmentIds; }
    public void setAttachmentIds(List<UUID> attachmentIds) { this.attachmentIds = attachmentIds; }

    public Map<String, String> getScreenContext() { return screenContext; }
    public void setScreenContext(Map<String, String> screenContext) { this.screenContext = screenContext; }
}
