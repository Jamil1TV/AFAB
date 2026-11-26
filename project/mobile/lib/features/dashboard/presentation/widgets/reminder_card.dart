import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Deterministic budget & overdue-invoice reminders card.
/// Fixes Web `ReminderCard.tsx` dead "View All" button and maps actual backend
/// types (`"budget"`, `"invoice"`).
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminders,
  });

  final List<ReminderItemDto> reminders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dashboardRemindersTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/budgets'),
                child: Text(l10n.commonViewAll),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reminders.isEmpty)
            AfabEmptyState(
              icon: LucideIcons.bellRing,
              title: l10n.commonNoData,
              description: l10n.dashboardRemindersEmpty,
            )
          else
            for (var i = 0; i < reminders.length; i++) ...[
              _ReminderTile(item: reminders[i], colors: colors),
              if (i < reminders.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.item, required this.colors});

  final ReminderItemDto item;
  final AfabColors colors;

  @override
  Widget build(BuildContext context) {
    final isInvoice = item.type.toLowerCase() == 'invoice';
    final isHigh = item.priority.toLowerCase() == 'high';
    final tint = isHigh ? colors.danger : colors.warning;

    return AfabInsetPanel(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => context.go(isInvoice ? '/invoices' : '/budgets'),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isInvoice ? LucideIcons.fileWarning : LucideIcons.piggyBank,
                size: 18,
                color: tint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AfabStatusBadge(
              label: item.priority.toUpperCase(),
              variant: isHigh
                  ? AfabBadgeVariant.danger
                  : AfabBadgeVariant.warning,
            ),
          ],
        ),
      ),
    );
  }
}
