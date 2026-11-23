package com.afab.notification;

import com.afab.notification.dto.NotificationsResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<NotificationsResponse> listNotifications(Authentication authentication) {
        return ResponseEntity.ok(notificationService.getNotifications(authentication.getName()));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<NotificationsResponse> markAsRead(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        return ResponseEntity.ok(notificationService.markAsRead(authentication.getName(), id));
    }

    @PutMapping("/read-all")
    public ResponseEntity<NotificationsResponse> markAllAsRead(Authentication authentication) {
        return ResponseEntity.ok(notificationService.markAllAsRead(authentication.getName()));
    }
}
