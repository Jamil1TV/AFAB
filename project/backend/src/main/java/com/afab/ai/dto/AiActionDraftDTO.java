package com.afab.ai.dto;

import java.util.Map;
import java.util.UUID;

public record AiActionDraftDTO(
        String draftId,
        String actionType, // CREATE_TRANSACTION | CREATE_INVOICE | CREATE_BUDGET | PAYMENT_REMINDER | SAVE_MEMORY
        String status,     // PENDING | APPROVED | DISMISSED
        String title,
        String summary,
        Map<String, Object> payload,
        UUID stagedAttachmentId,
        UUID createdEntityId,
        String createdEntityHref
) {
    public AiActionDraftDTO withApproved(UUID entityId, String href) {
        return new AiActionDraftDTO(
                draftId, actionType, "APPROVED", title, summary, payload,
                stagedAttachmentId, entityId, href
        );
    }

    public AiActionDraftDTO withDismissed() {
        return new AiActionDraftDTO(
                draftId, actionType, "DISMISSED", title, summary, payload,
                stagedAttachmentId, createdEntityId, createdEntityHref
        );
    }
}
