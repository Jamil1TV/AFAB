package com.afab.notification.dto;

import java.util.List;

public class NotificationsResponse {
    private long unreadCount;
    private List<NotificationDTO> notifications;

    public NotificationsResponse() {}

    public NotificationsResponse(long unreadCount, List<NotificationDTO> notifications) {
        this.unreadCount = unreadCount;
        this.notifications = notifications;
    }

    public long getUnreadCount() { return unreadCount; }
    public void setUnreadCount(long unreadCount) { this.unreadCount = unreadCount; }

    public List<NotificationDTO> getNotifications() { return notifications; }
    public void setNotifications(List<NotificationDTO> notifications) { this.notifications = notifications; }
}
