package com.afab.security;

import java.util.UUID;
import com.afab.security.domain.AuditLog;
import com.afab.security.domain.AuditLogRepository;
import com.afab.user.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class AuditService {

    private static final Logger log = LoggerFactory.getLogger(AuditService.class);

    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    /**
     * Logs a security event.
     */
    public void logSecurityEvent(User user, String action, String ipAddress, String userAgent, String details) {
        try {
            AuditLog auditLog = new AuditLog(user, action, "USER", user != null ? user.getId() : null, ipAddress, userAgent, details);
            auditLogRepository.save(auditLog);
            log.info("Security event recorded: {} for user {}", action, user != null ? user.getEmail() : "anonymous");
        } catch (Exception e) {
            log.error("Failed to write audit log for action: {}", action, e);
        }
    }

    public void logBusinessEvent(User user, String action, UUID businessId, String details) {
        try {
            AuditLog auditLog = new AuditLog(user, action, "BUSINESS", businessId, null, null, details);
            auditLogRepository.save(auditLog);
        } catch (Exception e) {
            log.error("Failed to write audit log for business action: {}", action, e);
        }
    }
}
