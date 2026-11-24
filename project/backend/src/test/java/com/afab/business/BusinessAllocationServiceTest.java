package com.afab.business;

import com.afab.business.dto.BusinessAllocationDTO;
import com.afab.common.exception.ForbiddenException;
import com.afab.subscription.*;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BusinessAllocationServiceTest {

    @Mock
    private BusinessRepository businessRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private PlanRepository planRepository;

    @Mock
    private PendingBusinessAllocationRepository pendingAllocationRepository;

    @Mock
    private SubscriptionHistoryRepository subscriptionHistoryRepository;

    private BusinessAllocationService allocationService;

    private User testUser;
    private Plan freePlan;
    private Plan plusPlan;
    private Plan proPlan;
    private Subscription subscription;
    private List<Business> fiveBusinesses;

    @BeforeEach
    void setUp() {
        allocationService = new BusinessAllocationService(
                businessRepository,
                userRepository,
                subscriptionRepository,
                planRepository,
                pendingAllocationRepository,
                subscriptionHistoryRepository
        );

        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setEmail("owner@afab.test");
        testUser.setPlanTier("PRO");

        freePlan = new Plan("Free", "free", BigDecimal.ZERO, BigDecimal.ZERO, "USD");
        freePlan.setEntitlements(List.of(new PlanEntitlement(freePlan, "business.max", "LIMIT", "1")));

        plusPlan = new Plan("Plus", "plus", new BigDecimal("9.99"), new BigDecimal("7.99"), "USD");
        plusPlan.setEntitlements(List.of(new PlanEntitlement(plusPlan, "business.max", "LIMIT", "3")));

        proPlan = new Plan("Pro", "pro", new BigDecimal("19.99"), new BigDecimal("15.99"), "USD");
        proPlan.setEntitlements(List.of(new PlanEntitlement(proPlan, "business.max", "LIMIT", "5")));

        subscription = new Subscription(testUser, proPlan, "ACTIVE", Instant.now());

        fiveBusinesses = new ArrayList<>();
        for (int i = 1; i <= 5; i++) {
            Business b = new Business(testUser, "Business #" + i, "USD");
            b.setId(UUID.randomUUID());
            b.setPrimary(i == 1);
            b.setAccessMode("EDITABLE");
            fiveBusinesses.add(b);
        }
        testUser.setActiveBusinessId(fiveBusinesses.get(0).getId());

        lenient().when(userRepository.findByEmail("owner@afab.test")).thenReturn(Optional.of(testUser));
        lenient().when(subscriptionRepository.findForUpdateByUserId(testUser.getId())).thenReturn(Optional.of(subscription));
        lenient().when(subscriptionRepository.findWithPlanAndEntitlementsByUserId(testUser.getId())).thenReturn(Optional.of(subscription));
    }

    @Test
    @DisplayName("Scenario 5: Pro -> Plus downgrade applies customer's any 3 selected businesses as EDITABLE and 2 as READ_ONLY")
    void testProToPlusDowngradeAppliesAnyThreeSelectedBusinesses() {
        when(businessRepository.findAllOwnedActiveByUserId(testUser.getId())).thenReturn(fiveBusinesses);

        // User chooses businesses #2, #4, #5 (not the first 3 created!)
        List<Business> chosen = List.of(fiveBusinesses.get(1), fiveBusinesses.get(3), fiveBusinesses.get(4));
        List<UUID> chosenIds = chosen.stream().map(Business::getId).toList();

        allocationService.savePendingAllocation(testUser, "plus", chosenIds);

        // Before effective date, all 5 remain EDITABLE
        assertThat(fiveBusinesses).allMatch(Business::isEditable);

        List<PendingBusinessAllocation> savedPending = chosen.stream()
                .map(b -> new PendingBusinessAllocation(testUser, b, "plus"))
                .toList();
        when(pendingAllocationRepository.findAllWithBusinessByUserId(testUser.getId())).thenReturn(savedPending);

        // Apply downgrade when billing period ends
        boolean attentionRequired = allocationService.applyDowngradeAllocation(subscription, plusPlan);

        assertThat(attentionRequired).isFalse();
        assertThat(fiveBusinesses.get(0).isEditable()).isFalse();
        assertThat(fiveBusinesses.get(1).isEditable()).isTrue();
        assertThat(fiveBusinesses.get(2).isEditable()).isFalse();
        assertThat(fiveBusinesses.get(3).isEditable()).isTrue();
        assertThat(fiveBusinesses.get(4).isEditable()).isTrue();
        assertThat(fiveBusinesses).hasSize(5); // All 5 preserved!
        // User's previously active business (#1) was locked -> auto-switched to unlocked primary (#2)
        assertThat(testUser.getActiveBusinessId()).isEqualTo(fiveBusinesses.get(1).getId());
    }

    @Test
    @DisplayName("Scenario 6: Plus -> Free downgrade keeps selected 1 of 3 businesses EDITABLE and sets 2 READ_ONLY")
    void testPlusToFreeDowngradeSelectsOneOfThree() {
        List<Business> threeBusinesses = fiveBusinesses.subList(0, 3);
        subscription.setPlan(plusPlan);
        when(businessRepository.findAllOwnedActiveByUserId(testUser.getId())).thenReturn(threeBusinesses);

        Business selected = threeBusinesses.get(2); // 3rd business chosen
        when(pendingAllocationRepository.findAllWithBusinessByUserId(testUser.getId()))
                .thenReturn(List.of(new PendingBusinessAllocation(testUser, selected, "free")));

        boolean attention = allocationService.applyDowngradeAllocation(subscription, freePlan);

        assertThat(attention).isFalse();
        assertThat(threeBusinesses.get(0).isEditable()).isFalse();
        assertThat(threeBusinesses.get(1).isEditable()).isFalse();
        assertThat(threeBusinesses.get(2).isEditable()).isTrue();
        assertThat(threeBusinesses.get(2).isPrimary()).isTrue();
    }

    @Test
    @DisplayName("Scenario 7: Pro -> Free without prior selection keeps designated primary business EDITABLE and flags attention")
    void testProToFreeWithoutSelectionKeepsPrimaryEditable() {
        when(businessRepository.findAllOwnedActiveByUserId(testUser.getId())).thenReturn(fiveBusinesses);
        when(pendingAllocationRepository.findAllWithBusinessByUserId(testUser.getId())).thenReturn(List.of());

        boolean attention = allocationService.applyDowngradeAllocation(subscription, freePlan);

        assertThat(attention).isTrue();
        assertThat(subscription.getAllocationAttentionRequired()).isTrue();
        assertThat(fiveBusinesses.get(0).isEditable()).isTrue();
        assertThat(fiveBusinesses.subList(1, 5)).allMatch(b -> "READ_ONLY".equals(b.getAccessMode()));
    }

    @Test
    @DisplayName("Scenario 8: Plus customer swaps an editable business with a read-only business within plan limit (3)")
    void testSwapEditableBusinessWithinPlanLimit() {
        subscription.setPlan(plusPlan);
        fiveBusinesses.get(0).setAccessMode("EDITABLE");
        fiveBusinesses.get(1).setAccessMode("EDITABLE");
        fiveBusinesses.get(2).setAccessMode("EDITABLE");
        fiveBusinesses.get(3).setAccessMode("READ_ONLY");
        fiveBusinesses.get(4).setAccessMode("READ_ONLY");

        when(businessRepository.findAllOwnedActiveByUserId(testUser.getId())).thenReturn(fiveBusinesses);
        when(pendingAllocationRepository.findAllWithBusinessByUserId(testUser.getId())).thenReturn(List.of());

        // Replace Business #3 with Business #5
        List<UUID> newSelection = List.of(
                fiveBusinesses.get(0).getId(),
                fiveBusinesses.get(1).getId(),
                fiveBusinesses.get(4).getId()
        );

        BusinessAllocationDTO result = allocationService.updateCurrentAllocation("owner@afab.test", newSelection, null);

        assertThat(result.getEditableCount()).isEqualTo(3);
        assertThat(result.getReadOnlyCount()).isEqualTo(2);
        assertThat(fiveBusinesses.get(2).isEditable()).isFalse();
        assertThat(fiveBusinesses.get(4).isEditable()).isTrue();
    }

    @Test
    @DisplayName("Security: rejects allocating another user's business ID or exceeding active plan limit")
    void testRejectsForeignBusinessAndPlanLimitOverflow() {
        subscription.setPlan(freePlan);
        when(businessRepository.findAllOwnedActiveByUserId(testUser.getId())).thenReturn(fiveBusinesses);

        // Foreign business UUID not owned by testUser
        assertThatThrownBy(() -> allocationService.updateCurrentAllocation(
                "owner@afab.test", List.of(UUID.randomUUID()), null))
                .isInstanceOf(ForbiddenException.class);

        // Selecting 2 businesses on Free plan (limit 1)
        assertThatThrownBy(() -> allocationService.updateCurrentAllocation(
                "owner@afab.test",
                List.of(fiveBusinesses.get(0).getId(), fiveBusinesses.get(1).getId()),
                null))
                .isInstanceOf(PlanLimitReachedException.class);
    }

    @Test
    @DisplayName("Scenario 14: Upgrading Free -> Plus (3) and Plus -> Pro (5) restores previously READ_ONLY businesses")
    void testUpgradeRestoresReadOnlyBusinesses() {
        fiveBusinesses.get(0).setAccessMode("EDITABLE");
        for (int i = 1; i < 5; i++) {
            fiveBusinesses.get(i).setAccessMode("READ_ONLY");
        }
        when(businessRepository.findAllOwnedActiveByUserId(testUser.getId())).thenReturn(fiveBusinesses);

        // Upgrade Free -> Plus: restores up to 3 editable businesses
        allocationService.applyUpgradeAllocation(subscription, plusPlan);
        assertThat(fiveBusinesses.stream().filter(Business::isEditable).count()).isEqualTo(3);

        // Upgrade Plus -> Pro: restores all 5 editable businesses
        allocationService.applyUpgradeAllocation(subscription, proPlan);
        assertThat(fiveBusinesses.stream().filter(Business::isEditable).count()).isEqualTo(5);
    }
}
