package com.afab.subscription;

import com.afab.subscription.dto.PlanSwitchRequest;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.subscription.dto.TrialActivationRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/subscription")
public class SubscriptionController {

    private final EntitlementService entitlementService;

    public SubscriptionController(EntitlementService entitlementService) {
        this.entitlementService = entitlementService;
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
     * POST /api/v1/subscription/trial — activate 7-day trial on Plus or Pro.
     */
    @PostMapping("/trial")
    public ResponseEntity<SubscriptionSnapshotDTO> activateTrial(
            @Valid @RequestBody TrialActivationRequest request,
            Authentication authentication
    ) {
        SubscriptionSnapshotDTO snapshot = entitlementService.activateTrial(authentication.getName(), request.getPlanSlug());
        return ResponseEntity.ok(snapshot);
    }

    /**
     * POST /api/v1/subscription/switch — switch plan (Free, Plus, Pro).
     */
    @PostMapping("/switch")
    public ResponseEntity<SubscriptionSnapshotDTO> switchPlan(
            @Valid @RequestBody PlanSwitchRequest request,
            Authentication authentication
    ) {
        SubscriptionSnapshotDTO snapshot = entitlementService.switchPlan(authentication.getName(), request.getPlanSlug());
        return ResponseEntity.ok(snapshot);
    }
}
