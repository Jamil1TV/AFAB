package com.afab.business;

import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.user.User;
import com.afab.user.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Service to resolve the current active business context for a user.
 * Implements Phase 4 Multi-Business context resolution and security enforcement:
 * - Reads X-Business-Id request header when present
 * - Enforces business membership (returns 403 Forbidden on foreign/unauthorized business IDs)
 * - Falls back to user.activeBusinessId or the user's primary/first active business
 */
@Service
public class CurrentBusinessService {

    public static final String BUSINESS_HEADER = "X-Business-Id";

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final BusinessMemberRepository businessMemberRepository;

    public CurrentBusinessService(
            UserRepository userRepository,
            BusinessRepository businessRepository,
            BusinessMemberRepository businessMemberRepository
    ) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.businessMemberRepository = businessMemberRepository;
    }

    @Transactional(readOnly = true)
    public Business getCurrentBusiness(String userEmail) {
        UUID headerBusinessId = resolveHeaderBusinessId();
        return getCurrentBusiness(userEmail, headerBusinessId);
    }

    @Transactional(readOnly = true)
    public Business getCurrentBusiness(String userEmail, UUID requestedBusinessId) {
        User user = getCurrentUser(userEmail);

        // 1. If explicit business ID requested (via X-Business-Id header or parameter)
        if (requestedBusinessId != null) {
            BusinessMember member = businessMemberRepository
                    .findWithBusinessByBusinessIdAndUserId(requestedBusinessId, user.getId())
                    .orElseThrow(() -> new ForbiddenException("Unauthorized: You do not have access to business " + requestedBusinessId));

            if (!"ACTIVE".equalsIgnoreCase(member.getStatus()) || member.getBusiness().getArchivedAt() != null) {
                throw new ForbiddenException("Unauthorized: Membership in business is inactive or business is archived.");
            }
            return member.getBusiness();
        }

        // 2. If user has activeBusinessId saved
        if (user.getActiveBusinessId() != null) {
            Optional<BusinessMember> memberOpt = businessMemberRepository
                    .findWithBusinessByBusinessIdAndUserId(user.getActiveBusinessId(), user.getId());
            if (memberOpt.isPresent() && "ACTIVE".equalsIgnoreCase(memberOpt.get().getStatus()) && memberOpt.get().getBusiness().getArchivedAt() == null) {
                return memberOpt.get().getBusiness();
            }
        }

        // 3. Fallback: Find user's first active business membership
        List<BusinessMember> members = businessMemberRepository.findAllActiveByUserIdWithBusiness(user.getId());
        if (!members.isEmpty()) {
            return members.get(0).getBusiness();
        }

        // 4. Legacy fallback: findFirstByUserIdAndArchivedAtIsNull
        return businessRepository.findFirstByUserIdAndArchivedAtIsNull(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("No active business found for user: " + userEmail));
    }

    @Transactional(readOnly = true)
    public User getCurrentUser(String userEmail) {
        return userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
    }

    @Transactional(readOnly = true)
    public List<BusinessMember> getUserMemberships(String userEmail) {
        User user = getCurrentUser(userEmail);
        return businessMemberRepository.findAllActiveByUserIdWithBusiness(user.getId());
    }

    @Transactional
    public Business switchActiveBusiness(String userEmail, UUID businessId) {
        User user = getCurrentUser(userEmail);

        BusinessMember member = businessMemberRepository
                .findWithBusinessByBusinessIdAndUserId(businessId, user.getId())
                .orElseThrow(() -> new ForbiddenException("Unauthorized: You do not belong to business " + businessId));

        if (!"ACTIVE".equalsIgnoreCase(member.getStatus()) || member.getBusiness().getArchivedAt() != null) {
            throw new ForbiddenException("Cannot switch to an inactive or archived business.");
        }

        user.setActiveBusinessId(businessId);
        userRepository.save(user);
        return member.getBusiness();
    }

    private UUID resolveHeaderBusinessId() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                String headerVal = request.getHeader(BUSINESS_HEADER);
                if (headerVal != null && !headerVal.isBlank()) {
                    return UUID.fromString(headerVal.trim());
                }
            }
        } catch (IllegalArgumentException e) {
            throw new ForbiddenException("Invalid X-Business-Id header format.");
        } catch (Exception ignored) {
            // Non-HTTP context (async/background/test)
        }
        return null;
    }
}
