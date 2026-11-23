package com.afab.security;

import com.afab.security.DistributedRateLimiter.Endpoint;
import com.afab.security.DistributedRateLimiter.RateLimitResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

class DistributedRateLimiterTest {

    @Test
    @DisplayName("Allows requests within Redis window limit and hashes identifiers before keying")
    @SuppressWarnings("unchecked")
    void allowsWithinLimitAndHashesKeys() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        RateLimitProperties props = new RateLimitProperties();
        props.setLoginPerMinute(5);

        when(redis.execute(any(RedisScript.class), anyList(), any()))
                .thenReturn(List.of(1L, 59_000L));

        DistributedRateLimiter limiter = new DistributedRateLimiter(redis, props);
        RateLimitResult res = limiter.check(Endpoint.LOGIN, "198.51.100.9", "user@example.com");

        assertThat(res.allowed()).isTrue();
        assertThat(res.remaining()).isEqualTo(4L);

        ArgumentCaptor<List<String>> keysCaptor = ArgumentCaptor.forClass(List.class);
        verify(redis, times(2)).execute(any(RedisScript.class), keysCaptor.capture(), any());
        List<String> allKeys = keysCaptor.getAllValues().stream().flatMap(List::stream).toList();
        assertThat(allKeys).allSatisfy(k -> {
            assertThat(k).doesNotContain("user@example.com");
            assertThat(k).doesNotContain("198.51.100.9");
        });
    }

    @Test
    @DisplayName("Rejects request with retryAfter when Redis counter exceeds limit")
    @SuppressWarnings("unchecked")
    void rejectsWhenLimitExceeded() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        RateLimitProperties props = new RateLimitProperties();
        props.setLoginPerMinute(3);

        when(redis.execute(any(RedisScript.class), anyList(), any()))
                .thenReturn(List.of(4L, 42_500L));

        DistributedRateLimiter limiter = new DistributedRateLimiter(redis, props);
        RateLimitResult res = limiter.check(Endpoint.LOGIN, "198.51.100.9", "user@example.com");

        assertThat(res.allowed()).isFalse();
        assertThat(res.serviceUnavailable()).isFalse();
        assertThat(res.retryAfterSeconds()).isEqualTo(43L);
    }

    @Test
    @DisplayName("Fails closed when Redis is unreachable and fail-mode is fail_closed")
    @SuppressWarnings("unchecked")
    void failsClosedOnRedisOutage() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        RateLimitProperties props = new RateLimitProperties();
        props.setFailMode("fail_closed");

        when(redis.execute(any(RedisScript.class), anyList(), any()))
                .thenThrow(new RedisConnectionFailureException("Connection refused"));

        DistributedRateLimiter limiter = new DistributedRateLimiter(redis, props);
        RateLimitResult res = limiter.check(Endpoint.LOGIN, "198.51.100.9", null);

        assertThat(res.allowed()).isFalse();
        assertThat(res.serviceUnavailable()).isTrue();
    }

    @Test
    @DisplayName("Fails open when explicitly configured for local dev")
    @SuppressWarnings("unchecked")
    void failsOpenWhenConfigured() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        RateLimitProperties props = new RateLimitProperties();
        props.setFailMode("fail_open");

        when(redis.execute(any(RedisScript.class), anyList(), any()))
                .thenThrow(new RedisConnectionFailureException("Connection refused"));

        DistributedRateLimiter limiter = new DistributedRateLimiter(redis, props);
        RateLimitResult res = limiter.check(Endpoint.LOGIN, "198.51.100.9", null);

        assertThat(res.allowed()).isTrue();
        assertThat(res.serviceUnavailable()).isFalse();
    }
}
