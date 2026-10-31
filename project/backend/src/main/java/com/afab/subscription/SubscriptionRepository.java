package com.afab.subscription;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
import java.util.UUID;

public interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {
    Optional<Subscription> findByUserId(UUID userId);

    @Query("SELECT s FROM Subscription s JOIN FETCH s.plan p LEFT JOIN FETCH p.entitlements WHERE s.user.id = :userId")
    Optional<Subscription> findWithPlanAndEntitlementsByUserId(@Param("userId") UUID userId);
}
