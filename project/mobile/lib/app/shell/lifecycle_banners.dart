import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/connectivity_provider.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LifecycleBanners extends ConsumerWidget {
  const LifecycleBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final isOnline = ref.watch(isOnlineProvider);
    final sub = ref.watch(subscriptionSnapshotProvider).value;

    final banners = <Widget>[];

    if (!isOnline) {
      banners.add(
        _BannerStrip(
          background: colors.surfaceInset,
          borderColor: colors.border,
          icon: LucideIcons.wifiOff,
          iconColor: colors.textMuted,
          title: l10n.commonOfflineBanner,
        ),
      );
    }

    if (sub != null && sub.isPastDue) {
      final hours = sub.gracePeriodHoursRemaining ?? 72;
      banners.add(
        _BannerStrip(
          background: colors.dangerBg,
          borderColor: colors.danger.withValues(alpha: 0.4),
          icon: LucideIcons.triangleAlert,
          iconColor: colors.danger,
          title: l10n.bannerPastDueTitle(hours),
          subtitle: l10n.bannerPastDueDesc,
          actionLabel: l10n.bannerManageAction,
          onAction: () => context.go('/plans'),
        ),
      );
    }

    if (sub != null && sub.allocationAttentionRequired) {
      banners.add(
        _BannerStrip(
          background: colors.warningBg,
          borderColor: colors.warning.withValues(alpha: 0.4),
          icon: LucideIcons.building2,
          iconColor: colors.warning,
          title: l10n.bannerAllocationTitle,
          subtitle: l10n.bannerAllocationDesc,
          actionLabel: l10n.bannerManageAction,
          onAction: () => context.go('/plans'),
        ),
      );
    }

    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: banners);
  }
}

class _BannerStrip extends StatelessWidget {
  const _BannerStrip({
    required this.background,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final Color background;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: iconColor,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
