package com.afab.notification;

import com.afab.common.exception.ResourceNotFoundException;
import com.afab.mail.EmailService;
import com.afab.notification.dto.NotificationDTO;
import com.afab.notification.dto.NotificationsResponse;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    public NotificationService(
            NotificationRepository notificationRepository,
            UserRepository userRepository,
            EmailService emailService
    ) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
    }

    @Transactional
    public void notifyUser(
            User user,
            String type,
            String severity,
            String title,
            String message,
            String actionUrl,
            boolean sendEmail
    ) {
        if (user == null || user.getId() == null) {
            return;
        }
        Notification notification = new Notification(user, type, severity, title, message, actionUrl);
        notificationRepository.save(notification);

        if (sendEmail && user.getEmail() != null && !user.getEmail().isBlank()) {
            try {
                String accent = switch (severity != null ? severity.toUpperCase() : "INFO") {
                    case "ERROR" -> "#DC2626";
                    case "WARNING" -> "#F59E0B";
                    case "SUCCESS" -> "#10B981";
                    default -> "#7C3AED";
                };
                emailService.sendBillingNotification(
                        user.getEmail(),
                        user.getFirstName(),
                        "AFAB — " + title,
                        title,
                        message,
                        "Review Subscription",
                        actionUrl != null ? actionUrl : "/dashboard/settings/subscription",
                        accent
                );
            } catch (Exception e) {
                log.warn("Non-fatal failure sending billing email ({}) to {}: {}", type, user.getEmail(), e.getMessage());
            }
        }
    }

    @Transactional(readOnly = true)
    public NotificationsResponse getNotifications(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        List<NotificationDTO> dtos = notificationRepository.findTop30ByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(n -> new NotificationDTO(
                        n.getId(),
                        n.getType(),
                        n.getSeverity(),
                        n.getTitle(),
                        n.getMessage(),
                        n.getActionUrl(),
                        n.getReadAt(),
                        n.getCreatedAt()
                ))
                .toList();
        long unreadCount = notificationRepository.countByUserIdAndReadAtIsNull(user.getId());
        return new NotificationsResponse(unreadCount, dtos);
    }

    @Transactional
    public NotificationsResponse markAsRead(String userEmail, UUID notificationId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Notification n = notificationRepository.findByIdAndUserId(notificationId, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
        if (n.getReadAt() == null) {
            n.setReadAt(Instant.now());
            notificationRepository.save(n);
        }
        return getNotifications(userEmail);
    }

    @Transactional
    public NotificationsResponse markAllAsRead(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        notificationRepository.markAllReadByUserId(user.getId(), Instant.now());
        return getNotifications(userEmail);
    }
}
