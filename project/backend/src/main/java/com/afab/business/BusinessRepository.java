package com.afab.business;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BusinessRepository extends JpaRepository<Business, UUID> {
    List<Business> findAllByUserId(UUID userId);
    Optional<Business> findFirstByUserIdAndArchivedAtIsNull(UUID userId);
    boolean existsByUserId(UUID userId);
}
