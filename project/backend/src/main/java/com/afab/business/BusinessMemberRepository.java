package com.afab.business;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BusinessMemberRepository extends JpaRepository<BusinessMember, UUID> {

    Optional<BusinessMember> findByBusinessIdAndUserId(UUID businessId, UUID userId);

    @Query("SELECT bm FROM BusinessMember bm " +
           "JOIN FETCH bm.business b " +
           "WHERE bm.business.id = :businessId AND bm.user.id = :userId")
    Optional<BusinessMember> findWithBusinessByBusinessIdAndUserId(
            @Param("businessId") UUID businessId, 
            @Param("userId") UUID userId
    );

    @Query("SELECT bm FROM BusinessMember bm " +
           "JOIN FETCH bm.business b " +
           "WHERE bm.user.id = :userId AND bm.status = 'ACTIVE' AND b.archivedAt IS NULL " +
           "ORDER BY bm.createdAt ASC")
    List<BusinessMember> findAllActiveByUserIdWithBusiness(@Param("userId") UUID userId);

    boolean existsByBusinessIdAndUserIdAndStatus(UUID businessId, UUID userId, String status);

    long countByBusinessIdAndStatus(UUID businessId, String status);
}
