import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/notifications/data/notification_dto.dart';
import 'package:afab_mobile/features/notifications/data/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsNotifier extends AsyncNotifier<NotificationsResponseDto> {
  @override
  Future<NotificationsResponseDto> build() async {
    final session = ref.watch(authNotifierProvider);
    if (!session.isAuthenticated ||
        session.needsEmailVerification ||
        session.needsOnboarding) {
      return const NotificationsResponseDto(unreadCount: 0, notifications: []);
    }
    return ref.read(notificationsRepositoryProvider).fetchNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).fetchNotifications(),
    );
  }

  Future<void> markRead(String id) async {
    final next =
        await ref.read(notificationsRepositoryProvider).markRead(id);
    state = AsyncValue.data(next);
  }

  Future<void> markAllRead() async {
    final next =
        await ref.read(notificationsRepositoryProvider).markAllRead();
    state = AsyncValue.data(next);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsResponseDto>(
  NotificationsNotifier.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).value?.unreadCount ?? 0;
});
