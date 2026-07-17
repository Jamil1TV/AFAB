package com.afab.auth;

import com.afab.auth.dto.AuthResponse;
import com.afab.auth.dto.LoginRequest;
import com.afab.auth.dto.RegisterRequest;
import com.afab.auth.dto.TokenRefreshRequest;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    
    // Rate Limiting Bucket: 5 requests per minute for auth endpoints
    private final Bucket authBucket;

    public AuthController(AuthService authService) {
        this.authService = authService;
        
        Bandwidth limit = Bandwidth.classic(5, Refill.greedy(5, Duration.ofMinutes(1)));
        this.authBucket = Bucket.builder()
                .addLimit(limit)
                .build();
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest httpRequest
    ) {
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body("Rate limit exceeded");
        }

        try {
            AuthResponse response = authService.register(
                    request,
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest
    ) {
        if (!authBucket.tryConsume(1)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body("Rate limit exceeded");
        }

        try {
            AuthResponse response = authService.login(
                    request,
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid credentials");
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(
            @Valid @RequestBody TokenRefreshRequest request,
            HttpServletRequest httpRequest
    ) {
        try {
            AuthResponse response = authService.refreshToken(
                    request.getRefreshToken(),
                    getClientIp(httpRequest),
                    httpRequest.getHeader("User-Agent")
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Invalid or expired refresh token");
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            @Valid @RequestBody TokenRefreshRequest request,
            HttpServletRequest httpRequest
    ) {
        authService.logout(
                request.getRefreshToken(),
                getClientIp(httpRequest),
                httpRequest.getHeader("User-Agent")
        );
        return ResponseEntity.ok().build();
    }

    private String getClientIp(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0];
    }
}
