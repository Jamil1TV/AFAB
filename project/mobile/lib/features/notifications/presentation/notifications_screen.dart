import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/notifications/data/notification_dto.dart';
import 'package:afab_mobile/features/notifications/domain/notifications_provider.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `DASH-04`: User-scoped notifications inbox (`GET /notifications`,
/// `PUT /notifications/{id}/read`, `PUT /notifications/read-all`).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _mapActionUrl(String? actionUrl) {
    if (actionUrl == null || actionUrl.isEmpty) return '/dashboard';
    if (actionUrl.contains('subscription') || actionUrl.contains('plans')) {
      return '/plans';
    }
    if (actionUrl.contains('transactions')) return '/transactions';
    if (actionUrl.contains('invoices')) return '/invoices';
    if (actionUrl.contains('budgets')) return '/budgets';
    if (actionUrl.contains('settings')) return '/settings';
    return '/dashboard';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final asyncState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if ((asyncState.value?.unreadCount ?? 0) > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(l10n.notificationsMarkAllRead),
            ),
        ],
      ),
      body: asyncState.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const AfabShimmerBox(height: 82),
        ),
        error: (err, _) => AfabErrorState(
          title: l10n.errorGenericTitle,
          message: err.toString(),
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (data) {
          if (data.notifications.isEmpty) {
            return Center(
              child: AfabEmptyState(
                icon: LucideIcons.bellOff,
                title: l10n.notificationsEmpty,
                description: l10n.notificationsEmptyDesc,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final item = data.notifications[index];
                return _NotificationCard(
                  item: item,
                  locale: locale,
                  onTap: () async {
                    if (!item.read) {
                      await ref
                          .read(notificationsProvider.notifier)
                          .markRead(item.id);
                    }
                    if (ctx.mounted &&
                        item.actionUrl != null &&
                        item.actionUrl!.isNotEmpty) {
                      ctx.go(_mapActionUrl(item.actionUrl));
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.locale,
    required this.onTap,
  });

  final NotificationItemDto item;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final (icon, tint) = switch (item.severity.toUpperCase()) {
      'ERROR' => (LucideIcons.circleAlert, colors.danger),
      'WARNING' => (LucideIcons.triangleAlert, colors.warning),
      'SUCCESS' => (LucideIcons.circleCheck, colors.success),
      _ => (LucideIcons.bell, colors.primary),
    };

    return AfabCard(
      padding: const EdgeInsets.all(14),
      borderColor:
          item.read ? colors.border : colors.primary.withValues(alpha: 0.45),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (!item.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
                if (item.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    AfabDateFormatter.formatRelativeTimestamp(
                      item.createdAt,
                      locale,
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
