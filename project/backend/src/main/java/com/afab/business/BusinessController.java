package com.afab.business;

import com.afab.business.dto.*;
import com.afab.common.exception.ForbiddenException;
import com.afab.subscription.EntitlementService;
import com.afab.subscription.Plan;
import com.afab.subscription.PlanEntitlement;
import com.afab.subscription.Subscription;
import com.afab.user.User;
import com.afab.user.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/business")
public class BusinessController {

    private final BusinessRepository businessRepository;
    private final BusinessMemberRepository businessMemberRepository;
    private final UserRepository userRepository;
    private final CurrentBusinessService currentBusinessService;
    private final EntitlementService entitlementService;
    private final BusinessAllocationService businessAllocationService;

    public BusinessController(
            BusinessRepository businessRepository,
            BusinessMemberRepository businessMemberRepository,
            UserRepository userRepository,
            CurrentBusinessService currentBusinessService,
            EntitlementService entitlementService
    ) {
        this(businessRepository, businessMemberRepository, userRepository,
                currentBusinessService, entitlementService, null);
    }

    @Autowired
    public BusinessController(
            BusinessRepository businessRepository,
            BusinessMemberRepository businessMemberRepository,
            UserRepository userRepository,
            CurrentBusinessService currentBusinessService,
            EntitlementService entitlementService,
            BusinessAllocationService businessAllocationService
    ) {
        this.businessRepository = businessRepository;
        this.businessMemberRepository = businessMemberRepository;
        this.userRepository = userRepository;
        this.currentBusinessService = currentBusinessService;
        this.entitlementService = entitlementService;
        this.businessAllocationService = businessAllocationService;
    }

    /**
     * GET /api/v1/business — list all businesses the authenticated user belongs to.
     */
    @GetMapping
    public ResponseEntity<List<BusinessDTO>> listMyBusinesses(Authentication authentication) {
        String email = authentication.getName();
        Business activeBusiness = currentBusinessService.getCurrentBusiness(email);
        List<BusinessMember> memberships = currentBusinessService.getUserMemberships(email);

        List<BusinessDTO> dtos = memberships.stream().map(m -> {
            Business b = m.getBusiness();
            BusinessDTO dto = toDTO(b);
            dto.setUserRole(m.getRole());
            dto.setActive(b.getId().equals(activeBusiness.getId()));
            return dto;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    /**
     * POST /api/v1/business — create a new workspace / business.
     */
    @PostMapping
    @Transactional
    public ResponseEntity<BusinessDTO> createBusiness(
            @Valid @RequestBody CreateBusinessRequest request,
            Authentication authentication
    ) {
        User user = currentBusinessService.getCurrentUser(authentication.getName());

        // Reconcile active subscription before checking Plan Limits: FREE = 1, PLUS = 3, PRO = 5
        Subscription activeSub = entitlementService.getOrReconcileSubscription(user);
        Plan activePlan = activeSub != null ? activeSub.getPlan() : null;
        String planSlug = activePlan != null && activePlan.getSlug() != null
                ? activePlan.getSlug().toUpperCase()
                : (user.getPlanTier() != null ? user.getPlanTier().toUpperCase() : "FREE");

        int maxAllowed = 1;
        boolean resolvedFromEntitlements = false;
        if (activePlan != null && activePlan.getEntitlements() != null) {
            for (PlanEntitlement ent : activePlan.getEntitlements()) {
                if ("business.max".equalsIgnoreCase(ent.getFeatureKey())) {
                    maxAllowed = Integer.parseInt(ent.getValue());
                    resolvedFromEntitlements = true;
                    break;
                }
            }
        }
        if (!resolvedFromEntitlements) {
            if (planSlug.contains("PRO") || planSlug.contains("ENTERPRISE")) {
                maxAllowed = 5;
            } else if (planSlug.contains("PLUS")) {
                maxAllowed = 3;
            }
        }

        List<BusinessMember> existingMembers = businessMemberRepository.findAllActiveByUserIdWithBusiness(user.getId());
        if (businessAllocationService != null) {
            businessAllocationService.assertCanCreateEditableBusiness(user, maxAllowed);
        } else {
            long activeEditableOwnedCount = existingMembers.stream()
                    .filter(m -> "OWNER".equalsIgnoreCase(m.getRole())
                            && m.getBusiness().getArchivedAt() == null
                            && m.getBusiness().isEditable())
                    .count();

            if (activeEditableOwnedCount >= maxAllowed) {
                throw new com.afab.subscription.PlanLimitReachedException(
                        "business.max",
                        maxAllowed,
                        (int) activeEditableOwnedCount,
                        planSlug.contains("FREE") ? "plus" : "pro"
                );
            }
        }

        boolean hasAnyExistingBusiness = existingMembers.stream()
                .anyMatch(m -> "OWNER".equalsIgnoreCase(m.getRole()) && m.getBusiness().getArchivedAt() == null);

        Business business = new Business();
        business.setUser(user);
        business.setName(request.getName().trim());
        business.setCurrency(request.getCurrency().toUpperCase().trim());
        business.setCountry(request.getCountry());
        business.setTimezone(request.getTimezone());
        business.setIndustry(request.getIndustry());
        business.setBusinessType(request.getBusinessType());
        business.setBusinessEmail(user.getEmail());
        business.setStatus("ACTIVE");
        business.setAccessMode("EDITABLE");
        business.setPrimary(!hasAnyExistingBusiness);

        business = businessRepository.save(business);

        // Automatically assign OWNER membership
        BusinessMember ownerMember = new BusinessMember(business, user, "OWNER", "ACTIVE");
        businessMemberRepository.save(ownerMember);

        // Set as active business
        user.setActiveBusinessId(business.getId());
        userRepository.save(user);

        BusinessDTO dto = toDTO(business);
        dto.setUserRole("OWNER");
        dto.setActive(true);

        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    /**
     * GET /api/v1/business/mine — get the active business for the current context.
     */
    @GetMapping("/mine")
    public ResponseEntity<BusinessDTO> getMyBusiness(Authentication authentication) {
        String email = authentication.getName();
        Business business = currentBusinessService.getCurrentBusiness(email);
        User user = currentBusinessService.getCurrentUser(email);

        BusinessDTO dto = toDTO(business);
        dto.setActive(true);

        businessMemberRepository.findByBusinessIdAndUserId(business.getId(), user.getId())
                .ifPresent(m -> dto.setUserRole(m.getRole()));

        return ResponseEntity.ok(dto);
    }

    /**
     * GET /api/v1/business/{id} — get a specific business if member.
     */
    @GetMapping("/{id}")
    public ResponseEntity<BusinessDTO> getBusiness(@PathVariable UUID id, Authentication authentication) {
        User user = currentBusinessService.getCurrentUser(authentication.getName());

        BusinessMember member = businessMemberRepository.findWithBusinessByBusinessIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ForbiddenException("Unauthorized: You do not have access to business " + id));

        BusinessDTO dto = toDTO(member.getBusiness());
        dto.setUserRole(member.getRole());
        dto.setActive(id.equals(user.getActiveBusinessId()));

        return ResponseEntity.ok(dto);
    }

    /**
     * PUT /api/v1/business/{id} — update business settings (OWNER or ADMIN only).
     */
    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<BusinessDTO> updateBusiness(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBusinessRequest request,
            Authentication authentication
    ) {
        User user = currentBusinessService.getCurrentUser(authentication.getName());

        BusinessMember member = businessMemberRepository.findWithBusinessByBusinessIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ForbiddenException("Unauthorized: You do not have access to business " + id));

        if (!member.isAdminOrOwner()) {
            throw new ForbiddenException("Only business owners and admins can update business settings.");
        }

        Business business = member.getBusiness();
        BusinessAccessGuard.assertEditable(business);

        if (request.getName() != null) business.setName(request.getName());
        if (request.getCountry() != null) business.setCountry(request.getCountry());
        if (request.getCurrency() != null) business.setCurrency(request.getCurrency());
        if (request.getTimezone() != null) business.setTimezone(request.getTimezone());
        if (request.getFiscalYearStartMonth() != null) business.setFiscalYearStartMonth(request.getFiscalYearStartMonth());
        if (request.getIndustry() != null) business.setIndustry(request.getIndustry());
        if (request.getBusinessType() != null) business.setBusinessType(request.getBusinessType());
        if (request.getBusinessEmail() != null) business.setBusinessEmail(request.getBusinessEmail());
        if (request.getPhoneNumber() != null) business.setPhoneNumber(request.getPhoneNumber());
        if (request.getWebsite() != null) business.setWebsite(request.getWebsite());
        if (request.getTaxId() != null) business.setTaxId(request.getTaxId());
        if (request.getAddressLine() != null) business.setAddressLine(request.getAddressLine());
        if (request.getCity() != null) business.setCity(request.getCity());
        if (request.getState() != null) business.setState(request.getState());
        if (request.getPostalCode() != null) business.setPostalCode(request.getPostalCode());
        if (request.getDescription() != null) business.setDescription(request.getDescription());
        if (request.getLogoUrl() != null) business.setLogoUrl(request.getLogoUrl());
        if (request.getDateFormat() != null) business.setDateFormat(request.getDateFormat());
        if (request.getNumberFormat() != null) business.setNumberFormat(request.getNumberFormat());

        business = businessRepository.save(business);

        BusinessDTO dto = toDTO(business);
        dto.setUserRole(member.getRole());
        dto.setActive(id.equals(user.getActiveBusinessId()));

        return ResponseEntity.ok(dto);
    }

    /**
     * DELETE /api/v1/business/{id} — archive a business (OWNER only).
     */
    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> archiveBusiness(@PathVariable UUID id, Authentication authentication) {
        User user = currentBusinessService.getCurrentUser(authentication.getName());

        BusinessMember member = businessMemberRepository.findWithBusinessByBusinessIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ForbiddenException("Unauthorized: You do not have access to business " + id));

        if (!member.isOwner()) {
            throw new ForbiddenException("Only the business owner can archive a business.");
        }

        Business business = member.getBusiness();
        BusinessAccessGuard.assertEditable(business);
        business.setArchivedAt(Instant.now());
        business.setStatus("ARCHIVED");
        boolean wasPrimary = business.isPrimary();
        business.setPrimary(false);
        businessRepository.save(business);

        if (wasPrimary && businessAllocationService != null) {
            businessRepository.findAllOwnedActiveByUserId(user.getId()).stream()
                    .filter(Business::isEditable)
                    .findFirst()
                    .ifPresent(nextPrimary -> {
                        nextPrimary.setPrimary(true);
                        businessRepository.save(nextPrimary);
                    });
        }

        // If the archived business was the user's active business, clear it
        if (id.equals(user.getActiveBusinessId())) {
            user.setActiveBusinessId(null);
            userRepository.save(user);
        }

        return ResponseEntity.noContent().build();
    }

    /**
     * PUT /api/v1/business/{id}/switch — switch active business context.
     */
    @PutMapping("/{id}/switch")
    public ResponseEntity<BusinessDTO> switchBusiness(@PathVariable UUID id, Authentication authentication) {
        String email = authentication.getName();
        Business business = currentBusinessService.switchActiveBusiness(email, id);

        BusinessDTO dto = toDTO(business);
        dto.setActive(true);
        dto.setUserRole("MEMBER");

        User user = currentBusinessService.getCurrentUser(email);
        businessMemberRepository.findByBusinessIdAndUserId(id, user.getId())
                .ifPresent(m -> dto.setUserRole(m.getRole()));

        return ResponseEntity.ok(dto);
    }

    /**
     * GET /api/v1/business/allocations — inspect editable limit, access modes & pending downgrade selection.
     */
    @GetMapping("/allocations")
    public ResponseEntity<BusinessAllocationDTO> getAllocations(Authentication authentication) {
        return ResponseEntity.ok(businessAllocationService.getAllocationSummary(authentication.getName()));
    }

    /**
     * PUT /api/v1/business/allocations — swap which owned businesses are EDITABLE vs READ_ONLY.
     */
    @PutMapping("/allocations")
    public ResponseEntity<BusinessAllocationDTO> updateAllocations(
            @Valid @RequestBody UpdateBusinessAllocationRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(businessAllocationService.updateCurrentAllocation(
                authentication.getName(),
                request.getSelectedBusinessIds(),
                request.getPrimaryBusinessId()
        ));
    }

    /**
     * PUT /api/v1/business/allocations/pending — configure future editable selection for scheduled downgrade.
     */
    @PutMapping("/allocations/pending")
    public ResponseEntity<BusinessAllocationDTO> savePendingAllocations(
            @Valid @RequestBody SavePendingAllocationRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(businessAllocationService.savePendingAllocationForUser(
                authentication.getName(),
                request.getTargetPlanSlug(),
                request.getSelectedBusinessIds()
        ));
    }

    private BusinessDTO toDTO(Business business) {
        BusinessDTO dto = new BusinessDTO();
        dto.setId(business.getId());
        dto.setName(business.getName());
        dto.setCountry(business.getCountry());
        dto.setCurrency(business.getCurrency());
        dto.setTimezone(business.getTimezone());
        dto.setFiscalYearStartMonth(business.getFiscalYearStartMonth());
        dto.setIndustry(business.getIndustry());
        dto.setBusinessType(business.getBusinessType());
        dto.setBusinessEmail(business.getBusinessEmail());
        dto.setPhoneNumber(business.getPhoneNumber());
        dto.setWebsite(business.getWebsite());
        dto.setTaxId(business.getTaxId());
        dto.setAddressLine(business.getAddressLine());
        dto.setCity(business.getCity());
        dto.setState(business.getState());
        dto.setPostalCode(business.getPostalCode());
        dto.setDescription(business.getDescription());
        dto.setLogoUrl(business.getLogoUrl());
        dto.setStatus(business.getStatus());
        dto.setOnboardingComplete(business.isOnboardingComplete());
        dto.setCreatedAt(business.getCreatedAt());
        dto.setDateFormat(business.getDateFormat());
        dto.setNumberFormat(business.getNumberFormat());
        dto.setAccessMode(business.getAccessMode());
        dto.setEditable(business.isEditable());
        dto.setPrimary(business.isPrimary());
        return dto;
    }
}
