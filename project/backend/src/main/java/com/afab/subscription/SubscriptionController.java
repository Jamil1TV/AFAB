package com.afab.subscription;

import com.afab.common.exception.ForbiddenException;
import com.afab.subscription.dto.PlanSwitchRequest;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.subscription.dto.TrialActivationRequest;
import com.afab.subscription.stripe.StripeProperties;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;

@RestController
@RequestMapping("/api/v1/subscription")
public class SubscriptionController {

    private final EntitlementService entitlementService;
    private final StripeProperties stripeProperties;
    private final String activeProfiles;

    public SubscriptionController(EntitlementService entitlementService) {
        this(entitlementService, new StripeProperties(), "local");
    }

    @Autowired
    public SubscriptionController(
            EntitlementService entitlementService,
            StripeProperties stripeProperties,
            @Value("${spring.profiles.active:local}") String activeProfiles
    ) {
        this.entitlementService = entitlementService;
        this.stripeProperties = stripeProperties;
        this.activeProfiles = activeProfiles;
    }

    /**
     * GET /api/v1/subscription/me — fetch user's active plan, limits, and usage.
     */
    @GetMapping("/me")
    public ResponseEntity<SubscriptionSnapshotDTO> getMySubscription(Authentication authentication) {
        SubscriptionSnapshotDTO snapshot = entitlementService.getEntitlementsSnapshot(authentication.getName());
        return ResponseEntity.ok(snapshot);
    }

    /**
     * POST /api/v1/subscription/trial — disabled once Stripe Billing is active or outside local/dev profiles.
     */
    @PostMapping("/trial")
    public ResponseEntity<SubscriptionSnapshotDTO> activateTrial(
            @Valid @RequestBody TrialActivationRequest request,
            Authentication authentication
    ) {
        ensureDevFallbackAllowed();
        SubscriptionSnapshotDTO snapshot = entitlementService.activateTrial(authentication.getName(), request.getPlanSlug());
        return ResponseEntity.ok(snapshot);
    }

    /**
     * POST /api/v1/subscription/switch — disabled once Stripe Billing is active or outside local/dev profiles.
     */
    @PostMapping("/switch")
    public ResponseEntity<SubscriptionSnapshotDTO> switchPlan(
            @Valid @RequestBody PlanSwitchRequest request,
            Authentication authentication
    ) {
        ensureDevFallbackAllowed();
        SubscriptionSnapshotDTO snapshot = entitlementService.switchPlan(authentication.getName(), request.getPlanSlug());
        return ResponseEntity.ok(snapshot);
    }

    private void ensureDevFallbackAllowed() {
        boolean isDevProfile = activeProfiles != null && Arrays.stream(activeProfiles.split(","))
                .map(String::trim)
                .anyMatch(p -> "local".equalsIgnoreCase(p) || "dev".equalsIgnoreCase(p));

        if ((stripeProperties != null && stripeProperties.isConfigured()) || !isDevProfile) {
            throw new ForbiddenException(
                    "Direct plan switching is disabled. Use /api/v1/billing/checkout or /api/v1/billing/portal."
            );
        }
    }
}
