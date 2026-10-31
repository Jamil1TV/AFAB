package com.afab.business;

import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CurrentBusinessServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private BusinessRepository businessRepository;

    @Mock
    private BusinessMemberRepository businessMemberRepository;

    @InjectMocks
    private CurrentBusinessService currentBusinessService;

    private User testUser;
    private Business testBusiness1;
    private Business testBusiness2;
    private UUID b1Id;
    private UUID b2Id;
    private final String userEmail = "founder@enterprise.com";

    @BeforeEach
    void setUp() {
        b1Id = UUID.randomUUID();
        b2Id = UUID.randomUUID();

        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setEmail(userEmail);

        testBusiness1 = new Business();
        testBusiness1.setId(b1Id);
        testBusiness1.setName("Acme Logistics");
        testBusiness1.setCurrency("USD");
        testBusiness1.setStatus("ACTIVE");

        testBusiness2 = new Business();
        testBusiness2.setId(b2Id);
        testBusiness2.setName("Acme Cloud");
        testBusiness2.setCurrency("EUR");
        testBusiness2.setStatus("ACTIVE");
    }

    @Test
    @DisplayName("getCurrentBusiness: returns requested business when user is an active member")
    void testGetCurrentBusiness_authorized() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));

        BusinessMember member = new BusinessMember(testBusiness1, testUser, "OWNER", "ACTIVE");
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(b1Id, testUser.getId()))
                .thenReturn(Optional.of(member));

        Business result = currentBusinessService.getCurrentBusiness(userEmail, b1Id);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(b1Id);
        assertThat(result.getName()).isEqualTo("Acme Logistics");
    }

    @Test
    @DisplayName("getCurrentBusiness: throws ForbiddenException when user is NOT a member of requested business")
    void testGetCurrentBusiness_unauthorized_throwsForbidden() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(b2Id, testUser.getId()))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> currentBusinessService.getCurrentBusiness(userEmail, b2Id))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Unauthorized: You do not have access to business");
    }

    @Test
    @DisplayName("getCurrentBusiness: throws ForbiddenException when business is archived")
    void testGetCurrentBusiness_archivedBusiness_throwsForbidden() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));

        testBusiness1.setArchivedAt(Instant.now());
        BusinessMember member = new BusinessMember(testBusiness1, testUser, "OWNER", "ACTIVE");
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(b1Id, testUser.getId()))
                .thenReturn(Optional.of(member));

        assertThatThrownBy(() -> currentBusinessService.getCurrentBusiness(userEmail, b1Id))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("inactive or business is archived");
    }

    @Test
    @DisplayName("getCurrentBusiness: falls back to user.activeBusinessId when header is missing")
    void testGetCurrentBusiness_fallbackToActiveBusinessId() {
        testUser.setActiveBusinessId(b2Id);
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));

        BusinessMember member2 = new BusinessMember(testBusiness2, testUser, "ADMIN", "ACTIVE");
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(b2Id, testUser.getId()))
                .thenReturn(Optional.of(member2));

        Business result = currentBusinessService.getCurrentBusiness(userEmail, null);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(b2Id);
        assertThat(result.getName()).isEqualTo("Acme Cloud");
    }

    @Test
    @DisplayName("switchActiveBusiness: updates user activeBusinessId when user is an active member")
    void testSwitchActiveBusiness_success() {
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(testUser));

        BusinessMember member = new BusinessMember(testBusiness2, testUser, "MEMBER", "ACTIVE");
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(b2Id, testUser.getId()))
                .thenReturn(Optional.of(member));

        Business switched = currentBusinessService.switchActiveBusiness(userEmail, b2Id);

        assertThat(switched).isNotNull();
        assertThat(switched.getId()).isEqualTo(b2Id);
        assertThat(testUser.getActiveBusinessId()).isEqualTo(b2Id);
        verify(userRepository).save(testUser);
    }
}
