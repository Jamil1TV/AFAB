package com.afab.common.exception;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.Map;

/**
 * Standard API error response body.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(
        int status,
        String error,
        String message,
        String path,
        Map<String, String> fieldErrors,
        Instant timestamp
) {
    public ApiError(int status, String error, String message, String path) {
        this(status, error, message, path, null, Instant.now());
    }

    public ApiError(int status, String error, String message, String path, Map<String, String> fieldErrors) {
        this(status, error, message, path, fieldErrors, Instant.now());
    }
}
