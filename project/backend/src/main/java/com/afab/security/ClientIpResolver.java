package com.afab.security;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Resolves the real client IP without blindly trusting arbitrary X-Forwarded-For headers.
 * X-Forwarded-For is honored ONLY when the immediate peer (remoteAddr) is listed in
 * `afab.security.trusted-proxies`.
 */
@Component
public class ClientIpResolver {

    private final Set<String> trustedProxies;

    public ClientIpResolver(@Value("${afab.security.trusted-proxies:}") String trustedProxiesRaw) {
        this.trustedProxies = Arrays.stream(trustedProxiesRaw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toUnmodifiableSet());
    }

    public String resolve(HttpServletRequest request) {
        if (request == null) {
            return "unknown";
        }
        String remoteAddr = normalizeIp(request.getRemoteAddr());
        if (trustedProxies.isEmpty() || !trustedProxies.contains(remoteAddr)) {
            return remoteAddr;
        }

        String xff = request.getHeader("X-Forwarded-For");
        if (xff == null || xff.isBlank()) {
            return remoteAddr;
        }

        // Walk right-to-left, skipping trusted proxy hops, and return the first untrusted client IP.
        String[] hops = xff.split(",");
        for (int i = hops.length - 1; i >= 0; i--) {
            String candidate = normalizeIp(hops[i]);
            if (!candidate.isEmpty() && !"unknown".equalsIgnoreCase(candidate) && !trustedProxies.contains(candidate)) {
                return candidate;
            }
        }
        return remoteAddr;
    }

    private String normalizeIp(String raw) {
        if (raw == null) {
            return "unknown";
        }
        String trimmed = raw.trim();
        return trimmed.isEmpty() ? "unknown" : trimmed;
    }
}
