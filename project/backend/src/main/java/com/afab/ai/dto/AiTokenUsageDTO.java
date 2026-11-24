package com.afab.ai.dto;

public record AiTokenUsageDTO(
        int promptTokens,
        int completionTokens,
        int totalTokens,
        int monthlyTokensUsed,
        int monthlyTokensLimit,
        int monthlyTokensRemaining,
        int monthlyQueriesUsed,
        int monthlyQueriesLimit,
        int monthlyQueriesRemaining,
        String planSlug,
        String planName
) {}
