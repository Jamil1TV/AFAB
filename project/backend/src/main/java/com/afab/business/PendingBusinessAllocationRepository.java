package com.afab.business;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.UUID;

public interface PendingBusinessAllocationRepository extends JpaRepository<PendingBusinessAllocation, UUID> {

    @Query("SELECT p FROM PendingBusinessAllocation p JOIN FETCH p.business b WHERE p.user.id = :userId AND b.archivedAt IS NULL AND b.deletedAt IS NULL")
    List<PendingBusinessAllocation> findAllWithBusinessByUserId(@Param("userId") UUID userId);

    @Modifying
    @Query("DELETE FROM PendingBusinessAllocation p WHERE p.user.id = :userId")
    void deleteAllByUserId(@Param("userId") UUID userId);
}
