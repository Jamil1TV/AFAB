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

    @Modifying
    @Query(value = "INSERT INTO usage_counters (id, user_id, feature_key, period_start, used, updated_at) " +
                   "VALUES (:id, :userId, :featureKey, :periodStart, :amount, :now) " +
                   "ON CONFLICT (user_id, feature_key, period_start) " +
                   "DO UPDATE SET used = usage_counters.used + EXCLUDED.used, updated_at = EXCLUDED.updated_at",
           nativeQuery = true)
    void recordUsage(
            @Param("id") UUID id,
            @Param("userId") UUID userId,
            @Param("featureKey") String featureKey,
            @Param("periodStart") Instant periodStart,
            @Param("amount") int amount,
            @Param("now") Instant now);
}
