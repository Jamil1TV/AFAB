package com.afab.subscription.stripe;

import com.afab.subscription.*;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.subscription.stripe.dto.CheckoutRequest;
import com.afab.subscription.stripe.dto.CheckoutSessionResponse;
import com.afab.user.User;
import com.afab.user.UserRepository;
import com.stripe.StripeClient;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.model.Customer;
import com.stripe.model.Price;
import com.stripe.model.SubscriptionItem;
import com.stripe.model.SubscriptionItemCollection;
import com.stripe.param.CustomerCreateParams;
import com.stripe.param.checkout.SessionCreateParams;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Answers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StripeBillingServiceTest {

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

    private StripeProperties stripeProperties;
    private StripeBillingService billingService;

    private User testUser;
    private Plan freePlan;
    private Plan plusPlan;
    private Plan proPlan;
    private Subscription localSub;

    @BeforeEach
    void setUp() {
        stripeProperties = new StripeProperties();
        stripeProperties.setSecretKey("sk_test_dummy_key_for_unit_test");
        stripeProperties.setWebhookSecret("whsec_unit_test_secret");
        stripeProperties.setPortalConfigurationId("bpc_test_config");

        billingService = new StripeBillingService(
                stripeClientFactory,
                stripeProperties,
                userRepository,
                planRepository,
                subscriptionRepository,
                webhookEventRepository,
                entitlementService,
                "http://localhost:3000"
        );

        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setFirstName("Jamil");
        testUser.setLastName("Test");
        testUser.setEmail("founder@afab.test");
        testUser.setPlanTier("FREE");

        freePlan = new Plan("Free", "free", BigDecimal.ZERO, BigDecimal.ZERO, "USD");
        freePlan.setId(UUID.randomUUID());

        plusPlan = new Plan("Plus", "plus", new BigDecimal("9.99"), new BigDecimal("7.99"), "USD");
        plusPlan.setId(UUID.randomUUID());
        plusPlan.setStripeProductId("prod_plus_test");
        plusPlan.setStripePriceIdMonthly("price_plus_monthly_test");
        plusPlan.setStripePriceIdYearly("price_plus_yearly_test");

        proPlan = new Plan("Pro", "pro", new BigDecimal("19.99"), new BigDecimal("15.99"), "USD");
        proPlan.setId(UUID.randomUUID());
        proPlan.setStripeProductId("prod_pro_test");
        proPlan.setStripePriceIdMonthly("price_pro_monthly_test");
        proPlan.setStripePriceIdYearly("price_pro_yearly_test");

        localSub = new Subscription(testUser, freePlan, "ACTIVE", Instant.now());

        lenient().when(stripeClientFactory.getClient()).thenReturn(stripeClient);
        lenient().when(userRepository.findByEmail("founder@afab.test")).thenReturn(Optional.of(testUser));
        lenient().when(entitlementService.getOrReconcileSubscription(testUser)).thenReturn(localSub);
    }

    @Test
    @DisplayName("createCheckoutSession: creates Stripe customer and Checkout session with 7-day trial when eligible")
    void testCreateCheckoutWithTrial() throws Exception {
        when(planRepository.findBySlug("plus")).thenReturn(Optional.of(plusPlan));

        Customer mockCustomer = new Customer();
        mockCustomer.setId("cus_test_123");
        when(stripeClient.v1().customers().create(any(CustomerCreateParams.class))).thenReturn(mockCustomer);

        com.stripe.model.checkout.Session mockSession = new com.stripe.model.checkout.Session();
        mockSession.setId("cs_test_123");
        mockSession.setUrl("https://checkout.stripe.com/c/pay/cs_test_123");
        when(stripeClient.v1().checkout().sessions().create(any(SessionCreateParams.class))).thenReturn(mockSession);

        CheckoutRequest req = new CheckoutRequest();
        req.setPlanSlug("plus");
        req.setBillingInterval("monthly");
        req.setLocale("en");
        req.setReturnPath("/dashboard/plans");

        CheckoutSessionResponse res = billingService.createCheckoutSession("founder@afab.test", req);

        assertThat(res.getMode()).isEqualTo("CHECKOUT");
        assertThat(res.getSessionId()).isEqualTo("cs_test_123");
        assertThat(res.getUrl()).isEqualTo("https://checkout.stripe.com/c/pay/cs_test_123");
        assertThat(localSub.getStripeCustomerId()).isEqualTo("cus_test_123");
    }

    @Test
    @DisplayName("createCheckoutSession: redirects existing active subscriber to Customer Portal instead of double-billing")
    void testExistingSubscriberRedirectsToPortal() throws Exception {
        localSub.setStripeCustomerId("cus_existing_123");
        localSub.setStripeSubscriptionId("sub_existing_123");
        localSub.setStatus("ACTIVE");

        com.stripe.model.billingportal.Session portalSession = new com.stripe.model.billingportal.Session();
        portalSession.setUrl("https://billing.stripe.com/p/session/test_portal");
        when(stripeClient.v1().billingPortal().sessions()
                .create(any(com.stripe.param.billingportal.SessionCreateParams.class)))
                .thenReturn(portalSession);

        CheckoutRequest req = new CheckoutRequest();
        req.setPlanSlug("pro");
        req.setBillingInterval("yearly");

        CheckoutSessionResponse res = billingService.createCheckoutSession("founder@afab.test", req);

        assertThat(res.getMode()).isEqualTo("PORTAL");
        assertThat(res.getUrl()).isEqualTo("https://billing.stripe.com/p/session/test_portal");
    }

    @Test
    @DisplayName("syncFromStripeSubscription: upgrades local subscription to Pro and marks trialUsed=true")
    void testSyncStripeSubscription() {
        com.stripe.model.Subscription stripeSub = new com.stripe.model.Subscription();
        stripeSub.setId("sub_stripe_999");
        stripeSub.setCustomer("cus_stripe_999");
        stripeSub.setStatus("trialing");
        stripeSub.setTrialEnd(Instant.now().plusSeconds(7 * 86400L).getEpochSecond());
        stripeSub.setCancelAtPeriodEnd(false);
        stripeSub.setMetadata(Map.of("userId", testUser.getId().toString(), "planSlug", "pro"));

        Price price = new Price();
        price.setId("price_pro_yearly_test");
        Price.Recurring recurring = new Price.Recurring();
        recurring.setInterval("year");
        price.setRecurring(recurring);

        SubscriptionItem item = new SubscriptionItem();
        item.setPrice(price);
        item.setCurrentPeriodStart(1795000000L);
        item.setCurrentPeriodEnd(1798000000L);

        SubscriptionItemCollection items = new SubscriptionItemCollection();
        items.setData(List.of(item));
        stripeSub.setItems(items);

        when(planRepository.findByStripePriceIdMonthlyOrStripePriceIdYearly("price_pro_yearly_test", "price_pro_yearly_test"))
                .thenReturn(Optional.of(proPlan));
        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));

        billingService.syncFromStripeSubscription(stripeSub, null);

        assertThat(localSub.getPlan()).isEqualTo(proPlan);
        assertThat(localSub.getStatus()).isEqualTo("TRIALING");
        assertThat(localSub.getBillingInterval()).isEqualTo("YEARLY");
        assertThat(localSub.getStripeSubscriptionId()).isEqualTo("sub_stripe_999");
        assertThat(localSub.getTrialUsed()).isTrue();
        assertThat(testUser.getPlanTier()).isEqualTo("PRO");
        verify(subscriptionRepository).save(localSub);
        verify(userRepository).save(testUser);
    }

    @Test
    @DisplayName("handleWebhook: rejects invalid Stripe signature cleanly")
    void testWebhookInvalidSignature() {
        assertThatThrownBy(() -> billingService.handleWebhook("{\"id\":\"evt_1\"}", "t=123,v1=bad"))
                .isInstanceOf(SignatureVerificationException.class);
        verify(webhookEventRepository, never()).save(any());
    }

    @Test
    @DisplayName("handleWebhook: processes customer.subscription.deleted once and ignores duplicate deliveries")
    void testWebhookIdempotencyAndSubscriptionDeleted() throws Exception {
        localSub.setPlan(proPlan);
        localSub.setStripeCustomerId("cus_del_1");
        localSub.setStripeSubscriptionId("sub_del_1");
        localSub.setStatus("ACTIVE");
        testUser.setPlanTier("PRO");

        String payload = """
                {
                  "id": "evt_test_deleted_1",
                  "object": "event",
                  "api_version": "2026-09-30.endive",
                  "type": "customer.subscription.deleted",
                  "data": {
                    "object": {
                      "id": "sub_del_1",
                      "object": "subscription",
                      "customer": "cus_del_1",
                      "status": "canceled"
                    }
                  }
                }
                """;
        String sigHeader = signWebhookPayload(payload, stripeProperties.getWebhookSecret());

        when(webhookEventRepository.existsById("evt_test_deleted_1")).thenReturn(false).thenReturn(true);
        when(subscriptionRepository.findByStripeSubscriptionId("sub_del_1")).thenReturn(Optional.of(localSub));
        when(planRepository.findBySlug("free")).thenReturn(Optional.of(freePlan));

        // First delivery -> downgrades cleanly to Free
        billingService.handleWebhook(payload, sigHeader);

        assertThat(localSub.getPlan()).isEqualTo(freePlan);
        assertThat(localSub.getStripeSubscriptionId()).isNull();
        assertThat(localSub.getStatus()).isEqualTo("ACTIVE");
        assertThat(testUser.getPlanTier()).isEqualTo("FREE");
        verify(webhookEventRepository, times(1)).save(any(StripeWebhookEvent.class));

        // Duplicate delivery -> ignored idempotently
        billingService.handleWebhook(payload, sigHeader);
        verify(webhookEventRepository, times(1)).save(any(StripeWebhookEvent.class));
    }

    @Test
    @DisplayName("handleWebhook: marks subscription PAST_DUE on invoice.payment_failed")
    void testWebhookInvoicePaymentFailed() throws Exception {
        localSub.setPlan(plusPlan);
        localSub.setStripeCustomerId("cus_past_1");
        localSub.setStripeSubscriptionId("sub_past_1");
        localSub.setStatus("ACTIVE");

        String payload = """
                {
                  "id": "evt_test_failed_1",
                  "object": "event",
                  "api_version": "2026-09-30.endive",
                  "type": "invoice.payment_failed",
                  "data": {
                    "object": {
                      "id": "in_test_1",
                      "object": "invoice",
                      "customer": "cus_past_1",
                      "parent": {
                        "type": "subscription_details",
                        "subscription_details": {
                          "subscription": "sub_past_1"
                        }
                      }
                    }
                  }
                }
                """;
        String sigHeader = signWebhookPayload(payload, stripeProperties.getWebhookSecret());

        when(webhookEventRepository.existsById("evt_test_failed_1")).thenReturn(false);
        when(subscriptionRepository.findByStripeSubscriptionId("sub_past_1")).thenReturn(Optional.of(localSub));

        billingService.handleWebhook(payload, sigHeader);

        assertThat(localSub.getStatus()).isEqualTo("PAST_DUE");
        verify(subscriptionRepository).save(localSub);
        verify(webhookEventRepository).save(any(StripeWebhookEvent.class));
    }

    @Test
    @DisplayName("verifyCheckoutSession: rejects verifying another user's checkout session")
    void testVerifyOwnershipCheck() throws Exception {
        com.stripe.model.checkout.Session session = new com.stripe.model.checkout.Session();
        session.setId("cs_other_user");
        session.setClientReferenceId(UUID.randomUUID().toString());
        session.setCustomer("cus_other_user");
        when(stripeClient.v1().checkout().sessions().retrieve("cs_other_user")).thenReturn(session);

        assertThatThrownBy(() -> billingService.verifyCheckoutSession("founder@afab.test", "cs_other_user"))
                .isInstanceOf(com.afab.common.exception.ForbiddenException.class);
    }

    private String signWebhookPayload(String payload, String secret) throws Exception {
        long timestamp = Instant.now().getEpochSecond();
        String signedPayload = timestamp + "." + payload;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] hash = mac.doFinal(signedPayload.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) {
            hex.append(String.format("%02x", b));
        }
        return "t=" + timestamp + ",v1=" + hex;
    }
}
