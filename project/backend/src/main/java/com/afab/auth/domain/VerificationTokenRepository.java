package com.afab.auth.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

public interface VerificationTokenRepository extends JpaRepository<VerificationToken, UUID> {

    /**
     * Find a valid (unused, not expired) token by its hash and type.
     */
    @Query("SELECT t FROM VerificationToken t WHERE t.token = :token AND t.tokenType = :type AND t.usedAt IS NULL AND t.expiresAt > :now")
    Optional<VerificationToken> findValidToken(
            @Param("token") String tokenHash,
            @Param("type") VerificationToken.TokenType type,
            @Param("now") Instant now
    );

    /**
     * Find the latest valid token for a specific user and type.
     */
    @Query("SELECT t FROM VerificationToken t WHERE t.user.id = :userId AND t.tokenType = :type AND t.usedAt IS NULL AND t.expiresAt > :now ORDER BY t.createdAt DESC LIMIT 1")
    Optional<VerificationToken> findLatestValidToken(
            @Param("userId") UUID userId,
            @Param("type") VerificationToken.TokenType type,
            @Param("now") Instant now
    );

    /**
     * Invalidate all existing tokens for a user+type combination before issuing a new one.
     * This prevents token accumulation and brute-force attacks.
     */
    @Modifying
    @Query("UPDATE VerificationToken t SET t.usedAt = :now WHERE t.user.id = :userId AND t.tokenType = :type AND t.usedAt IS NULL")
    void invalidateAllUserTokens(
            @Param("userId") UUID userId,
            @Param("type") VerificationToken.TokenType type,
            @Param("now") Instant now
    );

    /**
     * Count recent tokens to enforce rate limiting (e.g., max 5 OTP requests per hour).
     */
    @Query("SELECT COUNT(t) FROM VerificationToken t WHERE t.user.id = :userId AND t.tokenType = :type AND t.createdAt > :since")
    long countRecentTokens(
            @Param("userId") UUID userId,
            @Param("type") VerificationToken.TokenType type,
            @Param("since") Instant since
    );

    /**
     * Cleanup: delete all expired and used tokens older than a threshold.
     */
    @Modifying
    @Query("DELETE FROM VerificationToken t WHERE t.expiresAt < :before AND (t.usedAt IS NOT NULL OR t.expiresAt < :before)")
    void deleteExpiredTokens(@Param("before") Instant before);
}
