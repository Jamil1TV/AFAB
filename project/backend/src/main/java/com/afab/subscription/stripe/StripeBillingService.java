package com.afab.subscription.stripe;

import com.afab.business.Business;
import com.afab.business.BusinessAllocationService;
import com.afab.business.BusinessRepository;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.notification.NotificationService;
import com.afab.subscription.*;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.subscription.stripe.dto.*;
import com.afab.user.User;
import com.afab.user.UserRepository;
import com.stripe.StripeClient;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Customer;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.Invoice;
import com.stripe.model.StripeObject;
import com.stripe.model.SubscriptionItem;
import com.stripe.model.SubscriptionSchedule;
import com.stripe.net.Webhook;
import com.stripe.param.CustomerCreateParams;
import com.stripe.param.SubscriptionScheduleCreateParams;
import com.stripe.param.SubscriptionScheduleUpdateParams;
import com.stripe.param.SubscriptionUpdateParams;
import com.stripe.param.checkout.SessionCreateParams;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class StripeBillingService {

    private static final Logger log = LoggerFactory.getLogger(StripeBillingService.class);
    private static final Set<String> ACTIVE_STRIPE_STATUSES = Set.of("ACTIVE", "TRIALING", "PAST_DUE");
    private static final DateTimeFormatter FRIENDLY_DATE =
            DateTimeFormatter.ofPattern("MMM dd, yyyy").withZone(ZoneOffset.UTC);

    private final StripeClientFactory stripeClientFactory;
    private final StripeProperties stripeProperties;
    private final UserRepository userRepository;
    private final PlanRepository planRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final StripeWebhookEventRepository webhookEventRepository;
    private final EntitlementService entitlementService;
    private final BusinessRepository businessRepository;
    private final BusinessAllocationService businessAllocationService;
    private final SubscriptionHistoryRepository subscriptionHistoryRepository;
    private final PaymentHistoryRepository paymentHistoryRepository;
    private final NotificationService notificationService;
    private final String frontendUrl;

    public StripeBillingService(
            StripeClientFactory stripeClientFactory,
            StripeProperties stripeProperties,
            UserRepository userRepository,
            PlanRepository planRepository,
            SubscriptionRepository subscriptionRepository,
            StripeWebhookEventRepository webhookEventRepository,
            EntitlementService entitlementService,
            String frontendUrl
    ) {
        this(stripeClientFactory, stripeProperties, userRepository, planRepository,
                subscriptionRepository, webhookEventRepository, entitlementService,
                null, null, null, null, null, frontendUrl);
    }

    @Autowired
    public StripeBillingService(
            StripeClientFactory stripeClientFactory,
            StripeProperties stripeProperties,
            UserRepository userRepository,
            PlanRepository planRepository,
            SubscriptionRepository subscriptionRepository,
            StripeWebhookEventRepository webhookEventRepository,
            EntitlementService entitlementService,
            BusinessRepository businessRepository,
            BusinessAllocationService businessAllocationService,
            SubscriptionHistoryRepository subscriptionHistoryRepository,
            PaymentHistoryRepository paymentHistoryRepository,
            NotificationService notificationService,
            @Value("${afab.frontend-url:http://localhost:3000}") String frontendUrl
    ) {
        this.stripeClientFactory = stripeClientFactory;
        this.stripeProperties = stripeProperties;
        this.userRepository = userRepository;
        this.planRepository = planRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.webhookEventRepository = webhookEventRepository;
        this.entitlementService = entitlementService;
        this.businessRepository = businessRepository;
        this.businessAllocationService = businessAllocationService;
        this.subscriptionHistoryRepository = subscriptionHistoryRepository;
        this.paymentHistoryRepository = paymentHistoryRepository;
        this.notificationService = notificationService;
        this.frontendUrl = frontendUrl != null ? frontendUrl.replaceAll("/+$", "") : "http://localhost:3000";
    }

    @Transactional
    public CheckoutSessionResponse createCheckoutSession(String userEmail, CheckoutRequest request) throws StripeException {
        String planSlug = normalizePlanSlug(request.getPlanSlug());
        String billingInterval = normalizeInterval(request.getBillingInterval());
        String locale = sanitizeLocale(request.getLocale());
        String returnPath = sanitizeReturnPath(request.getReturnPath());

        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription localSub = entitlementService.getOrReconcileSubscription(user);

        // If the user already has a Stripe-managed subscription, route them to Customer Portal
        // so billing changes avoid duplicate subscriptions / double-billing.
        if (hasActiveStripeSubscription(localSub) && localSub.getStripeCustomerId() != null) {
            String portalUrl = buildPortalUrl(localSub.getStripeCustomerId(), locale, returnPath);
            return new CheckoutSessionResponse(null, portalUrl, "PORTAL");
        }

        Plan targetPlan = planRepository.findBySlug(planSlug)
                .orElseThrow(() -> new ResourceNotFoundException("Plan not found: " + planSlug));

        String priceId = resolvePriceId(targetPlan, planSlug, billingInterval);
        StripeClient client = stripeClientFactory.getClient();
        String customerId = ensureStripeCustomer(client, user, localSub);

        String baseReturnUrl = frontendUrl + "/" + locale + returnPath;
        String successUrl = baseReturnUrl + "?checkout=success&session_id={CHECKOUT_SESSION_ID}";
        String cancelUrl = baseReturnUrl + "?checkout=canceled";

        SessionCreateParams.SubscriptionData.Builder subData = SessionCreateParams.SubscriptionData.builder()
                .putMetadata("userId", user.getId().toString())
                .putMetadata("planSlug", planSlug)
                .putMetadata("billingInterval", billingInterval);

        // Official AFAB policy: 7-day free trial is EXCLUSIVELY available for Plus, once per account.
        boolean eligibleForTrial = "plus".equals(planSlug)
                && !Boolean.TRUE.equals(localSub.getTrialUsed())
                && localSub.getTrialEnd() == null;
        if (eligibleForTrial) {
            subData.setTrialPeriodDays(7L);
        }

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.SUBSCRIPTION)
                .setCustomer(customerId)
                .setClientReferenceId(user.getId().toString())
                .setAllowPromotionCodes(true)
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .addLineItem(
                        SessionCreateParams.LineItem.builder()
                                .setQuantity(1L)
                                .setPrice(priceId)
                                .build()
                )
                .setSubscriptionData(subData.build())
                .build();

        com.stripe.model.checkout.Session session = client.v1().checkout().sessions().create(params);
        return new CheckoutSessionResponse(session.getId(), session.getUrl(), "CHECKOUT");
    }

    @Transactional
    public PortalSessionResponse createPortalSession(String userEmail, PortalRequest request) throws StripeException {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription localSub = entitlementService.getOrReconcileSubscription(user);

        if (localSub.getStripeCustomerId() == null || localSub.getStripeCustomerId().isBlank()) {
            throw new IllegalStateException("No Stripe billing profile exists yet. Start a paid plan first.");
        }

        String locale = sanitizeLocale(request != null ? request.getLocale() : null);
        String returnPath = sanitizeReturnPath(request != null ? request.getReturnPath() : null);
        String portalUrl = buildPortalUrl(localSub.getStripeCustomerId(), locale, returnPath);
        return new PortalSessionResponse(portalUrl);
    }

    @Transactional
    public SubscriptionSnapshotDTO verifyCheckoutSession(String userEmail, String sessionId) throws StripeException {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription localSub = entitlementService.getOrReconcileSubscription(user);

        StripeClient client = stripeClientFactory.getClient();
        com.stripe.model.checkout.Session session = client.v1().checkout().sessions().retrieve(sessionId.trim());

        boolean matchesUser = user.getId().toString().equals(session.getClientReferenceId());
        boolean matchesCustomer = localSub.getStripeCustomerId() != null
                && localSub.getStripeCustomerId().equals(session.getCustomer());
        if (!matchesUser && !matchesCustomer) {
            throw new ForbiddenException("Checkout session does not belong to the authenticated user.");
        }

        if (session.getSubscription() != null && !session.getSubscription().isBlank()) {
            com.stripe.model.Subscription stripeSub = client.v1().subscriptions().retrieve(session.getSubscription());
            syncFromStripeSubscription(stripeSub, user, null, null);
        }

        return entitlementService.getEntitlementsSnapshot(userEmail);
    }

    /**
     * Schedule subscription cancellation at the end of the current billing period or 7-day trial.
     * Prevents future renewal / first trial charge while keeping paid access until expiration.
     */
    @Transactional
    public SubscriptionSnapshotDTO cancelSubscription(String userEmail, CancelSubscriptionRequest request) throws StripeException {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription localSub = entitlementService.getOrReconcileSubscription(user);

        String currentSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug().toLowerCase() : "free";
        if ("free".equals(currentSlug) && !hasActiveStripeSubscription(localSub)) {
            throw new IllegalStateException("No active paid subscription is available to cancel.");
        }

        if (request != null && request.getSelectedBusinessIds() != null && !request.getSelectedBusinessIds().isEmpty()
                && businessAllocationService != null) {
            businessAllocationService.savePendingAllocation(user, "free", request.getSelectedBusinessIds());
        }

        Plan freePlan = planRepository.findBySlug("free")
                .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));

        // If subscription is managed locally in DB without a Stripe subscription ID, downgrade immediately to Free
        if (!hasActiveStripeSubscription(localSub)) {
            String previousStatus = localSub.getStatus();
            localSub.setPlan(freePlan);
            localSub.setStatus("ACTIVE");
            localSub.setBillingInterval(null);
            localSub.setCancelAtPeriodEnd(false);
            localSub.setCanceledAt(null);
            localSub.setEffectiveCancelAt(null);
            localSub.setPeriodStart(Instant.now());
            localSub.setPeriodEnd(null);
            if (businessAllocationService != null) {
                businessAllocationService.applyDowngradeAllocation(localSub, freePlan);
            }
            subscriptionRepository.save(localSub);
            user.setPlanTier("FREE");
            userRepository.save(user);

            recordHistory(user, "SUBSCRIPTION_DOWNGRADED", currentSlug, "free",
                    previousStatus, "ACTIVE", null, Instant.now(),
                    "Downgraded from " + currentSlug.toUpperCase() + " to FREE and applied 1-business editable allocation.");
            emitNotification(
                    user,
                    "SUBSCRIPTION_DOWNGRADED",
                    "WARNING",
                    "Subscription Moved to Free",
                    "Your account is now on the Free plan (1 editable business). All remaining businesses and historical financial data are preserved in read-only mode.",
                    "/dashboard/settings/subscription",
                    true
            );
            return entitlementService.getEntitlementsSnapshot(userEmail);
        }

        StripeClient client = stripeClientFactory.getClient();
        releaseScheduleIfPresent(client, localSub);

        SubscriptionUpdateParams params = SubscriptionUpdateParams.builder()
                .setCancelAtPeriodEnd(true)
                .build();
        com.stripe.model.Subscription updatedStripeSub =
                client.v1().subscriptions().update(localSub.getStripeSubscriptionId(), params);

        Instant effectiveEnd = resolveEffectiveEnd(updatedStripeSub, localSub);

        String previousPlanSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug() : "free";
        boolean wasTrial = "TRIALING".equalsIgnoreCase(localSub.getStatus());

        localSub.setCancelAtPeriodEnd(true);
        localSub.setCanceledAt(Instant.now());
        localSub.setEffectiveCancelAt(effectiveEnd);
        localSub.setPendingPlan(freePlan);
        localSub.setPendingBillingInterval(null);
        localSub.setPendingChangeEffectiveAt(effectiveEnd);
        subscriptionRepository.save(localSub);

        String formattedDate = effectiveEnd != null ? FRIENDLY_DATE.format(effectiveEnd) : "the end of your billing period";
        String historyDetail = wasTrial
                ? "Trial cancellation scheduled for " + formattedDate + "; no first payment will be collected."
                : "Subscription cancellation scheduled for " + formattedDate + "; will transition to Free.";

        recordHistory(user, "CANCEL_SCHEDULED", previousPlanSlug, "free",
                localSub.getStatus(), localSub.getStatus(), null, effectiveEnd, historyDetail);

        emitNotification(
                user,
                "SUBSCRIPTION_CANCELED",
                "WARNING",
                wasTrial ? "Trial Cancellation Scheduled" : "Subscription Cancellation Scheduled",
                wasTrial
                        ? "Your Plus trial has been canceled and you will not be charged. You keep full Plus access until " + formattedDate + ", after which your account moves to Free with 1 editable business and all other business records preserved in read-only mode."
                        : "Your " + localSub.getPlan().getName() + " subscription will remain active until " + formattedDate + " and will not renew. All businesses beyond the Free limit will switch to read-only mode with full historical data preserved.",
                "/dashboard/settings/subscription",
                true
        );

        return entitlementService.getEntitlementsSnapshot(userEmail);
    }

    /**
     * Reverses a scheduled cancellation or scheduled downgrade before the effective date.
     */
    @Transactional
    public SubscriptionSnapshotDTO resumeSubscription(String userEmail) throws StripeException {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription localSub = entitlementService.getOrReconcileSubscription(user);

        boolean hasPendingCancel = Boolean.TRUE.equals(localSub.getCancelAtPeriodEnd());
        boolean hasPendingDowngrade = localSub.getPendingPlan() != null || localSub.getStripeScheduleId() != null;
        if (!hasPendingCancel && !hasPendingDowngrade) {
            throw new IllegalStateException("No scheduled cancellation or downgrade is active to reverse.");
        }

        StripeClient client = stripeClientFactory.getClient();
        releaseScheduleIfPresent(client, localSub);

        if (hasPendingCancel && hasActiveStripeSubscription(localSub)) {
            SubscriptionUpdateParams params = SubscriptionUpdateParams.builder()
                    .setCancelAtPeriodEnd(false)
                    .build();
            com.stripe.model.Subscription updated = client.v1().subscriptions().update(localSub.getStripeSubscriptionId(), params);
            applyStripePeriodDates(updated, localSub);
        }

        String currentSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug() : "free";
        String cancelledPendingSlug = localSub.getPendingPlan() != null ? localSub.getPendingPlan().getSlug() : "free";

        localSub.setCancelAtPeriodEnd(false);
        localSub.setCanceledAt(null);
        localSub.setEffectiveCancelAt(null);
        localSub.setPendingPlan(null);
        localSub.setPendingBillingInterval(null);
        localSub.setPendingChangeEffectiveAt(null);
        subscriptionRepository.save(localSub);

        if (businessAllocationService != null) {
            businessAllocationService.clearPendingAllocation(user);
        }

        recordHistory(user, "CANCEL_REVERSED", cancelledPendingSlug, currentSlug,
                localSub.getStatus(), localSub.getStatus(), null, Instant.now(),
                "Scheduled cancellation/downgrade reversed; continuing on " + currentSlug.toUpperCase());

        emitNotification(
                user,
                "SUBSCRIPTION_RESUMED",
                "SUCCESS",
                "Subscription Renewal Restored",
                "Your " + localSub.getPlan().getName() + " plan will continue renewing as normal and your current editable businesses remain active.",
                "/dashboard/settings/subscription",
                true
        );

        return entitlementService.getEntitlementsSnapshot(userEmail);
    }

    /**
     * Schedules a downgrade at period end (Pro -> Plus, Pro -> Free, Plus -> Free),
     * saving the customer's chosen future editable businesses separately in pending_business_allocations.
     */
    @Transactional
    public SubscriptionSnapshotDTO scheduleDowngrade(String userEmail, DowngradeSubscriptionRequest request) throws StripeException {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription localSub = entitlementService.getOrReconcileSubscription(user);

        String targetSlug = request.getTargetPlanSlug().trim().toLowerCase();
        if (!"free".equals(targetSlug) && !"plus".equals(targetSlug)) {
            throw new IllegalArgumentException("Downgrades target either 'plus' or 'free'.");
        }

        String currentSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug().toLowerCase() : "free";
        if (tierRank(targetSlug) >= tierRank(currentSlug)) {
            throw new IllegalArgumentException("Target plan '" + targetSlug + "' is not lower than current plan '" + currentSlug + "'.");
        }

        Plan targetPlan = planRepository.findBySlug(targetSlug)
                .orElseThrow(() -> new ResourceNotFoundException("Plan not found: " + targetSlug));

        int targetLimit = businessAllocationService != null ? businessAllocationService.resolveEditableLimit(targetPlan) : 1;
        List<Business> owned = businessRepository != null ? businessRepository.findAllOwnedActiveByUserId(user.getId()) : List.of();

        if (request.getSelectedBusinessIds() != null && !request.getSelectedBusinessIds().isEmpty()) {
            if (businessAllocationService != null) {
                businessAllocationService.savePendingAllocation(user, targetSlug, request.getSelectedBusinessIds());
            }
        } else if (owned.size() > targetLimit && !Boolean.TRUE.equals(request.getDeferAllocation())) {
            throw new IllegalArgumentException(
                    "Your " + targetPlan.getName() + " plan supports " + targetLimit
                            + " editable business(es). Please select which " + targetLimit + " businesses to keep editable."
            );
        }

        if ("free".equals(targetSlug)) {
            CancelSubscriptionRequest cancelReq = new CancelSubscriptionRequest();
            cancelReq.setSelectedBusinessIds(request.getSelectedBusinessIds());
            return cancelSubscription(userEmail, cancelReq);
        }

        String targetInterval = (request.getBillingInterval() != null && !request.getBillingInterval().isBlank())
                ? normalizeInterval(request.getBillingInterval())
                : ("YEARLY".equalsIgnoreCase(localSub.getBillingInterval()) ? "yearly" : "monthly");

        // If subscription is a local/non-Stripe Pro plan in DB, apply the downgrade & 3-business allocation immediately
        if (!hasActiveStripeSubscription(localSub)) {
            String previousStatus = localSub.getStatus();
            localSub.setPlan(targetPlan);
            localSub.setStatus("ACTIVE");
            localSub.setBillingInterval(targetInterval.toUpperCase());
            localSub.setCancelAtPeriodEnd(false);
            localSub.setCanceledAt(null);
            localSub.setEffectiveCancelAt(null);
            if (businessAllocationService != null) {
                businessAllocationService.applyDowngradeAllocation(localSub, targetPlan);
            }
            subscriptionRepository.save(localSub);
            user.setPlanTier(targetPlan.getSlug().toUpperCase());
            userRepository.save(user);

            recordHistory(user, "SUBSCRIPTION_DOWNGRADED", currentSlug, targetSlug,
                    previousStatus, "ACTIVE", null, Instant.now(),
                    "Downgraded from " + currentSlug.toUpperCase() + " to " + targetSlug.toUpperCase()
                            + " and applied " + targetLimit + "-business editable allocation.");
            emitNotification(
                    user,
                    "SUBSCRIPTION_DOWNGRADED",
                    "WARNING",
                    "Plan Downgraded to " + targetPlan.getName(),
                    "Your subscription is now on " + targetPlan.getName()
                            + " (" + targetLimit + " editable businesses). Your unselected businesses remain safely preserved in read-only mode.",
                    "/dashboard/settings/subscription",
                    true
            );
            return entitlementService.getEntitlementsSnapshot(userEmail);
        }

        String newPriceId = resolvePriceId(targetPlan, targetSlug, targetInterval);

        StripeClient client = stripeClientFactory.getClient();
        com.stripe.model.Subscription stripeSub = client.v1().subscriptions().retrieve(localSub.getStripeSubscriptionId());

        if (Boolean.TRUE.equals(stripeSub.getCancelAtPeriodEnd())) {
            stripeSub = client.v1().subscriptions().update(
                    stripeSub.getId(),
                    SubscriptionUpdateParams.builder().setCancelAtPeriodEnd(false).build()
            );
        }

        SubscriptionItem firstItem = extractFirstItem(stripeSub);
        long phase1Start = firstItem != null && firstItem.getCurrentPeriodStart() != null
                ? firstItem.getCurrentPeriodStart()
                : Instant.now().getEpochSecond();
        long phase1End = firstItem != null && firstItem.getCurrentPeriodEnd() != null
                ? firstItem.getCurrentPeriodEnd()
                : Instant.now().plus(30, ChronoUnit.DAYS).getEpochSecond();
        String currentPriceId = firstItem != null && firstItem.getPrice() != null
                ? firstItem.getPrice().getId()
                : localSub.getStripePriceId();

        String scheduleId = stripeSub.getSchedule();
        SubscriptionSchedule activeSchedule = null;
        if (scheduleId == null || scheduleId.isBlank()) {
            activeSchedule = client.v1().subscriptionSchedules().create(
                    SubscriptionScheduleCreateParams.builder()
                            .setFromSubscription(stripeSub.getId())
                            .build()
            );
            scheduleId = activeSchedule != null ? activeSchedule.getId() : null;
        } else {
            try {
                activeSchedule = client.v1().subscriptionSchedules().retrieve(scheduleId);
            } catch (Exception ignored) {}
        }

        if (activeSchedule != null && activeSchedule.getPhases() != null && !activeSchedule.getPhases().isEmpty()) {
            SubscriptionSchedule.Phase currentPhase = activeSchedule.getPhases().get(0);
            if (currentPhase.getStartDate() != null) {
                phase1Start = currentPhase.getStartDate();
            }
            if (currentPhase.getEndDate() != null) {
                phase1End = currentPhase.getEndDate();
            }
        }

        SubscriptionScheduleUpdateParams scheduleUpdateParams = SubscriptionScheduleUpdateParams.builder()
                .setEndBehavior(SubscriptionScheduleUpdateParams.EndBehavior.RELEASE)
                .addPhase(SubscriptionScheduleUpdateParams.Phase.builder()
                        .setStartDate(phase1Start)
                        .setEndDate(phase1End)
                        .addItem(SubscriptionScheduleUpdateParams.Phase.Item.builder()
                                .setPrice(currentPriceId)
                                .setQuantity(1L)
                                .build())
                        .build())
                .addPhase(SubscriptionScheduleUpdateParams.Phase.builder()
                        .setStartDate(phase1End)
                        .addItem(SubscriptionScheduleUpdateParams.Phase.Item.builder()
                                .setPrice(newPriceId)
                                .setQuantity(1L)
                                .build())
                        .putMetadata("userId", user.getId().toString())
                        .putMetadata("planSlug", targetSlug)
                        .putMetadata("billingInterval", targetInterval)
                        .build())
                .build();
        client.v1().subscriptionSchedules().update(scheduleId, scheduleUpdateParams);

        Instant effectiveAt = Instant.ofEpochSecond(phase1End);
        localSub.setStripeScheduleId(scheduleId);
        localSub.setPendingPlan(targetPlan);
        localSub.setPendingBillingInterval(targetInterval.toUpperCase());
        localSub.setPendingChangeEffectiveAt(effectiveAt);
        localSub.setCancelAtPeriodEnd(false);
        localSub.setCanceledAt(null);
        localSub.setEffectiveCancelAt(null);
        subscriptionRepository.save(localSub);

        recordHistory(user, "DOWNGRADE_SCHEDULED", currentSlug, targetSlug,
                localSub.getStatus(), localSub.getStatus(), null, effectiveAt,
                "Scheduled downgrade from " + currentSlug.toUpperCase() + " to " + targetSlug.toUpperCase()
                        + " effective " + FRIENDLY_DATE.format(effectiveAt));

        emitNotification(
                user,
                "DOWNGRADE_SCHEDULED",
                "INFO",
                "Downgrade Scheduled to " + targetPlan.getName(),
                "You will continue enjoying " + localSub.getPlan().getName() + " benefits until "
                        + FRIENDLY_DATE.format(effectiveAt) + ", when your plan transitions to " + targetPlan.getName()
                        + " (" + targetLimit + " editable businesses).",
                "/dashboard/settings/subscription",
                true
        );

        return entitlementService.getEntitlementsSnapshot(userEmail);
    }

    /**
     * Upgrades a subscription immediately (either direct prorated Stripe subscription update
     * when already subscribed, or Stripe Checkout when moving up from Free) and restores editable access
     * to previously read-only businesses up to the new plan limit.
     */
    @Transactional
    public UpgradeSubscriptionResponse upgradeSubscription(String userEmail, UpgradeSubscriptionRequest request) throws StripeException {
        String planSlug = normalizePlanSlug(request.getPlanSlug());
        String billingInterval = normalizeInterval(request.getBillingInterval());

        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription localSub = entitlementService.getOrReconcileSubscription(user);

        String currentSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug().toLowerCase() : "free";
        if (tierRank(planSlug) < tierRank(currentSlug)) {
            throw new IllegalArgumentException("Use the downgrade workflow to move to a lower plan tier.");
        }

        if (!hasActiveStripeSubscription(localSub)) {
            CheckoutRequest checkoutReq = new CheckoutRequest();
            checkoutReq.setPlanSlug(planSlug);
            checkoutReq.setBillingInterval(billingInterval);
            checkoutReq.setLocale(request.getLocale());
            checkoutReq.setReturnPath(request.getReturnPath());
            CheckoutSessionResponse checkoutRes = createCheckoutSession(userEmail, checkoutReq);
            return new UpgradeSubscriptionResponse(checkoutRes.getMode(), checkoutRes.getSessionId(), checkoutRes.getUrl(), null);
        }

        Plan targetPlan = planRepository.findBySlug(planSlug)
                .orElseThrow(() -> new ResourceNotFoundException("Plan not found: " + planSlug));
        String newPriceId = resolvePriceId(targetPlan, planSlug, billingInterval);

        StripeClient client = stripeClientFactory.getClient();
        releaseScheduleIfPresent(client, localSub);

        com.stripe.model.Subscription stripeSub = client.v1().subscriptions().retrieve(localSub.getStripeSubscriptionId());
        SubscriptionItem firstItem = extractFirstItem(stripeSub);
        if (firstItem == null || firstItem.getId() == null) {
            throw new IllegalStateException("Active Stripe subscription is missing line items.");
        }

        SubscriptionUpdateParams params = SubscriptionUpdateParams.builder()
                .setCancelAtPeriodEnd(false)
                .setProrationBehavior(SubscriptionUpdateParams.ProrationBehavior.CREATE_PRORATIONS)
                .addItem(SubscriptionUpdateParams.Item.builder()
                        .setId(firstItem.getId())
                        .setPrice(newPriceId)
                        .build())
                .putMetadata("userId", user.getId().toString())
                .putMetadata("planSlug", planSlug)
                .putMetadata("billingInterval", billingInterval)
                .build();

        com.stripe.model.Subscription updatedStripeSub = client.v1().subscriptions().update(stripeSub.getId(), params);
        syncFromStripeSubscription(updatedStripeSub, user, null, null);

        SubscriptionSnapshotDTO snapshot = entitlementService.getEntitlementsSnapshot(userEmail);
        return new UpgradeSubscriptionResponse("DIRECT_UPGRADE", null, null, snapshot);
    }

    @Transactional(readOnly = true)
    public BillingHistoryResponse getBillingHistory(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));

        List<BillingHistoryResponse.SubscriptionHistoryItemDTO> subHistory = subscriptionHistoryRepository != null
                ? subscriptionHistoryRepository.findTop50ByUserIdOrderByCreatedAtDesc(user.getId())
                        .stream()
                        .map(h -> {
                            BillingHistoryResponse.SubscriptionHistoryItemDTO item =
                                    new BillingHistoryResponse.SubscriptionHistoryItemDTO();
                            item.setId(h.getId());
                            item.setEventType(h.getEventType());
                            item.setFromPlanSlug(h.getFromPlanSlug());
                            item.setToPlanSlug(h.getToPlanSlug());
                            item.setFromStatus(h.getFromStatus());
                            item.setToStatus(h.getToStatus());
                            item.setEffectiveAt(h.getEffectiveAt());
                            item.setDetails(h.getDetails());
                            item.setCreatedAt(h.getCreatedAt());
                            return item;
                        })
                        .toList()
                : List.of();

        List<BillingHistoryResponse.PaymentHistoryItemDTO> payHistory = paymentHistoryRepository != null
                ? paymentHistoryRepository.findTop50ByUserIdOrderByCreatedAtDesc(user.getId())
                        .stream()
                        .map(p -> {
                            BillingHistoryResponse.PaymentHistoryItemDTO item =
                                    new BillingHistoryResponse.PaymentHistoryItemDTO();
                            item.setId(p.getId());
                            item.setStripeInvoiceId(p.getStripeInvoiceId());
                            item.setAmountCents(p.getAmountCents());
                            item.setCurrency(p.getCurrency());
                            item.setStatus(p.getStatus());
                            item.setFailureReason(p.getFailureReason());
                            item.setHostedInvoiceUrl(p.getHostedInvoiceUrl());
                            item.setInvoicePdfUrl(p.getInvoicePdfUrl());
                            item.setPaidAt(p.getPaidAt());
                            item.setFailedAt(p.getFailedAt());
                            item.setCreatedAt(p.getCreatedAt());
                            return item;
                        })
                        .toList()
                : List.of();

        return new BillingHistoryResponse(subHistory, payHistory);
    }

    @Transactional
    public void handleWebhook(String rawPayload, String sigHeader) throws SignatureVerificationException, StripeException {
        if (!stripeProperties.isWebhookConfigured()) {
            throw new BillingNotConfiguredException(
                    "Stripe webhook secret is not configured. Set STRIPE_WEBHOOK_SECRET in project/.env."
            );
        }
        if (sigHeader == null || sigHeader.isBlank()) {
            throw new IllegalArgumentException("Missing Stripe-Signature header.");
        }

        Event event = Webhook.constructEvent(rawPayload, sigHeader, stripeProperties.getWebhookSecret().trim());
        if (webhookEventRepository.existsById(event.getId())) {
            log.debug("Ignoring duplicate Stripe webhook event {}", event.getId());
            return;
        }

        String type = event.getType();
        log.info("Processing Stripe webhook event {} ({})", event.getId(), type);

        switch (type) {
            case "checkout.session.completed" -> handleCheckoutCompleted(event);
            case "customer.subscription.created", "customer.subscription.updated" -> handleSubscriptionUpsert(event);
            case "customer.subscription.deleted" -> handleSubscriptionDeletedEvent(event);
            case "invoice.paid", "invoice.payment_succeeded" -> handleInvoicePaid(event);
            case "invoice.payment_failed" -> handleInvoicePaymentFailed(event);
            default -> log.debug("Unhandled Stripe webhook event type {}", type);
        }

        webhookEventRepository.save(new StripeWebhookEvent(event.getId(), type));
    }

    public void cancelStripeSubscriptionIfPresent(User user) {
        if (user == null || !stripeProperties.isConfigured()) {
            return;
        }
        Optional<Subscription> subOpt = subscriptionRepository.findByUserId(user.getId());
        if (subOpt.isEmpty()) {
            return;
        }
        String stripeSubId = subOpt.get().getStripeSubscriptionId();
        if (stripeSubId == null || stripeSubId.isBlank()) {
            return;
        }
        try {
            releaseScheduleIfPresent(stripeClientFactory.getClient(), subOpt.get());
            stripeClientFactory.getClient().v1().subscriptions().cancel(stripeSubId);
            log.info("Canceled Stripe subscription {} before deleting user {}", stripeSubId, user.getId());
        } catch (Exception e) {
            log.warn("Best-effort Stripe cancellation failed for subscription {}: {}", stripeSubId, e.getMessage());
        }
    }

    private void handleCheckoutCompleted(Event event) throws StripeException {
        Optional<com.stripe.model.checkout.Session> sessionOpt =
                deserializeEventObject(event, com.stripe.model.checkout.Session.class);
        if (sessionOpt.isEmpty()) {
            return;
        }
        com.stripe.model.checkout.Session session = sessionOpt.get();
        if (session.getSubscription() == null || session.getSubscription().isBlank()) {
            return;
        }

        User explicitUser = null;
        if (session.getClientReferenceId() != null && !session.getClientReferenceId().isBlank()) {
            try {
                explicitUser = userRepository.findById(UUID.fromString(session.getClientReferenceId())).orElse(null);
            } catch (IllegalArgumentException ignored) {
                // Fallback to customer lookup inside syncFromStripeSubscription
            }
        }

        com.stripe.model.Subscription stripeSub = stripeClientFactory.getClient()
                .v1().subscriptions().retrieve(session.getSubscription());
        syncFromStripeSubscription(stripeSub, explicitUser, event.getCreated(), event.getId());
    }

    private void handleSubscriptionUpsert(Event event) {
        deserializeEventObject(event, com.stripe.model.Subscription.class)
                .ifPresent(stripeSub -> syncFromStripeSubscription(stripeSub, null, event.getCreated(), event.getId()));
    }

    private void handleSubscriptionDeletedEvent(Event event) {
        deserializeEventObject(event, com.stripe.model.Subscription.class)
                .ifPresent(stripeSub -> downgradeDeletedStripeSubscription(stripeSub, event.getCreated(), event.getId()));
    }

    private void handleInvoicePaid(Event event) throws StripeException {
        Optional<Invoice> invoiceOpt = deserializeEventObject(event, Invoice.class);
        if (invoiceOpt.isEmpty()) {
            return;
        }
        Invoice invoice = invoiceOpt.get();
        String subId = extractSubscriptionId(invoice);

        Subscription localSub = resolveSubscriptionByInvoice(invoice, subId);
        if (localSub != null && isStaleEvent(localSub, event.getCreated())) {
            log.debug("Ignoring stale {} event {} for user {}", event.getType(), event.getId(), localSub.getUser().getId());
            return;
        }

        boolean alreadyRecordedPaid = false;
        if (localSub != null && paymentHistoryRepository != null && invoice.getId() != null) {
            Optional<PaymentHistory> existingOpt = paymentHistoryRepository.findByStripeInvoiceId(invoice.getId());
            alreadyRecordedPaid = existingOpt.isPresent() && "PAID".equalsIgnoreCase(existingOpt.get().getStatus());
            PaymentHistory record = existingOpt.orElseGet(PaymentHistory::new);
            record.setUser(localSub.getUser());
            record.setStripeInvoiceId(invoice.getId());
            record.setStripeSubscriptionId(subId);
            long amount = invoice.getAmountPaid() != null && invoice.getAmountPaid() > 0
                    ? invoice.getAmountPaid()
                    : (invoice.getAmountDue() != null ? invoice.getAmountDue() : 0L);
            record.setAmountCents(amount);
            record.setCurrency(invoice.getCurrency() != null ? invoice.getCurrency().toUpperCase() : "USD");
            record.setStatus("PAID");
            record.setFailureReason(null);
            record.setHostedInvoiceUrl(invoice.getHostedInvoiceUrl());
            record.setInvoicePdfUrl(invoice.getInvoicePdf());
            record.setPaidAt(Instant.now());
            paymentHistoryRepository.save(record);
        }

        boolean wasPastDue = localSub != null
                && ("PAST_DUE".equalsIgnoreCase(localSub.getStatus()) || localSub.getFirstPaymentFailureAt() != null);

        if (localSub != null && wasPastDue) {
            clearGracePeriodFields(localSub);
            subscriptionRepository.save(localSub);
        }

        if (subId != null && !subId.isBlank()) {
            com.stripe.model.Subscription stripeSub = stripeClientFactory.getClient()
                    .v1().subscriptions().retrieve(subId);
            syncFromStripeSubscription(stripeSub, localSub != null ? localSub.getUser() : null, event.getCreated(), event.getId());
        }

        if (localSub != null && !alreadyRecordedPaid) {
            String planSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug() : "free";
            long paidCents = invoice.getAmountPaid() != null ? invoice.getAmountPaid() : 0L;
            if (wasPastDue) {
                recordHistory(localSub.getUser(), "GRACE_PERIOD_RESOLVED", planSlug, planSlug,
                        "PAST_DUE", "ACTIVE", event.getId(), Instant.now(),
                        "Payment succeeded during 3-day grace period; access maintained without changing business allocations.");
                emitNotification(
                        localSub.getUser(),
                        "PAYMENT_SUCCEEDED",
                        "SUCCESS",
                        "Payment Received — Subscription Restored",
                        "Your subscription payment succeeded and your " + localSub.getPlan().getName()
                                + " access has been fully restored with all editable businesses intact.",
                        "/dashboard/settings/subscription",
                        true
                );
            } else if (paidCents > 0) {
                recordHistory(localSub.getUser(), "PAYMENT_SUCCEEDED", planSlug, planSlug,
                        localSub.getStatus(), "ACTIVE", event.getId(), Instant.now(),
                        "Stripe invoice " + invoice.getId() + " paid.");
                emitNotification(
                        localSub.getUser(),
                        "PAYMENT_SUCCEEDED",
                        "SUCCESS",
                        "Subscription Payment Confirmed",
                        "Thank you! Your payment for AFAB " + localSub.getPlan().getName() + " succeeded.",
                        "/dashboard/settings/subscription",
                        true
                );
            }
        }
    }

    private void handleInvoicePaymentFailed(Event event) {
        Optional<Invoice> invoiceOpt = deserializeEventObject(event, Invoice.class);
        if (invoiceOpt.isEmpty()) {
            return;
        }
        Invoice invoice = invoiceOpt.get();
        String subId = extractSubscriptionId(invoice);
        Subscription localSub = resolveSubscriptionByInvoice(invoice, subId);
        if (localSub == null) {
            return;
        }

        if (isStaleEvent(localSub, event.getCreated())) {
            log.debug("Ignoring stale invoice.payment_failed event {} for user {}", event.getId(), localSub.getUser().getId());
            return;
        }

        if (paymentHistoryRepository != null && invoice.getId() != null) {
            Optional<PaymentHistory> existingOpt = paymentHistoryRepository.findByStripeInvoiceId(invoice.getId());
            if (existingOpt.isPresent() && "PAID".equalsIgnoreCase(existingOpt.get().getStatus())) {
                log.debug("Ignoring failure event for already-paid invoice {}", invoice.getId());
                return;
            }
            PaymentHistory record = existingOpt.orElseGet(PaymentHistory::new);
            record.setUser(localSub.getUser());
            record.setStripeInvoiceId(invoice.getId());
            record.setStripeSubscriptionId(subId);
            record.setAmountCents(invoice.getAmountDue() != null ? invoice.getAmountDue() : 0L);
            record.setCurrency(invoice.getCurrency() != null ? invoice.getCurrency().toUpperCase() : "USD");
            record.setStatus("FAILED");
            record.setFailureReason("Subscription renewal payment failed");
            record.setHostedInvoiceUrl(invoice.getHostedInvoiceUrl());
            record.setInvoicePdfUrl(invoice.getInvoicePdf());
            record.setFailedAt(Instant.now());
            paymentHistoryRepository.save(record);
        }

        String previousStatus = localSub.getStatus();
        Instant now = Instant.now();
        boolean startedGraceNow = localSub.getFirstPaymentFailureAt() == null;

        localSub.setStatus("PAST_DUE");
        if (startedGraceNow) {
            localSub.setFirstPaymentFailureAt(now);
            localSub.setGracePeriodEndsAt(now.plus(3, ChronoUnit.DAYS));
            localSub.setGraceReminderSentAt(null);
        }
        localSub.setLastPaymentFailureReason("Payment attempt failed — update your payment method within the 3-day grace period.");
        updateLastStripeEventCreated(localSub, event.getCreated());
        subscriptionRepository.save(localSub);

        String planSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug() : "free";
        recordHistory(
                localSub.getUser(),
                startedGraceNow ? "GRACE_PERIOD_STARTED" : "PAYMENT_FAILED",
                planSlug,
                planSlug,
                previousStatus,
                "PAST_DUE",
                event.getId(),
                localSub.getGracePeriodEndsAt(),
                "Payment failed; 3-day grace period expires on " + FRIENDLY_DATE.format(localSub.getGracePeriodEndsAt())
        );

        emitNotification(
                localSub.getUser(),
                "PAYMENT_FAILED",
                "ERROR",
                "Payment Failed — 3-Day Grace Period Started",
                "We could not process your " + localSub.getPlan().getName()
                        + " renewal payment. Your paid entitlements and businesses remain active during the 3-day grace period until "
                        + FRIENDLY_DATE.format(localSub.getGracePeriodEndsAt())
                        + ". Please update your payment method in Billing Settings to avoid downgrade to Free.",
                "/dashboard/settings/subscription",
                true
        );
    }

    public void syncFromStripeSubscription(com.stripe.model.Subscription stripeSub, User explicitUser) {
        syncFromStripeSubscription(stripeSub, explicitUser, null, null);
    }

    @Transactional
    public void syncFromStripeSubscription(
            com.stripe.model.Subscription stripeSub,
            User explicitUser,
            Long eventCreatedEpoch,
            String stripeEventId
    ) {
        if (stripeSub == null) {
            return;
        }

        Subscription localSub = resolveLocalSubscription(stripeSub, explicitUser);
        if (localSub == null) {
            log.warn("Could not match Stripe subscription {} (customer {}) to an AFAB user.",
                    stripeSub.getId(), stripeSub.getCustomer());
            return;
        }

        if (isStaleEvent(localSub, eventCreatedEpoch)) {
            log.debug("Ignoring out-of-order Stripe subscription event {} ({} < {})",
                    stripeEventId, eventCreatedEpoch, localSub.getLastStripeEventCreated());
            return;
        }

        String mappedStatus = mapStripeStatus(stripeSub.getStatus());
        if ("CANCELED".equals(mappedStatus) || "EXPIRED".equals(mappedStatus)) {
            downgradeDeletedStripeSubscription(stripeSub, eventCreatedEpoch, stripeEventId);
            return;
        }

        String previousSlug = localSub.getPlan() != null && localSub.getPlan().getSlug() != null
                ? localSub.getPlan().getSlug().toLowerCase()
                : "free";
        String previousStatus = localSub.getStatus();
        boolean previousCancelAtPeriodEnd = Boolean.TRUE.equals(localSub.getCancelAtPeriodEnd());

        SubscriptionItem firstItem = extractFirstItem(stripeSub);
        String priceId = (firstItem != null && firstItem.getPrice() != null) ? firstItem.getPrice().getId() : null;
        String metadataPlan = stripeSub.getMetadata() != null ? stripeSub.getMetadata().get("planSlug") : null;
        Plan targetPlan = resolveLocalPlan(priceId, metadataPlan);

        String interval = resolveBillingInterval(firstItem, priceId, targetPlan,
                stripeSub.getMetadata() != null ? stripeSub.getMetadata().get("billingInterval") : null);

        Long periodStartEpoch = firstItem != null ? firstItem.getCurrentPeriodStart() : null;
        Long periodEndEpoch = firstItem != null ? firstItem.getCurrentPeriodEnd() : null;

        localSub.setStripeCustomerId(stripeSub.getCustomer());
        localSub.setStripeSubscriptionId(stripeSub.getId());
        if (priceId != null) {
            localSub.setStripePriceId(priceId);
        }
        localSub.setBillingInterval(interval);
        localSub.setPlan(targetPlan);
        localSub.setStatus(mappedStatus);

        if (periodStartEpoch != null) {
            localSub.setPeriodStart(Instant.ofEpochSecond(periodStartEpoch));
        }
        if (periodEndEpoch != null) {
            localSub.setPeriodEnd(Instant.ofEpochSecond(periodEndEpoch));
        }
        if (stripeSub.getTrialStart() != null) {
            localSub.setTrialStart(Instant.ofEpochSecond(stripeSub.getTrialStart()));
        } else if ("TRIALING".equalsIgnoreCase(mappedStatus) && localSub.getTrialStart() == null) {
            localSub.setTrialStart(Instant.now());
        }
        if (stripeSub.getTrialEnd() != null) {
            localSub.setTrialEnd(Instant.ofEpochSecond(stripeSub.getTrialEnd()));
            localSub.setTrialUsed(true);
        } else if ("TRIALING".equalsIgnoreCase(mappedStatus)) {
            localSub.setTrialUsed(true);
        }

        boolean nowCancelAtPeriodEnd = Boolean.TRUE.equals(stripeSub.getCancelAtPeriodEnd());
        localSub.setCancelAtPeriodEnd(nowCancelAtPeriodEnd);
        if (nowCancelAtPeriodEnd) {
            Instant effectiveEnd = resolveEffectiveEnd(stripeSub, localSub);
            if (localSub.getCanceledAt() == null) {
                localSub.setCanceledAt(Instant.now());
            }
            localSub.setEffectiveCancelAt(effectiveEnd);
            Plan freePlan = planRepository.findBySlug("free").orElse(null);
            localSub.setPendingPlan(freePlan);
            localSub.setPendingBillingInterval(null);
            localSub.setPendingChangeEffectiveAt(effectiveEnd);
        } else if (previousCancelAtPeriodEnd) {
            localSub.setCanceledAt(null);
            localSub.setEffectiveCancelAt(null);
            if (localSub.getPendingPlan() != null && "free".equalsIgnoreCase(localSub.getPendingPlan().getSlug())) {
                localSub.setPendingPlan(null);
                localSub.setPendingBillingInterval(null);
                localSub.setPendingChangeEffectiveAt(null);
            }
        }

        if ("ACTIVE".equalsIgnoreCase(mappedStatus)) {
            clearGracePeriodFields(localSub);
        }

        if (stripeSub.getSchedule() != null && !stripeSub.getSchedule().isBlank()) {
            localSub.setStripeScheduleId(stripeSub.getSchedule());
        } else if (localSub.getPendingPlan() != null && !"free".equalsIgnoreCase(localSub.getPendingPlan().getSlug())
                && targetPlan.getSlug().equalsIgnoreCase(localSub.getPendingPlan().getSlug())) {
            localSub.setStripeScheduleId(null);
        }

        updateLastStripeEventCreated(localSub, eventCreatedEpoch);

        User user = localSub.getUser();
        String newSlug = targetPlan.getSlug().toLowerCase();
        int prevRank = tierRank(previousSlug);
        int newRank = tierRank(newSlug);

        if (prevRank < newRank) {
            if (businessAllocationService != null) {
                businessAllocationService.applyUpgradeAllocation(localSub, targetPlan);
            }
            if ("TRIALING".equalsIgnoreCase(mappedStatus)) {
                recordHistory(user, "TRIAL_STARTED", previousSlug, newSlug,
                        previousStatus, mappedStatus, stripeEventId, localSub.getTrialEnd(),
                        "Started 7-day Plus free trial");
                emitNotification(
                        user,
                        "TRIAL_STARTED",
                        "SUCCESS",
                        "Your 7-Day Plus Free Trial Has Started",
                        "Welcome to AFAB Plus! Manage up to 3 editable businesses free for 7 days"
                                + (localSub.getTrialEnd() != null ? " until " + FRIENDLY_DATE.format(localSub.getTrialEnd()) : "")
                                + ".",
                        "/dashboard/settings/subscription",
                        true
                );
            } else {
                recordHistory(user, "SUBSCRIPTION_UPGRADED", previousSlug, newSlug,
                        previousStatus, mappedStatus, stripeEventId, Instant.now(),
                        "Upgraded from " + previousSlug.toUpperCase() + " to " + newSlug.toUpperCase());
                emitNotification(
                        user,
                        "SUBSCRIPTION_UPGRADED",
                        "SUCCESS",
                        "Upgraded to AFAB " + targetPlan.getName(),
                        "Your subscription is now on " + targetPlan.getName()
                                + " and your previously restricted businesses have been restored up to your new plan limit.",
                        "/dashboard/settings/subscription",
                        true
                );
            }
        } else if (prevRank > newRank) {
            boolean attention = false;
            if (businessAllocationService != null) {
                attention = businessAllocationService.applyDowngradeAllocation(localSub, targetPlan);
            }
            recordHistory(user, "SUBSCRIPTION_DOWNGRADED", previousSlug, newSlug,
                    previousStatus, mappedStatus, stripeEventId, Instant.now(),
                    "Downgraded from " + previousSlug.toUpperCase() + " to " + newSlug.toUpperCase());
            emitNotification(
                    user,
                    "SUBSCRIPTION_DOWNGRADED",
                    "WARNING",
                    "Plan Downgraded to " + targetPlan.getName(),
                    "Your subscription has transitioned to " + targetPlan.getName()
                            + ". All financial data remains preserved; additional businesses exceeding your limit are read-only.",
                    "/dashboard/settings/subscription",
                    true
            );
            if (attention) {
                emitNotification(
                        user,
                        "ALLOCATION_ATTENTION",
                        "WARNING",
                        "Choose Your Editable Businesses",
                        "Your downgrade to " + targetPlan.getName() + " kept your primary business editable. Choose your preferred editable businesses in Subscription Settings.",
                        "/dashboard/settings/subscription",
                        true
                );
            }
        } else if ("TRIALING".equalsIgnoreCase(previousStatus) && "ACTIVE".equalsIgnoreCase(mappedStatus)) {
            recordHistory(user, "TRIAL_CONVERTED", previousSlug, newSlug,
                    previousStatus, mappedStatus, stripeEventId, Instant.now(),
                    "Trial converted to active paid " + targetPlan.getName() + " subscription.");
        } else if (!previousCancelAtPeriodEnd && nowCancelAtPeriodEnd) {
            recordHistory(user, "CANCEL_SCHEDULED", previousSlug, "free",
                    previousStatus, mappedStatus, stripeEventId, localSub.getEffectiveCancelAt(),
                    "Scheduled cancellation synced from Stripe.");
            emitNotification(
                    user,
                    "SUBSCRIPTION_CANCELED",
                    "WARNING",
                    "Subscription Cancellation Scheduled",
                    "Your " + targetPlan.getName() + " plan is scheduled to end on "
                            + (localSub.getEffectiveCancelAt() != null ? FRIENDLY_DATE.format(localSub.getEffectiveCancelAt()) : "the end of your billing period")
                            + " and will not renew.",
                    "/dashboard/settings/subscription",
                    true
            );
        } else if (previousCancelAtPeriodEnd && !nowCancelAtPeriodEnd) {
            if (businessAllocationService != null) {
                businessAllocationService.clearPendingAllocation(user);
            }
            recordHistory(user, "CANCEL_REVERSED", "free", newSlug,
                    previousStatus, mappedStatus, stripeEventId, Instant.now(),
                    "Cancellation reversed via Stripe.");
        }

        subscriptionRepository.save(localSub);
        user.setPlanTier(targetPlan.getSlug().toUpperCase());
        userRepository.save(user);
    }

    private void downgradeDeletedStripeSubscription(
            com.stripe.model.Subscription stripeSub,
            Long eventCreatedEpoch,
            String stripeEventId
    ) {
        Subscription localSub = resolveLocalSubscription(stripeSub, null);
        if (localSub == null) {
            return;
        }
        if (localSub.getStripeSubscriptionId() != null
                && stripeSub.getId() != null
                && !localSub.getStripeSubscriptionId().equals(stripeSub.getId())) {
            log.info("Ignoring deletion of superseded Stripe subscription {} (active is {})",
                    stripeSub.getId(), localSub.getStripeSubscriptionId());
            return;
        }
        if (isStaleEvent(localSub, eventCreatedEpoch)) {
            log.debug("Ignoring stale customer.subscription.deleted event {}", stripeEventId);
            return;
        }

        Plan freePlan = planRepository.findBySlug("free")
                .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));

        String previousSlug = localSub.getPlan() != null ? localSub.getPlan().getSlug() : "free";
        String previousStatus = localSub.getStatus();
        boolean wasTrial = "TRIALING".equalsIgnoreCase(previousStatus);

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
        clearGracePeriodFields(localSub);
        if (localSub.getTrialEnd() != null) {
            localSub.setTrialUsed(true);
        }
        updateLastStripeEventCreated(localSub, eventCreatedEpoch);

        boolean attentionRequired = false;
        if (businessAllocationService != null) {
            attentionRequired = businessAllocationService.applyDowngradeAllocation(localSub, freePlan);
        }

        subscriptionRepository.save(localSub);

        User user = localSub.getUser();
        user.setPlanTier("FREE");
        userRepository.save(user);

        recordHistory(
                user,
                wasTrial ? "TRIAL_ENDED" : "SUBSCRIPTION_DOWNGRADED",
                previousSlug,
                "free",
                previousStatus,
                "ACTIVE",
                stripeEventId,
                Instant.now(),
                wasTrial
                        ? "Trial period ended; transitioned to Free plan."
                        : "Subscription ended and transitioned from " + previousSlug.toUpperCase() + " to FREE."
        );

        emitNotification(
                user,
                "SUBSCRIPTION_DOWNGRADED",
                "WARNING",
                wasTrial ? "Your Plus Trial Ended — Switched to Free" : "Your Subscription Moved to Free",
                "Your account is now on the Free plan (1 editable business). All remaining businesses and historical financial data remain preserved in read-only mode.",
                "/dashboard/settings/subscription",
                true
        );
        if (attentionRequired) {
            emitNotification(
                    user,
                    "ALLOCATION_ATTENTION",
                    "WARNING",
                    "Confirm Your Editable Business",
                    "We kept your designated primary business editable. You can switch which business is editable at any time in Subscription Settings.",
                    "/dashboard/settings/subscription",
                    false
            );
        }
    }

    private Subscription resolveLocalSubscription(com.stripe.model.Subscription stripeSub, User explicitUser) {
        if (stripeSub.getId() != null) {
            Optional<Subscription> bySub = subscriptionRepository.findByStripeSubscriptionId(stripeSub.getId());
            if (bySub.isPresent()) {
                return bySub.get();
            }
        }
        if (stripeSub.getCustomer() != null) {
            Optional<Subscription> byCustomer = subscriptionRepository.findByStripeCustomerId(stripeSub.getCustomer());
            if (byCustomer.isPresent()) {
                return byCustomer.get();
            }
        }
        User user = explicitUser;
        if (user == null && stripeSub.getMetadata() != null && stripeSub.getMetadata().get("userId") != null) {
            try {
                UUID userId = UUID.fromString(stripeSub.getMetadata().get("userId"));
                user = userRepository.findById(userId).orElse(null);
            } catch (IllegalArgumentException ignored) {
                // Ignore invalid metadata UUID
            }
        }
        if (user == null) {
            return null;
        }
        return entitlementService.getOrReconcileSubscription(user);
    }

    private Subscription resolveSubscriptionByInvoice(Invoice invoice, String subId) {
        Optional<Subscription> localOpt = (subId != null && !subId.isBlank())
                ? subscriptionRepository.findByStripeSubscriptionId(subId)
                : Optional.empty();
        if (localOpt.isEmpty() && invoice.getCustomer() != null) {
            localOpt = subscriptionRepository.findByStripeCustomerId(invoice.getCustomer());
        }
        return localOpt.orElse(null);
    }

    private Plan resolveLocalPlan(String priceId, String metadataPlanSlug) {
        if (priceId != null && !priceId.isBlank()) {
            if (priceId.equals(stripeProperties.getPricePlusMonthly()) || priceId.equals(stripeProperties.getPricePlusYearly())) {
                return planRepository.findBySlug("plus").orElseThrow();
            }
            if (priceId.equals(stripeProperties.getPriceProMonthly()) || priceId.equals(stripeProperties.getPriceProYearly())) {
                return planRepository.findBySlug("pro").orElseThrow();
            }
            Optional<Plan> byDbPrice = planRepository.findByStripePriceIdMonthlyOrStripePriceIdYearly(priceId, priceId);
            if (byDbPrice.isPresent()) {
                return byDbPrice.get();
            }
        }
        if (metadataPlanSlug != null && !metadataPlanSlug.isBlank()) {
            Optional<Plan> byMeta = planRepository.findBySlug(metadataPlanSlug.toLowerCase().trim());
            if (byMeta.isPresent()) {
                return byMeta.get();
            }
        }
        return planRepository.findBySlug("free")
                .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));
    }

    private String resolveBillingInterval(SubscriptionItem item, String priceId, Plan plan, String metadataInterval) {
        if (item != null && item.getPrice() != null && item.getPrice().getRecurring() != null
                && item.getPrice().getRecurring().getInterval() != null) {
            return "year".equalsIgnoreCase(item.getPrice().getRecurring().getInterval()) ? "YEARLY" : "MONTHLY";
        }
        if (priceId != null) {
            if (priceId.equals(stripeProperties.getPricePlusYearly())
                    || priceId.equals(stripeProperties.getPriceProYearly())
                    || priceId.equals(plan.getStripePriceIdYearly())) {
                return "YEARLY";
            }
            if (priceId.equals(stripeProperties.getPricePlusMonthly())
                    || priceId.equals(stripeProperties.getPriceProMonthly())
                    || priceId.equals(plan.getStripePriceIdMonthly())) {
                return "MONTHLY";
            }
        }
        if ("yearly".equalsIgnoreCase(metadataInterval)) {
            return "YEARLY";
        }
        return "MONTHLY";
    }

    private String resolvePriceId(Plan plan, String planSlug, String billingInterval) {
        boolean yearly = "yearly".equalsIgnoreCase(billingInterval);
        String configuredOverride;
        if ("plus".equalsIgnoreCase(planSlug)) {
            configuredOverride = yearly ? stripeProperties.getPricePlusYearly() : stripeProperties.getPricePlusMonthly();
        } else {
            configuredOverride = yearly ? stripeProperties.getPriceProYearly() : stripeProperties.getPriceProMonthly();
        }
        if (configuredOverride != null && !configuredOverride.isBlank()) {
            return configuredOverride.trim();
        }
        String dbPrice = yearly ? plan.getStripePriceIdYearly() : plan.getStripePriceIdMonthly();
        if (dbPrice != null && !dbPrice.isBlank()) {
            return dbPrice.trim();
        }
        throw new IllegalStateException("Stripe price ID is not configured for plan " + planSlug + " (" + billingInterval + ").");
    }

    private String ensureStripeCustomer(StripeClient client, User user, Subscription localSub) throws StripeException {
        if (localSub.getStripeCustomerId() != null && !localSub.getStripeCustomerId().isBlank()) {
            return localSub.getStripeCustomerId();
        }
        String fullName = ((user.getFirstName() != null ? user.getFirstName() : "") + " "
                + (user.getLastName() != null ? user.getLastName() : "")).trim();

        CustomerCreateParams customerParams = CustomerCreateParams.builder()
                .setEmail(user.getEmail())
                .setName(fullName.isEmpty() ? user.getEmail() : fullName)
                .putMetadata("userId", user.getId().toString())
                .build();

        Customer customer = client.v1().customers().create(customerParams);
        localSub.setStripeCustomerId(customer.getId());
        subscriptionRepository.save(localSub);
        return customer.getId();
    }

    private String buildPortalUrl(String customerId, String locale, String returnPath) throws StripeException {
        StripeClient client = stripeClientFactory.getClient();
        String returnUrl = frontendUrl + "/" + locale + returnPath;

        com.stripe.param.billingportal.SessionCreateParams.Builder builder =
                com.stripe.param.billingportal.SessionCreateParams.builder()
                        .setCustomer(customerId)
                        .setReturnUrl(returnUrl);

        if (stripeProperties.getPortalConfigurationId() != null && !stripeProperties.getPortalConfigurationId().isBlank()) {
            builder.setConfiguration(stripeProperties.getPortalConfigurationId().trim());
        }

        com.stripe.model.billingportal.Session session = client.v1().billingPortal().sessions().create(builder.build());
        return session.getUrl();
    }

    private void releaseScheduleIfPresent(StripeClient client, Subscription localSub) {
        String scheduleId = localSub.getStripeScheduleId();
        if (scheduleId == null || scheduleId.isBlank()) {
            return;
        }
        try {
            client.v1().subscriptionSchedules().release(scheduleId);
        } catch (Exception e) {
            log.warn("Could not release Stripe schedule {}: {}", scheduleId, e.getMessage());
        }
        localSub.setStripeScheduleId(null);
    }

    private void applyStripePeriodDates(com.stripe.model.Subscription stripeSub, Subscription localSub) {
        if (stripeSub == null) return;
        SubscriptionItem item = extractFirstItem(stripeSub);
        if (item != null && item.getCurrentPeriodStart() != null) {
            localSub.setPeriodStart(Instant.ofEpochSecond(item.getCurrentPeriodStart()));
        }
        if (item != null && item.getCurrentPeriodEnd() != null) {
            localSub.setPeriodEnd(Instant.ofEpochSecond(item.getCurrentPeriodEnd()));
        }
        if (stripeSub.getTrialEnd() != null) {
            localSub.setTrialEnd(Instant.ofEpochSecond(stripeSub.getTrialEnd()));
        }
    }

    private Instant resolveEffectiveEnd(com.stripe.model.Subscription stripeSub, Subscription localSub) {
        if (stripeSub != null) {
            if (stripeSub.getCancelAt() != null) {
                return Instant.ofEpochSecond(stripeSub.getCancelAt());
            }
            SubscriptionItem item = extractFirstItem(stripeSub);
            if (item != null && item.getCurrentPeriodEnd() != null) {
                return Instant.ofEpochSecond(item.getCurrentPeriodEnd());
            }
            if (stripeSub.getTrialEnd() != null) {
                return Instant.ofEpochSecond(stripeSub.getTrialEnd());
            }
        }
        return localSub.getPeriodEnd() != null ? localSub.getPeriodEnd() : localSub.getTrialEnd();
    }

    private SubscriptionItem extractFirstItem(com.stripe.model.Subscription stripeSub) {
        if (stripeSub != null && stripeSub.getItems() != null
                && stripeSub.getItems().getData() != null
                && !stripeSub.getItems().getData().isEmpty()) {
            return stripeSub.getItems().getData().get(0);
        }
        return null;
    }

    private void clearGracePeriodFields(Subscription localSub) {
        localSub.setFirstPaymentFailureAt(null);
        localSub.setGracePeriodEndsAt(null);
        localSub.setLastPaymentFailureReason(null);
        localSub.setGraceReminderSentAt(null);
    }

    private boolean isStaleEvent(Subscription localSub, Long eventCreatedEpoch) {
        return eventCreatedEpoch != null
                && localSub.getLastStripeEventCreated() != null
                && eventCreatedEpoch < localSub.getLastStripeEventCreated();
    }

    private void updateLastStripeEventCreated(Subscription localSub, Long eventCreatedEpoch) {
        if (eventCreatedEpoch != null && (localSub.getLastStripeEventCreated() == null
                || eventCreatedEpoch > localSub.getLastStripeEventCreated())) {
            localSub.setLastStripeEventCreated(eventCreatedEpoch);
        }
    }

    private void recordHistory(User user, String eventType, String fromPlan, String toPlan,
                               String fromStatus, String toStatus, String stripeEventId,
                               Instant effectiveAt, String details) {
        if (subscriptionHistoryRepository == null || user == null) {
            return;
        }
        subscriptionHistoryRepository.save(new SubscriptionHistory(
                user, eventType, fromPlan, toPlan, fromStatus, toStatus, stripeEventId, effectiveAt, details
        ));
    }

    private void emitNotification(User user, String type, String severity, String title,
                                  String message, String actionUrl, boolean sendEmail) {
        if (notificationService == null || user == null) {
            return;
        }
        notificationService.notifyUser(user, type, severity, title, message, actionUrl, sendEmail);
    }

    private boolean hasActiveStripeSubscription(Subscription sub) {
        return sub.getStripeSubscriptionId() != null
                && !sub.getStripeSubscriptionId().isBlank()
                && sub.getStatus() != null
                && ACTIVE_STRIPE_STATUSES.contains(sub.getStatus().toUpperCase());
    }

    private int tierRank(String planSlug) {
        if (planSlug == null) return 0;
        String lower = planSlug.trim().toLowerCase();
        if (lower.contains("pro") || lower.contains("enterprise")) return 2;
        if (lower.contains("plus")) return 1;
        return 0;
    }

    private String mapStripeStatus(String stripeStatus) {
        if (stripeStatus == null) return "ACTIVE";
        return switch (stripeStatus.toLowerCase()) {
            case "trialing" -> "TRIALING";
            case "active" -> "ACTIVE";
            case "past_due" -> "PAST_DUE";
            case "canceled" -> "CANCELED";
            case "unpaid", "incomplete_expired" -> "EXPIRED";
            default -> stripeStatus.toUpperCase();
        };
    }

    private String extractSubscriptionId(Invoice invoice) {
        Invoice.Parent parent = invoice.getParent();
        if (parent != null && "subscription_details".equals(parent.getType()) && parent.getSubscriptionDetails() != null) {
            return parent.getSubscriptionDetails().getSubscription();
        }
        return null;
    }

    private <T extends StripeObject> Optional<T> deserializeEventObject(Event event, Class<T> targetClass) {
        EventDataObjectDeserializer deserializer = event.getDataObjectDeserializer();
        Optional<StripeObject> obj = Optional.empty();
        try {
            obj = deserializer.getObject();
        } catch (Exception e) {
            log.debug("Standard deserialization skipped for event {}: {}", event.getId(), e.getMessage());
        }
        if (obj.isEmpty()) {
            try {
                obj = Optional.ofNullable(deserializer.deserializeUnsafe());
            } catch (Exception e) {
                log.warn("Could not deserialize Stripe webhook payload for event {}: {}", event.getId(), e.getMessage());
                return Optional.empty();
            }
        }
        return obj.filter(targetClass::isInstance).map(targetClass::cast);
    }

    private String normalizePlanSlug(String raw) {
        if (raw == null) throw new IllegalArgumentException("Plan slug is required.");
        String slug = raw.trim().toLowerCase();
        if (!"plus".equals(slug) && !"pro".equals(slug)) {
            throw new IllegalArgumentException("Paid Stripe checkout supports 'plus' or 'pro' plans only.");
        }
        return slug;
    }

    private String normalizeInterval(String raw) {
        if (raw == null) return "monthly";
        String interval = raw.trim().toLowerCase();
        if (!"monthly".equals(interval) && !"yearly".equals(interval)) {
            throw new IllegalArgumentException("Billing interval must be 'monthly' or 'yearly'.");
        }
        return interval;
    }

    private String sanitizeLocale(String locale) {
        return "ar".equalsIgnoreCase(locale) ? "ar" : "en";
    }

    private String sanitizeReturnPath(String rawPath) {
        if (rawPath == null || rawPath.isBlank()) {
            return "/dashboard/settings/subscription";
        }
        String path = rawPath.trim();
        if (!path.startsWith("/dashboard") || path.startsWith("//") || path.contains("://")) {
            return "/dashboard/settings/subscription";
        }
        int qIdx = path.indexOf('?');
        if (qIdx > 0) {
            path = path.substring(0, qIdx);
        }
        return path;
    }
}
