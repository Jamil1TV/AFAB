package com.afab.ai.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AiConversationRepository extends JpaRepository<AiConversation, UUID> {

    @Query("SELECT c FROM AiConversation c WHERE c.business.id = :businessId AND c.user.id = :userId AND c.archivedAt IS NULL ORDER BY c.updatedAt DESC")
    List<AiConversation> findActiveByBusinessIdAndUserId(
            @Param("businessId") UUID businessId,
            @Param("userId") UUID userId
    );

    @Query("SELECT c FROM AiConversation c JOIN FETCH c.business JOIN FETCH c.user WHERE c.id = :id AND c.archivedAt IS NULL")
    Optional<AiConversation> findActiveById(@Param("id") UUID id);
}
