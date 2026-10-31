package com.afab.subscription;

import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EntitlementServiceTest {

    @Mock
    private PlanRepository planRepository;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private UsageCounterRepository usageCounterRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private EntitlementService entitlementService;

    private User testUser;
    private Plan freePlan;
    private Plan plusPlan;
    private Plan proPlan;
    private Subscription activeSubscription;
    private final String userEmail = "founder@enterprise.com";

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setEmail(userEmail);
        testUser.setPlanTier("FREE");

        freePlan = new Plan("Free", "free", BigDecimal.ZERO, BigDecimal.ZERO, "USD");
        freePlan.setId(UUID.randomUUID());
        freePlan.setEntitlements(List.of(
                new PlanEntitlement(freePlan, "ai.chat.queries_per_month", "QUOTA", "10"),
                new PlanEntitlement(freePlan, "invoices.per_month", "QUOTA", "5"),
                new PlanEntitlement(freePlan, "business.max", "LIMIT", "1"),
                new PlanEntitlement(freePlan, "forecast.cashflow", "BOOLEAN", "false")
        ));

        plusPlan = new Plan("Plus", "plus", new BigDecimal("9.99"), new BigDecimal("7.99"), "USD");
        plusPlan.setId(UUID.randomUUID());
        plusPlan.setEntitlements(List.of(
                new PlanEntitlement(plusPlan, "ai.chat.queries_per_month", "QUOTA", "100"),
                new PlanEntitlement(plusPlan, "invoices.per_month", "QUOTA", "50"),
                new PlanEntitlement(plusPlan, "business.max", "LIMIT", "3"),
                new PlanEntitlement(plusPlan, "forecast.cashflow", "BOOLEAN", "true")
        ));

        proPlan = new Plan("Pro", "pro", new BigDecimal("19.99"), new BigDecimal("15.99"), "USD");
        proPlan.setId(UUID.randomUUID());
        proPlan.setEntitlements(List.of(
                new PlanEntitlement(proPlan, "ai.chat.queries_per_month", "QUOTA", "300"),
                new PlanEntitlement(proPlan, "invoices.per_month", "QUOTA", "-1"), // unlimited
                new PlanEntitlement(proPlan, "business.max", "LIMIT", "5"),
                new PlanEntitlement(proPlan, "forecast.cashflow", "BOOLEAN", "true")
        ));

        activeSubscription = new Subscription(testUser, freePlan, "ACTIVE", Instant.now());
    }

    @Test
    @DisplayName("getEntitlementsSnapshot: returns plan details and current monthly quota usage")
    void testGetEntitlementsSnapshot() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));
        when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId()))
                .thenReturn(Optional.of(activeSubscription));

        lenient().when(usageCounterRepository.findByUserIdAndFeatureKeyAndPeriodStart(any(), any(), any()))
                .thenReturn(Optional.empty());

        UsageCounter invoiceCounter = new UsageCounter(testUser, "invoices.per_month", Instant.now(), 3);
        lenient().when(usageCounterRepository.findByUserIdAndFeatureKeyAndPeriodStart(eq(testUser.getId()), eq("invoices.per_month"), any()))
                .thenReturn(Optional.of(invoiceCounter));

        SubscriptionSnapshotDTO snapshot = entitlementService.getEntitlementsSnapshot(userEmail);

        assertThat(snapshot).isNotNull();
        assertThat(snapshot.getPlanSlug()).isEqualTo("free");
        assertThat(snapshot.getEntitlements()).containsEntry("invoices.per_month", 5);
        assertThat(snapshot.getEntitlements()).containsEntry("forecast.cashflow", false);
        assertThat(snapshot.getUsage()).containsEntry("invoices.per_month", 3);
    }

    @Test
    @DisplayName("check: throws PlanLimitReachedException when boolean feature is not allowed on Free plan")
    void testCheckBooleanFeatureDenied() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));
        when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId()))
                .thenReturn(Optional.of(activeSubscription));

        assertThatThrownBy(() -> entitlementService.check(userEmail, "forecast.cashflow"))
                .isInstanceOf(PlanLimitReachedException.class)
                .hasMessageContaining("forecast.cashflow");
    }

    @Test
    @DisplayName("consume: atomically increments usage and succeeds when quota is available")
    void testConsumeSuccess() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));
        when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId()))
                .thenReturn(Optional.of(activeSubscription));

        when(usageCounterRepository.atomicIncrement(eq(testUser.getId()), eq("invoices.per_month"), any(), eq(1), eq(5), any()))
                .thenReturn(1);

        entitlementService.consume(userEmail, "invoices.per_month", 1);

        verify(usageCounterRepository).atomicIncrement(eq(testUser.getId()), eq("invoices.per_month"), any(), eq(1), eq(5), any());
    }

    @Test
    @DisplayName("consume: throws PlanLimitReachedException when quota limit is exhausted")
    void testConsumeLimitExhausted() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));
        when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId()))
                .thenReturn(Optional.of(activeSubscription));

        when(usageCounterRepository.atomicIncrement(eq(testUser.getId()), eq("invoices.per_month"), any(), eq(1), eq(5), any()))
                .thenReturn(0);

        UsageCounter existing = new UsageCounter(testUser, "invoices.per_month", Instant.now(), 5);
        when(usageCounterRepository.findByUserIdAndFeatureKeyAndPeriodStart(eq(testUser.getId()), eq("invoices.per_month"), any()))
                .thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> entitlementService.consume(userEmail, "invoices.per_month", 1))
                .isInstanceOf(PlanLimitReachedException.class)
                .hasMessageContaining("invoices.per_month");
    }

    @Test
    @DisplayName("activateTrial: grants 7-day trial on Plus plan and updates user plan tier")
    void testActivateTrialSuccess() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));
        when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId()))
                .thenReturn(Optional.of(activeSubscription));
        when(planRepository.findBySlug("plus")).thenReturn(Optional.of(plusPlan));

        SubscriptionSnapshotDTO result = entitlementService.activateTrial(userEmail, "plus");

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("TRIALING");
        assertThat(activeSubscription.getStatus()).isEqualTo("TRIALING");
        assertThat(activeSubscription.getTrialEnd()).isAfter(Instant.now());
        assertThat(testUser.getPlanTier()).isEqualTo("PLUS");
        verify(subscriptionRepository).save(activeSubscription);
        verify(userRepository).save(testUser);
    }

    @Test
    @DisplayName("activateTrial: rejects second trial if trial has already been used")
    void testActivateTrialAlreadyUsed() {
        activeSubscription.setTrialEnd(Instant.now().minus(10, ChronoUnit.DAYS)); // Trial ended in past
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));
        when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId()))
                .thenReturn(Optional.of(activeSubscription));

        assertThatThrownBy(() -> entitlementService.activateTrial(userEmail, "plus"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("7-day trial has already been used");
    }

    @Test
    @DisplayName("reconcile: automatically reverts expired trial to Free plan")
    void testReconcileExpiredTrial() {
        activeSubscription.setPlan(plusPlan);
        activeSubscription.setStatus("TRIALING");
        activeSubscription.setTrialEnd(Instant.now().minus(1, ChronoUnit.DAYS)); // Expired yesterday

        when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId()))
                .thenReturn(Optional.of(activeSubscription));
        when(planRepository.findBySlug("free")).thenReturn(Optional.of(freePlan));
        when(subscriptionRepository.save(any(Subscription.class))).thenAnswer(i -> i.getArgument(0));

        Subscription reconciled = entitlementService.getOrReconcileSubscription(testUser);

        assertThat(reconciled.getStatus()).isEqualTo("ACTIVE");
        assertThat(reconciled.getPlan().getSlug()).isEqualTo("free");
        assertThat(testUser.getPlanTier()).isEqualTo("FREE");
        verify(subscriptionRepository).save(activeSubscription);
        verify(userRepository).save(testUser);
    }
}
