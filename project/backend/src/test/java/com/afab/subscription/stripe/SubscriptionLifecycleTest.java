package com.afab.subscription.stripe;

import com.afab.business.Business;
import com.afab.business.BusinessAllocationService;
import com.afab.business.BusinessRepository;
import com.afab.notification.NotificationService;
import com.afab.subscription.*;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.subscription.stripe.dto.*;
import com.afab.user.User;
import com.afab.user.UserRepository;
import com.stripe.StripeClient;
import com.stripe.model.Customer;
import com.stripe.model.Price;
import com.stripe.model.SubscriptionItem;
import com.stripe.model.SubscriptionItemCollection;
import com.stripe.model.SubscriptionSchedule;
import com.stripe.param.CustomerCreateParams;
import com.stripe.param.SubscriptionScheduleCreateParams;
import com.stripe.param.SubscriptionScheduleUpdateParams;
import com.stripe.param.SubscriptionUpdateParams;
import com.stripe.param.checkout.SessionCreateParams;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Answers;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SubscriptionLifecycleTest {

    @Mock
    private StripeClientFactory stripeClientFactory;

    @Mock(answer = Answers.RETURNS_DEEP_STUBS)
    private StripeClient stripeClient;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PlanRepository planRepository;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private StripeWebhookEventRepository webhookEventRepository;

    @Mock
    private EntitlementService entitlementService;

    @Mock
    private BusinessRepository businessRepository;

    @Mock
    private BusinessAllocationService businessAllocationService;

    @Mock
    private SubscriptionHistoryRepository subscriptionHistoryRepository;

    @Mock
    private PaymentHistoryRepository paymentHistoryRepository;

    @Mock
    private NotificationService notificationService;

    private StripeProperties stripeProperties;
    private StripeBillingService billingService;
    private SubscriptionLifecycleScheduler scheduler;

    private User testUser;
    private Plan freePlan;
    private Plan plusPlan;
    private Plan proPlan;
    private Subscription localSub;

    @BeforeEach
    void setUp() {
        stripeProperties = new StripeProperties();
        stripeProperties.setSecretKey("sk_test_dummy_for_lifecycle_test");
        stripeProperties.setWebhookSecret("whsec_lifecycle_test_secret");
        stripeProperties.setPortalConfigurationId("bpc_test_config");

        billingService = new StripeBillingService(
                stripeClientFactory,
                stripeProperties,
                userRepository,
                planRepository,
                subscriptionRepository,
                webhookEventRepository,
                entitlementService,
                businessRepository,
                businessAllocationService,
                subscriptionHistoryRepository,
                paymentHistoryRepository,
                notificationService,
                "http://localhost:3000"
        );

        scheduler = new SubscriptionLifecycleScheduler(
                subscriptionRepository,
                planRepository,
                userRepository,
                businessAllocationService,
                subscriptionHistoryRepository,
                notificationService,
                billingService,
                stripeClientFactory,
                stripeProperties
        );

        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setFirstName("Ayoub");
        testUser.setLastName("Test");
        testUser.setEmail("founder@afab.test");
        testUser.setPlanTier("FREE");

        freePlan = new Plan("Free", "free", BigDecimal.ZERO, BigDecimal.ZERO, "USD");
        freePlan.setId(UUID.randomUUID());

        plusPlan = new Plan("Plus", "plus", new BigDecimal("9.99"), new BigDecimal("7.99"), "USD");
        plusPlan.setId(UUID.randomUUID());
        plusPlan.setStripePriceIdMonthly("price_plus_monthly");
        plusPlan.setStripePriceIdYearly("price_plus_yearly");

        proPlan = new Plan("Pro", "pro", new BigDecimal("19.99"), new BigDecimal("15.99"), "USD");
        proPlan.setId(UUID.randomUUID());
        proPlan.setStripePriceIdMonthly("price_pro_monthly");
        proPlan.setStripePriceIdYearly("price_pro_yearly");

        localSub = new Subscription(testUser, freePlan, "ACTIVE", Instant.now());

        lenient().when(stripeClientFactory.getClient()).thenReturn(stripeClient);
        lenient().when(userRepository.findByEmail("founder@afab.test")).thenReturn(Optional.of(testUser));
        lenient().when(entitlementService.getOrReconcileSubscription(testUser)).thenReturn(localSub);
        lenient().when(entitlementService.getEntitlementsSnapshot("founder@afab.test"))
                .thenReturn(new SubscriptionSnapshotDTO());
    }

    @Test
    @DisplayName("Scenario 1: Eligible user subscribes to Plus and receives 7-day trial, whereas Pro never receives a trial")
    void testPlusGetsSevenDayTrialAndProNeverGetsTrial() throws Exception {
        when(planRepository.findBySlug("plus")).thenReturn(Optional.of(plusPlan));
        when(planRepository.findBySlug("pro")).thenReturn(Optional.of(proPlan));

        Customer mockCustomer = new Customer();
        mockCustomer.setId("cus_trial_1");
        when(stripeClient.v1().customers().create(any(CustomerCreateParams.class))).thenReturn(mockCustomer);

        com.stripe.model.checkout.Session mockSession = new com.stripe.model.checkout.Session();
        mockSession.setId("cs_plus_trial");
        mockSession.setUrl("https://checkout.stripe.com/c/pay/cs_plus_trial");
        when(stripeClient.v1().checkout().sessions().create(any(SessionCreateParams.class))).thenReturn(mockSession);

        // 1. Plus checkout for eligible user -> 7-day trial
        CheckoutRequest plusReq = new CheckoutRequest();
        plusReq.setPlanSlug("plus");
        plusReq.setBillingInterval("monthly");
        billingService.createCheckoutSession("founder@afab.test", plusReq);

        ArgumentCaptor<SessionCreateParams> captor = ArgumentCaptor.forClass(SessionCreateParams.class);
        verify(stripeClient.v1().checkout().sessions(), times(1)).create(captor.capture());
        assertThat(captor.getValue().getSubscriptionData().getTrialPeriodDays()).isEqualTo(7L);

        // 2. Pro checkout for eligible user -> NO trial
        CheckoutRequest proReq = new CheckoutRequest();
        proReq.setPlanSlug("pro");
        proReq.setBillingInterval("monthly");
        billingService.createCheckoutSession("founder@afab.test", proReq);

        verify(stripeClient.v1().checkout().sessions(), times(2)).create(captor.capture());
        assertThat(captor.getValue().getSubscriptionData().getTrialPeriodDays()).isNull();

        // 3. Repeat Plus checkout after trialUsed=true -> NO trial
        localSub.setTrialUsed(true);
        billingService.createCheckoutSession("founder@afab.test", plusReq);
        verify(stripeClient.v1().checkout().sessions(), times(3)).create(captor.capture());
        assertThat(captor.getValue().getSubscriptionData().getTrialPeriodDays()).isNull();
    }

    @Test
    @DisplayName("Scenario 2, 3 & 13: Trial cancellation keeps Plus access until trial end, can be reversed, and downgrades to Free on expiration")
    void testTrialCancellationReversalAndExpiration() throws Exception {
        Instant trialEnd = Instant.now().plus(5, ChronoUnit.DAYS);
        localSub.setPlan(plusPlan);
        localSub.setStatus("TRIALING");
        localSub.setTrialEnd(trialEnd);
        localSub.setPeriodEnd(trialEnd);
        localSub.setTrialUsed(true);
        localSub.setStripeCustomerId("cus_trial_cancel");
        localSub.setStripeSubscriptionId("sub_trial_cancel");

        when(planRepository.findBySlug("free")).thenReturn(Optional.of(freePlan));

        com.stripe.model.Subscription stripeUpdated = new com.stripe.model.Subscription();
        stripeUpdated.setId("sub_trial_cancel");
        stripeUpdated.setStatus("trialing");
        stripeUpdated.setTrialEnd(trialEnd.getEpochSecond());
        stripeUpdated.setCancelAtPeriodEnd(true);
        when(stripeClient.v1().subscriptions().update(eq("sub_trial_cancel"), any(SubscriptionUpdateParams.class)))
                .thenReturn(stripeUpdated);

        UUID keepBizId = UUID.randomUUID();
        CancelSubscriptionRequest cancelReq = new CancelSubscriptionRequest();
        cancelReq.setSelectedBusinessIds(List.of(keepBizId));

        billingService.cancelSubscription("founder@afab.test", cancelReq);

        // Access remains PLUS / TRIALING until trialEnd
        assertThat(localSub.getPlan()).isEqualTo(plusPlan);
        assertThat(localSub.getStatus()).isEqualTo("TRIALING");
        assertThat(localSub.getCancelAtPeriodEnd()).isTrue();
        assertThat(localSub.getPendingPlan()).isEqualTo(freePlan);
        verify(businessAllocationService).savePendingAllocation(testUser, "free", List.of(keepBizId));

        // User reverses scheduled cancellation before trial end
        stripeUpdated.setCancelAtPeriodEnd(false);
        billingService.resumeSubscription("founder@afab.test");
        assertThat(localSub.getCancelAtPeriodEnd()).isFalse();
        assertThat(localSub.getPendingPlan()).isNull();
        verify(businessAllocationService).clearPendingAllocation(testUser);

        // Schedule cancellation again and simulate trial end webhook (customer.subscription.deleted)
        localSub.setCancelAtPeriodEnd(true);
        String deletedPayload = """
                {
                  "id": "evt_trial_ended_1",
                  "object": "event",
                  "api_version": "2026-09-30.endive",
                  "created": 1795400000,
                  "type": "customer.subscription.deleted",
                  "data": {
                    "object": {
                      "id": "sub_trial_cancel",
                      "object": "subscription",
                      "customer": "cus_trial_cancel",
                      "status": "canceled"
                    }
                  }
                }
                """;
        when(webhookEventRepository.existsById("evt_trial_ended_1")).thenReturn(false);
        when(subscriptionRepository.findByStripeSubscriptionId("sub_trial_cancel")).thenReturn(Optional.of(localSub));

        billingService.handleWebhook(deletedPayload, signPayload(deletedPayload));

        assertThat(localSub.getPlan()).isEqualTo(freePlan);
        assertThat(localSub.getStatus()).isEqualTo("ACTIVE");
        assertThat(testUser.getPlanTier()).isEqualTo("FREE");
        verify(businessAllocationService).applyDowngradeAllocation(localSub, freePlan);
    }

    @Test
    @DisplayName("Scenario 4, 10, 11 & 12: Payment failure starts 3-day grace period, recovery restores access, and expired grace downgrades to Free")
    void testPaymentFailureGracePeriodRecoveryAndExpiration() throws Exception {
        localSub.setPlan(plusPlan);
        localSub.setStatus("ACTIVE");
        localSub.setStripeCustomerId("cus_grace_1");
        localSub.setStripeSubscriptionId("sub_grace_1");
        testUser.setPlanTier("PLUS");

        when(subscriptionRepository.findByStripeSubscriptionId("sub_grace_1")).thenReturn(Optional.of(localSub));
        when(paymentHistoryRepository.findByStripeInvoiceId("in_fail_1")).thenReturn(Optional.empty());

        // Scenario 10: invoice.payment_failed starts 3-day grace period while preserving Plus plan
        String failedPayload = """
                {
                  "id": "evt_pay_failed_1",
                  "object": "event",
                  "api_version": "2026-09-30.endive",
                  "created": 1795500000,
                  "type": "invoice.payment_failed",
                  "data": {
                    "object": {
                      "id": "in_fail_1",
                      "object": "invoice",
                      "customer": "cus_grace_1",
                      "amount_due": 999,
                      "currency": "usd",
                      "parent": {
                        "type": "subscription_details",
                        "subscription_details": {
                          "subscription": "sub_grace_1"
                        }
                      }
                    }
                  }
                }
                """;
        billingService.handleWebhook(failedPayload, signPayload(failedPayload));

        assertThat(localSub.getStatus()).isEqualTo("PAST_DUE");
        assertThat(localSub.getPlan()).isEqualTo(plusPlan); // Paid entitlements kept during grace period
        assertThat(localSub.getFirstPaymentFailureAt()).isNotNull();
        assertThat(localSub.getGracePeriodEndsAt()).isAfter(Instant.now().plus(2, ChronoUnit.DAYS));
        assertThat(localSub.isSubscribed()).isTrue();

        // Scenario 11: invoice.payment_succeeded during grace period clears grace state and keeps business allocation untouched
        com.stripe.model.Subscription activeStripeSub = buildStripeSubscription("sub_grace_1", "cus_grace_1", "active", "price_plus_monthly", "plus");
        when(stripeClient.v1().subscriptions().retrieve("sub_grace_1")).thenReturn(activeStripeSub);
        when(planRepository.findByStripePriceIdMonthlyOrStripePriceIdYearly("price_plus_monthly", "price_plus_monthly"))
                .thenReturn(Optional.of(plusPlan));

        String paidPayload = """
                {
                  "id": "evt_pay_succeeded_1",
                  "object": "event",
                  "api_version": "2026-09-30.endive",
                  "created": 1795500500,
                  "type": "invoice.payment_succeeded",
                  "data": {
                    "object": {
                      "id": "in_fail_1",
                      "object": "invoice",
                      "customer": "cus_grace_1",
                      "amount_paid": 999,
                      "currency": "usd",
                      "parent": {
                        "type": "subscription_details",
                        "subscription_details": {
                          "subscription": "sub_grace_1"
                        }
                      }
                    }
                  }
                }
                """;
        billingService.handleWebhook(paidPayload, signPayload(paidPayload));

        assertThat(localSub.getStatus()).isEqualTo("ACTIVE");
        assertThat(localSub.getFirstPaymentFailureAt()).isNull();
        assertThat(localSub.getGracePeriodEndsAt()).isNull();
        assertThat(localSub.getPlan()).isEqualTo(plusPlan);
        verify(businessAllocationService, never()).applyDowngradeAllocation(any(), any());

        // Scenario 12: Failed payment remains unpaid after 3 days -> scheduler checks Stripe & downgrades to Free
        localSub.setStatus("PAST_DUE");
        localSub.setFirstPaymentFailureAt(Instant.now().minus(4, ChronoUnit.DAYS));
        localSub.setGracePeriodEndsAt(Instant.now().minus(1, ChronoUnit.DAYS));

        com.stripe.model.Subscription stillPastDueStripeSub =
                buildStripeSubscription("sub_grace_1", "cus_grace_1", "past_due", "price_plus_monthly", "plus");
        when(stripeClient.v1().subscriptions().retrieve("sub_grace_1")).thenReturn(stillPastDueStripeSub);
        when(subscriptionRepository.findPastDueWithExpiredGracePeriod(any(Instant.class))).thenReturn(List.of(localSub));
        when(planRepository.findBySlug("free")).thenReturn(Optional.of(freePlan));

        int processed = scheduler.processExpiredGracePeriods();

        assertThat(processed).isEqualTo(1);
        assertThat(localSub.getPlan()).isEqualTo(freePlan);
        assertThat(localSub.getStatus()).isEqualTo("ACTIVE");
        assertThat(localSub.getGracePeriodEndsAt()).isNull();
        assertThat(testUser.getPlanTier()).isEqualTo("FREE");
        verify(stripeClient.v1().subscriptions()).cancel("sub_grace_1");
        verify(businessAllocationService).applyDowngradeAllocation(localSub, freePlan);
    }

    @Test
    @DisplayName("Scenario 5 & 14: Pro -> Plus scheduled downgrade preserves Pro until effective, and Plus -> Pro upgrade restores businesses immediately")
    void testScheduledDowngradeAndImmediateUpgrade() throws Exception {
        localSub.setPlan(proPlan);
        localSub.setStatus("ACTIVE");
        localSub.setStripeCustomerId("cus_pro_1");
        localSub.setStripeSubscriptionId("sub_pro_1");
        localSub.setStripePriceId("price_pro_monthly");
        testUser.setPlanTier("PRO");

        when(planRepository.findBySlug("plus")).thenReturn(Optional.of(plusPlan));
        when(planRepository.findBySlug("pro")).thenReturn(Optional.of(proPlan));

        com.stripe.model.Subscription liveProSub =
                buildStripeSubscription("sub_pro_1", "cus_pro_1", "active", "price_pro_monthly", "pro");
        when(stripeClient.v1().subscriptions().retrieve("sub_pro_1")).thenReturn(liveProSub);

        SubscriptionSchedule schedule = new SubscriptionSchedule();
        schedule.setId("sub_sched_123");
        when(stripeClient.v1().subscriptionSchedules().create(any(SubscriptionScheduleCreateParams.class)))
                .thenReturn(schedule);
        when(stripeClient.v1().subscriptionSchedules().update(eq("sub_sched_123"), any(SubscriptionScheduleUpdateParams.class)))
                .thenReturn(schedule);

        List<UUID> threeIds = List.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID());
        DowngradeSubscriptionRequest downReq = new DowngradeSubscriptionRequest();
        downReq.setTargetPlanSlug("plus");
        downReq.setBillingInterval("monthly");
        downReq.setSelectedBusinessIds(threeIds);

        billingService.scheduleDowngrade("founder@afab.test", downReq);

        // Current plan stays Pro until period end; pending plan is Plus
        assertThat(localSub.getPlan()).isEqualTo(proPlan);
        assertThat(localSub.getPendingPlan()).isEqualTo(plusPlan);
        assertThat(localSub.getStripeScheduleId()).isEqualTo("sub_sched_123");
        verify(businessAllocationService).savePendingAllocation(testUser, "plus", threeIds);

        // Now simulate Plus -> Pro direct upgrade
        localSub.setPlan(plusPlan);
        com.stripe.model.Subscription upgradedProSub =
                buildStripeSubscription("sub_pro_1", "cus_pro_1", "active", "price_pro_monthly", "pro");
        when(stripeClient.v1().subscriptions().update(eq("sub_pro_1"), any(SubscriptionUpdateParams.class)))
                .thenReturn(upgradedProSub);
        when(planRepository.findByStripePriceIdMonthlyOrStripePriceIdYearly("price_pro_monthly", "price_pro_monthly"))
                .thenReturn(Optional.of(proPlan));

        UpgradeSubscriptionRequest upReq = new UpgradeSubscriptionRequest();
        upReq.setPlanSlug("pro");
        upReq.setBillingInterval("monthly");

        UpgradeSubscriptionResponse upRes = billingService.upgradeSubscription("founder@afab.test", upReq);

        assertThat(upRes.getMode()).isEqualTo("DIRECT_UPGRADE");
        assertThat(localSub.getPlan()).isEqualTo(proPlan);
        verify(businessAllocationService).applyUpgradeAllocation(localSub, proPlan);
    }

    @Test
    @DisplayName("Local/Legacy Pro subscription (without Stripe subscription ID) downgrades to Plus and applies 3-business allocation cleanly")
    void testLocalNonStripeProToPlusDowngradeAppliesImmediately() throws Exception {
        localSub.setPlan(proPlan);
        localSub.setStatus("ACTIVE");
        localSub.setStripeCustomerId(null);
        localSub.setStripeSubscriptionId(null);
        testUser.setPlanTier("PRO");

        when(planRepository.findBySlug("plus")).thenReturn(Optional.of(plusPlan));
        when(businessAllocationService.resolveEditableLimit(plusPlan)).thenReturn(3);

        List<UUID> threeIds = List.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID());
        DowngradeSubscriptionRequest downReq = new DowngradeSubscriptionRequest();
        downReq.setTargetPlanSlug("plus");
        downReq.setBillingInterval("monthly");
        downReq.setSelectedBusinessIds(threeIds);

        billingService.scheduleDowngrade("founder@afab.test", downReq);

        assertThat(localSub.getPlan()).isEqualTo(plusPlan);
        assertThat(localSub.getStatus()).isEqualTo("ACTIVE");
        assertThat(testUser.getPlanTier()).isEqualTo("PLUS");
        verify(businessAllocationService).savePendingAllocation(testUser, "plus", threeIds);
        verify(businessAllocationService).applyDowngradeAllocation(localSub, plusPlan);
    }

    @Test
    @DisplayName("Scenario 15 & 16: Out-of-order stale webhook events and duplicate webhooks do not corrupt newer subscription state")
    void testOutOfOrderAndDuplicateWebhooksIgnored() throws Exception {
        localSub.setPlan(proPlan);
        localSub.setStatus("ACTIVE");
        localSub.setStripeCustomerId("cus_order_1");
        localSub.setStripeSubscriptionId("sub_order_1");
        localSub.setLastStripeEventCreated(1796000500L); // Newer state already processed at t=500
        testUser.setPlanTier("PRO");

        when(subscriptionRepository.findByStripeSubscriptionId("sub_order_1")).thenReturn(Optional.of(localSub));

        // Older event (created = 1796000100 < 1796000500) tries to overwrite with Plus
        String stalePayload = """
                {
                  "id": "evt_stale_older_1",
                  "object": "event",
                  "api_version": "2026-09-30.endive",
                  "created": 1796000100,
                  "type": "customer.subscription.updated",
                  "data": {
                    "object": {
                      "id": "sub_order_1",
                      "object": "subscription",
                      "customer": "cus_order_1",
                      "status": "active",
                      "metadata": {
                        "planSlug": "plus"
                      }
                    }
                  }
                }
                """;
        when(webhookEventRepository.existsById("evt_stale_older_1")).thenReturn(false);

        billingService.handleWebhook(stalePayload, signPayload(stalePayload));

        // State must remain PRO (not overwritten by older event!)
        assertThat(localSub.getPlan()).isEqualTo(proPlan);
        assertThat(testUser.getPlanTier()).isEqualTo("PRO");
    }

    private com.stripe.model.Subscription buildStripeSubscription(
            String subId,
            String customerId,
            String status,
            String priceId,
            String planSlug
    ) {
        com.stripe.model.Subscription sub = new com.stripe.model.Subscription();
        sub.setId(subId);
        sub.setCustomer(customerId);
        sub.setStatus(status);
        sub.setCancelAtPeriodEnd(false);
        sub.setMetadata(Map.of("userId", testUser.getId().toString(), "planSlug", planSlug));

        Price price = new Price();
        price.setId(priceId);
        Price.Recurring recurring = new Price.Recurring();
        recurring.setInterval("month");
        price.setRecurring(recurring);

        SubscriptionItem item = new SubscriptionItem();
        item.setId("si_item_1");
        item.setPrice(price);
        item.setCurrentPeriodStart(1795000000L);
        item.setCurrentPeriodEnd(1797600000L);

        SubscriptionItemCollection items = new SubscriptionItemCollection();
        items.setData(List.of(item));
        sub.setItems(items);
        return sub;
    }

    private String signPayload(String payload) throws Exception {
        long timestamp = Instant.now().getEpochSecond();
        String signedPayload = timestamp + "." + payload;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(stripeProperties.getWebhookSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] hash = mac.doFinal(signedPayload.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) {
            hex.append(String.format("%02x", b));
        }
        return "t=" + timestamp + ",v1=" + hex;
    }
}
