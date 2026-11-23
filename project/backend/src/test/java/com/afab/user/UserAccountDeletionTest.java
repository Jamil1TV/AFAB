package com.afab.user;

import com.afab.auth.domain.PasswordResetTokenRepository;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.auth.domain.VerificationTokenRepository;
import com.afab.business.*;
import com.afab.business.dto.TransferOwnershipRequest;
import com.afab.common.exception.ConflictException;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.subscription.SubscriptionRepository;
import com.afab.user.dto.AccountDeletionPreflightDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserAccountDeletionTest {

    @Mock private UserRepository userRepository;
    @Mock private BusinessRepository businessRepository;
    @Mock private BusinessMemberRepository businessMemberRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private SubscriptionRepository subscriptionRepository;
    @Mock private RefreshTokenRepository refreshTokenRepository;
    @Mock private VerificationTokenRepository verificationTokenRepository;
    @Mock private PasswordResetTokenRepository passwordResetTokenRepository;
    @Mock private AuditService auditService;
    @Mock private CurrentBusinessService currentBusinessService;

    private UserAccountService userAccountService;
    private BusinessController businessController;

    private User owner;
    private User admin;
    private Business business;

    @BeforeEach
    void setUp() {
        userAccountService = new UserAccountService(
                userRepository, businessRepository, businessMemberRepository,
                categoryRepository, transactionRepository, subscriptionRepository,
                refreshTokenRepository, verificationTokenRepository, passwordResetTokenRepository,
                auditService
        );
        businessController = new BusinessController(
                businessRepository, businessMemberRepository, userRepository, currentBusinessService, auditService
        );

        owner = new User("Omar", "Owner", "omar@acme.com", "hash");
        owner.setId(UUID.randomUUID());
        owner.setStatus("ACTIVE");

        admin = new User("Sara", "Admin", "sara@acme.com", "hash");
        admin.setId(UUID.randomUUID());
        admin.setStatus("ACTIVE");

        business = new Business(owner, "Acme Trading", "TND");
        business.setId(UUID.randomUUID());
        business.setStatus("ACTIVE");
    }

    @Test
    @DisplayName("Blocks account deletion with 409 Conflict when user is sole owner of an active business")
    void blocksDeletionWhileOwningActiveBusiness() {
        BusinessMember ownerMembership = new BusinessMember(business, owner, "OWNER", "ACTIVE");
        when(userRepository.findByEmail("omar@acme.com")).thenReturn(Optional.of(owner));
        when(businessMemberRepository.findAllActiveByUserIdWithBusiness(owner.getId())).thenReturn(List.of(ownerMembership));
        when(businessRepository.findAllByUserId(owner.getId())).thenReturn(List.of(business));
        when(businessMemberRepository.countOtherActiveOwners(business.getId(), owner.getId())).thenReturn(0L);
        when(businessMemberRepository.countByBusinessIdAndStatus(business.getId(), "ACTIVE")).thenReturn(2L);

        AccountDeletionPreflightDTO preflight = userAccountService.getDeletionPreflight("omar@acme.com");
        assertThat(preflight.canDelete()).isFalse();
        assertThat(preflight.blockingBusinesses()).hasSize(1);
        assertThat(preflight.blockingBusinesses().get(0).businessName()).isEqualTo("Acme Trading");

        assertThatThrownBy(() -> userAccountService.deleteUserAccount(
                "omar@acme.com", "delete omar@acme.com", "127.0.0.1", "Browser"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Acme Trading");

        verify(userRepository, never()).delete(any());
        verify(businessRepository, never()).delete(any());
    }

    @Test
    @DisplayName("Allows account deletion after business is archived — soft-deletes & anonymizes user without deleting business data")
    void allowsDeletionAfterBusinessArchivedWithoutCascadingBusiness() {
        business.setArchivedAt(Instant.now());
        business.setStatus("ARCHIVED");
        BusinessMember archivedOwnerMembership = new BusinessMember(business, owner, "OWNER", "ACTIVE");

        when(userRepository.findByEmail("omar@acme.com")).thenReturn(Optional.of(owner));
        when(businessMemberRepository.findAllActiveByUserIdWithBusiness(owner.getId())).thenReturn(List.of());
        when(businessRepository.findAllByUserId(owner.getId())).thenReturn(List.of(business));
        when(businessMemberRepository.findAllActiveMembershipsByUserId(owner.getId())).thenReturn(List.of(archivedOwnerMembership));

        userAccountService.deleteUserAccount("omar@acme.com", "delete omar@acme.com", "127.0.0.1", "Browser");

        // User is anonymized and soft-deleted — NEVER hard-deleted
        verify(userRepository, never()).delete(any());
        verify(businessRepository, never()).delete(any());
        verify(userRepository).saveAndFlush(owner);
        assertThat(owner.getStatus()).isEqualTo("DELETED");
        assertThat(owner.getDeletedAt()).isNotNull();
        assertThat(owner.getEmail()).startsWith("deleted-").endsWith("@deleted.afab.local");
        assertThat(owner.getActiveBusinessId()).isNull();
        // Membership cleanly marked REMOVED
        assertThat(archivedOwnerMembership.getStatus()).isEqualTo("REMOVED");
        // All sessions & tokens revoked
        verify(refreshTokenRepository).revokeAllUserTokens(eq(owner.getId()), any(Instant.class));
    }

    @Test
    @DisplayName("Ownership transfer promotes target active member to OWNER and demotes previous owner to ADMIN")
    void transferOwnershipUpdatesBusinessAndMembers() {
        BusinessMember ownerMember = new BusinessMember(business, owner, "OWNER", "ACTIVE");
        BusinessMember adminMember = new BusinessMember(business, admin, "ADMIN", "ACTIVE");

        Authentication auth = mock(Authentication.class);
        when(auth.getName()).thenReturn("omar@acme.com");
        when(currentBusinessService.getCurrentUser("omar@acme.com")).thenReturn(owner);
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(business.getId(), owner.getId()))
                .thenReturn(Optional.of(ownerMember));
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(business.getId(), admin.getId()))
                .thenReturn(Optional.of(adminMember));
        when(businessRepository.save(business)).thenReturn(business);

        businessController.transferOwnership(business.getId(), new TransferOwnershipRequest(admin.getId()), auth);

        assertThat(adminMember.getRole()).isEqualTo("OWNER");
        assertThat(ownerMember.getRole()).isEqualTo("ADMIN");
        assertThat(business.getUser().getId()).isEqualTo(admin.getId());
        verify(auditService).logBusinessEvent(eq(owner), eq("OWNERSHIP_TRANSFERRED"), eq(business.getId()), any());
    }
}
