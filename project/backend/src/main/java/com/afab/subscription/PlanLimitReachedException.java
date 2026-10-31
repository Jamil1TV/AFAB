package com.afab.subscription;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.FORBIDDEN)
public class PlanLimitReachedException extends RuntimeException {

    private final String code = "PLAN_LIMIT_REACHED";
    private final String feature;
    private final int limit;
    private final int used;
    private final String upgradeTo;

    public PlanLimitReachedException(String feature, int limit, int used, String upgradeTo) {
        super(String.format("Plan limit reached for '%s'. Limit: %d, Used: %d. Upgrade to %s to continue.",
                feature, limit, used, upgradeTo));
        this.feature = feature;
        this.limit = limit;
        this.used = used;
        this.upgradeTo = upgradeTo;
    }

    public String getCode() { return code; }
    public String getFeature() { return feature; }
    public int getLimit() { return limit; }
    public int getUsed() { return used; }
    public String getUpgradeTo() { return upgradeTo; }
}
