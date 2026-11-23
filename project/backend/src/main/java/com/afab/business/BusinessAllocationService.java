package com.afab.business;

import com.afab.business.dto.BusinessAllocationDTO;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.subscription.*;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class BusinessAllocationService {

    private final BusinessRepository businessRepository;
    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final PlanRepository planRepository;
    private final PendingBusinessAllocationRepository pendingAllocationRepository;
    private final SubscriptionHistoryRepository subscriptionHistoryRepository;

    public BusinessAllocationService(
            BusinessRepository businessRepository,
            UserRepository userRepository,
            SubscriptionRepository subscriptionRepository,
            PlanRepository planRepository,
            PendingBusinessAllocationRepository pendingAllocationRepository,
            SubscriptionHistoryRepository subscriptionHistoryRepository
    ) {
        this.businessRepository = businessRepository;
        this.userRepository = userRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository = planRepository;
        this.pendingAllocationRepository = pendingAllocationRepository;
        this.subscriptionHistoryRepository = subscriptionHistoryRepository;
    }

    public int resolveEditableLimit(Subscription sub) {
        if (sub == null || sub.getPlan() == null) {
            return 1;
        }
        String status = sub.getStatus();
        if ("CANCELED".equalsIgnoreCase(status) || "EXPIRED".equalsIgnoreCase(status)) {
            return 1;
        }
        return resolveEditableLimit(sub.getPlan());
    }

    public int resolveEditableLimit(Plan plan) {
        if (plan == null) {
            return 1;
        }
        if (plan.getEntitlements() != null) {
            for (PlanEntitlement ent : plan.getEntitlements()) {
                if ("business.max".equalsIgnoreCase(ent.getFeatureKey())) {
                    try {
                        int parsed = Integer.parseInt(ent.getValue());
                        if (parsed > 0) {
                            return parsed;
                        }
                    } catch (NumberFormatException ignored) {
                        // Fall through to slug-based canonical limits
                    }
                }
            }
        }
        return resolveEditableLimit(plan.getSlug());
    }

    public int resolveEditableLimit(String planSlug) {
        if (planSlug == null) {
            return 1;
        }
        String normalized = planSlug.trim().toLowerCase();
        if (normalized.contains("pro") || normalized.contains("enterprise")) {
            return 5;
        }
        if (normalized.contains("plus")) {
            return 3;
        }
        return 1;
    }

    @Transactional
    public void assertCanCreateEditableBusiness(User user, int resolvedMaxAllowed) {
        Subscription lockedSub = lockOrCreateSubscription(user);
        int limit = Math.max(1, resolvedMaxAllowed);
        List<Business> owned = businessRepository.findAllOwnedActiveByUserId(user.getId());
        long editableOwnedCount = owned.stream().filter(Business::isEditable).count();
        if (editableOwnedCount >= limit) {
            String slug = lockedSub.getPlan() != null ? lockedSub.getPlan().getSlug() : "free";
            throw new PlanLimitReachedException(
                    "business.max",
                    limit,
                    (int) editableOwnedCount,
                    "free".equalsIgnoreCase(slug) ? "plus" : "pro"
            );
        }
    }

    @Transactional(readOnly = true)
    public BusinessAllocationDTO getAllocationSummary(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));

        Subscription sub = subscriptionRepository.findWithPlanAndEntitlementsByUserId(user.getId())
                .orElseGet(() -> {
                    Plan freePlan = planRepository.findBySlug("free").orElseThrow();
                    return new Subscription(user, freePlan, "ACTIVE", Instant.now());
                });

        Plan activePlan = sub.getPlan();
        int editableLimit = resolveEditableLimit(sub);
        List<Business> owned = businessRepository.findAllOwnedActiveByUserId(user.getId());
        List<PendingBusinessAllocation> pendingRows = pendingAllocationRepository.findAllWithBusinessByUserId(user.getId());

        Set<UUID> pendingIds = pendingRows.stream()
                .map(p -> p.getBusiness().getId())
                .collect(Collectors.toCollection(LinkedHashSet::new));

        int editableCount = 0;
        int readOnlyCount = 0;
        List<BusinessAllocationDTO.BusinessAllocationItemDTO> items = new ArrayList<>();
        for (Business b : owned) {
            boolean editable = b.isEditable();
            if (editable) editableCount++;
            else readOnlyCount++;

            BusinessAllocationDTO.BusinessAllocationItemDTO item = new BusinessAllocationDTO.BusinessAllocationItemDTO();
            item.setId(b.getId());
            item.setName(b.getName());
            item.setCurrency(b.getCurrency());
            item.setIndustry(b.getIndustry());
            item.setCountry(b.getCountry());
            item.setLogoUrl(b.getLogoUrl());
            item.setAccessMode(b.getAccessMode());
            item.setEditable(editable);
            item.setPrimary(b.isPrimary());
            item.setActive(b.getId().equals(user.getActiveBusinessId()));
            item.setSelectedForPending(pendingIds.contains(b.getId()));
            item.setCreatedAt(b.getCreatedAt());
            items.add(item);
        }

        BusinessAllocationDTO dto = new BusinessAllocationDTO();
        dto.setCurrentPlanSlug(activePlan != null ? activePlan.getSlug() : "free");
        dto.setCurrentPlanName(activePlan != null ? activePlan.getName() : "Free");
        dto.setEditableLimit(editableLimit);
        dto.setEditableCount(editableCount);
        dto.setReadOnlyCount(readOnlyCount);
        dto.setTotalOwnedCount(owned.size());
        dto.setAllocationAttentionRequired(Boolean.TRUE.equals(sub.getAllocationAttentionRequired()));

        if (sub.getPendingPlan() != null) {
            dto.setPendingPlanSlug(sub.getPendingPlan().getSlug());
            dto.setPendingPlanName(sub.getPendingPlan().getName());
            dto.setPendingEditableLimit(resolveEditableLimit(sub.getPendingPlan()));
            dto.setPendingChangeEffectiveAt(
                    sub.getPendingChangeEffectiveAt() != null ? sub.getPendingChangeEffectiveAt() : sub.getEffectiveCancelAt()
            );
        } else if (Boolean.TRUE.equals(sub.getCancelAtPeriodEnd())) {
            dto.setPendingPlanSlug("free");
            dto.setPendingPlanName("Free");
            dto.setPendingEditableLimit(1);
            dto.setPendingChangeEffectiveAt(
                    sub.getEffectiveCancelAt() != null ? sub.getEffectiveCancelAt() : sub.getPeriodEnd()
            );
        }

        dto.setPendingBusinessIds(new ArrayList<>(pendingIds));
        dto.setBusinesses(items);
        return dto;
    }

    @Transactional
    public BusinessAllocationDTO updateCurrentAllocation(
            String userEmail,
            List<UUID> selectedBusinessIds,
            UUID primaryBusinessId
    ) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Subscription sub = lockOrCreateSubscription(user);
        int maxAllowed = resolveEditableLimit(sub);

        List<Business> owned = businessRepository.findAllOwnedActiveByUserId(user.getId());
        if (owned.isEmpty()) {
            sub.setAllocationAttentionRequired(false);
            subscriptionRepository.save(sub);
            return getAllocationSummary(userEmail);
        }

        Set<UUID> uniqueSelected = validateOwnedSelection(owned, selectedBusinessIds, maxAllowed, false,
                sub.getPlan() != null ? sub.getPlan().getSlug() : "free");

        if (primaryBusinessId != null && !uniqueSelected.contains(primaryBusinessId)) {
            throw new IllegalArgumentException("Primary business must be one of your selected editable businesses.");
        }

        UUID resolvedPrimaryId = resolvePrimaryId(owned, uniqueSelected, primaryBusinessId, user.getActiveBusinessId());
        for (Business b : owned) {
            boolean editable = uniqueSelected.contains(b.getId());
            b.setAccessMode(editable ? "EDITABLE" : "READ_ONLY");
            b.setPrimary(b.getId().equals(resolvedPrimaryId));
        }
        businessRepository.saveAll(owned);

        sub.setAllocationAttentionRequired(false);
        subscriptionRepository.save(sub);

        String planSlug = sub.getPlan() != null ? sub.getPlan().getSlug() : "free";
        subscriptionHistoryRepository.save(new SubscriptionHistory(
                user,
                "ALLOCATION_UPDATED",
                planSlug,
                planSlug,
                sub.getStatus(),
                sub.getStatus(),
                null,
                Instant.now(),
                "Updated active editable business allocation (" + uniqueSelected.size() + " of " + owned.size() + " editable)"
        ));

        return getAllocationSummary(userEmail);
    }

    @Transactional
    public List<UUID> savePendingAllocation(User user, String targetPlanSlug, List<UUID> selectedBusinessIds) {
        if (targetPlanSlug == null || targetPlanSlug.isBlank()) {
            throw new IllegalArgumentException("Target plan slug is required.");
        }
        String normalizedSlug = targetPlanSlug.trim().toLowerCase();
        if (!"free".equals(normalizedSlug) && !"plus".equals(normalizedSlug) && !"pro".equals(normalizedSlug)) {
            throw new IllegalArgumentException("Unsupported target plan: " + targetPlanSlug);
        }

        lockOrCreateSubscription(user);
        int targetLimit = resolveEditableLimit(normalizedSlug);
        List<Business> owned = businessRepository.findAllOwnedActiveByUserId(user.getId());

        pendingAllocationRepository.deleteAllByUserId(user.getId());
        pendingAllocationRepository.flush();

        if (owned.isEmpty()) {
            return List.of();
        }

        Set<UUID> uniqueSelected = validateOwnedSelection(owned, selectedBusinessIds, targetLimit, true, normalizedSlug);
        Map<UUID, Business> ownedById = owned.stream().collect(Collectors.toMap(Business::getId, b -> b));

        List<PendingBusinessAllocation> toSave = new ArrayList<>();
        for (UUID businessId : uniqueSelected) {
            toSave.add(new PendingBusinessAllocation(user, ownedById.get(businessId), normalizedSlug));
        }
        pendingAllocationRepository.saveAll(toSave);
        return new ArrayList<>(uniqueSelected);
    }

    @Transactional
    public BusinessAllocationDTO savePendingAllocationForUser(
            String userEmail,
            String targetPlanSlug,
            List<UUID> selectedBusinessIds
    ) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        savePendingAllocation(user, targetPlanSlug, selectedBusinessIds);
        return getAllocationSummary(userEmail);
    }

    @Transactional
    public void clearPendingAllocation(User user) {
        pendingAllocationRepository.deleteAllByUserId(user.getId());
        pendingAllocationRepository.flush();
    }

    /**
     * Applies pending downgrade selection if configured for the target plan,
     * otherwise keeps the designated primary business EDITABLE and sets all others READ_ONLY.
     * Never deletes, archives, or duplicates any business records.
     *
     * @return true if user should be prompted to review/select their allocation afterward
     */
    @Transactional
    public boolean applyDowngradeAllocation(Subscription sub, Plan targetPlan) {
        User user = sub.getUser();
        int targetLimit = resolveEditableLimit(targetPlan);
        String targetSlug = targetPlan != null && targetPlan.getSlug() != null
                ? targetPlan.getSlug().toLowerCase()
                : "free";

        List<Business> owned = businessRepository.findAllOwnedActiveByUserId(user.getId());
        sub.setPendingPlan(null);
        sub.setPendingBillingInterval(null);
        sub.setPendingChangeEffectiveAt(null);
        sub.setStripeScheduleId(null);

        if (owned.isEmpty()) {
            clearPendingAllocation(user);
            sub.setAllocationAttentionRequired(false);
            return false;
        }

        if (owned.size() <= targetLimit) {
            UUID primaryId = resolvePrimaryId(owned, owned.stream().map(Business::getId).collect(Collectors.toSet()),
                    null, user.getActiveBusinessId());
            for (Business b : owned) {
                b.setAccessMode("EDITABLE");
                b.setPrimary(b.getId().equals(primaryId));
            }
            businessRepository.saveAll(owned);
            clearPendingAllocation(user);
            sub.setAllocationAttentionRequired(false);
            return false;
        }

        List<PendingBusinessAllocation> pendingRows = pendingAllocationRepository.findAllWithBusinessByUserId(user.getId());
        Set<UUID> ownedIds = owned.stream().map(Business::getId).collect(Collectors.toSet());
        List<UUID> matchingPendingIds = pendingRows.stream()
                .filter(p -> targetSlug.equalsIgnoreCase(p.getTargetPlanSlug()))
                .map(p -> p.getBusiness().getId())
                .filter(ownedIds::contains)
                .distinct()
                .limit(targetLimit)
                .toList();

        boolean attentionRequired;
        Set<UUID> editableSet = new LinkedHashSet<>();

        if (!matchingPendingIds.isEmpty()) {
            editableSet.addAll(matchingPendingIds);
            attentionRequired = false;
        } else {
            // Keep ONLY the designated primary business editable; all other businesses become read-only
            UUID fallbackPrimaryId = pickDesignatedPrimaryId(owned, user.getActiveBusinessId());
            editableSet.add(fallbackPrimaryId);
            attentionRequired = owned.size() > 1;
        }

        UUID resolvedPrimaryId = resolvePrimaryId(owned, editableSet, null, user.getActiveBusinessId());
        for (Business b : owned) {
            b.setAccessMode(editableSet.contains(b.getId()) ? "EDITABLE" : "READ_ONLY");
            b.setPrimary(b.getId().equals(resolvedPrimaryId));
        }
        businessRepository.saveAll(owned);
        clearPendingAllocation(user);
        sub.setAllocationAttentionRequired(attentionRequired);
        return attentionRequired;
    }

    /**
     * Restores READ_ONLY businesses back to EDITABLE up to the new plan limit when upgrading.
     */
    @Transactional
    public boolean applyUpgradeAllocation(Subscription sub, Plan newPlan) {
        User user = sub.getUser();
        int newLimit = resolveEditableLimit(newPlan);

        sub.setPendingPlan(null);
        sub.setPendingBillingInterval(null);
        sub.setPendingChangeEffectiveAt(null);
        sub.setStripeScheduleId(null);
        sub.setCanceledAt(null);
        sub.setEffectiveCancelAt(null);
        clearPendingAllocation(user);

        List<Business> owned = businessRepository.findAllOwnedActiveByUserId(user.getId());
        if (owned.isEmpty()) {
            sub.setAllocationAttentionRequired(false);
            return false;
        }

        int editableCount = 0;
        for (Business b : owned) {
            if (b.isEditable()) {
                editableCount++;
            }
        }

        for (Business b : owned) {
            if (editableCount >= Math.min(owned.size(), newLimit)) {
                break;
            }
            if (!b.isEditable()) {
                b.setAccessMode("EDITABLE");
                editableCount++;
            }
        }

        // Ensure a primary business exists among editable businesses
        Set<UUID> editableSet = owned.stream()
                .filter(Business::isEditable)
                .map(Business::getId)
                .collect(Collectors.toSet());
        UUID primaryId = resolvePrimaryId(owned, editableSet, null, user.getActiveBusinessId());
        for (Business b : owned) {
            b.setPrimary(b.getId().equals(primaryId));
        }

        businessRepository.saveAll(owned);
        boolean attentionRequired = owned.size() > newLimit;
        sub.setAllocationAttentionRequired(attentionRequired);
        return attentionRequired;
    }

    private Subscription lockOrCreateSubscription(User user) {
        Optional<Subscription> locked = subscriptionRepository.findForUpdateByUserId(user.getId());
        if (locked.isPresent()) {
            return locked.get();
        }
        Plan freePlan = planRepository.findBySlug("free")
                .orElseThrow(() -> new IllegalStateException("Default 'free' plan not found"));
        Subscription created = new Subscription(user, freePlan, "ACTIVE", Instant.now());
        subscriptionRepository.saveAndFlush(created);
        return subscriptionRepository.findForUpdateByUserId(user.getId()).orElse(created);
    }

    private Set<UUID> validateOwnedSelection(
            List<Business> owned,
            List<UUID> selectedBusinessIds,
            int maxAllowed,
            boolean exactRequiredWhenExceeding,
            String planSlug
    ) {
        if (selectedBusinessIds == null || selectedBusinessIds.isEmpty()) {
            throw new IllegalArgumentException("Please select at least 1 business.");
        }
        Set<UUID> uniqueSelected = new LinkedHashSet<>(selectedBusinessIds);
        if (uniqueSelected.size() != selectedBusinessIds.size()) {
            throw new IllegalArgumentException("Duplicate business IDs are not allowed.");
        }

        Set<UUID> ownedIds = owned.stream().map(Business::getId).collect(Collectors.toSet());
        for (UUID id : uniqueSelected) {
            if (!ownedIds.contains(id)) {
                throw new ForbiddenException("Unauthorized: You can only allocate active businesses you own (" + id + ").");
            }
        }

        if (uniqueSelected.size() > maxAllowed) {
            throw new PlanLimitReachedException(
                    "business.max",
                    maxAllowed,
                    uniqueSelected.size(),
                    "free".equalsIgnoreCase(planSlug) ? "plus" : "pro"
            );
        }

        if (exactRequiredWhenExceeding) {
            int required = Math.min(owned.size(), maxAllowed);
            if (uniqueSelected.size() != required) {
                throw new IllegalArgumentException(
                        "Plan '" + planSlug.toUpperCase() + "' requires selecting exactly " + required + " editable business(es)."
                );
            }
        }
        return uniqueSelected;
    }

    private UUID pickDesignatedPrimaryId(List<Business> owned, UUID activeBusinessId) {
        return owned.stream()
                .filter(Business::isPrimary)
                .map(Business::getId)
                .findFirst()
                .or(() -> owned.stream()
                        .filter(b -> b.getId().equals(activeBusinessId))
                        .map(Business::getId)
                        .findFirst())
                .orElse(owned.get(0).getId());
    }

    private UUID resolvePrimaryId(
            List<Business> owned,
            Set<UUID> editableSet,
            UUID explicitPrimaryId,
            UUID activeBusinessId
    ) {
        if (explicitPrimaryId != null && editableSet.contains(explicitPrimaryId)) {
            return explicitPrimaryId;
        }
        return owned.stream()
                .filter(b -> b.isPrimary() && editableSet.contains(b.getId()))
                .map(Business::getId)
                .findFirst()
                .or(() -> owned.stream()
                        .filter(b -> b.getId().equals(activeBusinessId) && editableSet.contains(b.getId()))
                        .map(Business::getId)
                        .findFirst())
                .orElseGet(() -> editableSet.iterator().next());
    }
}
