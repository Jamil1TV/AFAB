package com.afab.user;

import com.afab.auth.domain.RefreshToken;
import com.afab.auth.domain.RefreshTokenRepository;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.subscription.Subscription;
import com.afab.subscription.SubscriptionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class UserAccountService {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final AuditService auditService;

    public UserAccountService(
            UserRepository userRepository,
            BusinessRepository businessRepository,
            CategoryRepository categoryRepository,
            TransactionRepository transactionRepository,
            SubscriptionRepository subscriptionRepository,
            RefreshTokenRepository refreshTokenRepository,
            AuditService auditService
    ) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.auditService = auditService;
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

        List<Business> businesses = businessRepository.findAllByUserId(user.getId());
        List<Map<String, Object>> businessExports = new ArrayList<>();
        int totalCategories = 0;
        int totalTransactions = 0;

        for (Business b : businesses) {
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
                tm.put("receiptUrl", tx.getReceiptUrl());
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
        summary.put("businessesCount", businesses.size());
        summary.put("categoriesCount", totalCategories);
        summary.put("transactionsCount", totalTransactions);
        summary.put("activeSessionsCount", sessionExports.size());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("schemaVersion", "1.0");
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
                "{\"businesses\":" + businesses.size() + ",\"transactions\":" + totalTransactions + "}"
        );

        return payload;
    }

    /**
     * Permanently deletes the authenticated user's account and cascades removal of all owned data.
     * Requires exact confirmation phrase: "delete <user-email>".
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

        UUID deletedUserId = user.getId();
        String deletedEmail = user.getEmail().replace("\"", "");

        // Break circular FK (users.active_business_id -> businesses.id) before cascading delete
        if (user.getActiveBusinessId() != null) {
            user.setActiveBusinessId(null);
            userRepository.saveAndFlush(user);
        }

        // Record anonymized deletion audit entry (user=null so row persists after user deletion)
        auditService.logSecurityEvent(
                null,
                "ACCOUNT_DELETED",
                ipAddress,
                userAgent,
                "{\"deletedUserId\":\"" + deletedUserId + "\",\"email\":\"" + deletedEmail + "\"}"
        );

        // Permanently delete user — DB ON DELETE CASCADE removes businesses, transactions, categories,
        // refresh tokens, verification/reset tokens, subscriptions, usage counters, and memberships.
        userRepository.delete(user);
        userRepository.flush();
    }
}
