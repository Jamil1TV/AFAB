package com.afab.business;

import com.afab.business.dto.BusinessDTO;
import com.afab.business.dto.CreateBusinessRequest;
import com.afab.subscription.EntitlementService;
import com.afab.subscription.Plan;
import com.afab.subscription.PlanEntitlement;
import com.afab.subscription.PlanLimitReachedException;
import com.afab.subscription.Subscription;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BusinessControllerTest {

    @Mock
    private BusinessRepository businessRepository;

    @Mock
    private BusinessMemberRepository businessMemberRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CurrentBusinessService currentBusinessService;

    @Mock
    private com.afab.security.AuditService auditService;

    @Mock
    private EntitlementService entitlementService;

    @Mock
    private Authentication authentication;

    private BusinessController businessController;

    private User testUser;
    private Plan freePlan;
    private Plan plusPlan;
    private final String userEmail = "founder@enterprise.com";

    @BeforeEach
    void setUp() {
        businessController = new BusinessController(
                businessRepository,
                businessMemberRepository,
                userRepository,
                currentBusinessService,
                auditService,
                entitlementService,
                null
        );
        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setEmail(userEmail);
        testUser.setPlanTier("FREE");

        freePlan = new Plan("Free", "free", BigDecimal.ZERO, BigDecimal.ZERO, "USD");
        freePlan.setEntitlements(List.of(new PlanEntitlement(freePlan, "business.max", "LIMIT", "1")));

        plusPlan = new Plan("Plus", "plus", new BigDecimal("9.99"), new BigDecimal("7.99"), "USD");
        plusPlan.setEntitlements(List.of(new PlanEntitlement(plusPlan, "business.max", "LIMIT", "3")));

        lenient().when(authentication.getName()).thenReturn(userEmail);
        lenient().when(currentBusinessService.getCurrentUser(userEmail)).thenReturn(testUser);
        lenient().when(entitlementService.getOrReconcileSubscription(testUser))
                .thenReturn(new Subscription(testUser, freePlan, "ACTIVE", Instant.now()));
    }

    @Test
    @DisplayName("createBusiness: rejects additional business creation when Free plan limit (1) is reached")
    void testFreePlanLimitReached() {
        Business existingBusiness = new Business();
        existingBusiness.setId(UUID.randomUUID());
        existingBusiness.setName("First Workspace");

        BusinessMember existingMember = new BusinessMember(existingBusiness, testUser, "OWNER", "ACTIVE");
        when(businessMemberRepository.findAllActiveByUserIdWithBusiness(testUser.getId()))
                .thenReturn(List.of(existingMember));

        CreateBusinessRequest req = new CreateBusinessRequest();
        req.setName("Second Workspace");
        req.setCurrency("USD");

        assertThatThrownBy(() -> businessController.createBusiness(req, authentication))
                .isInstanceOf(PlanLimitReachedException.class)
                .hasMessageContaining("business.max");

        verify(businessRepository, never()).save(any());
    }

    @Test
    @DisplayName("createBusiness: enforces reconciled subscription even if user.planTier is stale")
    void testExpiredTrialStalePlanTierRejected() {
        testUser.setPlanTier("PLUS"); // Stale column from expired trial
        when(entitlementService.getOrReconcileSubscription(testUser))
                .thenReturn(new Subscription(testUser, freePlan, "ACTIVE", Instant.now()));

        Business existingBusiness = new Business();
        existingBusiness.setId(UUID.randomUUID());
        BusinessMember existingMember = new BusinessMember(existingBusiness, testUser, "OWNER", "ACTIVE");
        when(businessMemberRepository.findAllActiveByUserIdWithBusiness(testUser.getId()))
                .thenReturn(List.of(existingMember));

        CreateBusinessRequest req = new CreateBusinessRequest();
        req.setName("Second Workspace");
        req.setCurrency("USD");

        assertThatThrownBy(() -> businessController.createBusiness(req, authentication))
                .isInstanceOf(PlanLimitReachedException.class)
                .hasMessageContaining("business.max");

        verify(businessRepository, never()).save(any());
    }

    @Test
    @DisplayName("createBusiness: allows creation when reconciled subscription is within plan limits")
    void testCreateBusinessSuccessUnderLimit() {
        testUser.setPlanTier("PLUS");
        when(entitlementService.getOrReconcileSubscription(testUser))
                .thenReturn(new Subscription(testUser, plusPlan, "ACTIVE", Instant.now()));

        Business existingBusiness = new Business();
        existingBusiness.setId(UUID.randomUUID());
        BusinessMember existingMember = new BusinessMember(existingBusiness, testUser, "OWNER", "ACTIVE");

        when(businessMemberRepository.findAllActiveByUserIdWithBusiness(testUser.getId()))
                .thenReturn(List.of(existingMember));

        when(businessRepository.save(any(Business.class))).thenAnswer(invocation -> {
            Business b = invocation.getArgument(0);
            b.setId(UUID.randomUUID());
            return b;
        });

        CreateBusinessRequest req = new CreateBusinessRequest();
        req.setName("Second Business");
        req.setCurrency("EUR");

        ResponseEntity<BusinessDTO> response = businessController.createBusiness(req, authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getName()).isEqualTo("Second Business");
        assertThat(response.getBody().getCurrency()).isEqualTo("EUR");
        assertThat(response.getBody().getUserRole()).isEqualTo("OWNER");
        assertThat(response.getBody().isActive()).isTrue();

        verify(businessRepository).save(argThat(b -> userEmail.equals(b.getBusinessEmail())));
        verify(businessMemberRepository).save(any(BusinessMember.class));
        verify(userRepository).save(testUser);
    }
}
