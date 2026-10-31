package com.afab.health;

import com.afab.mail.MailHealthMonitor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

    private final MailHealthMonitor mailHealthMonitor;

    public HealthController(MailHealthMonitor mailHealthMonitor) {
        this.mailHealthMonitor = mailHealthMonitor;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> healthCheck() {
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "timestamp", Instant.now(),
                "service", "afab-backend",
                "mail", Map.of("status", mailHealthMonitor.isHealthy() ? "UP" : "DOWN")
        ));
    }
}
