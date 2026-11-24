package com.afab.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public class AiChatRequest {

    @NotBlank(message = "Message is required")
    @Size(max = 4000, message = "Message cannot exceed 4000 characters")
    private String message;

    private UUID conversationId;

    @Size(max = 16)
    private String locale;

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public UUID getConversationId() { return conversationId; }
    public void setConversationId(UUID conversationId) { this.conversationId = conversationId; }

    public String getLocale() { return locale; }
    public void setLocale(String locale) { this.locale = locale; }
}
