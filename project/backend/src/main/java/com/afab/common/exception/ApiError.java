package com.afab.common.exception;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.Map;

/**
 * Standardized error response structure.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(
        int status,
        String error,
        String message,
        String path,
        Map<String, String> validationErrors,
        Instant timestamp
) {

    public static ApiError of(int status, String error, String message, String path) {
        return new ApiError(status, error, message, path, null, Instant.now());
    }

    public static ApiError withValidation(int status, String error, String message, String path,
                                          Map<String, String> validationErrors) {
        return new ApiError(status, error, message, path, validationErrors, Instant.now());
    }
}
