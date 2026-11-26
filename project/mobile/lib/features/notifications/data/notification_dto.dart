import 'package:flutter/foundation.dart';

@immutable
class NotificationItemDto {
  const NotificationItemDto({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.actionUrl,
    required this.read,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final String? actionUrl;
  final bool read;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) {
    return NotificationItemDto(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      severity: (json['severity'] ?? 'INFO').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      actionUrl: json['actionUrl']?.toString(),
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] is String
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

@immutable
class NotificationsResponseDto {
  const NotificationsResponseDto({
    required this.unreadCount,
    required this.notifications,
  });

  final int unreadCount;
  final List<NotificationItemDto> notifications;

  factory NotificationsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['notifications'] as List<dynamic>? ?? const [];
    return NotificationsResponseDto(
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      notifications: rawList
          .whereType<Map<String, dynamic>>()
          .map(NotificationItemDto.fromJson)
          .toList(),
    );
  }
}
