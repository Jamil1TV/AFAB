package com.afab.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

/**
 * Paginated response wrapper for list endpoints.
 *
 * @param <T> The type of items in the page.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record PageResponse<T>(
        List<T> content,
        int page,
        int size,
        long totalElements,
        int totalPages,
        boolean first,
        boolean last
) {

    /**
     * Create a PageResponse from Spring Data Page.
     */
    public static <T> PageResponse<T> of(org.springframework.data.domain.Page<T> page) {
        return new PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.isFirst(),
                page.isLast()
        );
    }
}
