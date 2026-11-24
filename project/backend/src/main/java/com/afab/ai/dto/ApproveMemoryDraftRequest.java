package com.afab.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public class ApproveMemoryDraftRequest {

    @NotNull
    private UUID messageId;

    @NotBlank
    private String draftId;

    @NotBlank
    private String memoryType;

    @NotBlank
    @Size(max = 160)
    private String title;

    @NotBlank
    @Size(max = 2000)
    private String content;

    public UUID getMessageId() { return messageId; }
    public void setMessageId(UUID messageId) { this.messageId = messageId; }

    public String getDraftId() { return draftId; }
    public void setDraftId(String draftId) { this.draftId = draftId; }

    public String getMemoryType() { return memoryType; }
    public void setMemoryType(String memoryType) { this.memoryType = memoryType; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
