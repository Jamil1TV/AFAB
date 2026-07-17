package com.afab.common.exception;

import java.time.Instant;

/**
 * Standard API error response body.
 */
public record ApiError(
        int status,
        String error,
        String message,
        String path,
        Instant timestamp
) {
    public ApiError(int status, String error, String message, String path) {
        this(status, error, message, path, Instant.now());
    }
}
