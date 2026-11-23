package com.afab.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;

/**
 * Redis-backed distributed rate limiter using an atomic Lua script.
 * Shared across all backend instances. Handles Redis outages explicitly according
 * to `afab.rate-limit.fail-mode` (fail_closed in production, never silent in-memory fallback).
 */
@Service
public class DistributedRateLimiter {

    private static final Logger log = LoggerFactory.getLogger(DistributedRateLimiter.class);

    private static final long WINDOW_MILLIS = 60_000L;

    /**
     * Atomic fixed-window counter script:
     * KEYS[1] = rate limit key
     * ARGV[1] = window duration in ms
     * Returns {currentCount, remainingTtlMs}
     */
    private static final DefaultRedisScript<List> RATE_LIMIT_SCRIPT;

    static {
        RATE_LIMIT_SCRIPT = new DefaultRedisScript<>();
        RATE_LIMIT_SCRIPT.setScriptText(
                "local current = redis.call('INCR', KEYS[1]) " +
                "if current == 1 then " +
                "  redis.call('PEXPIRE', KEYS[1], ARGV[1]) " +
                "end " +
                "local ttl = redis.call('PTTL', KEYS[1]) " +
                "if ttl < 0 then " +
                "  redis.call('PEXPIRE', KEYS[1], ARGV[1]) " +
                "  ttl = tonumber(ARGV[1]) " +
                "end " +
                "return {current, ttl}"
        );
        RATE_LIMIT_SCRIPT.setResultType(List.class);
    }

    public enum Endpoint {
        LOGIN,
        REGISTER,
        FORGOT_PASSWORD,
        VERIFY_EMAIL,
        OTP_VERIFY,
        RESET_PASSWORD,
        REFRESH
    }

    public record RateLimitResult(boolean allowed, boolean serviceUnavailable, long remaining, long retryAfterSeconds) {
        public static RateLimitResult ok(long remaining) {
            return new RateLimitResult(true, false, Math.max(0, remaining), 0);
        }

        public static RateLimitResult rejected(long retryAfterSeconds) {
            return new RateLimitResult(false, false, 0, Math.max(1, retryAfterSeconds));
        }

        public static RateLimitResult unavailable() {
            return new RateLimitResult(false, true, 0, 5);
        }
    }

    private final StringRedisTemplate redisTemplate;
    private final RateLimitProperties properties;

    public DistributedRateLimiter(StringRedisTemplate redisTemplate, RateLimitProperties properties) {
        this.redisTemplate = redisTemplate;
        this.properties = properties;
    }

    /**
     * Checks rate limit for client IP and (optionally) a secondary identifier (e.g. normalized email).
     * Identifiers are SHA-256 hashed before being used in Redis keys so PII is never stored in Redis.
     */
    public RateLimitResult check(Endpoint endpoint, String clientIp, String secondaryIdentifier) {
        if (!properties.isEnabled()) {
            return RateLimitResult.ok(limitFor(endpoint));
        }

        int limit = limitFor(endpoint);
        String safeIp = (clientIp == null || clientIp.isBlank()) ? "unknown" : clientIp.trim();
        String ipKey = "afab:rl:" + endpoint.name().toLowerCase(Locale.ROOT) + ":ip:" + sha256Short(safeIp);

        RateLimitResult ipDecision = consumeKey(ipKey, limit);
        if (!ipDecision.allowed()) {
            return ipDecision;
        }

        if (secondaryIdentifier != null && !secondaryIdentifier.isBlank()) {
            String normalizedId = secondaryIdentifier.trim().toLowerCase(Locale.ROOT);
            String idKey = "afab:rl:" + endpoint.name().toLowerCase(Locale.ROOT) + ":id:" + sha256Short(normalizedId);
            RateLimitResult idDecision = consumeKey(idKey, limit);
            if (!idDecision.allowed()) {
                return idDecision;
            }
            return RateLimitResult.ok(Math.min(ipDecision.remaining(), idDecision.remaining()));
        }

        return ipDecision;
    }

    private RateLimitResult consumeKey(String key, int maxRequestsPerWindow) {
        try {
            @SuppressWarnings("unchecked")
            List<Object> result = redisTemplate.execute(
                    RATE_LIMIT_SCRIPT,
                    List.of(key),
                    String.valueOf(WINDOW_MILLIS)
            );
            if (result == null || result.size() < 2) {
                return handleRedisFailure(new IllegalStateException("Unexpected empty response from Redis rate limit script"));
            }
            long current = ((Number) result.get(0)).longValue();
            long ttlMs = ((Number) result.get(1)).longValue();
            if (current > maxRequestsPerWindow) {
                long retryAfterSeconds = Math.max(1L, (ttlMs + 999L) / 1000L);
                return RateLimitResult.rejected(retryAfterSeconds);
            }
            return RateLimitResult.ok(maxRequestsPerWindow - current);
        } catch (Exception e) {
            return handleRedisFailure(e);
        }
    }

    private RateLimitResult handleRedisFailure(Exception e) {
        log.error("Distributed rate limiter Redis error (failMode={}): {}",
                properties.getFailMode(), LogSanitizer.sanitizeMessage(e.getMessage()));
        if (properties.isFailClosed()) {
            return RateLimitResult.unavailable();
        }
        return RateLimitResult.ok(1);
    }

    public int limitFor(Endpoint endpoint) {
        return switch (endpoint) {
            case LOGIN -> Math.max(1, properties.getLoginPerMinute());
            case REGISTER -> Math.max(1, properties.getRegisterPerMinute());
            case FORGOT_PASSWORD -> Math.max(1, properties.getForgotPasswordPerMinute());
            case VERIFY_EMAIL -> Math.max(1, properties.getVerifyEmailPerMinute());
            case OTP_VERIFY -> Math.max(1, properties.getOtpPerMinute());
            case RESET_PASSWORD -> Math.max(1, properties.getResetPasswordPerMinute());
            case REFRESH -> Math.max(1, properties.getRefreshPerMinute());
        };
    }

    private static String sha256Short(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash).substring(0, 32);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }
}
