package com.afab.subscription.stripe;

import com.afab.business.BusinessAllocationService;
import com.afab.notification.NotificationService;
import com.afab.subscription.*;
import com.afab.user.User;
import com.afab.user.UserRepository;
import com.stripe.StripeClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class SubscriptionLifecycleScheduler {

    private static final Logger log = LoggerFactory.getLogger(SubscriptionLifecycleScheduler.class);

    private final SubscriptionRepository subscriptionRepository;
    private final PlanRepository planRepository;
    private final UserRepository userRepository;
    private final BusinessAllocationService businessAllocationService;
    private final SubscriptionHistoryRepository subscriptionHistoryRepository;
    private final NotificationService notificationService;
    private final StripeBillingService stripeBillingService;
    private final StripeClientFactory stripeClientFactory;
    private final StripeProperties stripeProperties;

    public SubscriptionLifecycleScheduler(
            SubscriptionRepository subscriptionRepository,
            PlanRepository planRepository,
            UserRepository userRepository,
            BusinessAllocationService businessAllocationService,
            SubscriptionHistoryRepository subscriptionHistoryRepository,
            NotificationService notificationService,
            StripeBillingService stripeBillingService,
            StripeClientFactory stripeClientFactory,
            StripeProperties stripeProperties
    ) {
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository = planRepository;
        this.userRepository = userRepository;
        this.businessAllocationService = businessAllocationService;
        this.subscriptionHistoryRepository = subscriptionHistoryRepository;
        this.notificationService = notificationService;
        this.stripeBillingService = stripeBillingService;
        this.stripeClientFactory = stripeClientFactory;
        this.stripeProperties = stripeProperties;
    }

    /**
     * Runs every 15 minutes (configurable via afab.billing.scheduler-interval-ms)
     * to enforce expired 3-day payment failure grace periods and emit reminders.
     */
    @Scheduled(fixedDelayString = "${afab.billing.scheduler-interval-ms:900000}")
    public void runLifecycleMaintenance() {
        processTrialReminders();
        processGracePeriodReminders();
        processExpiredGracePeriods();
    }

    @Transactional
    public int processTrialReminders() {
        Instant now = Instant.now();
        Instant threshold = now.plus(48, ChronoUnit.HOURS);
        List<Subscription> approaching = subscriptionRepository.findTrialsApproachingExpiration(now, threshold);
        for (Subscription sub : approaching) {
            User user = sub.getUser();
            boolean cancelsAtEnd = Boolean.TRUE.equals(sub.getCancelAtPeriodEnd());
            notificationService.notifyUser(
                    user,
                    "TRIAL_EXPIRING",
                    "INFO",
                    cancelsAtEnd ? "Your Plus Trial Ends Soon (No Charge)" : "Your 7-Day Plus Trial Ends Soon",
                    cancelsAtEnd
                            ? "Your canceled Plus trial ends soon. You will not be charged and your account will transition to Free (1 editable business, remaining businesses preserved read-only)."
                            : "Your 7-day Plus trial ends within 48 hours. Your subscription will automatically continue unless you cancel beforehand.",
                    "/dashboard/settings/subscription",
                    true
            );
            sub.setTrialReminderSentAt(now);
            subscriptionRepository.save(sub);
        }
        return approaching.size();
    }

    @Transactional
    public int processGracePeriodReminders() {
        Instant now = Instant.now();
        Instant threshold = now.plus(24, ChronoUnit.HOURS);
        List<Subscription> approaching = subscriptionRepository.findGracePeriodsApproachingExpiration(now, threshold);
        for (Subscription sub : approaching) {
            User user = sub.getUser();
            notificationService.notifyUser(
                    user,
                    "GRACE_PERIOD_EXPIRING",
                    "WARNING",
                    "Urgent: 3-Day Payment Grace Period Ending Soon",
                    "Your payment failure grace period expires in under 24 hours. Update your payment method now to prevent your "
                            + sub.getPlan().getName() + " plan from downgrading to Free.",
                    "/dashboard/settings/subscription",
                    true
            );
            sub.setGraceReminderSentAt(now);
            subscriptionRepository.save(sub);
        }
        return approaching.size();
    }

    @Transactional
    public int processExpiredGracePeriods() {
        Instant now = Instant.now();
        List<Subscription> expired = subscriptionRepository.findPastDueWithExpiredGracePeriod(now);
        int processed = 0;

        for (Subscription sub : expired) {
            try {
                reconcileSingleExpiredGracePeriod(sub);
                processed++;
            } catch (Exception e) {
                log.error("Failed processing expired grace period for subscription {}: {}", sub.getId(), e.getMessage(), e);
            }
        }
        return processed;
    }

    private void reconcileSingleExpiredGracePeriod(Subscription localSub) {
        User user = localSub.getUser();
        String stripeSubId = localSub.getStripeSubscriptionId();

        if (stripeProperties != null && stripeProperties.isConfigured()
                && stripeSubId != null && !stripeSubId.isBlank()) {
            try {
                StripeClient client = stripeClientFactory.getClient();
                com.stripe.model.Subscription liveStripeSub = client.v1().subscriptions().retrieve(stripeSubId);
                String liveStatus = liveStripeSub.getStatus() != null ? liveStripeSub.getStatus().toLowerCase() : "";

                // If payment recovered on Stripe side, restore active state instead of downgrading!
                if ("active".equals(liveStatus) || "trialing".equals(liveStatus)) {
                    localSub.setFirstPaymentFailureAt(null);
                    localSub.setGracePeriodEndsAt(null);
                    localSub.setLastPaymentFailureReason(null);
                    localSub.setGraceReminderSentAt(null);
                    stripeBillingService.syncFromStripeSubscription(liveStripeSub, user, null, null);
                    return;
                }

                // If still unpaid / past_due after 3 days, cancel unpaid Stripe subscription before downgrading to Free
                if ("past_due".equals(liveStatus) || "unpaid".equals(liveStatus)) {
                    try {
                        if (localSub.getStripeScheduleId() != null && !localSub.getStripeScheduleId().isBlank()) {
                            client.v1().subscriptionSchedules().release(localSub.getStripeScheduleId());
                        }
                        client.v1().subscriptions().cancel(stripeSubId);
                    } catch (Exception cancelEx) {
                        log.warn("Best-effort Stripe cancel after grace expiration failed for {}: {}", stripeSubId, cancelEx.getMessage());
                    }
                }
            } catch (Exception e) {
                log.warn("Could not check live Stripe subscription {} during grace reconciliation: {}", stripeSubId, e.getMessage());
            }
        }

        Plan freePlan = planRepository.findBySlug("free")
                .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));
        String previousSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug() : "free";

        localSub.setPlan(freePlan);
        localSub.setStatus("ACTIVE");
        localSub.setStripeSubscriptionId(null);
        localSub.setStripePriceId(null);
        localSub.setStripeScheduleId(null);
        localSub.setBillingInterval(null);
        localSub.setCancelAtPeriodEnd(false);
        localSub.setCanceledAt(null);
        localSub.setEffectiveCancelAt(null);
        localSub.setPeriodStart(Instant.now());
        localSub.setPeriodEnd(null);
        localSub.setFirstPaymentFailureAt(null);
        localSub.setGracePeriodEndsAt(null);
        localSub.setLastPaymentFailureReason(null);
        localSub.setGraceReminderSentAt(null);

        boolean attentionRequired = businessAllocationService.applyDowngradeAllocation(localSub, freePlan);
        subscriptionRepository.save(localSub);

        user.setPlanTier("FREE");
        userRepository.save(user);

        subscriptionHistoryRepository.save(new SubscriptionHistory(
                user,
                "GRACE_PERIOD_EXPIRED",
                previousSlug,
                "free",
                "PAST_DUE",
                "ACTIVE",
                null,
                Instant.now(),
                "3-day payment failure grace period expired without successful payment; downgraded to Free."
        ));

        notificationService.notifyUser(
                user,
                "SUBSCRIPTION_DOWNGRADED",
                "WARNING",
                "Subscription Downgraded to Free After Grace Period",
                "Your 3-day payment grace period has ended without a successful payment. Your account has been moved to Free with 1 editable business, and all additional businesses remain accessible in read-only mode.",
                "/dashboard/settings/subscription",
                true
        );

        if (attentionRequired) {
            notificationService.notifyUser(
                    user,
                    "ALLOCATION_ATTENTION",
                    "WARNING",
                    "Review Your Active Business Allocation",
                    "Your primary business remained editable after downgrading to Free. You can change which business is editable anytime in Subscription Settings.",
                    "/dashboard/settings/subscription",
                    false
            );
        }
    }
}
