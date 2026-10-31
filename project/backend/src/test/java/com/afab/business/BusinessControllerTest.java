package com.afab.business;

import com.afab.business.dto.BusinessDTO;
import com.afab.business.dto.CreateBusinessRequest;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

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
    private Authentication authentication;

    @InjectMocks
    private BusinessController businessController;

    private User testUser;
    private final String userEmail = "founder@enterprise.com";

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setEmail(userEmail);
        testUser.setPlanTier("FREE");

        lenient().when(authentication.getName()).thenReturn(userEmail);
        lenient().when(currentBusinessService.getCurrentUser(userEmail)).thenReturn(testUser);
    }

    @Test
    @DisplayName("createBusiness: rejects additional business creation when Free plan limit (1) is reached")
    void testFreePlanLimitReached() {
        // User already owns 1 active business
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
                .isInstanceOf(com.afab.subscription.PlanLimitReachedException.class)
                .hasMessageContaining("business.max");

        verify(businessRepository, never()).save(any());
    }

    @Test
    @DisplayName("createBusiness: allows creation when user is within plan limits and links user's real email")
    void testCreateBusinessSuccessUnderLimit() {
        testUser.setPlanTier("PLUS"); // Plus allows 3 businesses

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
