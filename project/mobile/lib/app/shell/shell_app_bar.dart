import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/business/presentation/business_switcher_sheet.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/notifications/domain/notifications_provider.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ShellAppBar({
    super.key,
    required this.currentPath,
  });

  final String currentPath;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final activeBiz = ref.watch(activeBusinessProvider);
    final sub = ref.watch(subscriptionSnapshotProvider).value;
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isCopilot = currentPath.startsWith('/copilot');

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showBusinessSwitcherSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceInset,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                activeBiz?.isReadOnly == true
                    ? LucideIcons.lock
                    : LucideIcons.building2,
                size: 16,
                color: activeBiz?.isReadOnly == true
                    ? colors.warning
                    : colors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  activeBiz?.name ?? l10n.businessSwitcherTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (activeBiz != null) ...[
                const SizedBox(width: 6),
                AfabStatusBadge(
                  label: activeBiz.currency,
                  variant: AfabBadgeVariant.neutral,
                ),
              ],
              if (sub != null && !sub.isFree) ...[
                const SizedBox(width: 6),
                AfabStatusBadge(
                  label: sub.planName.toUpperCase(),
                  variant: sub.isPro
                      ? AfabBadgeVariant.warning
                      : AfabBadgeVariant.primary,
                ),
              ],
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronsUpDown, size: 14, color: colors.textMuted),
            ],
          ),
        ),
      ),
      actions: [
        if (!isCopilot)
          IconButton(
            tooltip: l10n.moreHubAskCopilotTooltip,
            onPressed: () => ref
                .read(copilotLauncherProvider.notifier)
                .openCopilot(screenContext: {'page': currentPath}),
            icon: Icon(LucideIcons.sparkles, size: 20, color: colors.primary),
          ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: l10n.notificationsTitle,
              onPressed: () {
                ref.read(notificationsProvider.notifier).refresh();
                context.push('/notifications');
              },
              icon: Icon(LucideIcons.bell, size: 20, color: colors.textPrimary),
            ),
            if (unreadCount > 0)
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.danger,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
