package com.afab.ai.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AiStagedAttachmentRepository extends JpaRepository<AiStagedAttachment, UUID> {

    @Query("SELECT a FROM AiStagedAttachment a WHERE a.id = :id AND a.business.id = :businessId")
    Optional<AiStagedAttachment> findByIdAndBusinessId(@Param("id") UUID id, @Param("businessId") UUID businessId);

    @Query("SELECT a FROM AiStagedAttachment a WHERE a.business.id = :businessId AND a.id IN :ids")
    List<AiStagedAttachment> findAllByIdInAndBusinessId(@Param("businessId") UUID businessId, @Param("ids") Collection<UUID> ids);

    @Query("SELECT a FROM AiStagedAttachment a WHERE a.status = 'STAGED' AND a.expiresAt < :cutoff")
    List<AiStagedAttachment> findExpiredStaged(@Param("cutoff") Instant cutoff);
}
