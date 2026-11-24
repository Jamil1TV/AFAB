package com.afab.subscription;

import com.afab.business.Business;
import com.afab.business.BusinessAllocationService;
import com.afab.business.BusinessRepository;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.subscription.stripe.StripeProperties;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
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
    private final StripeProperties stripeProperties;
    private final BusinessRepository businessRepository;
    private final BusinessAllocationService businessAllocationService;

    public EntitlementService(
            PlanRepository planRepository,
            SubscriptionRepository subscriptionRepository,
            UsageCounterRepository usageCounterRepository,
            UserRepository userRepository
    ) {
        this(planRepository, subscriptionRepository, usageCounterRepository, userRepository,
                new StripeProperties(), null, null);
    }

    public EntitlementService(
            PlanRepository planRepository,
            SubscriptionRepository subscriptionRepository,
            UsageCounterRepository usageCounterRepository,
            UserRepository userRepository,
            StripeProperties stripeProperties
    ) {
        this(planRepository, subscriptionRepository, usageCounterRepository, userRepository,
                stripeProperties, null, null);
    }

    @Autowired
    public EntitlementService(
            PlanRepository planRepository,
            SubscriptionRepository subscriptionRepository,
            UsageCounterRepository usageCounterRepository,
            UserRepository userRepository,
            StripeProperties stripeProperties,
            BusinessRepository businessRepository,
            BusinessAllocationService businessAllocationService
    ) {
        this.planRepository = planRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.usageCounterRepository = usageCounterRepository;
        this.userRepository = userRepository;
        this.stripeProperties = stripeProperties != null ? stripeProperties : new StripeProperties();
        this.businessRepository = businessRepository;
        this.businessAllocationService = businessAllocationService;
    }

    /**
     * Retrieves or auto-creates the active subscription for the given user,
     * reconciling expired non-Stripe trials if necessary.
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

        // Reconcile local trial expiration only when not managed by Stripe webhooks
        if ((sub.getStripeSubscriptionId() == null || sub.getStripeSubscriptionId().isBlank())
                && "TRIALING".equalsIgnoreCase(sub.getStatus())
                && sub.getTrialEnd() != null
                && sub.getTrialEnd().isBefore(Instant.now())) {
            Plan freePlan = planRepository.findBySlug("free")
                    .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));
            sub.setPlan(freePlan);
            sub.setStatus("ACTIVE");
            sub.setTrialUsed(true);
            sub.setCancelAtPeriodEnd(false);
            sub.setCanceledAt(null);
            sub.setEffectiveCancelAt(null);
            if (businessAllocationService != null) {
                businessAllocationService.applyDowngradeAllocation(sub, freePlan);
            }
            sub = subscriptionRepository.save(sub);

            user.setPlanTier("FREE");
            userRepository.save(user);
        }

        return sub;
    }

    /**
     * Returns full snapshot of user's active plan, lifecycle state, business allocation counts, limits, and usage.
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
        Instant now = Instant.now();

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
        dto.setTrialStart(sub.getTrialStart());
        dto.setTrialEnd(sub.getTrialEnd());

        boolean isTrial = sub.isTrialActive();
        dto.setTrial(isTrial);
        if (isTrial && sub.getTrialEnd() != null) {
            long remaining = Duration.between(now, sub.getTrialEnd()).toDays();
            dto.setTrialDaysRemaining(Math.max(0, remaining));
        }
        dto.setBillingInterval(sub.getBillingInterval());
        dto.setCancelAtPeriodEnd(Boolean.TRUE.equals(sub.getCancelAtPeriodEnd()));
        dto.setCanceledAt(sub.getCanceledAt());
        dto.setEffectiveCancelAt(sub.getEffectiveCancelAt());

        if (sub.getPendingPlan() != null) {
            dto.setPendingPlanSlug(sub.getPendingPlan().getSlug());
            dto.setPendingPlanName(sub.getPendingPlan().getName());
            dto.setPendingBillingInterval(sub.getPendingBillingInterval());
            dto.setPendingChangeEffectiveAt(
                    sub.getPendingChangeEffectiveAt() != null ? sub.getPendingChangeEffectiveAt() : sub.getEffectiveCancelAt()
            );
        } else if (Boolean.TRUE.equals(sub.getCancelAtPeriodEnd())) {
            dto.setPendingPlanSlug("free");
            dto.setPendingPlanName("Free");
            dto.setPendingChangeEffectiveAt(
                    sub.getEffectiveCancelAt() != null ? sub.getEffectiveCancelAt() : sub.getPeriodEnd()
            );
        }

        dto.setFirstPaymentFailureAt(sub.getFirstPaymentFailureAt());
        dto.setGracePeriodEndsAt(sub.getGracePeriodEndsAt());
        if ("PAST_DUE".equalsIgnoreCase(sub.getStatus()) && sub.getGracePeriodEndsAt() != null) {
            long hoursRemaining = Duration.between(now, sub.getGracePeriodEndsAt()).toHours();
            dto.setGracePeriodHoursRemaining(Math.max(0L, hoursRemaining));
        }
        dto.setLastPaymentFailureReason(sub.getLastPaymentFailureReason());

        boolean trialUsed = Boolean.TRUE.equals(sub.getTrialUsed()) || sub.getTrialEnd() != null;
        boolean hasActiveStripe = sub.getStripeSubscriptionId() != null
                && !sub.getStripeSubscriptionId().isBlank()
                && ("ACTIVE".equalsIgnoreCase(sub.getStatus())
                || "TRIALING".equalsIgnoreCase(sub.getStatus())
                || "PAST_DUE".equalsIgnoreCase(sub.getStatus()));

        dto.setTrialUsed(trialUsed);
        dto.setTrialEligible(!trialUsed && !hasActiveStripe);
        dto.setAllocationAttentionRequired(Boolean.TRUE.equals(sub.getAllocationAttentionRequired()));
        dto.setHasStripeCustomer(sub.getStripeCustomerId() != null && !sub.getStripeCustomerId().isBlank());
        dto.setHasActiveStripeSubscription(hasActiveStripe);
        dto.setStripeConfigured(stripeProperties != null && stripeProperties.isConfigured());

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

        int editableLimit = businessAllocationService != null
                ? businessAllocationService.resolveEditableLimit(sub)
                : resolveLimitFallback(entitlementMap, plan.getSlug());
        dto.setEditableBusinessLimit(editableLimit);

        if (businessRepository != null) {
            List<Business> owned = businessRepository.findAllOwnedActiveByUserId(user.getId());
            int editableCount = (int) owned.stream().filter(Business::isEditable).count();
            dto.setEditableBusinessCount(editableCount);
            dto.setTotalBusinessCount(owned.size());
        } else {
            dto.setEditableBusinessCount(0);
            dto.setTotalBusinessCount(0);
        }

        // Fetch usage counters for the current month period
        Instant periodStart = getCurrentPeriodStart();
        Map<String, Integer> usageMap = new HashMap<>();
        for (String quotaKey : List.of(
                "ai.chat.queries_per_month",
                "ai.chat.tokens_per_month",
                "invoices.per_month",
                "export.per_month"
        )) {
            usageCounterRepository.findByUserIdAndFeatureKeyAndPeriodStart(user.getId(), quotaKey, periodStart)
                    .ifPresentOrElse(
                            c -> usageMap.put(quotaKey, c.getUsed()),
                            () -> usageMap.put(quotaKey, 0)
                    );
        }
        dto.setUsage(usageMap);

        return dto;
    }

    public record QuotaStatus(String planSlug, String planName, int limit, int used, int remaining) {}

    /**
     * Returns current plan limit, used count, and remaining count for any monthly quota feature.
     */
    @Transactional(readOnly = true)
    public QuotaStatus getQuotaStatus(String userEmail, String featureKey) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = subscriptionRepository.findWithPlanAndEntitlementsByUserId(user.getId())
                .orElseGet(() -> {
                    Plan freePlan = planRepository.findBySlug("free").orElseThrow();
                    return new Subscription(user, freePlan, "ACTIVE", Instant.now());
                });
        Plan plan = resolveEffectivePlanForEntitlements(sub);
        PlanEntitlement entitlement = findEntitlement(plan, featureKey);

        int limit = -1;
        if (entitlement != null) {
            try {
                limit = Integer.parseInt(entitlement.getValue());
            } catch (NumberFormatException ignored) {
                limit = -1;
            }
        }

        Instant periodStart = getCurrentPeriodStart();
        int used = usageCounterRepository.findByUserIdAndFeatureKeyAndPeriodStart(user.getId(), featureKey, periodStart)
                .map(UsageCounter::getUsed)
                .orElse(0);

        int remaining = limit < 0 ? -1 : Math.max(0, limit - used);
        return new QuotaStatus(plan.getSlug(), plan.getName(), limit, used, remaining);
    }

    /**
     * Records post-execution usage (such as actual LLM prompt + completion tokens) without failing
     * when a turn slightly overshoots the nominal limit.
     */
    @Transactional
    public void recordUsage(String userEmail, String featureKey, int amount) {
        if (amount <= 0) {
            return;
        }
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        usageCounterRepository.recordUsage(
                UUID.randomUUID(),
                user.getId(),
                featureKey,
                getCurrentPeriodStart(),
                amount,
                Instant.now()
        );
    }

    /**
     * Validates access to a feature. Throws PlanLimitReachedException if limit is reached.
     */
    @Transactional
    public void check(String userEmail, String featureKey) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = getOrReconcileSubscription(user);
        Plan plan = resolveEffectivePlanForEntitlements(sub);

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
        Plan plan = resolveEffectivePlanForEntitlements(sub);

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
     * Activates a strictly one-time 7-day free trial EXCLUSIVELY on the Plus plan.
     */
    @Transactional
    public SubscriptionSnapshotDTO activateTrial(String userEmail, String planSlug) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = getOrReconcileSubscription(user);

        if (Boolean.TRUE.equals(sub.getTrialUsed()) || sub.getTrialEnd() != null) {
            throw new IllegalStateException("7-day trial has already been used for this account.");
        }

        String targetSlug = planSlug != null ? planSlug.toLowerCase().trim() : "";
        if (!"plus".equals(targetSlug)) {
            throw new IllegalArgumentException("The 7-day free trial is available exclusively for the Plus plan.");
        }

        Plan targetPlan = planRepository.findBySlug(targetSlug)
                .orElseThrow(() -> new ResourceNotFoundException("Plan not found: " + targetSlug));

        Instant now = Instant.now();
        sub.setPlan(targetPlan);
        sub.setStatus("TRIALING");
        sub.setTrialStart(now);
        sub.setTrialEnd(now.plus(7, ChronoUnit.DAYS));
        sub.setTrialUsed(true);
        sub.setPeriodStart(now);
        sub.setPeriodEnd(sub.getTrialEnd());
        subscriptionRepository.save(sub);

        user.setPlanTier(targetSlug.toUpperCase());
        userRepository.save(user);

        return getEntitlementsSnapshot(userEmail);
    }

    /**
     * Developer/testing switch plan endpoint (disabled when Stripe is configured).
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

    private Plan resolveEffectivePlanForEntitlements(Subscription sub) {
        if ("CANCELED".equalsIgnoreCase(sub.getStatus()) || "EXPIRED".equalsIgnoreCase(sub.getStatus())) {
            return planRepository.findBySlug("free").orElse(sub.getPlan());
        }
        return sub.getPlan();
    }

    private int resolveLimitFallback(Map<String, Object> entitlementMap, String planSlug) {
        Object val = entitlementMap.get("business.max");
        if (val instanceof Number n) {
            return n.intValue();
        }
        if (planSlug != null) {
            String lower = planSlug.toLowerCase();
            if (lower.contains("pro")) return 5;
            if (lower.contains("plus")) return 3;
        }
        return 1;
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
