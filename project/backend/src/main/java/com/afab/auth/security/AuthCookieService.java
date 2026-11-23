package com.afab.auth.security;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;

/**
 * Manages secure HttpOnly refresh token cookies and double-submit CSRF cookies.
 * Production enforces Secure=true via SecurityConfigurationValidator.
 */
@Service
public class AuthCookieService {

    public static final String REFRESH_COOKIE_NAME = "refreshToken";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    @Value("${afab.auth.cookie.secure:true}")
    private boolean cookieSecure;

    @Value("${afab.auth.cookie.same-site:Lax}")
    private String cookieSameSite;

    @Value("${afab.auth.cookie.domain:}")
    private String cookieDomain;

    @Value("${afab.auth.cookie.refresh-path:/api/v1/auth}")
    private String refreshPath;

    @Value("${afab.auth.cookie.csrf-cookie-name:afab_csrf}")
    private String csrfCookieName;

    @Value("${afab.auth.cookie.csrf-header-name:X-CSRF-Token}")
    private String csrfHeaderName;

    @Value("${afab.cors.allowed-origins:http://localhost:3000,http://localhost:3001}")
    private String allowedOriginsRaw;

    public ResponseCookie buildRefreshCookie(String rawRefreshToken, long maxAgeSeconds) {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from(REFRESH_COOKIE_NAME, rawRefreshToken)
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite(cookieSameSite)
                .path(refreshPath)
                .maxAge(maxAgeSeconds);
        if (cookieDomain != null && !cookieDomain.isBlank()) {
            builder.domain(cookieDomain.trim());
        }
        return builder.build();
    }

    public ResponseCookie buildClearRefreshCookie() {
        return buildClearRefreshCookieForPath(refreshPath);
    }

    /**
     * Expires any leftover refreshToken cookie stored under the alternate legacy path
     * (/api/v1 vs /api/v1/auth) so browsers never send two cookies with the same name.
     */
    public ResponseCookie buildClearLegacyRefreshCookie() {
        String legacyPath = "/api/v1/auth".equals(refreshPath) ? "/api/v1" : "/api/v1/auth";
        return buildClearRefreshCookieForPath(legacyPath);
    }

    private ResponseCookie buildClearRefreshCookieForPath(String path) {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from(REFRESH_COOKIE_NAME, "")
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite(cookieSameSite)
                .path(path)
                .maxAge(0);
        if (cookieDomain != null && !cookieDomain.isBlank()) {
            builder.domain(cookieDomain.trim());
        }
        return builder.build();
    }

    /**
     * Non-HttpOnly double-submit CSRF cookie (Path=/) carrying a random nonce (no JWT/secret).
     * Frontend reads this value and echoes it in the X-CSRF-Token header on cookie-authenticated mutations.
     */
    public ResponseCookie buildCsrfCookie(String csrfToken, long maxAgeSeconds) {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from(csrfCookieName, csrfToken)
                .httpOnly(false)
                .secure(cookieSecure)
                .sameSite(cookieSameSite)
                .path("/")
                .maxAge(maxAgeSeconds);
        if (cookieDomain != null && !cookieDomain.isBlank()) {
            builder.domain(cookieDomain.trim());
        }
        return builder.build();
    }

    public ResponseCookie buildClearCsrfCookie() {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from(csrfCookieName, "")
                .httpOnly(false)
                .secure(cookieSecure)
                .sameSite(cookieSameSite)
                .path("/")
                .maxAge(0);
        if (cookieDomain != null && !cookieDomain.isBlank()) {
            builder.domain(cookieDomain.trim());
        }
        return builder.build();
    }

    public String generateCsrfToken() {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * Verifies CSRF protection for cookie-authenticated endpoints (/auth/refresh, /auth/logout):
     * 1. If Origin header is present, it must match an allowed CORS origin.
     * 2. X-CSRF-Token header must match the afab_csrf cookie in constant time.
     */
    public boolean verifyCsrfAndOrigin(HttpServletRequest request) {
        String origin = request.getHeader("Origin");
        if (origin != null && !origin.isBlank()) {
            List<String> allowed = Arrays.stream(allowedOriginsRaw.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
            if (!allowed.contains(origin.trim())) {
                return false;
            }
        }

        String headerToken = request.getHeader(csrfHeaderName);
        String cookieToken = extractCookie(request, csrfCookieName);
        if (headerToken == null || headerToken.isBlank() || cookieToken == null || cookieToken.isBlank()) {
            return false;
        }
        return MessageDigest.isEqual(
                headerToken.trim().getBytes(StandardCharsets.UTF_8),
                cookieToken.trim().getBytes(StandardCharsets.UTF_8)
        );
    }

    public String extractCookie(HttpServletRequest request, String name) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        for (Cookie cookie : cookies) {
            if (name.equals(cookie.getName())) {
                return cookie.getValue();
            }
        }
        return null;
    }

    public boolean isCookieSecure() {
        return cookieSecure;
    }

    public String getCookieSameSite() {
        return cookieSameSite;
    }
}
