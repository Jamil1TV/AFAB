package com.afab.ai.domain;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface AiMessageRepository extends JpaRepository<AiMessage, UUID> {

    @Query("SELECT m FROM AiMessage m WHERE m.conversation.id = :conversationId AND m.business.id = :businessId ORDER BY m.createdAt ASC")
    List<AiMessage> findAllByConversationIdAndBusinessId(
            @Param("conversationId") UUID conversationId,
            @Param("businessId") UUID businessId
    );

    @Query("SELECT m FROM AiMessage m WHERE m.conversation.id = :conversationId AND m.business.id = :businessId ORDER BY m.createdAt DESC")
    List<AiMessage> findRecentByConversationIdAndBusinessId(
            @Param("conversationId") UUID conversationId,
            @Param("businessId") UUID businessId,
            Pageable pageable
    );
}
