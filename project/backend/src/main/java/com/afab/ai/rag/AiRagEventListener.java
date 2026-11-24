package com.afab.ai.rag;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Automatically indexes or removes individual records in pgvector + FTS after DB transaction commits.
 */
@Component
public class AiRagEventListener {

    private static final Logger log = LoggerFactory.getLogger(AiRagEventListener.class);

    private final AiRagIndexService ragIndexService;

    public AiRagEventListener(AiRagIndexService ragIndexService) {
        this.ragIndexService = ragIndexService;
    }

    @Async("aiIndexExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onEntityChanged(AiEntityChangedEvent event) {
        if (event == null || event.businessId() == null || event.sourceId() == null || event.sourceType() == null) {
            return;
        }
        try {
            if (event.deleted()) {
                ragIndexService.deleteSingleRecord(event.businessId(), event.sourceType(), event.sourceId());
            } else {
                ragIndexService.upsertSingleRecord(event.businessId(), event.sourceType(), event.sourceId());
            }
        } catch (Exception e) {
            log.debug("Async Auto-RAG sync skipped for {} {}: {}", event.sourceType(), event.sourceId(), e.getMessage());
        }
    }
}
