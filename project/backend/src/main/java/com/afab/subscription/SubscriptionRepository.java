package com.afab.subscription;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {
    Optional<Subscription> findByUserId(UUID userId);

    @Query("SELECT s FROM Subscription s JOIN FETCH s.plan p LEFT JOIN FETCH p.entitlements WHERE s.user.id = :userId")
    Optional<Subscription> findWithPlanAndEntitlementsByUserId(@Param("userId") UUID userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM Subscription s LEFT JOIN FETCH s.plan WHERE s.user.id = :userId")
    Optional<Subscription> findForUpdateByUserId(@Param("userId") UUID userId);

    Optional<Subscription> findByStripeCustomerId(String stripeCustomerId);

    Optional<Subscription> findByStripeSubscriptionId(String stripeSubscriptionId);

    @Query("SELECT s FROM Subscription s JOIN FETCH s.user JOIN FETCH s.plan " +
           "WHERE UPPER(s.status) = 'PAST_DUE' AND s.gracePeriodEndsAt IS NOT NULL AND s.gracePeriodEndsAt <= :now")
    List<Subscription> findPastDueWithExpiredGracePeriod(@Param("now") Instant now);

    @Query("SELECT s FROM Subscription s JOIN FETCH s.user JOIN FETCH s.plan " +
           "WHERE UPPER(s.status) = 'TRIALING' AND s.trialEnd IS NOT NULL " +
           "AND s.trialEnd > :now AND s.trialEnd <= :threshold AND s.trialReminderSentAt IS NULL")
    List<Subscription> findTrialsApproachingExpiration(@Param("now") Instant now, @Param("threshold") Instant threshold);

    @Query("SELECT s FROM Subscription s JOIN FETCH s.user JOIN FETCH s.plan " +
           "WHERE UPPER(s.status) = 'PAST_DUE' AND s.gracePeriodEndsAt IS NOT NULL " +
           "AND s.gracePeriodEndsAt > :now AND s.gracePeriodEndsAt <= :threshold AND s.graceReminderSentAt IS NULL")
    List<Subscription> findGracePeriodsApproachingExpiration(@Param("now") Instant now, @Param("threshold") Instant threshold);
}
