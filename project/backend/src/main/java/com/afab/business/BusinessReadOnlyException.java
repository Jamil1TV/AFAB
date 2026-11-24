package com.afab.business;

import java.util.UUID;

/**
 * Thrown when a write/mutation operation targets a business currently in READ_ONLY mode.
 */
public class BusinessReadOnlyException extends RuntimeException {

    private final String code = "BUSINESS_READ_ONLY";
    private final UUID businessId;
    private final String businessName;

    public BusinessReadOnlyException(Business business) {
        super(String.format(
                "Business '%s' is locked under your current subscription plan. All data inside it is safely preserved; swap your active business allocation in Subscription Settings or upgrade your plan to unlock it.",
                business != null && business.getName() != null ? business.getName() : "workspace"
        ));
        this.businessId = business != null ? business.getId() : null;
        this.businessName = business != null ? business.getName() : null;
    }

    public BusinessReadOnlyException(String message, UUID businessId, String businessName) {
        super(message);
        this.businessId = businessId;
        this.businessName = businessName;
    }

    public String getCode() {
        return code;
    }

    public UUID getBusinessId() {
        return businessId;
    }

    public String getBusinessName() {
        return businessName;
    }
}
