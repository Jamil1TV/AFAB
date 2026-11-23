package com.afab.business;

/**
 * Backend-authoritative enforcement guard blocking mutations on READ_ONLY businesses.
 */
public final class BusinessAccessGuard {

    private BusinessAccessGuard() {}

    public static void assertEditable(Business business) {
        if (business != null && !business.isEditable()) {
            throw new BusinessReadOnlyException(business);
        }
    }
}
