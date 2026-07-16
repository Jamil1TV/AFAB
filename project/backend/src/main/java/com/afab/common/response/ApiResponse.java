package com.afab.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;

/**
 * Standardized API response wrapper.
 * Every API response is wrapped in this structure for consistency.
 *
 * @param <T> The type of the response data payload.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
        boolean success,
        String message,
        T data,
        Instant timestamp
) {

    /**
     * Create a successful response with data.
     */
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, null, data, Instant.now());
    }

    /**
     * Create a successful response with a message and data.
     */
    public static <T> ApiResponse<T> success(String message, T data) {
        return new ApiResponse<>(true, message, data, Instant.now());
    }

    /**
     * Create a successful response with only a message (no data payload).
     */
    public static <T> ApiResponse<T> success(String message) {
        return new ApiResponse<>(true, message, null, Instant.now());
    }

    /**
     * Create an error response.
     */
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, message, null, Instant.now());
    }
}
