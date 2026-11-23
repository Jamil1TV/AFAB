package com.afab.business;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BusinessRepository extends JpaRepository<Business, UUID> {
    List<Business> findAllByUserId(UUID userId);
    Optional<Business> findFirstByUserIdAndArchivedAtIsNull(UUID userId);
    boolean existsByUserId(UUID userId);

    @Query("SELECT b FROM Business b WHERE b.user.id = :userId AND b.archivedAt IS NULL AND b.deletedAt IS NULL ORDER BY b.primary DESC, b.createdAt ASC, b.id ASC")
    List<Business> findAllOwnedActiveByUserId(@Param("userId") UUID userId);
}
