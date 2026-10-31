package com.afab.subscription;

import com.afab.common.exception.ResourceNotFoundException;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

@Service
public class EntitlementService {

    private final PlanRepository planRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final UsageCounterRepository usageCounterRepository;
    private final UserRepository userRepository;

    public EntitlementService(
            PlanRepository planRepository,
            SubscriptionRepository subscriptionRepository,
            UsageCounterRepository usageCounterRepository,
            UserRepository userRepository
    ) {
        this.planRepository = planRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.usageCounterRepository = usageCounterRepository;
        this.userRepository = userRepository;
    }

    /**
     * Retrieves or auto-creates the active subscription for the given user,
     * reconciling expired trials if necessary.
     */
    @Transactional
    public Subscription getOrReconcileSubscription(User user) {
        Subscription sub = subscriptionRepository.findWithPlanAndEntitlementsByUserId(user.getId())
                .orElseGet(() -> {
                    Plan freePlan = planRepository.findBySlug("free")
                            .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));
                    Subscription newSub = new Subscription(user, freePlan, "ACTIVE", Instant.now());
                    return subscriptionRepository.save(newSub);
                });

        // Reconcile trial expiration
        if ("TRIALING".equalsIgnoreCase(sub.getStatus()) && sub.getTrialEnd() != null && sub.getTrialEnd().isBefore(Instant.now())) {
            Plan freePlan = planRepository.findBySlug("free")
                    .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));
            sub.setPlan(freePlan);
            sub.setStatus("ACTIVE");
            sub = subscriptionRepository.save(sub);

            user.setPlanTier("FREE");
            userRepository.save(user);
        }

        return sub;
    }

    /**
     * Returns full snapshot of user's active plan, limits, and current usage.
     */
    @Transactional(readOnly = true)
    public SubscriptionSnapshotDTO getEntitlementsSnapshot(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));

        Subscription sub = subscriptionRepository.findWithPlanAndEntitlementsByUserId(user.getId())
                .orElseGet(() -> {
                    Plan freePlan = planRepository.findBySlug("free").orElseThrow();
                    return new Subscription(user, freePlan, "ACTIVE", Instant.now());
                });

        Plan plan = sub.getPlan();
        SubscriptionSnapshotDTO dto = new SubscriptionSnapshotDTO();
        dto.setPlanId(plan.getId());
        dto.setPlanName(plan.getName());
        dto.setPlanSlug(plan.getSlug());
        dto.setPriceMonthly(plan.getPriceMonthly());
        dto.setPriceYearly(plan.getPriceYearly());
        dto.setCurrency(plan.getCurrency());
        dto.setStatus(sub.getStatus());
        dto.setPeriodStart(sub.getPeriodStart());
        dto.setPeriodEnd(sub.getPeriodEnd());
        dto.setTrialEnd(sub.getTrialEnd());

        boolean isTrial = sub.isTrialActive();
        dto.setTrial(isTrial);
        if (isTrial && sub.getTrialEnd() != null) {
            long remaining = Duration.between(Instant.now(), sub.getTrialEnd()).toDays();
            dto.setTrialDaysRemaining(Math.max(0, remaining));
        }

        Map<String, Object> entitlementMap = new HashMap<>();
        for (PlanEntitlement ent : plan.getEntitlements()) {
            if ("BOOLEAN".equalsIgnoreCase(ent.getType())) {
                entitlementMap.put(ent.getFeatureKey(), Boolean.parseBoolean(ent.getValue()));
            } else if ("LIMIT".equalsIgnoreCase(ent.getType()) || "QUOTA".equalsIgnoreCase(ent.getType())) {
                try {
                    entitlementMap.put(ent.getFeatureKey(), Integer.parseInt(ent.getValue()));
                } catch (NumberFormatException e) {
                    entitlementMap.put(ent.getFeatureKey(), ent.getValue());
                }
            } else {
                entitlementMap.put(ent.getFeatureKey(), ent.getValue());
            }
        }
        dto.setEntitlements(entitlementMap);

        // Fetch usage counters for the current month period
        Instant periodStart = getCurrentPeriodStart();
        Map<String, Integer> usageMap = new HashMap<>();
        for (String quotaKey : List.of("ai.chat.queries_per_month", "invoices.per_month", "export.per_month")) {
            usageCounterRepository.findByUserIdAndFeatureKeyAndPeriodStart(user.getId(), quotaKey, periodStart)
                    .ifPresentOrElse(
                            c -> usageMap.put(quotaKey, c.getUsed()),
                            () -> usageMap.put(quotaKey, 0)
                    );
        }
        dto.setUsage(usageMap);

        return dto;
    }

    /**
     * Validates access to a feature. Throws PlanLimitReachedException if limit is reached.
     */
    @Transactional
    public void check(String userEmail, String featureKey) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = getOrReconcileSubscription(user);
        Plan plan = sub.getPlan();

        PlanEntitlement entitlement = findEntitlement(plan, featureKey);
        if (entitlement == null) {
            return; // No explicit constraint
        }

        if ("BOOLEAN".equalsIgnoreCase(entitlement.getType())) {
            boolean allowed = Boolean.parseBoolean(entitlement.getValue());
            if (!allowed) {
                throw new PlanLimitReachedException(featureKey, 0, 0, getRecommendedUpgrade(plan.getSlug()));
            }
            return;
        }

        int limit = Integer.parseInt(entitlement.getValue());
        if (limit < 0) {
            return; // -1 represents unlimited
        }

        Instant periodStart = getCurrentPeriodStart();
        int used = usageCounterRepository.findByUserIdAndFeatureKeyAndPeriodStart(user.getId(), featureKey, periodStart)
                .map(UsageCounter::getUsed)
                .orElse(0);

        if (used >= limit) {
            throw new PlanLimitReachedException(featureKey, limit, used, getRecommendedUpgrade(plan.getSlug()));
        }
    }

    /**
     * Atomically consumes quota. Throws PlanLimitReachedException if quota is exhausted.
     */
    @Transactional
    public void consume(String userEmail, String featureKey, int amount) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = getOrReconcileSubscription(user);
        Plan plan = sub.getPlan();

        PlanEntitlement entitlement = findEntitlement(plan, featureKey);
        if (entitlement == null) {
            return; // No limit
        }

        int limit = Integer.parseInt(entitlement.getValue());
        if (limit < 0) {
            return; // Unlimited
        }

        Instant periodStart = getCurrentPeriodStart();
        int updated = usageCounterRepository.atomicIncrement(
                user.getId(), featureKey, periodStart, amount, limit, Instant.now());

        if (updated == 0) {
            // Either counter doesn't exist yet or limit exceeded
            Optional<UsageCounter> counterOpt = usageCounterRepository
                    .findByUserIdAndFeatureKeyAndPeriodStart(user.getId(), featureKey, periodStart);

            if (counterOpt.isEmpty()) {
                if (amount <= limit) {
                    UsageCounter counter = new UsageCounter(user, featureKey, periodStart, amount);
                    usageCounterRepository.save(counter);
                    return;
                }
            }

            int currentUsed = counterOpt.map(UsageCounter::getUsed).orElse(0);
            throw new PlanLimitReachedException(featureKey, limit, currentUsed, getRecommendedUpgrade(plan.getSlug()));
        }
    }

    /**
     * Activates a 7-day free trial on Plus or Pro plans.
     */
    @Transactional
    public SubscriptionSnapshotDTO activateTrial(String userEmail, String planSlug) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = getOrReconcileSubscription(user);

        if (sub.getTrialEnd() != null) {
            throw new IllegalStateException("7-day trial has already been used for this account.");
        }

        String targetSlug = planSlug.toLowerCase().trim();
        if (!"plus".equals(targetSlug) && !"pro".equals(targetSlug)) {
            throw new IllegalArgumentException("Trials are available for 'plus' and 'pro' plans only.");
        }

        Plan targetPlan = planRepository.findBySlug(targetSlug)
                .orElseThrow(() -> new ResourceNotFoundException("Plan not found: " + targetSlug));

        sub.setPlan(targetPlan);
        sub.setStatus("TRIALING");
        sub.setTrialEnd(Instant.now().plus(7, ChronoUnit.DAYS));
        sub.setPeriodEnd(sub.getTrialEnd());
        subscriptionRepository.save(sub);

        user.setPlanTier(targetSlug.toUpperCase());
        userRepository.save(user);

        return getEntitlementsSnapshot(userEmail);
    }

    /**
     * Developer/testing switch plan endpoint.
     */
    @Transactional
    public SubscriptionSnapshotDTO switchPlan(String userEmail, String planSlug) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = getOrReconcileSubscription(user);

        String targetSlug = planSlug.toLowerCase().trim();
        Plan targetPlan = planRepository.findBySlug(targetSlug)
                .orElseThrow(() -> new ResourceNotFoundException("Plan not found: " + targetSlug));

        sub.setPlan(targetPlan);
        sub.setStatus("ACTIVE");
        sub.setPeriodStart(Instant.now());
        subscriptionRepository.save(sub);

        user.setPlanTier(targetSlug.toUpperCase());
        userRepository.save(user);

        return getEntitlementsSnapshot(userEmail);
    }

    private PlanEntitlement findEntitlement(Plan plan, String featureKey) {
        return plan.getEntitlements().stream()
                .filter(e -> featureKey.equalsIgnoreCase(e.getFeatureKey()))
                .findFirst()
                .orElse(null);
    }

    private String getRecommendedUpgrade(String currentSlug) {
        if ("free".equalsIgnoreCase(currentSlug)) return "plus";
        return "pro";
    }

    private Instant getCurrentPeriodStart() {
        return ZonedDateTime.now(ZoneOffset.UTC)
                .with(TemporalAdjusters.firstDayOfMonth())
                .truncatedTo(ChronoUnit.DAYS)
                .toInstant();
    }
}
