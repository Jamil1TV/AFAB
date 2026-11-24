package com.afab.ai.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BusinessMemoryRepository extends JpaRepository<BusinessMemory, UUID> {

    @Query("SELECT m FROM BusinessMemory m WHERE m.business.id = :businessId AND m.status <> 'DELETED' ORDER BY m.updatedAt DESC")
    List<BusinessMemory> findAllVisibleByBusinessId(@Param("businessId") UUID businessId);

    @Query("SELECT m FROM BusinessMemory m WHERE m.business.id = :businessId AND m.status = :status ORDER BY m.updatedAt DESC")
    List<BusinessMemory> findByBusinessIdAndStatus(
            @Param("businessId") UUID businessId,
            @Param("status") String status
    );

    @Query("SELECT m FROM BusinessMemory m JOIN FETCH m.business WHERE m.id = :id AND m.status <> 'DELETED'")
    Optional<BusinessMemory> findActiveById(@Param("id") UUID id);

    @Query("SELECT COUNT(m) FROM BusinessMemory m WHERE m.business.id = :businessId AND m.status = 'APPROVED'")
    long countApprovedByBusinessId(@Param("businessId") UUID businessId);
}
