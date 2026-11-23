package com.afab.user;

import com.afab.auth.domain.PasswordResetTokenRepository;
import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.auth.domain.VerificationToken;
import com.afab.auth.domain.VerificationTokenRepository;
import com.afab.business.Business;
import com.afab.business.BusinessMember;
import com.afab.business.BusinessMemberRepository;
import com.afab.business.BusinessRepository;
import com.afab.common.exception.ConflictException;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.subscription.Subscription;
import com.afab.subscription.SubscriptionRepository;
import com.afab.subscription.stripe.StripeBillingService;
import com.afab.user.dto.AccountDeletionPreflightDTO;
import com.afab.user.dto.AccountDeletionPreflightDTO.BlockingBusinessDTO;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class UserAccountService {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final BusinessMemberRepository businessMemberRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final VerificationTokenRepository verificationTokenRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final AuditService auditService;
    private final ObjectProvider<StripeBillingService> stripeBillingServiceProvider;

    public UserAccountService(
            UserRepository userRepository,
            BusinessRepository businessRepository,
            BusinessMemberRepository businessMemberRepository,
            CategoryRepository categoryRepository,
            TransactionRepository transactionRepository,
            SubscriptionRepository subscriptionRepository,
            RefreshTokenRepository refreshTokenRepository,
            VerificationTokenRepository verificationTokenRepository,
            PasswordResetTokenRepository passwordResetTokenRepository,
            AuditService auditService
    ) {
        this(userRepository, businessRepository, businessMemberRepository, categoryRepository,
                transactionRepository, subscriptionRepository, refreshTokenRepository,
                verificationTokenRepository, passwordResetTokenRepository, auditService, null);
    }

    @Autowired
    public UserAccountService(
            UserRepository userRepository,
            BusinessRepository businessRepository,
            BusinessMemberRepository businessMemberRepository,
            CategoryRepository categoryRepository,
            TransactionRepository transactionRepository,
            SubscriptionRepository subscriptionRepository,
            RefreshTokenRepository refreshTokenRepository,
            VerificationTokenRepository verificationTokenRepository,
            PasswordResetTokenRepository passwordResetTokenRepository,
            AuditService auditService,
            ObjectProvider<StripeBillingService> stripeBillingServiceProvider
    ) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.businessMemberRepository = businessMemberRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.verificationTokenRepository = verificationTokenRepository;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.auditService = auditService;
        this.stripeBillingServiceProvider = stripeBillingServiceProvider;
    }

    /**
     * Evaluates whether the user can safely delete their account without orphaning
     * or endangering any active business's financial ledger.
     */
    @Transactional(readOnly = true)
    public AccountDeletionPreflightDTO getDeletionPreflight(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        List<BlockingBusinessDTO> blocking = findBlockingOwnedBusinesses(user);
        boolean canDelete = blocking.isEmpty();
        String guidance = canDelete
                ? "Your account has no active businesses blocking deletion. Existing archived business ledgers and audit trails will be preserved while your personal account is deactivated and anonymized."
                : "You currently own " + blocking.size() + " active business(es). Transfer ownership to another active team member or explicitly archive each business before deleting your user account.";

        return new AccountDeletionPreflightDTO(canDelete, blocking, guidance);
    }

    /**
     * Exports all data associated with the authenticated user in a structured GDPR-ready payload.
     * Excludes sensitive credentials (password hash, 2FA secrets, backup codes, token hashes).
     */
    @Transactional
    public Map<String, Object> exportUserData(String email, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Map<String, Object> account = new LinkedHashMap<>();
        account.put("id", user.getId());
        account.put("firstName", user.getFirstName());
        account.put("lastName", user.getLastName());
        account.put("email", user.getEmail());
        account.put("phoneNumber", user.getPhoneNumber());
        account.put("avatarUrl", user.getAvatarUrl());
        account.put("status", user.getStatus());
        account.put("planTier", user.getPlanTier());
        account.put("emailVerified", user.getEmailVerifiedAt() != null);
        account.put("emailVerifiedAt", user.getEmailVerifiedAt());
        account.put("twoFactorEnabled", Boolean.TRUE.equals(user.getTwoFactorEnabled()));
        account.put("createdAt", user.getCreatedAt());
        account.put("updatedAt", user.getUpdatedAt());
        account.put("lastLoginAt", user.getLastLoginAt());
        account.put("lastLoginIp", user.getLastLoginIp());
        account.put("passwordChangedAt", user.getPasswordChangedAt());

        Map<String, Object> preferences = new LinkedHashMap<>();
        preferences.put("enableAiInsights", Boolean.TRUE.equals(user.getEnableAiInsights()));
        preferences.put("compactMode", Boolean.TRUE.equals(user.getCompactMode()));
        preferences.put("autoCategorizeTransactions", Boolean.TRUE.equals(user.getAutoCategorizeTransactions()));
        preferences.put("showTips", Boolean.TRUE.equals(user.getShowTips()));
        account.put("preferences", preferences);

        Map<String, Object> subscriptionMap = null;
        Optional<Subscription> subOpt = subscriptionRepository.findByUserId(user.getId());
        if (subOpt.isPresent()) {
            Subscription sub = subOpt.get();
            subscriptionMap = new LinkedHashMap<>();
            subscriptionMap.put("id", sub.getId());
            subscriptionMap.put("status", sub.getStatus());
            subscriptionMap.put("planName", sub.getPlan() != null ? sub.getPlan().getName() : null);
            subscriptionMap.put("planSlug", sub.getPlan() != null ? sub.getPlan().getSlug() : null);
            subscriptionMap.put("periodStart", sub.getPeriodStart());
            subscriptionMap.put("periodEnd", sub.getPeriodEnd());
            subscriptionMap.put("trialEnd", sub.getTrialEnd());
            subscriptionMap.put("cancelAtPeriodEnd", Boolean.TRUE.equals(sub.getCancelAtPeriodEnd()));
        }

        // Export businesses the user actively belongs to or owns (no unauthorized access)
        Map<UUID, Business> authorizedBusinesses = new LinkedHashMap<>();
        for (BusinessMember m : businessMemberRepository.findAllActiveMembershipsByUserId(user.getId())) {
            authorizedBusinesses.put(m.getBusiness().getId(), m.getBusiness());
        }
        for (Business owned : businessRepository.findAllByUserId(user.getId())) {
            authorizedBusinesses.putIfAbsent(owned.getId(), owned);
        }

        List<Map<String, Object>> businessExports = new ArrayList<>();
        int totalCategories = 0;
        int totalTransactions = 0;

        for (Business b : authorizedBusinesses.values()) {
            List<Category> categories = categoryRepository.findAllOwnedByBusiness(b.getId());
            List<Transaction> transactions = transactionRepository.findAllActiveByBusinessIdForExport(b.getId());
            totalCategories += categories.size();
            totalTransactions += transactions.size();

            List<Map<String, Object>> categoryExports = new ArrayList<>();
            for (Category c : categories) {
                Map<String, Object> cm = new LinkedHashMap<>();
                cm.put("id", c.getId());
                cm.put("name", c.getName());
                cm.put("type", c.getType());
                cm.put("icon", c.getIcon());
                cm.put("color", c.getColor());
                cm.put("createdAt", c.getCreatedAt());
                categoryExports.add(cm);
            }

            List<Map<String, Object>> txExports = new ArrayList<>();
            for (Transaction tx : transactions) {
                Map<String, Object> tm = new LinkedHashMap<>();
                tm.put("id", tx.getId());
                tm.put("type", tx.getType());
                tm.put("amount", tx.getAmount());
                tm.put("currency", tx.getCurrency());
                tm.put("categoryName", tx.getCategory() != null ? tx.getCategory().getName() : null);
                tm.put("description", tx.getDescription());
                tm.put("transactionDate", tx.getTransactionDate());
                tm.put("paymentMethod", tx.getPaymentMethod());
                tm.put("status", tx.getStatus());
                tm.put("taxDeductible", tx.getTaxDeductible());
                tm.put("taxRate", tx.getTaxRate());
                tm.put("isSplit", tx.getIsSplit());
                tm.put("notes", tx.getNotes());
                tm.put("createdAt", tx.getCreatedAt());
                txExports.add(tm);
            }

            Map<String, Object> bm = new LinkedHashMap<>();
            bm.put("id", b.getId());
            bm.put("name", b.getName());
            bm.put("currency", b.getCurrency());
            bm.put("country", b.getCountry());
            bm.put("timezone", b.getTimezone());
            bm.put("fiscalYearStartMonth", b.getFiscalYearStartMonth());
            bm.put("dateFormat", b.getDateFormat());
            bm.put("numberFormat", b.getNumberFormat());
            bm.put("industry", b.getIndustry());
            bm.put("businessType", b.getBusinessType());
            bm.put("businessEmail", b.getBusinessEmail());
            bm.put("phoneNumber", b.getPhoneNumber());
            bm.put("website", b.getWebsite());
            bm.put("taxId", b.getTaxId());
            bm.put("addressLine", b.getAddressLine());
            bm.put("city", b.getCity());
            bm.put("state", b.getState());
            bm.put("postalCode", b.getPostalCode());
            bm.put("description", b.getDescription());
            bm.put("status", b.getStatus());
            bm.put("archivedAt", b.getArchivedAt());
            bm.put("createdAt", b.getCreatedAt());
            bm.put("categories", categoryExports);
            bm.put("transactions", txExports);
            businessExports.add(bm);
        }

        List<RefreshToken> activeTokens = refreshTokenRepository
                .findByUserIdAndRevokedAtIsNullAndExpiresAtAfter(user.getId(), Instant.now());
        List<Map<String, Object>> sessionExports = new ArrayList<>();
        for (RefreshToken token : activeTokens) {
            Map<String, Object> sm = new LinkedHashMap<>();
            sm.put("id", token.getId());
            sm.put("deviceInfo", token.getDeviceInfo());
            sm.put("ipAddress", token.getIpAddress());
            sm.put("createdAt", token.getCreatedAt());
            sm.put("expiresAt", token.getExpiresAt());
            sessionExports.add(sm);
        }

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("businessesCount", authorizedBusinesses.size());
        summary.put("categoriesCount", totalCategories);
        summary.put("transactionsCount", totalTransactions);
        summary.put("activeSessionsCount", sessionExports.size());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("schemaVersion", "1.1");
        payload.put("exportedAt", Instant.now().toString());
        payload.put("summary", summary);
        payload.put("account", account);
        payload.put("subscription", subscriptionMap);
        payload.put("businesses", businessExports);
        payload.put("activeSessions", sessionExports);

        auditService.logSecurityEvent(
                user,
                "ACCOUNT_DATA_EXPORTED",
                ipAddress,
                userAgent,
                "{\"businesses\":" + authorizedBusinesses.size() + ",\"transactions\":" + totalTransactions + "}"
        );

        return payload;
    }

    /**
     * Safely deactivates and anonymizes the authenticated user's account.
     *
     * Financial Data Preservation Rules (P0.4):
     * 1. Rejects deletion with 409 Conflict if the user owns ANY active (non-archived) Business
     *    without another active OWNER — requires ownership transfer or explicit Business archival first.
     * 2. NEVER cascade-deletes Businesses, Transactions, Invoices, Customers, or Audit Logs.
     * 3. Deactivates the user's BusinessMember memberships to prevent orphaned active records.
     * 4. Revokes all active sessions & pending verification/reset tokens.
     * 5. Soft-deletes & anonymizes the User record so financial foreign keys and audit trails remain intact.
     */
    @Transactional
    public void deleteUserAccount(String email, String confirmation, String ipAddress, String userAgent) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String expectedPhrase = "delete " + user.getEmail();
        String provided = confirmation != null ? confirmation.trim() : "";

        if (!provided.equalsIgnoreCase(expectedPhrase)) {
            throw new IllegalArgumentException(
                    "Confirmation phrase does not match. Please type: " + expectedPhrase
            );
        }

        // Guard: Block deletion while user owns any active business without another active OWNER
        List<BlockingBusinessDTO> blockingBusinesses = findBlockingOwnedBusinesses(user);
        if (!blockingBusinesses.isEmpty()) {
            String names = blockingBusinesses.stream()
                    .map(BlockingBusinessDTO::businessName)
                    .reduce((a, b) -> a + ", " + b)
                    .orElse("");
            throw new ConflictException(
                    "Cannot delete account while you own active business(es): " + names
                            + ". Transfer ownership to another member or archive the business(es) first."
            );
        }

        Instant now = Instant.now();
        UUID deletedUserId = user.getId();

        // 1. Deactivate all active memberships (prevents orphaned active memberships; preserves team access for other members)
        List<BusinessMember> activeMemberships = businessMemberRepository.findAllActiveMembershipsByUserId(deletedUserId);
        for (BusinessMember membership : activeMemberships) {
            membership.setStatus("REMOVED");
        }
        if (!activeMemberships.isEmpty()) {
            businessMemberRepository.saveAll(activeMemberships);
        }

        // 2. Revoke all active refresh tokens and pending verification / password reset tokens
        refreshTokenRepository.revokeAllUserTokens(deletedUserId, now);
        verificationTokenRepository.invalidateAllUserTokens(deletedUserId, VerificationToken.TokenType.EMAIL_VERIFICATION, now);
        verificationTokenRepository.invalidateAllUserTokens(deletedUserId, VerificationToken.TokenType.PASSWORD_RESET, now);
        passwordResetTokenRepository.invalidateAllUserTokens(deletedUserId, now);

        // 3. Record deletion audit event (without raw PII in details)
        auditService.logSecurityEvent(
                user,
                "ACCOUNT_DELETED",
                ipAddress,
                userAgent,
                "{\"deletedUserId\":\"" + deletedUserId + "\",\"anonymized\":true}"
        );

        // 4. Best-effort cancellation of any active Stripe subscription before account anonymization
        StripeBillingService billingService = stripeBillingServiceProvider != null
                ? stripeBillingServiceProvider.getIfAvailable()
                : null;
        if (billingService != null) {
            billingService.cancelStripeSubscriptionIfPresent(user);
        }

        // 5. Soft-delete and anonymize user PII while keeping tombstone row intact for FK & ledger retention
        user.setStatus("DELETED");
        user.setDeletedAt(now);
        user.setActiveBusinessId(null);
        user.setFirstName("Deleted");
        user.setLastName("User");
        user.setEmail("deleted-" + deletedUserId + "@deleted.afab.local");
        user.setPhoneNumber(null);
        user.setAvatarUrl(null);
        user.setTwoFactorEnabled(false);
        user.setTwoFactorSecret(null);
        user.setTwoFactorBackupCodes(null);
        user.setPasswordHash("DELETED:" + UUID.randomUUID());
        user.setLastLoginIp(null);

        userRepository.saveAndFlush(user);
    }

    private List<BlockingBusinessDTO> findBlockingOwnedBusinesses(User user) {
        Map<UUID, Business> ownedActiveBusinesses = new LinkedHashMap<>();

        // Check active OWNER memberships
        List<BusinessMember> activeMemberships = businessMemberRepository.findAllActiveByUserIdWithBusiness(user.getId());
        for (BusinessMember m : activeMemberships) {
            if (m.isOwner() && m.getBusiness().getArchivedAt() == null) {
                long otherOwners = businessMemberRepository.countOtherActiveOwners(m.getBusiness().getId(), user.getId());
                if (otherOwners == 0) {
                    ownedActiveBusinesses.put(m.getBusiness().getId(), m.getBusiness());
                }
            }
        }

        // Also guard legacy businesses.user_id ownership pointer
        for (Business b : businessRepository.findAllByUserId(user.getId())) {
            if (b.getArchivedAt() == null && !ownedActiveBusinesses.containsKey(b.getId())) {
                long otherOwners = businessMemberRepository.countOtherActiveOwners(b.getId(), user.getId());
                if (otherOwners == 0) {
                    ownedActiveBusinesses.put(b.getId(), b);
                }
            }
        }

        List<BlockingBusinessDTO> blocking = new ArrayList<>();
        for (Business b : ownedActiveBusinesses.values()) {
            long activeMembers = businessMemberRepository.countByBusinessIdAndStatus(b.getId(), "ACTIVE");
            blocking.add(new BlockingBusinessDTO(
                    b.getId(),
                    b.getName(),
                    activeMembers,
                    activeMembers > 1
            ));
        }
        return blocking;
    }
}
