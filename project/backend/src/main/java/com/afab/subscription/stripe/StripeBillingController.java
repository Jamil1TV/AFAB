package com.afab.subscription.stripe;

import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import com.afab.subscription.stripe.dto.*;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/billing")
public class StripeBillingController {

    private static final Logger log = LoggerFactory.getLogger(StripeBillingController.class);
    private final StripeBillingService billingService;

    public StripeBillingController(StripeBillingService billingService) {
        this.billingService = billingService;
    }

    @PostMapping("/checkout")
    public ResponseEntity<CheckoutSessionResponse> createCheckoutSession(
            @Valid @RequestBody CheckoutRequest request,
            Authentication authentication
    ) throws StripeException {
        CheckoutSessionResponse response = billingService.createCheckoutSession(authentication.getName(), request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/portal")
    public ResponseEntity<PortalSessionResponse> createPortalSession(
            @RequestBody(required = false) PortalRequest request,
            Authentication authentication
    ) throws StripeException {
        PortalSessionResponse response = billingService.createPortalSession(
                authentication.getName(),
                request != null ? request : new PortalRequest()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/checkout/verify")
    public ResponseEntity<SubscriptionSnapshotDTO> verifyCheckoutSession(
            @Valid @RequestBody VerifyCheckoutRequest request,
            Authentication authentication
    ) throws StripeException {
        SubscriptionSnapshotDTO snapshot = billingService.verifyCheckoutSession(
                authentication.getName(),
                request.getSessionId()
        );
        return ResponseEntity.ok(snapshot);
    }

    @PostMapping("/cancel")
    public ResponseEntity<SubscriptionSnapshotDTO> cancelSubscription(
            @RequestBody(required = false) CancelSubscriptionRequest request,
            Authentication authentication
    ) throws StripeException {
        SubscriptionSnapshotDTO snapshot = billingService.cancelSubscription(
                authentication.getName(),
                request != null ? request : new CancelSubscriptionRequest()
        );
        return ResponseEntity.ok(snapshot);
    }

    @PostMapping("/resume")
    public ResponseEntity<SubscriptionSnapshotDTO> resumeSubscription(Authentication authentication) throws StripeException {
        SubscriptionSnapshotDTO snapshot = billingService.resumeSubscription(authentication.getName());
        return ResponseEntity.ok(snapshot);
    }

    @PostMapping("/downgrade")
    public ResponseEntity<SubscriptionSnapshotDTO> scheduleDowngrade(
            @Valid @RequestBody DowngradeSubscriptionRequest request,
            Authentication authentication
    ) throws StripeException {
        SubscriptionSnapshotDTO snapshot = billingService.scheduleDowngrade(authentication.getName(), request);
        return ResponseEntity.ok(snapshot);
    }

    @PostMapping("/upgrade")
    public ResponseEntity<UpgradeSubscriptionResponse> upgradeSubscription(
            @Valid @RequestBody UpgradeSubscriptionRequest request,
            Authentication authentication
    ) throws StripeException {
        UpgradeSubscriptionResponse response = billingService.upgradeSubscription(authentication.getName(), request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/history")
    public ResponseEntity<BillingHistoryResponse> getBillingHistory(Authentication authentication) {
        return ResponseEntity.ok(billingService.getBillingHistory(authentication.getName()));
    }

    @PostMapping("/webhook")
    public ResponseEntity<?> handleWebhook(
            @RequestBody String rawPayload,
            @RequestHeader(value = "Stripe-Signature", required = false) String sigHeader
    ) throws StripeException {
        try {
            billingService.handleWebhook(rawPayload, sigHeader);
            return ResponseEntity.ok(Map.of("received", true));
        } catch (SignatureVerificationException | IllegalArgumentException e) {
            log.warn("Rejected invalid Stripe webhook request: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Invalid Stripe webhook signature"));
        }
    }
}
