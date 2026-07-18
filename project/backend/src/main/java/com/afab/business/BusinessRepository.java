package com.afab.business;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface BusinessRepository extends JpaRepository<Business, UUID> {
    Optional<Business> findByUserId(UUID userId);
    boolean existsByUserId(UUID userId);
}
