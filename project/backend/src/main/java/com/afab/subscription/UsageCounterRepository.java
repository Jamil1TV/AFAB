package com.afab.subscription;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

public interface UsageCounterRepository extends JpaRepository<UsageCounter, UUID> {

    Optional<UsageCounter> findByUserIdAndFeatureKeyAndPeriodStart(
            UUID userId, String featureKey, Instant periodStart);

    @Modifying
    @Query("UPDATE UsageCounter u SET u.used = u.used + :amount, u.updatedAt = :now " +
           "WHERE u.user.id = :userId AND u.featureKey = :featureKey AND u.periodStart = :periodStart " +
           "AND (:limit < 0 OR u.used + :amount <= :limit)")
    int atomicIncrement(
            @Param("userId") UUID userId,
            @Param("featureKey") String featureKey,
            @Param("periodStart") Instant periodStart,
            @Param("amount") int amount,
            @Param("limit") int limit,
            @Param("now") Instant now);
}
